// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
pragma solidity 0.8.17;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IGNSBorrowingFees.sol";
import "../interfaces/IGNSTradingStorage.sol";
import "../interfaces/IGNSPairInfos.sol";

import "../libraries/ChainUtils.sol";
import "../libraries/PriceImpactUtils.sol";

/**
 * @custom:version 6.4.2
 * @custom:oz-upgrades-unsafe-allow external-library-linking
 */
contract GNSBorrowingFees is Initializable, IGNSBorrowingFees {
    // Constants
    uint256 constant P_1 = 1e10;
    uint256 constant P_2 = 1e40;

    // Addresses
    IGNSTradingStorage public storageT;
    IGNSPairInfos public pairInfos;

    // State
    mapping(uint16 => Group) public groups;
    mapping(uint256 => Pair) public pairs;
    mapping(address => mapping(uint256 => mapping(uint256 => InitialAccFees))) public initialAccFees;
    mapping(uint256 => PairOi) public pairOis;
    mapping(uint256 => uint48) public groupFeeExponents;

    // v6.4.2 Storage & state
    PriceImpactUtils.OiWindowsStorage private oiWindowsStorage;

    function initialize(IGNSTradingStorage _storageT, IGNSPairInfos _pairInfos) external initializer {
        require(address(_storageT) != address(0) && address(_pairInfos) != address(0), "WRONG_PARAMS");

        storageT = _storageT;
        pairInfos = _pairInfos;
    }

    function initializeV2(uint48 _windowsDuration) external reinitializer(2) {
        PriceImpactUtils.initializeOiWindowsSettings(_windowsDuration);
    }

    // Modifiers
    modifier onlyManager() {
        require(msg.sender == pairInfos.manager(), "MANAGER_ONLY");
        _;
    }

    modifier onlyCallbacks() {
        require(msg.sender == storageT.callbacks(), "CALLBACKS_ONLY");
        _;
    }

    // Manage pair params
    function setPairParams(uint256 pairIndex, PairParams calldata value) external onlyManager {
        _setPairParams(pairIndex, value);
    }

    function setPairParamsArray(uint256[] calldata indices, PairParams[] calldata values) external onlyManager {
        uint256 len = indices.length;
        require(len == values.length, "WRONG_LENGTH");

        for (uint256 i; i < len; ) {
            _setPairParams(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _setPairParams(uint256 pairIndex, PairParams calldata value) private {
        require(value.feeExponent >= 1 && value.feeExponent <= 3, "WRONG_EXPONENT");

        Pair storage p = pairs[pairIndex];

        uint16 prevGroupIndex = getPairGroupIndex(pairIndex);
        uint256 currentBlock = ChainUtils.getBlockNumber();

        _setPairPendingAccFees(pairIndex, currentBlock);

        if (value.groupIndex != prevGroupIndex) {
            _setGroupPendingAccFees(prevGroupIndex, currentBlock);
            _setGroupPendingAccFees(value.groupIndex, currentBlock);

            (uint256 oiLong, uint256 oiShort) = getPairOpenInterestDai(pairIndex);

            // Only remove OI from old group if old group is not 0
            _setGroupOi(prevGroupIndex, true, false, oiLong);
            _setGroupOi(prevGroupIndex, false, false, oiShort);

            // Add OI to new group if it's not group 0 (even if old group is 0)
            // So when we assign a pair to a group, it takes into account its OI
            // And group 0 OI will always be 0 but it doesn't matter since it's not used
            _setGroupOi(value.groupIndex, true, true, oiLong);
            _setGroupOi(value.groupIndex, false, true, oiShort);

            Group memory newGroup = groups[value.groupIndex];
            Group memory prevGroup = groups[prevGroupIndex];

            p.groups.push(
                PairGroup(
                    value.groupIndex,
                    ChainUtils.getUint48BlockNumber(currentBlock),
                    newGroup.accFeeLong,
                    newGroup.accFeeShort,
                    prevGroup.accFeeLong,
                    prevGroup.accFeeShort,
                    p.accFeeLong,
                    p.accFeeShort,
                    0 // placeholder
                )
            );

            emit PairGroupUpdated(pairIndex, prevGroupIndex, value.groupIndex);
        }

        p.feePerBlock = value.feePerBlock;
        p.feeExponent = value.feeExponent;
        pairOis[pairIndex].max = value.maxOi;

        emit PairParamsUpdated(pairIndex, value.groupIndex, value.feePerBlock, value.feeExponent, value.maxOi);
    }

    // Manage group params
    function setGroupParams(uint16 groupIndex, GroupParams calldata value) external onlyManager {
        _setGroupParams(groupIndex, value);
    }

    function setGroupParamsArray(uint16[] calldata indices, GroupParams[] calldata values) external onlyManager {
        uint256 len = indices.length;
        require(len == values.length, "WRONG_LENGTH");

        for (uint256 i; i < len; ) {
            _setGroupParams(indices[i], values[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _setGroupParams(uint16 groupIndex, GroupParams calldata value) private {
        require(groupIndex > 0, "GROUP_0");
        require(value.feeExponent >= 1 && value.feeExponent <= 3, "WRONG_EXPONENT");

        _setGroupPendingAccFees(groupIndex, ChainUtils.getBlockNumber());

        Group storage g = groups[groupIndex];
        g.feePerBlock = value.feePerBlock;
        g.maxOi = uint80(value.maxOi);
        groupFeeExponents[groupIndex] = value.feeExponent;

        emit GroupUpdated(groupIndex, value.feePerBlock, value.maxOi, value.feeExponent);
    }

    // Group OI setter
    function _setGroupOi(
        uint16 groupIndex,
        bool long,
        bool increase,
        uint256 amount // 1e18
    ) private {
        Group storage group = groups[groupIndex];
        uint112 amountFinal;

        if (groupIndex > 0) {
            amount = (amount * P_1) / 1e18; // 1e10
            require(amount <= type(uint112).max, "OVERFLOW");

            amountFinal = uint112(amount);

            if (long) {
                group.oiLong = increase
                    ? group.oiLong + amountFinal
                    : group.oiLong - (group.oiLong > amountFinal ? amountFinal : group.oiLong);
            } else {
                group.oiShort = increase
                    ? group.oiShort + amountFinal
                    : group.oiShort - (group.oiShort > amountFinal ? amountFinal : group.oiShort);
            }
        }

        emit GroupOiUpdated(groupIndex, long, increase, amountFinal, group.oiLong, group.oiShort);
    }

    // Acc fees getters for pairs and groups
    function getPendingAccFees(
        PendingAccFeesInput memory input
    ) public pure returns (uint64 newAccFeeLong, uint64 newAccFeeShort, uint64 delta) {
        require(input.currentBlock >= input.accLastUpdatedBlock, "BLOCK_ORDER");

        bool moreShorts = input.oiLong < input.oiShort;
        uint256 netOi = moreShorts ? input.oiShort - input.oiLong : input.oiLong - input.oiShort;

        uint256 _delta = input.maxOi > 0 && input.feeExponent > 0
            ? ((input.currentBlock - input.accLastUpdatedBlock) *
                input.feePerBlock *
                ((netOi * 1e10) / input.maxOi) ** input.feeExponent) / (1e18 ** input.feeExponent)
            : 0; // 1e10 (%)

        require(_delta <= type(uint64).max, "OVERFLOW");
        delta = uint64(_delta);

        newAccFeeLong = moreShorts ? input.accFeeLong : input.accFeeLong + delta;
        newAccFeeShort = moreShorts ? input.accFeeShort + delta : input.accFeeShort;
    }

    function getPairGroupAccFeesDeltas(
        uint256 i,
        PairGroup[] memory pairGroups,
        InitialAccFees memory initialFees,
        uint256 pairIndex,
        bool long,
        uint256 currentBlock
    ) public view returns (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) {
        PairGroup memory group = pairGroups[i];

        beforeTradeOpen = group.block < initialFees.block;

        if (i == pairGroups.length - 1) {
            // Last active group
            deltaGroup = getGroupPendingAccFee(group.groupIndex, currentBlock, long);
            deltaPair = getPairPendingAccFee(pairIndex, currentBlock, long);
        } else {
            // Previous groups
            PairGroup memory nextGroup = pairGroups[i + 1];

            // If it's not the first group to be before the trade was opened then fee is 0
            if (beforeTradeOpen && nextGroup.block <= initialFees.block) {
                return (0, 0, beforeTradeOpen);
            }

            deltaGroup = long ? nextGroup.prevGroupAccFeeLong : nextGroup.prevGroupAccFeeShort;
            deltaPair = long ? nextGroup.pairAccFeeLong : nextGroup.pairAccFeeShort;
        }

        if (beforeTradeOpen) {
            deltaGroup -= initialFees.accGroupFee;
            deltaPair -= initialFees.accPairFee;
        } else {
            deltaGroup -= (long ? group.initialAccFeeLong : group.initialAccFeeShort);
            deltaPair -= (long ? group.pairAccFeeLong : group.pairAccFeeShort);
        }
    }

    // Pair acc fees helpers
    function getPairPendingAccFees(
        uint256 pairIndex,
        uint256 currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 pairAccFeeDelta) {
        Pair memory pair = pairs[pairIndex];

        (uint256 pairOiLong, uint256 pairOiShort) = getPairOpenInterestDai(pairIndex);

        (accFeeLong, accFeeShort, pairAccFeeDelta) = getPendingAccFees(
            PendingAccFeesInput(
                pair.accFeeLong,
                pair.accFeeShort,
                pairOiLong,
                pairOiShort,
                pair.feePerBlock,
                currentBlock,
                pair.accLastUpdatedBlock,
                pairOis[pairIndex].max,
                pair.feeExponent
            )
        );
    }

    function getPairPendingAccFee(
        uint256 pairIndex,
        uint256 currentBlock,
        bool long
    ) public view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getPairPendingAccFees(pairIndex, currentBlock);
        return long ? accFeeLong : accFeeShort;
    }

    function _setPairPendingAccFees(
        uint256 pairIndex,
        uint256 currentBlock
    ) private returns (uint64 accFeeLong, uint64 accFeeShort) {
        (accFeeLong, accFeeShort, ) = getPairPendingAccFees(pairIndex, currentBlock);

        Pair storage pair = pairs[pairIndex];

        (pair.accFeeLong, pair.accFeeShort) = (accFeeLong, accFeeShort);
        pair.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(currentBlock);

        emit PairAccFeesUpdated(pairIndex, currentBlock, pair.accFeeLong, pair.accFeeShort);
    }

    // Group acc fees helpers
    function getGroupPendingAccFees(
        uint16 groupIndex,
        uint256 currentBlock
    ) public view returns (uint64 accFeeLong, uint64 accFeeShort, uint64 groupAccFeeDelta) {
        Group memory group = groups[groupIndex];

        (accFeeLong, accFeeShort, groupAccFeeDelta) = getPendingAccFees(
            PendingAccFeesInput(
                group.accFeeLong,
                group.accFeeShort,
                (uint256(group.oiLong) * 1e18) / P_1,
                (uint256(group.oiShort) * 1e18) / P_1,
                group.feePerBlock,
                currentBlock,
                group.accLastUpdatedBlock,
                uint72(group.maxOi),
                groupFeeExponents[groupIndex]
            )
        );
    }

    function getGroupPendingAccFee(
        uint16 groupIndex,
        uint256 currentBlock,
        bool long
    ) public view returns (uint64 accFee) {
        (uint64 accFeeLong, uint64 accFeeShort, ) = getGroupPendingAccFees(groupIndex, currentBlock);
        return long ? accFeeLong : accFeeShort;
    }

    function _setGroupPendingAccFees(
        uint16 groupIndex,
        uint256 currentBlock
    ) private returns (uint64 accFeeLong, uint64 accFeeShort) {
        (accFeeLong, accFeeShort, ) = getGroupPendingAccFees(groupIndex, currentBlock);

        Group storage group = groups[groupIndex];

        (group.accFeeLong, group.accFeeShort) = (accFeeLong, accFeeShort);
        group.accLastUpdatedBlock = ChainUtils.getUint48BlockNumber(currentBlock);

        emit GroupAccFeesUpdated(groupIndex, currentBlock, group.accFeeLong, group.accFeeShort);
    }

    // Interaction with callbacks
    function handleTradeAction(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 positionSizeDai, // 1e18 (collateral * leverage)
        bool open,
        bool long
    ) external override onlyCallbacks {
        uint16 groupIndex = getPairGroupIndex(pairIndex);
        uint256 currentBlock = ChainUtils.getBlockNumber();

        (uint64 pairAccFeeLong, uint64 pairAccFeeShort) = _setPairPendingAccFees(pairIndex, currentBlock);
        (uint64 groupAccFeeLong, uint64 groupAccFeeShort) = _setGroupPendingAccFees(groupIndex, currentBlock);

        _setGroupOi(groupIndex, long, open, positionSizeDai);

        if (open) {
            InitialAccFees memory initialFees = InitialAccFees(
                long ? pairAccFeeLong : pairAccFeeShort,
                long ? groupAccFeeLong : groupAccFeeShort,
                ChainUtils.getUint48BlockNumber(currentBlock),
                0 // placeholder
            );

            initialAccFees[trader][pairIndex][index] = initialFees;

            emit TradeInitialAccFeesStored(trader, pairIndex, index, initialFees.accPairFee, initialFees.accGroupFee);
        }

        emit TradeActionHandled(trader, pairIndex, index, open, long, positionSizeDai);
    }

    // Important trade getters
    function getTradeBorrowingFee(BorrowingFeeInput memory input) public view returns (uint256 fee) {
        InitialAccFees memory initialFees = initialAccFees[input.trader][input.pairIndex][input.index];
        PairGroup[] memory pairGroups = pairs[input.pairIndex].groups;

        uint256 currentBlock = ChainUtils.getBlockNumber();

        PairGroup memory firstPairGroup;
        if (pairGroups.length > 0) {
            firstPairGroup = pairGroups[0];
        }

        // If pair has had no group after trade was opened, initialize with pair borrowing fee
        if (pairGroups.length == 0 || firstPairGroup.block > initialFees.block) {
            fee = ((
                pairGroups.length == 0
                    ? getPairPendingAccFee(input.pairIndex, currentBlock, input.long)
                    : (input.long ? firstPairGroup.pairAccFeeLong : firstPairGroup.pairAccFeeShort)
            ) - initialFees.accPairFee);
        }

        // Sum of max(pair fee, group fee) for all groups the pair was in while trade was open
        for (uint256 i = pairGroups.length; i > 0; ) {
            (uint64 deltaGroup, uint64 deltaPair, bool beforeTradeOpen) = getPairGroupAccFeesDeltas(
                i - 1,
                pairGroups,
                initialFees,
                input.pairIndex,
                input.long,
                currentBlock
            );

            fee += (deltaGroup > deltaPair ? deltaGroup : deltaPair);

            // Exit loop at first group before trade was open
            if (beforeTradeOpen) break;
            unchecked {
                --i;
            }
        }

        fee = (input.collateral * input.leverage * fee) / P_1 / 100; // 1e18 (DAI)
    }

    function getTradeLiquidationPrice(LiqPriceInput calldata input) external view returns (uint256) {
        return
            pairInfos.getTradeLiquidationPricePure(
                input.openPrice,
                input.long,
                input.collateral,
                input.leverage,
                pairInfos.getTradeRolloverFee(input.trader, input.pairIndex, input.index, input.collateral) +
                    getTradeBorrowingFee(
                        BorrowingFeeInput(
                            input.trader,
                            input.pairIndex,
                            input.index,
                            input.long,
                            input.collateral,
                            input.leverage
                        )
                    ),
                pairInfos.getTradeFundingFee(
                    input.trader,
                    input.pairIndex,
                    input.index,
                    input.long,
                    input.collateral,
                    input.leverage
                )
            );
    }

    // Public getters
    function getPairOpenInterestDai(uint256 pairIndex) public view returns (uint256, uint256) {
        return (storageT.openInterestDai(pairIndex, 0), storageT.openInterestDai(pairIndex, 1));
    }

    function getPairGroupIndex(uint256 pairIndex) public view returns (uint16 groupIndex) {
        PairGroup[] memory pairGroups = pairs[pairIndex].groups;
        return pairGroups.length == 0 ? 0 : pairGroups[pairGroups.length - 1].groupIndex;
    }

    // External getters
    function withinMaxGroupOi(
        uint256 pairIndex,
        bool long,
        uint256 positionSizeDai // 1e18
    ) external view returns (bool) {
        Group memory g = groups[getPairGroupIndex(pairIndex)];
        return (g.maxOi == 0) || ((long ? g.oiLong : g.oiShort) + (positionSizeDai * P_1) / 1e18 <= g.maxOi);
    }

    function getGroup(uint16 groupIndex) external view returns (Group memory, uint48) {
        return (groups[groupIndex], groupFeeExponents[groupIndex]);
    }

    function getPair(uint256 pairIndex) external view returns (Pair memory, PairOi memory) {
        return (pairs[pairIndex], pairOis[pairIndex]);
    }

    function getAllPairs() external view returns (Pair[] memory, PairOi[] memory) {
        uint256 len = storageT.priceAggregator().pairsStorage().pairsCount();
        Pair[] memory p = new Pair[](len);
        PairOi[] memory pairOi = new PairOi[](len);

        for (uint256 i; i < len; ) {
            p[i] = pairs[i];
            pairOi[i] = pairOis[i];
            unchecked {
                ++i;
            }
        }

        return (p, pairOi);
    }

    function getGroups(uint16[] calldata indices) external view returns (Group[] memory, uint48[] memory) {
        Group[] memory g = new Group[](indices.length);
        uint48[] memory e = new uint48[](indices.length);
        uint256 len = indices.length;

        for (uint256 i; i < len; ) {
            g[i] = groups[indices[i]];
            e[i] = groupFeeExponents[indices[i]];
            unchecked {
                ++i;
            }
        }

        return (g, e);
    }

    function getTradeInitialAccFees(
        address trader,
        uint256 pairIndex,
        uint256 index
    ) external view returns (InitialAccFees memory borrowingFees, IGNSPairInfos.TradeInitialAccFees memory otherFees) {
        borrowingFees = initialAccFees[trader][pairIndex][index];
        otherFees = pairInfos.tradeInitialAccFees(trader, pairIndex, index);
    }

    function getPairMaxOi(uint256 pairIndex) external view returns (uint256) {
        return pairOis[pairIndex].max;
    }

    /**
     * v6.4.2
     */

    // Setters
    function setPriceImpactWindowsCount(uint48 _newWindowsCount) external onlyManager {
        PriceImpactUtils.setPriceImpactWindowsCount(_newWindowsCount);
    }

    function setPriceImpactWindowsDuration(uint48 _newWindowsDuration) external onlyManager {
        PriceImpactUtils.setPriceImpactWindowsDuration(
            _newWindowsDuration,
            storageT.priceAggregator().pairsStorage().pairsCount()
        );
    }

    // Helpers (permissioned)
    function addPriceImpactOpenInterest(uint256 _openInterest, uint256 _pairIndex, bool _long) external onlyCallbacks {
        PriceImpactUtils.addPriceImpactOpenInterest(uint128(_openInterest), _pairIndex, _long);
    }

    function removePriceImpactOpenInterest(
        uint256 _openInterest,
        uint256 _pairIndex,
        bool _long,
        uint48 _addTs
    ) external onlyCallbacks {
        PriceImpactUtils.removePriceImpactOpenInterest(uint128(_openInterest), _pairIndex, _long, _addTs);
    }

    // Getters
    function getPriceImpactOi(uint256 _pairIndex, bool _long) public view returns (uint256 activeOi) {
        return PriceImpactUtils.getPriceImpactOi(_pairIndex, _long, storageT);
    }

    function getTradePriceImpact(
        uint256 _openPrice, // PRECISION
        uint256 _pairIndex,
        bool _long,
        uint256 _tradeOpenInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        )
    {
        IGNSPairInfos.PairParams memory pParams = pairInfos.pairParams(_pairIndex);
        uint256 depth = _long ? pParams.onePercentDepthAbove : pParams.onePercentDepthBelow;

        (priceImpactP, priceAfterImpact) = PriceImpactUtils.getTradePriceImpact(
            _openPrice,
            _long,
            depth > 0 ? getPriceImpactOi(_pairIndex, _long) : 0, // saves gas if depth is 0
            _tradeOpenInterest,
            depth
        );
    }

    function getOiWindowsSettings() external view returns (PriceImpactUtils.OiWindowsSettings memory) {
        return oiWindowsStorage.settings;
    }

    function getOiWindow(
        uint48 _windowsDuration,
        uint256 _pairIndex,
        uint256 _windowId
    ) external view returns (PriceImpactUtils.PairOi memory) {
        return
            oiWindowsStorage.windows[
                _windowsDuration > 0 ? _windowsDuration : oiWindowsStorage.settings.windowsDuration
            ][_pairIndex][_windowId];
    }

    function getOiWindows(
        uint48 _windowsDuration,
        uint256 _pairIndex,
        uint256[] calldata _windowIds
    ) external view returns (PriceImpactUtils.PairOi[] memory) {
        PriceImpactUtils.PairOi[] memory _pairOis = new PriceImpactUtils.PairOi[](_windowIds.length);
        _windowsDuration = _windowsDuration > 0 ? _windowsDuration : oiWindowsStorage.settings.windowsDuration;

        for (uint256 i; i < _windowIds.length; ) {
            _pairOis[i] = oiWindowsStorage.windows[_windowsDuration][_pairIndex][_windowIds[i]];

            unchecked {
                ++i;
            }
        }

        return _pairOis;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.3.2
 */
interface IArbSys {
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 5
 */
interface IChainlinkFeed {
    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../libraries/PriceImpactUtils.sol";

/**
 * @custom:version 6.4.2
 */
interface IGNSBorrowingFees {
    // Structs
    struct PairGroup {
        uint16 groupIndex;
        uint48 block;
        uint64 initialAccFeeLong; // 1e10 (%)
        uint64 initialAccFeeShort; // 1e10 (%)
        uint64 prevGroupAccFeeLong; // 1e10 (%)
        uint64 prevGroupAccFeeShort; // 1e10 (%)
        uint64 pairAccFeeLong; // 1e10 (%)
        uint64 pairAccFeeShort; // 1e10 (%)
        uint64 _placeholder; // might be useful later
    }
    struct Pair {
        PairGroup[] groups;
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint48 feeExponent;
        uint256 lastAccBlockWeightedMarketCap; // 1e40
    }
    struct PairOi {
        uint72 long; // 1e10 (DAI)
        uint72 short; // 1e10 (DAI)
        uint72 max; // 1e10 (DAI)
        uint40 _placeholder; // might be useful later
    }
    struct Group {
        uint112 oiLong; // 1e10
        uint112 oiShort; // 1e10
        uint32 feePerBlock; // 1e10 (%)
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint48 accLastUpdatedBlock;
        uint80 maxOi; // 1e10
        uint256 lastAccBlockWeightedMarketCap; // 1e40
    }
    struct InitialAccFees {
        uint64 accPairFee; // 1e10 (%)
        uint64 accGroupFee; // 1e10 (%)
        uint48 block;
        uint80 _placeholder; // might be useful later
    }
    struct PairParams {
        uint16 groupIndex;
        uint32 feePerBlock; // 1e10 (%)
        uint48 feeExponent;
        uint72 maxOi;
    }
    struct GroupParams {
        uint32 feePerBlock; // 1e10 (%)
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }
    struct BorrowingFeeInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        bool long;
        uint256 collateral; // 1e18 (DAI)
        uint256 leverage;
    }
    struct LiqPriceInput {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 openPrice; // 1e10
        bool long;
        uint256 collateral; // 1e18 (DAI)
        uint256 leverage;
    }
    struct PendingAccFeesInput {
        uint64 accFeeLong; // 1e10 (%)
        uint64 accFeeShort; // 1e10 (%)
        uint256 oiLong; // 1e18
        uint256 oiShort; // 1e18
        uint32 feePerBlock; // 1e10
        uint256 currentBlock;
        uint256 accLastUpdatedBlock;
        uint72 maxOi; // 1e10
        uint48 feeExponent;
    }

    // Events
    event PairParamsUpdated(
        uint256 indexed pairIndex,
        uint16 indexed groupIndex,
        uint32 feePerBlock,
        uint48 feeExponent,
        uint72 maxOi
    );
    event PairGroupUpdated(uint256 indexed pairIndex, uint16 indexed prevGroupIndex, uint16 indexed newGroupIndex);
    event GroupUpdated(uint16 indexed groupIndex, uint32 feePerBlock, uint72 maxOi, uint48 feeExponent);
    event TradeInitialAccFeesStored(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        uint64 initialPairAccFee,
        uint64 initialGroupAccFee
    );
    event TradeActionHandled(
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        bool open,
        bool long,
        uint256 positionSizeDai // 1e18
    );
    event PairAccFeesUpdated(uint256 indexed pairIndex, uint256 currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupAccFeesUpdated(uint16 indexed groupIndex, uint256 currentBlock, uint64 accFeeLong, uint64 accFeeShort);
    event GroupOiUpdated(
        uint16 indexed groupIndex,
        bool indexed long,
        bool indexed increase,
        uint112 amount,
        uint112 oiLong,
        uint112 oiShort
    );

    // v6.4.2 - PriceImpactUtils events, have to be duplicated (solved after 0.8.20 but can't update bc of PUSH0 opcode)
    event OiWindowsSettingsInitialized(uint48 indexed windowsDuration);

    event PriceImpactWindowsCountUpdated(uint48 indexed windowsCount);
    event PriceImpactWindowsDurationUpdated(uint48 indexed windowsDuration);

    event PriceImpactOpenInterestAdded(PriceImpactUtils.OiWindowUpdate oiWindowUpdate);
    event PriceImpactOpenInterestRemoved(PriceImpactUtils.OiWindowUpdate oiWindowUpdate, bool notOutdated);

    event PriceImpactOiTransferredPairs(
        uint256 pairsCount,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        uint256 newCurrentWindowId
    );
    event PriceImpactOiTransferredPair(uint256 indexed pairIndex, PriceImpactUtils.PairOi totalPairOi);

    // Functions
    function getTradeLiquidationPrice(LiqPriceInput calldata) external view returns (uint256); // PRECISION

    function getTradeBorrowingFee(BorrowingFeeInput memory) external view returns (uint256); // 1e18 (DAI)

    function handleTradeAction(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 positionSizeDai, // 1e18 (collateral * leverage)
        bool open,
        bool long
    ) external;

    function withinMaxGroupOi(uint256 pairIndex, bool long, uint256 positionSizeDai) external view returns (bool);

    function getPairMaxOi(uint256 pairIndex) external view returns (uint256);

    // v6.4.2 - Functions
    function addPriceImpactOpenInterest(uint256 _openInterest, uint256 _pairIndex, bool _long) external;

    function removePriceImpactOpenInterest(
        uint256 _openInterest,
        uint256 _pairIndex,
        bool _long,
        uint48 _addTs
    ) external;

    function getTradePriceImpact(
        uint256 _openPrice, // PRECISION
        uint256 _pairIndex,
        bool _long,
        uint256 _tradeOpenInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6
 */
interface IGNSPairInfos {
    struct PairParams {
        uint256 onePercentDepthAbove; // DAI
        uint256 onePercentDepthBelow; // DAI
        uint256 rolloverFeePerBlockP; // PRECISION (%)
        uint256 fundingFeePerBlockP; // PRECISION (%)
    }

    struct TradeInitialAccFees {
        uint256 rollover; // 1e18 (DAI)
        int256 funding; // 1e18 (DAI)
        bool openedAfterUpdate;
    }

    function pairParams(uint256) external view returns (PairParams memory);

    function tradeInitialAccFees(address, uint256, uint256) external view returns (TradeInitialAccFees memory);

    function maxNegativePnlOnOpenP() external view returns (uint256); // PRECISION (%)

    function storeTradeInitialAccFees(address trader, uint256 pairIndex, uint256 index, bool long) external;

    /**
     * @custom:deprecated
     * getTradePriceImpact has been moved to Borrowing Fees contract
     */
    function getTradePriceImpact(
        uint256 openPrice, // PRECISION
        uint256 pairIndex,
        bool long,
        uint256 openInterest // 1e18 (DAI)
    )
        external
        view
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        );

    function getTradeRolloverFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 collateral // 1e18 (DAI)
    ) external view returns (uint256);

    function getTradeFundingFee(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    )
        external
        view
        returns (
            int256 // 1e18 (DAI) | Positive => Fee, Negative => Reward
        );

    function getTradeLiquidationPricePure(
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        uint256 rolloverFee, // 1e18 (DAI)
        int256 fundingFee // 1e18 (DAI)
    ) external pure returns (uint256);

    function getTradeLiquidationPrice(
        address trader,
        uint256 pairIndex,
        uint256 index,
        uint256 openPrice, // PRECISION
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage
    ) external view returns (uint256); // PRECISION

    function getTradeValue(
        address trader,
        uint256 pairIndex,
        uint256 index,
        bool long,
        uint256 collateral, // 1e18 (DAI)
        uint256 leverage,
        int256 percentProfit, // PRECISION (%)
        uint256 closingFee // 1e18 (DAI)
    ) external returns (uint256); // 1e18 (DAI)

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6
 */
interface IGNSPairsStorage {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    }
    struct Feed {
        address feed1;
        address feed2;
        FeedCalculation feedCalculation;
        uint256 maxDeviationP;
    } // PRECISION (%)

    struct Pair {
        string from;
        string to;
        Feed feed;
        uint256 spreadP; // PRECISION
        uint256 groupIndex;
        uint256 feeIndex;
    }
    struct Group {
        string name;
        bytes32 job;
        uint256 minLeverage;
        uint256 maxLeverage;
        uint256 maxCollateralP; // % (of DAI vault current balance)
    }
    struct Fee {
        string name;
        uint256 openFeeP; // PRECISION (% of leveraged pos)
        uint256 closeFeeP; // PRECISION (% of leveraged pos)
        uint256 oracleFeeP; // PRECISION (% of leveraged pos)
        uint256 nftLimitOrderFeeP; // PRECISION (% of leveraged pos)
        uint256 referralFeeP; // PRECISION (% of leveraged pos)
        uint256 minLevPosDai; // 1e18 (collateral x leverage, useful for min fee)
    }

    function updateGroupCollateral(uint256, uint256, bool, bool) external;

    function pairJob(uint256) external returns (string memory, string memory, bytes32, uint256);

    function pairFeed(uint256) external view returns (Feed memory);

    function pairSpreadP(uint256) external view returns (uint256);

    function pairMinLeverage(uint256) external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    function groupMaxCollateral(uint256) external view returns (uint256);

    function groupCollateral(uint256, bool) external view returns (uint256);

    function guaranteedSlEnabled(uint256) external view returns (bool);

    function pairOpenFeeP(uint256) external view returns (uint256);

    function pairCloseFeeP(uint256) external view returns (uint256);

    function pairOracleFeeP(uint256) external view returns (uint256);

    function pairNftLimitOrderFeeP(uint256) external view returns (uint256);

    function pairReferralFeeP(uint256) external view returns (uint256);

    function pairMinLevPosDai(uint256) external view returns (uint256);

    function pairsCount() external view returns (uint256);

    event PairAdded(uint256 index, string from, string to);
    event PairUpdated(uint256 index);

    event GroupAdded(uint256 index, string name);
    event GroupUpdated(uint256 index);

    event FeeAdded(uint256 index, string name);
    event FeeUpdated(uint256 index);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IChainlinkFeed.sol";
import "./IGNSTradingCallbacks.sol";
import "./IGNSPairsStorage.sol";

/**
 * @custom:version 6.4
 */
interface IGNSPriceAggregator {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE
    }

    struct Order {
        uint16 pairIndex;
        uint112 linkFeePerNode;
        OrderType orderType;
        bool active;
        bool isLookback;
    }

    struct LookbackOrderAnswer {
        uint64 open;
        uint64 high;
        uint64 low;
        uint64 ts;
    }

    function pairsStorage() external view returns (IGNSPairsStorage);

    function getPrice(uint256, OrderType, uint256, uint256) external returns (uint256);

    function tokenPriceDai() external returns (uint256);

    function linkFee(uint256, uint256) external view returns (uint256);

    function openFeeP(uint256) external view returns (uint256);

    function linkPriceFeed() external view returns (IChainlinkFeed);

    function nodes(uint256 index) external view returns (address);

    event PairsStorageUpdated(address value);
    event LinkPriceFeedUpdated(address value);
    event MinAnswersUpdated(uint256 value);

    event NodeAdded(uint256 index, address value);
    event NodeReplaced(uint256 index, address oldNode, address newNode);
    event NodeRemoved(uint256 index, address oldNode);

    event JobIdUpdated(uint256 index, bytes32 jobId);

    event PriceRequested(
        uint256 indexed orderId,
        bytes32 indexed job,
        uint256 indexed pairIndex,
        OrderType orderType,
        uint256 nodesCount,
        uint256 linkFeePerNode,
        uint256 fromBlock,
        bool isLookback
    );

    event PriceReceived(
        bytes32 request,
        uint256 indexed orderId,
        address indexed node,
        uint16 indexed pairIndex,
        uint256 price,
        uint256 referencePrice,
        uint112 linkFee,
        bool isLookback,
        bool usedInMedian
    );

    event CallbackExecuted(IGNSTradingCallbacks.AggregatorAnswer a, OrderType orderType);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSTradingStorage.sol";

/**
 * @custom:version 6.4.2
 */
interface IGNSTradingCallbacks {
    struct AggregatorAnswer {
        uint256 orderId;
        uint256 price;
        uint256 spreadP;
        uint256 open;
        uint256 high;
        uint256 low;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint256 posDai;
        uint256 levPosDai;
        uint256 tokenPriceDai;
        int256 profitP;
        uint256 price;
        uint256 liqPrice;
        uint256 daiSentToTrader;
        uint256 reward1;
        uint256 reward2;
        uint256 reward3;
        bool exactExecution;
    }

    struct SimplifiedTradeId {
        address trader;
        uint256 pairIndex;
        uint256 index;
        TradeType tradeType;
    }

    struct LastUpdated {
        uint32 tp;
        uint32 sl;
        uint32 limit;
        uint32 created;
    }

    struct TradeData {
        uint40 maxSlippageP; // 1e10 (%)
        uint48 lastOiUpdateTs;
        uint168 _placeholder; // for potential future data
    }

    struct OpenTradePrepInput {
        uint256 executionPrice;
        uint256 wantedPrice;
        uint256 marketPrice;
        uint256 spreadP;
        bool buy;
        uint256 pairIndex;
        uint256 positionSize;
        uint256 leverage;
        uint256 maxSlippageP;
        uint256 tp;
        uint256 sl;
    }

    enum TradeType {
        MARKET,
        LIMIT
    }

    enum CancelReason {
        NONE,
        PAUSED,
        MARKET_CLOSED,
        SLIPPAGE,
        TP_REACHED,
        SL_REACHED,
        EXPOSURE_LIMITS,
        PRICE_IMPACT,
        MAX_LEVERAGE,
        NO_TRADE,
        WRONG_TRADE,
        NOT_HIT
    }

    function openTradeMarketCallback(AggregatorAnswer memory) external;

    function closeTradeMarketCallback(AggregatorAnswer memory) external;

    function executeNftOpenOrderCallback(AggregatorAnswer memory) external;

    function executeNftCloseOrderCallback(AggregatorAnswer memory) external;

    function getTradeLastUpdated(address, uint256, uint256, TradeType) external view returns (LastUpdated memory);

    function setTradeLastUpdated(SimplifiedTradeId calldata, LastUpdated memory) external;

    function setTradeData(SimplifiedTradeId calldata, TradeData memory) external;

    function canExecuteTimeout() external view returns (uint256);

    function pairMaxLeverage(uint256) external view returns (uint256);

    event MarketExecuted(
        uint256 indexed orderId,
        IGNSTradingStorage.Trade t,
        bool open,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit, // before fees
        uint256 daiSentToTrader
    );

    event LimitExecuted(
        uint256 indexed orderId,
        uint256 limitIndex,
        IGNSTradingStorage.Trade t,
        address indexed nftHolder,
        IGNSTradingStorage.LimitOrder orderType,
        uint256 price,
        uint256 priceImpactP,
        uint256 positionSizeDai,
        int256 percentProfit,
        uint256 daiSentToTrader,
        bool exactExecution
    );

    event MarketOpenCanceled(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        CancelReason cancelReason
    );
    event MarketCloseCanceled(
        uint256 indexed orderId,
        address indexed trader,
        uint256 indexed pairIndex,
        uint256 index,
        CancelReason cancelReason
    );
    event NftOrderCanceled(
        uint256 indexed orderId,
        address indexed nftHolder,
        IGNSTradingStorage.LimitOrder orderType,
        CancelReason cancelReason
    );

    event ClosingFeeSharesPUpdated(uint256 daiVaultFeeP, uint256 lpFeeP, uint256 sssFeeP);

    event Pause(bool paused);
    event Done(bool done);
    event GovFeesClaimed(uint256 valueDai);

    event GovFeeCharged(address indexed trader, uint256 valueDai, bool distributed);
    event ReferralFeeCharged(address indexed trader, uint256 valueDai);
    event TriggerFeeCharged(address indexed trader, uint256 valueDai);
    event SssFeeCharged(address indexed trader, uint256 valueDai);
    event DaiVaultFeeCharged(address indexed trader, uint256 valueDai);
    event BorrowingFeeCharged(address indexed trader, uint256 tradeValueDai, uint256 feeValueDai);
    event PairMaxLeverageUpdated(uint256 indexed pairIndex, uint256 maxLeverage);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IGNSPriceAggregator.sol"; // avoid chained conversions for pairsStorage

/**
 * @custom:version 5
 */
interface IGNSTradingStorage {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }
    struct Trade {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 initialPosToken; // 1e18
        uint256 positionSizeDai; // 1e18
        uint256 openPrice; // PRECISION
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION
        uint256 sl; // PRECISION
    }
    struct TradeInfo {
        uint256 tokenId;
        uint256 tokenPriceDai; // PRECISION
        uint256 openInterestDai; // 1e18
        uint256 tpLastUpdated;
        uint256 slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint256 pairIndex;
        uint256 index;
        uint256 positionSize; // 1e18 (DAI or GFARM2)
        uint256 spreadReductionP;
        bool buy;
        uint256 leverage;
        uint256 tp; // PRECISION (%)
        uint256 sl; // PRECISION (%)
        uint256 minPrice; // PRECISION
        uint256 maxPrice; // PRECISION
        uint256 block;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint256 block;
        uint256 wantedPrice; // PRECISION
        uint256 slippageP; // PRECISION (%)
        uint256 spreadReductionP;
        uint256 tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint256 nftId;
        address trader;
        uint256 pairIndex;
        uint256 index;
        LimitOrder orderType;
    }

    function PRECISION() external pure returns (uint256);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function dai() external view returns (address);

    function token() external view returns (address);

    function linkErc677() external view returns (address);

    function priceAggregator() external view returns (IGNSPriceAggregator);

    function vault() external view returns (address);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint256, bool) external;

    function transferDai(address, address, uint256) external;

    function transferLinkToAggregator(address, uint256, uint256) external;

    function unregisterTrade(address, uint256, uint256) external;

    function unregisterPendingMarketOrder(uint256, bool) external;

    function unregisterOpenLimitOrder(address, uint256, uint256) external;

    function hasOpenLimitOrder(address, uint256, uint256) external view returns (bool);

    function storePendingMarketOrder(PendingMarketOrder memory, uint256, bool) external;

    function openTrades(address, uint256, uint256) external view returns (Trade memory);

    function openTradesInfo(address, uint256, uint256) external view returns (TradeInfo memory);

    function updateSl(address, uint256, uint256, uint256) external;

    function updateTp(address, uint256, uint256, uint256) external;

    function getOpenLimitOrder(address, uint256, uint256) external view returns (OpenLimitOrder memory);

    function getOpenLimitOrders() external view returns (OpenLimitOrder[] memory);

    function spreadReductionsP(uint256) external view returns (uint256);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(uint256) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint256) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function firstEmptyTradeIndex(address, uint256) external view returns (uint256);

    function firstEmptyOpenLimitIndex(address, uint256) external view returns (uint256);

    function increaseNftRewards(uint256, uint256) external;

    function nftSuccessTimelock() external view returns (uint256);

    function reqID_pendingNftOrder(uint256) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint256) external view returns (uint256);

    function unregisterPendingNftOrder(uint256) external;

    function handleDevGovFees(uint256, uint256, bool, bool) external returns (uint256);

    function distributeLpRewards(uint256) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint256) external view returns (uint256);

    function openTradesCount(address, uint256) external view returns (uint256);

    function pendingMarketOpenCount(address, uint256) external view returns (uint256);

    function pendingMarketCloseCount(address, uint256) external view returns (uint256);

    function maxTradesPerPair() external view returns (uint256);

    function pendingOrderIdsCount(address) external view returns (uint256);

    function maxPendingMarketOrders() external view returns (uint256);

    function openInterestDai(uint256, uint256) external view returns (uint256);

    function getPendingOrderIds(address) external view returns (uint256[] memory);

    function nfts(uint256) external view returns (address);

    function fakeBlockNumber() external view returns (uint256); // Testing
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IArbSys.sol";

/**
 * @custom:version 6.3.2
 */
library ChainUtils {
    uint256 public constant ARBITRUM_MAINNET = 42161;
    uint256 public constant ARBITRUM_GOERLI = 421613;
    IArbSys public constant ARB_SYS = IArbSys(address(100));

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_MAINNET || block.chainid == ARBITRUM_GOERLI) {
            return ARB_SYS.arbBlockNumber();
        }

        return block.number;
    }

    function getUint48BlockNumber(uint256 blockNumber) internal pure returns (uint48) {
        require(blockNumber <= type(uint48).max, "OVERFLOW");
        return uint48(blockNumber);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/IGNSTradingStorage.sol";

import "./StorageUtils.sol";

/**
 * @custom:version 6.4.2
 *
 * @dev This is a library to help manage a price impact decay algorithm .
 *
 * When a trade is placed, OI is added to the window corresponding to time of open.
 * When a trade is removed, OI is removed from the window corresponding to time of open.
 *
 * When calculating price impact, only the most recent X windows are taken into account.
 */
library PriceImpactUtils {
    uint256 private constant PRECISION = 1e10; // 10 decimals

    uint48 private constant MAX_WINDOWS_COUNT = 5;
    uint48 private constant MAX_WINDOWS_DURATION = 1 days;
    uint48 private constant MIN_WINDOWS_DURATION = 10 minutes;

    struct OiWindowsStorage {
        OiWindowsSettings settings;
        mapping(uint48 => mapping(uint256 => mapping(uint256 => PairOi))) windows; // duration => pairIndex => windowId => Oi
    }

    struct OiWindowsSettings {
        uint48 startTs;
        uint48 windowsDuration;
        uint48 windowsCount;
    }

    struct PairOi {
        uint128 long; // 1e18 (DAI)
        uint128 short; // 1e18 (DAI)
    }

    struct OiWindowUpdate {
        uint48 windowsDuration;
        uint256 pairIndex;
        uint256 windowId;
        bool long;
        uint128 openInterest; // 1e18 (DAI)
    }

    /**
     * @dev Triggered when OiWindowsSettings is initialized (once)
     */
    event OiWindowsSettingsInitialized(uint48 indexed windowsDuration);

    /**
     * @dev Triggered when OiWindowsSettings.windowsCount is updated
     */
    event PriceImpactWindowsCountUpdated(uint48 indexed windowsCount);

    /**
     * @dev Triggered when OiWindowsSettings.windowsDuration is updated
     */
    event PriceImpactWindowsDurationUpdated(uint48 indexed windowsDuration);

    /**
     * @dev Triggered when OI is added to a window.
     */
    event PriceImpactOpenInterestAdded(OiWindowUpdate oiWindowUpdate);

    /**
     * @dev Triggered when OI is (tentatively) removed from a window.
     */
    event PriceImpactOpenInterestRemoved(OiWindowUpdate oiWindowUpdate, bool notOutdated);

    /**
     * @dev Triggered when multiple pairs' OI are transferred to a new window.
     */
    event PriceImpactOiTransferredPairs(
        uint256 pairsCount,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        uint256 newCurrentWindowId
    );

    /**
     * @dev Triggered when a pair's OI is transferred to a new window.
     */
    event PriceImpactOiTransferredPair(uint256 indexed pairIndex, PairOi totalPairOi);

    /**
     * @dev Returns storage pointer for struct in borrowing contract, at defined slot
     */
    function getStorage() private pure returns (OiWindowsStorage storage s) {
        uint256 storageSlot = StorageUtils.PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT;
        assembly {
            s.slot := storageSlot
        }
    }

    /**
     * @dev Validates new windowsDuration value
     */
    modifier validWindowsDuration(uint48 _windowsDuration) {
        require(
            _windowsDuration >= MIN_WINDOWS_DURATION && _windowsDuration <= MAX_WINDOWS_DURATION,
            "WRONG_WINDOWS_DURATION"
        );
        _;
    }

    /**
     * @dev Initializes OiWindowsSettings startTs and windowsDuration.
     * windowsCount is 0 for now for backwards-compatible behavior until oi windows have enough data.
     *
     * Should only be called once, in initializeV2() of borrowing contract.
     * Emits a {OiWindowsSettingsInitialized} event.
     */
    function initializeOiWindowsSettings(uint48 _windowsDuration) external validWindowsDuration(_windowsDuration) {
        getStorage().settings = OiWindowsSettings({
            startTs: uint48(block.timestamp),
            windowsDuration: _windowsDuration,
            windowsCount: 0 // maintains previous price impact OI behavior for now
        });

        emit OiWindowsSettingsInitialized(_windowsDuration);
    }

    /**
     * @dev Updates OiWindowSettings.windowsCount storage value
     *
     * Emits a {PriceImpactWindowsCountUpdated} event.
     */
    function setPriceImpactWindowsCount(uint48 _newWindowsCount) external {
        OiWindowsSettings storage settings = getStorage().settings;

        require(_newWindowsCount <= MAX_WINDOWS_COUNT, "ABOVE_MAX_WINDOWS_COUNT");
        require(_newWindowsCount == 0 || getCurrentWindowId(settings) >= _newWindowsCount - 1, "TOO_EARLY");

        settings.windowsCount = _newWindowsCount;

        emit PriceImpactWindowsCountUpdated(_newWindowsCount);
    }

    /**
     * @dev Updates OiWindowSettings.windowsDuration storage value,
     * and transfers the OI from all pairs past active windows (current window duration)
     * to the new current window (new window duration).
     *
     * Emits a {PriceImpactWindowsDurationUpdated} event.
     */
    function setPriceImpactWindowsDuration(
        uint48 _newWindowsDuration,
        uint256 _pairsCount
    ) external validWindowsDuration(_newWindowsDuration) {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        if (settings.windowsCount > 0) {
            transferPriceImpactOiForPairs(
                _pairsCount,
                oiStorage.windows[settings.windowsDuration],
                oiStorage.windows[_newWindowsDuration],
                settings,
                _newWindowsDuration
            );
        }

        settings.windowsDuration = _newWindowsDuration;

        emit PriceImpactWindowsDurationUpdated(_newWindowsDuration);
    }

    /**
     * @dev Adds long / short `_openInterest` (1e18) to current window of `_pairIndex`.
     *
     * Emits a {PriceImpactOpenInterestAdded} event.
     */
    function addPriceImpactOpenInterest(uint128 _openInterest, uint256 _pairIndex, bool _long) external {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        uint256 currentWindowId = getCurrentWindowId(settings);
        PairOi storage pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][currentWindowId];

        if (_long) {
            pairOi.long += _openInterest;
        } else {
            pairOi.short += _openInterest;
        }

        emit PriceImpactOpenInterestAdded(
            OiWindowUpdate(settings.windowsDuration, _pairIndex, currentWindowId, _long, _openInterest)
        );
    }

    /**
     * @dev Removes `_openInterest` (1e18) from window at `_addTs` of `_pairIndex`.
     *
     * Emits a {PriceImpactOpenInterestRemoved} event when `_addTs` is greater than zero.
     */
    function removePriceImpactOpenInterest(
        uint128 _openInterest,
        uint256 _pairIndex,
        bool _long,
        uint48 _addTs
    ) external {
        // If trade opened before update, OI wasn't stored in any window anyway
        if (_addTs == 0) {
            return;
        }

        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        uint256 currentWindowId = getCurrentWindowId(settings);
        uint256 addWindowId = getWindowId(_addTs, settings);

        bool notOutdated = isWindowPotentiallyActive(addWindowId, currentWindowId);

        // Only remove OI if window is not outdated already
        if (notOutdated) {
            PairOi storage pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][addWindowId];

            if (_long) {
                pairOi.long = _openInterest < pairOi.long ? pairOi.long - _openInterest : 0;
            } else {
                pairOi.short = _openInterest < pairOi.short ? pairOi.short - _openInterest : 0;
            }
        }

        emit PriceImpactOpenInterestRemoved(
            OiWindowUpdate(settings.windowsDuration, _pairIndex, addWindowId, _long, _openInterest),
            notOutdated
        );
    }

    /**
     * @dev Transfers total long / short OI from last '_settings.windowsCount' windows of `_prevPairOiWindows`
     * to current window of `_newPairOiWindows` for `pairsCount` pairs.
     *
     * Emits a {PriceImpactOiTransferredPairs} event.
     */
    function transferPriceImpactOiForPairs(
        uint256 pairsCount,
        mapping(uint256 => mapping(uint256 => PairOi)) storage _prevPairOiWindows, // pairIndex => windowId => PairOi
        mapping(uint256 => mapping(uint256 => PairOi)) storage _newPairOiWindows, // pairIndex => windowId => PairOi
        OiWindowsSettings memory _settings,
        uint48 _newWindowsDuration
    ) private {
        uint256 prevCurrentWindowId = getCurrentWindowId(_settings);
        uint256 prevEarliestWindowId = getEarliestActiveWindowId(prevCurrentWindowId, _settings.windowsCount);

        uint256 newCurrentWindowId = getCurrentWindowId(
            OiWindowsSettings(_settings.startTs, _newWindowsDuration, _settings.windowsCount)
        );

        for (uint256 pairIndex; pairIndex < pairsCount; ) {
            transferPriceImpactOiForPair(
                pairIndex,
                prevCurrentWindowId,
                prevEarliestWindowId,
                _prevPairOiWindows[pairIndex],
                _newPairOiWindows[pairIndex][newCurrentWindowId]
            );

            unchecked {
                ++pairIndex;
            }
        }

        emit PriceImpactOiTransferredPairs(pairsCount, prevCurrentWindowId, prevEarliestWindowId, newCurrentWindowId);
    }

    /**
     * @dev Transfers total long / short OI from `prevEarliestWindowId` to `prevCurrentWindowId` windows of
     * `_prevPairOiWindows` to `_newPairOiWindow` window.
     *
     * Emits a {PriceImpactOiTransferredPair} event.
     */
    function transferPriceImpactOiForPair(
        uint256 pairIndex,
        uint256 prevCurrentWindowId,
        uint256 prevEarliestWindowId,
        mapping(uint256 => PairOi) storage _prevPairOiWindows,
        PairOi storage _newPairOiWindow
    ) private {
        PairOi memory totalPairOi;

        // Aggregate sum of total long / short OI for past windows
        for (uint256 id = prevEarliestWindowId; id <= prevCurrentWindowId; ) {
            PairOi memory pairOi = _prevPairOiWindows[id];

            totalPairOi.long += pairOi.long;
            totalPairOi.short += pairOi.short;

            // Clean up previous map once added to the sum
            delete _prevPairOiWindows[id];

            unchecked {
                ++id;
            }
        }

        bool longOiTransfer = totalPairOi.long > 0;
        bool shortOiTransfer = totalPairOi.short > 0;

        if (longOiTransfer) {
            _newPairOiWindow.long += totalPairOi.long;
        }

        if (shortOiTransfer) {
            _newPairOiWindow.short += totalPairOi.short;
        }

        // Only emit even if there was an actual OI transfer
        if (longOiTransfer || shortOiTransfer) {
            emit PriceImpactOiTransferredPair(pairIndex, totalPairOi);
        }
    }

    /**
     * @dev Returns window id at `_timestamp` given `_settings`.
     */
    function getWindowId(uint48 _timestamp, OiWindowsSettings memory _settings) internal pure returns (uint256) {
        return (_timestamp - _settings.startTs) / _settings.windowsDuration;
    }

    /**
     * @dev Returns window id at current timestamp given `_settings`.
     */
    function getCurrentWindowId(OiWindowsSettings memory _settings) internal view returns (uint256) {
        return getWindowId(uint48(block.timestamp), _settings);
    }

    /**
     * @dev Returns earliest active window id given `_currentWindowId` and `_windowsCount`.
     */
    function getEarliestActiveWindowId(uint256 _currentWindowId, uint48 _windowsCount) internal pure returns (uint256) {
        uint256 windowNegativeDelta = _windowsCount - 1; // -1 because we include current window
        return _currentWindowId > windowNegativeDelta ? _currentWindowId - windowNegativeDelta : 0;
    }

    /**
     * @dev Returns whether '_windowId' can be potentially active id given `_currentWindowId`
     */
    function isWindowPotentiallyActive(uint256 _windowId, uint256 _currentWindowId) internal pure returns (bool) {
        return _currentWindowId - _windowId < MAX_WINDOWS_COUNT;
    }

    /**
     * @dev Returns total long / short OI `activeOi`, from last active windows of `_pairOiWindows`
     * given `_settings` (backwards-compatible).
     */
    function getPriceImpactOi(
        uint256 _pairIndex,
        bool _long,
        IGNSTradingStorage _previousOiContract
    ) external view returns (uint256 activeOi) {
        OiWindowsStorage storage oiStorage = getStorage();
        OiWindowsSettings storage settings = oiStorage.settings;

        // Return raw OI if windowsCount is explicitly 0 (= previous behavior)
        if (settings.windowsCount == 0) {
            return _previousOiContract.openInterestDai(_pairIndex, _long ? 0 : 1);
        }

        uint256 currentWindowId = getCurrentWindowId(settings);
        uint256 earliestWindowId = getEarliestActiveWindowId(currentWindowId, settings.windowsCount);

        for (uint256 i = earliestWindowId; i <= currentWindowId; ) {
            PairOi memory _pairOi = oiStorage.windows[settings.windowsDuration][_pairIndex][i];
            activeOi += _long ? _pairOi.long : _pairOi.short;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Returns trade price impact % and opening price after impact.
     */
    function getTradePriceImpact(
        uint256 _openPrice, // PRECISION
        bool _long,
        uint256 _startOpenInterest, // 1e18 (DAI)
        uint256 _tradeOpenInterest, // 1e18 (DAI)
        uint256 _onePercentDepth
    )
        external
        pure
        returns (
            uint256 priceImpactP, // PRECISION (%)
            uint256 priceAfterImpact // PRECISION
        )
    {
        if (_onePercentDepth == 0) {
            return (0, _openPrice);
        }

        priceImpactP = ((_startOpenInterest + _tradeOpenInterest / 2) * PRECISION) / _onePercentDepth / 1e18;

        uint256 priceImpact = (priceImpactP * _openPrice) / PRECISION / 100;
        priceAfterImpact = _long ? _openPrice + priceImpact : _openPrice - priceImpact;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @custom:version 6.4.2
 *
 * @dev This is a library to help manage storage slots used by our external libraries.
 *
 * BE EXTREMELY CAREFUL, DO NOT EDIT THIS WITHOUT A GOOD REASON
 *
 */
library StorageUtils {
    uint256 internal constant PRICE_IMPACT_OI_WINDOWS_STORAGE_SLOT = 7;
}