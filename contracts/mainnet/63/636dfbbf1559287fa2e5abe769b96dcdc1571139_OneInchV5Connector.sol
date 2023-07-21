// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title FixedPoint
 * @dev Math library to operate with fixed point values with 18 decimals
 */
library FixedPoint {
    // 1 in fixed point value: 18 decimal places
    uint256 internal constant ONE = 1e18;

    /**
     * @dev Multiplies two fixed point numbers rounding down
     */
    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product / ONE;
        }
    }

    /**
     * @dev Multiplies two fixed point numbers rounding up
     */
    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            uint256 product = a * b;
            require(a == 0 || product / a == b, 'MUL_OVERFLOW');
            return product == 0 ? 0 : (((product - 1) / ONE) + 1);
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding down
     */
    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return aInflated / b;
        }
    }

    /**
     * @dev Divides two fixed point numbers rounding up
     */
    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            require(b != 0, 'ZERO_DIVISION');
            if (a == 0) return 0;
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, 'DIV_INTERNAL');
            return ((aInflated - 1) / b) + 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title Arrays
 * @dev Helper methods to operate arrays
 */
library Arrays {
    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address b) internal pure returns (address[] memory result) {
        result = new address[](2);
        result[0] = a;
        result[1] = b;
    }

    /**
     * @dev Builds an array of addresses based on the given ones
     */
    function from(address a, address[] memory b, address c) internal pure returns (address[] memory result) {
        result = new address[](b.length + 2);
        result[0] = a;
        for (uint256 i = 0; i < b.length; i++) {
            result[i + 1] = b[i];
        }
        result[b.length + 1] = c;
    }

    /**
     * @dev Builds an array of uint24s based on the given ones
     */
    function from(uint24 a, uint24[] memory b) internal pure returns (uint24[] memory result) {
        result = new uint24[](b.length + 1);
        result[0] = a;
        for (uint256 i = 0; i < b.length; i++) {
            result[i + 1] = b[i];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title BytesHelpers
 * @dev Provides a list of Bytes helper methods
 */
library BytesHelpers {
    /**
     * @dev Concatenates an address to a bytes array
     */
    function concat(bytes memory self, address value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }

    /**
     * @dev Concatenates an uint24 to a bytes array
     */
    function concat(bytes memory self, uint24 value) internal pure returns (bytes memory) {
        return abi.encodePacked(self, value);
    }

    /**
     * @dev Decodes a bytes array into an uint256
     */
    function toUint256(bytes memory self) internal pure returns (uint256) {
        return toUint256(self, 0);
    }

    /**
     * @dev Reads an uint256 from a bytes array starting at a given position
     */
    function toUint256(bytes memory self, uint256 start) internal pure returns (uint256 result) {
        require(self.length >= start + 32, 'BYTES_OUT_OF_BOUNDS');
        assembly {
            result := mload(add(add(self, 0x20), start))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

/**
 * @title Denominations
 * @dev Provides a list of ground denominations for those tokens that cannot be represented by an ERC20.
 * For now, the only needed is the native token that could be ETH, MATIC, or other depending on the layer being operated.
 */
library Denominations {
    address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
    address internal constant USD = address(840);

    function isNativeToken(address token) internal pure returns (bool) {
        return token == NATIVE_TOKEN;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

import './Denominations.sol';

/**
 * @title ERC20Helpers
 * @dev Provides a list of ERC20 helper methods
 */
library ERC20Helpers {
    function approve(address token, address to, uint256 amount) internal {
        SafeERC20.safeApprove(IERC20(token), to, 0);
        SafeERC20.safeApprove(IERC20(token), to, amount);
    }

    function transfer(address token, address to, uint256 amount) internal {
        if (Denominations.isNativeToken(token)) Address.sendValue(payable(to), amount);
        else SafeERC20.safeTransfer(IERC20(token), to, amount);
    }

    function balanceOf(address token, address account) internal view returns (uint256) {
        if (Denominations.isNativeToken(token)) return address(account).balance;
        else return IERC20(token).balanceOf(address(account));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title IWrappedNativeToken
 */
interface IWrappedNativeToken is IERC20 {
    /**
     * @dev Wraps msg.value into the wrapped-native token
     */
    function deposit() external payable;

    /**
     * @dev Unwraps requested amount to the native token
     */
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IAxelarGateway.sol';

/**
 * @title AxelarConnector
 * @dev Interfaces with Axelar to bridge tokens
 */
contract AxelarConnector {
    // List of chain names supported by Axelar
    string private constant ETHEREUM_NAME = 'Ethereum';
    string private constant POLYGON_NAME = 'Polygon';
    string private constant ARBITRUM_NAME = 'arbitrum';
    string private constant BSC_NAME = 'binance';
    string private constant FANTOM_NAME = 'Fantom';
    string private constant AVALANCHE_NAME = 'Avalanche';

    // List of chain IDs supported by Axelar
    uint256 private constant ETHEREUM_ID = 1;
    uint256 private constant POLYGON_ID = 137;
    uint256 private constant ARBITRUM_ID = 42161;
    uint256 private constant BSC_ID = 56;
    uint256 private constant FANTOM_ID = 250;
    uint256 private constant AVALANCHE_ID = 43114;

    // Reference to the Axelar gateway of the source chain
    IAxelarGateway public immutable axelarGateway;

    /**
     * @dev Creates a new Axelar connector
     * @param _axelarGateway Address of the Axelar gateway for the source chain
     */
    constructor(address _axelarGateway) {
        axelarGateway = IAxelarGateway(_axelarGateway);
    }

    /**
     * @dev Executes a bridge of assets using Axelar
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amountIn, address recipient) external {
        require(block.chainid != chainId, 'AXELAR_BRIDGE_SAME_CHAIN');
        require(recipient != address(0), 'AXELAR_BRIDGE_RECIPIENT_ZERO');

        string memory chainName = _getChainName(chainId);
        string memory symbol = IERC20Metadata(token).symbol();

        uint256 preBalanceIn = IERC20(token).balanceOf(address(this));

        ERC20Helpers.approve(token, address(axelarGateway), amountIn);
        axelarGateway.sendToken(chainName, Strings.toHexString(recipient), symbol, amountIn);

        uint256 postBalanceIn = IERC20(token).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'AXELAR_BAD_TOKEN_IN_BALANCE');
    }

    /**
     * @dev Tells the chain name based on a chain ID
     * @param chainId ID of the chain being queried
     * @return Chain name associated to the requested chain ID
     */
    function _getChainName(uint256 chainId) internal pure returns (string memory) {
        if (chainId == ETHEREUM_ID) return ETHEREUM_NAME;
        else if (chainId == POLYGON_ID) return POLYGON_NAME;
        else if (chainId == ARBITRUM_ID) return ARBITRUM_NAME;
        else if (chainId == BSC_ID) return BSC_NAME;
        else if (chainId == FANTOM_ID) return FANTOM_NAME;
        else if (chainId == AVALANCHE_ID) return AVALANCHE_NAME;
        else revert('AXELAR_UNKNOWN_CHAIN_ID');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IAxelarGateway {
    function sendToken(string memory chain, string memory recipient, string memory symbol, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IConnext.sol';

/**
 * @title ConnextConnector
 * @dev Interfaces with Connext to bridge tokens
 */
contract ConnextConnector {
    // List of chain domains supported by Connext
    uint32 private constant ETHEREUM_DOMAIN = 6648936;
    uint32 private constant POLYGON_DOMAIN = 1886350457;
    uint32 private constant ARBITRUM_DOMAIN = 1634886255;
    uint32 private constant OPTIMISM_DOMAIN = 1869640809;
    uint32 private constant GNOSIS_DOMAIN = 6778479;
    uint32 private constant BSC_DOMAIN = 6450786;

    // List of chain IDs supported by Connext
    uint256 private constant ETHEREUM_ID = 1;
    uint256 private constant POLYGON_ID = 137;
    uint256 private constant ARBITRUM_ID = 42161;
    uint256 private constant OPTIMISM_ID = 10;
    uint256 private constant GNOSIS_ID = 100;
    uint256 private constant BSC_ID = 56;

    // Reference to the Connext contract of the source chain
    IConnext public immutable connext;

    /**
     * @dev Creates a new Connext connector
     * @param _connext Address of the Connext contract for the source chain
     */
    constructor(address _connext) {
        connext = IConnext(_connext);
    }

    /**
     * @dev Executes a bridge of assets using Connext
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param minAmountOut Min amount of tokens to receive on the destination chain after relayer fees and slippage
     * @param recipient Address that will receive the tokens on the destination chain
     * @param relayerFee Fee to be paid to the relayer
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        uint256 relayerFee
    ) external {
        require(block.chainid != chainId, 'CONNEXT_BRIDGE_SAME_CHAIN');
        require(recipient != address(0), 'CONNEXT_BRIDGE_RECIPIENT_ZERO');
        require(relayerFee <= amountIn, 'CONNEXT_RELAYER_FEE_GT_AMOUNT_IN');
        require(minAmountOut <= amountIn - relayerFee, 'CONNEXT_MIN_AMOUNT_OUT_TOO_BIG');

        uint32 domain = _getChainDomain(chainId);
        uint256 amountInAfterFees = amountIn - relayerFee;

        // We validated `minAmountOut` is lower than or equal to `amountInAfterFees`
        // then we can compute slippage in BPS (e.g. 30 = 0.3%)
        uint256 slippage = 100 - ((minAmountOut * 100) / amountInAfterFees);

        uint256 preBalanceIn = IERC20(token).balanceOf(address(this));
        ERC20Helpers.approve(token, address(connext), amountIn);

        connext.xcall(
            domain,
            recipient,
            token,
            address(this), // This is the delegate address, the one that will be able to act in case the bridge fails
            amountInAfterFees,
            slippage,
            new bytes(0), // No call on the destination chain needed
            relayerFee
        );

        uint256 postBalanceIn = IERC20(token).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'CONNEXT_BAD_TOKEN_IN_BALANCE');
    }

    /**
     * @dev Tells the chain domain based on a chain ID
     * @param chainId ID of the chain being queried
     * @return Chain domain associated to the requested chain ID
     */
    function _getChainDomain(uint256 chainId) internal pure returns (uint32) {
        if (chainId == ETHEREUM_ID) return ETHEREUM_DOMAIN;
        else if (chainId == POLYGON_ID) return POLYGON_DOMAIN;
        else if (chainId == ARBITRUM_ID) return ARBITRUM_DOMAIN;
        else if (chainId == OPTIMISM_ID) return OPTIMISM_DOMAIN;
        else if (chainId == GNOSIS_ID) return GNOSIS_DOMAIN;
        else if (chainId == BSC_ID) return BSC_DOMAIN;
        else revert('CONNEXT_UNKNOWN_CHAIN_ID');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IConnext {
    function xcall(
        uint32 destination,
        address to,
        address asset,
        address delegate,
        uint256 amount,
        uint256 slippage,
        bytes calldata callData,
        uint256 relayerFee
    ) external payable returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';
import '@mimic-fi/v3-helpers/contracts/utils/Denominations.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';
import '@mimic-fi/v3-helpers/contracts/utils/IWrappedNativeToken.sol';

import './IHopL2AMM.sol';
import './IHopL1Bridge.sol';

/**
 * @title HopConnector
 * @dev Interfaces with Hop Exchange to bridge tokens
 */
contract HopConnector {
    using FixedPoint for uint256;
    using Denominations for address;

    // Ethereum mainnet chain ID = 1
    uint256 private constant MAINNET_CHAIN_ID = 1;

    // Goerli chain ID = 5
    uint256 private constant GOERLI_CHAIN_ID = 5;

    // Wrapped native token reference
    address public immutable wrappedNativeToken;

    /**
     * @dev Initializes the HopConnector contract
     * @param _wrappedNativeToken Address of the wrapped native token
     */
    constructor(address _wrappedNativeToken) {
        wrappedNativeToken = _wrappedNativeToken;
    }

    /**
     * @dev It allows receiving native token transfers
     */
    receive() external payable {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Executes a bridge of assets using Hop Exchange
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param bridge Address of the bridge component (i.e. hopBridge or hopAMM)
     * @param deadline Deadline to be used when bridging to L2 in order to swap the corresponding hToken
     * @param relayer Only used when transfering from L1 to L2 if a 3rd party is relaying the transfer on the user's behalf
     * @param fee Fee to be sent to the bridge based on the source and destination chain (i.e. relayerFee or bonderFee)
     */
    function execute(
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        address bridge,
        uint256 deadline,
        address relayer,
        uint256 fee
    ) external {
        require(block.chainid != chainId, 'HOP_BRIDGE_SAME_CHAIN');
        require(recipient != address(0), 'HOP_BRIDGE_RECIPIENT_ZERO');

        bool toL2 = !_isL1(chainId);
        bool fromL1 = _isL1(block.chainid);

        uint256 preBalanceIn = IERC20(token).balanceOf(address(this));

        if (fromL1 && toL2)
            _bridgeFromL1ToL2(chainId, token, amountIn, minAmountOut, recipient, bridge, deadline, relayer, fee);
        else if (!fromL1 && toL2) {
            require(relayer == address(0), 'HOP_RELAYER_NOT_NEEDED');
            _bridgeFromL2ToL2(chainId, token, amountIn, minAmountOut, recipient, bridge, deadline, fee);
        } else if (!fromL1 && !toL2) {
            require(deadline == 0, 'HOP_DEADLINE_NOT_NEEDED');
            _bridgeFromL2ToL1(chainId, token, amountIn, minAmountOut, recipient, bridge, fee);
        } else revert('HOP_BRIDGE_OP_NOT_SUPPORTED');

        uint256 postBalanceIn = IERC20(token).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'HOP_BAD_TOKEN_IN_BALANCE');
    }

    /**
     * @dev Bridges assets from L1 to L2
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param hopBridge Address of the Hop bridge corresponding to the token to be bridged
     * @param deadline Deadline to be applied on L2 when swapping the hToken for the token to be bridged
     * @param relayer Only used if a 3rd party is relaying the transfer on the user's behalf
     * @param relayerFee Only used if a 3rd party is relaying the transfer on the user's behalf
     */
    function _bridgeFromL1ToL2(
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        address hopBridge,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) internal {
        require(deadline > block.timestamp, 'HOP_BRIDGE_INVALID_DEADLINE');

        uint256 value = _unwrapOrApproveTokens(hopBridge, token, amountIn);
        IHopL1Bridge(hopBridge).sendToL2{ value: value }(
            chainId,
            recipient,
            amountIn,
            minAmountOut,
            deadline,
            relayer,
            relayerFee
        );
    }

    /**
     * @dev Bridges assets from L2 to L1
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param hopAMM Address of the Hop AMM corresponding to the token to be bridged
     * @param bonderFee Must be computed using the Hop SDK or API
     */
    function _bridgeFromL2ToL1(
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        address hopAMM,
        uint256 bonderFee
    ) internal {
        uint256 value = _unwrapOrApproveTokens(hopAMM, token, amountIn);
        // No destination min amount nor deadline needed since there is no AMM on L1
        IHopL2AMM(hopAMM).swapAndSend{ value: value }(
            chainId,
            recipient,
            amountIn,
            bonderFee,
            minAmountOut,
            block.timestamp,
            0,
            0
        );
    }

    /**
     * @dev Bridges assets from L2 to L2
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain
     * @param recipient Address that will receive the tokens on the destination chain
     * @param hopAMM Address of the Hop AMM corresponding to the token to be bridged
     * @param deadline Deadline to be applied on the destination L2 when swapping the hToken for the token to be bridged
     * @param bonderFee Must be computed using the Hop SDK or API
     */
    function _bridgeFromL2ToL2(
        uint256 chainId,
        address token,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient,
        address hopAMM,
        uint256 deadline,
        uint256 bonderFee
    ) internal {
        require(deadline > block.timestamp, 'HOP_BRIDGE_INVALID_DEADLINE');

        uint256 intermediateMinAmountOut = amountIn - ((amountIn - minAmountOut) / 2);
        IHopL2AMM(hopAMM).swapAndSend{ value: _unwrapOrApproveTokens(hopAMM, token, amountIn) }(
            chainId,
            recipient,
            amountIn,
            bonderFee,
            intermediateMinAmountOut,
            block.timestamp,
            minAmountOut,
            deadline
        );
    }

    /**
     * @dev Unwraps or approves the given amount of tokens depending on the token being bridged
     * @param bridge Address of the bridge component to approve the tokens to
     * @param token Address of the token to be bridged
     * @param amount Amount of tokens to be bridged
     * @return value Value that must be used to perform a bridge op
     */
    function _unwrapOrApproveTokens(address bridge, address token, uint256 amount) internal returns (uint256 value) {
        if (token == wrappedNativeToken) {
            value = amount;
            IWrappedNativeToken(token).withdraw(amount);
        } else {
            value = 0;
            ERC20Helpers.approve(token, bridge, amount);
        }
    }

    /**
     * @dev Tells if a chain ID refers to L1 or not: currently only Ethereum Mainnet or Goerli
     * @param chainId ID of the chain being queried
     */
    function _isL1(uint256 chainId) internal pure returns (bool) {
        return chainId == MAINNET_CHAIN_ID || chainId == GOERLI_CHAIN_ID;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopL1Bridge {
    /**
     * @notice To send funds L1->L2, call the sendToL2 method on the L1 Bridge contract
     * @notice `amountOutMin` and `deadline` should be 0 when no swap is intended at the destination.
     * @notice `amount` is the total amount the user wants to send including the relayer fee
     * @dev Send tokens to a supported layer-2 to mint hToken and optionally swap the hToken in the
     * AMM at the destination.
     * @param chainId The chainId of the destination chain
     * @param recipient The address receiving funds at the destination
     * @param amount The amount being sent
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     * @param relayer The address of the relayer at the destination.
     * @param relayerFee The amount distributed to the relayer at the destination. This is subtracted from the `amount`.
     */
    function sendToL2(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopL2AMM {
    function hToken() external view returns (address);

    function exchangeAddress() external view returns (address);

    /**
     * @notice To send funds L2->L1 or L2->L2, call the swapAndSend method on the L2 AMM Wrapper contract
     * @dev Do not set destinationAmountOutMin and destinationDeadline when sending to L1 because there is no AMM on L1,
     * otherwise the calculated transferId will be invalid and the transfer will be unbondable. These parameters should
     * be set to 0 when sending to L1.
     * @param amount is the amount the user wants to send plus the Bonder fee
     */
    function swapAndSend(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        uint256 destinationAmountOutMin,
        uint256 destinationDeadline
    ) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IWormhole {
    function transferTokensWithRelay(
        address token,
        uint256 amount,
        uint256 toNativeTokenAmount,
        uint16 targetChain,
        bytes32 targetRecipientWallet
    ) external payable returns (uint64 messageSequence);

    function relayerFee(uint16 chainId, address token) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IWormhole.sol';

/**
 * @title WormholeConnector
 * @dev Interfaces with Wormhole to bridge tokens through CCTP
 */
contract WormholeConnector {
    // List of Wormhole network IDs
    uint16 private constant ETHEREUM_WORMHOLE_NETWORK_ID = 2;
    uint16 private constant POLYGON_WORMHOLE_NETWORK_ID = 5;
    uint16 private constant ARBITRUM_WORMHOLE_NETWORK_ID = 23;
    uint16 private constant OPTIMISM_WORMHOLE_NETWORK_ID = 24;
    uint16 private constant BSC_WORMHOLE_NETWORK_ID = 4;
    uint16 private constant FANTOM_WORMHOLE_NETWORK_ID = 10;
    uint16 private constant AVALANCHE_WORMHOLE_NETWORK_ID = 6;

    // List of chain IDs supported by Wormhole
    uint256 private constant ETHEREUM_ID = 1;
    uint256 private constant POLYGON_ID = 137;
    uint256 private constant ARBITRUM_ID = 42161;
    uint256 private constant OPTIMISM_ID = 10;
    uint256 private constant BSC_ID = 56;
    uint256 private constant FANTOM_ID = 250;
    uint256 private constant AVALANCHE_ID = 43114;

    // Reference to the Wormhole's CircleRelayer contract of the source chain
    IWormhole public immutable wormholeCircleRelayer;

    /**
     * @dev Creates a new Wormhole connector
     * @param _wormholeCircleRelayer Address of the Wormhole's CircleRelayer contract for the source chain
     */
    constructor(address _wormholeCircleRelayer) {
        wormholeCircleRelayer = IWormhole(_wormholeCircleRelayer);
    }

    /**
     * @dev Executes a bridge of assets using Wormhole's CircleRelayer integration
     * @param chainId ID of the destination chain
     * @param token Address of the token to be bridged
     * @param amountIn Amount of tokens to be bridged
     * @param minAmountOut Minimum amount of tokens willing to receive on the destination chain after relayer fees
     * @param recipient Address that will receive the tokens on the destination chain
     */
    function execute(uint256 chainId, address token, uint256 amountIn, uint256 minAmountOut, address recipient)
        external
    {
        require(block.chainid != chainId, 'WORMHOLE_BRIDGE_SAME_CHAIN');
        require(recipient != address(0), 'WORMHOLE_BRIDGE_RECIPIENT_ZERO');

        uint16 wormholeNetworkId = _getWormholeNetworkId(chainId);
        uint256 relayerFee = wormholeCircleRelayer.relayerFee(wormholeNetworkId, token);
        require(relayerFee <= amountIn, 'WORMHOLE_RELAYER_FEE_GT_AMT_IN');
        require(minAmountOut <= amountIn - relayerFee, 'WORMHOLE_MIN_AMOUNT_OUT_TOO_BIG');

        uint256 preBalanceIn = IERC20(token).balanceOf(address(this));

        ERC20Helpers.approve(token, address(wormholeCircleRelayer), amountIn);
        wormholeCircleRelayer.transferTokensWithRelay(
            token,
            amountIn,
            0, // don't swap to native token
            wormholeNetworkId,
            bytes32(uint256(uint160(recipient))) // convert from address to bytes32
        );

        uint256 postBalanceIn = IERC20(token).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'WORMHOLE_BAD_TOKEN_IN_BALANCE');
    }

    /**
     * @dev Tells the Wormhole network ID based on a chain ID
     * @param chainId ID of the chain being queried
     * @return Wormhole network ID associated to the requested chain ID
     */
    function _getWormholeNetworkId(uint256 chainId) internal pure returns (uint16) {
        if (chainId == ETHEREUM_ID) return ETHEREUM_WORMHOLE_NETWORK_ID;
        else if (chainId == POLYGON_ID) return POLYGON_WORMHOLE_NETWORK_ID;
        else if (chainId == ARBITRUM_ID) return ARBITRUM_WORMHOLE_NETWORK_ID;
        else if (chainId == OPTIMISM_ID) return OPTIMISM_WORMHOLE_NETWORK_ID;
        else if (chainId == BSC_ID) return BSC_WORMHOLE_NETWORK_ID;
        else if (chainId == FANTOM_ID) return FANTOM_WORMHOLE_NETWORK_ID;
        else if (chainId == AVALANCHE_ID) return AVALANCHE_WORMHOLE_NETWORK_ID;
        else revert('WORMHOLE_UNKNOWN_CHAIN_ID');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import './ICvxPool.sol';
import './ICvxBooster.sol';

/**
 * @title ConvexConnector
 */
contract ConvexConnector {
    using FixedPoint for uint256;

    // Convex booster
    ICvxBooster public immutable booster;

    /**
     * @dev Creates a new Convex connector
     */
    constructor(ICvxBooster _booster) {
        booster = _booster;
    }

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCurvePool(address cvxPool) public view returns (address) {
        uint256 poolId = ICvxPool(cvxPool).convexPoolId();
        (address pool, , , , ) = booster.poolInfo(poolId);
        return pool;
    }

    /**
     * @dev Finds the Curve pool address associated to a Convex pool
     */
    function getCvxPool(address curvePool) public view returns (address) {
        (, ICvxPool pool) = _findCvxPoolInfo(curvePool);
        return address(pool);
    }

    /**
     * @dev Claims Convex pool rewards for a Curve pool
     */
    function claim(address cvxPool) external returns (address[] memory tokens, uint256[] memory amounts) {
        IERC20 crv = IERC20(ICvxPool(cvxPool).crv());

        uint256 initialCrvBalance = crv.balanceOf(address(this));
        ICvxPool(cvxPool).getReward(address(this));
        uint256 finalCrvBalance = crv.balanceOf(address(this));

        amounts = new uint256[](1);
        amounts[0] = finalCrvBalance - initialCrvBalance;

        tokens = new address[](1);
        tokens[0] = address(crv);
    }

    /**
     * @dev Deposits Curve pool tokens into Convex
     * @param curvePool Address of the Curve pool to join Convex
     * @param amount Amount of Curve pool tokens to be deposited into Convex
     */
    function join(address curvePool, uint256 amount) external returns (uint256) {
        if (amount == 0) return 0;
        (uint256 poolId, ICvxPool cvxPool) = _findCvxPoolInfo(curvePool);

        uint256 initialCvxPoolTokenBalance = cvxPool.balanceOf(address(this));
        IERC20(curvePool).approve(address(booster), amount);
        require(booster.deposit(poolId, amount), 'CONVEX_BOOSTER_DEPOSIT_FAILED');
        uint256 finalCvxPoolTokenBalance = cvxPool.balanceOf(address(this));
        return finalCvxPoolTokenBalance - initialCvxPoolTokenBalance;
    }

    /**
     * @dev Withdraws Curve pool tokens from Convex
     * @param cvxPool Address of the Convex pool to exit from Convex
     * @param amount Amount of Convex tokens to be withdrawn
     */
    function exit(address cvxPool, uint256 amount) external returns (uint256) {
        if (amount == 0) return 0;
        address curvePool = getCurvePool(cvxPool);

        // Unstake from Convex
        uint256 initialPoolTokenBalance = IERC20(curvePool).balanceOf(address(this));
        require(ICvxPool(cvxPool).withdraw(amount, true), 'CONVEX_CVX_POOL_WITHDRAW_FAILED');
        uint256 finalPoolTokenBalance = IERC20(curvePool).balanceOf(address(this));
        return finalPoolTokenBalance - initialPoolTokenBalance;
    }

    /**
     * @dev Finds the Convex pool information associated to the given Curve pool
     */
    function _findCvxPoolInfo(address curvePool) internal view returns (uint256 poolId, ICvxPool cvxPool) {
        for (uint256 i = 0; i < booster.poolLength(); i++) {
            (address lp, , address rewards, bool shutdown, ) = booster.poolInfo(i);
            if (lp == curvePool && !shutdown) {
                return (i, ICvxPool(rewards));
            }
        }
        revert('CONVEX_CVX_POOL_NOT_FOUND');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface ICvxBooster {
    function poolLength() external view returns (uint256);

    function poolInfo(uint256 i)
        external
        view
        returns (address lpToken, address gauge, address rewards, bool shutdown, address factory);

    function deposit(uint256 pid, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICvxPool is IERC20 {
    function crv() external view returns (address);

    function convexPoolId() external view returns (uint256);

    function getReward(address account) external;

    function withdraw(uint256 amount, bool claim) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/math/FixedPoint.sol';

import './I2CrvPool.sol';

/**
 * @title Curve2CrvConnector
 */
contract Curve2CrvConnector {
    using FixedPoint for uint256;

    /**
     * @dev Adds liquidity to the 2CRV pool
     * @param pool Address of the 2CRV pool to join
     * @param tokenIn Address of the token to join the 2CRV pool
     * @param amountIn Amount of tokens to join the 2CRV pool
     * @param slippage Slippage value to be used to compute the desired min amount out of pool tokens
     */
    function join(address pool, address tokenIn, uint256 amountIn, uint256 slippage) external returns (uint256) {
        if (amountIn == 0) return 0;
        require(slippage <= FixedPoint.ONE, '2CRV_SLIPPAGE_ABOVE_ONE');
        (uint256 tokenIndex, uint256 tokenScale) = _findTokenInfo(pool, tokenIn);

        // Compute min amount out
        uint256 expectedAmountOut = (amountIn * tokenScale).divUp(I2CrvPool(pool).get_virtual_price());
        uint256 minAmountOut = expectedAmountOut.mulUp(FixedPoint.ONE - slippage);

        // Join pool
        uint256 initialPoolTokenBalance = I2CrvPool(pool).balanceOf(address(this));
        IERC20(tokenIn).approve(address(pool), amountIn);
        uint256[2] memory amounts;
        amounts[tokenIndex] = amountIn;
        I2CrvPool(pool).add_liquidity(amounts, minAmountOut);
        uint256 finalPoolTokenBalance = I2CrvPool(pool).balanceOf(address(this));
        return finalPoolTokenBalance - initialPoolTokenBalance;
    }

    /**
     * @dev Removes liquidity from 2CRV pool
     * @param pool Address of the 2CRV pool to exit
     * @param amountIn Amount of pool tokens to exit from the 2CRV pool
     * @param tokenOut Address of the token to exit the pool
     * @param slippage Slippage value to be used to compute the desired min amount out of tokens
     */
    function exit(address pool, uint256 amountIn, address tokenOut, uint256 slippage)
        external
        returns (uint256 amountOut)
    {
        if (amountIn == 0) return 0;
        require(slippage <= FixedPoint.ONE, '2CRV_INVALID_SLIPPAGE');
        (uint256 tokenIndex, uint256 tokenScale) = _findTokenInfo(pool, tokenOut);

        // Compute min amount out
        uint256 expectedAmountOut = amountIn.mulUp(I2CrvPool(pool).get_virtual_price()) / tokenScale;
        uint256 minAmountOut = expectedAmountOut.mulUp(FixedPoint.ONE - slippage);

        // Exit pool
        uint256 initialTokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        I2CrvPool(pool).remove_liquidity_one_coin(amountIn, int128(int256(tokenIndex)), minAmountOut);
        uint256 finalTokenOutBalance = IERC20(tokenOut).balanceOf(address(this));
        return finalTokenOutBalance - initialTokenOutBalance;
    }

    /**
     * @dev Finds the index and scale factor of a token in the 2CRV pool
     */
    function _findTokenInfo(address pool, address token) internal view returns (uint256 index, uint256 scale) {
        for (uint256 i = 0; true; i++) {
            try I2CrvPool(pool).coins(i) returns (address coin) {
                if (token == coin) {
                    uint256 decimals = IERC20Metadata(token).decimals();
                    require(decimals <= 18, '2CRV_TOKEN_ABOVE_18_DECIMALS');
                    return (i, 10**(18 - decimals));
                }
            } catch {
                revert('2CRV_TOKEN_NOT_FOUND');
            }
        }
        revert('2CRV_TOKEN_NOT_FOUND');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// solhint-disable func-name-mixedcase

interface I2CrvPool is IERC20 {
    function get_virtual_price() external view returns (uint256);

    function coins(uint256 index) external view returns (address);

    function exchange(int128 i, int128 j, uint256 dx, uint256 minDy) external;

    function add_liquidity(uint256[2] memory amountsIn, uint256 minAmountOut) external returns (uint256);

    function remove_liquidity_one_coin(uint256 amountIn, int128 index, uint256 minAmountOut) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IAggregationExecutor {
    /// @notice propagates information about original msg.sender and executes arbitrary data
    function execute(address msgSender) external payable;
}

interface IOneInchV5AggregationRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address payable srcReceiver;
        address payable dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
    }

    /// @notice Performs a swap, delegating all calls encoded in `data` to `executor`. See tests for usage examples
    /// @dev router keeps 1 wei of every token on the contract balance for gas optimisations reasons. This affects first swap of every token by leaving 1 wei on the contract.
    /// @param executor Aggregation executor that executes calls described in `data`
    /// @param desc Swap description
    /// @param permit Should contain valid permit that can be used in `IERC20Permit.permit` calls.
    /// @param data Encoded calls that `caller` should execute in between of swaps
    /// @return returnAmount Resulting token amount
    /// @return spentAmount Source token amount
    function swap(
        IAggregationExecutor executor,
        SwapDescription calldata desc,
        bytes calldata permit,
        bytes calldata data
    ) external payable returns (uint256 returnAmount, uint256 spentAmount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IOneInchV5AggregationRouter.sol';

/**
 * @title OneInchV5Connector
 * @dev Interfaces with 1inch V5 to swap tokens
 */
contract OneInchV5Connector {
    // Reference to 1inch aggregation router v5
    IOneInchV5AggregationRouter public immutable oneInchV5Router;

    /**
     * @dev Creates a new OneInchV5Connector contract
     * @param _oneInchV5Router 1inch aggregation router v5 reference
     */
    constructor(address _oneInchV5Router) {
        oneInchV5Router = IOneInchV5AggregationRouter(_oneInchV5Router);
    }

    /**
     * @dev Executes a token swap in 1Inch V5
     * @param tokenIn Token to be sent
     * @param tokenOut Token to received
     * @param amountIn Amount of token in to be swapped
     * @param minAmountOut Minimum amount of token out willing to receive
     * @param data Calldata to be sent to the 1inch aggregation router
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut)
    {
        require(tokenIn != tokenOut, '1INCH_V5_SWAP_SAME_TOKEN');

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        ERC20Helpers.approve(tokenIn, address(oneInchV5Router), amountIn);
        Address.functionCall(address(oneInchV5Router), data, '1INCH_V5_SWAP_FAILED');

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, '1INCH_V5_BAD_TOKEN_IN_BALANCE');

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        require(amountOut >= minAmountOut, '1INCH_V5_MIN_AMOUNT_OUT');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IHopDex.sol';

/**
 * @title HopSwapConnector
 * @dev Interfaces with Hop to swap tokens
 */
contract HopSwapConnector {
    /**
     * @dev Executes a token swap in Hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopDexAddress Address of the Hop dex to be used
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, address hopDexAddress)
        external
        returns (uint256 amountOut)
    {
        require(tokenIn != tokenOut, 'HOP_SWAP_SAME_TOKEN');
        require(hopDexAddress != address(0), 'HOP_DEX_ADDRESS_ZERO');

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        IHopDex hopDex = IHopDex(hopDexAddress);
        uint8 tokenInIndex = hopDex.getTokenIndex(tokenIn);
        uint8 tokenOutIndex = hopDex.getTokenIndex(tokenOut);

        ERC20Helpers.approve(tokenIn, hopDexAddress, amountIn);
        hopDex.swap(tokenInIndex, tokenOutIndex, amountIn, minAmountOut, block.timestamp);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'HOP_BAD_TOKEN_IN_BALANCE');

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        require(amountOut >= minAmountOut, 'HOP_MIN_AMOUNT_OUT');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopDex {
    function getTokenIndex(address) external view returns (uint8);

    function swap(uint8 tokenIndexFrom, uint8 tokenIndexTo, uint256 dx, uint256 minDy, uint256 deadline)
        external
        returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.8.0;

interface IHopL2Amm {
    function hToken() external view returns (address);

    function exchangeAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IParaswapV5Augustus {
    function getTokenTransferProxy() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IParaswapV5Augustus.sol';

/**
 * @title ParaswapV5Connector
 * @dev Interfaces with Paraswap V5 to swap tokens
 */
contract ParaswapV5Connector {
    // Reference to Paraswap V5 Augustus swapper
    IParaswapV5Augustus public immutable paraswapV5Augustus;

    /**
     * @dev Creates a new ParaswapV5Connector contract
     * @param _paraswapV5Augustus Paraswap V5 augusts reference
     */
    constructor(address _paraswapV5Augustus) {
        paraswapV5Augustus = IParaswapV5Augustus(_paraswapV5Augustus);
    }

    /**
     * @dev Executes a token swap in Paraswap V5
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param data Calldata to be sent to the Augusuts swapper
     */
    function execute(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut)
    {
        require(tokenIn != tokenOut, 'PARASWAP_V5_SWAP_SAME_TOKEN');

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        address tokenTransferProxy = paraswapV5Augustus.getTokenTransferProxy();
        ERC20Helpers.approve(tokenIn, tokenTransferProxy, amountIn);
        Address.functionCall(address(paraswapV5Augustus), data, 'PARASWAP_V5_SWAP_FAILED');

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'PARASWAP_V5_BAD_TOKEN_IN_BALANCE');

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        require(amountOut >= minAmountOut, 'PARASWAP_V5_MIN_AMOUNT_OUT');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.6.2;

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

import '@mimic-fi/v3-helpers/contracts/utils/Arrays.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';

/**
 * @title UniswapV2Connector
 * @dev Interfaces with Uniswap V2 to swap tokens
 */
contract UniswapV2Connector {
    // Reference to UniswapV2 router
    IUniswapV2Router02 public immutable uniswapV2Router;

    /**
     * @dev Initializes the UniswapV2Connector contract
     * @param _uniswapV2Router Uniswap V2 router reference
     */
    constructor(address _uniswapV2Router) {
        uniswapV2Router = IUniswapV2Router02(_uniswapV2Router);
    }

    /**
     * @dev Executes a token swap in Uniswap V2
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory hopTokens
    ) external returns (uint256 amountOut) {
        require(tokenIn != tokenOut, 'UNI_V2_SWAP_SAME_TOKEN');

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        ERC20Helpers.approve(tokenIn, address(uniswapV2Router), amountIn);
        hopTokens.length == 0
            ? _singleSwap(tokenIn, tokenOut, amountIn, minAmountOut)
            : _batchSwap(tokenIn, tokenOut, amountIn, minAmountOut, hopTokens);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'UNI_V2_BAD_TOKEN_IN_BALANCE');

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        require(amountOut >= minAmountOut, 'UNI_V2_MIN_AMOUNT_OUT');
    }

    /**
     * @dev Swap two tokens through UniswapV2 using a single hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     */
    function _singleSwap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut)
        internal
        returns (uint256[] memory)
    {
        address factory = uniswapV2Router.factory();
        address[] memory tokens = Arrays.from(tokenIn, tokenOut);
        _validatePool(factory, tokenIn, tokenOut);
        return uniswapV2Router.swapExactTokensForTokens(amountIn, minAmountOut, tokens, address(this), block.timestamp);
    }

    /**
     * @dev Swap two tokens through UniswapV2 using a multi hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of the first token in the path to be swapped
     * @param minAmountOut Minimum amount of the last token in the path willing to receive
     * @param hopTokens List of hop-tokens between tokenIn and tokenOut
     */
    function _batchSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        address[] memory hopTokens
    ) internal returns (uint256[] memory) {
        address factory = uniswapV2Router.factory();
        address[] memory tokens = Arrays.from(tokenIn, hopTokens, tokenOut);
        for (uint256 i = 0; i < tokens.length - 1; i++) {
            _validatePool(factory, tokens[i], tokens[i + 1]);
        }
        return uniswapV2Router.swapExactTokensForTokens(amountIn, minAmountOut, tokens, address(this), block.timestamp);
    }

    /**
     * @dev Validates that there is a pool created for tokenA and tokenB
     * @param factory UniswapV2 factory to check against
     * @param tokenA First token of the pair
     * @param tokenB Second token of the pair
     */
    function _validatePool(address factory, address tokenA, address tokenB) private view {
        address pool = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        require(pool != address(0), 'INVALID_UNISWAP_POOL');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IUniswapV3PeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.5;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3SwapRouter {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '@mimic-fi/v3-helpers/contracts/utils/Arrays.sol';
import '@mimic-fi/v3-helpers/contracts/utils/BytesHelpers.sol';
import '@mimic-fi/v3-helpers/contracts/utils/ERC20Helpers.sol';

import './IUniswapV3Factory.sol';
import './IUniswapV3SwapRouter.sol';
import './IUniswapV3PeripheryImmutableState.sol';

/**
 * @title UniswapV3Connector
 * @dev Interfaces with Uniswap V3 to swap tokens
 */
contract UniswapV3Connector {
    using BytesHelpers for bytes;

    // Reference to UniswapV3 router
    IUniswapV3SwapRouter public immutable uniswapV3Router;

    /**
     * @dev Initializes the UniswapV3Connector contract
     * @param _uniswapV3Router Uniswap V3 router reference
     */
    constructor(address _uniswapV3Router) {
        uniswapV3Router = IUniswapV3SwapRouter(_uniswapV3Router);
    }

    /**
     * @dev Executes a token swap in Uniswap V3
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param fee Fee to be used
     * @param hopTokens Optional list of hop-tokens between tokenIn and tokenOut, only used for multi-hops
     * @param hopFees Optional list of hop-fees between tokenIn and tokenOut, only used for multi-hops
     */
    function execute(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) external returns (uint256 amountOut) {
        require(tokenIn != tokenOut, 'UNI_V3_SWAP_SAME_TOKEN');
        require(hopTokens.length == hopFees.length, 'UNI_V3_BAD_HOP_TOKENS_FEES_LEN');

        uint256 preBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 preBalanceOut = IERC20(tokenOut).balanceOf(address(this));

        ERC20Helpers.approve(tokenIn, address(uniswapV3Router), amountIn);
        hopTokens.length == 0
            ? _singleSwap(tokenIn, tokenOut, amountIn, minAmountOut, fee)
            : _batchSwap(tokenIn, tokenOut, amountIn, minAmountOut, fee, hopTokens, hopFees);

        uint256 postBalanceIn = IERC20(tokenIn).balanceOf(address(this));
        require(postBalanceIn >= preBalanceIn - amountIn, 'UNI_V3_BAD_TOKEN_IN_BALANCE');

        uint256 postBalanceOut = IERC20(tokenOut).balanceOf(address(this));
        amountOut = postBalanceOut - preBalanceOut;
        require(amountOut >= minAmountOut, 'UNI_V3_MIN_AMOUNT_OUT');
    }

    /**
     * @dev Swap two tokens through UniswapV3 using a single hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of tokenIn being swapped
     * @param minAmountOut Minimum amount of tokenOut willing to receive
     * @param fee Fee to be used
     */
    function _singleSwap(address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, uint24 fee)
        internal
        returns (uint256 amountOut)
    {
        _validatePool(_uniswapV3Factory(), tokenIn, tokenOut, fee);

        IUniswapV3SwapRouter.ExactInputSingleParams memory input;
        input.tokenIn = tokenIn;
        input.tokenOut = tokenOut;
        input.fee = fee;
        input.recipient = address(this);
        input.deadline = block.timestamp;
        input.amountIn = amountIn;
        input.amountOutMinimum = minAmountOut;
        input.sqrtPriceLimitX96 = 0;
        return uniswapV3Router.exactInputSingle(input);
    }

    /**
     * @dev Swap two tokens through UniswapV3 using a multi hop
     * @param tokenIn Token being sent
     * @param tokenOut Token being received
     * @param amountIn Amount of the first token in the path to be swapped
     * @param minAmountOut Minimum amount of the last token in the path willing to receive
     * @param fee Fee to be used
     * @param hopTokens List of hop-tokens between tokenIn and tokenOut
     * @param hopFees List of hop-fees between tokenIn and tokenOut
     */
    function _batchSwap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint24 fee,
        address[] memory hopTokens,
        uint24[] memory hopFees
    ) internal returns (uint256 amountOut) {
        address factory = _uniswapV3Factory();
        address[] memory tokens = Arrays.from(tokenIn, hopTokens, tokenOut);
        uint24[] memory fees = Arrays.from(fee, hopFees);

        // No need for checked math since we are using it to compute indexes manually, always within boundaries
        for (uint256 i = 0; i < fees.length; i++) {
            _validatePool(factory, tokens[i], tokens[i + 1], fees[i]);
        }

        IUniswapV3SwapRouter.ExactInputParams memory input;
        input.path = _encodePoolPath(tokens, fees);
        input.amountIn = amountIn;
        input.amountOutMinimum = minAmountOut;
        input.recipient = address(this);
        input.deadline = block.timestamp;
        return uniswapV3Router.exactInput(input);
    }

    /**
     * @dev Tells the Uniswap V3 factory contract address
     * @return Address of the Uniswap V3 factory contract
     */
    function _uniswapV3Factory() internal view returns (address) {
        return IUniswapV3PeripheryImmutableState(address(uniswapV3Router)).factory();
    }

    /**
     * @dev Validates that there is a pool created for tokenA and tokenB with a requested fee
     * @param factory UniswapV3 factory to check against
     * @param tokenA One of the tokens in the pool
     * @param tokenB The other token in the pool
     * @param fee Fee used by the pool
     */
    function _validatePool(address factory, address tokenA, address tokenB, uint24 fee) internal view {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(IUniswapV3Factory(factory).getPool(token0, token1, fee) != address(0), 'UNI_V3_INVALID_POOL_FEE');
    }

    /**
     * @dev Encodes a path of tokens with their corresponding fees
     * @param tokens List of tokens to be encoded
     * @param fees List of fees to use for each token pair
     */
    function _encodePoolPath(address[] memory tokens, uint24[] memory fees) internal pure returns (bytes memory path) {
        path = new bytes(0);
        for (uint256 i = 0; i < fees.length; i++) path = path.concat(tokens[i]).concat(fees[i]);
        path = path.concat(tokens[fees.length]);
    }
}