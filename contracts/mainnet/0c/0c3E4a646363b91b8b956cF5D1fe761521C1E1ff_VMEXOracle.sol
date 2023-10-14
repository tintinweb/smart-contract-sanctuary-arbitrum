// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

// SPDX-License-Identifier: GPL-3.0-or-later

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BConst.sol

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

library BConst {
  uint public constant BONE = 10**18;

  uint public constant MIN_BOUND_TOKENS = 2;
  uint public constant MAX_BOUND_TOKENS = 8;

  uint public constant MIN_FEE = BONE / 10**6;
  uint public constant MAX_FEE = BONE / 10;
  uint public constant EXIT_FEE = 0;

  uint public constant MIN_WEIGHT = BONE;
  uint public constant MAX_WEIGHT = BONE * 50;
  uint public constant MAX_TOTAL_WEIGHT = BONE * 50;
  uint public constant MIN_BALANCE = BONE / 10**12;

  uint public constant INIT_POOL_SUPPLY = BONE * 100;

  uint public constant MIN_BPOW_BASE = 1 wei;
  uint public constant MAX_BPOW_BASE = (2 * BONE) - 1 wei;
  uint public constant BPOW_PRECISION = BONE / 10**10;

  uint public constant MAX_IN_RATIO = BONE / 2;
  uint public constant MAX_OUT_RATIO = (BONE / 3) + 1 wei;
}

// SPDX-License-Identifier: GPL-3.0-or-later

// https://github.com/balancer-labs/balancer-core/blob/master/contracts/BNum.sol

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

import {BConst} from './BConst.sol';

