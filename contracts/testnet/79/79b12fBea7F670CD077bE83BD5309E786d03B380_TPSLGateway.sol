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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

/*
 * Copyright 2021 ConsenSys Software Inc
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
pragma solidity >=0.8;

/**
 * Crosschain Function Call Interface allows applications to call functions on other blockchains
 * and to get information about the currently executing function call.
 *
 */
interface CrosschainFunctionCallInterface {
    /**
     * Call a function on another blockchain. All function call implementations must implement
     * this function.
     *
     * @param _bcId Blockchain identifier of blockchain to be called.
     * @param _contract The address of the contract to be called.
     * @param _functionCallData The function selector and parameter data encoded using ABI encoding rules.
     */
    function crossBlockchainCall(
        uint256 _bcId,
        address _contract,
        uint8 _destMethodID,
        bytes calldata _functionCallData
    ) external;
}

pragma solidity ^0.8.0;

interface IFuturXGateway {
    function executionFee() external returns (uint256);

    function maxGlobalShortSizes(address token) external view returns (uint256);

    function maxGlobalLongSizes(address token) external view returns (uint256);

    function gatewayStorage() external view returns (address);

    function isPaused() external view returns (bool);

    function coreManagers(address token) external view returns (address);

    function pcsId() external view returns (uint256);

    function pscCrossChainGateway() external view returns (address);

    function futuresAdapter() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./IVault.sol";

interface IFuturXGatewayStorage {
    enum OpCode {
        IncreasePosition,
        DecreasePosition,
        UpdateCollateral
    }
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        bool hasCollateralInETH;
        uint256 amountInToken;
        uint256 feeUsd;
        uint256 positionFeeUsd;
        uint256 voucherId;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        bool withdrawETH;
        uint256 sizeDeltaToken;
    }

    struct UpdateCollateralRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountInToken;
        bool isLong;
        uint256 feeToken;
    }

    struct PendingCollateral {
        uint16 count;
        address collateral;
    }

    struct UpPendingCollateralParam {
        address account;
        address indexToken;
        address collateralToken;
        uint8 op;
    }

    function getRequestKey(
        address _account,
        uint256 _index,
        OpCode _op
    ) external view returns (bytes32);

    function getTPSLRequestKey(
        address _account,
        address _indexToken,
        bool _isHigherPip
    ) external pure returns (bytes32);

    function getIncreasePositionRequest(
        bytes32 _key
    ) external view returns (IncreasePositionRequest memory);

    function getDeleteIncreasePositionRequest(
        bytes32 _key
    ) external returns (IncreasePositionRequest memory);

    function getUpdateOrDeleteIncreasePositionRequest(
        bytes32 _key,
        uint256 amountInToken,
        bool isExecutedFully,
        IVault vault,
        uint16 leverage
    ) external returns (IncreasePositionRequest memory);

    function getDecreasePositionRequest(
        bytes32 _key
    ) external view returns (DecreasePositionRequest memory);

    function getDeleteDecreasePositionRequest(
        bytes32 _key
    ) external returns (DecreasePositionRequest memory);

    function getUpdateOrDeleteDecreasePositionRequest(
        bytes32 _key,
        uint256 quantity,
        bool isExecutedFully
    ) external returns (DecreasePositionRequest memory);

    function getDeleteUpdateCollateralRequest(
        bytes32 _key
    ) external returns (UpdateCollateralRequest memory);

    function getPendingCollateral(
        address _account,
        address _indexToken
    ) external returns (PendingCollateral memory);

    function storeIncreasePositionRequest(
        IncreasePositionRequest memory _request
    ) external returns (uint256, bytes32);

    function storeDecreasePositionRequest(
        DecreasePositionRequest memory _request
    ) external returns (uint256, bytes32);

    function storeUpdateCollateralRequest(
        UpdateCollateralRequest memory _request
    ) external returns (uint256, bytes32);

    function storeTpslRequest(
        address _account,
        address _indexToken,
        bool _isHigherPip,
        bytes32 _decreasePositionRequestKey
    ) external;

    function deleteDecreasePositionRequest(bytes32 _key) external;

    function deleteTpslRequest(
        address _account,
        address _indexToken,
        bool _isHigherPip
    ) external;

    function updatePendingCollateral(
        UpPendingCollateralParam memory param
    ) external returns (bytes32);
}

