// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import { Initializable } from "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import "src/libraries/Errors.sol";
import "src/abstract/AdminAbstract.sol";

import "src/interfaces/manage/IFeeManager.sol";

contract FeeManager is AdminAbstract, Initializable, IFeeManager {
    uint16 public constant maxBPS = 10000; // 100%

    uint16 private positionFee;
    uint16 private borrowingFee;
    uint16 private liquidationFee;

    address private feeWallet;

    modifier onlyCorrectFee(uint16 _fee) {
        if (_fee > maxBPS) revert Errors.WrongFee();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _adminStructureAddress, address _feeWallet, uint16 _positionFee, uint16 _liquidationFee)
        external
        initializer
    {
        _setAdminStructure(_adminStructureAddress);
        _setFeeWallet(_feeWallet);
        _setPositionFee(_positionFee);
        _setLiquidationFee(_liquidationFee);
    }

    function setPositionFee(uint16 _newPositionFee) external onlyAdmin {
        _setPositionFee(_newPositionFee);

        emit PositionFeeSet(_newPositionFee);
    }

    function setLiquidationFee(uint16 _newLiquidationFee) external onlyAdmin {
        _setLiquidationFee(_newLiquidationFee);

        emit LiquidationFeeSet(_newLiquidationFee);
    }

    function setFeeWallet(address _newFeeWallet) external onlyAdmin {
        _setFeeWallet(_newFeeWallet);

        emit FeeWalletSet(_newFeeWallet);
    }

    function getPositionFee() external view returns (uint16) {
        return positionFee;
    }

    function getLiquidationFee() external view returns (uint16) {
        return liquidationFee;
    }

    function getFeeWallet() external view returns (address) {
        return feeWallet;
    }

    function _setPositionFee(uint16 _newPositionFee) private onlyCorrectFee(_newPositionFee) {
        positionFee = _newPositionFee;
    }

    function _setLiquidationFee(uint16 _newLiquidationFee) private onlyCorrectFee(_newLiquidationFee) {
        liquidationFee = _newLiquidationFee;
    }

    function _setFeeWallet(address _newFeeWallet) private {
        if (_newFeeWallet == address(0)) revert Errors.AddressZero();

        feeWallet = _newFeeWallet;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

library Errors {
    // Global
    error WrongAddress();
    error NotOrderBook();
    error NotPositionRegistry();

    // AdminStructure
    error NotSuperAdmin();
    error NotAdmin();

    // MarketManager
    error AlreadyOpened();
    error AlreadyClosed();
    error MaxLeverageTooHigh();

    // OrderBook
    error NotOpened();
    error ZeroMargin();
    error WrongLeverage();
    error HasOppositeOrder();
    error IsClosingOrder();
    error PriceIsZero();
    error TooManyOrders();
    error WrongOrder();

    // PositionRegistry
    error WrongPosition();
    error PositionClosed();
    error WrongQuantity();

    // Vault
    error TokenNotAllowed(address _token);
    error NothingToChange();
    error AddressZero();
    error ZeroDeposit();
    error ZeroWithdraw();
    error DepositLocked();
    error NotEnoughBalanceToWithdraw();
    error ZeroPNL();
    error InvalidSize();
    error InvalidTokenAmount();
    error InvalidSignature();
    error NotManager();

    // Fee
    error WrongFee();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "src/interfaces/admin/IAdminStructure.sol";

import "src/libraries/Errors.sol";

abstract contract AdminAbstract {
    IAdminStructure internal adminStructure;

    event AdminStructureSet(address _adminStructureAddress);

    modifier onlySuperAdmin() {
        if (msg.sender != IAdminStructure(adminStructure).superAdmin()) revert Errors.NotSuperAdmin();
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != IAdminStructure(adminStructure).admin()) revert Errors.NotAdmin();
        _;
    }

    // SETTINGS

    function setAdminStructure(address _adminStructureAddress) external onlySuperAdmin {
        _setAdminStructure(_adminStructureAddress);

        emit AdminStructureSet(_adminStructureAddress);
    }

    function _setAdminStructure(address _adminStructureAddress) internal {
        if (_adminStructureAddress == address(0)) revert Errors.WrongAddress();

        adminStructure = IAdminStructure(_adminStructureAddress);
    }

    // GETTERS

    function getAdminStructure() external view returns (address _adminStructureAddress) {
        return address(adminStructure);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IFeeManager {
    event PositionFeeSet(uint16 _positionFee);
    event LiquidationFeeSet(uint16 _liquidationFee);
    event FeeWalletSet(address _feeWallet);

    function setPositionFee(uint16 _newPositionFee) external;
    function setLiquidationFee(uint16 _newLiquidationFee) external;
    function setFeeWallet(address _newFeeWallet) external;

    function getPositionFee() external view returns (uint16);
    function getLiquidationFee() external view returns (uint16);
    function getFeeWallet() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

interface IAdminStructure {
    event AdminRigthsTransfered(address _admin);

    function superAdmin() external view returns (address _superAdmin);

    function admin() external view returns (address _admin);
}