library BNum {
  function btoi(uint a) internal pure returns (uint) {
    return a / BConst.BONE;
  }

  function bfloor(uint a) internal pure returns (uint) {
    return btoi(a) * BConst.BONE;
  }

  function badd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, 'ERR_ADD_OVERFLOW');
    return c;
  }

  function bsub(uint a, uint b) internal pure returns (uint) {
    (uint c, bool flag) = bsubSign(a, b);
    require(!flag, 'ERR_SUB_UNDERFLOW');
    return c;
  }

  function bsubSign(uint a, uint b) internal pure returns (uint, bool) {
    if (a >= b) {
      return (a - b, false);
    } else {
      return (b - a, true);
    }
  }

  function bmul(uint a, uint b) internal pure returns (uint) {
    uint c0 = a * b;
    require(a == 0 || c0 / a == b, 'ERR_MUL_OVERFLOW');
    uint c1 = c0 + (BConst.BONE / 2);
    require(c1 >= c0, 'ERR_MUL_OVERFLOW');
    uint c2 = c1 / BConst.BONE;
    return c2;
  }

  function bdiv(uint a, uint b) internal pure returns (uint) {
    require(b != 0, 'ERR_DIV_ZERO');
    uint c0 = a * BConst.BONE;
    require(a == 0 || c0 / a == BConst.BONE, 'ERR_DIV_INTERNAL'); // bmul overflow
    uint c1 = c0 + (b / 2);
    require(c1 >= c0, 'ERR_DIV_INTERNAL'); //  badd require
    uint c2 = c1 / b;
    return c2;
  }

  // DSMath.wpow
  function bpowi(uint a, uint n) internal pure returns (uint) {
    uint z = n % 2 != 0 ? a : BConst.BONE;

    for (n /= 2; n != 0; n /= 2) {
      a = bmul(a, a);

      if (n % 2 != 0) {
        z = bmul(z, a);
      }
    }
    return z;
  }

  // Compute b^(e.w) by splitting it into (b^e)*(b^0.w).
  // Use `bpowi` for `b^e` and `bpowK` for k iterations
  // of approximation of b^0.w
  function bpow(uint base, uint exp) internal pure returns (uint) {
    require(base >= BConst.MIN_BPOW_BASE, 'ERR_BPOW_BASE_TOO_LOW');
    require(base <= BConst.MAX_BPOW_BASE, 'ERR_BPOW_BASE_TOO_HIGH');

    uint whole = bfloor(exp);
    uint remain = bsub(exp, whole);

    uint wholePow = bpowi(base, btoi(whole));

    if (remain == 0) {
      return wholePow;
    }

    uint partialResult = bpowApprox(base, remain, BConst.BPOW_PRECISION);
    return bmul(wholePow, partialResult);
  }

  function bpowApprox(
    uint base,
    uint exp,
    uint precision
  ) internal pure returns (uint) {
    // term 0:
    uint a = exp;
    (uint x, bool xneg) = bsubSign(base, BConst.BONE);
    uint term = BConst.BONE;
    uint sum = term;
    bool negative = false;

    // term(k) = numer / denom
    //         = (product(a - i - 1, i=1-->k) * x^k) / (k!)
    // each iteration, multiply previous term by (a-(k-1)) * x / k
    // continue until term is less than precision
    for (uint i = 1; term >= precision; ++i) {
      uint bigK = i * BConst.BONE;
      (uint c, bool cneg) = bsubSign(a, bsub(bigK, BConst.BONE));
      term = bmul(term, bmul(c, x));
      term = bdiv(term, bigK);
      if (term == 0) break;

      if (xneg) negative = !negative;
      if (cneg) negative = !negative;
      if (negative) {
        sum = bsub(sum, term);
      } else {
        sum = badd(sum, term);
      }
    }

    return sum;
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

pragma solidity >=0.7.0 <0.9.0;

import "../../interfaces/IVault.sol";

library VaultReentrancyLib {
    /**
     * @dev Ensure we are not in a Vault context when this function is called, by attempting a no-op internal
     * balance operation. If we are already in a Vault transaction (e.g., a swap, join, or exit), the Vault's
     * reentrancy protection will cause this function to revert.
     *
     * The exact function call doesn't really matter: we're just trying to trigger the Vault reentrancy check
     * (and not hurt anything in case it works). An empty operation array with no specific operation at all works
     * for that purpose, and is also the least expensive in terms of gas and bytecode size.
     *
     * Call this at the top of any function that can cause a state change in a pool and is either public itself,
     * or called by a public function *outside* a Vault operation (e.g., join, exit, or swap).
     *
     * If this is *not* called in functions that are vulnerable to the read-only reentrancy issue described
     * here (https://forum.balancer.fi/t/reentrancy-vulnerability-scope-expanded/4345), those functions are unsafe,
     * and subject to manipulation that may result in loss of funds.
     */
    function ensureNotInVaultContext(IVault vault) internal {
        IVault.UserBalanceOp[] memory noop = new IVault.UserBalanceOp[](0);
        vault.manageUserBalance(noop);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

	function decimals() external view returns (uint8); 

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20} from "./IERC20.sol";

interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "./IERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";
import {IERC20Permit} from "./governance/IERC20Permit.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {} 1 {} {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break       
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := shl(add(div(r, 3), lt(0xf, shr(r, x))), 0xff)
            z := div(z, byte(mod(r, 3), shl(232, 0x7f624b)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(
                        shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001),
                        0x3fffff
                    )
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for { let w := not(0) } 1 {} {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) { break }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface IAssetMappings {
    event AssetDataSet(
        address indexed asset,
        uint8 underlyingAssetDecimals,
        string underlyingAssetSymbol,
        uint256 supplyCap,
        uint256 borrowCap,
        uint256 baseLTV,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 borrowFactor,
        address defaultInterestRateStrategyAddress,
        bool borrowingEnabled,
        uint256 VMEXReserveFactor
    );

    event ConfiguredAssetMapping(
        address indexed asset,
        uint256 baseLTV,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 supplyCap,
        uint256 borrowCap,
        uint256 borrowFactor
    );

    event AddedInterestRateStrategyAddress(
        address indexed asset,
        address indexed defaultInterestRateStrategyAddress
    );

    event VMEXReserveFactorChanged(address indexed asset, uint256 factor);

    event BorrowingEnabledChanged(address indexed asset, bool borrowingEnabled);

    struct AddAssetMappingInput {
        address asset;
        address defaultInterestRateStrategyAddress;
        uint128 supplyCap; //can get up to 10^38. Good enough.
        uint128 borrowCap; //can get up to 10^38. Good enough.
        uint64 baseLTV; // % of value of collateral that can be used to borrow. "Collateral factor." 64 bits
        uint64 liquidationThreshold; //if this is zero, then disabled as collateral. 64 bits
        uint64 liquidationBonus; // 64 bits
        uint64 borrowFactor; // borrowFactor * baseLTV * value = truly how much you can borrow of an asset. 64 bits

        bool borrowingEnabled;
        uint8 assetType; //to choose what oracle to use
        uint64 VMEXReserveFactor;
        string tokenSymbol;
    }

    function getVMEXReserveFactor(
        address asset
    ) external view returns(uint256);

    function setVMEXReserveFactor(
        address asset,
        uint256 reserveFactor
    ) external;

    function setBorrowingEnabled(
        address asset,
        bool borrowingEnabled
    ) external;

    function addAssetMapping(
        AddAssetMappingInput[] memory input
    ) external;

    function configureAssetMapping(
        address asset,//20
        uint64 baseLTV, //28
        uint64 liquidationThreshold, //36 --> 1 word, 8 bytes
        uint64 liquidationBonus, //1 word, 16 bytes
        uint128 supplyCap, //1 word, 32 bytes -> 1 word
        uint128 borrowCap, //2 words, 16 bytes
        uint64 borrowFactor //2 words, 24 bytes --> 3 words total
    ) external;

    function setAssetAllowed(address asset, bool isAllowed) external;

    function isAssetInMappings(address asset) view external returns (bool);

    function getNumApprovedTokens() view external returns (uint256);

    function getAllApprovedTokens() view external returns (address[] memory tokens);

    function getAssetMapping(address asset) view external returns(DataTypes.AssetData memory);

    function getAssetBorrowable(address asset) view external returns (bool);

    function getAssetCollateralizable(address asset) view external returns (bool);

    function getInterestRateStrategyAddress(address asset, uint64 trancheId) view external returns(address);

    function getDefaultInterestRateStrategyAddress(address asset) view external returns(address);

    function getAssetType(address asset) view external returns(DataTypes.ReserveAssetType);

    function getSupplyCap(address asset) view external returns(uint256);

    function getBorrowCap(address asset) view external returns(uint256);

    function getBorrowFactor(address asset) view external returns(uint256);

    function getAssetAllowed(address asset) view external returns(bool);

    function setInterestRateStrategyAddress(address asset, address strategy) external;

    function setCurveMetadata(address[] calldata asset, DataTypes.CurveMetadata[] calldata vars) external;

    function getCurveMetadata(address asset) external view returns (DataTypes.CurveMetadata memory);

    function getBeethovenMetadata(address asset) external view returns (DataTypes.BeethovenMetadata memory);


    function getParams(address asset, uint64 trancheId)
        external view
        returns (
            uint256 baseLTV,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 underlyingAssetDecimals,
            uint256 borrowFactor
        );

    function getDefaultCollateralParams(address asset)
        external view
        returns (
            uint64 baseLTV,
            uint64 liquidationThreshold,
            uint64 liquidationBonus,
            uint64 borrowFactor
        );

    function getDecimals(address asset) external view
        returns (
            uint256
        );

    function setAssetType(address asset, DataTypes.ReserveAssetType assetType) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0; 
import {IVault} from "./IVault.sol"; 


interface IBalancer {

	function getPoolId() external view returns (bytes32 poolID); 
	function getVault() external view returns (IVault vaultAddress); 
	function getInvariant() external returns (uint256); 
	function totalSupply() external returns (uint256); 
	function getActualSupply() external returns (uint256); 
	function getVirtualSupply() external returns (uint256); 
	function getNormalizedWeights() external returns (uint256[] memory); 
	function getNumTokens() external view returns (uint256); 
	function getRateProviders() external view returns (address[] memory);
	function getFinalTokens() external view returns (address[] memory);
	function getRate() external view returns (uint256); 
	function getBptIndex() external view returns (uint256); 
	function getTokenRate(address) external view returns (uint256); 
	function decimals() external view returns (uint8); 

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0; 

interface IBeefyVault {

	function balance() external view returns (uint256); 
	function getPricePerFullShare() external view returns(uint256); 
	function totalSupply() external view returns (uint256); 
	function decimals() external view returns (uint256); 
	function strategy() external view returns (address); 
	function withdraw(uint256 amount) external; 

	function balanceOf(address token) external view returns (uint256); 
	
	function deposit(uint256 amount) external; 

    function want() external view returns (address);
}

interface IFeeConfig {
    struct FeeCategory {
        uint256 total;
        uint256 beefy;
        uint256 call;
        uint256 strategist;
        string label;
        bool active;
    }
    struct AllFees {
        FeeCategory performance;
        uint256 deposit;
        uint256 withdraw;
    }
    function getFees(address strategy) external view returns (FeeCategory memory);
    function stratFeeId(address strategy) external view returns (uint256);
    function setStratFeeId(uint256 feeId) external;
}

interface IBeefyStrategy {
	function getAllFees() external view returns (IFeeConfig.AllFees memory); 

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0; 

interface ICamelotPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function precisionMultiplier0() external view returns (uint256);
    function precisionMultiplier1() external view returns (uint256);
    function stableSwap() external view returns (bool);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent);
    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);
    function kLast() external view returns (uint);

    function setFeePercent(uint16 token0FeePercent, uint16 token1FeePercent) external;
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data, address referrer) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IChainlinkAggregator {
    function minAnswer() external view returns(int192);
    function maxAnswer() external view returns(int192);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IChainlinkPriceFeed {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function aggregator() external view returns(address);

    event AnswerUpdated(
        int256 indexed current,
        uint256 indexed roundId,
        uint256 timestamp
    );
    event NewRound(uint256 indexed roundId, address indexed startedBy);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19; 


interface ICurvePool {
    enum CurveReentrancyType {
        NO_CHECK, //0
        REMOVE_LIQUIDITY_ONE_COIN, //1
        REMOVE_LIQUIDITY_ONE_COIN_RETURNS, //2
        REMOVE_LIQUIDITY_2, //3
        REMOVE_LIQUIDITY_2_RETURNS, //4
        REMOVE_LIQUIDITY_3, //5
        REMOVE_LIQUIDITY_3_RETURNS //6
        // CLAIM_ADMIN_FEES,
        // WITHDRAW_ADMIN_FEES
    }

	function get_virtual_price() external view returns (uint256 out);

    function add_liquidity(
        // renbtc/tbtc pool
        uint256[2] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // sBTC pool
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function add_liquidity(
        // bUSD pool
        uint256[4] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256 out);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        uint256 deadline
    ) external;

    function remove_liquidity(
        uint256 _amount,
        uint256 deadline,
        uint256[2] calldata min_amounts
    ) external;

    function remove_liquidity(
        uint lp,
        uint[2] calldata min_amounts
    ) external returns (uint[2] memory);


    function remove_liquidity(
        uint lp,
        uint[3] calldata min_amounts
    ) external returns (uint[3] memory);

    function remove_liquidity_imbalance(
        uint256[2] calldata amounts,
        uint256 deadline
    ) external;

    function remove_liquidity_imbalance(
        uint256[3] calldata amounts,
        uint256 max_burn_amount
    ) external;

    function remove_liquidity_imbalance(
        uint256[4] calldata amounts,
        uint256 max_burn_amount) external;

    function remove_liquidity(uint256 _amount, uint256[4] calldata amounts)
        external returns(uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;


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

    function coins(uint256 arg0) external view returns (address out);

    function underlying_coins(int128 arg0) external returns (address out);

    function balances(uint256 arg0) external view returns (uint256 out);

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

    function calc_withdraw_one_coin(uint256 _token_amount, int128 _i)
        external
        view
        returns (uint256 out);

    function claim_admin_fees() external;
}

interface ICurvePool2 {
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external returns(uint256);


    function remove_liquidity(
        uint lp,
        uint[2] calldata min_amounts
    ) external;


    function remove_liquidity(
        uint lp,
        uint[3] calldata min_amounts
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20} from "../dependencies/openzeppelin/contracts/IERC20.sol";

interface IERC20WithPermit is IERC20 {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        uint64 trancheId,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        uint64 trancheId,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        uint64 trancheId,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        uint64 trancheId,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        uint64 trancheId,
        address indexed user
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused(uint64 indexed trancheId);

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused(uint64 indexed trancheId);

    /**
     * @dev Emitted when the pause is triggered.
     */
    event EverythingPaused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event EverythingUnpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param trancheId The trancheId of the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        uint64 trancheId,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param trancheId The trancheId of the reserve
     * @param liquidityRate The new liquidity rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint64 indexed trancheId,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );


    event ConfigurationAdminVerifiedUpdated(
        uint64 indexed trancheId,
        bool indexed verified
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * VariableDebtToken
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param trancheId The trancheId of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint64 trancheId,
        uint256 amount,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param trancheId The trancheId of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint64 trancheId,
        uint256 amount,
        address onBehalfOf
    ) external returns (uint256);


    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(
        address asset,
        uint64 trancheId,
        bool useAsCollateral
    ) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        uint64 trancheId,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user, uint64 trancheId)
        external
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor,
            uint256 avgBorrowFactor
        );

    function initReserve(
        address underlyingAsset,
        uint64 trancheId,
        address aTokenAddress,
        address variableDebtAddress
    ) external;

    function setReserveInterestRateStrategyAddress(
        address reserve,
        uint64 trancheId,
        address rateStrategyAddress
    ) external;

    function setConfiguration(
        address reserve,
        uint64 trancheId,
        uint256 configuration
    ) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset, uint64 trancheId)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user, uint64 trancheId)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset, uint64 trancheId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset, uint64 trancheId)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset, uint64 trancheId)
        external
        view
        returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        uint64 trancheId,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList(uint64 trancheId)
        external
        view
        returns (address[] memory);

    // function getReservesList(uint64 trancheId) external view returns (address[] memory);


    function getAddressesProvider()
        external
        view
        returns (ILendingPoolAddressesProvider);

    function setPauseEverything(bool val) external;

    function setPause(bool val, uint64 trancheId) external;

    function paused(uint64 trancheId) external view returns (bool);

    function setWhitelistEnabled(uint64 trancheId, bool isUsingWhitelist) external;
    function addToWhitelist(uint64 trancheId, address user, bool isWhitelisted) external;
    function addToBlacklist(uint64 trancheId, address user, bool isBlacklisted) external;

    function getTrancheParams(uint64) external view returns(DataTypes.TrancheParams memory);

    function setCollateralParams(
        address asset,
        uint64 trancheId,
        uint64 ltv,
        uint64 liquidationThreshold,
        uint64 liquidationBonus,
        uint64 borrowFactor
    ) external;
    function reserveAdded(address asset, uint64 trancheId) external view returns(bool);

    function setTrancheAdminVerified(uint64 trancheId, bool verified) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);

    // event ATokensAndRatesHelperUpdated(address indexed newAddress);
    event TrancheAdminUpdated(
        address indexed newAddress,
        uint64 indexed trancheId
    );
    event EmergencyAdminUpdated(address indexed newAddress);
    event GlobalAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event CurvePriceOracleUpdated(address indexed newAddress);
    event CurvePriceOracleWrapperUpdated(address indexed newAddress);
    event CurveAddressProviderUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);


    event VMEXTreasuryUpdated(address indexed newAddress);
    event AssetMappingsUpdated(address indexed newAddress);


    event ATokenUpdated(address indexed newAddress);
    event ATokenBeaconUpdated(address indexed newAddress);
    event VariableDebtUpdated(address indexed newAddress);
    event VariableDebtBeaconUpdated(address indexed newAddress);

    event IncentivesControllerUpdated(address indexed newAddress);

    event PermissionlessTranchesEnabled(bool enabled);

    event WhitelistedAddressesSet(address indexed user, bool whitelisted);

    function getVMEXTreasury() external view returns(address);

    function setVMEXTreasury(address add) external;

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    //********************************************************** */

    function getGlobalAdmin() external view returns (address);

    function setGlobalAdmin(address admin) external;

    function getTrancheAdmin(uint64 trancheId) external view returns (address);

    function setTrancheAdmin(address admin, uint64 trancheId) external;

    function addTrancheAdmin(address admin, uint64 trancheId) external;

    function getEmergencyAdmin()
        external
        view
        returns (address);

    function setEmergencyAdmin(address admin) external;

    function isWhitelistedAddress(address ad) external view returns (bool);

    //********************************************************** */
    function getPriceOracle()
        external
        view
        returns (address);

    function setPriceOracle(address priceOracle) external;

    function getAToken() external view returns (address);
    function setATokenImpl(address pool) external;

    function getATokenBeacon() external view returns (address);
    function setATokenBeacon(address pool) external;

    function getVariableDebtToken() external view returns (address);
    function setVariableDebtToken(address pool) external;

    function getVariableDebtTokenBeacon() external view returns (address);
    function setVariableDebtTokenBeacon(address pool) external;

    function getAssetMappings() external view returns (address);
    function setAssetMappingsImpl(address pool) external;

    function getIncentivesController() external view returns (address);
    function setIncentivesController(address incentives) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IPriceOracleGetter} from "./IPriceOracleGetter.sol";
