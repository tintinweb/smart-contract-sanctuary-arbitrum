// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { OnlyDolomiteMarginForUpgradeable } from "../helpers/OnlyDolomiteMarginForUpgradeable.sol";
import { ProxyContractHelpers } from "../helpers/ProxyContractHelpers.sol";
import { IDolomiteRegistry } from "../interfaces/IDolomiteRegistry.sol";
import { IGenericTraderProxyV1 } from "../interfaces/IGenericTraderProxyV1.sol";
import { ValidationLib } from "../lib/ValidationLib.sol";


/**
 * @title   DolomiteRegistryImplementation
 * @author  Dolomite
 *
 * @notice  Registry contract for storing Dolomite-related addresses
 */
contract DolomiteRegistryImplementation is
    IDolomiteRegistry,
    ProxyContractHelpers,
    OnlyDolomiteMarginForUpgradeable,
    Initializable
{

    // ===================== Constants =====================

    bytes32 private constant _FILE = "DolomiteRegistryImplementation";
    bytes32 private constant _GENERIC_TRADER_PROXY_SLOT = bytes32(uint256(keccak256("eip1967.proxy.genericTraderProxy")) - 1);

    // ==================== Constructor ====================

    function initialize(
        address _genericTraderProxy
    ) external initializer {
        _ownerSetGenericTraderProxy(_genericTraderProxy);
    }

    // ===================== Functions =====================

    function ownerSetGenericTraderProxy(
        address _genericTraderProxy
    )
    external
    onlyDolomiteMarginOwner(msg.sender) {
        _ownerSetGenericTraderProxy(_genericTraderProxy);
    }

    function genericTraderProxy() external view returns (IGenericTraderProxyV1) {
        return IGenericTraderProxyV1(_getAddress(_GENERIC_TRADER_PROXY_SLOT));
    }

    // ===================== Internal Functions =====================

    function _ownerSetGenericTraderProxy(
        address _genericTraderProxy
    ) internal {
        Require.that(
            _genericTraderProxy != address(0),
            _FILE,
            "Invalid genericTraderProxy"
        );
        bytes memory returnData = ValidationLib.callAndCheckSuccess(
            _genericTraderProxy,
            IGenericTraderProxyV1(_genericTraderProxy).MARGIN_POSITION_REGISTRY.selector,
            bytes("")
        );
        abi.decode(returnData, (address));

        _setAddress(_GENERIC_TRADER_PROXY_SLOT, _genericTraderProxy);
        emit GenericTraderProxySet(_genericTraderProxy);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";
import { Require } from "../../protocol/lib/Require.sol";
import { IOnlyDolomiteMargin } from "../interfaces/IOnlyDolomiteMargin.sol";
import { ProxyContractHelpers } from "./ProxyContractHelpers.sol";


/**
 * @title   OnlyDolomiteMarginForUpgradeable
 * @author  Dolomite
 *
 * @notice  Inheritable contract that restricts the calling of certain functions to `DolomiteMargin`, the owner of
 *          `DolomiteMargin` or a `DolomiteMargin` global operator
 */
abstract contract OnlyDolomiteMarginForUpgradeable is IOnlyDolomiteMargin, ProxyContractHelpers {

    // ============ Constants ============

    bytes32 private constant _FILE = "OnlyDolomiteMargin";
    bytes32 private constant _DOLOMITE_MARGIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.dolomiteMargin")) - 1);

    // ============ Modifiers ============

    modifier onlyDolomiteMargin(address _from) {
        Require.that(
            _from == address(DOLOMITE_MARGIN()),
            _FILE,
            "Only Dolomite can call function",
            _from
        );
        _;
    }

    modifier onlyDolomiteMarginOwner(address _from) {
        Require.that(
            _from == DOLOMITE_MARGIN().owner(),
            _FILE,
            "Caller is not owner of Dolomite",
            _from
        );
        _;
    }

    modifier onlyDolomiteMarginGlobalOperator(address _from) {
        Require.that(
            DOLOMITE_MARGIN().getIsGlobalOperator(_from),
            _FILE,
            "Caller is not a global operator",
            _from
        );
        _;
    }

    // ============ Functions ============

    function DOLOMITE_MARGIN() public virtual view returns (IDolomiteMargin) {
        return IDolomiteMargin(_getAddress(_DOLOMITE_MARGIN_SLOT));
    }

    function _setDolomiteMarginViaSlot(address _dolomiteMargin) internal {
        _setAddress(_DOLOMITE_MARGIN_SLOT, _dolomiteMargin);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   ProxyContractHelpers
 * @author  Dolomite
 *
 * @notice  Helper functions for upgradeable proxy contracts to use
 */
abstract contract ProxyContractHelpers {

    // ================ Internal Functions ==================

    function _callImplementation(address _implementation) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

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

    function _setAddress(bytes32 slot, address _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function _getAddress(bytes32 slot) internal view returns (address value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }

    function _getUint256(bytes32 slot) internal view returns (uint256 value) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            value := sload(slot)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IGenericTraderProxyV1 } from "./IGenericTraderProxyV1.sol";


/**
 * @title   IDolomiteRegistry
 * @author  Dolomite
 *
 * @notice  A registry contract for storing all of the addresses that can interact with Umami's Delta Neutral vaults
 */
interface IDolomiteRegistry {

    // ========================================================
    // ======================== Events ========================
    // ========================================================

    event GenericTraderProxySet(address indexed _genericTraderProxy);

    // ========================================================
    // =================== Admin Functions ====================
    // ========================================================

    function ownerSetGenericTraderProxy(address _genericTraderProxy) external;

    // ========================================================
    // =================== Getter Functions ===================
    // ========================================================

    function genericTraderProxy() external view returns (IGenericTraderProxyV1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IGenericTraderBase
 * @author  Dolomite
 *
 * @notice  Base contract structs/params for a generic trader contract.
 */
interface IGenericTraderBase {

    // ============ Enums ============

    enum TraderType {
        /// @dev    The trade will be conducted using external liquidity, using an `ActionType.Sell` or `ActionType.Buy`
        ///         action.
        ExternalLiquidity,
        /// @dev    The trade will be conducted using internal liquidity, using an `ActionType.Trade` action.
        InternalLiquidity,
        /// @dev    The trade will be conducted using external liquidity using an `ActionType.Sell` or `ActionType.Buy`
        ///         action. If this TradeType is used, the trader must be validated using
        ///         the `IIsolationModeToken#isTokenConverterTrusted` function on the IsolationMode token.
        IsolationModeUnwrapper,
        /// @dev    The trade will be conducted using external liquidity using an `ActionType.Sell` or `ActionType.Buy`
        ///         action. If this TradeType is used, the trader must be validated using
        ///         the `IIsolationModeToken#isTokenConverterTrusted` function on the IsolationMode token.
        IsolationModeWrapper
    }

    // ============ Structs ============

    struct TraderParam {
        /// @dev The type of trade to conduct
        TraderType traderType;
        /// @dev    The index into the `_makerAccounts` array of the maker account to trade with. Should be set to 0 if
        ///         the traderType is not `TraderType.InternalLiquidity`.
        uint256 makerAccountIndex;
        /// @dev The address of IAutoTrader or IExchangeWrapper that will be used to conduct the trade.
        address trader;
        /// @dev The data that will be passed through to the trader contract.
        bytes tradeData;
    }

    struct GenericTraderProxyCache {
        IDolomiteMargin dolomiteMargin;
        /// @dev    True if the user is making a margin deposit, false if they are withdrawing. False if the variable is
        ///         unused too.
        bool isMarginDeposit;
        /// @dev    The other account number that is not `_traderAccountNumber`. Only used for TransferCollateralParams.
        uint256 otherAccountNumber;
        /// @dev    The index into the account array at which traders start.
        uint256 traderAccountStartIndex;
        /// @dev    The cursor for the looping through the operation's actions.
        uint256 actionsCursor;
        /// @dev    The balance of `inputMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei inputBalanceWeiBeforeOperate;
        /// @dev    The balance of `outputMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei outputBalanceWeiBeforeOperate;
        /// @dev    The balance of `transferMarket` that the trader has before the call to `dolomiteMargin.operate`
        IDolomiteMargin.Wei transferBalanceWeiBeforeOperate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";

import { IGenericTraderBase } from "./IGenericTraderBase.sol";


/**
 * @title IGenericTraderProxyV1
 * @author Dolomite
 *
 * Trader proxy interface for trading assets using any trader from msg.sender
 */
interface IGenericTraderProxyV1 is IGenericTraderBase {

    // ============ Structs ============

    struct TransferAmount {
        /// @dev The market ID to transfer
        uint256 marketId;
        /// @dev Note, setting to uint(-1) will transfer all of the user's balance.
        uint256 amountWei;
    }

    struct TransferCollateralParam {
        /// @dev The account number from which collateral will be transferred.
        uint256 fromAccountNumber;
        /// @dev The account number to which collateral will be transferred.
        uint256 toAccountNumber;
        /// @dev The transfers to execute after all of the trades.
        TransferAmount[] transferAmounts;
    }

    struct ExpiryParam {
        /// @dev The market ID whose expiry will be updated.
        uint256 marketId;
        /// @dev The new expiry time delta for the market. Setting this to `0` will reset the expiration.
        uint32 expiryTimeDelta;
    }

    // ============ Functions ============

    /**
     * @dev     Swaps an exact amount of input (specified in the `_amountWeisPath[0]` parameter) for at least
     *          `_amountWeisPath[_amountWeisPath.length - 1]` of output.
     *
     * @param _tradeAccountNumber           The account number to use for msg.sender's trade
     * @param _marketIdsPath                The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param _amountWeisPath               The path of amounts (in wei) to use for each trade action. Length should be
     *                                      equal to `_tradersPath.length + 1`. Setting a value to `uint(-1)` will use
     *                                      the user's full balance for the trade at that part in the path. Caution must
     *                                      be taken when using this parameter for frontends that call this function.
     * @param _tradersPath                  The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1` and `_amountWeisPath.length - 1`.
     * @param _makerAccounts                The accounts that will be used for the maker side of the trades involving
     *                                      `TraderType.InternalLiquidity`.
     */
    function swapExactInputForOutput(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256[] calldata _amountWeisPath,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts
    )
    external;

    /**
     * @dev     The same function as `swapExactInputForOutput`, but allows the caller transfer collateral and modify
     *          their position's expiration in the same transaction.
     *
     * @param _tradeAccountNumber           The account number to use for msg.sender's trade
     * @param _marketIdsPath                The path of market IDs to use for each trade action. Length should be equal
     *                                      to `_tradersPath.length + 1`.
     * @param _amountWeisPath               The path of amounts (in wei) to use for each trade action. Length should be
     *                                      equal to `_tradersPath.length + 1`. Setting a value to `uint(-1)` will use
     *                                      the user's full balance for the trade at that part in the path. Caution must
     *                                      be taken when using this parameter for frontends that call this function.
     * @param _tradersPath                  The path of traders to use for each trade action. Length should be equal to
     *                                      `_marketIdsPath.length - 1` and `_amountWeisPath.length - 1`.
     * @param _makerAccounts                The accounts that will be used for the maker side of the trades involving
                                            `TraderType.InternalLiquidity`.
     * @param _transferCollateralParams     The parameters for transferring collateral in/out of the
     *                                      `_tradeAccountNumber` once the trades settle. One of
     *                                      `_params.fromAccountNumber` or `_params.toAccountNumber` must be equal to
     *                                      `_tradeAccountNumber`.
     * @param _expiryParams                 The parameters for modifying the expiration of the debt in the position.
     */
    function swapExactInputForOutputAndModifyPosition(
        uint256 _tradeAccountNumber,
        uint256[] calldata _marketIdsPath,
        uint256[] calldata _amountWeisPath,
        IGenericTraderBase.TraderParam[] calldata _tradersPath,
        IDolomiteMargin.AccountInfo[] calldata _makerAccounts,
        TransferCollateralParam calldata _transferCollateralParams,
        ExpiryParam calldata _expiryParams
    )
    external;

    function EXPIRY() external view returns (address);

    function MARGIN_POSITION_REGISTRY() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteMargin } from "../../protocol/interfaces/IDolomiteMargin.sol";


/**
 * @title   IOnlyDolomiteMargin
 * @author  Dolomite
 *
 * @notice  This interface is for contracts that need to add modifiers for only DolomiteMargin / Owner caller.
 */
interface IOnlyDolomiteMargin {

    function DOLOMITE_MARGIN() external view returns (IDolomiteMargin);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { Require } from "../../protocol/lib/Require.sol";


/**
 * @title   ValidationLib
 * @author  Dolomite
 *
 * @notice  Library contract that checks generic calls to be successful (useful when validation config changes)
 */
library ValidationLib {
    // ============ Constants ============

    bytes32 private constant _FILE = "ValidationLib";

    // ============ Functions ============

    /**
     *  Converts the scaled Par value to an actual Wei value
     */
    function callAndCheckSuccess(
        address _target,
        bytes4 _selector,
        bytes memory _data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returnData) = _target.staticcall(abi.encodePacked(_selector, _data));
        Require.that(
            success && returnData.length > 0,
            _FILE,
            "Call to target failed",
            _target
        );
        return returnData;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;


/**
 * @title   IDolomiteInterestSetter
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that for an interest setter that can be used to determine the interest
 *          rate of a market.
 */
interface IDolomiteInterestSetter {

    // ============ Enum ============

    enum InterestSetterType {
        None,
        Linear,
        DoubleExponential
    }

    // ============ Structs ============

    struct InterestRate {
        uint256 value;
    }

    // ============ Functions ============

    /**
     * Get the interest rate of a token given some borrowed and supplied amounts
     *
     * @param  token        The address of the ERC20 token for the market
     * @param  borrowWei    The total borrowed token amount for the market
     * @param  supplyWei    The total supplied token amount for the market
     * @return              The interest rate per second
     */
    function getInterestRate(
        address token,
        uint256 borrowWei,
        uint256 supplyWei
    )
    external
    view
    returns (InterestRate memory);

    function interestSetterType() external pure returns (InterestSetterType);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomiteMarginAdmin } from "./IDolomiteMarginAdmin.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteMargin
 * @author  Dolomite
 *
 * @notice  The interface for interacting with the main entry-point to DolomiteMargin
 */
interface IDolomiteMargin is IDolomiteMarginAdmin {

    // ==================================================
    // ================= Write Functions ================
    // ==================================================

    /**
     * The main entry-point to DolomiteMargin that allows users and contracts to manage accounts.
     * Take one or more actions on one or more accounts. The msg.sender must be the owner or
     * operator of all accounts except for those being liquidated, vaporized, or traded with.
     * One call to operate() is considered a singular "operation". Account collateralization is
     * ensured only after the completion of the entire operation.
     *
     * @param  accounts  A list of all accounts that will be used in this operation. Cannot contain
     *                   duplicates. In each action, the relevant account will be referred-to by its
     *                   index in the list.
     * @param  actions   An ordered list of all actions that will be taken in this operation. The
     *                   actions will be processed in order.
     */
    function operate(
        AccountInfo[] calldata accounts,
        ActionArgs[] calldata actions
    ) external;

    /**
     * Approves/disapproves any number of operators. An operator is an external address that has the
     * same permissions to manipulate an account as the owner of the account. Operators are simply
     * addresses and therefore may either be externally-owned Ethereum accounts OR smart contracts.
     *
     * Operators are also able to act as AutoTrader contracts on behalf of the account owner if the
     * operator is a smart contract and implements the IAutoTrader interface.
     *
     * @param  args  A list of OperatorArgs which have an address and a boolean. The boolean value
     *               denotes whether to approve (true) or revoke approval (false) for that address.
     */
    function setOperators(
        OperatorArg[] calldata args
    ) external;

    // ==================================================
    // ================= Read Functions ================
    // ==================================================

    // ============ Getters for Markets ============

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  token    The token to query
     * @return          The token's marketId if the token is valid
     */
    function getMarketIdByTokenAddress(
        address token
    ) external view returns (uint256);

    /**
     * Get the ERC20 token address for a market.
     *
     * @param  marketId  The market to query
     * @return           The token address
     */
    function getMarketTokenAddress(
        uint256 marketId
    ) external view returns (address);

    /**
     * Return true if a particular market is in closing mode. Additional borrows cannot be taken
     * from a market that is closing.
     *
     * @param  marketId  The market to query
     * @return           True if the market is closing
     */
    function getMarketIsClosing(
        uint256 marketId
    )
    external
    view
    returns (bool);

    /**
     * Get the price of the token for a market.
     *
     * @param  marketId  The market to query
     * @return           The price of each atomic unit of the token
     */
    function getMarketPrice(
        uint256 marketId
    ) external view returns (MonetaryPrice memory);

    /**
     * Get the total number of markets.
     *
     * @return  The number of markets
     */
    function getNumMarkets() external view returns (uint256);

    /**
     * Get the total principal amounts (borrowed and supplied) for a market.
     *
     * @param  marketId  The market to query
     * @return           The total principal amounts
     */
    function getMarketTotalPar(
        uint256 marketId
    ) external view returns (TotalPar memory);

    /**
     * Get the most recently cached interest index for a market.
     *
     * @param  marketId  The market to query
     * @return           The most recent index
     */
    function getMarketCachedIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the interest index for a market if it were to be updated right now.
     *
     * @param  marketId  The market to query
     * @return           The estimated current index
     */
    function getMarketCurrentIndex(
        uint256 marketId
    ) external view returns (InterestIndex memory);

    /**
     * Get the price oracle address for a market.
     *
     * @param  marketId  The market to query
     * @return           The price oracle address
     */
    function getMarketPriceOracle(
        uint256 marketId
    ) external view returns (IDolomitePriceOracle);

    /**
     * Get the interest-setter address for a market.
     *
     * @param  marketId  The market to query
     * @return           The interest-setter address
     */
    function getMarketInterestSetter(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter);

    /**
     * Get the margin premium for a market. A margin premium makes it so that any positions that
     * include the market require a higher collateralization to avoid being liquidated.
     *
     * @param  marketId  The market to query
     * @return           The market's margin premium
     */
    function getMarketMarginPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Get the spread premium for a market. A spread premium makes it so that any liquidations
     * that include the market have a higher spread than the global default.
     *
     * @param  marketId  The market to query
     * @return           The market's spread premium
     */
    function getMarketSpreadPremium(
        uint256 marketId
    ) external view returns (Decimal memory);

    /**
     * Return true if this market can be removed and its ID can be recycled and reused
     *
     * @param  marketId  The market to query
     * @return           True if the market is recyclable
     */
    function getMarketIsRecyclable(
        uint256 marketId
    ) external view returns (bool);

    /**
     * Gets the recyclable markets, up to `n` length. If `n` is greater than the length of the list, 0's are returned
     * for the empty slots.
     *
     * @param  n    The number of markets to get, bounded by the linked list being smaller than `n`
     * @return      The list of recyclable markets, in the same order held by the linked list
     */
    function getRecyclableMarkets(
        uint256 n
    ) external view returns (uint[] memory);

    /**
     * Get the current borrower interest rate for a market.
     *
     * @param  marketId  The market to query
     * @return           The current interest rate
     */
    function getMarketInterestRate(
        uint256 marketId
    ) external view returns (IDolomiteInterestSetter.InterestRate memory);

    /**
     * Get basic information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A Market struct with the current state of the market
     */
    function getMarket(
        uint256 marketId
    ) external view returns (Market memory);

    /**
     * Get comprehensive information about a particular market.
     *
     * @param  marketId  The market to query
     * @return           A tuple containing the values:
     *                    - A Market struct with the current state of the market
     *                    - The current estimated interest index
     *                    - The current token price
     *                    - The current market interest rate
     */
    function getMarketWithInfo(
        uint256 marketId
    )
    external
    view
    returns (
        Market memory,
        InterestIndex memory,
        MonetaryPrice memory,
        IDolomiteInterestSetter.InterestRate memory
    );

    /**
     * Get the number of excess tokens for a market. The number of excess tokens is calculated by taking the current
     * number of tokens held in DolomiteMargin, adding the number of tokens owed to DolomiteMargin by borrowers, and
     * subtracting the number of tokens owed to suppliers by DolomiteMargin.
     *
     * @param  marketId  The market to query
     * @return           The number of excess tokens
     */
    function getNumExcessTokens(
        uint256 marketId
    ) external view returns (Wei memory);

    // ============ Getters for Accounts ============

    /**
     * Get the principal value for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountPar(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the principal value for a particular account and market, with no check the market is valid. Meaning, markets
     * that don't exist return 0.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The principal value
     */
    function getAccountParNoMarketCheck(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Par memory);

    /**
     * Get the token balance for a particular account and market.
     *
     * @param  account   The account to query
     * @param  marketId  The market to query
     * @return           The token amount
     */
    function getAccountWei(
        AccountInfo calldata account,
        uint256 marketId
    ) external view returns (Wei memory);

    /**
     * Get the status of an account (Normal, Liquidating, or Vaporizing).
     *
     * @param  account  The account to query
     * @return          The account's status
     */
    function getAccountStatus(
        AccountInfo calldata account
    ) external view returns (AccountStatus);

    /**
     * Get a list of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256[] memory);

    /**
     * Get the number of markets that have a non-zero balance for an account
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithBalances(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the marketId for an account's market with a non-zero balance at the given index
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountMarketWithBalanceAtIndex(
        AccountInfo calldata account,
        uint256 index
    ) external view returns (uint256);

    /**
     * Get the number of markets with which an account has a negative balance.
     *
     * @param  account  The account to query
     * @return          The non-sorted marketIds with non-zero balance for the account.
     */
    function getAccountNumberOfMarketsWithDebt(
        AccountInfo calldata account
    ) external view returns (uint256);

    /**
     * Get the total supplied and total borrowed value of an account.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account
     *                   - The borrowed value of the account
     */
    function getAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get the total supplied and total borrowed values of an account adjusted by the marginPremium
     * of each market. Supplied values are divided by (1 + marginPremium) for each market and
     * borrowed values are multiplied by (1 + marginPremium) for each market. Comparing these
     * adjusted values gives the margin-ratio of the account which will be compared to the global
     * margin-ratio when determining if the account can be liquidated.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The supplied value of the account (adjusted for marginPremium)
     *                   - The borrowed value of the account (adjusted for marginPremium)
     */
    function getAdjustedAccountValues(
        AccountInfo calldata account
    ) external view returns (MonetaryValue memory, MonetaryValue memory);

    /**
     * Get an account's summary for each market.
     *
     * @param  account  The account to query
     * @return          The following values:
     *                   - The market IDs for each market
     *                   - The ERC20 token address for each market
     *                   - The account's principal value for each market
     *                   - The account's (supplied or borrowed) number of tokens for each market
     */
    function getAccountBalances(
        AccountInfo calldata account
    ) external view returns (uint[] memory, address[] memory, Par[] memory, Wei[] memory);

    // ============ Getters for Account Permissions ============

    /**
     * Return true if a particular address is approved as an operator for an owner's accounts.
     * Approved operators can act on the accounts of the owner as if it were the operator's own.
     *
     * @param  owner     The owner of the accounts
     * @param  operator  The possible operator
     * @return           True if operator is approved for owner's accounts
     */
    function getIsLocalOperator(
        address owner,
        address operator
    ) external view returns (bool);

    /**
     * Return true if a particular address is approved as a global operator. Such an address can
     * act on any account as if it were the operator's own.
     *
     * @param  operator  The address to query
     * @return           True if operator is a global operator
     */
    function getIsGlobalOperator(
        address operator
    ) external view returns (bool);

    /**
     * Checks if the autoTrader can only be called invoked by a global operator
     *
     * @param  autoTrader    The trader that should be checked for special call privileges.
     */
    function getIsAutoTraderSpecial(address autoTrader) external view returns (bool);

    /**
     * @return The address that owns the DolomiteMargin protocol
     */
    function owner() external view returns (address);

    // ============ Getters for Risk Params ============

    /**
     * Get the global minimum margin-ratio that every position must maintain to prevent being
     * liquidated.
     *
     * @return  The global margin-ratio
     */
    function getMarginRatio() external view returns (Decimal memory);

    /**
     * Get the global liquidation spread. This is the spread between oracle prices that incentivizes
     * the liquidation of risky positions.
     *
     * @return  The global liquidation spread
     */
    function getLiquidationSpread() external view returns (Decimal memory);

    /**
     * Get the adjusted liquidation spread for some market pair. This is equal to the global
     * liquidation spread multiplied by (1 + spreadPremium) for each of the two markets.
     *
     * @param  heldMarketId  The market for which the account has collateral
     * @param  owedMarketId  The market for which the account has borrowed tokens
     * @return               The adjusted liquidation spread
     */
    function getLiquidationSpreadForPair(
        uint256 heldMarketId,
        uint256 owedMarketId
    ) external view returns (Decimal memory);

    /**
     * Get the global earnings-rate variable that determines what percentage of the interest paid
     * by borrowers gets passed-on to suppliers.
     *
     * @return  The global earnings rate
     */
    function getEarningsRate() external view returns (Decimal memory);

    /**
     * Get the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     *
     * @return  The global minimum borrow value
     */
    function getMinBorrowedValue() external view returns (MonetaryValue memory);

    /**
     * Get all risk parameters in a single struct.
     *
     * @return  All global risk parameters
     */
    function getRiskParams() external view returns (RiskParams memory);

    /**
     * Get all risk parameter limits in a single struct. These are the maximum limits at which the
     * risk parameters can be set by the admin of DolomiteMargin.
     *
     * @return  All global risk parameter limits
     */
    function getRiskLimits() external view returns (RiskLimits memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";
import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomiteMarginAdmin
 * @author  Dolomite
 *
 * @notice  This interface defines the functions that can be called by the owner of DolomiteMargin.
 */
interface IDolomiteMarginAdmin is IDolomiteStructs {

    // ============ Token Functions ============

    /**
     * Withdraw an ERC20 token for which there is an associated market. Only excess tokens can be withdrawn. The number
     * of excess tokens is calculated by taking the current number of tokens held in DolomiteMargin, adding the number
     * of tokens owed to DolomiteMargin by borrowers, and subtracting the number of tokens owed to suppliers by
     * DolomiteMargin.
     */
    function ownerWithdrawExcessTokens(
        uint256 marketId,
        address recipient
    )
    external
    returns (uint256);

    /**
     * Withdraw an ERC20 token for which there is no associated market.
     */
    function ownerWithdrawUnsupportedTokens(
        address token,
        address recipient
    )
    external
    returns (uint256);

    // ============ Market Functions ============

    /**
     * Sets the number of non-zero balances an account may have within the same `accountIndex`. This ensures a user
     * cannot DOS the system by filling their account with non-zero balances (which linearly increases gas costs when
     * checking collateralization) and disallowing themselves to close the position, because the number of gas units
     * needed to process their transaction exceed the block's gas limit. In turn, this would  prevent the user from also
     * being liquidated, causing the all of the capital to be "stuck" in the position.
     *
     * Lowering this number does not "freeze" user accounts that have more than the new limit of balances, because this
     * variable is enforced by checking the users number of non-zero balances against the max or if it sizes down before
     * each transaction finishes.
     */
    function ownerSetAccountMaxNumberOfMarketsWithBalances(
        uint256 accountMaxNumberOfMarketsWithBalances
    )
    external;

    /**
     * Add a new market to DolomiteMargin. Must be for a previously-unsupported ERC20 token.
     */
    function ownerAddMarket(
        address token,
        IDolomitePriceOracle priceOracle,
        IDolomiteInterestSetter interestSetter,
        Decimal calldata marginPremium,
        Decimal calldata spreadPremium,
        uint256 maxWei,
        bool isClosing,
        bool isRecyclable
    )
    external;

    /**
     * Removes a market from DolomiteMargin, sends any remaining tokens in this contract to `salvager` and invokes the
     * recyclable callback
     */
    function ownerRemoveMarkets(
        uint[] calldata marketIds,
        address salvager
    )
    external;

    /**
     * Set (or unset) the status of a market to "closing". The borrowedValue of a market cannot increase while its
     * status is "closing".
     */
    function ownerSetIsClosing(
        uint256 marketId,
        bool isClosing
    )
    external;

    /**
     * Set the price oracle for a market.
     */
    function ownerSetPriceOracle(
        uint256 marketId,
        IDolomitePriceOracle priceOracle
    )
    external;

    /**
     * Set the interest-setter for a market.
     */
    function ownerSetInterestSetter(
        uint256 marketId,
        IDolomiteInterestSetter interestSetter
    )
    external;

    /**
     * Set a premium on the minimum margin-ratio for a market. This makes it so that any positions that include this
     * market require a higher collateralization to avoid being liquidated.
     */
    function ownerSetMarginPremium(
        uint256 marketId,
        Decimal calldata marginPremium
    )
    external;

    function ownerSetMaxWei(
        uint256 marketId,
        uint256 maxWei
    )
    external;

    /**
     * Set a premium on the liquidation spread for a market. This makes it so that any liquidations that include this
     * market have a higher spread than the global default.
     */
    function ownerSetSpreadPremium(
        uint256 marketId,
        Decimal calldata spreadPremium
    )
    external;

    // ============ Risk Functions ============

    /**
     * Set the global minimum margin-ratio that every position must maintain to prevent being liquidated.
     */
    function ownerSetMarginRatio(
        Decimal calldata ratio
    )
    external;

    /**
     * Set the global liquidation spread. This is the spread between oracle prices that incentivizes the liquidation of
     * risky positions.
     */
    function ownerSetLiquidationSpread(
        Decimal calldata spread
    )
    external;

    /**
     * Set the global earnings-rate variable that determines what percentage of the interest paid by borrowers gets
     * passed-on to suppliers.
     */
    function ownerSetEarningsRate(
        Decimal calldata earningsRate
    )
    external;

    /**
     * Set the global minimum-borrow value which is the minimum value of any new borrow on DolomiteMargin.
     */
    function ownerSetMinBorrowedValue(
        MonetaryValue calldata minBorrowedValue
    )
    external;

    // ============ Global Operator Functions ============

    /**
     * Approve (or disapprove) an address that is permissioned to be an operator for all accounts in DolomiteMargin.
     * Intended only to approve smart-contracts.
     */
    function ownerSetGlobalOperator(
        address operator,
        bool approved
    )
    external;

    /**
     * Approve (or disapprove) an auto trader that can only be called by a global operator. IE for expirations
     */
    function ownerSetAutoTraderSpecial(
        address autoTrader,
        bool special
    )
    external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteStructs } from "./IDolomiteStructs.sol";


/**
 * @title   IDolomitePriceOracle
 * @author  Dolomite
 *
 * @notice  Interface that Price Oracles for DolomiteMargin must implement in order to report prices.
 */
interface IDolomitePriceOracle {

    // ============ Public Functions ============

    /**
     * Get the price of a token
     *
     * @param  token  The ERC20 token address of the market
     * @return        The USD price of a base unit of the token, then multiplied by 10^(36 - decimals).
     *                So a USD-stable coin with 6 decimal places would return `price * 10^30`.
     *                This is the price of the base unit rather than the price of a "human-readable"
     *                token amount. Every ERC20 may have a different number of decimals.
     */
    function getPrice(
        address token
    )
    external
    view
    returns (IDolomiteStructs.MonetaryPrice memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
/*

    Copyright 2023 Dolomite

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

pragma solidity ^0.8.9;

import { IDolomiteInterestSetter } from "./IDolomiteInterestSetter.sol";
import { IDolomitePriceOracle } from "./IDolomitePriceOracle.sol";


/**
 * @title   IDolomiteStructs
 * @author  Dolomite
 *
 * @notice  This interface defines the structs used by DolomiteMargin
 */
interface IDolomiteStructs {

    // ========================= Enums =========================

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    // ========================= Structs =========================

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    /**
     * Most-recently-cached account status.
     *
     * Normal: Can only be liquidated if the account values are violating the global margin-ratio.
     * Liquid: Can be liquidated no matter the account values.
     *         Can be vaporized if there are no more positive account values.
     * Vapor:  Has only negative (or zeroed) account values. Can be vaporized.
     *
     */
    enum AccountStatus {
        Normal,
        Liquid,
        Vapor
    }

    /*
     * Arguments that are passed to DolomiteMargin in an ordered list as part of a single operation.
     * Each ActionArgs has an actionType which specifies which action struct that this data will be
     * parsed into before being processed.
     */
    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Decimal {
        uint256 value;
    }

    struct InterestIndex {
        uint96 borrow;
        uint96 supply;
        uint32 lastUpdate;
    }

    struct Market {
        address token;

        // Whether additional borrows are allowed for this market
        bool isClosing;

        // Whether this market can be removed and its ID can be recycled and reused
        bool isRecyclable;

        // Total aggregated supply and borrow amount of the entire market
        TotalPar totalPar;

        // Interest index of the market
        InterestIndex index;

        // Contract address of the price oracle for this market
        IDolomitePriceOracle priceOracle;

        // Contract address of the interest setter for this market
        IDolomiteInterestSetter interestSetter;

        // Multiplier on the marginRatio for this market, IE 5% (0.05 * 1e18). This number increases the market's
        // required collateralization by: reducing the user's supplied value (in terms of dollars) for this market and
        // increasing its borrowed value. This is done through the following operation:
        // `suppliedWei = suppliedWei + (assetValueForThisMarket / (1 + marginPremium))`
        // This number increases the user's borrowed wei by multiplying it by:
        // `borrowedWei = borrowedWei + (assetValueForThisMarket * (1 + marginPremium))`
        Decimal marginPremium;

        // Multiplier on the liquidationSpread for this market, IE 20% (0.2 * 1e18). This number increases the
        // `liquidationSpread` using the following formula:
        // `liquidationSpread = liquidationSpread * (1 + spreadPremium)`
        // NOTE: This formula is applied up to two times - one for each market whose spreadPremium is greater than 0
        // (when performing a liquidation between two markets)
        Decimal spreadPremium;

        // The maximum amount that can be held by the external. This allows the external to cap any additional risk
        // that is inferred by allowing borrowing against low-cap or assets with increased volatility. Setting this
        // value to 0 is analogous to having no limit. This value can never be below 0.
        Wei maxWei;
    }

    /*
     * The price of a base-unit of an asset. Has `36 - token.decimals` decimals
     */
    struct MonetaryPrice {
        uint256 value;
    }

    struct MonetaryValue {
        uint256 value;
    }

    struct OperatorArg {
        address operator;
        bool trusted;
    }

    struct Par {
        bool sign;
        uint256 value;
    }

    struct RiskLimits {
        // The highest that the ratio can be for liquidating under-water accounts
        uint64 marginRatioMax;
        // The highest that the liquidation rewards can be when a liquidator liquidates an account
        uint64 liquidationSpreadMax;
        // The highest that the supply APR can be for a market, as a proportion of the borrow rate. Meaning, a rate of
        // 100% (1e18) would give suppliers all of the interest that borrowers are paying. A rate of 90% would give
        // suppliers 90% of the interest that borrowers pay.
        uint64 earningsRateMax;
        // The highest min margin ratio premium that can be applied to a particular market. Meaning, a value of 100%
        // (1e18) would require borrowers to maintain an extra 100% collateral to maintain a healthy margin ratio. This
        // value works by increasing the debt owed and decreasing the supply held for the particular market by this
        // amount, plus 1e18 (since a value of 10% needs to be applied as `decimal.plusOne`)
        uint64 marginPremiumMax;
        // The highest liquidation reward that can be applied to a particular market. This percentage is applied
        // in addition to the liquidation spread in `RiskParams`. Meaning a value of 1e18 is 100%. It is calculated as:
        // `liquidationSpread * Decimal.onePlus(spreadPremium)`
        uint64 spreadPremiumMax;
        uint128 minBorrowedValueMax;
    }

    struct RiskParams {
        // Required ratio of over-collateralization
        Decimal marginRatio;

        // Percentage penalty incurred by liquidated accounts
        Decimal liquidationSpread;

        // Percentage of the borrower's interest fee that gets passed to the suppliers
        Decimal earningsRate;

        // The minimum absolute borrow value of an account
        // There must be sufficient incentivize to liquidate undercollateralized accounts
        MonetaryValue minBorrowedValue;

        // The maximum number of markets a user can have a non-zero balance for a given account.
        uint256 accountMaxNumberOfMarketsWithBalances;
    }

    struct TotalPar {
        uint128 borrow;
        uint128 supply;
    }

    struct Wei {
        bool sign;
        uint256 value;
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

    Copyright 2019 dYdX Trading Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

*/

pragma solidity ^0.8.9;


/**
 * @title   Require
 * @author  dYdX
 *
 * @notice  Stringifies parameters to pretty-print revert messages. Costs more gas than regular require()
 */
library Require {

    // ============ Constants ============

    uint256 private constant _ASCII_ZERO = 48; // '0'
    uint256 private constant _ASCII_RELATIVE_ZERO = 87; // 'a' - 10
    uint256 private constant _ASCII_LOWER_EX = 120; // 'x'
    bytes2 private constant _COLON = 0x3a20; // ': '
    bytes2 private constant _COMMA = 0x2c20; // ', '
    bytes2 private constant _LPAREN = 0x203c; // ' <'
    bytes1 private constant _RPAREN = 0x3e; // '>'
    uint256 private constant _FOUR_BIT_MASK = 0xf;

    // ============ Library Functions ============

    function that(
        bool must,
        bytes32 file,
        bytes32 reason
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason)
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        uint256 payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        address payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _RPAREN
                )
            )
            );
        }
    }

    function that(
        bool must,
        bytes32 file,
        bytes32 reason,
        bytes32 payloadA,
        uint256 payloadB,
        uint256 payloadC
    )
    internal
    pure
    {
        if (!must) {
            revert(
            string(
                abi.encodePacked(
                    stringifyTruncated(file),
                    _COLON,
                    stringifyTruncated(reason),
                    _LPAREN,
                    _stringify(payloadA),
                    _COMMA,
                    _stringify(payloadB),
                    _COMMA,
                    _stringify(payloadC),
                    _RPAREN
                )
            )
            );
        }
    }

    // ============ Private Functions ============

    function stringifyTruncated(
        bytes32 input
    )
    internal
    pure
    returns (bytes memory)
    {
        // put the input bytes into the result
        bytes memory result = abi.encodePacked(input);

        // determine the length of the input by finding the location of the last non-zero byte
        for (uint256 i = 32; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // find the last non-zero byte in order to determine the length
            if (result[i] != 0) {
                uint256 length = i + 1;

                /* solhint-disable-next-line no-inline-assembly */
                assembly {
                    mstore(result, length) // r.length = length;
                }

                return result;
            }
        }

        // all bytes are zero
        return new bytes(0);
    }

    function _stringify(
        uint256 input
    )
    private
    pure
    returns (bytes memory)
    {
        if (input == 0) {
            return "0";
        }

        // get the final string length
        uint256 j = input;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }

        // allocate the string
        bytes memory bstr = new bytes(length);

        // populate the string starting with the least-significant character
        j = input;
        for (uint256 i = length; i > 0; ) {
            // reverse-for-loops with unsigned integer
            i--;

            // take last decimal digit
            bstr[i] = bytes1(uint8(_ASCII_ZERO + (j % 10)));

            // remove the last decimal digit
            j /= 10;
        }

        return bstr;
    }

    function _stringify(
        address input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(uint160(input));

        // addresses are "0x" followed by 20 bytes of data which take up 2 characters each
        bytes memory result = new bytes(42);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 20; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[41 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[40 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _stringify(
        bytes32 input
    )
    private
    pure
    returns (bytes memory)
    {
        uint256 z = uint256(input);

        // bytes32 are "0x" followed by 32 bytes of data which take up 2 characters each
        bytes memory result = new bytes(66);

        // populate the result with "0x"
        result[0] = bytes1(uint8(_ASCII_ZERO));
        result[1] = bytes1(uint8(_ASCII_LOWER_EX));

        // for each byte (starting from the lowest byte), populate the result with two characters
        for (uint256 i = 0; i < 32; i++) {
            // each byte takes two characters
            uint256 shift = i * 2;

            // populate the least-significant character
            result[65 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;

            // populate the most-significant character
            result[64 - shift] = _char(z & _FOUR_BIT_MASK);
            z = z >> 4;
        }

        return result;
    }

    function _char(
        uint256 input
    )
    private
    pure
    returns (bytes1)
    {
        // return ASCII digit (0-9)
        if (input < 10) {
            return bytes1(uint8(input + _ASCII_ZERO));
        }

        // return ASCII letter (a-f)
        return bytes1(uint8(input + _ASCII_RELATIVE_ZERO));
    }
}