pragma solidity ^0.8.9;

import "./IVaultUtils.sol";
import "../protocol/libraries/TokenConfiguration.sol";
import "../protocol/libraries/PositionInfo.sol";

interface IVault {
    /* Variables Getter */
    function priceFeed() external view returns (address);

    function vaultUtils() external view returns (address);

    function usdp() external view returns (address);

    function hasDynamicFees() external view returns (bool);

    function poolAmounts(address token) external view returns (uint256);

    function minProfitTime() external returns (uint256);

    function inManagerMode() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    /* Write Functions */
    function buyUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function sellUSDP(
        address _token,
        address _receiver
    ) external returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function swapWithoutFees(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function claimFund(
        address _collateralToken,
        address _account,
        bool _isLong,
        uint256 _amountOutUsd,
        address _receiver
    ) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        uint256 _feeUsd
    ) external;

    function decreasePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _entryPrice,
        uint256 _sizeDeltaToken,
        bool _isLong,
        address _receiver,
        uint256 _amountOutUsd,
        uint256 _feeUsd
    ) external returns (uint256);

    function liquidatePosition(
        address _trader,
        address _collateralToken,
        address _indexToken,
        uint256 _positionSize,
        uint256 _positionMargin,
        bool _isLong
    ) external;

    function addCollateral(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _isLong,
        uint256 _feeToken
    ) external;

    function removeCollateral(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _amountInToken
    ) external;

    /* Goivernance function */
    function setWhitelistCaller(address caller, bool val) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setConfigToken(
        address _token,
        uint8 _tokenDecimals,
        uint64 _minProfitBps,
        uint128 _tokenWeight,
        uint128 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setPriceFeed(address _priceFeed) external;

    function setVaultUtils(IVaultUtils _vaultUtils) external;

    function setBorrowingRate(
        uint256 _borrowingRateInterval,
        uint256 _borrowingRateFactor,
        uint256 _stableBorrowingRateFactor
    ) external;

    function withdrawFees(
        address _token,
        address _receiver
    ) external returns (uint256);

    /* End Goivernance function */

    /* View Functions */
    function getBidPrice(address _token) external view returns (uint256);

    function getAskPrice(address _token) external view returns (uint256);

    function getRedemptionAmount(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function isStableToken(address _token) external view returns (bool);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256 i) external view returns (address);

    function isWhitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function borrowingRateInterval() external view returns (uint256);

    function borrowingRateFactor() external view returns (uint256);

    function stableBorrowingRateFactor() external view returns (uint256);

    function lastBorrowingRateTimes(
        address _token
    ) external view returns (uint256);

    function globalShortAveragePrices(
        address _token
    ) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function cumulativeBorrowingRates(
        address _token
    ) external view returns (uint256);

    function getNextBorrowingRate(
        address _token
    ) external view returns (uint256);

    function getBorrowingFee(
        address _trader,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getSwapFee(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    // pool info
    function usdpAmount(address _token) external view returns (uint256);

    function getTargetUsdpAmount(
        address _token
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdpDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getTokenConfiguration(
        address _token
    ) external view returns (TokenConfiguration.Data memory);

    function getPositionInfo(
        address _account,
        address _indexToken,
        bool _isLong
    ) external view returns (PositionInfo.Data memory);

    function getAvailableReservedAmount(
        address _collateralToken
    ) external view returns (uint256);

    function adjustDecimalToUsd(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function adjustDecimalToToken(
        address _token,
        uint256 _amount
    ) external view returns (uint256);

    function usdToTokenMin(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);

    function tokenToUsdMin(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function tokenToUsdMinWithAdjustment(
        address _token,
        uint256 _tokenAmount
    ) external view returns (uint256);

    function usdToTokenMinWithAdjustment(
        address _token,
        uint256 _usdAmount
    ) external view returns (uint256);
}

pragma solidity ^0.8.9;

interface IVaultUtils {
    function getBuyUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSellUsdgFeeBasisPoints(
        address _token,
        uint256 _usdpAmount
    ) external view returns (uint256);

    function getSwapFeeBasisPoints(
        address _tokenIn,
        address _tokenOut,
        uint256 _usdgAmount
    ) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function getBorrowingFee(
        address _collateralToken,
        uint256 _size,
        uint256 _entryBorrowingRate
    ) external view returns (uint256);

    function updateCumulativeBorrowingRate(
        address _collateralToken,
        address _indexToken
    ) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

contract CrosscallMethod {
    enum Method {
        OPEN_MARKET,
        OPEN_LIMIT,
        CANCEL_LIMIT,
        ADD_MARGIN,
        REMOVE_MARGIN,
        CLOSE_POSITION,
        INSTANTLY_CLOSE_POSITION,
        CLOSE_LIMIT_POSITION,
        CLAIM_FUND,
        SET_TPSL,
        UNSET_TP_AND_SL,
        UNSET_TP_OR_SL,
        OPEN_MARKET_BY_QUOTE,
        EXECUTE_STORE_POSITION
    }
}

pragma solidity ^0.8.9;

library PositionInfo {
    struct Data {
        uint256 reservedAmount;
        uint128 entryBorrowingRates;
        address collateralToken;
    }

    function setEntryBorrowingRates(
        Data storage _self,
        uint256 _rate
    ) internal {
        _self.entryBorrowingRates = uint128(_rate);
    }

    function addReservedAmount(Data storage _self, uint256 _amount) internal {
        _self.reservedAmount = _self.reservedAmount + _amount;
    }

    function subReservedAmount(
        Data storage _self,
        uint256 _amount
    ) internal returns (uint256) {
        // Position already decreased on process chain -> no point in reverting
        // require(
        //    _amount <= _self.reservedAmount,
        //    "Vault: reservedAmount exceeded"
        // );
        if (_amount >= _self.reservedAmount) {
            _amount = _self.reservedAmount;
        }
        _self.reservedAmount = _self.reservedAmount - _amount;
        return _amount;
    }

    function setCollateralToken(Data storage _self, address _token) internal {
        if (_self.collateralToken == address(0)) {
            _self.collateralToken = _token;
            return;
        }
        require(_self.collateralToken == _token);
    }
}

pragma solidity ^0.8.9;

library TokenConfiguration {
    struct Data {
        // packable storage
        bool isWhitelisted;
        uint8 tokenDecimals;
        bool isStableToken;
        bool isShortableToken;
        uint64 minProfitBasisPoints;
        uint128 tokenWeight;
        // maxUsdpAmounts allows setting a max amount of USDP debt for a token
        uint128 maxUsdpAmount;
    }

    function getIsWhitelisted(Data storage _self) internal view returns (bool) {
        return _self.isWhitelisted;
    }

    function getTokenDecimals(
        Data storage _self
    ) internal view returns (uint8) {
        return _self.tokenDecimals;
    }

    function getTokenWeight(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.tokenWeight);
    }

    function getIsStableToken(Data storage _self) internal view returns (bool) {
        return _self.isStableToken;
    }

    function getIsShortableToken(
        Data storage _self
    ) internal view returns (bool) {
        return _self.isShortableToken;
    }

    function getMinProfitBasisPoints(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.minProfitBasisPoints);
    }

    function getMaxUsdpAmount(
        Data storage _self
    ) internal view returns (uint256) {
        return uint256(_self.maxUsdpAmount);
    }
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../interfaces/IFuturXGateway.sol";
import "../interfaces/IFuturXGatewayStorage.sol";
import "../interfaces/CrosschainFunctionCallInterface.sol";

import "./common/CrosscallMethod.sol";

contract TPSLGateway is ReentrancyGuardUpgradeable, CrosscallMethod {
    IFuturXGateway public futurXGateway;

    enum SetTPSLOption {
        BOTH,
        HIGHER,
        LOWER
    }

    modifier whenNotPaused() {
        require(!futurXGateway.isPaused(), "Gateway is paused");
        _;
    }

    function initialize(address _futurXGateway) external initializer {
        __ReentrancyGuard_init();
        futurXGateway = IFuturXGateway(_futurXGateway);
    }

    function setTPSL(
        address[] memory _path,
        address _indexToken,
        bool _withdrawETH,
        uint128 _higherPip,
        uint128 _lowerPip,
        SetTPSLOption _option
    ) external nonReentrant whenNotPaused {
        (, bytes32 requestKey) = _storeDecreasePositionRequest(
            msg.sender,
            _path,
            _indexToken,
            _withdrawETH
        );

        if (_option == SetTPSLOption.HIGHER || _option == SetTPSLOption.BOTH) {
            _storeTpslRequest(msg.sender, _indexToken, true, requestKey);
        }

        if (_option == SetTPSLOption.LOWER || _option == SetTPSLOption.BOTH) {
            _storeTpslRequest(msg.sender, _indexToken, false, requestKey);
        }

        _crossBlockchainCall(
            uint8(Method.SET_TPSL),
            abi.encode(
                _indexTokenToManager(_indexToken),
                msg.sender,
                _higherPip,
                _lowerPip,
                uint8(_option)
            )
        );
    }

    function unsetTPAndSL(
        address _indexToken
    ) external nonReentrant whenNotPaused {
        _deleteTPSLRequestMap(msg.sender, _indexToken, true);
        _deleteTPSLRequestMap(msg.sender, _indexToken, false);

        _crossBlockchainCall(
            uint8(Method.UNSET_TP_AND_SL),
            abi.encode(_indexTokenToManager(_indexToken), msg.sender)
        );
    }

    function unsetTPOrSL(
        address _indexToken,
        bool _isHigherPrice
    ) external nonReentrant whenNotPaused {
        if (_isHigherPrice) {
            _deleteTPSLRequestMap(msg.sender, _indexToken, true);
        } else {
            _deleteTPSLRequestMap(msg.sender, _indexToken, false);
        }
        _crossBlockchainCall(
            uint8(Method.UNSET_TP_OR_SL),
            abi.encode(
                _indexTokenToManager(_indexToken),
                msg.sender,
                _isHigherPrice
            )
        );
    }

    function _deleteTPSLRequestMap(
        address _account,
        address _indexToken,
        bool _isHigherPip
    ) private {
        gatewayStorage().deleteTpslRequest(_account, _indexToken, _isHigherPip);
    }

    function _storeTpslRequest(
        address _account,
        address _indexToken,
        bool _isHigherPip,
        bytes32 _decreasePositionRequestKey
    ) private {
        gatewayStorage().storeTpslRequest(
            _account,
            _indexToken,
            _isHigherPip,
            _decreasePositionRequestKey
        );
    }

    function _crossBlockchainCall(
        uint8 _destMethodID,
        bytes memory _functionCallData
    ) internal {
        CrosschainFunctionCallInterface(futurXGateway.futuresAdapter())
            .crossBlockchainCall(
                pscId(),
                pscCrossChainGateway(),
                _destMethodID,
                _functionCallData
            );
    }

    // get gateway storage return IFuturXGatewayStorage
    function gatewayStorage() private view returns (IFuturXGatewayStorage) {
        return IFuturXGatewayStorage(futurXGateway.gatewayStorage());
    }

    function _storeDecreasePositionRequest(
        address _account,
        address[] memory _path,
        address _indexToken,
        bool _withdrawETH
    ) internal returns (uint256, bytes32) {
        return
            gatewayStorage().storeDecreasePositionRequest(
                IFuturXGatewayStorage.DecreasePositionRequest(
                    _account,
                    _path,
                    _indexToken,
                    _withdrawETH,
                    0
                )
            );
    }

    function pscId() public view returns (uint256) {
        return futurXGateway.pcsId();
    }

    function pscCrossChainGateway() public view returns (address) {
        return futurXGateway.pscCrossChainGateway();
    }

    function _indexTokenToManager(
        address _indexToken
    ) internal view returns (address) {
        return futurXGateway.coreManagers(_indexToken);
    }
}