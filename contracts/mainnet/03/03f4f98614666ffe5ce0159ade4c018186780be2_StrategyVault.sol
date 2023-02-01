/**
 *Submitted for verification at Arbiscan on 2023-01-31
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/interfaces/IGmxHelper.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

interface IGmxHelper {
    function getTokenAums(address[] memory _tokens, bool _maximise) external view returns (uint256[] memory);

    function getTokenAumsPerAmount(uint256 _fsGlpAmount, bool _maximise) external view returns (uint256, uint256);

    function getPrice(address _token, bool _maximise) external view returns (uint256);

    function totalValue(address _account) external view returns (uint256);

    function getLastFundingTime() external view returns (uint256);

    function getCumulativeFundingRates(address _token) external view returns (uint256);

    function getFundingFee(address _account, address _indexToken) external view returns (uint256);

    function getLongValue(uint256 _glpAmount) external view returns (uint256);

    function getShortValue(address _account, address _indexToken) external view returns (uint256);

    function getMintBurnFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        bool _increment
    ) external view returns (uint256);

    function getGlpTotalSupply() external view returns (uint256);

    function getAumInUsdg(bool _maximise) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function getPosition(
        address _account,
        address _indexToken
    ) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function getFundingFeeWithRate(
        address _account,
        address _indexToken,
        uint256 _fundingRate
    ) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _avgPrice) external view returns (bool, uint256);

    function validateMaxGlobalShortSize(address _indexToken, uint256 _sizeDelta) external view returns (bool);
}


// File contracts/interfaces/IMintable.sol

pragma solidity 0.8.11;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}


// File contracts/interfaces/IERC20.sol

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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


// File contracts/interfaces/gmx/IGlpManager.sol

pragma solidity 0.8.11;

interface IGlpManager {
    function aumAddition() external view returns (uint256);

    function aumDedection() external view returns (uint256);

    function getAum(bool maximise) external view returns (uint256);

    function getAums() external view returns (uint256[] memory);

    function cooldownDuration() external view returns (uint256);

    function lastAddedAt(address) external view returns (uint256);

    function getAumInUsdg(bool maximise) external view returns (uint256);
}


// File contracts/interfaces/gmx/IRewardRouter.sol

pragma solidity 0.8.11;

interface IRewardRouter {
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;

    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    function signalTransfer(address _receiver) external;
}


// File contracts/interfaces/gmx/IReferralStorage.sol

pragma solidity 0.8.11;

interface IReferralStorage {
    function registerCode(bytes32 _code) external;

    function setTraderReferralCodeByUser(bytes32 _code) external;
}


// File contracts/interfaces/gmx/IRouter.sol

pragma solidity 0.8.11;

interface IRouter {
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;

    function approvePlugin(address _plugin) external;
}


// File contracts/interfaces/gmx/IPositionRouter.sol

pragma solidity 0.8.11;

interface IPositionRouter {
    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable;

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable;

    function increasePositionRequestKeysStart() external view returns (uint256);
    function decreasePositionRequestKeysStart() external view returns (uint256);
    function maxGlobalShortSizes(address _indexToken) external view returns (uint256);
    function minExecutionFee() external view returns (uint256);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}


// File @openzeppelin/contracts-upgradeable/interfaces/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}


// File @openzeppelin/contracts-upgradeable/proxy/beacon/[email protected]
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}


// File @openzeppelin/contracts-upgradeable/proxy/ERC1967/[email protected]
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;





/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;



/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}


// File contracts/StrategyVault.sol

pragma solidity 0.8.11;









struct InitialConfig {
    address glpManager;
    address positionRouter;
    address rewardRouter;
    address glpRewardRouter;
    address router;
    address referralStorage;
    address fsGlp;
    address gmx;
    address sGmx;

    address want;
    address wbtc;
    address weth;
    address nGlp;
}

struct ConfirmList {
    //for withdraw
    bool hasDecrease;

    //for rebalance
    uint256 beforeWantBalance;
}

struct PendingPositionFeeInfo {
    uint256 fundingRate; // wbtc and weth should have the same fundingRate  
    uint256 wbtcFundingFee;
    uint256 wethFundingFee;
}

contract StrategyVault is Initializable, UUPSUpgradeable {
    uint256 constant SECS_PER_YEAR = 31_536_000;
    uint256 constant MAX_BPS = 10_000;
    uint256 constant PRECISION = 1e30;
    uint256 constant MAX_MANAGEMENT_FEE = 500_000_000;
    uint256 constant MANAGEMENT_FEE_BPS = 10_000_000_000;

    bool public confirmed;
    bool public initialDeposit;
    bool public exited;
    
    bytes32 public referralCode;

    uint256 public executionFee;

    uint256 public lastCollect; // block.timestamp of last collect
    uint256 public managementFee; 

    uint256 public insuranceFund;
    uint256 public feeReserves;
    uint256 public prepaidGmxFee;

    // gmx 
    uint256 public marginFeeBasisPoints;

    // fundingFee can be unpaid if requests position before funding rate increases 
    // and then position gets executed after funding rate increases 
    mapping(address => uint256) public unpaidFundingFee;

    ConfirmList public confirmList;
    PendingPositionFeeInfo public pendingPositionFeeInfo;

    address public gov;
    // deposit token
    address public want;
    address public wbtc;
    address public weth;
    address public nGlp;
    address public gmxHelper;
    address public management;

    // GMX interfaces
    address public glpManager;
    address public positionRouter;
    address public rewardRouter;
    address public glpRewardRouter;
    address public gmxRouter;
    address public referralStorage;
    address public fsGlp;
    address public callbackTarget;

    mapping(address => bool) public routers;
    mapping(address => bool) public keepers;

    uint256 pendingShortValue;

    event RebalanceActions(uint256 timestamp, bool isBuy, bool hasWbtcIncrease, bool hasWbtcDecrease, bool hasWethIncrease, bool hasWethDecrease);
    event BuyNeuGlp(uint256 amountIn, uint256 amountOut, uint256 value);
    event SellNeuGlp(uint256 amountIn, uint256 amountOut, address recipient);
    event ConfirmRebalance(bool hasDebt, uint256 delta, uint256 prepaidGmxFee);
    event Harvest(uint256 amountOut, uint256 feeReserves);
    event CollectManagementFee(uint256 alpha, uint256 lastCollect);
    event RepayFundingFee(uint256 wbtcFundingFee, uint256 wethFundingFee, uint256 prepaidGmxFee);
    event DepositInsuranceFund(uint256 amount, uint256 insuranceFund);
    event BuyGlp(uint256 amount);
    event SellGlp(uint256 amount, address recipient);
    event IncreaseShortPosition(address _indexToken, uint256 _amountIn, uint256 _sizeDelta);
    event DecreaseShortPosition(address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, address _recipient);
    event RepayUnpaidFundingFee(uint256 unpaidFundingFeeWbtc, uint256 unpaidFundingFeeWeth);
    event WithdrawFees(uint256 amount, address receiver);
    event WithdrawInsuranceFund(uint256 amount, address receiver);
    event Settle(uint256 amountIn, uint256 amountOut, address recipient);
    event SetGov(address gov);
    event SetGmxHelper(address helper);
    event SetKeeper(address keeper, bool isActive);
    event SetWant(address want);
    event SetExecutionFee(uint256 fee);
    event SetCallbackTarget(address callbackTarget);
    event SetRouter(address router, bool isActive);
    event SetManagement(address management, uint256 fee);
    event WithdrawEth(uint256 amount);
    event ConfirmFundingRates(uint256 lastUpdatedFundingRate, uint256 wbtcFundingRate, uint256 wethFundingRate);
    event AdjustPrepaidGmxFee(uint256 adjustAmount, uint256 prepaidGmxFee);
    event ConfirmFundingFees(uint256 wbtcFundingFee, uint256 pendingPositionFeeInfo, uint256 prepaidGmxFee);

    modifier onlyGov() {
        _onlyGov();
        _;
    }

    modifier onlyKeepersAndAbove() {
        _onlyKeepersAndAbove();
        _;
    }

    modifier onlyRouter() {
        _onlyRouter();
        _;
    }

    function initialize(InitialConfig memory _config) public initializer {
        glpManager = _config.glpManager;
        positionRouter = _config.positionRouter;
        rewardRouter = _config.rewardRouter;
        glpRewardRouter = _config.glpRewardRouter;
        gmxRouter = _config.router;
        referralStorage = _config.referralStorage;
        fsGlp = _config.fsGlp;

        want = _config.want;
        wbtc = _config.wbtc;
        weth = _config.weth;
        nGlp = _config.nGlp;
        gov = msg.sender;
        executionFee = 100000000000000;
        marginFeeBasisPoints = 10;
        confirmed = true;

        IERC20(want).approve(glpManager, type(uint256).max);
        IERC20(want).approve(gmxRouter, type(uint256).max);
        IRouter(gmxRouter).approvePlugin(positionRouter);
        IERC20(_config.gmx).approve(_config.sGmx, type(uint256).max);
        IERC20(weth).approve(gmxRouter, type(uint256).max);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyGov {}

    function _onlyGov() internal view {
        require(msg.sender == gov, "StrategyVault: not authorized");
    }

    function _onlyKeepersAndAbove() internal view {
        require(keepers[msg.sender] || routers[msg.sender] || msg.sender == gov, "StrategyVault: not keepers");
    }

    function _onlyRouter() internal view {
        require(routers[msg.sender], "StrategyVault: not router");
    }

    /// @dev rebalance init function
    function minimiseDeltaWithBuyGlp(bytes4[] calldata _selectors, bytes[] calldata _params) external payable onlyKeepersAndAbove {
        require(confirmed, "StrategyVault: not confirmed yet");
        require(!exited, "StrategyVault: strategy already exited");
        uint256 length = _selectors.length;
        require(msg.value >= executionFee * (length - 1), "StrategyVault: not enough execution fee");
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        
        _updatePendingPositionFundingRate();

        _harvest();
        
        bool hasWbtcIncrease;
        bool hasWbtcDecrease;
        bool hasWethIncrease;
        bool hasWethDecrease;
        // save current balance of want to track debt cost after rebalance; 
        confirmList.beforeWantBalance = IERC20(want).balanceOf(address(this));

        for(uint256 i=0; i<length; i++) {
            bytes4 selector = _selectors[i];
            bytes memory param = _params[i];
            if (i == 0) {
                require(selector == this.buyGlp.selector, "StrategyVault: should buy glp first");
                
                uint256 amount = abi.decode(param, (uint256));
                if (amount == 0) { continue; }
                
                buyGlp(amount);
                continue;
            } 
            
            if (i == 1 || i == 2) {
                require(selector == this.increaseShortPosition.selector, "StrategyVault: should increase position");
                (address indexToken, uint256 amountIn, uint256 sizeDelta) = abi.decode(_params[i], (address, uint256, uint256));

                uint256 fundingFee = _gmxHelper.getFundingFee(address(this), indexToken); // 30 decimals
                fundingFee = usdToTokenMax(want, fundingFee, true);
                if (indexToken == wbtc) {
                    pendingPositionFeeInfo.wbtcFundingFee = fundingFee;
                    hasWbtcIncrease = true;
                } else {
                    pendingPositionFeeInfo.wethFundingFee = fundingFee;
                    hasWethIncrease = true;
                }
                // add additional funding fee here to save execution fee
                increaseShortPosition(indexToken, amountIn + fundingFee, sizeDelta);
                continue;
            }

            // call remainig actions should be decrease action
            (address indexToken, uint256 collateralDelta, uint256 sizeDelta, address recipient) = abi.decode(param, (address, uint256, uint256, address));

            if (indexToken == wbtc) {
                hasWbtcDecrease = true;
            } else {
                hasWethDecrease = true;
            }

            decreaseShortPosition(indexToken, collateralDelta, sizeDelta, recipient);
        }

        _requireConfirm();

        emit RebalanceActions(block.timestamp, true, hasWbtcIncrease, hasWbtcDecrease, hasWethIncrease, hasWethDecrease);
    }

    /// @dev rebalance init function
    function minimiseDeltaWithSellGlp(bytes4[] calldata _selectors, bytes[] calldata _params) external payable onlyKeepersAndAbove {
        require(confirmed, "StrategyVault: not confirmed yet");
        require(!exited, "StrategyVault: strategy already exited");
        uint256 length = _selectors.length;
        require(msg.value >= executionFee * (length - 1), "StrategyVault: not enough execution fee");
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        
        _updatePendingPositionFundingRate();

        _harvest();
        
        bool hasWbtcIncrease;
        bool hasWbtcDecrease;
        bool hasWethIncrease;
        bool hasWethDecrease;
        // save current balance of want to track debt cost after rebalance; 
        confirmList.beforeWantBalance = IERC20(want).balanceOf(address(this));

        for(uint256 i=0; i<length; i++){
            bytes4 selector = _selectors[i];
            bytes memory param = _params[i];
            if(i == 0) {
                require(selector == this.sellGlp.selector, "StrategyVault: should sell glp first");

                (uint256 amount, address recipient) = abi.decode(param, (uint256, address));
                if (amount == 0) { continue; }

                sellGlp(amount, recipient);
                continue;
            }

            if(i==1 || i == 2) {
                require(selector == this.increaseShortPosition.selector, "StrategyVault: should increase position");
                (address indexToken, uint256 amountIn, uint256 sizeDelta) = abi.decode(_params[i], (address, uint256, uint256));

                uint256 fundingFee = _gmxHelper.getFundingFee(address(this), indexToken); // 30 decimals
                fundingFee = usdToTokenMax(want, fundingFee, true);

                if (indexToken == wbtc) {
                    pendingPositionFeeInfo.wbtcFundingFee = fundingFee;
                    hasWbtcIncrease = true;
                } else {
                    pendingPositionFeeInfo.wethFundingFee = fundingFee;
                    hasWethIncrease = true;
                }
                // add additional funding fee here to save execution fee
                increaseShortPosition(indexToken, amountIn + fundingFee, sizeDelta);
                continue;
            }

            // remainig actions should be decrease action
            (address indexToken, uint256 collateralDelta, uint256 sizeDelta, address recipient) = abi.decode(param, (address, uint256, uint256, address));
            
            if (indexToken == wbtc) {
                hasWbtcDecrease = true;
            } else {
                hasWethDecrease = true;
            }

            decreaseShortPosition(indexToken, collateralDelta, sizeDelta, recipient);
        }

        _requireConfirm();

        emit RebalanceActions(block.timestamp, false, hasWbtcIncrease, hasWbtcDecrease, hasWethIncrease, hasWethDecrease);
    }
    
    /// @dev deposit init function 
    /// execute wbtc, weth increase positions
    function executeIncreasePositions(bytes[] calldata _params) external payable onlyRouter {
        require(confirmed, "StrategyVault: not confirmed yet");
        require(!exited, "StrategyVault: strategy already exited");
        require(_params.length == 2, "StrategyVault: invalid length of parameters");
        require(msg.value >= executionFee * 2, "StrategyVault: not enough execution fee");
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        
        _updatePendingPositionFundingRate();

        // always conduct harvest beforehand to update funding fee
        _harvest();

        for (uint256 i=0; i<2; i++) {
            (address indexToken, uint256 amountIn, uint256 sizeDelta) = abi.decode(_params[i], (address, uint256, uint256));
            IERC20(want).transferFrom(msg.sender, address(this), amountIn);

            uint256 positionFee = sizeDelta * marginFeeBasisPoints / MAX_BPS;
            uint256 shortValue = tokenToUsdMin(want, amountIn);
            pendingShortValue += shortValue - positionFee;

            uint256 fundingFee = _gmxHelper.getFundingFee(address(this), indexToken); // 30 decimals
            fundingFee = usdToTokenMax(want, fundingFee, true);

            if (indexToken == wbtc) {
                pendingPositionFeeInfo.wbtcFundingFee = fundingFee;
            } else {
                pendingPositionFeeInfo.wethFundingFee = fundingFee;
            }
            
            // add additional funding fee here to save execution fee
            increaseShortPosition(indexToken, amountIn + fundingFee, sizeDelta);
        }
        _requireConfirm();

    }

    /// @dev withdraw init function
    /// execute wbtc, weth decrease positions
    function executeDecreasePositions(bytes[] calldata _params) external payable onlyRouter {
        require(confirmed, "StrategyVault: not confirmed yet");
        require(!exited, "StrategyVault: strategy already exited");
        require(_params.length == 2, "StrategyVault: invalid length of parameters");
        require(msg.value >= executionFee * 2, "StrategyVault: not enough execution fee");
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        
        _updatePendingPositionFundingRate();

        // always conduct harvest beforehand to update funding fee
        _harvest();

        confirmList.hasDecrease = true;

        for (uint256 i=0; i<2; i++) {
            (address indexToken, uint256 collateralDelta, uint256 sizeDelta, address recipient) = abi.decode(_params[i], (address, uint256, uint256, address));
            uint256 positionFee = sizeDelta * marginFeeBasisPoints / MAX_BPS; // 30 deciamls
            uint256 fundingFee = _gmxHelper.getFundingFee(address(this), indexToken); // 30 decimals

            if (indexToken == wbtc) {
                pendingPositionFeeInfo.wbtcFundingFee = usdToTokenMax(want, fundingFee, true);
            } else {
                pendingPositionFeeInfo.wethFundingFee = usdToTokenMax(want, fundingFee, true);
            }

            // when collateralDelta is less than margin fee, fee will be subtracted on position state
            // to prevent , collateralDelta always has to be greater than fees
            // if it reverts, should repay funding fee first 
            require(collateralDelta > positionFee + fundingFee, "StrategyVault: not enough collateralDelta");

            decreaseShortPosition(indexToken, collateralDelta, sizeDelta, recipient);
        }
        _requireConfirm();

    }

    /// @dev should be called only if positions execution had been failed
    function retryPositions(bytes4[] calldata _selectors, bytes[] calldata _params) external payable onlyKeepersAndAbove {
        require(!confirmed, "StrategyVault: no failed execution");
        uint256 length = _selectors.length;
        require(msg.value >= executionFee * length, "StrategyVault: not enough execution fee");
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        
        _harvest();

        for(uint256 i=0; i<length; i++){
            bytes4 selector = _selectors[i];
            bytes memory param = _params[i];
            if(selector == this.increaseShortPosition.selector) {
                (address indexToken, uint256 amountIn, uint256 sizeDelta) = abi.decode(_params[i], (address, uint256, uint256));
                
                uint256 fundingFee = _gmxHelper.getFundingFee(address(this), indexToken); // 30 decimals
                fundingFee = usdToTokenMax(want, fundingFee, true);

                if (indexToken == wbtc) {
                    pendingPositionFeeInfo.wbtcFundingFee = fundingFee;
                } else {
                    pendingPositionFeeInfo.wethFundingFee = fundingFee;
                }
                // add additional funding fee here to save execution fee
                increaseShortPosition(indexToken, amountIn + fundingFee, sizeDelta);
                continue;
            }

            (address indexToken, uint256 collateralDelta, uint256 sizeDelta, address recipient) = abi.decode(param, (address, uint256, uint256, address));

            decreaseShortPosition(indexToken, collateralDelta, sizeDelta, recipient);
        }
    }

    function buyNeuGlp(uint256 _amountIn) external onlyRouter returns (uint256) {
        require(confirmed, "StrategyVault: not confirmed yet");
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);
        
        // amountOut 18 decimal
        IERC20(want).transferFrom(msg.sender, address(this), _amountIn);
        uint256 amountOut = buyGlp(_amountIn);

        uint256 longValue = _gmxHelper.getLongValue(amountOut); // 30 decimals
        uint256 shortValue = pendingShortValue;
        uint256 value = longValue + shortValue;

        pendingShortValue = 0;
        
        emit BuyNeuGlp(_amountIn, amountOut, value);

        return value;
    }

    function sellNeuGlp(uint256 _glpAmount, address _recipient) external onlyRouter returns (uint256) {
        require(confirmed, "StrategyVault: not confirmed yet");

        uint256 amountOut = sellGlp(_glpAmount, _recipient); 
  
        emit SellNeuGlp(_glpAmount, amountOut, _recipient);

        return amountOut;
    }

    // confirm for deposit & withdraw
    function confirm() external onlyRouter {
        _confirm();
        
        if (confirmList.hasDecrease) {
            // wamt decimals
            uint256 fundingFee = pendingPositionFeeInfo.wbtcFundingFee + pendingPositionFeeInfo.wethFundingFee;
            IERC20(want).transfer(msg.sender, fundingFee);
            confirmList.hasDecrease = false;
        }
        
        _clearPendingPositionFeeInfo();

        confirmed = true;
    }

    // confirm for rebalance
    function confirmRebalance() external onlyKeepersAndAbove {
        _confirm();

        uint256 currentBalance = IERC20(want).balanceOf(address(this));

        uint256 fundingFee = pendingPositionFeeInfo.wbtcFundingFee + pendingPositionFeeInfo.wethFundingFee;

        // fundingFee must be added in order to avoid double counting
        currentBalance += fundingFee; // want decimals

        bool hasDebt = currentBalance < confirmList.beforeWantBalance;
        uint256 delta = hasDebt ? confirmList.beforeWantBalance - currentBalance : currentBalance - confirmList.beforeWantBalance;

        if(hasDebt) {
            prepaidGmxFee = prepaidGmxFee + delta;
        } else {
            if (prepaidGmxFee > delta) {
                prepaidGmxFee -= delta;
            } else {
                feeReserves += delta - prepaidGmxFee;
                prepaidGmxFee = 0;
            }
        }

        confirmList.beforeWantBalance = 0;

        _clearPendingPositionFeeInfo();

        confirmed = true;

        emit ConfirmRebalance(hasDebt, delta, prepaidGmxFee);
    }

    function _confirm() internal {
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);

        (,,,uint256 wbtcFundingRate,,,,) = _gmxHelper.getPosition(address(this), wbtc);
        (,,,uint256 wethFundingRate,,,,) = _gmxHelper.getPosition(address(this), weth);

        uint256 lastUpdatedFundingRate = pendingPositionFeeInfo.fundingRate;
        require(wbtcFundingRate >= lastUpdatedFundingRate && wethFundingRate >= lastUpdatedFundingRate, "StrategyVault: positions not executed");
        
        if (wbtcFundingRate > lastUpdatedFundingRate) {
            uint256 wbtcFundingFee = _gmxHelper.getFundingFeeWithRate(address(this), wbtc, lastUpdatedFundingRate); // 30 decimals
            unpaidFundingFee[wbtc] += usdToTokenMax(want, wbtcFundingFee, true);
        } 

        if (wethFundingRate > lastUpdatedFundingRate) {
            uint256 wethFundingFee = _gmxHelper.getFundingFeeWithRate(address(this), weth, lastUpdatedFundingRate); // 30 decimals
            unpaidFundingFee[weth] += usdToTokenMax(want, wethFundingFee, true);
        }
        
        uint256 fundingFee = pendingPositionFeeInfo.wbtcFundingFee + pendingPositionFeeInfo.wethFundingFee;

        prepaidGmxFee += fundingFee; // want decimals

        emit ConfirmFundingRates(lastUpdatedFundingRate, wbtcFundingRate, wethFundingRate);
        emit ConfirmFundingFees(pendingPositionFeeInfo.wbtcFundingFee, pendingPositionFeeInfo.wethFundingFee, prepaidGmxFee);
    }

    function harvest() external {
        _harvest();
    }

    function _harvest() internal {
        _collectManagementFee();

        IRewardRouter(rewardRouter).handleRewards(true, true, true, true, true, true, false);

        uint256 beforeWantBalance = IERC20(want).balanceOf(address(this));
        // this might include referral rewards 
        uint256 wethBalance = IERC20(weth).balanceOf(address(this));
        if (wethBalance > 0) {
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = want;
            IRouter(gmxRouter).swap(path, wethBalance, 0, address(this));
        }
        uint256 amountOut = IERC20(want).balanceOf(address(this)) - beforeWantBalance;
        if (amountOut == 0) {
            return;
        }

        feeReserves += amountOut;

        emit Harvest(amountOut, feeReserves);

        return;
    }

    // (totalVaule) / (totalSupply + alpha) = (totalValue * (1-(managementFee * duration))) / totalSupply 
    // alpha = (totalSupply / (1-(managementFee * duration))) - totalSupply
    function _collectManagementFee() internal {
        uint256 _lastCollect = lastCollect;
        if (_lastCollect == 0) {
            return;
        }
        uint256 duration = block.timestamp - _lastCollect;
        uint256 supply = IERC20(nGlp).totalSupply() - IERC20(nGlp).balanceOf(management);
        uint256 alpha = supply * MANAGEMENT_FEE_BPS / (MANAGEMENT_FEE_BPS - (managementFee * duration / SECS_PER_YEAR)) - supply;
        if (alpha == 0) {
            return;
        }
        IMintable(nGlp).mint(management, alpha);
        lastCollect = block.timestamp;   

        emit CollectManagementFee(alpha, lastCollect);
    }

    function activateManagementFee() external onlyGov {
        lastCollect = block.timestamp;
    }

    function deactivateManagementFee() external onlyGov {
        lastCollect = 0;
    }

    /// @dev repaying funding fee requires execution fee
    /// @dev needs to call regularly by keepers
    function repayFundingFee() external payable onlyKeepersAndAbove {
        require(!exited, "StrategyVault: strategy already exited");
        require(msg.value >= executionFee * 2, "StrategyVault: not enough execution fee");

        _harvest();

        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);

        uint256 wbtcFundingFee = _gmxHelper.getFundingFee(address(this), wbtc); // 30 decimals
        wbtcFundingFee = usdToTokenMax(want, wbtcFundingFee, true);
        uint256 wethFundingFee = _gmxHelper.getFundingFee(address(this), weth);
        wethFundingFee = usdToTokenMax(want, wethFundingFee, true);
        
        uint256 balance = IERC20(want).balanceOf(address(this));
        require(wethFundingFee + wbtcFundingFee <= balance, "StrategyVault: not enough balance to repay");

        if (wbtcFundingFee > 0) {
            increaseShortPosition(wbtc, wbtcFundingFee, 0);
        }

        if (wethFundingFee > 0) {
            increaseShortPosition(weth, wethFundingFee, 0);
        }

        prepaidGmxFee = prepaidGmxFee + wbtcFundingFee + wethFundingFee;

        emit RepayFundingFee(wbtcFundingFee, wethFundingFee, prepaidGmxFee);
    }

    function exitStrategy() external payable onlyGov {
        require(!exited, "StrategyVault: strategy already exited");
        require(confirmed, "StrategyVault: not confirmed yet");
        IGmxHelper _gmxHelper = IGmxHelper(gmxHelper);

        _harvest();

        sellGlp(IERC20(fsGlp).balanceOf(address(this)), address(this));

        (uint256 wbtcSize,,,,,,,) = _gmxHelper.getPosition(address(this), wbtc);
        (uint256 wethSize,,,,,,,) = _gmxHelper.getPosition(address(this), weth);

        decreaseShortPosition(wbtc, 0, wbtcSize, msg.sender);
        decreaseShortPosition(weth, 0, wethSize, msg.sender);

        exited = true;
    }

    // executed only if strategy exited
    // make sure to withdraw insuranceFund and withdraw fees beforehand
    function settle(uint256 _amount, address _recipient) external onlyRouter {
        require(exited, "StrategyVault: stragey not exited yet");
        uint256 value = _totalValue();
        uint256 supply = IERC20(nGlp).totalSupply();
        uint256 amountOut = value * _amount / supply;
        IERC20(want).transfer(_recipient, amountOut);
        emit Settle(_amount, amountOut, _recipient);
    }

    function _updatePendingPositionFundingRate() internal {
        uint256 cumulativeFundingRate = IGmxHelper(gmxHelper).getCumulativeFundingRates(want);
        pendingPositionFeeInfo.fundingRate = cumulativeFundingRate;
    }

    function _requireConfirm() internal {
        confirmed = false;
    }

    function _clearPendingPositionFeeInfo() internal {
        pendingPositionFeeInfo.fundingRate = 0;
        pendingPositionFeeInfo.wbtcFundingFee = 0;
        pendingPositionFeeInfo.wethFundingFee = 0;
    }

    function depositInsuranceFund(uint256 _amount) public onlyGov {
        IERC20(want).transferFrom(msg.sender, address(this), _amount);
        insuranceFund += _amount;

        emit DepositInsuranceFund(_amount, insuranceFund);
    }

    function buyGlp(uint256 _amount) public onlyKeepersAndAbove returns (uint256) {
        emit BuyGlp(_amount);
        //TODO: improve slippage
        return IRewardRouter(glpRewardRouter).mintAndStakeGlp(want, _amount, 0, 0);
    }

    function sellGlp(uint256 _amount, address _recipient) public onlyKeepersAndAbove returns (uint256) {
        emit SellGlp(_amount, _recipient);
        //TODO: improve slippage
        return IRewardRouter(glpRewardRouter).unstakeAndRedeemGlp(want, _amount, 0, _recipient);
    }

    function increaseShortPosition(
        address _indexToken,
        uint256 _amountIn,
        uint256 _sizeDelta
    ) public payable onlyKeepersAndAbove {
        require(IGmxHelper(gmxHelper).validateMaxGlobalShortSize(_indexToken, _sizeDelta), "StrategyVault: max global shorts exceeded");

        address[] memory path = new address[](1);
        path[0] = want;

        //TODO: can improve minOut and acceptablePrice
        IPositionRouter(positionRouter).createIncreasePosition{value: executionFee}(
            path,
            _indexToken,
            _amountIn,
            0, // minOut
            _sizeDelta,
            false,
            0, // acceptablePrice
            executionFee,
            referralCode,
            callbackTarget
        );

        emit IncreaseShortPosition(_indexToken, _amountIn, _sizeDelta);
    }

    function decreaseShortPosition(
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        address _recipient
    ) public payable onlyKeepersAndAbove {
        address[] memory path = new address[](1);
        path[0] = want;

        //TODO: can improve acceptablePrice and minOut
        IPositionRouter(positionRouter).createDecreasePosition{value: executionFee}(
            path,
            _indexToken,
            _collateralDelta,
            _sizeDelta,
            false,
            _recipient,
            type(uint256).max, // acceptablePrice
            0,
            executionFee,
            false,
            callbackTarget
        );

        emit DecreaseShortPosition(_indexToken, _collateralDelta, _sizeDelta, _recipient);
    }

    function setGov(address _gov) external onlyGov {
        require(_gov != address(0), "StrategyVault: invalid address");
        gov = _gov;
        emit SetGov(_gov);
    }

    function setGmxHelper(address _helper) external onlyGov {
        require(_helper != address(0), "StrategyVault: invalid address");
        gmxHelper = _helper;
        emit SetGmxHelper(_helper);
    }

    function setMarginFeeBasisPoints(uint256 _bps) external onlyGov {
        marginFeeBasisPoints = _bps;
    }

    function setKeeper(address _keeper, bool _isActive) external onlyGov {
        require(_keeper != address(0), "StrategyVault: invalid address");
        keepers[_keeper] = _isActive;
        emit SetKeeper(_keeper, _isActive);
    }

    function setWant(address _want) external onlyGov {
        IERC20(want).approve(glpManager, 0);
        IERC20(want).approve(gmxRouter, 0);
        want = _want;
        IERC20(_want).approve(glpManager, type(uint256).max);
        IERC20(_want).approve(gmxRouter, type(uint256).max);
        emit SetWant(_want);
    }

    function setExecutionFee(uint256 _executionFee) external onlyGov {
        require(_executionFee > IPositionRouter(positionRouter).minExecutionFee(), "StrategyVault: execution fee needs to be set higher");
        executionFee = _executionFee;
        emit SetExecutionFee(_executionFee);
    }

    function setCallbackTarget(address _callbackTarget) external onlyGov {
        callbackTarget = _callbackTarget;
        emit SetCallbackTarget(_callbackTarget);
    }

    function setRouter(address _router, bool _isActive) external onlyGov {
        require(_router != address(0), "StrategyVault: invalid address");
        routers[_router] = _isActive;
        emit SetRouter(_router, _isActive);
    }

    function setManagement(address _management, uint256 _fee) external onlyGov {
        require(_management != address(0), "StrategyVault: invalid address");
        require(MAX_MANAGEMENT_FEE >= _fee, "StrategyVault: max fee exceeded");
        management = _management;
        managementFee =_fee;
        emit SetManagement(_management, _fee);
    }

    function registerAndSetReferralCode(string memory _text) public onlyGov {
        bytes32 stringToByte32 = bytes32(bytes(_text));

        IReferralStorage(referralStorage).registerCode(stringToByte32);
        IReferralStorage(referralStorage).setTraderReferralCodeByUser(stringToByte32);
        referralCode = stringToByte32;
    }

    function totalValue() external view returns (uint256) {
        return _totalValue();
    }

    function _totalValue() internal view returns (uint256) {
        return exited ? IERC20(want).balanceOf(address(this)) : IGmxHelper(gmxHelper).totalValue(address(this));
    }

    function repayUnpaidFundingFee() external payable onlyKeepersAndAbove {
        require(!exited, "StrategyVault: strategy already exited");

        uint256 unpaidFundingFeeWbtc = unpaidFundingFee[wbtc];
        uint256 unpaidFundingFeeWeth = unpaidFundingFee[weth];

        if (unpaidFundingFeeWbtc > 0) {
            increaseShortPosition(wbtc, unpaidFundingFeeWbtc, 0);
            unpaidFundingFee[wbtc] = 0;
        }

        if (unpaidFundingFeeWeth > 0) {
            increaseShortPosition(weth, unpaidFundingFeeWeth, 0);
            unpaidFundingFee[weth] = 0;
        }

        emit RepayUnpaidFundingFee(unpaidFundingFeeWbtc, unpaidFundingFeeWeth);
    }

    function withdrawFees(address _receiver) external onlyGov returns (uint256) {
        _harvest();

        if (prepaidGmxFee >= feeReserves) {
            feeReserves = 0;
            prepaidGmxFee -= feeReserves;
            return 0;
        }

        uint256 amount = feeReserves - prepaidGmxFee;
        prepaidGmxFee = 0;
        feeReserves = 0;
        IERC20(want).transfer(_receiver, amount);

        emit WithdrawFees(amount, _receiver);

        return amount;
    }

    function withdrawInsuranceFund(address _receiver) external onlyGov returns (uint256) {
        uint256 curBalance = IERC20(want).balanceOf(address(this));
        uint256 amount = insuranceFund >= curBalance ? curBalance : insuranceFund;
        insuranceFund -= amount;
        IERC20(want).transfer(_receiver, amount);

        emit WithdrawInsuranceFund(amount, _receiver);

        return amount;
    }

    // rescue execution fee
    function withdrawEth() external payable onlyGov {
        payable(msg.sender).transfer(address(this).balance);
        emit WithdrawEth(address(this).balance);
    }

    function adjustPrepaidGmxFee(uint256 _amount) external onlyGov {
        prepaidGmxFee -= _amount;
        emit AdjustPrepaidGmxFee(_amount, prepaidGmxFee);
    }

    function tokenToUsdMin(address _token, uint256 _tokenAmount) public view returns(uint256) {
        if (_tokenAmount == 0) { return 0; }
        uint256 price = IGmxHelper(gmxHelper).getPrice(_token, false);
        uint256 decimals = IERC20(_token).decimals();
        return _tokenAmount * price / (10 ** decimals);
    }

    function usdToTokenMax(address _token, uint256 _usdAmount, bool _isCeil) public view returns(uint256) {
        if (_usdAmount == 0) { return 0; }
        uint256 price = IGmxHelper(gmxHelper).getPrice(_token, false);
        uint256 decimals = IERC20(_token).decimals();
        return _isCeil ? ceilDiv(_usdAmount * (10 ** decimals), price) : _usdAmount * (10 ** decimals) / price;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }
}