/************
@title IPriceOracle interface
@notice Interface for the Aave price oracle.*/
abstract contract IPriceOracle is IPriceOracleGetter {
    /***********
    @dev returns the asset price in ETH
     */
    // function getAssetPrice(address asset) external view override virtual returns (uint256);

    /***********
    @dev sets the asset price, in wei
     */
    function setAssetPrice(address asset, uint256 price) external virtual;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Aave price oracle.
 **/
interface IPriceOracleGetter {
    event BaseCurrencySet(
        address indexed baseCurrency,
        uint256 baseCurrencyUnit
    );
    event AssetSourceUpdated(address indexed asset, address indexed source);
    event FallbackOracleUpdated(address indexed fallbackOracle);
    event SequencerUptimeFeedUpdated(uint256 indexed chainId, address indexed sequencerUptimeFeed);


    /**
     * @dev returns the asset price in ETH
     * @param asset the address of the asset
     * @return the ETH price of the asset
     **/
    function getAssetPrice(address asset) external returns (uint256);


    function BASE_CURRENCY_DECIMALS() external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0; 

interface IRateProvider {
	function getRate() external view returns (uint256); 
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;
import {DataTypes} from "../protocol/libraries/types/DataTypes.sol";

/**
 * @title IRocketPriceOracle interface
 * @dev Interface for getting the rate for rocket eth
 * @author Rocket Pool
 */
interface IRocketPriceOracle {
    function rate() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;
	

import "../dependencies/openzeppelin/contracts/IERC20.sol"; 

interface IAsset {
 //only needed for sol to not complain
}

interface IVault {

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

	enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

	function getPoolTokens(bytes32 poolId) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0; 



interface IVeloPair {

	function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19; 


interface IYearnToken {
	
	function totalAssets() external view returns(uint256); 
	function totalSupply() external view returns(uint256); 
	function pricePerShare() external view returns(uint256);
	function token() external view returns(address);
	function decimals() external view returns(uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 *  - AM = Asset Mappings
 *  - VO = VMEX Oracle
 */
library Errors {
    //common errors
    string public constant CALLER_NOT_TRANCHE_ADMIN = "33"; // 'The caller must be the tranche admin'
    string public constant CALLER_NOT_GLOBAL_ADMIN = "0"; // 'The caller must be the global admin'
    string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small
    string public constant ARRAY_LENGTH_MISMATCH = "85";

    //contract specific errors
    string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
    string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
    string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
    string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
    string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "10"; // 'Health factor is lesser than the liquidation threshold'
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
    string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
    string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
    string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
    string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
    string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
    string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
    string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
    string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
    string public constant VL_SUPPLY_CAP_EXCEEDED = "82";
    string public constant VL_BORROW_CAP_EXCEEDED = "83";
    string public constant VL_COLLATERAL_DISABLED = "93";
    string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
    string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
    string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
    string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
    string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
    string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
    string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
    string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
    string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
    string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
    string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS =
        "38"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS =
        "39"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
    string public constant LPC_NOT_WHITELISTED_TRANCHE_CREATION = "84"; //not whitelisted to create a tranche
    string public constant LPC_NOT_APPROVED_BORROWABLE = "86"; //assetmappings does not allow setting borrowable
    string public constant LPC_NOT_APPROVED_COLLATERAL = "87"; //assetmappings does not allow setting collateral
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
    string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
    string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
    string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
    string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
    string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
    string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
    string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
    string public constant MATH_ADDITION_OVERFLOW = "49";
    string public constant MATH_DIVISION_BY_ZERO = "50";
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
    string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
    string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
    string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
    string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
    string public constant LP_FAILED_COLLATERAL_SWAP = "60";
    string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
    string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
    string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
    string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
    string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
    string public constant LP_NOT_WHITELISTED_TRANCHE_PARTICIPANT = "91";
    string public constant LP_BLACKLISTED_TRANCHE_PARTICIPANT = "92";
    string public constant RC_INVALID_LTV = "67";
    string public constant RC_INVALID_LIQ_THRESHOLD = "68";
    string public constant RC_INVALID_LIQ_BONUS = "69";
    string public constant RC_INVALID_DECIMALS = "70";
    string public constant RC_INVALID_RESERVE_FACTOR = "71";
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
    string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
    string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
    string public constant UL_INVALID_INDEX = "77";
    string public constant LP_NOT_CONTRACT = "78";
    string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
    string public constant SDT_BURN_EXCEEDS_BALANCE = "80";
    string public constant CT_CALLER_MUST_BE_STRATEGIST = "81";

    string public constant AM_ASSET_DOESNT_EXIST = "88";
    string public constant AM_ASSET_NOT_ALLOWED = "89";
    string public constant AM_NO_INTEREST_STRATEGY = "90";

    string public constant VO_REENTRANCY_GUARD_FAIL = "94"; //vmex curve oracle view reentrancy call failed
    string public constant VO_UNDERLYING_FAIL = "95";
    string public constant VO_ORACLE_ADDRESS_NOT_FOUND = "96";
    string public constant VO_SEQUENCER_DOWN = "97";
    string public constant VO_SEQUENCER_GRACE_PERIOD_NOT_OVER = "98";
    string public constant VO_BASE_CURRENCY_SET_ONLY_ONCE = "99";

    string public constant AM_ASSET_ALREADY_IN_MAPPINGS = "100";
    string public constant AM_ASSET_NOT_CONTRACT = "101";
    string public constant AM_INTEREST_STRATEGY_NOT_CONTRACT = "102";
    string public constant AM_INVALID_CONFIGURATION = "103";
    string public constant AM_UNABLE_TO_DISALLOW_ASSET = "104";

    string public constant VO_WETH_SET_ONLY_ONCE = "105";
    string public constant VO_BAD_DENOMINATION = "106";
    string public constant VO_BAD_DECIMALS = "107";
    
    string public constant LPAPR_ALREADY_SET = "108";

    string public constant LPC_TREASURY_ADDRESS_ZERO = "109"; //assetmappings does not allow setting collateral
    string public constant LPC_WHITELISTING_NOT_ALLOWED = "110"; //setting whitelist enabled is not allowed after initializing reserves

    string public constant INVALID_TRANCHE = "111"; // 'The tranche doesn't exist

    string public constant TRANCHE_ADMIN_NOT_VERIFIED = "112"; // 'The caller must be verified tranche admin

    string public constant ALREADY_VERIFIED = "113";

    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN_OR_VERIFIED_TRANCHE = "114";

    enum CollateralManagerErrors {
        NO_ERROR,
        NO_COLLATERAL_AVAILABLE,
        COLLATERAL_CANNOT_BE_LIQUIDATED,
        CURRRENCY_NOT_BORROWED,
        HEALTH_FACTOR_ABOVE_THRESHOLD,
        NOT_ENOUGH_LIQUIDITY,
        NO_ACTIVE_RESERVE,
        HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
        INVALID_EQUAL_ASSETS_TO_SWAP,
        FROZEN_RESERVE
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20} from "../../../dependencies/openzeppelin/contracts/IERC20.sol";
import {DataTypes} from "../types/DataTypes.sol";
import {Errors} from "./Errors.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {SafeCast} from "../../../dependencies/openzeppelin/contracts/SafeCast.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../../interfaces/ILendingPool.sol";

/**
 * @title Helpers library
 * @author Aave and VMEX
 */
library Helpers {
    using PercentageMath for uint256;
    using SafeCast for uint256;
    /**
     * @dev Fetches the user current variable debt balance
     * @param user The user address
     * @param reserve The reserve data object
     * @return The variable debt balance
     **/
    function getUserCurrentDebt(
        address user,
        DataTypes.ReserveData storage reserve
    ) internal view returns (uint256) {
        return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
    }

    function getUserCurrentDebtMemory(
        address user,
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256) {
        return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
    }

    /**
     * @dev Gets a string attribute of a token (in our case, the name and symbol attribute), where it could 
     * not be implemented, or return bytes32, or return a string
     * @param token The token
     * @param functionToQuery The function to query the string of
     **/
    function getStringAttribute(address token, string memory functionToQuery)
        internal
        view
        returns (string memory queryResult)
    {
        bytes memory payload = abi.encodeWithSignature(functionToQuery);
        (bool success, bytes memory result) = token.staticcall(payload);
        if (success && result.length != 0) {
            if (result.length == 32) {
                // If the result is 32 bytes long, assume it's a bytes32 value
                queryResult = string(result);
            } else {
                // Otherwise, assume it's a string
                queryResult = abi.decode(result, (string));
            }
        }
    }

    /**
     * @dev Helper function to get symbol of erc20 token since some protocols return a bytes32, others do string, others don't even implement.
     * @param token The token
     **/
    function getSymbol(address token) internal view returns (string memory) {
        return getStringAttribute(token, "symbol()");
    }

    /**
     * @dev Helper function to get name of erc20 token since some protocols return a bytes32, others do string, others don't even implement.
     * @param token The token
     **/ 
    function getName(address token) internal view returns(string memory) {
        return getStringAttribute(token, "name()");
    }

    /**
     * @dev Helper function to compare suffix of str to a target
     * @param str String with suffix to compare
     * @param target target string
     **/ 
    function compareSuffix(string memory str, string memory target) internal pure returns(bool) {
        uint strLen = bytes(str).length;
        uint targetLen = bytes(target).length;

        if (strLen < targetLen) {
            return false;
        }

        uint suffixStart = strLen - targetLen;

        bytes memory suffixBytes = new bytes(targetLen);

        for (uint256 i; i < targetLen;) {
            suffixBytes[i] = bytes(str)[suffixStart + i];

            unchecked { ++i; }
        }

        string memory suffix = string(suffixBytes);

        bool ret = (keccak256(bytes(suffix)) == keccak256(bytes(target)));

        return ret;
    }

    function onlyEmergencyAdmin(ILendingPoolAddressesProvider addressesProvider, address user) internal view {
        require(
            _isEmergencyAdmin(addressesProvider, user) ||
            _isGlobalAdmin(addressesProvider, user),
            Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN
        );
    }

    function onlyEmergencyTrancheAdmin(ILendingPoolAddressesProvider addressesProvider, uint64 trancheId, address user) internal view {
        ILendingPool pool = ILendingPool(addressesProvider.getLendingPool());
        require(
            _isEmergencyAdmin(addressesProvider, user) ||
            (_isTrancheAdmin(addressesProvider,trancheId, user) && pool.getTrancheParams(trancheId).verified) || //allow verified tranche admins to pause tranches
            _isGlobalAdmin(addressesProvider, user),
            Errors.LPC_CALLER_NOT_EMERGENCY_ADMIN_OR_VERIFIED_TRANCHE
        );
    }

    function onlyGlobalAdmin(ILendingPoolAddressesProvider addressesProvider, address user) internal view {
        require(
            _isGlobalAdmin(addressesProvider, user),
            Errors.CALLER_NOT_GLOBAL_ADMIN
        );
    }

    function onlyTrancheAdmin(ILendingPoolAddressesProvider addressesProvider, uint64 trancheId, address user) internal view {
        require(
            _isTrancheAdmin(addressesProvider,trancheId, user) ||
                _isGlobalAdmin(addressesProvider, user),
            Errors.CALLER_NOT_TRANCHE_ADMIN
        );
    }


    function onlyVerifiedTrancheAdmin(ILendingPoolAddressesProvider addressesProvider, uint64 trancheId, address user) internal view {
        ILendingPool pool = ILendingPool(addressesProvider.getLendingPool());
        require(
            (_isTrancheAdmin(addressesProvider,trancheId, user) && pool.getTrancheParams(trancheId).verified) ||
                _isGlobalAdmin(addressesProvider, user),
            Errors.TRANCHE_ADMIN_NOT_VERIFIED
        );
    }

    function _isGlobalAdmin(ILendingPoolAddressesProvider addressesProvider, address user) internal view returns(bool){
        return addressesProvider.getGlobalAdmin() == user;
    }

    function _isTrancheAdmin(ILendingPoolAddressesProvider addressesProvider, uint64 trancheId, address user) internal view returns(bool) {
        return addressesProvider.getTrancheAdmin(trancheId) == user;
    }

    function _isEmergencyAdmin(ILendingPoolAddressesProvider addressesProvider, address user) internal view returns(bool) {
        return addressesProvider.getEmergencyAdmin() == user;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Vmex
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 16 decimals of precision. The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant NUM_DECIMALS = 18;
    uint256 constant PERCENTAGE_FACTOR = 10**NUM_DECIMALS; //percentage plus 16 decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IAssetMappings} from "../../../interfaces/IAssetMappings.sol";
import {ILendingPoolAddressesProvider} from "../../../interfaces/ILendingPoolAddressesProvider.sol";
import {ILendingPool} from "../../../interfaces/ILendingPool.sol";
import {ICurvePool} from "../../../interfaces/ICurvePool.sol";

library DataTypes {
    struct TrancheParams {
        uint8 reservesCount;
        bool paused;
        bool isUsingWhitelist;
        bool verified;
    }

    struct CurveMetadata {
        ICurvePool.CurveReentrancyType _reentrancyType;
        uint8 _poolSize;
        address _curvePool;
    }

    struct BeethovenMetadata {
        uint8 _typeOfPool;
        bool _legacy;
        bool _exists;
    }

    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct AssetData {
        //if we assume most decimals is 18, storing these in uint128 should be ok, that means the maximum someone can deposit is 3.4 * 10^20
        uint128 supplyCap; //can get up to 10^38. Good enough.
        uint128 borrowCap; //can get up to 10^38. Good enough.
        uint64 baseLTV; // % of value of collateral that can be used to borrow. "Collateral factor." 64 bits
        uint64 liquidationThreshold; //if this is zero, then disabled as collateral. 64 bits
        uint64 liquidationBonus; // 64 bits
        uint64 borrowFactor; // borrowFactor * baseLTV * value = truly how much you can borrow of an asset. 64 bits

        bool borrowingEnabled;
        bool isAllowed; //default to false, unless set
        bool exists;    //true if the asset was added to the linked list, false otherwise
        uint8 assetType; //to choose what oracle to use
        uint64 VMEXReserveFactor; //64 bits. is sufficient (percentages can all be stored in 64 bits)
        address defaultInterestRateStrategyAddress;
        //pointer to the next asset that is approved. This allows us to avoid using a list
        address nextApprovedAsset;
    }

    enum ReserveAssetType {
        CHAINLINK, //0
        CURVE, //1
        CURVEV2, //2
        YEARN, //3
        BEEFY, //4
        VELODROME, //5
        BEETHOVEN, //6
        RETH, //7
        CL_PRICE_ADAPTER, //8
        CAMELOT, //9
        BACKED //10
    } //update with other possible types of the underlying asset

    struct TrancheAddress {
        uint64 trancheId;
        address asset;
    }
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration; //a lot of this is per asset rather than per reserve. But it's fine to keep since pretty gas efficient

        //the liquidity index. Expressed in ray
        uint128 liquidityIndex; //not used for nonlendable assets
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex; //not used for nonlendable assets
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate; //deposit APR is defined as liquidityRate / RAY //not used for nonlendable assets
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate; //not used for nonlendable assets
        uint40 lastUpdateTimestamp; //last updated timestamp for interest rates
        //tokens addresses
        address aTokenAddress;
        address variableDebtTokenAddress; //not used for nonlendable assets
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;

        // these are only set if tranche becomes verified
        address interestRateStrategyAddress;
        uint64 baseLTV; // % of value of collateral that can be used to borrow. "Collateral factor." 64 bits
        uint64 liquidationThreshold; //if this is zero, then disabled as collateral. 64 bits
        uint64 liquidationBonus; // 64 bits
        uint64 borrowFactor; // borrowFactor * baseLTV * value = truly how much you can borrow of an asset. 64 bits
    }

    // uint8 constant NUM_TRANCHES = 3;

    struct ReserveConfigurationMap {
        //new mappings to account for larger reserve factors
        //bit 0: Reserve is active
        //bit 1: reserve is frozen
        //bit 2: borrowing is enabled
        //bit 3: collateral is enabled
        //bit 4-67: reserve factor (64 bit)
        uint256 data; //in total we only need 68 bits, so that's 9 bytes = 72 bits
    }

    struct UserData {
        UserConfigurationMap configuration;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }

    struct AcctTranche {
        address user;
        uint64 trancheId;
    }

    struct DepositVars {
        address asset;
        uint64 trancheId;
        address _addressesProvider;
        IAssetMappings _assetMappings;
        uint256 amount;
        address onBehalfOf;
        uint16 referralCode;
    }

    struct ExecuteBorrowParams {
        uint256 amount;
        uint256 _reservesCount;
        uint256 assetPrice;
        uint64 trancheId; //trancheId the user wants to borrow out of
        uint16 referralCode;
        address asset;
        address user;
        address onBehalfOf;
        address aTokenAddress;
        bool releaseUnderlying;
        IAssetMappings _assetMappings;

    }

    struct WithdrawParams {
        uint8 _reservesCount; //number of reserves per tranche cannot exceed 128 (126 if we are packing whitelist and blacklist too)
        address asset;
        uint64 trancheId;
        uint256 amount;
        address to;
    }

    struct calculateInterestRatesVars {
        address reserve;
        address aToken;
        uint256 liquidityAdded;
        uint256 liquidityTaken;
        uint256 totalVariableDebt;
        uint256 reserveFactor;
        uint256 globalVMEXReserveFactor;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0; 

import "../../dependencies/balancer/BNum.sol"; //already audited import 
import "../../interfaces/IBalancer.sol"; //imports IVault as well
import "../../interfaces/IRateProvider.sol"; 
import "../../interfaces/IPriceOracle.sol";
import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {IERC20Detailed} from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import "./libs/vMath.sol";
import "../../dependencies/balancer/VaultReentrancyLib.sol";

//This contract orignally comes from alpha homora v2 -- audited by peckshield and quantstamp
//has been modified to suit VMEX's structure, updated to solc 0.8
//has also been updated to balancer v2 pools and structure
//mathematical formula remains the same
library BalancerOracle {

	uint256 internal constant uint211 = (2**211) - 1; 
	
	//weighted == 0
	//metastable/composable == 1 
	//metastable == pools of the same wrapped assets (eth/weth, eth/rweth, etc) (any amount supported)
	//composable == stablecoin pools (any amount supported)
	/// @param bal_pool the underlying balancer pool
	/// @param prices the underlying prices, must be scaled to 1e18
	/// @param type_of_pool the type of pool to calculate the price of
		//weighted == 0 (not supported yet)
		//metastable/composable == 1 
		//metastable == pools of the same wrapped assets (eth/weth, eth/rweth, etc) (any amount supported)
		//composable == stablecoin pools (any amount supported)
	/// @param legacy. If the pool supports pre-minted BPT or not. If not, legacy should be = true. 

	/// @dev we are only allowing stable balancer pools for now, until a good formula for 
	function get_lp_price(
		address vmexOracle,
		address bal_pool, 
		uint8 type_of_pool,
		bool legacy //if stable, ignore
	) internal returns (uint256 price) {

		//check for reentrancy on bal and beets
		IVault vault = IBalancer(bal_pool).getVault(); 
		VaultReentrancyLib.ensureNotInVaultContext(vault); 

		if (type_of_pool == 1) { //stable
			price = calc_stable_lp_price(
				vmexOracle,
				bal_pool,
				legacy
			); 
		} else {
			revert("Balancer pool not supported");  
		}


		return price; 
			
	}
	
	// inspired from https://github.com/Midas-Protocol/contracts/blob/352be0e9ba2795e14d05a5fa4661cb2569655141/contracts/oracles/default/BalancerLpStablePoolPriceOracle.sol
	function calc_stable_lp_price(
		address vmexOracle,
		address bal_pool, 
		bool legacy
	) internal returns (uint256) {	
		IBalancer pool = IBalancer(bal_pool);

        // get the underlying assets
        IVault vault = IBalancer(bal_pool).getVault();
        bytes32 poolId = IBalancer(bal_pool).getPoolId();


        (
            IERC20[] memory tokens,
            ,
        ) = vault.getPoolTokens(poolId);
		
		uint256 bptIndex;
		// if(legacy) {
		// 	bptIndex = type(uint256).max;
		// } else {
		// 	bptIndex = pool.getBptIndex();
		// }
		try pool.getBptIndex() returns (uint ind) {
			bptIndex = ind;
		} catch {
			bptIndex = type(uint256).max;
		}

		uint256 minPrice = type(uint256).max;

		address[] memory rateProviders;
		if(legacy) {
			rateProviders = pool.getRateProviders();
		} 

		for (uint256 i = 0; i < tokens.length; i++) {
			if (i == bptIndex) {
				continue;
			}
			// Get the price of each of the base tokens in ETH
			// This also includes the price of the nested LP tokens, if they are e.g. LinearPools
			// The only requirement is that the nested LP tokens have a price oracle registered
			// See BalancerLpLinearPoolPriceOracle.sol for an example, as well as the relevant tests
			uint256 price = IPriceOracle(vmexOracle).getAssetPrice(address(tokens[i]));
			uint256 depositTokenPrice;
			if(legacy) {
				if(rateProviders[i] == address(0)){
					depositTokenPrice = 1e18;
				} else {
					depositTokenPrice = IRateProvider(rateProviders[i]).getRate();
				}
			} else {
				depositTokenPrice = pool.getTokenRate(address(tokens[i]));
			}
			uint256 finalPrice = (price * 1e18) / depositTokenPrice; //rate always yas 18 decimals, so this preserves original decimals of price
			if (finalPrice < minPrice) {
				minPrice = finalPrice;
			}
		}
		// Multiply the value of each of the base tokens' share in ETH by the rate of the pool
		// pool.getRate() is the rate of the pool, scaled by 1e18
		return (minPrice * pool.getRate()) / 1e18;
	}
	
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19; 

import {ICurvePool, ICurvePool2} from "../../interfaces/ICurvePool.sol"; 
import {IERC20Detailed} from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol"; 
import {vMath} from "./libs/vMath.sol"; 
import {Errors} from "../libraries/helpers/Errors.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/Address.sol";
//import "hardhat/console.sol";

//used for all curveV1 amd V2 tokens, no need to redeploy
library CurveOracle {
	/**
     * @dev Helper to prevent read-only re-entrancy attacks with virtual price. Only needed if the underlying has ETH.
     * @param curve_pool The curve pool address (not the token address!)
     **/
	function check_reentrancy(address curve_pool, ICurvePool.CurveReentrancyType reentrancyType) internal {
		//makerdao uses remove_liquidity to trigger reentrancy lock
		if(reentrancyType == ICurvePool.CurveReentrancyType.NO_CHECK){
			return;
		}
		else if(reentrancyType == ICurvePool.CurveReentrancyType.REMOVE_LIQUIDITY_ONE_COIN){
			ICurvePool(curve_pool).remove_liquidity_one_coin(0,1,0);
		}
		else if(reentrancyType == ICurvePool.CurveReentrancyType.REMOVE_LIQUIDITY_ONE_COIN_RETURNS){
			ICurvePool2(curve_pool).remove_liquidity_one_coin(0,1,0);
		}
		else if(reentrancyType == ICurvePool.CurveReentrancyType.REMOVE_LIQUIDITY_2){
			uint[2] memory amounts = [uint(0), uint(0)];
			ICurvePool2(curve_pool).remove_liquidity(0, amounts);
		}
		else if(reentrancyType == ICurvePool.CurveReentrancyType.REMOVE_LIQUIDITY_2_RETURNS){
			uint[2] memory amounts = [uint(0), uint(0)];
			ICurvePool(curve_pool).remove_liquidity(0, amounts);
		}
		else if(reentrancyType == ICurvePool.CurveReentrancyType.REMOVE_LIQUIDITY_3){
			uint[3] memory amounts = [uint(0), uint(0), uint(0)];
			ICurvePool2(curve_pool).remove_liquidity(0, amounts);
		}
		else if(reentrancyType == ICurvePool.CurveReentrancyType.REMOVE_LIQUIDITY_3_RETURNS){
			uint[3] memory amounts = [uint(0), uint(0), uint(0)];
			ICurvePool(curve_pool).remove_liquidity(0, amounts);
		}
		else {
			revert(Errors.VO_REENTRANCY_GUARD_FAIL);
		}
	}
	
	/**
     * @dev Calculates the value of a curve v1 lp token
     * @param curve_pool The curve pool address (not the token address!)
     * @param prices The price of the underlying assets in the curve pool
     * @param reentrancyType Whhat type of reentrancy check is needed
     **/
	function get_price_v1(address curve_pool, uint256[] memory prices, ICurvePool.CurveReentrancyType reentrancyType) internal returns(uint256) {
	//prevent read-only reentrancy -- possibly a better way than this
		assert(prices.length > 1);
		check_reentrancy(curve_pool, reentrancyType);
		uint256 virtual_price = ICurvePool(curve_pool).get_virtual_price();

		uint256 minPrice = vMath.min(prices);
		
		
		uint256 lp_price = calculate_v1_token_price(
			virtual_price,
			minPrice
		);	
		
		return lp_price; 	
		
	}

	//where virtual price is the price of the pool in USD
	//returns lp_value = virtual price * weighted average(prices); 
	function calculate_v1_token_price(
		uint256 virtual_price,
		uint256 minPrice
	) internal pure returns(uint256) {
		// divide by virtual price decimals, which is always 18 for all existing curve pools.
		return (virtual_price * minPrice) / 1e18; //decimals equal to the number of decimals in chainlink price
	}

	/**	
     * @dev Calculates the value of a curve v2 lp token (not pegged)
     * @param curve_pool The curve pool address (not the token address!)
     * @param prices The price of the underlying assets in the curve pool
     * @param reentrancyType What type of reentrancy check is needed
     **/
	function get_price_v2(address curve_pool, uint256[] memory prices, ICurvePool.CurveReentrancyType reentrancyType) internal returns(uint256) {
		check_reentrancy(curve_pool, reentrancyType);
        uint256 virtual_price = ICurvePool(curve_pool).get_virtual_price();

		uint256 lp_price = calculate_v2_token_price(
			uint8(prices.length),
			virtual_price,
			prices
		);	
		
		return lp_price; 	
		
	}
	
	//returns n_token * vp * (p1 * p2 * p3) ^1/n	
	//n should only ever be 2 or 3 for v2 pools
	//returns the lp_price scaled by 1e36, so scale down by 1e18
	function calculate_v2_token_price(
		uint8 n,
		uint256 virtual_price,
		uint256[] memory prices
	) internal pure returns(uint256) {
		uint256 product = vMath.product(prices); 
		uint256 geo_mean = vMath.nthroot(n, product); 
		return (n * virtual_price * geo_mean) / 1e18; 
	}

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19; 

import {FixedPointMathLib} from "../../../dependencies/solady/FixedPointMathLib.sol";
import {Math} from "../../../dependencies/openzeppelin/contracts/utils/math/Math.sol";

library vMath {

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.
	
	function min(uint256[] memory array) internal pure returns(uint256) {
		uint256 _min = array[0];
		uint256 length = array.length;
		for (uint256 i = 1; i < length;) {
			if (_min > array[i]) {
				_min = array[i]; 
			}

			unchecked { ++i; }
		}
		return _min; 
	}

	function weightedAvg(uint256[] calldata prices, uint256[] calldata balances, uint8[] calldata decimals) internal pure returns(uint256) {
		uint256 cumSum;
		uint256 cumBalances;
		uint256 length = prices.length;
		for(uint256 i; i<length;) {
			cumSum += prices[i]*balances[i]/10**decimals[i]; //18 decimals
			cumBalances += balances[i]*1e18/10**decimals[i]; //18 decimals

			unchecked { ++i; }
		}

		return cumSum * 1e18 / cumBalances; //18 decimals
	}

	function product(uint256[] memory nums) internal pure returns(uint256) {
		uint256 _product = nums[0];
		uint256 length = nums.length;
		for (uint256 i = 1; i < length;) {
			_product *= nums[i]; 

			unchecked { ++i; }
		}
		return _product; 
	}
	
	//limited to curve pools only, either 2 or 3 assets (mostly 2) 
	function nthroot(uint8 n, uint256 val) internal pure returns(uint256) {
		//VMEX empirically checked that this is only accurate for square roots and cube roots, and the decimals are 9 and 12 respectively
		if(n==2){
			return Math.sqrt(val);
		}
		if(n==3){
			return FixedPointMathLib.cbrt(val);
		}
		revert("Math only can handle square roots and cube roots");
	}

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {vMath} from "./libs/vMath.sol";
import {FixedPointMathLib} from "../../dependencies/solmate/FixedPointMathLib.sol"; 
import {IVeloPair} from "../../interfaces/IVeloPair.sol"; 
import {ICamelotPair} from "../../interfaces/ICamelotPair.sol"; 
import {IERC20} from "../../interfaces/IERC20WithPermit.sol"; 


library VelodromeOracle {
	using FixedPointMathLib for *; 
		
	/**
     * @dev Gets the price of a velodrome lp token
     * @param lpToken The lp token address
     * @param prices The prices of the underlying in the liquidity pool, there must be 18 decimals
     **/
	//@dev assumes oracles only pass in wad scaled decimals for ALL prices
	function get_lp_price(address lpToken, uint256[] memory prices, uint256 priceDecimals) internal view returns(uint256) {
		IVeloPair token = IVeloPair(lpToken); 	
		uint256 total_supply = IERC20(lpToken).totalSupply()* 1e18 / (10**IERC20(lpToken).decimals()); //force to be 18 decimals
		(uint256 d0, uint256 d1, uint256 r0, uint256 r1, bool stable, ,) = token.metadata(); 

		r0 *= 1e18 / d0; 
		r1 *= 1e18 / d1; 
	
		return stable ?
			calculate_stable_lp_token_price(
				total_supply, 
				prices[0],
				prices[1],
				r0,
				r1,
				priceDecimals
			)
			: calculate_lp_token_price(
				total_supply, 
				prices[0],
				prices[1],
				r0,
				r1
			); 
	}

	/**
     * @dev Gets the price of a camelot lp token
     * @param lpToken The lp token address
     * @param prices The prices of the underlying in the liquidity pool, there must be 18 decimals
     **/
	//@dev assumes oracles only pass in wad scaled decimals for ALL prices
	function get_cmlt_lp_price(address lpToken, uint256[] memory prices, uint256 priceDecimals) internal view returns(uint256) {
		ICamelotPair token = ICamelotPair(lpToken); 	
		uint256 total_supply = IERC20(lpToken).totalSupply()* 1e18 / (10**IERC20(lpToken).decimals()); //force to be 18 decimals
		uint256 d0 = token.precisionMultiplier0();
		uint256 d1 = token.precisionMultiplier1();
		(uint256 r0, uint256 r1, , ) = token.getReserves(); 
		bool stable = token.stableSwap();

		r0 *= 1e18 / d0; 
		r1 *= 1e18 / d1; 
	
		return stable ?
			calculate_stable_lp_token_price(
				total_supply, 
				prices[0],
				prices[1],
				r0,
				r1,
				priceDecimals
			)
			: calculate_lp_token_price(
				total_supply, 
				prices[0],
				prices[1],
				r0,
				r1
			); 
	}
	
	//where total supply is the total supply of the LP token
	//formula solves xy = k curves only
	//assumes that prices passed in are already properly WAD scaled
	function calculate_lp_token_price(
		uint256 total_supply,
		uint256 price0,
		uint256 price1,
		uint256 reserve0,
		uint256 reserve1
	) internal pure returns (uint256) {
		uint256 a = vMath.nthroot(2, reserve0 * reserve1); //ends up with same number of decimals as reserve0 or reserve1 without loss of precision, which should be 18
		uint256 b = vMath.nthroot(2, price0 * price1); //same number of dec as price0 or price1, should be chainlink agg (op: 8)
		uint256 c = 2 * a * b / total_supply; //must end up as num decimals as prices since total supply is guaranteed to be 18

		return c; 
	}
	
	//solves for cases where curve is x^3 * y + y^3 * x = k  
	//fair reserves math formula author: @ksyao2002
	function calculate_stable_lp_token_price(
		uint256 total_supply,
		uint256 price0,
		uint256 price1,
		uint256 reserve0,
		uint256 reserve1,
		uint256 priceDecimals
	) internal pure returns (uint256) {
		uint256 k = getK(reserve0, reserve1); 
		//fair_reserves = ( (k * (price0 ** 3) * (price1 ** 3)) )^(1/4) / ((price0 ** 2) + (price1 ** 2));  
		price0 *= 1e18 / (10**priceDecimals); //convert to 18 dec
		price1 *= 1e18 / (10**priceDecimals); 
		uint256 a = FixedPointMathLib.rpow(price0, 3, 1e18); //keep same decimals as chainlink
		uint256 b = FixedPointMathLib.rpow(price1, 3, 1e18);  
		uint256 c = FixedPointMathLib.rpow(price0, 2, 1e18);  
		uint256 d = FixedPointMathLib.rpow(price1, 2, 1e18);  

		uint256 p0 =k * FixedPointMathLib.mulWadDown(a, b); //2*18 decimals
		
		uint256 fair = p0 / (c + d); // number of decimals is 18

		// each sqrt divides the num decimals by 2. So need to replenish the decimals midway through with another 1e18
		uint256 frth_fair = FixedPointMathLib.sqrt(FixedPointMathLib.sqrt(fair  * 1e18) * 1e18); // number of decimals is 18
		
		return 2 * ((frth_fair * (10**priceDecimals) ) / total_supply); // converts to chainlink decimals
	}

	function getK(uint256 x, uint256 y) internal pure returns (uint256) {
		//x, n, scalar	
		uint256 x_cubed = FixedPointMathLib.rpow(x, 3, 1e18); 
		uint256 newX = FixedPointMathLib.mulWadDown(x_cubed, y); 
		uint256 y_cubed = FixedPointMathLib.rpow(y, 3, 1e18); 
		uint256 newY = FixedPointMathLib.mulWadDown(y_cubed, x); 
	
		return newX + newY;  //18 decimals
	}

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20} from "../../dependencies/openzeppelin/contracts/IERC20.sol";
import {ILendingPoolAddressesProvider} from "../../interfaces/ILendingPoolAddressesProvider.sol";
import {ICurvePool} from "../../interfaces/ICurvePool.sol";
import {IPriceOracleGetter} from "../../interfaces/IPriceOracleGetter.sol";
import {IChainlinkPriceFeed} from "../../interfaces/IChainlinkPriceFeed.sol";
import {IChainlinkAggregator} from "../../interfaces/IChainlinkAggregator.sol";
import {SafeERC20} from "../../dependencies/openzeppelin/contracts/SafeERC20.sol";
import {IERC20Detailed} from "../../dependencies/openzeppelin/contracts/IERC20Detailed.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IAssetMappings} from "../../interfaces/IAssetMappings.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {CurveOracle} from "./CurveOracle.sol";
import {IYearnToken} from "../../interfaces/IYearnToken.sol";
import {Address} from "../../dependencies/openzeppelin/contracts/Address.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {Helpers} from "../libraries/helpers/Helpers.sol";
import {AggregatorV3Interface} from "../../interfaces/AggregatorV3Interface.sol";
import {IBeefyVault} from "../../interfaces/IBeefyVault.sol";
import {IVeloPair} from "../../interfaces/IVeloPair.sol";
import {IBalancer} from "../../interfaces/IBalancer.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {VelodromeOracle} from "./VelodromeOracle.sol";
import {BalancerOracle} from "./BalancerOracle.sol";
import {IRocketPriceOracle} from "../../interfaces/IRocketPriceOracle.sol";
import {ICamelotPair} from "../../interfaces/ICamelotPair.sol"; 

/// @title VMEXOracle
/// @author VMEX, with inspiration from Aave
/// @notice Proxy smart contract to get the price of an asset from a price source, with Chainlink Aggregator
///         smart contracts as primary option
/// - If the returned price by a Chainlink aggregator is <= 0, the call is forwarded to a fallbackOracle
/// - Owned by the VMEX governance system, allowed to add sources for assets, replace them
///   and change the fallbackOracle
contract VMEXOracle is Initializable, IPriceOracleGetter {
    using SafeERC20 for IERC20;

    struct ChainlinkData {
        IChainlinkPriceFeed feed;
        uint64 heartbeat;
    }

    ILendingPoolAddressesProvider internal _addressProvider;
    IAssetMappings internal _assetMappings;
    IPriceOracleGetter private _fallbackOracle;
    IRocketPriceOracle public rETHOracle;
    mapping(address => ChainlinkData) private _assetsSources;
    mapping(uint256 => AggregatorV3Interface) public sequencerUptimeFeeds;

    address public BASE_CURRENCY; //removed immutable keyword since
    uint256 public BASE_CURRENCY_DECIMALS; //amount of decimals that the chainlink aggregator assumes for price feeds with this currency as the base
    uint256 public BASE_CURRENCY_UNIT;
    string public BASE_CURRENCY_STRING;

    address public constant ETH_NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public WETH;
    uint256 private constant GRACE_PERIOD_TIME = 1 hours;

    modifier onlyGlobalAdmin() {
        //global admin will be able to have access to other tranches, also can set portion of reserve taken as fee for VMEX admin
        _onlyGlobalAdmin();
        _;
    }

    function _onlyGlobalAdmin() internal view {
        //this contract handles the updates to the configuration
        require(
            _addressProvider.getGlobalAdmin() == msg.sender,
            Errors.CALLER_NOT_GLOBAL_ADMIN
        );
    }

    function initialize (
        ILendingPoolAddressesProvider provider
    ) public initializer {
        _addressProvider = provider;
        _assetMappings = IAssetMappings(_addressProvider.getAssetMappings());
    }

    /**
     * @dev Sets the base currency that all other assets are priced based on. Can only be set once
     * @param baseCurrency The address of the base currency
     * @param baseCurrencyDecimals amount of decimals that the chainlink aggregator assumes for price feeds with this currency as the base
     * @param baseCurrencyUnit What price the base currency is. Usually this is just 10 ** how many decimals the base currency has
     * @param baseCurrencyString "ETH" or "USD" for purposes of checking correct denomination
     **/
    function setBaseCurrency(
        address baseCurrency,
        uint256 baseCurrencyDecimals,
        uint256 baseCurrencyUnit,
        string calldata baseCurrencyString
    ) external onlyGlobalAdmin {
        require(BASE_CURRENCY == address(0), Errors.VO_BASE_CURRENCY_SET_ONLY_ONCE);
        BASE_CURRENCY = baseCurrency;
        BASE_CURRENCY_DECIMALS = baseCurrencyDecimals;
        BASE_CURRENCY_UNIT = baseCurrencyUnit;
        BASE_CURRENCY_STRING = baseCurrencyString;
    }

    /**
     * @dev External function called by the VMEX governance to set or replace sources of assets
     * @param assets The addresses of the assets
     * @param sources The address of the source of each asset
     * @param checkDenomination true if the description of the chainlink price feed should be checked, false for exceptions
     **/
    function setAssetSources(
        address[] calldata assets,
        ChainlinkData[] calldata sources,
        bool checkDenomination
    ) external onlyGlobalAdmin {
        require(assets.length == sources.length, Errors.ARRAY_LENGTH_MISMATCH);
        uint256 assetsLength = assets.length;
        for (uint256 i; i < assetsLength; ++i) {
            require(!checkDenomination || Helpers.compareSuffix(IChainlinkPriceFeed(sources[i].feed).description(), BASE_CURRENCY_STRING), Errors.VO_BAD_DENOMINATION);
            require(IChainlinkPriceFeed(sources[i].feed).decimals() == BASE_CURRENCY_DECIMALS, Errors.VO_BAD_DECIMALS);
            _assetsSources[assets[i]] = sources[i];
            emit AssetSourceUpdated(assets[i], address(sources[i].feed));
        }
    }

    /**
     * @dev Sets the fallback oracle. Callable only by the VMEX governance
     * @param fallbackOracle The address of the fallbackOracle
     **/
    function setFallbackOracle(address fallbackOracle) external onlyGlobalAdmin {
        _fallbackOracle = IPriceOracleGetter(fallbackOracle);
        emit FallbackOracleUpdated(fallbackOracle);
    }

    function setWETH(
        address weth
    ) external onlyGlobalAdmin {
        require(WETH == address(0), Errors.VO_WETH_SET_ONLY_ONCE);
        WETH = weth;
    }

    function setRETHOracle(
        address _rETHOracle
    ) external onlyGlobalAdmin {
        rETHOracle = IRocketPriceOracle(_rETHOracle);
    }

    /**
     * @dev Sets the sequencerUptimeFeed. Callable only by the VMEX governance
     * @param sequencerUptimeFeed The address of the sequencerUptimeFeed
     **/
    function setSequencerUptimeFeed(uint256 chainId, address sequencerUptimeFeed) external onlyGlobalAdmin {
        sequencerUptimeFeeds[chainId] = AggregatorV3Interface(sequencerUptimeFeed);
        emit SequencerUptimeFeedUpdated(chainId, sequencerUptimeFeed);
    }

    /**
     * @dev Checks if sequencer is up. If not, reverts. If sequencer came back online, need to wait for the grace period before resuming
     **/
    function checkSequencerUp() internal view {
        AggregatorV3Interface seqUpFeed = sequencerUptimeFeeds[block.chainid];

        if(address(seqUpFeed)!=address(0)) {
            // prettier-ignore
            (
                /*uint80 roundID*/,
                int256 answer,
                uint256 startedAt,
                /*uint256 updatedAt*/,
                /*uint80 answeredInRound*/
            ) = seqUpFeed.latestRoundData();

            // Answer == 0: Sequencer is up
            // Answer == 1: Sequencer is down
            bool isSequencerUp = answer == 0;
            require(isSequencerUp, Errors.VO_SEQUENCER_DOWN);

            // Make sure the grace period has passed after the sequencer is back up.
            uint256 timeSinceUp = block.timestamp - startedAt;

            require(timeSinceUp > GRACE_PERIOD_TIME, Errors.VO_SEQUENCER_GRACE_PERIOD_NOT_OVER);
        }
    }

    /**
     * @dev Gets an asset price by address. 
     * Note the result should always have 18 decimals if using ETH as base. If using USD as base, there will be 8 decimals
     * @param asset The asset address
     **/
    function getAssetPrice(address asset)
        public
        override
        returns (uint256)
    {
        if (asset == BASE_CURRENCY) {
            return BASE_CURRENCY_UNIT;
        }

        checkSequencerUp();

        DataTypes.ReserveAssetType tmp = _assetMappings.getAssetType(asset);

        if(tmp==DataTypes.ReserveAssetType.CHAINLINK){
            return getChainlinkAssetPrice(asset);
        }
        else if(tmp==DataTypes.ReserveAssetType.CURVE || tmp==DataTypes.ReserveAssetType.CURVEV2){
            return getCurveAssetPrice(asset, tmp);
        }
        else if(tmp==DataTypes.ReserveAssetType.YEARN){
            return getYearnPrice(asset);
        }
        else if(tmp==DataTypes.ReserveAssetType.BEEFY) {
            return getBeefyPrice(asset);
        }
        else if(tmp==DataTypes.ReserveAssetType.VELODROME) {
            return getVeloPrice(asset);
        }
        else if(tmp == DataTypes.ReserveAssetType.BEETHOVEN) {
            return getBeethovenPrice(asset);
        }
        else if (tmp == DataTypes.ReserveAssetType.RETH) {
            return getRETHPrice(asset);
        }
        else if (tmp == DataTypes.ReserveAssetType.CL_PRICE_ADAPTER) {
            return getCLPriceAdapterPrice(asset);
        }
        else if (tmp == DataTypes.ReserveAssetType.CAMELOT) {
            return getCamelotPrice(asset);
        }
        else if (tmp == DataTypes.ReserveAssetType.BACKED) {
            return getBackedAssetPrice(asset);
        }
        revert(Errors.VO_ORACLE_ADDRESS_NOT_FOUND);
    }

    /**
     * @dev Gets an asset price for an asset with a chainlink aggregator
     * @param asset The asset address
     **/
    function getChainlinkAssetPrice(address asset) internal returns (uint256){
        IChainlinkPriceFeed source = _assetsSources[asset].feed;
        if (address(source) == address(0)) {
            return _fallbackOracle.getAssetPrice(asset);
        } else {
            try IChainlinkPriceFeed(source).latestRoundData() returns (
                uint80,
                int256 price,
                uint,
                uint256 updatedAt,
                uint80
            ) {
                IChainlinkAggregator aggregator = IChainlinkAggregator(IChainlinkPriceFeed(source).aggregator());
                if (price > int256(aggregator.minAnswer()) && 
                    price < int256(aggregator.maxAnswer()) && 
                    block.timestamp - updatedAt < _assetsSources[asset].heartbeat
                ) {
                    return uint256(price);
                } else {
                    return _fallbackOracle.getAssetPrice(asset);
                }
            } catch {
                return _fallbackOracle.getAssetPrice(asset);
            }
        }
    }

    /**
     * @dev Gets an asset price for an asset with a chainlink aggregator but in the wrong units. Uses Aave's adapter: https://basescan.org/address/0x80f2c02224a2e548fc67c0bf705ebfa825dd5439#code
     * @param asset The asset address
     **/
    function getCLPriceAdapterPrice(address asset) internal returns (uint256){
        IChainlinkPriceFeed source = _assetsSources[asset].feed;
        if (address(source) == address(0)) {
            return _fallbackOracle.getAssetPrice(asset);
        } else {
            try IChainlinkPriceFeed(source).latestAnswer() returns (
                int256 price
            ) {
                if (price > 0) {
                    return uint256(price);
                } else {
                    return _fallbackOracle.getAssetPrice(asset);
                }
            } catch {
                return _fallbackOracle.getAssetPrice(asset);
            }
        }
    }

    /**
     * @dev Gets an asset price for an asset with a chainlink aggregator
     * @param asset The asset address
     **/
    function getBackedAssetPrice(address asset) internal returns (uint256){
        IChainlinkPriceFeed source = _assetsSources[asset].feed;
        if (address(source) == address(0)) {
            return _fallbackOracle.getAssetPrice(asset);
        } else {
            try IChainlinkPriceFeed(source).latestRoundData() returns (
                uint80,
                int256 price,
                uint,
                uint256 updatedAt,
                uint80
            ) {
                if (block.timestamp - updatedAt < _assetsSources[asset].heartbeat) {
                    return uint256(price);
                } else {
                    return _fallbackOracle.getAssetPrice(asset);
                }
            } catch {
                return _fallbackOracle.getAssetPrice(asset);
            }
        }
    }

    /**
     * @dev Gets an asset price for an asset with a chainlink aggregator
     * @param asset The asset address
     **/
    function getCurveAssetPrice(
        address asset,
        DataTypes.ReserveAssetType assetType
    ) internal returns (uint256 price) {
        DataTypes.CurveMetadata memory c = _assetMappings.getCurveMetadata(asset);

        if (!Address.isContract(c._curvePool)) {
            return _fallbackOracle.getAssetPrice(asset);
        }

        uint256 poolSize = c._poolSize;

        uint256[] memory prices = new uint256[](poolSize);

        for (uint256 i; i < poolSize;) {
            address underlying = ICurvePool(c._curvePool).coins(i);
            if(underlying == ETH_NATIVE){
                underlying = WETH;
            }
            prices[i] = getAssetPrice(underlying); //handles case where underlying is curve too.
            require(prices[i] != 0, Errors.VO_UNDERLYING_FAIL);

            unchecked { ++i; }
        }

        if(assetType==DataTypes.ReserveAssetType.CURVE){
            price = CurveOracle.get_price_v1(c._curvePool, prices, c._reentrancyType);
        }
        else if(assetType==DataTypes.ReserveAssetType.CURVEV2){
            price = CurveOracle.get_price_v2(c._curvePool, prices, c._reentrancyType);
        }
        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }
        return price;
    }

    /**
     * @dev Gets an asset price for a velodrome (or chronos) token
     * @param asset The asset address
     **/
    function getVeloPrice(
        address asset
    ) internal returns (uint256 price) {
        uint256[] memory prices = new uint256[](2);

        (address token0, address token1) = IVeloPair(asset).tokens();

        if(token0 == ETH_NATIVE){
            token0 = WETH;
        }
        prices[0] = getAssetPrice(token0); //handles case where underlying is curve too.
        require(prices[0] != 0, Errors.VO_UNDERLYING_FAIL);

        if(token1 == ETH_NATIVE){
            token1 = WETH;
        }
        prices[1] = getAssetPrice(token1); //handles case where underlying is curve too.
        require(prices[1] != 0, Errors.VO_UNDERLYING_FAIL);

        price = VelodromeOracle.get_lp_price(asset, prices, BASE_CURRENCY_DECIMALS); //has 18 decimals

        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }

        return price;
    }

    /**
     * @dev Gets an asset price for a Camelot token
     * @param asset The asset address
     **/
    function getCamelotPrice(
        address asset
    ) internal returns (uint256 price) {
        uint256[] memory prices = new uint256[](2);

        address token0 = ICamelotPair(asset).token0();
        address token1 = ICamelotPair(asset).token1();

        token0 = token0 == ETH_NATIVE ? WETH : token0;
        prices[0] = getAssetPrice(token0); //handles case where underlying is curve too.
        require(prices[0] != 0, Errors.VO_UNDERLYING_FAIL);

        token1 = token1 == ETH_NATIVE ? WETH : token1;
        prices[1] = getAssetPrice(token1); //handles case where underlying is curve too.
        require(prices[1] != 0, Errors.VO_UNDERLYING_FAIL);

        price = VelodromeOracle.get_cmlt_lp_price(asset, prices, BASE_CURRENCY_DECIMALS); //has 18 decimals

        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }

        return price;
    }

    /**
     * @dev Gets an asset price for a beethoven or balancer token
     * @param asset The asset address
     **/
    function getBeethovenPrice(
        address asset
    ) internal returns (uint256) {
        DataTypes.BeethovenMetadata memory md = _assetMappings.getBeethovenMetadata(asset);

        uint256 price = BalancerOracle.get_lp_price(
            address(this),
            asset,
            md._typeOfPool,
            md._legacy
        );

        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }
        return price;
    }

    /**
     * @dev Gets an asset price for a yearn token
     * @param asset The asset address
     **/
    function getYearnPrice(address asset) internal returns (uint256){
        IYearnToken yearnVault = IYearnToken(asset);
        uint256 underlyingPrice = getAssetPrice(yearnVault.token()); //getAssetPrice() will always have 18 decimals for Aave and Curve tokens (prices in eth), or 8 decimals if prices in USD
        //note: pricePerShare has decimals equal to underlying tokens (ex: yvUSDC has 6 decimals). By dividing by 10**yearnVault.decimals(), we keep the decimals of underlyingPrice which is 18 decimals for eth base, 8 for usd base.
        uint256 price = yearnVault.pricePerShare()*underlyingPrice / 10**yearnVault.decimals();
        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }
        return price;
    }

    /**
     * @dev Gets an asset price for a beefy token
     * @param asset The asset address
     **/
	function getBeefyPrice(address asset) internal returns (uint256) {
        IBeefyVault beefyVault = IBeefyVault(asset);
        uint256 underlyingPrice = getAssetPrice(beefyVault.want());
        uint256 price = beefyVault.getPricePerFullShare()*underlyingPrice / 10**beefyVault.decimals();
        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }
        return price;
	}

    /**
     * @dev Gets an asset price for a rETH token
     * @param asset The asset address
     **/
	function getRETHPrice(address asset) internal returns (uint256) {
        uint256 underlyingPrice = getAssetPrice(WETH);
        uint256 price = rETHOracle.rate()*underlyingPrice / 10**18;
        if(price == 0){
            return _fallbackOracle.getAssetPrice(asset);
        }
        return price;
	}

    /// @notice Gets a list of prices from a list of assets addresses
    /// @param assets The list of assets addresses
    function getAssetsPrices(address[] calldata assets)
        external
        returns (uint256[] memory)
    {
        uint256[] memory prices = new uint256[](assets.length);
        for (uint256 i; i < assets.length;) {
            prices[i] = getAssetPrice(assets[i]);

            unchecked { ++i; }
        }
        return prices;
    }

    /// @notice Gets the address of the source for an asset address
    /// @param asset The address of the asset
    /// @return address The address of the source
    function getSourceOfAsset(address asset) external view returns (address) {
        return address(_assetsSources[asset].feed);
    }

    /// @notice Gets the address of the fallback oracle
    /// @return address The addres of the fallback oracle
    function getFallbackOracle() external view returns (address) {
        return address(_fallbackOracle);
    }

    //Just used for calling curve remove liquidity. Without this, remove_liquidity cannot find function selector receive()
    receive() external payable {
	}
}