// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "contract-evm/src/interface/IVault.sol";
import "contract-evm/src/library/types/VaultTypes.sol";
import "contract-evm/src/library/types/EventTypes.sol";
import "contract-evm/src/library/Utils.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interface/IVaultCrossChainManager.sol";
import "./interface/IOrderlyCrossChain.sol";
import "./utils/OrderlyCrossChainMessage.sol";

contract VaultCrossChainManagerDatalayout {
    // src chain id
    uint256 public chainId;
    // ledger chain id
    uint256 public ledgerChainId;
    // vault interface
    IVault public vault;
    // crosschain relay interface
    IOrderlyCrossChain public crossChainRelay;
    // map of chainId => LedgerCrossChainManager
    mapping(uint256 => address) public ledgerCrossChainManagers;
}

contract VaultCrossChainManagerUpgradeable is
    IVaultCrossChainManager,
    IOrderlyCrossChainReceiver,
    OwnableUpgradeable,
    UUPSUpgradeable,
    VaultCrossChainManagerDatalayout
{
    /// @notice Initializes the contract.
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function upgradeTo(address newImplementation) public override onlyOwner {
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /// @notice Sets the chain ID.
    /// @param _chainId ID of the chain.
    function setChainId(uint256 _chainId) public onlyOwner {
        chainId = _chainId;
    }

    /// @notice Sets the vault address.
    /// @param _vault Address of the new vault.
    function setVault(address _vault) public onlyOwner {
        vault = IVault(_vault);
    }

    /// @notice Sets the cross-chain relay address.
    /// @param _crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address _crossChainRelay) public onlyOwner {
        crossChainRelay = IOrderlyCrossChain(_crossChainRelay);
    }

    /// @notice Sets the ledger chain ID.
    /// @param _chainId ID of the ledger chain.
    function setLedgerCrossChainManager(uint256 _chainId, address _ledgerCrossChainManager) public onlyOwner {
        ledgerChainId = _chainId;
        ledgerCrossChainManagers[_chainId] = _ledgerCrossChainManager;
    }

    /// @notice receive message from relay, relay will call this function to send messages
    /// @param message message
    /// @param payload payload
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload)
        external
        override
    {
        require(msg.sender == address(crossChainRelay), "VaultCrossChainManager: only crossChainRelay can call");
        require(message.dstChainId == chainId, "VaultCrossChainManager: dstChainId not match");

        EventTypes.WithdrawData memory data = abi.decode(payload, (EventTypes.WithdrawData));

        // if token is CrossChainManagerTest
        if (keccak256(bytes(data.tokenSymbol)) == keccak256(bytes("CrossChainManagerTest"))) {
            _sendTestWithdrawBack();
        } else {
            VaultTypes.VaultWithdraw memory withdrawData = VaultTypes.VaultWithdraw({
                accountId: data.accountId,
                sender: data.sender,
                receiver: data.receiver,
                brokerHash: Utils.getBrokerHash(data.brokerId),
                tokenHash: Utils.getTokenHash(data.tokenSymbol),
                tokenAmount: data.tokenAmount,
                fee: data.fee,
                withdrawNonce: data.withdrawNonce
            });
            _sendWithdrawToVault(withdrawData);
        }
    }

    /// @notice Triggers a withdrawal from the ledger.
    /// @param data Struct containing withdrawal data.
    function _sendWithdrawToVault(VaultTypes.VaultWithdraw memory data) internal {
        vault.withdraw(data);
    }

    /// @notice Fetches the deposit fee based on deposit data.
    /// @param data Struct containing deposit data.
    function getDepositFee(VaultTypes.VaultDeposit memory data) public view override returns (uint256) {
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        bytes memory payload = abi.encode(data);

        return crossChainRelay.estimateGasFee(message, payload);
    }

    /// @notice Initiates a deposit to the vault.
    /// @param data Struct containing deposit data.
    function deposit(VaultTypes.VaultDeposit memory data) external override {
        require(msg.sender == address(vault), "only vault can call deposit");
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice Initiates a deposit to the vault along with native fees.
    /// @param data Struct containing deposit data.
    /// @param amount Amount of native fee.
    function depositWithFee(VaultTypes.VaultDeposit memory data, uint256 amount) external payable override {
        require(msg.sender == address(vault), "only vault can call depositWithFee");
        require(msg.value >= amount, "not enough fee");
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.Deposit),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultDeposit),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessageWithFee{value: amount}(message, payload, amount);
    }

    /// @notice Approves a cross-chain withdrawal from the ledger to the vault.
    /// @param data Struct containing withdrawal data.
    function withdraw(VaultTypes.VaultWithdraw memory data) external override {
        require(msg.sender == address(vault), "only vault can call withdraw");
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.WithdrawFinish),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice send test withdraw back
    function _sendTestWithdrawBack() internal {
        VaultTypes.VaultWithdraw memory data = VaultTypes.VaultWithdraw({
            accountId: bytes32(0),
            sender: address(0),
            receiver: address(0),
            brokerHash: bytes32(0),
            tokenHash: Utils.getTokenHash("CrossChainManagerTest"),
            tokenAmount: 0,
            fee: 0,
            withdrawNonce: 0
        });
        OrderlyCrossChainMessage.MessageV1 memory message = OrderlyCrossChainMessage.MessageV1({
            method: uint8(OrderlyCrossChainMessage.CrossChainMethod.WithdrawFinish),
            option: uint8(OrderlyCrossChainMessage.CrossChainOption.LayerZero),
            payloadDataType: uint8(OrderlyCrossChainMessage.PayloadDataType.VaultTypesVaultWithdraw),
            srcCrossChainManager: address(this),
            dstCrossChainManager: ledgerCrossChainManagers[ledgerChainId],
            srcChainId: chainId,
            dstChainId: ledgerChainId
        });
        // encode message
        bytes memory payload = abi.encode(data);

        crossChainRelay.sendMessage(message, payload);
    }

    /// @notice get version
    function getVersion() external pure returns (string memory) {
        return "0.0.1";
    }

    /// @notice get role
    function getRole() external pure returns (string memory) {
        return "vault";
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "./../library/types/VaultTypes.sol";

interface IVault {
    error OnlyCrossChainManagerCanCall();
    error AccountIdInvalid();
    error TokenNotAllowed();
    error BrokerNotAllowed();
    error BalanceNotEnough(uint256 balance, uint128 amount);
    error AddressZero();
    error EnumerableSetError();

    event AccountDeposit(
        bytes32 indexed accountId,
        address indexed userAddress,
        uint64 indexed depositNonce,
        bytes32 tokenHash,
        uint128 tokenAmount
    );

    event AccountDepositTo(
        bytes32 indexed accountId,
        address indexed userAddress,
        uint64 indexed depositNonce,
        bytes32 tokenHash,
        uint128 tokenAmount
    );

    event AccountWithdraw(
        bytes32 indexed accountId,
        uint64 indexed withdrawNonce,
        bytes32 brokerHash,
        address sender,
        address receiver,
        bytes32 tokenHash,
        uint128 tokenAmount,
        uint128 fee,
        uint256 blocktime
    );

    event SetAllowedToken(bytes32 indexed _tokenHash, bool _allowed);
    event SetAllowedBroker(bytes32 indexed _brokerHash, bool _allowed);
    event ChangeTokenAddressAndAllow(bytes32 indexed _tokenHash, address _tokenAddress);
    event ChangeCrossChainManager(address oldAddress, address newAddress);

    function initialize() external;

    function deposit(VaultTypes.VaultDepositFE calldata data) external;
    function depositTo(address receiver, VaultTypes.VaultDepositFE calldata data) external;
    function withdraw(VaultTypes.VaultWithdraw calldata data) external;

    // admin call
    function setCrossChainManager(address _crossChainManagerAddress) external;
    function emergencyPause() external;
    function emergencyUnpause() external;

    // whitelist
    function setAllowedToken(bytes32 _tokenHash, bool _allowed) external;
    function setAllowedBroker(bytes32 _brokerHash, bool _allowed) external;
    function changeTokenAddressAndAllow(bytes32 _tokenHash, address _tokenAddress) external;
    function getAllowedToken(bytes32 _tokenHash) external view returns (address);
    function getAllowedBroker(bytes32 _brokerHash) external view returns (bool);
    function getAllAllowedToken() external view returns (bytes32[] memory);
    function getAllAllowedBroker() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

/// @title VaultTypes library
/// @author Orderly_Rubick
library VaultTypes {
    struct VaultDepositFE {
        bytes32 accountId;
        bytes32 brokerHash;
        bytes32 tokenHash;
        uint128 tokenAmount;
    }

    struct VaultDeposit {
        bytes32 accountId;
        address userAddress;
        bytes32 brokerHash;
        bytes32 tokenHash;
        uint128 tokenAmount;
        uint64 depositNonce; // deposit nonce
    }

    struct VaultWithdraw {
        bytes32 accountId;
        bytes32 brokerHash;
        bytes32 tokenHash;
        uint128 tokenAmount;
        uint128 fee;
        address sender;
        address receiver;
        uint64 withdrawNonce; // withdraw nonce
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

/// @title EventTypes library
/// @author Orderly_Rubick
library EventTypes {
    // EventUpload
    struct EventUpload {
        EventUploadData[] events;
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 count;
        uint64 batchId;
    }

    struct EventUploadData {
        uint8 bizType; // 1 - withdraw, 2 - settlement, 3 - adl, 4 - liquidation
        uint64 eventId;
        bytes data;
    }

    // WithdrawData
    struct WithdrawData {
        uint128 tokenAmount;
        uint128 fee;
        uint256 chainId; // target withdraw chain
        bytes32 accountId;
        bytes32 r; // String to bytes32, big endian?
        bytes32 s;
        uint8 v;
        address sender;
        uint64 withdrawNonce;
        address receiver;
        uint64 timestamp;
        string brokerId; // only this field is string, others should be bytes32 hashedBrokerId
        string tokenSymbol; // only this field is string, others should be bytes32 hashedTokenSymbol
    }

    struct Settlement {
        bytes32 accountId;
        bytes32 settledAssetHash;
        bytes32 insuranceAccountId;
        int128 settledAmount;
        uint128 insuranceTransferAmount;
        uint64 timestamp;
        SettlementExecution[] settlementExecutions;
    }

    struct SettlementExecution {
        bytes32 symbolHash;
        uint128 markPrice;
        int128 sumUnitaryFundings;
        int128 settledAmount;
    }

    struct Adl {
        bytes32 accountId;
        bytes32 insuranceAccountId;
        bytes32 symbolHash;
        int128 positionQtyTransfer;
        int128 costPositionTransfer;
        uint128 adlPrice;
        int128 sumUnitaryFundings;
        uint64 timestamp;
    }

    struct Liquidation {
        bytes32 liquidatedAccountId;
        bytes32 insuranceAccountId;
        bytes32 liquidatedAssetHash;
        uint128 insuranceTransferAmount;
        uint64 timestamp;
        LiquidationTransfer[] liquidationTransfers;
    }

    struct LiquidationTransfer {
        bytes32 liquidatorAccountId;
        bytes32 symbolHash;
        int128 positionQtyTransfer;
        int128 costPositionTransfer;
        int128 liquidatorFee;
        int128 insuranceFee;
        int128 liquidationFee;
        uint128 markPrice;
        int128 sumUnitaryFundings;
        uint64 liquidationTransferId;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

/// @title Utils library
/// @author Orderly_Rubick
library Utils {
    function getAccoundId(address _userAddr, string memory _brokerId) internal pure returns (bytes32) {
        return keccak256(abi.encode(_userAddr, keccak256(abi.encodePacked(_brokerId))));
    }

    function getBrokerHash(string memory _brokerId) internal pure returns (bytes32) {
        return calculateStringHash(_brokerId);
    }

    function getTokenHash(string memory _tokenSymbol) internal pure returns (bytes32) {
        return calculateStringHash(_tokenSymbol);
    }

    function calculateStringHash(string memory _str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_str));
    }

    function validateAccountId(bytes32 _accountId, bytes32 _brokerHash, address _userAddress)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encode(_userAddress, _brokerHash)) == _accountId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
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
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
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
pragma solidity ^0.8.18;

// Importing necessary utility libraries and types
import "../utils/OrderlyCrossChainMessage.sol";
import "contract-evm/src/library/types/AccountTypes.sol";
import "contract-evm/src/library/types/VaultTypes.sol";

/// @title IVaultCrossChainManager Interface
/// @notice Interface for managing cross-chain activities related to the vault.
interface IVaultCrossChainManager {
    /// @notice Triggers a withdrawal from the ledger.
    /// @param _withdraw Struct containing withdrawal data.
    function withdraw(VaultTypes.VaultWithdraw memory _withdraw) external;

    /// @notice Initiates a deposit to the vault.
    /// @param _data Struct containing deposit data.
    function deposit(VaultTypes.VaultDeposit memory _data) external;

    /// @notice Initiates a deposit to the vault along with native fees.
    /// @param _data Struct containing deposit data.
    /// @param _amount Amount of native fee.
    function depositWithFee(VaultTypes.VaultDeposit memory _data, uint256 _amount) external payable;

    /// @notice Fetches the deposit fee based on deposit data.
    /// @param _data Struct containing deposit data.
    /// @return fee The calculated deposit fee.
    function getDepositFee(VaultTypes.VaultDeposit memory _data) external view returns (uint256);

    /// @notice Sets the vault address.
    /// @param _vault Address of the new vault.
    function setVault(address _vault) external;

    /// @notice Sets the cross-chain relay address.
    /// @param _crossChainRelay Address of the new cross-chain relay.
    function setCrossChainRelay(address _crossChainRelay) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../utils/OrderlyCrossChainMessage.sol";

// Interface for the Cross Chain Operations
interface IOrderlyCrossChain {
    // Event to be emitted when a message is sent
    event MessageSent(OrderlyCrossChainMessage.MessageV1 message, bytes payload);

    // Event to be emitted when a message is received
    event MessageReceived(OrderlyCrossChainMessage.MessageV1 message, bytes payload);

    /// @notice estimate gas fee
    /// @param data message data
    /// @param payload payload
    function estimateGasFee(OrderlyCrossChainMessage.MessageV1 memory data, bytes memory payload)
        external
        view
        returns (uint256);

    /// @notice send message
    /// @param message message
    /// @param payload payload
    function sendMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external payable;

    /// @notice send message with fee, so no estimate gas fee will not run
    /// @param message message
    /// @param payload payload
    function sendMessageWithFee(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload, uint256 amount)
        external
        payable;

    /// @notice receive message after decoding the message
    /// @param message message
    /// @param payload payload
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external payable;
}

// Interface for the Cross Chain Receiver
interface IOrderlyCrossChainReceiver {
    /// @notice receive message from relay, relay will call this function to send messages
    /// @param message message
    /// @param payload payload
    function receiveMessage(OrderlyCrossChainMessage.MessageV1 memory message, bytes memory payload) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Library to handle the conversion of the message structure to bytes array and vice versa
library OrderlyCrossChainMessage {
    // List of methods that can be called cross-chain
    enum CrossChainOption {LayerZero}

    enum CrossChainMethod {
        Deposit, // from vault to ledger
        Withdraw, // from ledger to vault
        WithdrawFinish, // from vault to ledger
        Ping, // for message testing
        PingPong // ABA message testing
    }

    enum PayloadDataType {
        EventTypesWithdrawData,
        AccountTypesAccountDeposit,
        AccountTypesAccountWithdraw,
        VaultTypesVaultDeposit,
        VaultTypesVaultWithdraw
    }

    // The structure of the message
    struct MessageV1 {
        uint8 method; // enum CrossChainMethod to uint8
        uint8 option; // enum CrossChainOption to uint8
        uint8 payloadDataType; // enum PayloadDataType to uint8
        address srcCrossChainManager; // Source cross-chain manager address
        address dstCrossChainManager; // Target cross-chain manager address
        uint256 srcChainId; // Source blockchain ID
        uint256 dstChainId; // Target blockchain ID
    }

    // Encode the message structure to bytes array
    function encodeMessageV1AndPayload(MessageV1 memory message, bytes memory payload)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(message, payload);
    }

    // Decode the bytes array to message structure
    function decodeMessageV1AndPayload(bytes memory data) internal pure returns (MessageV1 memory, bytes memory) {
        (MessageV1 memory message, bytes memory payload) = abi.decode(data, (MessageV1, bytes));
        return (message, payload);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/IERC1967Upgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable, IERC1967Upgradeable {
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
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
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
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            AddressUpgradeable.functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

/// @title AccountTypes library
/// @author Orderly_Rubick
library AccountTypes {
    struct PerpPosition {
        int128 positionQty;
        int128 costPosition;
        int128 lastSumUnitaryFundings;
        uint128 lastExecutedPrice;
        uint128 lastSettledPrice;
        uint128 averageEntryPrice;
        int128 openingCost;
        uint128 lastAdlPrice;
    }

    // account id, unique for each account, should be accountId -> {addr, brokerId}
    // and keccak256(addr, brokerID) == accountId
    struct Account {
        // user's broker id
        bytes32 brokerHash;
        // primary address
        address userAddress;
        // mapping symbol => balance
        mapping(bytes32 => uint128) balances;
        // mapping symbol => totalFrozenBalance
        mapping(bytes32 => uint128) totalFrozenBalances;
        // mapping withdrawNonce => symbol => balance
        mapping(uint64 => mapping(bytes32 => uint128)) frozenBalances;
        // perp position
        mapping(bytes32 => PerpPosition) perpPositions;
        // lastwithdraw nonce
        uint64 lastWithdrawNonce;
        // last perp trade id
        uint64 lastPerpTradeId;
        // last cefi event id
        uint64 lastCefiEventId;
        // last deposit event id
        uint64 lastDepositEventId;
    }

    struct AccountDeposit {
        bytes32 accountId;
        bytes32 brokerHash;
        address userAddress;
        bytes32 tokenHash;
        uint256 srcChainId;
        uint128 tokenAmount;
        uint64 srcChainDepositNonce;
    }

    // for accountWithdrawFinish
    struct AccountWithdraw {
        bytes32 accountId;
        address sender;
        address receiver;
        bytes32 brokerHash;
        bytes32 tokenHash;
        uint128 tokenAmount;
        uint128 fee;
        uint256 chainId;
        uint64 withdrawNonce;
    }

    struct AccountTokenBalances {
        // token hash
        bytes32 tokenHash;
        // balance & frozenBalance
        uint128 balance;
        uint128 frozenBalance;
    }

    struct AccountPerpPositions {
        // symbol hash
        bytes32 symbolHash;
        // perp position
        int128 positionQty;
        int128 costPosition;
        int128 lastSumUnitaryFundings;
        uint128 lastExecutedPrice;
        uint128 lastSettledPrice;
        uint128 averageEntryPrice;
        int128 openingCost;
        uint128 lastAdlPrice;
    }

    // for batch get
    struct AccountSnapshot {
        bytes32 accountId;
        bytes32 brokerHash;
        address userAddress;
        uint64 lastWithdrawNonce;
        uint64 lastPerpTradeId;
        uint64 lastCefiEventId;
        uint64 lastDepositEventId;
        AccountTokenBalances[] tokenBalances;
        AccountPerpPositions[] perpPositions;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967Upgradeable {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

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
 * ```solidity
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
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
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

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
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

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}