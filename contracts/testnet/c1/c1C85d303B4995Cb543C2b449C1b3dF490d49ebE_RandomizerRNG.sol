// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol) <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/Initializable.sol>

pragma solidity 0.8.18;

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
 * possible by providing the encoded function call as the `_data` argument to the proxy constructor
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

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1))
    bytes32 private constant _INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a0e;

    /**
     * @dev The contract is already initialized.
     */
    error AlreadyInitialized();

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
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;
        if (!(isTopLevelCall && initialized < 1) && !(address(this).code.length == 0 && initialized == 1)) {
            revert AlreadyInitialized();
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
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert AlreadyInitialized();
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
            revert AlreadyInitialized();
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
            $.slot := _INITIALIZABLE_STORAGE
        }
    }
}

//SPDX-License-Identifier: MIT
// Adapted from <https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/utils/UUPSUpgradeable.sol>

/**
 *  @authors: [@malatrax]
 *  @reviewers: []
 *  @auditors: []
 *  @bounties: []
 *  @deployments: []
 */
pragma solidity 0.8.18;

/**
 * @title UUPS Proxiable
 * @author Simon Malatrait <[email protected]>
 * @dev This contract implements an upgradeability mechanism designed for UUPS proxies.
 * The functions included here can perform an upgrade of an UUPS Proxy, when this contract is set as the implementation behind such a proxy.
 *
 * IMPORTANT: A UUPS proxy requires its upgradeability functions to be in the implementation as opposed to the transparent proxy.
 * This means that if the proxy is upgraded to an implementation that does not support this interface, it will no longer be upgradeable.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSProxiable` with a custom implementation of upgrades.
 *
 * The `_authorizeUpgrade` function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSProxiable {
    // ************************************* //
    // *             Event                 * //
    // ************************************* //

    /**
     * Emitted when the `implementation` has been successfully upgraded.
     * @param newImplementation Address of the new implementation the proxy is now forwarding calls to.
     */
    event Upgraded(address indexed newImplementation);

    // ************************************* //
    // *             Error                 * //
    // ************************************* //

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /// The `implementation` is not UUPS-compliant
    error InvalidImplementation(address implementation);

    /// Failed Delegated call
    error FailedDelegateCall();

    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     * NOTE: bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
     */
    bytes32 private constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage variable of the proxiable contract address.
     * It is used to check whether or not the current call is from the proxy.
     */
    address private immutable __self = address(this);

    // ************************************* //
    // *             Governance            * //
    // ************************************* //

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract.
     * @dev Called by {upgradeToAndCall}.
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /**
     * @dev Upgrade mechanism including access control and UUPS-compliance.
     * @param newImplementation Address of the new implementation contract.
     * @param data Data used in a delegate call to `newImplementation` if non-empty. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     *
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual {
        _authorizeUpgrade(newImplementation);

        /* Check that the execution is being performed through a delegatecall call and that the execution context is
        a proxy contract with an implementation (as defined in ERC1967) pointing to self. */
        if (address(this) == __self || _getImplementation() != __self) {
            revert UUPSUnauthorizedCallContext();
        }

        try UUPSProxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            // Store the new implementation address to the implementation storage slot.
            assembly {
                sstore(IMPLEMENTATION_SLOT, newImplementation)
            }
            emit Upgraded(newImplementation);

            if (data.length != 0) {
                // The return data is not checked (checking, in case of success, that the newImplementation code is non-empty if the return data is empty) because the authorized callee is trusted.
                (bool success, ) = newImplementation.delegatecall(data);
                if (!success) {
                    revert FailedDelegateCall();
                }
            }
        } catch {
            revert InvalidImplementation(newImplementation);
        }
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /**
     * @dev Implementation of the ERC1822 `proxiableUUID` function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the if statement.
     */
    function proxiableUUID() external view virtual returns (bytes32) {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
        return IMPLEMENTATION_SLOT;
    }

    // ************************************* //
    // *           Internal Views          * //
    // ************************************* //

    function _getImplementation() internal view returns (address implementation) {
        assembly {
            implementation := sload(IMPLEMENTATION_SLOT)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

// Randomizer protocol interface
interface IRandomizer {
    function request(uint256 callbackGasLimit) external returns (uint256);

    function clientWithdrawTo(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface RNG {
    /// @dev Request a random number.
    /// @param _block Block linked to the request.
    function requestRandomness(uint256 _block) external;

    /// @dev Receive the random number.
    /// @param _block Block the random number is linked to.
    /// @return randomNumber Random Number. If the number is not ready or has not been required 0 instead.
    function receiveRandomness(uint256 _block) external returns (uint256 randomNumber);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "./RNG.sol";
import "./IRandomizer.sol";
import "../proxy/UUPSProxiable.sol";
import "../proxy/Initializable.sol";

/// @title Random Number Generator that uses Randomizer.ai
/// https://randomizer.ai/
contract RandomizerRNG is RNG, UUPSProxiable, Initializable {
    // ************************************* //
    // *             Storage               * //
    // ************************************* //

    address public governor; // The address that can withdraw funds.
    uint256 public callbackGasLimit; // Gas limit for the randomizer callback
    IRandomizer public randomizer; // Randomizer address.
    mapping(uint256 => uint256) public randomNumbers; // randomNumbers[requestID] is the random number for this request id, 0 otherwise.
    mapping(address => uint256) public requesterToID; // Maps the requester to his latest request ID.

    // ************************************* //
    // *        Function Modifiers         * //
    // ************************************* //

    modifier onlyByGovernor() {
        require(governor == msg.sender, "Governor only");
        _;
    }

    // ************************************* //
    // *            Constructor            * //
    // ************************************* //

    /// @dev Constructor, initializing the implementation to reduce attack surface.
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializer
    /// @param _randomizer Randomizer contract.
    /// @param _governor Governor of the contract.
    function initialize(IRandomizer _randomizer, address _governor) external reinitializer(1) {
        randomizer = _randomizer;
        governor = _governor;
        callbackGasLimit = 50000;
    }

    // ************************ //
    // *      Governance      * //
    // ************************ //

    /**
     * @dev Access Control to perform implementation upgrades (UUPS Proxiable)
     * @dev Only the governor can perform upgrades (`onlyByGovernor`)
     */
    function _authorizeUpgrade(address) internal view override onlyByGovernor {
        // NOP
    }

    /// @dev Changes the governor of the contract.
    /// @param _governor The new governor.
    function changeGovernor(address _governor) external onlyByGovernor {
        governor = _governor;
    }

    /// @dev Change the Randomizer callback gas limit.
    /// @param _callbackGasLimit the new limit.
    function setCallbackGasLimit(uint256 _callbackGasLimit) external onlyByGovernor {
        callbackGasLimit = _callbackGasLimit;
    }

    /// @dev Change the Randomizer address.
    /// @param _randomizer the new Randomizer address.
    function setRandomizer(address _randomizer) external onlyByGovernor {
        randomizer = IRandomizer(_randomizer);
    }

    /// @dev Allows the governor to withdraw randomizer funds.
    /// @param _amount Amount to withdraw in wei.
    function randomizerWithdraw(uint256 _amount) external onlyByGovernor {
        randomizer.clientWithdrawTo(msg.sender, _amount);
    }

    // ************************************* //
    // *         State Modifiers           * //
    // ************************************* //

    /// @dev Request a random number. The id of the request is tied to the sender.
    function requestRandomness(uint256 /*_block*/) external override {
        uint256 id = randomizer.request(callbackGasLimit);
        requesterToID[msg.sender] = id;
    }

    /// @dev Callback function called by the randomizer contract when the random value is generated.
    function randomizerCallback(uint256 _id, bytes32 _value) external {
        require(msg.sender == address(randomizer), "Randomizer only");
        randomNumbers[_id] = uint256(_value);
    }

    // ************************************* //
    // *           Public Views            * //
    // ************************************* //

    /// @dev Return the random number.
    /// @return randomNumber The random number or 0 if it is not ready or has not been requested.
    function receiveRandomness(uint256 /*_block*/) external view override returns (uint256 randomNumber) {
        // Get the latest request ID for this requester.
        uint256 id = requesterToID[msg.sender];
        randomNumber = randomNumbers[id];
    }
}