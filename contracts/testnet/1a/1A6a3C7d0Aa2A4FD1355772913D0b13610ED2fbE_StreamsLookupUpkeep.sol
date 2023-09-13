// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract ExecutionPrevention {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice OnchainConfig of the registry
 * @dev only used in params and return values
 * @member paymentPremiumPPB payment premium rate oracles receive on top of
 * being reimbursed for gas, measured in parts per billion
 * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
 * priced in MicroLink; can be used in conjunction with or independently of
 * paymentPremiumPPB
 * @member checkGasLimit gas limit when checking for upkeep
 * @member stalenessSeconds number of seconds that is allowed for feed data to
 * be stale before switching to the fallback pricing
 * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
 * when calculating the payment ceiling for keepers
 * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
 * @member maxPerformGas max executeGas allowed for an upkeep on this registry
 * @member fallbackGasPrice gas price used if the gas price feed is stale
 * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
 * @member transcoder address of the transcoder contract
 * @member registrar address of the registrar contract
 */
struct OnchainConfig {
  uint32 paymentPremiumPPB;
  uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
  uint32 checkGasLimit;
  uint24 stalenessSeconds;
  uint16 gasCeilingMultiplier;
  uint96 minUpkeepSpend;
  uint32 maxPerformGas;
  uint32 maxCheckDataSize;
  uint32 maxPerformDataSize;
  uint256 fallbackGasPrice;
  uint256 fallbackLinkPrice;
  address transcoder;
  address registrar;
}

/**
 * @notice state of the registry
 * @dev only used in params and return values
 * @member nonce used for ID generation
 * @member ownerLinkBalance withdrawable balance of LINK by contract owner
 * @member expectedLinkBalance the expected balance of LINK of the registry
 * @member totalPremium the total premium collected on registry so far
 * @member numUpkeeps total number of upkeeps on the registry
 * @member configCount ordinal number of current config, out of all configs applied to this contract so far
 * @member latestConfigBlockNumber last block at which this config was set
 * @member latestConfigDigest domain-separation tag for current config
 * @member latestEpoch for which a report was transmitted
 * @member paused freeze on execution scoped to the entire registry
 */
struct State {
  uint32 nonce;
  uint96 ownerLinkBalance;
  uint256 expectedLinkBalance;
  uint96 totalPremium;
  uint256 numUpkeeps;
  uint32 configCount;
  uint32 latestConfigBlockNumber;
  bytes32 latestConfigDigest;
  uint32 latestEpoch;
  bool paused;
}

/**
 * @notice all information about an upkeep
 * @dev only used in return values
 * @member target the contract which needs to be serviced
 * @member executeGas the gas limit of upkeep execution
 * @member checkData the checkData bytes for this upkeep
 * @member balance the balance of this upkeep
 * @member admin for this upkeep
 * @member maxValidBlocknumber until which block this upkeep is valid
 * @member lastPerformBlockNumber the last block number when this upkeep was performed
 * @member amountSpent the amount this upkeep has spent
 * @member paused if this upkeep has been paused
 * @member skipSigVerification skip signature verification in transmit for a low security low cost model
 */
struct UpkeepInfo {
  address target;
  uint32 executeGas;
  bytes checkData;
  uint96 balance;
  address admin;
  uint64 maxValidBlocknumber;
  uint32 lastPerformBlockNumber;
  uint96 amountSpent;
  bool paused;
  bytes offchainConfig;
}

enum UpkeepFailureReason {
  NONE,
  UPKEEP_CANCELLED,
  UPKEEP_PAUSED,
  TARGET_CHECK_REVERTED,
  UPKEEP_NOT_NEEDED,
  PERFORM_DATA_EXCEEDS_LIMIT,
  INSUFFICIENT_BALANCE
}

interface AutomationRegistryBaseInterface {
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function updateCheckData(uint256 id, bytes calldata newCheckData) external;

  function addFunds(uint256 id, uint96 amount) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external;

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getTransmitterInfo(
    address query
  ) external view returns (bool active, uint8 index, uint96 balance, uint96 lastCollected, address payee);

  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );
}

/**
 * @dev The view methods are not actually marked as view in the implementation
 * but we want them to be easily queried off-chain. Solidity will not compile
 * if we actually inherit from this interface, so we document it here.
 */
interface AutomationRegistryInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId
  )
    external
    view
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

interface AutomationRegistryExecutableInterface is AutomationRegistryBaseInterface {
  function checkUpkeep(
    uint256 upkeepId
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 fastGasWei,
      uint256 linkNative
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../UpkeepFormat.sol";

interface MigratableKeeperRegistryInterfaceV2 {
  /**
   * @notice Migrates upkeeps from one registry to another, including LINK and upkeep params.
   * Only callable by the upkeep admin. All upkeeps must have the same admin. Can only migrate active upkeeps.
   * @param upkeepIDs ids of upkeeps to migrate
   * @param destination the address of the registry to migrate to
   */
  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  /**
   * @notice Called by other registries when migrating upkeeps. Only callable by other registries.
   * @param encodedUpkeeps abi encoding of upkeeps to import - decoded by the transcoder
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external;

  /**
   * @notice Specifies the version of upkeep data that this registry requires in order to import
   */
  function upkeepVersion() external view returns (uint8 version);
}

// SPDX-License-Identifier: MIT

import "../UpkeepFormat.sol";

pragma solidity ^0.8.0;

interface UpkeepTranscoderInterface {
  function transcodeUpkeeps(
    UpkeepFormat fromVersion,
    UpkeepFormat toVersion,
    bytes calldata encodedUpkeeps
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface UpkeepTranscoderInterfaceV2 {
  function transcodeUpkeeps(
    uint8 fromVersion,
    uint8 toVersion,
    bytes calldata encodedUpkeeps
  ) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev this struct is only maintained for backwards compatibility with MigratableKeeperRegistryInterface
 * it should be deprecated in the future in favor of MigratableKeeperRegistryInterfaceV2
 */
enum UpkeepFormat {
  V1,
  V2,
  V3
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IAutomationRegistryConsumer} from "./interfaces/IAutomationRegistryConsumer.sol";

uint256 constant PERFORM_GAS_CUSHION = 5_000;

/**
 * @title AutomationForwarder is a relayer that sits between the registry and the customer's target contract
 * @dev The purpose of the forwarder is to give customers a consistent address to authorize against,
 * which stays consistent between migrations. The Forwarder also exposes the registry address, so that users who
 * want to programatically interact with the registry (ie top up funds) can do so.
 */
contract AutomationForwarder {
  /// @notice the user's target contract address
  address private immutable i_target;

  /// @notice the shared logic address
  address private immutable i_logic;

  IAutomationRegistryConsumer private s_registry;

  constructor(address target, address registry, address logic) {
    s_registry = IAutomationRegistryConsumer(registry);
    i_target = target;
    i_logic = logic;
  }

  /**
   * @notice forward is called by the registry and forwards the call to the target
   * @param gasAmount is the amount of gas to use in the call
   * @param data is the 4 bytes function selector + arbitrary function data
   * @return success indicating whether the target call succeeded or failed
   */
  function forward(uint256 gasAmount, bytes memory data) external returns (bool success, uint256 gasUsed) {
    if (msg.sender != address(s_registry)) revert();
    address target = i_target;
    gasUsed = gasleft();
    assembly {
      let g := gas()
      // Compute g -= PERFORM_GAS_CUSHION and check for underflow
      if lt(g, PERFORM_GAS_CUSHION) {
        revert(0, 0)
      }
      g := sub(g, PERFORM_GAS_CUSHION)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call with exact gas
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    gasUsed = gasUsed - gasleft();
    return (success, gasUsed);
  }

  function getTarget() external view returns (address) {
    return i_target;
  }

  fallback() external {
    // copy to memory for assembly access
    address logic = i_logic;
    // copied directly from OZ's Proxy contract
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), logic, 0, calldatasize(), 0, 0)

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IAutomationRegistryConsumer} from "./interfaces/IAutomationRegistryConsumer.sol";
import {ITypeAndVersion} from "../../../shared/interfaces/ITypeAndVersion.sol";

contract AutomationForwarderLogic is ITypeAndVersion {
  IAutomationRegistryConsumer private s_registry;

  string public constant typeAndVersion = "AutomationForwarder 1.0.0";

  /**
   * @notice updateRegistry is called by the registry during migrations
   * @param newRegistry is the registry that this forwarder is being migrated to
   */
  function updateRegistry(address newRegistry) external {
    if (msg.sender != address(s_registry)) revert();
    s_registry = IAutomationRegistryConsumer(newRegistry);
  }

  function getRegistry() external view returns (IAutomationRegistryConsumer) {
    return s_registry;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LinkTokenInterface} from "../../../shared/interfaces/LinkTokenInterface.sol";
import {IKeeperRegistryMaster} from "./interfaces/IKeeperRegistryMaster.sol";
import {TypeAndVersionInterface} from "../../../interfaces/TypeAndVersionInterface.sol";
import {ConfirmedOwner} from "../../../shared/access/ConfirmedOwner.sol";
import {IERC677Receiver} from "../../../shared/interfaces/IERC677Receiver.sol";

/**
 * @notice Contract to accept requests for upkeep registrations
 * @dev There are 2 registration workflows in this contract
 * Flow 1. auto approve OFF / manual registration - UI calls `register` function on this contract, this contract owner at a later time then manually
 *  calls `approve` to register upkeep and emit events to inform UI and others interested.
 * Flow 2. auto approve ON / real time registration - UI calls `register` function as before, which calls the `registerUpkeep` function directly on
 *  keeper registry and then emits approved event to finish the flow automatically without manual intervention.
 * The idea is to have same interface(functions,events) for UI or anyone using this contract irrespective of auto approve being enabled or not.
 * they can just listen to `RegistrationRequested` & `RegistrationApproved` events and know the status on registrations.
 */
contract AutomationRegistrar2_1 is TypeAndVersionInterface, ConfirmedOwner, IERC677Receiver {
  /**
   * DISABLED: No auto approvals, all new upkeeps should be approved manually.
   * ENABLED_SENDER_ALLOWLIST: Auto approvals for allowed senders subject to max allowed. Manual for rest.
   * ENABLED_ALL: Auto approvals for all new upkeeps subject to max allowed.
   */
  enum AutoApproveType {
    DISABLED,
    ENABLED_SENDER_ALLOWLIST,
    ENABLED_ALL
  }

  bytes4 private constant REGISTER_REQUEST_SELECTOR = this.register.selector;

  mapping(bytes32 => PendingRequest) private s_pendingRequests;
  mapping(uint8 => TriggerRegistrationStorage) private s_triggerRegistrations;

  LinkTokenInterface public immutable LINK;

  /**
   * @notice versions:
   * - KeeperRegistrar 2.1.0: Update for compatability with registry 2.1.0
   *                          Add auto approval levels by type
   * - KeeperRegistrar 2.0.0: Remove source from register
   *                          Breaks our example of "Register an Upkeep using your own deployed contract"
   * - KeeperRegistrar 1.1.0: Add functionality for sender allowlist in auto approve
   *                        : Remove rate limit and add max allowed for auto approve
   * - KeeperRegistrar 1.0.0: initial release
   */
  string public constant override typeAndVersion = "AutomationRegistrar 2.1.0";

  /**
   * @notice TriggerRegistrationStorage stores the auto-approval levels for upkeeps by type
   * @member autoApproveType the auto approval setting (see enum)
   * @member autoApproveMaxAllowed the max number of upkeeps that can be auto approved of this type
   * @member approvedCount the count of upkeeps auto approved of this type
   */
  struct TriggerRegistrationStorage {
    AutoApproveType autoApproveType;
    uint32 autoApproveMaxAllowed;
    uint32 approvedCount;
  }

  /**
   * @notice InitialTriggerConfig configures the auto-approval levels for upkeeps by trigger type
   * @dev this struct is only used in the constructor to set the initial values for various trigger configs
   * @member triggerType the upkeep type to configure
   * @member autoApproveType the auto approval setting (see enum)
   * @member autoApproveMaxAllowed the max number of upkeeps that can be auto approved of this type
   */
  struct InitialTriggerConfig {
    uint8 triggerType;
    AutoApproveType autoApproveType;
    uint32 autoApproveMaxAllowed;
  }

  struct RegistrarConfig {
    IKeeperRegistryMaster keeperRegistry;
    uint96 minLINKJuels;
  }

  struct PendingRequest {
    address admin;
    uint96 balance;
  }

  struct RegistrationParams {
    string name;
    bytes encryptedEmail;
    address upkeepContract;
    uint32 gasLimit;
    address adminAddress;
    uint8 triggerType;
    bytes checkData;
    bytes triggerConfig;
    bytes offchainConfig;
    uint96 amount;
  }

  RegistrarConfig private s_config;
  // Only applicable if s_config.configType is ENABLED_SENDER_ALLOWLIST
  mapping(address => bool) private s_autoApproveAllowedSenders;

  event RegistrationRequested(
    bytes32 indexed hash,
    string name,
    bytes encryptedEmail,
    address indexed upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    uint8 triggerType,
    bytes triggerConfig,
    bytes offchainConfig,
    bytes checkData,
    uint96 amount
  );

  event RegistrationApproved(bytes32 indexed hash, string displayName, uint256 indexed upkeepId);

  event RegistrationRejected(bytes32 indexed hash);

  event AutoApproveAllowedSenderSet(address indexed senderAddress, bool allowed);

  event ConfigChanged(address keeperRegistry, uint96 minLINKJuels);

  event TriggerConfigSet(uint8 triggerType, AutoApproveType autoApproveType, uint32 autoApproveMaxAllowed);

  error InvalidAdminAddress();
  error RequestNotFound();
  error HashMismatch();
  error OnlyAdminOrOwner();
  error InsufficientPayment();
  error RegistrationRequestFailed();
  error OnlyLink();
  error AmountMismatch();
  error SenderMismatch();
  error FunctionNotPermitted();
  error LinkTransferFailed(address to);
  error InvalidDataLength();

  /**
   * @param LINKAddress Address of Link token
   * @param keeperRegistry keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   * @param triggerConfigs the initial config for individual triggers
   */
  constructor(
    address LINKAddress,
    address keeperRegistry,
    uint96 minLINKJuels,
    InitialTriggerConfig[] memory triggerConfigs
  ) ConfirmedOwner(msg.sender) {
    LINK = LinkTokenInterface(LINKAddress);
    setConfig(keeperRegistry, minLINKJuels);
    for (uint256 idx = 0; idx < triggerConfigs.length; idx++) {
      setTriggerConfig(
        triggerConfigs[idx].triggerType,
        triggerConfigs[idx].autoApproveType,
        triggerConfigs[idx].autoApproveMaxAllowed
      );
    }
  }

  //EXTERNAL

  /**
   * @notice register can only be called through transferAndCall on LINK contract
   * @param name string of the upkeep to be registered
   * @param encryptedEmail email address of upkeep contact
   * @param upkeepContract address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when performing upkeep
   * @param adminAddress address to cancel upkeep and withdraw remaining funds
   * @param triggerType the type of trigger for the upkeep
   * @param checkData data passed to the contract when checking for upkeep
   * @param triggerConfig the config for the trigger
   * @param offchainConfig offchainConfig for upkeep in bytes
   * @param amount quantity of LINK upkeep is funded with (specified in Juels)
   * @param sender address of the sender making the request
   */
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    uint8 triggerType,
    bytes memory checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig,
    uint96 amount,
    address sender
  ) external onlyLINK {
    _register(
      RegistrationParams({
        name: name,
        encryptedEmail: encryptedEmail,
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        triggerType: triggerType,
        checkData: checkData,
        triggerConfig: triggerConfig,
        offchainConfig: offchainConfig,
        amount: amount
      }),
      sender
    );
  }

  /**
   * @notice Allows external users to register upkeeps; assumes amount is approved for transfer by the contract
   * @param requestParams struct of all possible registration parameters
   */
  function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256) {
    if (requestParams.amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }

    LINK.transferFrom(msg.sender, address(this), requestParams.amount);

    return _register(requestParams, msg.sender);
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function approve(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    uint8 triggerType,
    bytes calldata checkData,
    bytes memory triggerConfig,
    bytes calldata offchainConfig,
    bytes32 hash
  ) external onlyOwner {
    PendingRequest memory request = s_pendingRequests[hash];
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    bytes32 expectedHash = keccak256(
      abi.encode(upkeepContract, gasLimit, adminAddress, triggerType, checkData, triggerConfig, offchainConfig)
    );
    if (hash != expectedHash) {
      revert HashMismatch();
    }
    delete s_pendingRequests[hash];
    _approve(
      RegistrationParams({
        name: name,
        encryptedEmail: "",
        upkeepContract: upkeepContract,
        gasLimit: gasLimit,
        adminAddress: adminAddress,
        triggerType: triggerType,
        checkData: checkData,
        triggerConfig: triggerConfig,
        offchainConfig: offchainConfig,
        amount: request.balance
      }),
      expectedHash
    );
  }

  /**
   * @notice cancel will remove a registration request and return the refunds to the request.admin
   * @param hash the request hash
   */
  function cancel(bytes32 hash) external {
    PendingRequest memory request = s_pendingRequests[hash];
    if (!(msg.sender == request.admin || msg.sender == owner())) {
      revert OnlyAdminOrOwner();
    }
    if (request.admin == address(0)) {
      revert RequestNotFound();
    }
    delete s_pendingRequests[hash];
    bool success = LINK.transfer(request.admin, request.balance);
    if (!success) {
      revert LinkTransferFailed(request.admin);
    }
    emit RegistrationRejected(hash);
  }

  /**
   * @notice owner calls this function to set contract config
   * @param keeperRegistry new keeper registry address
   * @param minLINKJuels minimum LINK that new registrations should fund their upkeep with
   */
  function setConfig(address keeperRegistry, uint96 minLINKJuels) public onlyOwner {
    s_config = RegistrarConfig({minLINKJuels: minLINKJuels, keeperRegistry: IKeeperRegistryMaster(keeperRegistry)});
    emit ConfigChanged(keeperRegistry, minLINKJuels);
  }

  /**
   * @notice owner calls to set the config for this upkeep type
   * @param triggerType the upkeep type to configure
   * @param autoApproveType the auto approval setting (see enum)
   * @param autoApproveMaxAllowed the max number of upkeeps that can be auto approved of this type
   */
  function setTriggerConfig(
    uint8 triggerType,
    AutoApproveType autoApproveType,
    uint32 autoApproveMaxAllowed
  ) public onlyOwner {
    s_triggerRegistrations[triggerType].autoApproveType = autoApproveType;
    s_triggerRegistrations[triggerType].autoApproveMaxAllowed = autoApproveMaxAllowed;
    emit TriggerConfigSet(triggerType, autoApproveType, autoApproveMaxAllowed);
  }

  /**
   * @notice owner calls this function to set allowlist status for senderAddress
   * @param senderAddress senderAddress to set the allowlist status for
   * @param allowed true if senderAddress needs to be added to allowlist, false if needs to be removed
   */
  function setAutoApproveAllowedSender(address senderAddress, bool allowed) external onlyOwner {
    s_autoApproveAllowedSenders[senderAddress] = allowed;

    emit AutoApproveAllowedSenderSet(senderAddress, allowed);
  }

  /**
   * @notice read the allowlist status of senderAddress
   * @param senderAddress address to read the allowlist status for
   */
  function getAutoApproveAllowedSender(address senderAddress) external view returns (bool) {
    return s_autoApproveAllowedSenders[senderAddress];
  }

  /**
   * @notice read the current registration configuration
   */
  function getConfig() external view returns (address keeperRegistry, uint256 minLINKJuels) {
    RegistrarConfig memory config = s_config;
    return (address(config.keeperRegistry), config.minLINKJuels);
  }

  /**
   * @notice read the config for this upkeep type
   * @param triggerType upkeep type to read config for
   */
  function getTriggerRegistrationDetails(uint8 triggerType) external view returns (TriggerRegistrationStorage memory) {
    return s_triggerRegistrations[triggerType];
  }

  /**
   * @notice gets the admin address and the current balance of a registration request
   */
  function getPendingRequest(bytes32 hash) external view returns (address, uint96) {
    PendingRequest memory request = s_pendingRequests[hash];
    return (request.admin, request.balance);
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param sender Address of the sender transfering LINK
   * @param amount Amount of LINK sent (specified in Juels)
   * @param data Payload of the transaction
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes calldata data
  )
    external
    override
    onlyLINK
    permittedFunctionsForLINK(data)
    isActualAmount(amount, data)
    isActualSender(sender, data)
  {
    if (amount < s_config.minLINKJuels) {
      revert InsufficientPayment();
    }
    (bool success, ) = address(this).delegatecall(data);
    // calls register
    if (!success) {
      revert RegistrationRequestFailed();
    }
  }

  // ================================================================
  // |                           PRIVATE                            |
  // ================================================================

  /**
   * @dev verify registration request and emit RegistrationRequested event
   */
  function _register(RegistrationParams memory params, address sender) private returns (uint256) {
    if (params.adminAddress == address(0)) {
      revert InvalidAdminAddress();
    }
    bytes32 hash = keccak256(
      abi.encode(
        params.upkeepContract,
        params.gasLimit,
        params.adminAddress,
        params.triggerType,
        params.checkData,
        params.triggerConfig,
        params.offchainConfig
      )
    );

    emit RegistrationRequested(
      hash,
      params.name,
      params.encryptedEmail,
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.triggerType,
      params.triggerConfig,
      params.offchainConfig,
      params.checkData,
      params.amount
    );

    uint256 upkeepId;
    if (_shouldAutoApprove(s_triggerRegistrations[params.triggerType], sender)) {
      s_triggerRegistrations[params.triggerType].approvedCount++;
      upkeepId = _approve(params, hash);
    } else {
      uint96 newBalance = s_pendingRequests[hash].balance + params.amount;
      s_pendingRequests[hash] = PendingRequest({admin: params.adminAddress, balance: newBalance});
    }

    return upkeepId;
  }

  /**
   * @dev register upkeep on KeeperRegistry contract and emit RegistrationApproved event
   */
  function _approve(RegistrationParams memory params, bytes32 hash) private returns (uint256) {
    IKeeperRegistryMaster keeperRegistry = s_config.keeperRegistry;
    uint256 upkeepId = keeperRegistry.registerUpkeep(
      params.upkeepContract,
      params.gasLimit,
      params.adminAddress,
      params.triggerType,
      params.checkData,
      params.triggerConfig,
      params.offchainConfig
    );
    bool success = LINK.transferAndCall(address(keeperRegistry), params.amount, abi.encode(upkeepId));
    if (!success) {
      revert LinkTransferFailed(address(keeperRegistry));
    }
    emit RegistrationApproved(hash, params.name, upkeepId);
    return upkeepId;
  }

  /**
   * @dev verify sender allowlist if needed and check max limit
   */
  function _shouldAutoApprove(TriggerRegistrationStorage memory config, address sender) private view returns (bool) {
    if (config.autoApproveType == AutoApproveType.DISABLED) {
      return false;
    }
    if (config.autoApproveType == AutoApproveType.ENABLED_SENDER_ALLOWLIST && (!s_autoApproveAllowedSenders[sender])) {
      return false;
    }
    if (config.approvedCount < config.autoApproveMaxAllowed) {
      return true;
    }
    return false;
  }

  // ================================================================
  // |                          MODIFIERS                           |
  // ================================================================

  /**
   * @dev Reverts if not sent from the LINK token
   */
  modifier onlyLINK() {
    if (msg.sender != address(LINK)) {
      revert OnlyLink();
    }
    _;
  }

  /**
   * @dev Reverts if the given data does not begin with the `register` function selector
   * @param _data The data payload of the request
   */
  modifier permittedFunctionsForLINK(bytes memory _data) {
    bytes4 funcSelector;
    assembly {
      // solhint-disable-next-line avoid-low-level-calls
      funcSelector := mload(add(_data, 32)) // First 32 bytes contain length of data
    }
    if (funcSelector != REGISTER_REQUEST_SELECTOR) {
      revert FunctionNotPermitted();
    }
    _;
  }

  /**
   * @dev Reverts if the actual amount passed does not match the expected amount
   * @param expected amount that should match the actual amount
   * @param data bytes
   */
  modifier isActualAmount(uint256 expected, bytes calldata data) {
    // decode register function arguments to get actual amount
    (, , , , , , , , , uint96 amount, ) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, uint8, bytes, bytes, bytes, uint96, address)
    );
    if (expected != amount) {
      revert AmountMismatch();
    }
    _;
  }

  /**
   * @dev Reverts if the actual sender address does not match the expected sender address
   * @param expected address that should match the actual sender address
   * @param data bytes
   */
  modifier isActualSender(address expected, bytes calldata data) {
    // decode register function arguments to get actual sender
    (, , , , , , , , , , address sender) = abi.decode(
      data[4:],
      (string, bytes, address, uint32, address, uint8, bytes, bytes, bytes, uint96, address)
    );
    if (expected != sender) {
      revert SenderMismatch();
    }
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {KeeperRegistryBase2_1} from "./KeeperRegistryBase2_1.sol";
import {ILogAutomation, Log} from "./interfaces/ILogAutomation.sol";

/**
 * @notice this file exposes structs that are otherwise internal to the automation registry
 * doing this allows those structs to be encoded and decoded with type safety in offchain code
 * and tests because generated wrappers are made available
 */

/**
 * @notice structure of trigger for log triggers
 */
struct LogTriggerConfig {
  address contractAddress;
  uint8 filterSelector; // denotes which topics apply to filter ex 000, 101, 111...only last 3 bits apply
  bytes32 topic0;
  bytes32 topic1;
  bytes32 topic2;
  bytes32 topic3;
}

contract AutomationUtils2_1 {
  /**
   * @dev this can be removed as OnchainConfig is now exposed directly from the registry
   */
  function _onChainConfig(KeeperRegistryBase2_1.OnchainConfig memory) external {} // 0x2ff92a81

  function _report(KeeperRegistryBase2_1.Report memory) external {} // 0xe65d6546

  function _logTriggerConfig(LogTriggerConfig memory) external {} // 0x21f373d7

  function _logTrigger(KeeperRegistryBase2_1.LogTrigger memory) external {} // 0x1c8d8260

  function _conditionalTrigger(KeeperRegistryBase2_1.ConditionalTrigger memory) external {} // 0x4b6df294

  function _log(Log memory) external {} // 0xe9720a49
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
 * @title Chainable - the contract size limit nullifier
 * @notice Chainable is designed to link together a "chain" of contracts through fallback functions
 * and delegatecalls. All code is executed in the context of the head of the chain, the "master" contract.
 */
contract Chainable {
  /**
   * @dev addresses of the next contract in the chain **have to be immutable/constant** or the system won't work
   */
  address private immutable FALLBACK_ADDRESS;

  /**
   * @param fallbackAddress the address of the next contract in the chain
   */
  constructor(address fallbackAddress) {
    FALLBACK_ADDRESS = fallbackAddress;
  }

  /**
   * @notice returns the address of the next contract in the chain
   */
  function fallbackTo() external view returns (address) {
    return FALLBACK_ADDRESS;
  }

  /**
   * @notice the fallback function routes the call to the next contract in the chain
   * @dev most of the implementation is copied directly from OZ's Proxy contract
   */
  fallback() external {
    // copy to memory for assembly access
    address next = FALLBACK_ADDRESS;
    // copied directly from OZ's Proxy contract
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the next contract.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), next, 0, calldatasize(), 0, 0)

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITypeAndVersion} from "../../../../shared/interfaces/ITypeAndVersion.sol";
import {IAutomationRegistryConsumer} from "./IAutomationRegistryConsumer.sol";

interface IAutomationForwarder is ITypeAndVersion {
  function forward(uint256 gasAmount, bytes memory data) external returns (bool success, uint256 gasUsed);

  function updateRegistry(address newRegistry) external;

  function getRegistry() external view returns (IAutomationRegistryConsumer);

  function getTarget() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @notice IAutomationRegistryConsumer defines the LTS user-facing interface that we intend to maintain for
 * across upgrades. As long as users use functions from within this interface, their upkeeps will retain
 * backwards compatability across migrations.
 * @dev Functions can be added to this interface, but not removed.
 */
interface IAutomationRegistryConsumer {
  function getBalance(uint256 id) external view returns (uint96 balance);

  function getMinBalance(uint256 id) external view returns (uint96 minBalance);

  function cancelUpkeep(uint256 id) external;

  function pauseUpkeep(uint256 id) external;

  function unpauseUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function withdrawFunds(uint256 id, address to) external;
}

// abi-checksum: 0x0ed34e4b36bd7b4a5447152c2d61491e6ba7ed944b11e4dfef4fea184708975e
// SPDX-License-Identifier: MIT
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IKeeperRegistryMaster {
  error ArrayHasNoEntries();
  error CannotCancel();
  error CheckDataExceedsLimit();
  error ConfigDigestMismatch();
  error DuplicateEntry();
  error DuplicateSigners();
  error GasLimitCanOnlyIncrease();
  error GasLimitOutsideRange();
  error IncorrectNumberOfFaultyOracles();
  error IncorrectNumberOfSignatures();
  error IncorrectNumberOfSigners();
  error IndexOutOfRange();
  error InsufficientFunds();
  error InvalidDataLength();
  error InvalidPayee();
  error InvalidRecipient();
  error InvalidReport();
  error InvalidSigner();
  error InvalidTransmitter();
  error InvalidTrigger();
  error InvalidTriggerType();
  error MaxCheckDataSizeCanOnlyIncrease();
  error MaxPerformDataSizeCanOnlyIncrease();
  error MigrationNotPermitted();
  error NotAContract();
  error OnlyActiveSigners();
  error OnlyActiveTransmitters();
  error OnlyCallableByAdmin();
  error OnlyCallableByLINKToken();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedAdmin();
  error OnlyCallableByProposedPayee();
  error OnlyCallableByUpkeepPrivilegeManager();
  error OnlyPausedUpkeep();
  error OnlySimulatedBackend();
  error OnlyUnpausedUpkeep();
  error ParameterLengthError();
  error PaymentGreaterThanAllLINK();
  error ReentrantCall();
  error RegistryPaused();
  error RepeatedSigner();
  error RepeatedTransmitter();
  error TargetCheckReverted(bytes reason);
  error TooManyOracles();
  error TranscoderNotSet();
  error UpkeepAlreadyExists();
  error UpkeepCancelled();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error ValueNotChanged();
  event AdminPrivilegeConfigSet(address indexed admin, bytes privilegeConfig);
  event CancelledUpkeepReport(uint256 indexed id, bytes trigger);
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    bytes32 configDigest,
    uint64 configCount,
    address[] signers,
    address[] transmitters,
    uint8 f,
    bytes onchainConfig,
    uint64 offchainConfigVersion,
    bytes offchainConfig
  );
  event DedupKeyAdded(bytes32 indexed dedupKey);
  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event InsufficientFundsUpkeepReport(uint256 indexed id, bytes trigger);
  event OwnerFundsWithdrawn(uint96 amount);
  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);
  event Paused(address account);
  event PayeesUpdated(address[] transmitters, address[] payees);
  event PayeeshipTransferRequested(address indexed transmitter, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed transmitter, address indexed from, address indexed to);
  event PaymentWithdrawn(address indexed transmitter, uint256 indexed amount, address indexed to, address payee);
  event ReorgedUpkeepReport(uint256 indexed id, bytes trigger);
  event StaleUpkeepReport(uint256 indexed id, bytes trigger);
  event Transmitted(bytes32 configDigest, uint32 epoch);
  event Unpaused(address account);
  event UpkeepAdminTransferRequested(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepAdminTransferred(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event UpkeepCheckDataSet(uint256 indexed id, bytes newCheckData);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepOffchainConfigSet(uint256 indexed id, bytes offchainConfig);
  event UpkeepPaused(uint256 indexed id);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    uint96 totalPayment,
    uint256 gasUsed,
    uint256 gasOverhead,
    bytes trigger
  );
  event UpkeepPrivilegeConfigSet(uint256 indexed id, bytes privilegeConfig);
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event UpkeepRegistered(uint256 indexed id, uint32 performGas, address admin);
  event UpkeepTriggerConfigSet(uint256 indexed id, bytes triggerConfig);
  event UpkeepUnpaused(uint256 indexed id);

  fallback() external;

  function acceptOwnership() external;

  function fallbackTo() external view returns (address);

  function latestConfigDetails() external view returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest);

  function latestConfigDigestAndEpoch() external view returns (bool scanLogs, bytes32 configDigest, uint32 epoch);

  function onTokenTransfer(address sender, uint256 amount, bytes memory data) external;

  function owner() external view returns (address);

  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfigBytes,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external;

  function setConfigTypeSafe(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    KeeperRegistryBase2_1.OnchainConfig memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external;

  function simulatePerformUpkeep(uint256 id, bytes memory performData) external returns (bool success, uint256 gasUsed);

  function transferOwnership(address to) external;

  function transmit(
    bytes32[3] memory reportContext,
    bytes memory rawReport,
    bytes32[] memory rs,
    bytes32[] memory ss,
    bytes32 rawVs
  ) external;

  function typeAndVersion() external view returns (string memory);

  function addFunds(uint256 id, uint96 amount) external;

  function cancelUpkeep(uint256 id) external;

  function checkCallback(
    uint256 id,
    bytes[] memory values,
    bytes memory extraData
  ) external returns (bool upkeepNeeded, bytes memory performData, uint8 upkeepFailureReason, uint256 gasUsed);

  function checkUpkeep(
    uint256 id,
    bytes memory triggerData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      uint8 upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    );

  function checkUpkeep(
    uint256 id
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      uint8 upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    );

  function executeCallback(
    uint256 id,
    bytes memory payload
  ) external returns (bool upkeepNeeded, bytes memory performData, uint8 upkeepFailureReason, uint256 gasUsed);

  function migrateUpkeeps(uint256[] memory ids, address destination) external;

  function receiveUpkeeps(bytes memory encodedUpkeeps) external;

  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    uint8 triggerType,
    bytes memory checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig
  ) external returns (uint256 id);

  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes memory checkData,
    bytes memory offchainConfig
  ) external returns (uint256 id);

  function setUpkeepTriggerConfig(uint256 id, bytes memory triggerConfig) external;

  function acceptPayeeship(address transmitter) external;

  function acceptUpkeepAdmin(uint256 id) external;

  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory);

  function getAdminPrivilegeConfig(address admin) external view returns (bytes memory);

  function getAutomationForwarderLogic() external view returns (address);

  function getBalance(uint256 id) external view returns (uint96 balance);

  function getCancellationDelay() external pure returns (uint256);

  function getConditionalGasOverhead() external pure returns (uint256);

  function getFastGasFeedAddress() external view returns (address);

  function getForwarder(uint256 upkeepID) external view returns (address);

  function getLinkAddress() external view returns (address);

  function getLinkNativeFeedAddress() external view returns (address);

  function getLogGasOverhead() external pure returns (uint256);

  function getMaxPaymentForGas(uint8 triggerType, uint32 gasLimit) external view returns (uint96 maxPayment);

  function getMinBalance(uint256 id) external view returns (uint96);

  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance);

  function getMode() external view returns (uint8);

  function getPeerRegistryMigrationPermission(address peer) external view returns (uint8);

  function getPerPerformByteGasOverhead() external pure returns (uint256);

  function getPerSignerGasOverhead() external pure returns (uint256);

  function getSignerInfo(address query) external view returns (bool active, uint8 index);

  function getState()
    external
    view
    returns (
      KeeperRegistryBase2_1.State memory state,
      KeeperRegistryBase2_1.OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    );

  function getTransmitterInfo(
    address query
  ) external view returns (bool active, uint8 index, uint96 balance, uint96 lastCollected, address payee);

  function getTriggerType(uint256 upkeepId) external pure returns (uint8);

  function getUpkeep(uint256 id) external view returns (KeeperRegistryBase2_1.UpkeepInfo memory upkeepInfo);

  function getUpkeepPrivilegeConfig(uint256 upkeepId) external view returns (bytes memory);

  function getUpkeepTriggerConfig(uint256 upkeepId) external view returns (bytes memory);

  function hasDedupKey(bytes32 dedupKey) external view returns (bool);

  function pause() external;

  function pauseUpkeep(uint256 id) external;

  function recoverFunds() external;

  function setAdminPrivilegeConfig(address admin, bytes memory newPrivilegeConfig) external;

  function setPayees(address[] memory payees) external;

  function setPeerRegistryMigrationPermission(address peer, uint8 permission) external;

  function setUpkeepCheckData(uint256 id, bytes memory newCheckData) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function setUpkeepOffchainConfig(uint256 id, bytes memory config) external;

  function setUpkeepPrivilegeConfig(uint256 upkeepId, bytes memory newPrivilegeConfig) external;

  function transferPayeeship(address transmitter, address proposed) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function unpause() external;

  function unpauseUpkeep(uint256 id) external;

  function upkeepTranscoderVersion() external pure returns (uint8);

  function upkeepVersion() external pure returns (uint8);

  function withdrawFunds(uint256 id, address to) external;

  function withdrawOwnerFunds() external;

  function withdrawPayment(address from, address to) external;
}

interface KeeperRegistryBase2_1 {
  struct OnchainConfig {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend;
    uint32 maxPerformGas;
    uint32 maxCheckDataSize;
    uint32 maxPerformDataSize;
    uint32 maxRevertDataSize;
    uint256 fallbackGasPrice;
    uint256 fallbackLinkPrice;
    address transcoder;
    address[] registrars;
    address upkeepPrivilegeManager;
  }

  struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint96 totalPremium;
    uint256 numUpkeeps;
    uint32 configCount;
    uint32 latestConfigBlockNumber;
    bytes32 latestConfigDigest;
    uint32 latestEpoch;
    bool paused;
  }

  struct UpkeepInfo {
    address target;
    uint32 performGas;
    bytes checkData;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    uint32 lastPerformedBlockNumber;
    uint96 amountSpent;
    bool paused;
    bytes offchainConfig;
  }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"contract KeeperRegistryLogicB2_1","name":"logicA","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"ArrayHasNoEntries","type":"error"},{"inputs":[],"name":"CannotCancel","type":"error"},{"inputs":[],"name":"CheckDataExceedsLimit","type":"error"},{"inputs":[],"name":"ConfigDigestMismatch","type":"error"},{"inputs":[],"name":"DuplicateEntry","type":"error"},{"inputs":[],"name":"DuplicateSigners","type":"error"},{"inputs":[],"name":"GasLimitCanOnlyIncrease","type":"error"},{"inputs":[],"name":"GasLimitOutsideRange","type":"error"},{"inputs":[],"name":"IncorrectNumberOfFaultyOracles","type":"error"},{"inputs":[],"name":"IncorrectNumberOfSignatures","type":"error"},{"inputs":[],"name":"IncorrectNumberOfSigners","type":"error"},{"inputs":[],"name":"IndexOutOfRange","type":"error"},{"inputs":[],"name":"InsufficientFunds","type":"error"},{"inputs":[],"name":"InvalidDataLength","type":"error"},{"inputs":[],"name":"InvalidPayee","type":"error"},{"inputs":[],"name":"InvalidRecipient","type":"error"},{"inputs":[],"name":"InvalidReport","type":"error"},{"inputs":[],"name":"InvalidSigner","type":"error"},{"inputs":[],"name":"InvalidTransmitter","type":"error"},{"inputs":[],"name":"InvalidTrigger","type":"error"},{"inputs":[],"name":"InvalidTriggerType","type":"error"},{"inputs":[],"name":"MaxCheckDataSizeCanOnlyIncrease","type":"error"},{"inputs":[],"name":"MaxPerformDataSizeCanOnlyIncrease","type":"error"},{"inputs":[],"name":"MigrationNotPermitted","type":"error"},{"inputs":[],"name":"NotAContract","type":"error"},{"inputs":[],"name":"OnlyActiveSigners","type":"error"},{"inputs":[],"name":"OnlyActiveTransmitters","type":"error"},{"inputs":[],"name":"OnlyCallableByAdmin","type":"error"},{"inputs":[],"name":"OnlyCallableByLINKToken","type":"error"},{"inputs":[],"name":"OnlyCallableByOwnerOrAdmin","type":"error"},{"inputs":[],"name":"OnlyCallableByOwnerOrRegistrar","type":"error"},{"inputs":[],"name":"OnlyCallableByPayee","type":"error"},{"inputs":[],"name":"OnlyCallableByProposedAdmin","type":"error"},{"inputs":[],"name":"OnlyCallableByProposedPayee","type":"error"},{"inputs":[],"name":"OnlyCallableByUpkeepPrivilegeManager","type":"error"},{"inputs":[],"name":"OnlyPausedUpkeep","type":"error"},{"inputs":[],"name":"OnlySimulatedBackend","type":"error"},{"inputs":[],"name":"OnlyUnpausedUpkeep","type":"error"},{"inputs":[],"name":"ParameterLengthError","type":"error"},{"inputs":[],"name":"PaymentGreaterThanAllLINK","type":"error"},{"inputs":[],"name":"ReentrantCall","type":"error"},{"inputs":[],"name":"RegistryPaused","type":"error"},{"inputs":[],"name":"RepeatedSigner","type":"error"},{"inputs":[],"name":"RepeatedTransmitter","type":"error"},{"inputs":[{"internalType":"bytes","name":"reason","type":"bytes"}],"name":"TargetCheckReverted","type":"error"},{"inputs":[],"name":"TooManyOracles","type":"error"},{"inputs":[],"name":"TranscoderNotSet","type":"error"},{"inputs":[],"name":"UpkeepAlreadyExists","type":"error"},{"inputs":[],"name":"UpkeepCancelled","type":"error"},{"inputs":[],"name":"UpkeepNotCanceled","type":"error"},{"inputs":[],"name":"UpkeepNotNeeded","type":"error"},{"inputs":[],"name":"ValueNotChanged","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":false,"internalType":"bytes","name":"privilegeConfig","type":"bytes"}],"name":"AdminPrivilegeConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"CancelledUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint32","name":"previousConfigBlockNumber","type":"uint32"},{"indexed":false,"internalType":"bytes32","name":"configDigest","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"configCount","type":"uint64"},{"indexed":false,"internalType":"address[]","name":"signers","type":"address[]"},{"indexed":false,"internalType":"address[]","name":"transmitters","type":"address[]"},{"indexed":false,"internalType":"uint8","name":"f","type":"uint8"},{"indexed":false,"internalType":"bytes","name":"onchainConfig","type":"bytes"},{"indexed":false,"internalType":"uint64","name":"offchainConfigVersion","type":"uint64"},{"indexed":false,"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"ConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"dedupKey","type":"bytes32"}],"name":"DedupKeyAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":false,"internalType":"uint96","name":"amount","type":"uint96"}],"name":"FundsAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":false,"internalType":"address","name":"to","type":"address"}],"name":"FundsWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"InsufficientFundsUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint96","name":"amount","type":"uint96"}],"name":"OwnerFundsWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Paused","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address[]","name":"transmitters","type":"address[]"},{"indexed":false,"internalType":"address[]","name":"payees","type":"address[]"}],"name":"PayeesUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"transmitter","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"PayeeshipTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"transmitter","type":"address"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"PayeeshipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"transmitter","type":"address"},{"indexed":true,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":false,"internalType":"address","name":"payee","type":"address"}],"name":"PaymentWithdrawn","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"ReorgedUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"StaleUpkeepReport","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bytes32","name":"configDigest","type":"bytes32"},{"indexed":false,"internalType":"uint32","name":"epoch","type":"uint32"}],"name":"Transmitted","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"account","type":"address"}],"name":"Unpaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"UpkeepAdminTransferRequested","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"}],"name":"UpkeepAdminTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"uint64","name":"atBlockHeight","type":"uint64"}],"name":"UpkeepCanceled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"newCheckData","type":"bytes"}],"name":"UpkeepCheckDataSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint96","name":"gasLimit","type":"uint96"}],"name":"UpkeepGasLimitSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"remainingBalance","type":"uint256"},{"indexed":false,"internalType":"address","name":"destination","type":"address"}],"name":"UpkeepMigrated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"UpkeepOffchainConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"UpkeepPaused","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":true,"internalType":"bool","name":"success","type":"bool"},{"indexed":false,"internalType":"uint96","name":"totalPayment","type":"uint96"},{"indexed":false,"internalType":"uint256","name":"gasUsed","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"gasOverhead","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"trigger","type":"bytes"}],"name":"UpkeepPerformed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"privilegeConfig","type":"bytes"}],"name":"UpkeepPrivilegeConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"startingBalance","type":"uint256"},{"indexed":false,"internalType":"address","name":"importedFrom","type":"address"}],"name":"UpkeepReceived","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"uint32","name":"performGas","type":"uint32"},{"indexed":false,"internalType":"address","name":"admin","type":"address"}],"name":"UpkeepRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"},{"indexed":false,"internalType":"bytes","name":"triggerConfig","type":"bytes"}],"name":"UpkeepTriggerConfigSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"UpkeepUnpaused","type":"event"},{"stateMutability":"nonpayable","type":"fallback"},{"inputs":[],"name":"acceptOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"fallbackTo","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestConfigDetails","outputs":[{"internalType":"uint32","name":"configCount","type":"uint32"},{"internalType":"uint32","name":"blockNumber","type":"uint32"},{"internalType":"bytes32","name":"configDigest","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"latestConfigDigestAndEpoch","outputs":[{"internalType":"bool","name":"scanLogs","type":"bool"},{"internalType":"bytes32","name":"configDigest","type":"bytes32"},{"internalType":"uint32","name":"epoch","type":"uint32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"sender","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"onTokenTransfer","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"signers","type":"address[]"},{"internalType":"address[]","name":"transmitters","type":"address[]"},{"internalType":"uint8","name":"f","type":"uint8"},{"internalType":"bytes","name":"onchainConfigBytes","type":"bytes"},{"internalType":"uint64","name":"offchainConfigVersion","type":"uint64"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"setConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"signers","type":"address[]"},{"internalType":"address[]","name":"transmitters","type":"address[]"},{"internalType":"uint8","name":"f","type":"uint8"},{"components":[{"internalType":"uint32","name":"paymentPremiumPPB","type":"uint32"},{"internalType":"uint32","name":"flatFeeMicroLink","type":"uint32"},{"internalType":"uint32","name":"checkGasLimit","type":"uint32"},{"internalType":"uint24","name":"stalenessSeconds","type":"uint24"},{"internalType":"uint16","name":"gasCeilingMultiplier","type":"uint16"},{"internalType":"uint96","name":"minUpkeepSpend","type":"uint96"},{"internalType":"uint32","name":"maxPerformGas","type":"uint32"},{"internalType":"uint32","name":"maxCheckDataSize","type":"uint32"},{"internalType":"uint32","name":"maxPerformDataSize","type":"uint32"},{"internalType":"uint32","name":"maxRevertDataSize","type":"uint32"},{"internalType":"uint256","name":"fallbackGasPrice","type":"uint256"},{"internalType":"uint256","name":"fallbackLinkPrice","type":"uint256"},{"internalType":"address","name":"transcoder","type":"address"},{"internalType":"address[]","name":"registrars","type":"address[]"},{"internalType":"address","name":"upkeepPrivilegeManager","type":"address"}],"internalType":"struct KeeperRegistryBase2_1.OnchainConfig","name":"onchainConfig","type":"tuple"},{"internalType":"uint64","name":"offchainConfigVersion","type":"uint64"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"setConfigTypeSafe","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"performData","type":"bytes"}],"name":"simulatePerformUpkeep","outputs":[{"internalType":"bool","name":"success","type":"bool"},{"internalType":"uint256","name":"gasUsed","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32[3]","name":"reportContext","type":"bytes32[3]"},{"internalType":"bytes","name":"rawReport","type":"bytes"},{"internalType":"bytes32[]","name":"rs","type":"bytes32[]"},{"internalType":"bytes32[]","name":"ss","type":"bytes32[]"},{"internalType":"bytes32","name":"rawVs","type":"bytes32"}],"name":"transmit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"typeAndVersion","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract KeeperRegistryLogicB2_1","name":"logicB","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint96","name":"amount","type":"uint96"}],"name":"addFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"cancelUpkeep","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes[]","name":"values","type":"bytes[]"},{"internalType":"bytes","name":"extraData","type":"bytes"}],"name":"checkCallback","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"triggerData","type":"bytes"}],"name":"checkUpkeep","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"},{"internalType":"uint256","name":"gasLimit","type":"uint256"},{"internalType":"uint256","name":"fastGasWei","type":"uint256"},{"internalType":"uint256","name":"linkNative","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"checkUpkeep","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"},{"internalType":"uint256","name":"gasLimit","type":"uint256"},{"internalType":"uint256","name":"fastGasWei","type":"uint256"},{"internalType":"uint256","name":"linkNative","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"payload","type":"bytes"}],"name":"executeCallback","outputs":[{"internalType":"bool","name":"upkeepNeeded","type":"bool"},{"internalType":"bytes","name":"performData","type":"bytes"},{"internalType":"enum KeeperRegistryBase2_1.UpkeepFailureReason","name":"upkeepFailureReason","type":"uint8"},{"internalType":"uint256","name":"gasUsed","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"ids","type":"uint256[]"},{"internalType":"address","name":"destination","type":"address"}],"name":"migrateUpkeeps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes","name":"encodedUpkeeps","type":"bytes"}],"name":"receiveUpkeeps","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint32","name":"gasLimit","type":"uint32"},{"internalType":"address","name":"admin","type":"address"},{"internalType":"enum KeeperRegistryBase2_1.Trigger","name":"triggerType","type":"uint8"},{"internalType":"bytes","name":"checkData","type":"bytes"},{"internalType":"bytes","name":"triggerConfig","type":"bytes"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"registerUpkeep","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint32","name":"gasLimit","type":"uint32"},{"internalType":"address","name":"admin","type":"address"},{"internalType":"bytes","name":"checkData","type":"bytes"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"name":"registerUpkeep","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"triggerConfig","type":"bytes"}],"name":"setUpkeepTriggerConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"enum KeeperRegistryBase2_1.Mode","name":"mode","type":"uint8"},{"internalType":"address","name":"link","type":"address"},{"internalType":"address","name":"linkNativeFeed","type":"address"},{"internalType":"address","name":"fastGasFeed","type":"address"},{"internalType":"address","name":"automationForwarderLogic","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"address","name":"transmitter","type":"address"}],"name":"acceptPayeeship","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"acceptUpkeepAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"startIndex","type":"uint256"},{"internalType":"uint256","name":"maxCount","type":"uint256"}],"name":"getActiveUpkeepIDs","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"admin","type":"address"}],"name":"getAdminPrivilegeConfig","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAutomationForwarderLogic","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getBalance","outputs":[{"internalType":"uint96","name":"balance","type":"uint96"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getCancellationDelay","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"getConditionalGasOverhead","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"getFastGasFeedAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepID","type":"uint256"}],"name":"getForwarder","outputs":[{"internalType":"contract IAutomationForwarder","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getLinkAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getLinkNativeFeedAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getLogGasOverhead","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"enum KeeperRegistryBase2_1.Trigger","name":"triggerType","type":"uint8"},{"internalType":"uint32","name":"gasLimit","type":"uint32"}],"name":"getMaxPaymentForGas","outputs":[{"internalType":"uint96","name":"maxPayment","type":"uint96"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getMinBalance","outputs":[{"internalType":"uint96","name":"","type":"uint96"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getMinBalanceForUpkeep","outputs":[{"internalType":"uint96","name":"minBalance","type":"uint96"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMode","outputs":[{"internalType":"enum KeeperRegistryBase2_1.Mode","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"peer","type":"address"}],"name":"getPeerRegistryMigrationPermission","outputs":[{"internalType":"enum KeeperRegistryBase2_1.MigrationPermission","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPerPerformByteGasOverhead","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"getPerSignerGasOverhead","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"query","type":"address"}],"name":"getSignerInfo","outputs":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint8","name":"index","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getState","outputs":[{"components":[{"internalType":"uint32","name":"nonce","type":"uint32"},{"internalType":"uint96","name":"ownerLinkBalance","type":"uint96"},{"internalType":"uint256","name":"expectedLinkBalance","type":"uint256"},{"internalType":"uint96","name":"totalPremium","type":"uint96"},{"internalType":"uint256","name":"numUpkeeps","type":"uint256"},{"internalType":"uint32","name":"configCount","type":"uint32"},{"internalType":"uint32","name":"latestConfigBlockNumber","type":"uint32"},{"internalType":"bytes32","name":"latestConfigDigest","type":"bytes32"},{"internalType":"uint32","name":"latestEpoch","type":"uint32"},{"internalType":"bool","name":"paused","type":"bool"}],"internalType":"struct KeeperRegistryBase2_1.State","name":"state","type":"tuple"},{"components":[{"internalType":"uint32","name":"paymentPremiumPPB","type":"uint32"},{"internalType":"uint32","name":"flatFeeMicroLink","type":"uint32"},{"internalType":"uint32","name":"checkGasLimit","type":"uint32"},{"internalType":"uint24","name":"stalenessSeconds","type":"uint24"},{"internalType":"uint16","name":"gasCeilingMultiplier","type":"uint16"},{"internalType":"uint96","name":"minUpkeepSpend","type":"uint96"},{"internalType":"uint32","name":"maxPerformGas","type":"uint32"},{"internalType":"uint32","name":"maxCheckDataSize","type":"uint32"},{"internalType":"uint32","name":"maxPerformDataSize","type":"uint32"},{"internalType":"uint32","name":"maxRevertDataSize","type":"uint32"},{"internalType":"uint256","name":"fallbackGasPrice","type":"uint256"},{"internalType":"uint256","name":"fallbackLinkPrice","type":"uint256"},{"internalType":"address","name":"transcoder","type":"address"},{"internalType":"address[]","name":"registrars","type":"address[]"},{"internalType":"address","name":"upkeepPrivilegeManager","type":"address"}],"internalType":"struct KeeperRegistryBase2_1.OnchainConfig","name":"config","type":"tuple"},{"internalType":"address[]","name":"signers","type":"address[]"},{"internalType":"address[]","name":"transmitters","type":"address[]"},{"internalType":"uint8","name":"f","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"query","type":"address"}],"name":"getTransmitterInfo","outputs":[{"internalType":"bool","name":"active","type":"bool"},{"internalType":"uint8","name":"index","type":"uint8"},{"internalType":"uint96","name":"balance","type":"uint96"},{"internalType":"uint96","name":"lastCollected","type":"uint96"},{"internalType":"address","name":"payee","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getTriggerType","outputs":[{"internalType":"enum KeeperRegistryBase2_1.Trigger","name":"","type":"uint8"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"getUpkeep","outputs":[{"components":[{"internalType":"address","name":"target","type":"address"},{"internalType":"uint32","name":"performGas","type":"uint32"},{"internalType":"bytes","name":"checkData","type":"bytes"},{"internalType":"uint96","name":"balance","type":"uint96"},{"internalType":"address","name":"admin","type":"address"},{"internalType":"uint64","name":"maxValidBlocknumber","type":"uint64"},{"internalType":"uint32","name":"lastPerformedBlockNumber","type":"uint32"},{"internalType":"uint96","name":"amountSpent","type":"uint96"},{"internalType":"bool","name":"paused","type":"bool"},{"internalType":"bytes","name":"offchainConfig","type":"bytes"}],"internalType":"struct KeeperRegistryBase2_1.UpkeepInfo","name":"upkeepInfo","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getUpkeepPrivilegeConfig","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"}],"name":"getUpkeepTriggerConfig","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"dedupKey","type":"bytes32"}],"name":"hasDedupKey","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"pauseUpkeep","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"recoverFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"admin","type":"address"},{"internalType":"bytes","name":"newPrivilegeConfig","type":"bytes"}],"name":"setAdminPrivilegeConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"payees","type":"address[]"}],"name":"setPayees","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"peer","type":"address"},{"internalType":"enum KeeperRegistryBase2_1.MigrationPermission","name":"permission","type":"uint8"}],"name":"setPeerRegistryMigrationPermission","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"newCheckData","type":"bytes"}],"name":"setUpkeepCheckData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"uint32","name":"gasLimit","type":"uint32"}],"name":"setUpkeepGasLimit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"config","type":"bytes"}],"name":"setUpkeepOffchainConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"upkeepId","type":"uint256"},{"internalType":"bytes","name":"newPrivilegeConfig","type":"bytes"}],"name":"setUpkeepPrivilegeConfig","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"transmitter","type":"address"},{"internalType":"address","name":"proposed","type":"address"}],"name":"transferPayeeship","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"proposed","type":"address"}],"name":"transferUpkeepAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"unpause","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"name":"unpauseUpkeep","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"upkeepTranscoderVersion","outputs":[{"internalType":"enum UpkeepFormat","name":"","type":"uint8"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"upkeepVersion","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"address","name":"to","type":"address"}],"name":"withdrawFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"withdrawOwnerFunds","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"}],"name":"withdrawPayment","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Log {
  uint256 index;
  uint256 txIndex;
  bytes32 txHash;
  uint256 blockNumber;
  bytes32 blockHash;
  address source;
  bytes32[] topics;
  bytes data;
}

interface ILogAutomation {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param log the raw log data matching the filter that this contract has
   * registered as a trigger
   * @param checkData user-specified extra data to provide context to this upkeep
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkLog(
    Log calldata log,
    bytes memory checkData
  ) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface StreamsLookupCompatibleInterface {
  error StreamsLookup(string feedParamKey, string[] feeds, string timeParamKey, uint256 time, bytes extraData);

  /**
   * @notice any contract which wants to utilize StreamsLookup feature needs to
   * implement this interface as well as the automation compatible interface.
   * @param values an array of bytes returned from data streams endpoint.
   * @param extraData context data from streams lookup process.
   * @return upkeepNeeded boolean to indicate whether the keeper should call performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try `abi.encode`.
   */
  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view returns (bool upkeepNeeded, bytes memory performData);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {EnumerableSet} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import {Proxy} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/proxy/Proxy.sol";
import {KeeperRegistryBase2_1} from "./KeeperRegistryBase2_1.sol";
import {KeeperRegistryLogicB2_1} from "./KeeperRegistryLogicB2_1.sol";
import {Chainable} from "./Chainable.sol";
import {IERC677Receiver} from "../../../shared/interfaces/IERC677Receiver.sol";
import {OCR2Abstract} from "../../../shared/ocr2/OCR2Abstract.sol";

/**
 * @notice Registry for adding work for Chainlink Keepers to perform on client
 * contracts. Clients must support the Upkeep interface.
 */
contract KeeperRegistry2_1 is KeeperRegistryBase2_1, OCR2Abstract, Chainable, IERC677Receiver {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @notice versions:
   * - KeeperRegistry 2.1.0: introduces support for log, cron, and ready triggers
                           : removes the need for "wrapped perform data"
   * - KeeperRegistry 2.0.2: pass revert bytes as performData when target contract reverts
   *                       : fixes issue with arbitrum block number
   *                       : does an early return in case of stale report instead of revert
   * - KeeperRegistry 2.0.1: implements workaround for buggy migrate function in 1.X
   * - KeeperRegistry 2.0.0: implement OCR interface
   * - KeeperRegistry 1.3.0: split contract into Proxy and Logic
   *                       : account for Arbitrum and Optimism L1 gas fee
   *                       : allow users to configure upkeeps
   * - KeeperRegistry 1.2.0: allow funding within performUpkeep
   *                       : allow configurable registry maxPerformGas
   *                       : add function to let admin change upkeep gas limit
   *                       : add minUpkeepSpend requirement
   *                       : upgrade to solidity v0.8
   * - KeeperRegistry 1.1.0: added flatFeeMicroLink
   * - KeeperRegistry 1.0.0: initial release
   */
  string public constant override typeAndVersion = "KeeperRegistry 2.1.0";

  /**
   * @param logicA the address of the first logic contract, but cast as logicB in order to call logicB functions
   */
  constructor(
    KeeperRegistryLogicB2_1 logicA
  )
    KeeperRegistryBase2_1(
      logicA.getMode(),
      logicA.getLinkAddress(),
      logicA.getLinkNativeFeedAddress(),
      logicA.getFastGasFeedAddress(),
      logicA.getAutomationForwarderLogic()
    )
    Chainable(address(logicA))
  {}

  // ================================================================
  // |                           ACTIONS                            |
  // ================================================================

  /**
   * @inheritdoc OCR2Abstract
   */
  function transmit(
    bytes32[3] calldata reportContext,
    bytes calldata rawReport,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) external override {
    uint256 gasOverhead = gasleft();
    HotVars memory hotVars = s_hotVars;

    if (hotVars.paused) revert RegistryPaused();
    if (!s_transmitters[msg.sender].active) revert OnlyActiveTransmitters();

    // Verify signatures
    if (s_latestConfigDigest != reportContext[0]) revert ConfigDigestMismatch();
    if (rs.length != hotVars.f + 1 || rs.length != ss.length) revert IncorrectNumberOfSignatures();
    _verifyReportSignature(reportContext, rawReport, rs, ss, rawVs);

    Report memory report = _decodeReport(rawReport);
    UpkeepTransmitInfo[] memory upkeepTransmitInfo = new UpkeepTransmitInfo[](report.upkeepIds.length);
    uint16 numUpkeepsPassedChecks;

    for (uint256 i = 0; i < report.upkeepIds.length; i++) {
      upkeepTransmitInfo[i].upkeep = s_upkeep[report.upkeepIds[i]];
      upkeepTransmitInfo[i].triggerType = _getTriggerType(report.upkeepIds[i]);
      upkeepTransmitInfo[i].maxLinkPayment = _getMaxLinkPayment(
        hotVars,
        upkeepTransmitInfo[i].triggerType,
        uint32(report.gasLimits[i]),
        uint32(report.performDatas[i].length),
        report.fastGasWei,
        report.linkNative,
        true
      );
      (upkeepTransmitInfo[i].earlyChecksPassed, upkeepTransmitInfo[i].dedupID) = _prePerformChecks(
        report.upkeepIds[i],
        report.triggers[i],
        upkeepTransmitInfo[i]
      );

      if (upkeepTransmitInfo[i].earlyChecksPassed) {
        numUpkeepsPassedChecks += 1;
      } else {
        continue;
      }

      // Actually perform the target upkeep
      (upkeepTransmitInfo[i].performSuccess, upkeepTransmitInfo[i].gasUsed) = _performUpkeep(
        upkeepTransmitInfo[i].upkeep.forwarder,
        report.gasLimits[i],
        report.performDatas[i]
      );

      // Deduct that gasUsed by upkeep from our running counter
      gasOverhead -= upkeepTransmitInfo[i].gasUsed;

      // Store last perform block number / deduping key for upkeep
      _updateTriggerMarker(report.upkeepIds[i], upkeepTransmitInfo[i]);
    }
    // No upkeeps to be performed in this report
    if (numUpkeepsPassedChecks == 0) {
      return;
    }

    // This is the overall gas overhead that will be split across performed upkeeps
    // Take upper bound of 16 gas per callData bytes, which is approximated to be reportLength
    // Rest of msg.data is accounted for in accounting overheads
    gasOverhead =
      (gasOverhead - gasleft() + 16 * rawReport.length) +
      ACCOUNTING_FIXED_GAS_OVERHEAD +
      (ACCOUNTING_PER_SIGNER_GAS_OVERHEAD * (hotVars.f + 1));
    gasOverhead = gasOverhead / numUpkeepsPassedChecks + ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD;

    uint96 totalReimbursement;
    uint96 totalPremium;
    {
      uint96 reimbursement;
      uint96 premium;
      for (uint256 i = 0; i < report.upkeepIds.length; i++) {
        if (upkeepTransmitInfo[i].earlyChecksPassed) {
          upkeepTransmitInfo[i].gasOverhead = _getCappedGasOverhead(
            gasOverhead,
            upkeepTransmitInfo[i].triggerType,
            uint32(report.performDatas[i].length),
            hotVars.f
          );

          (reimbursement, premium) = _postPerformPayment(
            hotVars,
            report.upkeepIds[i],
            upkeepTransmitInfo[i],
            report.fastGasWei,
            report.linkNative,
            numUpkeepsPassedChecks
          );
          totalPremium += premium;
          totalReimbursement += reimbursement;

          emit UpkeepPerformed(
            report.upkeepIds[i],
            upkeepTransmitInfo[i].performSuccess,
            reimbursement + premium,
            upkeepTransmitInfo[i].gasUsed,
            upkeepTransmitInfo[i].gasOverhead,
            report.triggers[i]
          );
        }
      }
    }
    // record payments
    s_transmitters[msg.sender].balance += totalReimbursement;
    s_hotVars.totalPremium += totalPremium;

    uint40 epochAndRound = uint40(uint256(reportContext[1]));
    uint32 epoch = uint32(epochAndRound >> 8);
    if (epoch > hotVars.latestEpoch) {
      s_hotVars.latestEpoch = epoch;
    }
  }

  /**
   * @notice simulates the upkeep with the perform data returned from checkUpkeep
   * @param id identifier of the upkeep to execute the data with.
   * @param performData calldata parameter to be passed to the target upkeep.
   * @return success whether the call reverted or not
   * @return gasUsed the amount of gas the target contract consumed
   */
  function simulatePerformUpkeep(
    uint256 id,
    bytes calldata performData
  ) external cannotExecute returns (bool success, uint256 gasUsed) {
    if (s_hotVars.paused) revert RegistryPaused();
    Upkeep memory upkeep = s_upkeep[id];
    (success, gasUsed) = _performUpkeep(upkeep.forwarder, upkeep.performGas, performData);
    return (success, gasUsed);
  }

  /**
   * @notice uses LINK's transferAndCall to LINK and add funding to an upkeep
   * @dev safe to cast uint256 to uint96 as total LINK supply is under UINT96MAX
   * @param sender the account which transferred the funds
   * @param amount number of LINK transfer
   */
  function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external override {
    if (msg.sender != address(i_link)) revert OnlyCallableByLINKToken();
    if (data.length != 32) revert InvalidDataLength();
    uint256 id = abi.decode(data, (uint256));
    if (s_upkeep[id].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
    s_upkeep[id].balance = s_upkeep[id].balance + uint96(amount);
    s_expectedLinkBalance = s_expectedLinkBalance + amount;
    emit FundsAdded(id, sender, uint96(amount));
  }

  // ================================================================
  // |                           SETTERS                            |
  // ================================================================

  /**
   * @inheritdoc OCR2Abstract
   * @dev prefer the type-safe version of setConfig (below) whenever possible
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfigBytes,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external override {
    setConfigTypeSafe(
      signers,
      transmitters,
      f,
      abi.decode(onchainConfigBytes, (OnchainConfig)),
      offchainConfigVersion,
      offchainConfig
    );
  }

  function setConfigTypeSafe(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    OnchainConfig memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) public onlyOwner {
    if (signers.length > maxNumOracles) revert TooManyOracles();
    if (f == 0) revert IncorrectNumberOfFaultyOracles();
    if (signers.length != transmitters.length || signers.length <= 3 * f) revert IncorrectNumberOfSigners();

    // move all pooled payments out of the pool to each transmitter's balance
    uint96 totalPremium = s_hotVars.totalPremium;
    uint96 oldLength = uint96(s_transmittersList.length);
    for (uint256 i = 0; i < oldLength; i++) {
      _updateTransmitterBalanceFromPool(s_transmittersList[i], totalPremium, oldLength);
    }

    // remove any old signer/transmitter addresses
    address signerAddress;
    address transmitterAddress;
    for (uint256 i = 0; i < oldLength; i++) {
      signerAddress = s_signersList[i];
      transmitterAddress = s_transmittersList[i];
      delete s_signers[signerAddress];
      // Do not delete the whole transmitter struct as it has balance information stored
      s_transmitters[transmitterAddress].active = false;
    }
    delete s_signersList;
    delete s_transmittersList;

    // add new signer/transmitter addresses
    {
      Transmitter memory transmitter;
      address temp;
      for (uint256 i = 0; i < signers.length; i++) {
        if (s_signers[signers[i]].active) revert RepeatedSigner();
        if (signers[i] == ZERO_ADDRESS) revert InvalidSigner();
        s_signers[signers[i]] = Signer({active: true, index: uint8(i)});

        temp = transmitters[i];
        if (temp == ZERO_ADDRESS) revert InvalidTransmitter();
        transmitter = s_transmitters[temp];
        if (transmitter.active) revert RepeatedTransmitter();
        transmitter.active = true;
        transmitter.index = uint8(i);
        // new transmitters start afresh from current totalPremium
        // some spare change of premium from previous pool will be forfeited
        transmitter.lastCollected = totalPremium;
        s_transmitters[temp] = transmitter;
      }
    }
    s_signersList = signers;
    s_transmittersList = transmitters;

    s_hotVars = HotVars({
      f: f,
      paymentPremiumPPB: onchainConfig.paymentPremiumPPB,
      flatFeeMicroLink: onchainConfig.flatFeeMicroLink,
      stalenessSeconds: onchainConfig.stalenessSeconds,
      gasCeilingMultiplier: onchainConfig.gasCeilingMultiplier,
      paused: s_hotVars.paused,
      reentrancyGuard: s_hotVars.reentrancyGuard,
      totalPremium: totalPremium,
      latestEpoch: 0 // DON restarts epoch
    });

    s_storage = Storage({
      checkGasLimit: onchainConfig.checkGasLimit,
      minUpkeepSpend: onchainConfig.minUpkeepSpend,
      maxPerformGas: onchainConfig.maxPerformGas,
      transcoder: onchainConfig.transcoder,
      maxCheckDataSize: onchainConfig.maxCheckDataSize,
      maxPerformDataSize: onchainConfig.maxPerformDataSize,
      maxRevertDataSize: onchainConfig.maxRevertDataSize,
      upkeepPrivilegeManager: onchainConfig.upkeepPrivilegeManager,
      nonce: s_storage.nonce,
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      ownerLinkBalance: s_storage.ownerLinkBalance
    });
    s_fallbackGasPrice = onchainConfig.fallbackGasPrice;
    s_fallbackLinkPrice = onchainConfig.fallbackLinkPrice;

    uint32 previousConfigBlockNumber = s_storage.latestConfigBlockNumber;
    s_storage.latestConfigBlockNumber = uint32(_blockNum());
    s_storage.configCount += 1;

    bytes memory onchainConfigBytes = abi.encode(onchainConfig);

    s_latestConfigDigest = _configDigestFromConfigData(
      block.chainid,
      address(this),
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfigBytes,
      offchainConfigVersion,
      offchainConfig
    );

    for (uint256 idx = 0; idx < s_registrars.length(); idx++) {
      s_registrars.remove(s_registrars.at(idx));
    }

    for (uint256 idx = 0; idx < onchainConfig.registrars.length; idx++) {
      s_registrars.add(onchainConfig.registrars[idx]);
    }

    emit ConfigSet(
      previousConfigBlockNumber,
      s_latestConfigDigest,
      s_storage.configCount,
      signers,
      transmitters,
      f,
      onchainConfigBytes,
      offchainConfigVersion,
      offchainConfig
    );
  }

  // ================================================================
  // |                           GETTERS                            |
  // ================================================================

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDetails()
    external
    view
    override
    returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest)
  {
    return (s_storage.configCount, s_storage.latestConfigBlockNumber, s_latestConfigDigest);
  }

  /**
   * @inheritdoc OCR2Abstract
   */
  function latestConfigDigestAndEpoch()
    external
    view
    override
    returns (bool scanLogs, bytes32 configDigest, uint32 epoch)
  {
    return (false, s_latestConfigDigest, s_hotVars.latestEpoch);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {EnumerableSet} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import {ArbGasInfo} from "../../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbGasInfo.sol";
import {OVM_GasPriceOracle} from "../../../vendor/@eth-optimism/contracts/0.8.9/contracts/L2/predeploys/OVM_GasPriceOracle.sol";
import {ExecutionPrevention} from "../../../automation/ExecutionPrevention.sol";
import {ArbSys} from "../../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import {StreamsLookupCompatibleInterface} from "./interfaces/StreamsLookupCompatibleInterface.sol";
import {ILogAutomation, Log} from "./interfaces/ILogAutomation.sol";
import {IAutomationForwarder} from "./interfaces/IAutomationForwarder.sol";
import {ConfirmedOwner} from "../../../shared/access/ConfirmedOwner.sol";
import {AggregatorV3Interface} from "../../../interfaces/AggregatorV3Interface.sol";
import {LinkTokenInterface} from "../../../shared/interfaces/LinkTokenInterface.sol";
import {KeeperCompatibleInterface} from "../../../automation/interfaces/KeeperCompatibleInterface.sol";
import {UpkeepTranscoderInterface, UpkeepFormat} from "../../../automation/interfaces/UpkeepTranscoderInterface.sol";

/**
 * @notice Base Keeper Registry contract, contains shared logic between
 * KeeperRegistry and KeeperRegistryLogic
 * @dev all errors, events, and internal functions should live here
 */
abstract contract KeeperRegistryBase2_1 is ConfirmedOwner, ExecutionPrevention {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  address internal constant ZERO_ADDRESS = address(0);
  address internal constant IGNORE_ADDRESS = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;
  bytes4 internal constant CHECK_SELECTOR = KeeperCompatibleInterface.checkUpkeep.selector;
  bytes4 internal constant PERFORM_SELECTOR = KeeperCompatibleInterface.performUpkeep.selector;
  bytes4 internal constant CHECK_CALLBACK_SELECTOR = StreamsLookupCompatibleInterface.checkCallback.selector;
  bytes4 internal constant CHECK_LOG_SELECTOR = ILogAutomation.checkLog.selector;
  uint256 internal constant PERFORM_GAS_MIN = 2_300;
  uint256 internal constant CANCELLATION_DELAY = 50;
  uint256 internal constant PERFORM_GAS_CUSHION = 5_000;
  uint256 internal constant PPB_BASE = 1_000_000_000;
  uint32 internal constant UINT32_MAX = type(uint32).max;
  uint96 internal constant LINK_TOTAL_SUPPLY = 1e27;
  // The first byte of the mask can be 0, because we only ever have 31 oracles
  uint256 internal constant ORACLE_MASK = 0x0001010101010101010101010101010101010101010101010101010101010101;
  /**
   * @dev UPKEEP_TRANSCODER_VERSION_BASE is temporary necessity for backwards compatibility with
   * MigratableKeeperRegistryInterfaceV1 - it should be removed in future versions in favor of
   * UPKEEP_VERSION_BASE and MigratableKeeperRegistryInterfaceV2
   */
  UpkeepFormat internal constant UPKEEP_TRANSCODER_VERSION_BASE = UpkeepFormat.V1;
  uint8 internal constant UPKEEP_VERSION_BASE = 3;
  // L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";

  uint256 internal constant REGISTRY_CONDITIONAL_OVERHEAD = 90_000; // Used in maxPayment estimation, and in capping overheads during actual payment
  uint256 internal constant REGISTRY_LOG_OVERHEAD = 110_000; // Used only in maxPayment estimation, and in capping overheads during actual payment.
  uint256 internal constant REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD = 20; // Used only in maxPayment estimation, and in capping overheads during actual payment. Value scales with performData length.
  uint256 internal constant REGISTRY_PER_SIGNER_GAS_OVERHEAD = 7_500; // Used only in maxPayment estimation, and in capping overheads during actual payment. Value scales with f.

  uint256 internal constant ACCOUNTING_FIXED_GAS_OVERHEAD = 27_500; // Used in actual payment. Fixed overhead per tx
  uint256 internal constant ACCOUNTING_PER_SIGNER_GAS_OVERHEAD = 1_100; // Used in actual payment. overhead per signer
  uint256 internal constant ACCOUNTING_PER_UPKEEP_GAS_OVERHEAD = 7_000; // Used in actual payment. overhead per upkeep performed

  OVM_GasPriceOracle internal constant OPTIMISM_ORACLE = OVM_GasPriceOracle(0x420000000000000000000000000000000000000F);
  ArbGasInfo internal constant ARB_NITRO_ORACLE = ArbGasInfo(0x000000000000000000000000000000000000006C);
  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);

  LinkTokenInterface internal immutable i_link;
  AggregatorV3Interface internal immutable i_linkNativeFeed;
  AggregatorV3Interface internal immutable i_fastGasFeed;
  Mode internal immutable i_mode;
  address internal immutable i_automationForwarderLogic;

  /**
   * @dev - The storage is gas optimised for one and only one function - transmit. All the storage accessed in transmit
   * is stored compactly. Rest of the storage layout is not of much concern as transmit is the only hot path
   */

  // Upkeep storage
  EnumerableSet.UintSet internal s_upkeepIDs;
  mapping(uint256 => Upkeep) internal s_upkeep; // accessed during transmit
  mapping(uint256 => address) internal s_upkeepAdmin;
  mapping(uint256 => address) internal s_proposedAdmin;
  mapping(uint256 => bytes) internal s_checkData;
  mapping(bytes32 => bool) internal s_dedupKeys;
  // Registry config and state
  EnumerableSet.AddressSet internal s_registrars;
  mapping(address => Transmitter) internal s_transmitters;
  mapping(address => Signer) internal s_signers;
  address[] internal s_signersList; // s_signersList contains the signing address of each oracle
  address[] internal s_transmittersList; // s_transmittersList contains the transmission address of each oracle
  mapping(address => address) internal s_transmitterPayees; // s_payees contains the mapping from transmitter to payee.
  mapping(address => address) internal s_proposedPayee; // proposed payee for a transmitter
  bytes32 internal s_latestConfigDigest; // Read on transmit path in case of signature verification
  HotVars internal s_hotVars; // Mixture of config and state, used in transmit
  Storage internal s_storage; // Mixture of config and state, not used in transmit
  uint256 internal s_fallbackGasPrice;
  uint256 internal s_fallbackLinkPrice;
  uint256 internal s_expectedLinkBalance; // Used in case of erroneous LINK transfers to contract
  mapping(address => MigrationPermission) internal s_peerRegistryMigrationPermission; // Permissions for migration to and fro
  mapping(uint256 => bytes) internal s_upkeepTriggerConfig; // upkeep triggers
  mapping(uint256 => bytes) internal s_upkeepOffchainConfig; // general config set by users for each upkeep
  mapping(uint256 => bytes) internal s_upkeepPrivilegeConfig; // general config set by an administrative role for an upkeep
  mapping(address => bytes) internal s_adminPrivilegeConfig; // general config set by an administrative role for an admin

  error ArrayHasNoEntries();
  error CannotCancel();
  error CheckDataExceedsLimit();
  error ConfigDigestMismatch();
  error DuplicateEntry();
  error DuplicateSigners();
  error GasLimitCanOnlyIncrease();
  error GasLimitOutsideRange();
  error IncorrectNumberOfFaultyOracles();
  error IncorrectNumberOfSignatures();
  error IncorrectNumberOfSigners();
  error IndexOutOfRange();
  error InsufficientFunds();
  error InvalidDataLength();
  error InvalidTrigger();
  error InvalidPayee();
  error InvalidRecipient();
  error InvalidReport();
  error InvalidSigner();
  error InvalidTransmitter();
  error InvalidTriggerType();
  error MaxCheckDataSizeCanOnlyIncrease();
  error MaxPerformDataSizeCanOnlyIncrease();
  error MigrationNotPermitted();
  error NotAContract();
  error OnlyActiveSigners();
  error OnlyActiveTransmitters();
  error OnlyCallableByAdmin();
  error OnlyCallableByLINKToken();
  error OnlyCallableByOwnerOrAdmin();
  error OnlyCallableByOwnerOrRegistrar();
  error OnlyCallableByPayee();
  error OnlyCallableByProposedAdmin();
  error OnlyCallableByProposedPayee();
  error OnlyCallableByUpkeepPrivilegeManager();
  error OnlyPausedUpkeep();
  error OnlyUnpausedUpkeep();
  error ParameterLengthError();
  error PaymentGreaterThanAllLINK();
  error ReentrantCall();
  error RegistryPaused();
  error RepeatedSigner();
  error RepeatedTransmitter();
  error TargetCheckReverted(bytes reason);
  error TooManyOracles();
  error TranscoderNotSet();
  error UpkeepAlreadyExists();
  error UpkeepCancelled();
  error UpkeepNotCanceled();
  error UpkeepNotNeeded();
  error ValueNotChanged();

  enum MigrationPermission {
    NONE,
    OUTGOING,
    INCOMING,
    BIDIRECTIONAL
  }

  enum Mode {
    DEFAULT,
    ARBITRUM,
    OPTIMISM
  }

  enum Trigger {
    CONDITION,
    LOG
  }

  enum UpkeepFailureReason {
    NONE,
    UPKEEP_CANCELLED,
    UPKEEP_PAUSED,
    TARGET_CHECK_REVERTED,
    UPKEEP_NOT_NEEDED,
    PERFORM_DATA_EXCEEDS_LIMIT,
    INSUFFICIENT_BALANCE,
    CALLBACK_REVERTED,
    REVERT_DATA_EXCEEDS_LIMIT,
    REGISTRY_PAUSED
  }

  /**
   * @notice OnchainConfig of the registry
   * @dev only used in params and return values
   * @member paymentPremiumPPB payment premium rate oracles receive on top of
   * being reimbursed for gas, measured in parts per billion
   * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
   * priced in MicroLink; can be used in conjunction with or independently of
   * paymentPremiumPPB
   * @member checkGasLimit gas limit when checking for upkeep
   * @member stalenessSeconds number of seconds that is allowed for feed data to
   * be stale before switching to the fallback pricing
   * @member gasCeilingMultiplier multiplier to apply to the fast gas feed price
   * when calculating the payment ceiling for keepers
   * @member minUpkeepSpend minimum LINK that an upkeep must spend before cancelling
   * @member maxPerformGas max performGas allowed for an upkeep on this registry
   * @member maxCheckDataSize max length of checkData bytes
   * @member maxPerformDataSize max length of performData bytes
   * @member maxRevertDataSize max length of revertData bytes
   * @member fallbackGasPrice gas price used if the gas price feed is stale
   * @member fallbackLinkPrice LINK price used if the LINK price feed is stale
   * @member transcoder address of the transcoder contract
   * @member registrars addresses of the registrar contracts
   * @member upkeepPrivilegeManager address which can set privilege for upkeeps
   */
  struct OnchainConfig {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend;
    uint32 maxPerformGas;
    uint32 maxCheckDataSize;
    uint32 maxPerformDataSize;
    uint32 maxRevertDataSize;
    uint256 fallbackGasPrice;
    uint256 fallbackLinkPrice;
    address transcoder;
    address[] registrars;
    address upkeepPrivilegeManager;
  }

  /**
   * @notice state of the registry
   * @dev only used in params and return values
   * @dev this will likely be deprecated in a future version of the registry in favor of individual getters
   * @member nonce used for ID generation
   * @member ownerLinkBalance withdrawable balance of LINK by contract owner
   * @member expectedLinkBalance the expected balance of LINK of the registry
   * @member totalPremium the total premium collected on registry so far
   * @member numUpkeeps total number of upkeeps on the registry
   * @member configCount ordinal number of current config, out of all configs applied to this contract so far
   * @member latestConfigBlockNumber last block at which this config was set
   * @member latestConfigDigest domain-separation tag for current config
   * @member latestEpoch for which a report was transmitted
   * @member paused freeze on execution scoped to the entire registry
   */
  struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint96 totalPremium;
    uint256 numUpkeeps;
    uint32 configCount;
    uint32 latestConfigBlockNumber;
    bytes32 latestConfigDigest;
    uint32 latestEpoch;
    bool paused;
  }

  /**
   * @notice relevant state of an upkeep which is used in transmit function
   * @member paused if this upkeep has been paused
   * @member performGas the gas limit of upkeep execution
   * @member maxValidBlocknumber until which block this upkeep is valid
   * @member forwarder the forwarder contract to use for this upkeep
   * @member amountSpent the amount this upkeep has spent
   * @member balance the balance of this upkeep
   * @member lastPerformedBlockNumber the last block number when this upkeep was performed
   */
  struct Upkeep {
    bool paused;
    uint32 performGas;
    uint32 maxValidBlocknumber;
    IAutomationForwarder forwarder;
    // 0 bytes left in 1st EVM word - not written to in transmit
    uint96 amountSpent;
    uint96 balance;
    uint32 lastPerformedBlockNumber;
    // 2 bytes left in 2nd EVM word - written in transmit path
  }

  /**
   * @notice all information about an upkeep
   * @dev only used in return values
   * @dev this will likely be deprecated in a future version of the registry
   * @member target the contract which needs to be serviced
   * @member performGas the gas limit of upkeep execution
   * @member checkData the checkData bytes for this upkeep
   * @member balance the balance of this upkeep
   * @member admin for this upkeep
   * @member maxValidBlocknumber until which block this upkeep is valid
   * @member lastPerformedBlockNumber the last block number when this upkeep was performed
   * @member amountSpent the amount this upkeep has spent
   * @member paused if this upkeep has been paused
   * @member offchainConfig the off-chain config of this upkeep
   */
  struct UpkeepInfo {
    address target;
    uint32 performGas;
    bytes checkData;
    uint96 balance;
    address admin;
    uint64 maxValidBlocknumber;
    uint32 lastPerformedBlockNumber;
    uint96 amountSpent;
    bool paused;
    bytes offchainConfig;
  }

  /// @dev Config + State storage struct which is on hot transmit path
  struct HotVars {
    uint8 f; // maximum number of faulty oracles
    uint32 paymentPremiumPPB; // premium percentage charged to user over tx cost
    uint32 flatFeeMicroLink; // flat fee charged to user for every perform
    uint24 stalenessSeconds; // Staleness tolerance for feeds
    uint16 gasCeilingMultiplier; // multiplier on top of fast gas feed for upper bound
    bool paused; // pause switch for all upkeeps in the registry
    bool reentrancyGuard; // guard against reentrancy
    uint96 totalPremium; // total historical payment to oracles for premium
    uint32 latestEpoch; // latest epoch for which a report was transmitted
    // 1 EVM word full
  }

  /// @dev Config + State storage struct which is not on hot transmit path
  struct Storage {
    uint96 minUpkeepSpend; // Minimum amount an upkeep must spend
    address transcoder; // Address of transcoder contract used in migrations
    // 1 EVM word full
    uint96 ownerLinkBalance; // Balance of owner, accumulates minUpkeepSpend in case it is not spent
    uint32 checkGasLimit; // Gas limit allowed in checkUpkeep
    uint32 maxPerformGas; // Max gas an upkeep can use on this registry
    uint32 nonce; // Nonce for each upkeep created
    uint32 configCount; // incremented each time a new config is posted, The count
    // is incorporated into the config digest to prevent replay attacks.
    uint32 latestConfigBlockNumber; // makes it easier for offchain systems to extract config from logs
    // 2 EVM word full
    uint32 maxCheckDataSize; // max length of checkData bytes
    uint32 maxPerformDataSize; // max length of performData bytes
    uint32 maxRevertDataSize; // max length of revertData bytes
    address upkeepPrivilegeManager; // address which can set privilege for upkeeps
    // 3 EVM word full
  }

  /// @dev Report transmitted by OCR to transmit function
  struct Report {
    uint256 fastGasWei;
    uint256 linkNative;
    uint256[] upkeepIds;
    uint256[] gasLimits;
    bytes[] triggers;
    bytes[] performDatas;
  }

  /**
   * @dev This struct is used to maintain run time information about an upkeep in transmit function
   * @member upkeep the upkeep struct
   * @member earlyChecksPassed whether the upkeep passed early checks before perform
   * @member maxLinkPayment the max amount this upkeep could pay for work
   * @member performSuccess whether the perform was successful
   * @member triggerType the type of trigger
   * @member gasUsed gasUsed by this upkeep in perform
   * @member gasOverhead gasOverhead for this upkeep
   * @member dedupID unique ID used to dedup an upkeep/trigger combo
   */
  struct UpkeepTransmitInfo {
    Upkeep upkeep;
    bool earlyChecksPassed;
    uint96 maxLinkPayment;
    bool performSuccess;
    Trigger triggerType;
    uint256 gasUsed;
    uint256 gasOverhead;
    bytes32 dedupID;
  }

  struct Transmitter {
    bool active;
    uint8 index; // Index of oracle in s_signersList/s_transmittersList
    uint96 balance;
    uint96 lastCollected;
  }

  struct Signer {
    bool active;
    // Index of oracle in s_signersList/s_transmittersList
    uint8 index;
  }

  /**
   * @notice the trigger structure conditional trigger type
   */
  struct ConditionalTrigger {
    uint32 blockNum;
    bytes32 blockHash;
  }

  /**
   * @notice the trigger structure of log upkeeps
   * @dev NOTE that blockNum / blockHash describe the block used for the callback,
   * not necessarily the block number that the log was emitted in!!!!
   */
  struct LogTrigger {
    bytes32 logBlockHash;
    bytes32 txHash;
    uint32 logIndex;
    uint32 blockNum;
    bytes32 blockHash;
  }

  event AdminPrivilegeConfigSet(address indexed admin, bytes privilegeConfig);
  event CancelledUpkeepReport(uint256 indexed id, bytes trigger);
  event DedupKeyAdded(bytes32 indexed dedupKey);
  event FundsAdded(uint256 indexed id, address indexed from, uint96 amount);
  event FundsWithdrawn(uint256 indexed id, uint256 amount, address to);
  event InsufficientFundsUpkeepReport(uint256 indexed id, bytes trigger);
  event OwnerFundsWithdrawn(uint96 amount);
  event Paused(address account);
  event PayeesUpdated(address[] transmitters, address[] payees);
  event PayeeshipTransferRequested(address indexed transmitter, address indexed from, address indexed to);
  event PayeeshipTransferred(address indexed transmitter, address indexed from, address indexed to);
  event PaymentWithdrawn(address indexed transmitter, uint256 indexed amount, address indexed to, address payee);
  event ReorgedUpkeepReport(uint256 indexed id, bytes trigger);
  event StaleUpkeepReport(uint256 indexed id, bytes trigger);
  event UpkeepAdminTransferred(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepAdminTransferRequested(uint256 indexed id, address indexed from, address indexed to);
  event UpkeepCanceled(uint256 indexed id, uint64 indexed atBlockHeight);
  event UpkeepCheckDataSet(uint256 indexed id, bytes newCheckData);
  event UpkeepGasLimitSet(uint256 indexed id, uint96 gasLimit);
  event UpkeepMigrated(uint256 indexed id, uint256 remainingBalance, address destination);
  event UpkeepOffchainConfigSet(uint256 indexed id, bytes offchainConfig);
  event UpkeepPaused(uint256 indexed id);
  event UpkeepPerformed(
    uint256 indexed id,
    bool indexed success,
    uint96 totalPayment,
    uint256 gasUsed,
    uint256 gasOverhead,
    bytes trigger
  );
  event UpkeepPrivilegeConfigSet(uint256 indexed id, bytes privilegeConfig);
  event UpkeepReceived(uint256 indexed id, uint256 startingBalance, address importedFrom);
  event UpkeepRegistered(uint256 indexed id, uint32 performGas, address admin);
  event UpkeepTriggerConfigSet(uint256 indexed id, bytes triggerConfig);
  event UpkeepUnpaused(uint256 indexed id);
  event Unpaused(address account);

  /**
   * @param mode the contract mode of default, Arbitrum, or Optimism
   * @param link address of the LINK Token
   * @param linkNativeFeed address of the LINK/Native price feed
   * @param fastGasFeed address of the Fast Gas price feed
   */
  constructor(
    Mode mode,
    address link,
    address linkNativeFeed,
    address fastGasFeed,
    address automationForwarderLogic
  ) ConfirmedOwner(msg.sender) {
    i_mode = mode;
    i_link = LinkTokenInterface(link);
    i_linkNativeFeed = AggregatorV3Interface(linkNativeFeed);
    i_fastGasFeed = AggregatorV3Interface(fastGasFeed);
    i_automationForwarderLogic = automationForwarderLogic;
  }

  // ================================================================
  // |                   INTERNAL FUNCTIONS ONLY                    |
  // ================================================================

  /**
   * @dev creates a new upkeep with the given fields
   * @param id the id of the upkeep
   * @param upkeep the upkeep to create
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param checkData data which is passed to user's checkUpkeep
   * @param triggerConfig the trigger config for this upkeep
   * @param offchainConfig the off-chain config of this upkeep
   */
  function _createUpkeep(
    uint256 id,
    Upkeep memory upkeep,
    address admin,
    bytes memory checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig
  ) internal {
    if (s_hotVars.paused) revert RegistryPaused();
    if (checkData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    if (upkeep.performGas < PERFORM_GAS_MIN || upkeep.performGas > s_storage.maxPerformGas)
      revert GasLimitOutsideRange();
    if (address(s_upkeep[id].forwarder) != address(0)) revert UpkeepAlreadyExists();
    s_upkeep[id] = upkeep;
    s_upkeepAdmin[id] = admin;
    s_checkData[id] = checkData;
    s_expectedLinkBalance = s_expectedLinkBalance + upkeep.balance;
    s_upkeepTriggerConfig[id] = triggerConfig;
    s_upkeepOffchainConfig[id] = offchainConfig;
    s_upkeepIDs.add(id);
  }

  /**
   * @dev creates an ID for the upkeep based on the upkeep's type
   * @dev the format of the ID looks like this:
   * ****00000000000X****************
   * 4 bytes of entropy
   * 11 bytes of zeros
   * 1 identifying byte for the trigger type
   * 16 bytes of entropy
   * @dev this maintains the same level of entropy as eth addresses, so IDs will still be unique
   * @dev we add the "identifying" part in the middle so that it is mostly hidden from users who usually only
   * see the first 4 and last 4 hex values ex 0x1234...ABCD
   */
  function _createID(Trigger triggerType) internal view returns (uint256) {
    bytes1 empty;
    bytes memory idBytes = abi.encodePacked(
      keccak256(abi.encode(_blockHash(_blockNum() - 1), address(this), s_storage.nonce))
    );
    for (uint256 idx = 4; idx < 15; idx++) {
      idBytes[idx] = empty;
    }
    idBytes[15] = bytes1(uint8(triggerType));
    return uint256(bytes32(idBytes));
  }

  /**
   * @dev retrieves feed data for fast gas/native and link/native prices. if the feed
   * data is stale it uses the configured fallback price. Once a price is picked
   * for gas it takes the min of gas price in the transaction or the fast gas
   * price in order to reduce costs for the upkeep clients.
   */
  function _getFeedData(HotVars memory hotVars) internal view returns (uint256 gasWei, uint256 linkNative) {
    uint32 stalenessSeconds = hotVars.stalenessSeconds;
    bool staleFallback = stalenessSeconds > 0;
    uint256 timestamp;
    int256 feedValue;
    (, feedValue, , timestamp, ) = i_fastGasFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      gasWei = s_fallbackGasPrice;
    } else {
      gasWei = uint256(feedValue);
    }
    (, feedValue, , timestamp, ) = i_linkNativeFeed.latestRoundData();
    if (
      feedValue <= 0 || block.timestamp < timestamp || (staleFallback && stalenessSeconds < block.timestamp - timestamp)
    ) {
      linkNative = s_fallbackLinkPrice;
    } else {
      linkNative = uint256(feedValue);
    }
    return (gasWei, linkNative);
  }

  /**
   * @dev calculates LINK paid for gas spent plus a configure premium percentage
   * @param gasLimit the amount of gas used
   * @param gasOverhead the amount of gas overhead
   * @param fastGasWei the fast gas price
   * @param linkNative the exchange ratio between LINK and Native token
   * @param numBatchedUpkeeps the number of upkeeps in this batch. Used to divide the L1 cost
   * @param isExecution if this is triggered by a perform upkeep function
   */
  function _calculatePaymentAmount(
    HotVars memory hotVars,
    uint256 gasLimit,
    uint256 gasOverhead,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps,
    bool isExecution
  ) internal view returns (uint96, uint96) {
    uint256 gasWei = fastGasWei * hotVars.gasCeilingMultiplier;
    // in case it's actual execution use actual gas price, capped by fastGasWei * gasCeilingMultiplier
    if (isExecution && tx.gasprice < gasWei) {
      gasWei = tx.gasprice;
    }

    uint256 l1CostWei = 0;
    if (i_mode == Mode.OPTIMISM) {
      bytes memory txCallData = new bytes(0);
      if (isExecution) {
        txCallData = bytes.concat(msg.data, L1_FEE_DATA_PADDING);
      } else {
        // fee is 4 per 0 byte, 16 per non-zero byte. Worst case we can have
        // s_storage.maxPerformDataSize non zero-bytes. Instead of setting bytes to non-zero
        // we initialize 'new bytes' of length 4*maxPerformDataSize to cover for zero bytes.
        txCallData = new bytes(4 * s_storage.maxPerformDataSize);
      }
      l1CostWei = OPTIMISM_ORACLE.getL1Fee(txCallData);
    } else if (i_mode == Mode.ARBITRUM) {
      if (isExecution) {
        l1CostWei = ARB_NITRO_ORACLE.getCurrentTxL1GasFees();
      } else {
        // fee is 4 per 0 byte, 16 per non-zero byte - we assume all non-zero and
        // max data size to calculate max payment
        (, uint256 perL1CalldataUnit, , , , ) = ARB_NITRO_ORACLE.getPricesInWei();
        l1CostWei = perL1CalldataUnit * s_storage.maxPerformDataSize * 16;
      }
    }
    // if it's not performing upkeeps, use gas ceiling multiplier to estimate the upper bound
    if (!isExecution) {
      l1CostWei = hotVars.gasCeilingMultiplier * l1CostWei;
    }
    // Divide l1CostWei among all batched upkeeps. Spare change from division is not charged
    l1CostWei = l1CostWei / numBatchedUpkeeps;

    uint256 gasPayment = ((gasWei * (gasLimit + gasOverhead) + l1CostWei) * 1e18) / linkNative;
    uint256 premium = (((gasWei * gasLimit) + l1CostWei) * 1e9 * hotVars.paymentPremiumPPB) /
      linkNative +
      uint256(hotVars.flatFeeMicroLink) *
      1e12;
    // LINK_TOTAL_SUPPLY < UINT96_MAX
    if (gasPayment + premium > LINK_TOTAL_SUPPLY) revert PaymentGreaterThanAllLINK();
    return (uint96(gasPayment), uint96(premium));
  }

  /**
   * @dev calculates the max LINK payment for an upkeep
   */
  function _getMaxLinkPayment(
    HotVars memory hotVars,
    Trigger triggerType,
    uint32 performGas,
    uint32 performDataLength,
    uint256 fastGasWei,
    uint256 linkNative,
    bool isExecution // Whether this is an actual perform execution or just a simulation
  ) internal view returns (uint96) {
    uint256 gasOverhead = _getMaxGasOverhead(triggerType, performDataLength, hotVars.f);
    (uint96 reimbursement, uint96 premium) = _calculatePaymentAmount(
      hotVars,
      performGas,
      gasOverhead,
      fastGasWei,
      linkNative,
      1, // Consider only 1 upkeep in batch to get maxPayment
      isExecution
    );

    return reimbursement + premium;
  }

  /**
   * @dev returns the max gas overhead that can be charged for an upkeep
   */
  function _getMaxGasOverhead(Trigger triggerType, uint32 performDataLength, uint8 f) internal pure returns (uint256) {
    // performData causes additional overhead in report length and memory operations
    uint256 baseOverhead;
    if (triggerType == Trigger.CONDITION) {
      baseOverhead = REGISTRY_CONDITIONAL_OVERHEAD;
    } else if (triggerType == Trigger.LOG) {
      baseOverhead = REGISTRY_LOG_OVERHEAD;
    } else {
      revert InvalidTriggerType();
    }
    return
      baseOverhead +
      (REGISTRY_PER_SIGNER_GAS_OVERHEAD * (f + 1)) +
      (REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD * performDataLength);
  }

  /**
   * @dev move a transmitter's balance from total pool to withdrawable balance
   */
  function _updateTransmitterBalanceFromPool(
    address transmitterAddress,
    uint96 totalPremium,
    uint96 payeeCount
  ) internal returns (uint96) {
    Transmitter memory transmitter = s_transmitters[transmitterAddress];

    if (transmitter.active) {
      uint96 uncollected = totalPremium - transmitter.lastCollected;
      uint96 due = uncollected / payeeCount;
      transmitter.balance += due;
      transmitter.lastCollected += due * payeeCount;
      s_transmitters[transmitterAddress] = transmitter;
    }

    return transmitter.balance;
  }

  /**
   * @dev gets the trigger type from an upkeepID (trigger type is encoded in the middle of the ID)
   */
  function _getTriggerType(uint256 upkeepId) internal pure returns (Trigger) {
    bytes32 rawID = bytes32(upkeepId);
    bytes1 empty = bytes1(0);
    for (uint256 idx = 4; idx < 15; idx++) {
      if (rawID[idx] != empty) {
        // old IDs that were created before this standard and migrated to this registry
        return Trigger.CONDITION;
      }
    }
    return Trigger(uint8(rawID[15]));
  }

  function _checkPayload(
    uint256 upkeepId,
    Trigger triggerType,
    bytes memory triggerData
  ) internal view returns (bytes memory) {
    if (triggerType == Trigger.CONDITION) {
      return abi.encodeWithSelector(CHECK_SELECTOR, s_checkData[upkeepId]);
    } else if (triggerType == Trigger.LOG) {
      Log memory log = abi.decode(triggerData, (Log));
      return abi.encodeWithSelector(CHECK_LOG_SELECTOR, log, s_checkData[upkeepId]);
    }
    revert InvalidTriggerType();
  }

  /**
   * @dev _decodeReport decodes a serialized report into a Report struct
   */
  function _decodeReport(bytes calldata rawReport) internal pure returns (Report memory) {
    Report memory report = abi.decode(rawReport, (Report));
    uint256 expectedLength = report.upkeepIds.length;
    if (
      report.gasLimits.length != expectedLength ||
      report.triggers.length != expectedLength ||
      report.performDatas.length != expectedLength
    ) {
      revert InvalidReport();
    }
    return report;
  }

  /**
   * @dev Does some early sanity checks before actually performing an upkeep
   * @return bool whether the upkeep should be performed
   * @return bytes32 dedupID for preventing duplicate performances of this trigger
   */
  function _prePerformChecks(
    uint256 upkeepId,
    bytes memory rawTrigger,
    UpkeepTransmitInfo memory transmitInfo
  ) internal returns (bool, bytes32) {
    bytes32 dedupID;
    if (transmitInfo.triggerType == Trigger.CONDITION) {
      if (!_validateConditionalTrigger(upkeepId, rawTrigger, transmitInfo)) return (false, dedupID);
    } else if (transmitInfo.triggerType == Trigger.LOG) {
      bool valid;
      (valid, dedupID) = _validateLogTrigger(upkeepId, rawTrigger, transmitInfo);
      if (!valid) return (false, dedupID);
    } else {
      revert InvalidTriggerType();
    }
    if (transmitInfo.upkeep.maxValidBlocknumber <= _blockNum()) {
      // Can happen when an upkeep got cancelled after report was generated.
      // However we have a CANCELLATION_DELAY of 50 blocks so shouldn't happen in practice
      emit CancelledUpkeepReport(upkeepId, rawTrigger);
      return (false, dedupID);
    }
    if (transmitInfo.upkeep.balance < transmitInfo.maxLinkPayment) {
      // Can happen due to fluctuations in gas / link prices
      emit InsufficientFundsUpkeepReport(upkeepId, rawTrigger);
      return (false, dedupID);
    }
    return (true, dedupID);
  }

  /**
   * @dev Does some early sanity checks before actually performing an upkeep
   */
  function _validateConditionalTrigger(
    uint256 upkeepId,
    bytes memory rawTrigger,
    UpkeepTransmitInfo memory transmitInfo
  ) internal returns (bool) {
    ConditionalTrigger memory trigger = abi.decode(rawTrigger, (ConditionalTrigger));
    if (trigger.blockNum < transmitInfo.upkeep.lastPerformedBlockNumber) {
      // Can happen when another report performed this upkeep after this report was generated
      emit StaleUpkeepReport(upkeepId, rawTrigger);
      return false;
    }
    if (
      (trigger.blockHash != bytes32("") && _blockHash(trigger.blockNum) != trigger.blockHash) ||
      trigger.blockNum >= _blockNum()
    ) {
      // There are two cases of reorged report
      // 1. trigger block number is in future: this is an edge case during extreme deep reorgs of chain
      // which is always protected against
      // 2. blockHash at trigger block number was same as trigger time. This is an optional check which is
      // applied if DON sends non empty trigger.blockHash. Note: It only works for last 256 blocks on chain
      // when it is sent
      emit ReorgedUpkeepReport(upkeepId, rawTrigger);
      return false;
    }
    return true;
  }

  function _validateLogTrigger(
    uint256 upkeepId,
    bytes memory rawTrigger,
    UpkeepTransmitInfo memory transmitInfo
  ) internal returns (bool, bytes32) {
    LogTrigger memory trigger = abi.decode(rawTrigger, (LogTrigger));
    bytes32 dedupID = keccak256(abi.encodePacked(upkeepId, trigger.logBlockHash, trigger.txHash, trigger.logIndex));
    if (
      (trigger.blockHash != bytes32("") && _blockHash(trigger.blockNum) != trigger.blockHash) ||
      trigger.blockNum >= _blockNum()
    ) {
      // Reorg protection is same as conditional trigger upkeeps
      emit ReorgedUpkeepReport(upkeepId, rawTrigger);
      return (false, dedupID);
    }
    if (s_dedupKeys[dedupID]) {
      emit StaleUpkeepReport(upkeepId, rawTrigger);
      return (false, dedupID);
    }
    return (true, dedupID);
  }

  /**
   * @dev Verify signatures attached to report
   */
  function _verifyReportSignature(
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs
  ) internal view {
    bytes32 h = keccak256(abi.encode(keccak256(report), reportContext));
    // i-th byte counts number of sigs made by i-th signer
    uint256 signedCount = 0;

    Signer memory signer;
    address signerAddress;
    for (uint256 i = 0; i < rs.length; i++) {
      signerAddress = ecrecover(h, uint8(rawVs[i]) + 27, rs[i], ss[i]);
      signer = s_signers[signerAddress];
      if (!signer.active) revert OnlyActiveSigners();
      unchecked {
        signedCount += 1 << (8 * signer.index);
      }
    }

    if (signedCount & ORACLE_MASK != signedCount) revert DuplicateSigners();
  }

  /**
   * @dev updates a storage marker for this upkeep to prevent duplicate and out of order performances
   * @dev for conditional triggers we set the latest block number, for log triggers we store a dedupID
   */
  function _updateTriggerMarker(uint256 upkeepID, UpkeepTransmitInfo memory upkeepTransmitInfo) internal {
    if (upkeepTransmitInfo.triggerType == Trigger.CONDITION) {
      s_upkeep[upkeepID].lastPerformedBlockNumber = uint32(_blockNum());
    } else if (upkeepTransmitInfo.triggerType == Trigger.LOG) {
      s_dedupKeys[upkeepTransmitInfo.dedupID] = true;
      emit DedupKeyAdded(upkeepTransmitInfo.dedupID);
    }
  }

  /**
   * @dev calls the Upkeep target with the performData param passed in by the
   * transmitter and the exact gas required by the Upkeep
   */
  function _performUpkeep(
    IAutomationForwarder forwarder,
    uint256 performGas,
    bytes memory performData
  ) internal nonReentrant returns (bool success, uint256 gasUsed) {
    performData = abi.encodeWithSelector(PERFORM_SELECTOR, performData);
    return forwarder.forward(performGas, performData);
  }

  /**
   * @dev does postPerform payment processing for an upkeep. Deducts upkeep's balance and increases
   * amount spent.
   */
  function _postPerformPayment(
    HotVars memory hotVars,
    uint256 upkeepId,
    UpkeepTransmitInfo memory upkeepTransmitInfo,
    uint256 fastGasWei,
    uint256 linkNative,
    uint16 numBatchedUpkeeps
  ) internal returns (uint96 gasReimbursement, uint96 premium) {
    (gasReimbursement, premium) = _calculatePaymentAmount(
      hotVars,
      upkeepTransmitInfo.gasUsed,
      upkeepTransmitInfo.gasOverhead,
      fastGasWei,
      linkNative,
      numBatchedUpkeeps,
      true
    );

    uint96 payment = gasReimbursement + premium;
    s_upkeep[upkeepId].balance -= payment;
    s_upkeep[upkeepId].amountSpent += payment;

    return (gasReimbursement, premium);
  }

  /**
   * @dev Caps the gas overhead by the constant overhead used within initial payment checks in order to
   * prevent a revert in payment processing.
   */
  function _getCappedGasOverhead(
    uint256 calculatedGasOverhead,
    Trigger triggerType,
    uint32 performDataLength,
    uint8 f
  ) internal pure returns (uint256 cappedGasOverhead) {
    cappedGasOverhead = _getMaxGasOverhead(triggerType, performDataLength, f);
    if (calculatedGasOverhead < cappedGasOverhead) {
      return calculatedGasOverhead;
    }
    return cappedGasOverhead;
  }

  /**
   * @dev ensures the upkeep is not cancelled and the caller is the upkeep admin
   */
  function _requireAdminAndNotCancelled(uint256 upkeepId) internal view {
    if (msg.sender != s_upkeepAdmin[upkeepId]) revert OnlyCallableByAdmin();
    if (s_upkeep[upkeepId].maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
  }

  /**
   * @dev returns the current block number in a chain agnostic manner
   */
  function _blockNum() internal view returns (uint256) {
    if (i_mode == Mode.ARBITRUM) {
      return ARB_SYS.arbBlockNumber();
    } else {
      return block.number;
    }
  }

  /**
   * @dev returns the blockhash of the provided block number in a chain agnostic manner
   * @param n the blocknumber to retrieve the blockhash for
   * @return blockhash the blockhash of block number n, or 0 if n is out queryable of range
   */
  function _blockHash(uint256 n) internal view returns (bytes32) {
    if (i_mode == Mode.ARBITRUM) {
      uint256 blockNum = ARB_SYS.arbBlockNumber();
      if (n >= blockNum || blockNum - n > 256) {
        return "";
      }
      return ARB_SYS.arbBlockHash(n);
    } else {
      return blockhash(n);
    }
  }

  /**
   * @dev replicates Open Zeppelin's ReentrancyGuard but optimized to fit our storage
   */
  modifier nonReentrant() {
    if (s_hotVars.reentrancyGuard) revert ReentrantCall();
    s_hotVars.reentrancyGuard = true;
    _;
    s_hotVars.reentrancyGuard = false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {EnumerableSet} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import {KeeperRegistryBase2_1} from "./KeeperRegistryBase2_1.sol";
import {KeeperRegistryLogicB2_1} from "./KeeperRegistryLogicB2_1.sol";
import {Chainable} from "./Chainable.sol";
import {AutomationForwarder} from "./AutomationForwarder.sol";
import {IAutomationForwarder} from "./interfaces/IAutomationForwarder.sol";
import {UpkeepTranscoderInterfaceV2} from "../../../automation/interfaces/UpkeepTranscoderInterfaceV2.sol";
import {MigratableKeeperRegistryInterfaceV2} from "../../../automation/interfaces/MigratableKeeperRegistryInterfaceV2.sol";

/**
 * @notice Logic contract, works in tandem with KeeperRegistry as a proxy
 */
contract KeeperRegistryLogicA2_1 is KeeperRegistryBase2_1, Chainable {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @param logicB the address of the second logic contract
   */
  constructor(
    KeeperRegistryLogicB2_1 logicB
  )
    KeeperRegistryBase2_1(
      logicB.getMode(),
      logicB.getLinkAddress(),
      logicB.getLinkNativeFeedAddress(),
      logicB.getFastGasFeedAddress(),
      logicB.getAutomationForwarderLogic()
    )
    Chainable(address(logicB))
  {}

  /**
   * @notice called by the automation DON to check if work is needed
   * @param id the upkeep ID to check for work needed
   * @param triggerData extra contextual data about the trigger (not used in all code paths)
   * @dev this one of the core functions called in the hot path
   * @dev there is a 2nd checkUpkeep function (below) that is being maintained for backwards compatibility
   * @dev there is an incongruency on what gets returned during failure modes
   * ex sometimes we include price data, sometimes we omit it depending on the failure
   */
  function checkUpkeep(
    uint256 id,
    bytes memory triggerData
  )
    public
    cannotExecute
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    Trigger triggerType = _getTriggerType(id);
    HotVars memory hotVars = s_hotVars;
    Upkeep memory upkeep = s_upkeep[id];

    if (hotVars.paused) return (false, bytes(""), UpkeepFailureReason.REGISTRY_PAUSED, 0, upkeep.performGas, 0, 0);
    if (upkeep.maxValidBlocknumber != UINT32_MAX)
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_CANCELLED, 0, upkeep.performGas, 0, 0);
    if (upkeep.paused) return (false, bytes(""), UpkeepFailureReason.UPKEEP_PAUSED, 0, upkeep.performGas, 0, 0);

    (fastGasWei, linkNative) = _getFeedData(hotVars);
    uint96 maxLinkPayment = _getMaxLinkPayment(
      hotVars,
      triggerType,
      upkeep.performGas,
      s_storage.maxPerformDataSize,
      fastGasWei,
      linkNative,
      false
    );
    if (upkeep.balance < maxLinkPayment) {
      return (false, bytes(""), UpkeepFailureReason.INSUFFICIENT_BALANCE, 0, upkeep.performGas, 0, 0);
    }

    bytes memory callData = _checkPayload(id, triggerType, triggerData);

    gasUsed = gasleft();
    (bool success, bytes memory result) = upkeep.forwarder.getTarget().call{gas: s_storage.checkGasLimit}(callData);
    gasUsed = gasUsed - gasleft();

    if (!success) {
      // User's target check reverted. We capture the revert data here and pass it within performData
      if (result.length > s_storage.maxRevertDataSize) {
        return (
          false,
          bytes(""),
          UpkeepFailureReason.REVERT_DATA_EXCEEDS_LIMIT,
          gasUsed,
          upkeep.performGas,
          fastGasWei,
          linkNative
        );
      }
      return (
        upkeepNeeded,
        result,
        UpkeepFailureReason.TARGET_CHECK_REVERTED,
        gasUsed,
        upkeep.performGas,
        fastGasWei,
        linkNative
      );
    }

    (upkeepNeeded, performData) = abi.decode(result, (bool, bytes));
    if (!upkeepNeeded)
      return (
        false,
        bytes(""),
        UpkeepFailureReason.UPKEEP_NOT_NEEDED,
        gasUsed,
        upkeep.performGas,
        fastGasWei,
        linkNative
      );

    if (performData.length > s_storage.maxPerformDataSize)
      return (
        false,
        bytes(""),
        UpkeepFailureReason.PERFORM_DATA_EXCEEDS_LIMIT,
        gasUsed,
        upkeep.performGas,
        fastGasWei,
        linkNative
      );

    return (upkeepNeeded, performData, upkeepFailureReason, gasUsed, upkeep.performGas, fastGasWei, linkNative);
  }

  /**
   * @notice see other checkUpkeep function for description
   * @dev this function may be deprecated in a future version of chainlink automation
   */
  function checkUpkeep(
    uint256 id
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData,
      UpkeepFailureReason upkeepFailureReason,
      uint256 gasUsed,
      uint256 gasLimit,
      uint256 fastGasWei,
      uint256 linkNative
    )
  {
    return checkUpkeep(id, bytes(""));
  }

  /**
   * @dev checkCallback is used specifically for automation data streams lookups (see StreamsLookupCompatibleInterface.sol)
   * @param id the upkeepID to execute a callback for
   * @param values the values returned from the data streams lookup
   * @param extraData the user-provided extra context data
   */
  function checkCallback(
    uint256 id,
    bytes[] memory values,
    bytes calldata extraData
  )
    external
    cannotExecute
    returns (bool upkeepNeeded, bytes memory performData, UpkeepFailureReason upkeepFailureReason, uint256 gasUsed)
  {
    bytes memory payload = abi.encodeWithSelector(CHECK_CALLBACK_SELECTOR, values, extraData);
    return executeCallback(id, payload);
  }

  /**
   * @notice this is a generic callback executor that forwards a call to a user's contract with the configured
   * gas limit
   * @param id the upkeepID to execute a callback for
   * @param payload the data (including function selector) to call on the upkeep target contract
   */
  function executeCallback(
    uint256 id,
    bytes memory payload
  )
    public
    cannotExecute
    returns (bool upkeepNeeded, bytes memory performData, UpkeepFailureReason upkeepFailureReason, uint256 gasUsed)
  {
    Upkeep memory upkeep = s_upkeep[id];
    gasUsed = gasleft();
    (bool success, bytes memory result) = upkeep.forwarder.getTarget().call{gas: s_storage.checkGasLimit}(payload);
    gasUsed = gasUsed - gasleft();
    if (!success) {
      return (false, bytes(""), UpkeepFailureReason.CALLBACK_REVERTED, gasUsed);
    }
    (upkeepNeeded, performData) = abi.decode(result, (bool, bytes));
    if (!upkeepNeeded) {
      return (false, bytes(""), UpkeepFailureReason.UPKEEP_NOT_NEEDED, gasUsed);
    }
    if (performData.length > s_storage.maxPerformDataSize) {
      return (false, bytes(""), UpkeepFailureReason.PERFORM_DATA_EXCEEDS_LIMIT, gasUsed);
    }
    return (upkeepNeeded, performData, upkeepFailureReason, gasUsed);
  }

  /**
   * @notice adds a new upkeep
   * @param target address to perform upkeep on
   * @param gasLimit amount of gas to provide the target contract when
   * performing upkeep
   * @param admin address to cancel upkeep and withdraw remaining funds
   * @param triggerType the trigger for the upkeep
   * @param checkData data passed to the contract when checking for upkeep
   * @param triggerConfig the config for the trigger
   * @param offchainConfig arbitrary offchain config for the upkeep
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    Trigger triggerType,
    bytes calldata checkData,
    bytes memory triggerConfig,
    bytes memory offchainConfig
  ) public returns (uint256 id) {
    if (msg.sender != owner() && !s_registrars.contains(msg.sender)) revert OnlyCallableByOwnerOrRegistrar();
    if (!target.isContract()) revert NotAContract();
    id = _createID(triggerType);
    IAutomationForwarder forwarder = IAutomationForwarder(
      address(new AutomationForwarder(target, address(this), i_automationForwarderLogic))
    );
    _createUpkeep(
      id,
      Upkeep({
        performGas: gasLimit,
        balance: 0,
        maxValidBlocknumber: UINT32_MAX,
        lastPerformedBlockNumber: 0,
        amountSpent: 0,
        paused: false,
        forwarder: forwarder
      }),
      admin,
      checkData,
      triggerConfig,
      offchainConfig
    );
    s_storage.nonce++;
    emit UpkeepRegistered(id, gasLimit, admin);
    emit UpkeepCheckDataSet(id, checkData);
    emit UpkeepTriggerConfigSet(id, triggerConfig);
    emit UpkeepOffchainConfigSet(id, offchainConfig);
    return (id);
  }

  /**
   * @notice this function registers a conditional upkeep, using a backwards compatible function signature
   * @dev this function is backwards compatible with versions <=2.0, but may be removed in a future version
   */
  function registerUpkeep(
    address target,
    uint32 gasLimit,
    address admin,
    bytes calldata checkData,
    bytes calldata offchainConfig
  ) external returns (uint256 id) {
    return registerUpkeep(target, gasLimit, admin, Trigger.CONDITION, checkData, bytes(""), offchainConfig);
  }

  /**
   * @notice cancels an upkeep
   * @param id the upkeepID to cancel
   * @dev if a user cancels an upkeep, their funds are locked for CANCELLATION_DELAY blocks to
   * allow any pending performUpkeep txs time to get confirmed
   */
  function cancelUpkeep(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    bool canceled = upkeep.maxValidBlocknumber != UINT32_MAX;
    bool isOwner = msg.sender == owner();

    if (canceled && !(isOwner && upkeep.maxValidBlocknumber > _blockNum())) revert CannotCancel();
    if (!isOwner && msg.sender != s_upkeepAdmin[id]) revert OnlyCallableByOwnerOrAdmin();

    uint256 height = _blockNum();
    if (!isOwner) {
      height = height + CANCELLATION_DELAY;
    }
    s_upkeep[id].maxValidBlocknumber = uint32(height);
    s_upkeepIDs.remove(id);

    // charge the cancellation fee if the minUpkeepSpend is not met
    uint96 minUpkeepSpend = s_storage.minUpkeepSpend;
    uint96 cancellationFee = 0;
    // cancellationFee is supposed to be min(max(minUpkeepSpend - amountSpent,0), amountLeft)
    if (upkeep.amountSpent < minUpkeepSpend) {
      cancellationFee = minUpkeepSpend - upkeep.amountSpent;
      if (cancellationFee > upkeep.balance) {
        cancellationFee = upkeep.balance;
      }
    }
    s_upkeep[id].balance = upkeep.balance - cancellationFee;
    s_storage.ownerLinkBalance = s_storage.ownerLinkBalance + cancellationFee;

    emit UpkeepCanceled(id, uint64(height));
  }

  /**
   * @notice adds fund to an upkeep
   * @param id the upkeepID
   * @param amount the amount of LINK to fund, in jules (jules = "wei" of LINK)
   */
  function addFunds(uint256 id, uint96 amount) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
    s_upkeep[id].balance = upkeep.balance + amount;
    s_expectedLinkBalance = s_expectedLinkBalance + amount;
    i_link.transferFrom(msg.sender, address(this), amount);
    emit FundsAdded(id, msg.sender, amount);
  }

  /**
   * @notice migrates upkeeps from one registry to another
   * @param ids the upkeepIDs to migrate
   * @param destination the destination registry address
   * @dev a transcoder must be set in order to enable migration
   * @dev migration permissions must be set on *both* sending and receiving registries
   * @dev only an upkeep admin can migrate their upkeeps
   */
  function migrateUpkeeps(uint256[] calldata ids, address destination) external {
    if (
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.OUTGOING &&
      s_peerRegistryMigrationPermission[destination] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    if (s_storage.transcoder == ZERO_ADDRESS) revert TranscoderNotSet();
    if (ids.length == 0) revert ArrayHasNoEntries();
    uint256 id;
    Upkeep memory upkeep;
    uint256 totalBalanceRemaining;
    address[] memory admins = new address[](ids.length);
    Upkeep[] memory upkeeps = new Upkeep[](ids.length);
    bytes[] memory checkDatas = new bytes[](ids.length);
    bytes[] memory triggerConfigs = new bytes[](ids.length);
    bytes[] memory offchainConfigs = new bytes[](ids.length);
    for (uint256 idx = 0; idx < ids.length; idx++) {
      id = ids[idx];
      upkeep = s_upkeep[id];
      _requireAdminAndNotCancelled(id);
      upkeep.forwarder.updateRegistry(destination);
      upkeeps[idx] = upkeep;
      admins[idx] = s_upkeepAdmin[id];
      checkDatas[idx] = s_checkData[id];
      triggerConfigs[idx] = s_upkeepTriggerConfig[id];
      offchainConfigs[idx] = s_upkeepOffchainConfig[id];
      totalBalanceRemaining = totalBalanceRemaining + upkeep.balance;
      delete s_upkeep[id];
      delete s_checkData[id];
      delete s_upkeepTriggerConfig[id];
      delete s_upkeepOffchainConfig[id];
      // nullify existing proposed admin change if an upkeep is being migrated
      delete s_proposedAdmin[id];
      s_upkeepIDs.remove(id);
      emit UpkeepMigrated(id, upkeep.balance, destination);
    }
    s_expectedLinkBalance = s_expectedLinkBalance - totalBalanceRemaining;
    bytes memory encodedUpkeeps = abi.encode(
      ids,
      upkeeps,
      new address[](ids.length),
      admins,
      checkDatas,
      triggerConfigs,
      offchainConfigs
    );
    MigratableKeeperRegistryInterfaceV2(destination).receiveUpkeeps(
      UpkeepTranscoderInterfaceV2(s_storage.transcoder).transcodeUpkeeps(
        UPKEEP_VERSION_BASE,
        MigratableKeeperRegistryInterfaceV2(destination).upkeepVersion(),
        encodedUpkeeps
      )
    );
    i_link.transfer(destination, totalBalanceRemaining);
  }

  /**
   * @notice received upkeeps migrated from another registry
   * @param encodedUpkeeps the raw upkeep data to import
   * @dev this function is never called directly, it is only called by another registry's migrate function
   */
  function receiveUpkeeps(bytes calldata encodedUpkeeps) external {
    if (
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.INCOMING &&
      s_peerRegistryMigrationPermission[msg.sender] != MigrationPermission.BIDIRECTIONAL
    ) revert MigrationNotPermitted();
    (
      uint256[] memory ids,
      Upkeep[] memory upkeeps,
      address[] memory targets,
      address[] memory upkeepAdmins,
      bytes[] memory checkDatas,
      bytes[] memory triggerConfigs,
      bytes[] memory offchainConfigs
    ) = abi.decode(encodedUpkeeps, (uint256[], Upkeep[], address[], address[], bytes[], bytes[], bytes[]));
    for (uint256 idx = 0; idx < ids.length; idx++) {
      if (address(upkeeps[idx].forwarder) == ZERO_ADDRESS) {
        upkeeps[idx].forwarder = IAutomationForwarder(
          address(new AutomationForwarder(targets[idx], address(this), i_automationForwarderLogic))
        );
      }
      _createUpkeep(
        ids[idx],
        upkeeps[idx],
        upkeepAdmins[idx],
        checkDatas[idx],
        triggerConfigs[idx],
        offchainConfigs[idx]
      );
      emit UpkeepReceived(ids[idx], upkeeps[idx].balance, msg.sender);
    }
  }

  /**
   * @notice sets the upkeep trigger config
   * @param id the upkeepID to change the trigger for
   * @param triggerConfig the new trigger config
   */
  function setUpkeepTriggerConfig(uint256 id, bytes calldata triggerConfig) external {
    _requireAdminAndNotCancelled(id);
    s_upkeepTriggerConfig[id] = triggerConfig;
    emit UpkeepTriggerConfigSet(id, triggerConfig);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {KeeperRegistryBase2_1} from "./KeeperRegistryBase2_1.sol";
import {EnumerableSet} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import {Address} from "../../../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/Address.sol";
import {UpkeepFormat} from "../../../automation/interfaces/UpkeepTranscoderInterface.sol";
import {IAutomationForwarder} from "./interfaces/IAutomationForwarder.sol";

contract KeeperRegistryLogicB2_1 is KeeperRegistryBase2_1 {
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableSet for EnumerableSet.AddressSet;

  /**
   * @dev see KeeperRegistry master contract for constructor description
   */
  constructor(
    Mode mode,
    address link,
    address linkNativeFeed,
    address fastGasFeed,
    address automationForwarderLogic
  ) KeeperRegistryBase2_1(mode, link, linkNativeFeed, fastGasFeed, automationForwarderLogic) {}

  // ================================================================
  // |                      UPKEEP MANAGEMENT                       |
  // ================================================================

  /**
   * @notice transfers the address of an admin for an upkeep
   */
  function transferUpkeepAdmin(uint256 id, address proposed) external {
    _requireAdminAndNotCancelled(id);
    if (proposed == msg.sender) revert ValueNotChanged();

    if (s_proposedAdmin[id] != proposed) {
      s_proposedAdmin[id] = proposed;
      emit UpkeepAdminTransferRequested(id, msg.sender, proposed);
    }
  }

  /**
   * @notice accepts the transfer of an upkeep admin
   */
  function acceptUpkeepAdmin(uint256 id) external {
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.maxValidBlocknumber != UINT32_MAX) revert UpkeepCancelled();
    if (s_proposedAdmin[id] != msg.sender) revert OnlyCallableByProposedAdmin();
    address past = s_upkeepAdmin[id];
    s_upkeepAdmin[id] = msg.sender;
    s_proposedAdmin[id] = ZERO_ADDRESS;

    emit UpkeepAdminTransferred(id, past, msg.sender);
  }

  /**
   * @notice pauses an upkeep - an upkeep will be neither checked nor performed while paused
   */
  function pauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (upkeep.paused) revert OnlyUnpausedUpkeep();
    s_upkeep[id].paused = true;
    s_upkeepIDs.remove(id);
    emit UpkeepPaused(id);
  }

  /**
   * @notice unpauses an upkeep
   */
  function unpauseUpkeep(uint256 id) external {
    _requireAdminAndNotCancelled(id);
    Upkeep memory upkeep = s_upkeep[id];
    if (!upkeep.paused) revert OnlyPausedUpkeep();
    s_upkeep[id].paused = false;
    s_upkeepIDs.add(id);
    emit UpkeepUnpaused(id);
  }

  /**
   * @notice updates the checkData for an upkeep
   */
  function setUpkeepCheckData(uint256 id, bytes calldata newCheckData) external {
    _requireAdminAndNotCancelled(id);
    if (newCheckData.length > s_storage.maxCheckDataSize) revert CheckDataExceedsLimit();
    s_checkData[id] = newCheckData;
    emit UpkeepCheckDataSet(id, newCheckData);
  }

  /**
   * @notice updates the gas limit for an upkeep
   */
  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external {
    if (gasLimit < PERFORM_GAS_MIN || gasLimit > s_storage.maxPerformGas) revert GasLimitOutsideRange();
    _requireAdminAndNotCancelled(id);
    s_upkeep[id].performGas = gasLimit;

    emit UpkeepGasLimitSet(id, gasLimit);
  }

  /**
   * @notice updates the offchain config for an upkeep
   */
  function setUpkeepOffchainConfig(uint256 id, bytes calldata config) external {
    _requireAdminAndNotCancelled(id);
    s_upkeepOffchainConfig[id] = config;
    emit UpkeepOffchainConfigSet(id, config);
  }

  /**
   * @notice withdraws LINK funds from an upkeep
   * @dev note that an upkeep must be cancelled first!!
   */
  function withdrawFunds(uint256 id, address to) external nonReentrant {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    Upkeep memory upkeep = s_upkeep[id];
    if (s_upkeepAdmin[id] != msg.sender) revert OnlyCallableByAdmin();
    if (upkeep.maxValidBlocknumber > _blockNum()) revert UpkeepNotCanceled();
    uint96 amountToWithdraw = s_upkeep[id].balance;
    s_expectedLinkBalance = s_expectedLinkBalance - amountToWithdraw;
    s_upkeep[id].balance = 0;
    i_link.transfer(to, amountToWithdraw);
    emit FundsWithdrawn(id, amountToWithdraw, to);
  }

  // ================================================================
  // |                       NODE MANAGEMENT                        |
  // ================================================================

  /**
   * @notice transfers the address of payee for a transmitter
   */
  function transferPayeeship(address transmitter, address proposed) external {
    if (s_transmitterPayees[transmitter] != msg.sender) revert OnlyCallableByPayee();
    if (proposed == msg.sender) revert ValueNotChanged();

    if (s_proposedPayee[transmitter] != proposed) {
      s_proposedPayee[transmitter] = proposed;
      emit PayeeshipTransferRequested(transmitter, msg.sender, proposed);
    }
  }

  /**
   * @notice accepts the transfer of the payee
   */
  function acceptPayeeship(address transmitter) external {
    if (s_proposedPayee[transmitter] != msg.sender) revert OnlyCallableByProposedPayee();
    address past = s_transmitterPayees[transmitter];
    s_transmitterPayees[transmitter] = msg.sender;
    s_proposedPayee[transmitter] = ZERO_ADDRESS;

    emit PayeeshipTransferred(transmitter, past, msg.sender);
  }

  /**
   * @notice withdraws LINK received as payment for work performed
   */
  function withdrawPayment(address from, address to) external {
    if (to == ZERO_ADDRESS) revert InvalidRecipient();
    if (s_transmitterPayees[from] != msg.sender) revert OnlyCallableByPayee();
    uint96 balance = _updateTransmitterBalanceFromPool(from, s_hotVars.totalPremium, uint96(s_transmittersList.length));
    s_transmitters[from].balance = 0;
    s_expectedLinkBalance = s_expectedLinkBalance - balance;
    i_link.transfer(to, balance);
    emit PaymentWithdrawn(from, balance, to, msg.sender);
  }

  // ================================================================
  // |                   OWNER / MANAGER ACTIONS                    |
  // ================================================================

  /**
   * @notice sets the privilege config for an upkeep
   */
  function setUpkeepPrivilegeConfig(uint256 upkeepId, bytes calldata newPrivilegeConfig) external {
    if (msg.sender != s_storage.upkeepPrivilegeManager) {
      revert OnlyCallableByUpkeepPrivilegeManager();
    }
    s_upkeepPrivilegeConfig[upkeepId] = newPrivilegeConfig;
    emit UpkeepPrivilegeConfigSet(upkeepId, newPrivilegeConfig);
  }

  /**
   * @notice withdraws the owner's LINK balance
   */
  function withdrawOwnerFunds() external onlyOwner {
    uint96 amount = s_storage.ownerLinkBalance;
    s_expectedLinkBalance = s_expectedLinkBalance - amount;
    s_storage.ownerLinkBalance = 0;
    emit OwnerFundsWithdrawn(amount);
    i_link.transfer(msg.sender, amount);
  }

  /**
   * @notice allows the owner to withdraw any LINK accidentally sent to the contract
   */
  function recoverFunds() external onlyOwner {
    uint256 total = i_link.balanceOf(address(this));
    i_link.transfer(msg.sender, total - s_expectedLinkBalance);
  }

  /**
   * @notice sets the payees for the transmitters
   */
  function setPayees(address[] calldata payees) external onlyOwner {
    if (s_transmittersList.length != payees.length) revert ParameterLengthError();
    for (uint256 i = 0; i < s_transmittersList.length; i++) {
      address transmitter = s_transmittersList[i];
      address oldPayee = s_transmitterPayees[transmitter];
      address newPayee = payees[i];
      if (
        (newPayee == ZERO_ADDRESS) || (oldPayee != ZERO_ADDRESS && oldPayee != newPayee && newPayee != IGNORE_ADDRESS)
      ) revert InvalidPayee();
      if (newPayee != IGNORE_ADDRESS) {
        s_transmitterPayees[transmitter] = newPayee;
      }
    }
    emit PayeesUpdated(s_transmittersList, payees);
  }

  /**
   * @notice sets the migration permission for a peer registry
   * @dev this must be done before upkeeps can be migrated to/from another registry
   */
  function setPeerRegistryMigrationPermission(address peer, MigrationPermission permission) external onlyOwner {
    s_peerRegistryMigrationPermission[peer] = permission;
  }

  /**
   * @notice pauses the entire registry
   */
  function pause() external onlyOwner {
    s_hotVars.paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @notice unpauses the entire registry
   */
  function unpause() external onlyOwner {
    s_hotVars.paused = false;
    emit Unpaused(msg.sender);
  }

  /**
   * @notice sets a generic bytes field used to indicate the privilege that this admin address had
   * @param admin the address to set privilege for
   * @param newPrivilegeConfig the privileges that this admin has
   */
  function setAdminPrivilegeConfig(address admin, bytes calldata newPrivilegeConfig) external {
    if (msg.sender != s_storage.upkeepPrivilegeManager) {
      revert OnlyCallableByUpkeepPrivilegeManager();
    }
    s_adminPrivilegeConfig[admin] = newPrivilegeConfig;
    emit AdminPrivilegeConfigSet(admin, newPrivilegeConfig);
  }

  // ================================================================
  // |                           GETTERS                            |
  // ================================================================

  function getConditionalGasOverhead() external pure returns (uint256) {
    return REGISTRY_CONDITIONAL_OVERHEAD;
  }

  function getLogGasOverhead() external pure returns (uint256) {
    return REGISTRY_LOG_OVERHEAD;
  }

  function getPerPerformByteGasOverhead() external pure returns (uint256) {
    return REGISTRY_PER_PERFORM_BYTE_GAS_OVERHEAD;
  }

  function getPerSignerGasOverhead() external pure returns (uint256) {
    return REGISTRY_PER_SIGNER_GAS_OVERHEAD;
  }

  function getCancellationDelay() external pure returns (uint256) {
    return CANCELLATION_DELAY;
  }

  function getMode() external view returns (Mode) {
    return i_mode;
  }

  function getLinkAddress() external view returns (address) {
    return address(i_link);
  }

  function getLinkNativeFeedAddress() external view returns (address) {
    return address(i_linkNativeFeed);
  }

  function getFastGasFeedAddress() external view returns (address) {
    return address(i_fastGasFeed);
  }

  function getAutomationForwarderLogic() external view returns (address) {
    return i_automationForwarderLogic;
  }

  function upkeepTranscoderVersion() public pure returns (UpkeepFormat) {
    return UPKEEP_TRANSCODER_VERSION_BASE;
  }

  function upkeepVersion() public pure returns (uint8) {
    return UPKEEP_VERSION_BASE;
  }

  /**
   * @notice read all of the details about an upkeep
   * @dev this function may be deprecated in a future version of automation in favor of individual
   * getters for each field
   */
  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo) {
    Upkeep memory reg = s_upkeep[id];
    address target = address(reg.forwarder) == address(0) ? address(0) : reg.forwarder.getTarget();
    upkeepInfo = UpkeepInfo({
      target: target,
      performGas: reg.performGas,
      checkData: s_checkData[id],
      balance: reg.balance,
      admin: s_upkeepAdmin[id],
      maxValidBlocknumber: reg.maxValidBlocknumber,
      lastPerformedBlockNumber: reg.lastPerformedBlockNumber,
      amountSpent: reg.amountSpent,
      paused: reg.paused,
      offchainConfig: s_upkeepOffchainConfig[id]
    });
    return upkeepInfo;
  }

  /**
   * @notice retrieve active upkeep IDs. Active upkeep is defined as an upkeep which is not paused and not canceled.
   * @param startIndex starting index in list
   * @param maxCount max count to retrieve (0 = unlimited)
   * @dev the order of IDs in the list is **not guaranteed**, therefore, if making successive calls, one
   * should consider keeping the blockheight constant to ensure a holistic picture of the contract state
   */
  function getActiveUpkeepIDs(uint256 startIndex, uint256 maxCount) external view returns (uint256[] memory) {
    uint256 numUpkeeps = s_upkeepIDs.length();
    if (startIndex >= numUpkeeps) revert IndexOutOfRange();
    uint256 endIndex = startIndex + maxCount;
    endIndex = endIndex > numUpkeeps || maxCount == 0 ? numUpkeeps : endIndex;
    uint256[] memory ids = new uint256[](endIndex - startIndex);
    for (uint256 idx = 0; idx < ids.length; idx++) {
      ids[idx] = s_upkeepIDs.at(idx + startIndex);
    }
    return ids;
  }

  /**
   * @notice returns the upkeep's trigger type
   */
  function getTriggerType(uint256 upkeepId) external pure returns (Trigger) {
    return _getTriggerType(upkeepId);
  }

  /**
   * @notice returns the trigger config for an upkeeep
   */
  function getUpkeepTriggerConfig(uint256 upkeepId) public view returns (bytes memory) {
    return s_upkeepTriggerConfig[upkeepId];
  }

  /**
   * @notice read the current info about any transmitter address
   */
  function getTransmitterInfo(
    address query
  ) external view returns (bool active, uint8 index, uint96 balance, uint96 lastCollected, address payee) {
    Transmitter memory transmitter = s_transmitters[query];

    uint96 pooledShare = 0;
    if (transmitter.active) {
      uint96 totalDifference = s_hotVars.totalPremium - transmitter.lastCollected;
      pooledShare = totalDifference / uint96(s_transmittersList.length);
    }

    return (
      transmitter.active,
      transmitter.index,
      (transmitter.balance + pooledShare),
      transmitter.lastCollected,
      s_transmitterPayees[query]
    );
  }

  /**
   * @notice read the current info about any signer address
   */
  function getSignerInfo(address query) external view returns (bool active, uint8 index) {
    Signer memory signer = s_signers[query];
    return (signer.active, signer.index);
  }

  /**
   * @notice read the current state of the registry
   */
  function getState()
    external
    view
    returns (
      State memory state,
      OnchainConfig memory config,
      address[] memory signers,
      address[] memory transmitters,
      uint8 f
    )
  {
    state = State({
      nonce: s_storage.nonce,
      ownerLinkBalance: s_storage.ownerLinkBalance,
      expectedLinkBalance: s_expectedLinkBalance,
      totalPremium: s_hotVars.totalPremium,
      numUpkeeps: s_upkeepIDs.length(),
      configCount: s_storage.configCount,
      latestConfigBlockNumber: s_storage.latestConfigBlockNumber,
      latestConfigDigest: s_latestConfigDigest,
      latestEpoch: s_hotVars.latestEpoch,
      paused: s_hotVars.paused
    });

    config = OnchainConfig({
      paymentPremiumPPB: s_hotVars.paymentPremiumPPB,
      flatFeeMicroLink: s_hotVars.flatFeeMicroLink,
      checkGasLimit: s_storage.checkGasLimit,
      stalenessSeconds: s_hotVars.stalenessSeconds,
      gasCeilingMultiplier: s_hotVars.gasCeilingMultiplier,
      minUpkeepSpend: s_storage.minUpkeepSpend,
      maxPerformGas: s_storage.maxPerformGas,
      maxCheckDataSize: s_storage.maxCheckDataSize,
      maxPerformDataSize: s_storage.maxPerformDataSize,
      maxRevertDataSize: s_storage.maxRevertDataSize,
      fallbackGasPrice: s_fallbackGasPrice,
      fallbackLinkPrice: s_fallbackLinkPrice,
      transcoder: s_storage.transcoder,
      registrars: s_registrars.values(),
      upkeepPrivilegeManager: s_storage.upkeepPrivilegeManager
    });

    return (state, config, s_signersList, s_transmittersList, s_hotVars.f);
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   * @param id the upkeep id to calculate minimum balance for
   */
  function getBalance(uint256 id) external view returns (uint96 balance) {
    return s_upkeep[id].balance;
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   * @param id the upkeep id to calculate minimum balance for
   */
  function getMinBalance(uint256 id) external view returns (uint96) {
    return getMinBalanceForUpkeep(id);
  }

  /**
   * @notice calculates the minimum balance required for an upkeep to remain eligible
   * @param id the upkeep id to calculate minimum balance for
   * @dev this will be deprecated in a future version in favor of getMinBalance
   */
  function getMinBalanceForUpkeep(uint256 id) public view returns (uint96 minBalance) {
    return getMaxPaymentForGas(_getTriggerType(id), s_upkeep[id].performGas);
  }

  /**
   * @notice calculates the maximum payment for a given gas limit
   * @param gasLimit the gas to calculate payment for
   */
  function getMaxPaymentForGas(Trigger triggerType, uint32 gasLimit) public view returns (uint96 maxPayment) {
    HotVars memory hotVars = s_hotVars;
    (uint256 fastGasWei, uint256 linkNative) = _getFeedData(hotVars);
    return
      _getMaxLinkPayment(hotVars, triggerType, gasLimit, s_storage.maxPerformDataSize, fastGasWei, linkNative, false);
  }

  /**
   * @notice retrieves the migration permission for a peer registry
   */
  function getPeerRegistryMigrationPermission(address peer) external view returns (MigrationPermission) {
    return s_peerRegistryMigrationPermission[peer];
  }

  /**
   * @notice returns the upkeep privilege config
   */
  function getUpkeepPrivilegeConfig(uint256 upkeepId) external view returns (bytes memory) {
    return s_upkeepPrivilegeConfig[upkeepId];
  }

  /**
   * @notice returns the upkeep privilege config
   */
  function getAdminPrivilegeConfig(address admin) external view returns (bytes memory) {
    return s_adminPrivilegeConfig[admin];
  }

  /**
   * @notice returns the upkeep's forwarder contract
   */
  function getForwarder(uint256 upkeepID) external view returns (IAutomationForwarder) {
    return s_upkeep[upkeepID].forwarder;
  }

  /**
   * @notice returns the upkeep's forwarder contract
   */
  function hasDedupKey(bytes32 dedupKey) external view returns (bool) {
    return s_dedupKeys[dedupKey];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/IAutomationRegistryConsumer.sol";

contract MockKeeperRegistry2_1 is IAutomationRegistryConsumer {
  uint96 balance;
  uint96 minBalance;

  constructor() {}

  function getBalance(uint256 id) external view override returns (uint96) {
    return balance;
  }

  function getMinBalance(uint256 id) external view override returns (uint96) {
    return minBalance;
  }

  function cancelUpkeep(uint256 id) external override {}

  function pauseUpkeep(uint256 id) external override {}

  function unpauseUpkeep(uint256 id) external override {}

  function updateCheckData(uint256 id, bytes calldata newCheckData) external {}

  function addFunds(uint256 id, uint96 amount) external override {}

  function withdrawFunds(uint256 id, address to) external override {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract UpkeepCounter {
  event PerformingUpkeep(
    address indexed from,
    uint256 initialBlock,
    uint256 lastBlock,
    uint256 previousBlock,
    uint256 counter
  );

  uint256 public testRange;
  uint256 public interval;
  uint256 public lastBlock;
  uint256 public previousPerformBlock;
  uint256 public initialBlock;
  uint256 public counter;

  constructor(uint256 _testRange, uint256 _interval) {
    testRange = _testRange;
    interval = _interval;
    previousPerformBlock = 0;
    lastBlock = block.number;
    initialBlock = 0;
    counter = 0;
  }

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    return (eligible(), data);
  }

  function performUpkeep(bytes calldata performData) external {
    if (initialBlock == 0) {
      initialBlock = block.number;
    }
    lastBlock = block.number;
    counter = counter + 1;
    performData;
    emit PerformingUpkeep(tx.origin, initialBlock, lastBlock, previousPerformBlock, counter);
    previousPerformBlock = lastBlock;
  }

  function eligible() public view returns (bool) {
    if (initialBlock == 0) {
      return true;
    }

    return (block.number - initialBlock) < testRange && (block.number - lastBlock) >= interval;
  }

  function setSpread(uint256 _testRange, uint256 _interval) external {
    testRange = _testRange;
    interval = _interval;
    initialBlock = 0;
    counter = 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract StructFactory {
  address internal OWNER;
  address internal constant STRANGER = address(999);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {UpkeepTranscoderInterfaceV2} from "../../../automation/interfaces/UpkeepTranscoderInterfaceV2.sol";
import {TypeAndVersionInterface} from "../../../interfaces/TypeAndVersionInterface.sol";
import {KeeperRegistryBase2_1 as R21} from "./KeeperRegistryBase2_1.sol";
import {IAutomationForwarder} from "./interfaces/IAutomationForwarder.sol";
import {AutomationRegistryBaseInterface, UpkeepInfo} from "../../../automation/interfaces/2_0/AutomationRegistryInterface2_0.sol";

enum RegistryVersion {
  V12,
  V13,
  V20,
  V21
}

/**
 * @dev structs copied directly from source (can't import without changing the contract version)
 */
struct UpkeepV12 {
  uint96 balance;
  address lastKeeper;
  uint32 executeGas;
  uint64 maxValidBlocknumber;
  address target;
  uint96 amountSpent;
  address admin;
}

struct UpkeepV13 {
  uint96 balance;
  address lastKeeper;
  uint96 amountSpent;
  address admin;
  uint32 executeGas;
  uint32 maxValidBlocknumber;
  address target;
  bool paused;
}

struct UpkeepV20 {
  uint32 executeGas;
  uint32 maxValidBlocknumber;
  bool paused;
  address target;
  uint96 amountSpent;
  uint96 balance;
  uint32 lastPerformedBlockNumber;
}

/**
 * @notice UpkeepTranscoder allows converting upkeep data from previous keeper registry versions 1.2, 1.3, and
 * 2.0 to registry 2.1
 */
contract UpkeepTranscoder4_0 is UpkeepTranscoderInterfaceV2, TypeAndVersionInterface {
  error InvalidTranscoding();

  /**
   * @notice versions:
   * - UpkeepTranscoder 4.0.0: adds support for registry 2.1; adds support for offchainConfigs
   * - UpkeepTranscoder 3.0.0: works with registry 2.0; adds temporary workaround for UpkeepFormat enum bug
   */
  string public constant override typeAndVersion = "UpkeepTranscoder 4.0.0";
  uint32 internal constant UINT32_MAX = type(uint32).max;
  IAutomationForwarder internal constant ZERO_FORWARDER = IAutomationForwarder(address(0));

  /**
   * @notice transcodeUpkeeps transforms upkeep data from the format expected by
   * one registry to the format expected by another. It future-proofs migrations
   * by allowing keepers team to customize migration paths and set sensible defaults
   * when new fields are added
   * @param fromVersion struct version the upkeep is migrating from
   * @param encodedUpkeeps encoded upkeep data
   * @dev this transcoder should ONLY be use for V1/V2 --> V3 migrations
   * @dev this transcoder **ignores** the toVersion param, as it assumes all migrations are
   * for the V3 version. Therefore, it is the responsibility of the deployer of this contract
   * to ensure it is not used in any other migration paths.
   */
  function transcodeUpkeeps(
    uint8 fromVersion,
    uint8,
    bytes calldata encodedUpkeeps
  ) external view override returns (bytes memory) {
    // v1.2 => v2.1
    if (fromVersion == uint8(RegistryVersion.V12)) {
      (uint256[] memory ids, UpkeepV12[] memory upkeepsV12, bytes[] memory checkDatas) = abi.decode(
        encodedUpkeeps,
        (uint256[], UpkeepV12[], bytes[])
      );
      if (ids.length != upkeepsV12.length || ids.length != checkDatas.length) {
        revert InvalidTranscoding();
      }
      address[] memory targets = new address[](ids.length);
      address[] memory admins = new address[](ids.length);
      R21.Upkeep[] memory newUpkeeps = new R21.Upkeep[](ids.length);
      UpkeepV12 memory upkeepV12;
      for (uint256 idx = 0; idx < ids.length; idx++) {
        upkeepV12 = upkeepsV12[idx];
        newUpkeeps[idx] = R21.Upkeep({
          performGas: upkeepV12.executeGas,
          maxValidBlocknumber: UINT32_MAX, // maxValidBlocknumber is uint64 in V1, hence a new default value is provided
          paused: false, // migrated upkeeps are not paused by default
          forwarder: ZERO_FORWARDER,
          amountSpent: upkeepV12.amountSpent,
          balance: upkeepV12.balance,
          lastPerformedBlockNumber: 0
        });
        targets[idx] = upkeepV12.target;
        admins[idx] = upkeepV12.admin;
      }
      return abi.encode(ids, newUpkeeps, targets, admins, checkDatas, new bytes[](ids.length), new bytes[](ids.length));
    }
    // v1.3 => v2.1
    if (fromVersion == uint8(RegistryVersion.V13)) {
      (uint256[] memory ids, UpkeepV13[] memory upkeepsV13, bytes[] memory checkDatas) = abi.decode(
        encodedUpkeeps,
        (uint256[], UpkeepV13[], bytes[])
      );
      if (ids.length != upkeepsV13.length || ids.length != checkDatas.length) {
        revert InvalidTranscoding();
      }
      address[] memory targets = new address[](ids.length);
      address[] memory admins = new address[](ids.length);
      R21.Upkeep[] memory newUpkeeps = new R21.Upkeep[](ids.length);
      UpkeepV13 memory upkeepV13;
      for (uint256 idx = 0; idx < ids.length; idx++) {
        upkeepV13 = upkeepsV13[idx];
        newUpkeeps[idx] = R21.Upkeep({
          performGas: upkeepV13.executeGas,
          maxValidBlocknumber: upkeepV13.maxValidBlocknumber,
          paused: upkeepV13.paused,
          forwarder: ZERO_FORWARDER,
          amountSpent: upkeepV13.amountSpent,
          balance: upkeepV13.balance,
          lastPerformedBlockNumber: 0
        });
        targets[idx] = upkeepV13.target;
        admins[idx] = upkeepV13.admin;
      }
      return abi.encode(ids, newUpkeeps, targets, admins, checkDatas, new bytes[](ids.length), new bytes[](ids.length));
    }
    // v2.0 => v2.1
    if (fromVersion == uint8(RegistryVersion.V20)) {
      (uint256[] memory ids, UpkeepV20[] memory upkeepsV20, bytes[] memory checkDatas, address[] memory admins) = abi
        .decode(encodedUpkeeps, (uint256[], UpkeepV20[], bytes[], address[]));
      if (ids.length != upkeepsV20.length || ids.length != checkDatas.length) {
        revert InvalidTranscoding();
      }
      // bit of a hack - transcodeUpkeeps should be a pure function
      R21.Upkeep[] memory newUpkeeps = new R21.Upkeep[](ids.length);
      bytes[] memory emptyBytes = new bytes[](ids.length);
      address[] memory targets = new address[](ids.length);
      UpkeepV20 memory upkeepV20;
      for (uint256 idx = 0; idx < ids.length; idx++) {
        upkeepV20 = upkeepsV20[idx];
        newUpkeeps[idx] = R21.Upkeep({
          performGas: upkeepV20.executeGas,
          maxValidBlocknumber: upkeepV20.maxValidBlocknumber,
          paused: upkeepV20.paused,
          forwarder: ZERO_FORWARDER,
          amountSpent: upkeepV20.amountSpent,
          balance: upkeepV20.balance,
          lastPerformedBlockNumber: 0
        });
        targets[idx] = upkeepV20.target;
      }
      return abi.encode(ids, newUpkeeps, targets, admins, checkDatas, emptyBytes, emptyBytes);
    }
    // v2.1 => v2.1
    if (fromVersion == uint8(RegistryVersion.V21)) {
      return encodedUpkeeps;
    }

    revert InvalidTranscoding();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// this struct is the same as LogTriggerConfig defined in KeeperRegistryLogicA2_1 contract
struct LogTriggerConfig {
  address contractAddress;
  uint8 filterSelector; // denotes which topics apply to filter ex 000, 101, 111...only last 3 bits apply
  bytes32 topic0;
  bytes32 topic1;
  bytes32 topic2;
  bytes32 topic3;
}

contract DummyProtocol {
  event LimitOrderSent(uint256 indexed amount, uint256 indexed price, address indexed to); // keccak256(LimitOrderSent(uint256,uint256,address)) => 0x3e9c37b3143f2eb7e9a2a0f8091b6de097b62efcfe48e1f68847a832e521750a
  event LimitOrderWithdrawn(uint256 indexed amount, uint256 indexed price, address indexed from); // keccak256(LimitOrderWithdrawn(uint256,uint256,address)) => 0x0a71b8ed921ff64d49e4d39449f8a21094f38a0aeae489c3051aedd63f2c229f
  event LimitOrderExecuted(uint256 indexed orderId, uint256 indexed amount, address indexed exchange); // keccak(LimitOrderExecuted(uint256,uint256,address)) => 0xd1ffe9e45581c11d7d9f2ed5f75217cd4be9f8b7eee6af0f6d03f46de53956cd

  function sendLimitedOrder(uint256 amount, uint256 price, address to) public {
    // send an order to an exchange
    emit LimitOrderSent(amount, price, to);
  }

  function withdrawLimit(uint256 amount, uint256 price, address from) public {
    // withdraw an order from an exchange
    emit LimitOrderSent(amount, price, from);
  }

  function executeLimitOrder(uint256 orderId, uint256 amount, address exchange) public {
    // execute a limit order
    emit LimitOrderExecuted(orderId, amount, exchange);
  }

  /**
   * @notice this function generates bytes for a basic log trigger config with no filter selector.
   * @param targetContract the address of contract where events will be emitted from
   * @param t0 the signature of the event to listen to
   */
  function getBasicLogTriggerConfig(
    address targetContract,
    bytes32 t0
  ) external view returns (bytes memory logTrigger) {
    LogTriggerConfig memory cfg = LogTriggerConfig({
      contractAddress: targetContract,
      filterSelector: 0,
      topic0: t0,
      topic1: 0x000000000000000000000000000000000000000000000000000000000000000,
      topic2: 0x000000000000000000000000000000000000000000000000000000000000000,
      topic3: 0x000000000000000000000000000000000000000000000000000000000000000
    });
    return abi.encode(cfg);
  }

  /**
   * @notice this function generates bytes for a customizable log trigger config.
   * @param targetContract the address of contract where events will be emitted from
   * @param selector the filter selector. this denotes which topics apply to filter ex 000, 101, 111....only last 3 bits apply
   * if 0, it won't filter based on topic 1, 2, 3.
   * if 1, it will filter based on topic 1,
   * if 2, it will filter based on topic 2,
   * if 3, it will filter based on topic 1 and topic 2,
   * if 4, it will filter based on topic 3,
   * if 5, it will filter based on topic 1 and topic 3....
   * @param t0 the signature of the event to listen to.
   * @param t1 the topic 1 of the event.
   * @param t2 the topic 2 of the event.
   * @param t3 the topic 2 of the event.
   */
  function getAdvancedLogTriggerConfig(
    address targetContract,
    uint8 selector,
    bytes32 t0,
    bytes32 t1,
    bytes32 t2,
    bytes32 t3
  ) external view returns (bytes memory logTrigger) {
    LogTriggerConfig memory cfg = LogTriggerConfig({
      contractAddress: targetContract,
      filterSelector: selector,
      topic0: t0,
      topic1: t1,
      topic2: t2,
      topic3: t3
    });
    return abi.encode(cfg);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ILogAutomation, Log} from "../2_1/interfaces/ILogAutomation.sol";
import "../2_1/interfaces/StreamsLookupCompatibleInterface.sol";
import {ArbSys} from "../../../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @return verifierResponse The encoded response from the verifier.
   */
  function verify(bytes memory signedReport) external returns (bytes memory verifierResponse);
}

contract LogTriggeredStreamsLookup is ILogAutomation, StreamsLookupCompatibleInterface {
  event PerformingLogTriggerUpkeep(
    address indexed from,
    uint256 orderId,
    uint256 amount,
    address exchange,
    uint256 blockNumber,
    bytes blob,
    bytes verified
  );

  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);
  IVerifierProxy internal constant VERIFIER = IVerifierProxy(0x09DFf56A4fF44e0f4436260A04F5CFa65636A481);

  // for log trigger
  bytes32 constant sentSig = 0x3e9c37b3143f2eb7e9a2a0f8091b6de097b62efcfe48e1f68847a832e521750a;
  bytes32 constant withdrawnSig = 0x0a71b8ed921ff64d49e4d39449f8a21094f38a0aeae489c3051aedd63f2c229f;
  bytes32 constant executedSig = 0xd1ffe9e45581c11d7d9f2ed5f75217cd4be9f8b7eee6af0f6d03f46de53956cd;

  // for mercury config
  bool public useArbitrumBlockNum;
  bool public verify;
  string[] public feedsHex = ["0x4554482d5553442d415242495452554d2d544553544e45540000000000000000"];
  string public feedParamKey = "feedIdHex";
  string public timeParamKey = "blockNumber";

  constructor(bool _useArbitrumBlockNum, bool _verify) {
    useArbitrumBlockNum = _useArbitrumBlockNum;
    verify = _verify;
  }

  function setTimeParamKey(string memory timeParam) external {
    timeParamKey = timeParam;
  }

  function setFeedParamKey(string memory feedParam) external {
    feedParamKey = feedParam;
  }

  function setFeedsHex(string[] memory newFeeds) external {
    feedsHex = newFeeds;
  }

  function checkLog(
    Log calldata log,
    bytes memory
  ) external override returns (bool upkeepNeeded, bytes memory performData) {
    uint256 blockNum = getBlockNumber();

    // filter by event signature
    if (log.topics[0] == executedSig) {
      // filter by indexed parameters
      bytes memory t1 = abi.encodePacked(log.topics[1]); // bytes32 to bytes
      uint256 orderId = abi.decode(t1, (uint256));
      bytes memory t2 = abi.encodePacked(log.topics[2]);
      uint256 amount = abi.decode(t2, (uint256));
      bytes memory t3 = abi.encodePacked(log.topics[3]);
      address exchange = abi.decode(t3, (address));

      revert StreamsLookup(feedParamKey, feedsHex, timeParamKey, blockNum, abi.encode(orderId, amount, exchange));
    }
    revert("could not find matching event sig");
  }

  function performUpkeep(bytes calldata performData) external override {
    (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
    (uint256 orderId, uint256 amount, address exchange) = abi.decode(extraData, (uint256, uint256, address));

    bytes memory verifiedResponse = "";
    if (verify) {
      verifiedResponse = VERIFIER.verify(values[0]);
    }

    emit PerformingLogTriggerUpkeep(
      tx.origin,
      orderId,
      amount,
      exchange,
      getBlockNumber(),
      values[0],
      verifiedResponse
    );
  }

  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external view override returns (bool, bytes memory) {
    // do sth about the chainlinkBlob data in values and extraData
    bytes memory performData = abi.encode(values, extraData);
    return (true, performData);
  }

  function getBlockNumber() internal view returns (uint256) {
    if (useArbitrumBlockNum) {
      return ARB_SYS.arbBlockNumber();
    } else {
      return block.number;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/*
 * @title ByteUtil
 * @author Michael Fletcher
 * @notice Byte utility functions for efficiently parsing and manipulating packed byte data
 */
library ByteUtil {
  // Error message when an offset is out of bounds
  error MalformedData();

  /**
   * @dev Reads a uint256 from a position within a byte array.
   * @param data Byte array to read from.
   * @param offset Position to start reading from.
   * @return result The uint256 read from the byte array.
   */
  function readUint256(bytes memory data, uint256 offset) internal pure returns (uint256 result) {
    //bounds check
    if (offset + 32 > data.length) revert MalformedData();

    assembly {
      //load 32 byte word accounting for 32 bit length and offset
      result := mload(add(add(data, 32), offset))
    }
  }

  /**
   * @dev Reads a uint192 from a position within a byte array.
   * @param data Byte array to read from.
   * @param offset Position to start reading from.
   * @return result The uint192 read from the byte array.
   */
  function readUint192(bytes memory data, uint256 offset) internal pure returns (uint256 result) {
    //bounds check
    if (offset + 24 > data.length) revert MalformedData();

    assembly {
      //load 32 byte word accounting for 32 bit length and offset
      result := mload(add(add(data, 32), offset))
      //shift the result right 64 bits
      result := shr(64, result)
    }
  }

  /**
   * @dev Reads a uint32 from a position within a byte array.
   * @param data Byte array to read from.
   * @param offset Position to start reading from.
   * @return result The uint32 read from the byte array.
   */
  function readUint32(bytes memory data, uint256 offset) internal pure returns (uint256 result) {
    //bounds check
    if (offset + 4 > data.length) revert MalformedData();

    assembly {
      //load 32 byte word accounting for 32 bit length and offset
      result := mload(add(add(data, 32), offset))
      //shift the result right 224 bits
      result := shr(224, result)
    }
  }

  /**
   * @dev Reads an address from a position within a byte array.
   * @param data Byte array to read from.
   * @param offset Position to start reading from.
   * @return result The uint32 read from the byte array.
   */
  function readAddress(bytes memory data, uint256 offset) internal pure returns (address result) {
    //bounds check
    if (offset + 20 > data.length) revert MalformedData();

    assembly {
      //load 32 byte word accounting for 32 bit length and offset
      let word := mload(add(add(data, 32), offset))
      //address is the last 20 bytes of the word, so shift right
      result := shr(96, word)
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/*
 * @title Common
 * @author Michael Fletcher
 * @notice Common functions and structs
 */
library Common {
  // @notice The asset struct to hold the address of an asset and amount
  struct Asset {
    address assetAddress;
    uint256 amount;
  }

  // @notice Struct to hold the address and its associated weight
  struct AddressAndWeight {
    address addr;
    uint64 weight;
  }

  /**
   * @notice Checks if an array of AddressAndWeight has duplicate addresses
   * @param recipients The array of AddressAndWeight to check
   * @return bool True if there are duplicates, false otherwise
   */
  function hasDuplicateAddresses(Common.AddressAndWeight[] memory recipients) internal pure returns (bool) {
    for (uint256 i = 0; i < recipients.length; ) {
      for (uint256 j = i + 1; j < recipients.length; ) {
        if (recipients[i].addr == recipients[j].addr) {
          return true;
        }
        unchecked {
          ++j;
        }
      }
      unchecked {
        ++i;
      }
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";
import {IFeeManager} from "./interfaces/IFeeManager.sol";
import {TypeAndVersionInterface} from "../../interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../libraries/Common.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";
import {IWERC20} from "../../shared/interfaces/IWERC20.sol";
import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC20.sol";
import {Math} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/utils/math/Math.sol";
import {SafeERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";
import {IVerifierFeeManager} from "./interfaces/IVerifierFeeManager.sol";

/**
 * @title FeeManager
 * @author Michael Fletcher
 * @author Austin Born
 * @notice This contract is used for the handling of fees required for users verifying reports.
 */
contract FeeManager is IFeeManager, ConfirmedOwner, TypeAndVersionInterface {
  using SafeERC20 for IERC20;

  /// @notice list of subscribers and their discounts subscriberDiscounts[subscriber][feedId][token]
  mapping(address => mapping(bytes32 => mapping(address => uint256))) public s_subscriberDiscounts;

  /// @notice keep track of any subsidised link that is owed to the reward manager.
  mapping(bytes32 => uint256) public s_linkDeficit;

  /// @notice the total discount that can be applied to a fee, 1e18 = 100% discount
  uint64 private constant PERCENTAGE_SCALAR = 1e18;

  /// @notice the LINK token address
  address private immutable i_linkAddress;

  /// @notice the native token address
  address private immutable i_nativeAddress;

  /// @notice the proxy address
  address private immutable i_proxyAddress;

  /// @notice the reward manager address
  IRewardManager private immutable i_rewardManager;

  // @notice the mask to apply to get the report version
  bytes32 private constant REPORT_VERSION_MASK = 0xffff000000000000000000000000000000000000000000000000000000000000;

  // @notice the different report versions
  bytes32 private constant REPORT_V1 = 0x0001000000000000000000000000000000000000000000000000000000000000;

  /// @notice the surcharge fee to be paid if paying in native
  uint256 public s_nativeSurcharge;

  /// @notice the error thrown if the discount or surcharge is invalid
  error InvalidSurcharge();

  /// @notice the error thrown if the discount is invalid
  error InvalidDiscount();

  /// @notice the error thrown if the address is invalid
  error InvalidAddress();

  /// @notice thrown if msg.value is supplied with a bad quote
  error InvalidDeposit();

  /// @notice thrown if a report has expired
  error ExpiredReport();

  /// @notice thrown if a report has no quote
  error InvalidQuote();

  // @notice thrown when the caller is not authorized
  error Unauthorized();

  // @notice thrown when trying to clear a zero deficit
  error ZeroDeficit();

  /// @notice thrown when trying to pay an address that cannot except funds
  error InvalidReceivingAddress();

  /// @notice Emitted whenever a subscriber's discount is updated
  /// @param subscriber address of the subscriber to update discounts for
  /// @param feedId Feed ID for the discount
  /// @param token Token address for the discount
  /// @param discount Discount to apply, in relation to the PERCENTAGE_SCALAR
  event SubscriberDiscountUpdated(address indexed subscriber, bytes32 indexed feedId, address token, uint64 discount);

  /// @notice Emitted when updating the native surcharge
  /// @param newSurcharge Surcharge amount to apply relative to PERCENTAGE_SCALAR
  event NativeSurchargeUpdated(uint64 newSurcharge);

  /// @notice Emits when this contract does not have enough LINK to send to the reward manager when paying in native
  /// @param rewards Config digest and link fees which could not be subsidised
  event InsufficientLink(IRewardManager.FeePayment[] rewards);

  /// @notice Emitted when funds are withdrawn
  /// @param adminAddress Address of the admin
  /// @param recipient Address of the recipient
  /// @param assetAddress Address of the asset withdrawn
  /// @param quantity Amount of the asset withdrawn
  event Withdraw(address adminAddress, address recipient, address assetAddress, uint192 quantity);

  /// @notice Emits when a deficit has been cleared for a particular config digest
  /// @param configDigest Config digest of the deficit cleared
  /// @param linkQuantity Amount of LINK required to pay the deficit
  event LinkDeficitCleared(bytes32 indexed configDigest, uint256 linkQuantity);

  /// @notice Emits when a fee has been processed
  /// @param configDigest Config digest of the fee processed
  /// @param subscriber Address of the subscriber who paid the fee
  /// @param fee Fee paid
  /// @param reward Reward paid
  /// @param appliedDiscount Discount applied to the fee
  event DiscountApplied(
    bytes32 indexed configDigest,
    address indexed subscriber,
    Common.Asset fee,
    Common.Asset reward,
    uint256 appliedDiscount
  );

  /**
   * @notice Construct the FeeManager contract
   * @param _linkAddress The address of the LINK token
   * @param _nativeAddress The address of the wrapped ERC-20 version of the native token (represents fee in native or wrapped)
   * @param _proxyAddress The address of the proxy contract
   * @param _rewardManagerAddress The address of the reward manager contract
   */
  constructor(
    address _linkAddress,
    address _nativeAddress,
    address _proxyAddress,
    address _rewardManagerAddress
  ) ConfirmedOwner(msg.sender) {
    if (
      _linkAddress == address(0) ||
      _nativeAddress == address(0) ||
      _proxyAddress == address(0) ||
      _rewardManagerAddress == address(0)
    ) revert InvalidAddress();

    i_linkAddress = _linkAddress;
    i_nativeAddress = _nativeAddress;
    i_proxyAddress = _proxyAddress;
    i_rewardManager = IRewardManager(_rewardManagerAddress);

    IERC20(i_linkAddress).approve(address(i_rewardManager), type(uint256).max);
  }

  modifier onlyOwnerOrProxy() {
    if (msg.sender != i_proxyAddress && msg.sender != owner()) revert Unauthorized();
    _;
  }

  modifier onlyProxy() {
    if (msg.sender != i_proxyAddress) revert Unauthorized();
    _;
  }

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "FeeManager 1.0.0";
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == this.processFee.selector || interfaceId == this.processFeeBulk.selector;
  }

  /// @inheritdoc IVerifierFeeManager
  function processFee(bytes calldata payload, address subscriber) external payable override onlyProxy {
    (Common.Asset memory fee, Common.Asset memory reward, uint256 appliedDiscount) = _processFee(payload, subscriber);

    if (fee.amount == 0) {
      _tryReturnChange(subscriber, msg.value);
      return;
    }

    IFeeManager.FeeAndReward[] memory feeAndReward = new IFeeManager.FeeAndReward[](1);
    feeAndReward[0] = IFeeManager.FeeAndReward(bytes32(payload), fee, reward, appliedDiscount);

    if (fee.assetAddress == i_linkAddress) {
      _handleFeesAndRewards(subscriber, feeAndReward, 1, 0);
    } else {
      _handleFeesAndRewards(subscriber, feeAndReward, 0, 1);
    }
  }

  /// @inheritdoc IVerifierFeeManager
  function processFeeBulk(bytes[] calldata payloads, address subscriber) external payable override onlyProxy {
    FeeAndReward[] memory feesAndRewards = new IFeeManager.FeeAndReward[](payloads.length);

    //keep track of the number of fees to prevent over initialising the FeePayment array within _convertToLinkAndNativeFees
    uint256 numberOfLinkFees;
    uint256 numberOfNativeFees;

    uint256 feesAndRewardsIndex;
    for (uint256 i; i < payloads.length; ++i) {
      (Common.Asset memory fee, Common.Asset memory reward, uint256 appliedDiscount) = _processFee(
        payloads[i],
        subscriber
      );

      if (fee.amount != 0) {
        feesAndRewards[feesAndRewardsIndex++] = IFeeManager.FeeAndReward(
          bytes32(payloads[i]),
          fee,
          reward,
          appliedDiscount
        );

        unchecked {
          //keep track of some tallys to make downstream calculations more efficient
          if (fee.assetAddress == i_linkAddress) {
            ++numberOfLinkFees;
          } else {
            ++numberOfNativeFees;
          }
        }
      }
    }

    if (numberOfLinkFees != 0 || numberOfNativeFees != 0) {
      _handleFeesAndRewards(subscriber, feesAndRewards, numberOfLinkFees, numberOfNativeFees);
    } else {
      _tryReturnChange(subscriber, msg.value);
    }
  }

  /// @inheritdoc IFeeManager
  function getFeeAndReward(
    address subscriber,
    bytes memory report,
    Quote memory quote
  ) public view returns (Common.Asset memory, Common.Asset memory, uint256) {
    Common.Asset memory fee;
    Common.Asset memory reward;

    //get the feedId from the report
    bytes32 feedId = bytes32(report);

    //the report needs to be a support version
    bytes32 reportVersion = _getReportVersion(feedId);

    //version 1 of the reports don't require quotes, so the fee will be 0
    if (reportVersion == REPORT_V1) {
      fee.assetAddress = i_nativeAddress;
      reward.assetAddress = i_linkAddress;
      return (fee, reward, 0);
    }

    //verify the quote payload is a supported token
    if (quote.quoteAddress != i_nativeAddress && quote.quoteAddress != i_linkAddress) {
      revert InvalidQuote();
    }

    //decode the report depending on the version
    uint256 linkQuantity;
    uint256 nativeQuantity;
    uint256 expiresAt;
    (, , , linkQuantity, nativeQuantity, expiresAt) = abi.decode(
      report,
      (bytes32, uint32, uint32, uint192, uint192, uint32)
    );

    //read the timestamp bytes from the report data and verify it has not expired
    if (expiresAt < block.timestamp) {
      revert ExpiredReport();
    }

    //get the discount being applied
    uint256 discount = s_subscriberDiscounts[subscriber][feedId][quote.quoteAddress];

    //the reward is always set in LINK
    reward.assetAddress = i_linkAddress;
    reward.amount = Math.ceilDiv(linkQuantity * (PERCENTAGE_SCALAR - discount), PERCENTAGE_SCALAR);

    //calculate either the LINK fee or native fee if it's within the report
    if (quote.quoteAddress == i_linkAddress) {
      fee.assetAddress = i_linkAddress;
      fee.amount = reward.amount;
    } else {
      uint256 surchargedFee = Math.ceilDiv(nativeQuantity * (PERCENTAGE_SCALAR + s_nativeSurcharge), PERCENTAGE_SCALAR);

      fee.assetAddress = i_nativeAddress;
      fee.amount = Math.ceilDiv(surchargedFee * (PERCENTAGE_SCALAR - discount), PERCENTAGE_SCALAR);
    }

    //return the fee
    return (fee, reward, discount);
  }

  /// @inheritdoc IVerifierFeeManager
  function setFeeRecipients(
    bytes32 configDigest,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights
  ) external onlyOwnerOrProxy {
    i_rewardManager.setRewardRecipients(configDigest, rewardRecipientAndWeights);
  }

  /// @inheritdoc IFeeManager
  function setNativeSurcharge(uint64 surcharge) external onlyOwner {
    if (surcharge > PERCENTAGE_SCALAR) revert InvalidSurcharge();

    s_nativeSurcharge = surcharge;

    emit NativeSurchargeUpdated(surcharge);
  }

  /// @inheritdoc IFeeManager
  function updateSubscriberDiscount(
    address subscriber,
    bytes32 feedId,
    address token,
    uint64 discount
  ) external onlyOwner {
    //make sure the discount is not greater than the total discount that can be applied
    if (discount > PERCENTAGE_SCALAR) revert InvalidDiscount();
    //make sure the token is either LINK or native
    if (token != i_linkAddress && token != i_nativeAddress) revert InvalidAddress();

    s_subscriberDiscounts[subscriber][feedId][token] = discount;

    emit SubscriberDiscountUpdated(subscriber, feedId, token, discount);
  }

  /// @inheritdoc IFeeManager
  function withdraw(address assetAddress, address recipient, uint192 quantity) external onlyOwner {
    //address 0 is used to withdraw native in the context of withdrawing
    if (assetAddress == address(0)) {
      (bool success, ) = payable(recipient).call{value: quantity}("");

      if (!success) revert InvalidReceivingAddress();
      return;
    }

    //withdraw the requested asset
    IERC20(assetAddress).safeTransfer(recipient, quantity);

    //emit event when funds are withdrawn
    emit Withdraw(msg.sender, recipient, assetAddress, uint192(quantity));
  }

  /// @inheritdoc IFeeManager
  function linkAvailableForPayment() external view returns (uint256) {
    //return the amount of LINK this contact has available to pay rewards
    return IERC20(i_linkAddress).balanceOf(address(this));
  }

  /**
   * @notice Gets the current version of the report that is encoded as the last two bytes of the feed
   * @param feedId feed id to get the report version for
   */
  function _getReportVersion(bytes32 feedId) internal pure returns (bytes32) {
    return REPORT_VERSION_MASK & feedId;
  }

  function _processFee(
    bytes calldata payload,
    address subscriber
  ) internal view returns (Common.Asset memory, Common.Asset memory, uint256) {
    if (subscriber == address(this)) revert InvalidAddress();

    //decode the report from the payload
    (, bytes memory report) = abi.decode(payload, (bytes32[3], bytes));

    //get the feedId from the report
    bytes32 feedId = bytes32(report);

    //v1 doesn't need a quote payload, so skip the decoding
    Quote memory quote;
    if (_getReportVersion(feedId) != REPORT_V1) {
      //all reports greater than v1 should have a quote payload
      (, , , , , bytes memory quoteBytes) = abi.decode(
        payload,
        // reportContext, report, rs, ss, raw, quote
        (bytes32[3], bytes, bytes32[], bytes32[], bytes32, bytes)
      );

      //decode the quote from the bytes
      (quote) = abi.decode(quoteBytes, (Quote));
    }

    //decode the fee, it will always be native or LINK
    return getFeeAndReward(subscriber, report, quote);
  }

  function _handleFeesAndRewards(
    address subscriber,
    FeeAndReward[] memory feesAndRewards,
    uint256 numberOfLinkFees,
    uint256 numberOfNativeFees
  ) internal {
    IRewardManager.FeePayment[] memory linkRewards = new IRewardManager.FeePayment[](numberOfLinkFees);
    IRewardManager.FeePayment[] memory nativeFeeLinkRewards = new IRewardManager.FeePayment[](numberOfNativeFees);

    uint256 totalNativeFee;
    uint256 totalNativeFeeLinkValue;

    uint256 linkRewardsIndex;
    uint256 nativeFeeLinkRewardsIndex;

    uint256 totalNumberOfFees = numberOfLinkFees + numberOfNativeFees;
    for (uint256 i; i < totalNumberOfFees; ++i) {
      if (feesAndRewards[i].fee.assetAddress == i_linkAddress) {
        linkRewards[linkRewardsIndex++] = IRewardManager.FeePayment(
          feesAndRewards[i].configDigest,
          uint192(feesAndRewards[i].reward.amount)
        );
      } else {
        nativeFeeLinkRewards[nativeFeeLinkRewardsIndex++] = IRewardManager.FeePayment(
          feesAndRewards[i].configDigest,
          uint192(feesAndRewards[i].reward.amount)
        );
        totalNativeFee += feesAndRewards[i].fee.amount;
        totalNativeFeeLinkValue += feesAndRewards[i].reward.amount;
      }

      if (feesAndRewards[i].appliedDiscount != 0) {
        emit DiscountApplied(
          feesAndRewards[i].configDigest,
          subscriber,
          feesAndRewards[i].fee,
          feesAndRewards[i].reward,
          feesAndRewards[i].appliedDiscount
        );
      }
    }

    //keep track of change in case of any over payment
    uint256 change;

    if (msg.value != 0) {
      //there must be enough to cover the fee
      if (totalNativeFee > msg.value) revert InvalidDeposit();

      //wrap the amount required to pay the fee & approve as the subscriber paid in wrapped native
      IWERC20(i_nativeAddress).deposit{value: totalNativeFee}();

      unchecked {
        //msg.value is always >= to fee.amount
        change = msg.value - totalNativeFee;
      }
    } else {
      if (totalNativeFee != 0) {
        //subscriber has paid in wrapped native, so transfer the native to this contract
        IERC20(i_nativeAddress).safeTransferFrom(subscriber, address(this), totalNativeFee);
      }
    }

    if (linkRewards.length != 0) {
      i_rewardManager.onFeePaid(linkRewards, subscriber);
    }

    if (nativeFeeLinkRewards.length != 0) {
      //distribute subsidised fees paid in Native
      if (totalNativeFeeLinkValue > IERC20(i_linkAddress).balanceOf(address(this))) {
        // If not enough LINK on this contract to forward for rewards, tally the deficit to be paid by out-of-band LINK
        for (uint256 i; i < nativeFeeLinkRewards.length; ++i) {
          unchecked {
            //we have previously tallied the fees, any overflows would have already reverted
            s_linkDeficit[nativeFeeLinkRewards[i].poolId] += nativeFeeLinkRewards[i].amount;
          }
        }

        emit InsufficientLink(nativeFeeLinkRewards);
      } else {
        //distribute the fees
        i_rewardManager.onFeePaid(nativeFeeLinkRewards, address(this));
      }
    }

    // a refund may be needed if the payee has paid in excess of the fee
    _tryReturnChange(subscriber, change);
  }

  function _tryReturnChange(address subscriber, uint256 quantity) internal {
    if (quantity != 0) {
      payable(subscriber).transfer(quantity);
    }
  }

  /// @inheritdoc IFeeManager
  function payLinkDeficit(bytes32 configDigest) external onlyOwner {
    uint256 deficit = s_linkDeficit[configDigest];

    if (deficit == 0) revert ZeroDeficit();

    delete s_linkDeficit[configDigest];

    IRewardManager.FeePayment[] memory deficitFeePayment = new IRewardManager.FeePayment[](1);

    deficitFeePayment[0] = IRewardManager.FeePayment(configDigest, uint192(deficit));

    i_rewardManager.onFeePaid(deficitFeePayment, address(this));

    emit LinkDeficitCleared(configDigest, deficit);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC165} from "../../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../../libraries/Common.sol";
import {IVerifierFeeManager} from "./IVerifierFeeManager.sol";

interface IFeeManager is IERC165, IVerifierFeeManager {
  /**
   * @notice Calculate the applied fee and the reward from a report. If the sender is a subscriber, they will receive a discount.
   * @param subscriber address trying to verify
   * @param report report to calculate the fee for
   * @param quote any metadata required to fetch the fee
   * @return (fee, reward, totalDiscount) fee and the reward data with the discount applied
   */
  function getFeeAndReward(
    address subscriber,
    bytes memory report,
    Quote memory quote
  ) external returns (Common.Asset memory, Common.Asset memory, uint256);

  /**
   * @notice Sets the native surcharge
   * @param surcharge surcharge to be paid if paying in native
   */
  function setNativeSurcharge(uint64 surcharge) external;

  /**
   * @notice Adds a subscriber to the fee manager
   * @param subscriber address of the subscriber
   * @param feedId feed id to apply the discount to
   * @param token token to apply the discount to
   * @param discount discount to be applied to the fee
   */
  function updateSubscriberDiscount(address subscriber, bytes32 feedId, address token, uint64 discount) external;

  /**
   * @notice Withdraws any native or LINK rewards to the owner address
   * @param assetAddress address of the asset to withdraw
   * @param recipientAddress address to withdraw to
   * @param quantity quantity to withdraw
   */
  function withdraw(address assetAddress, address recipientAddress, uint192 quantity) external;

  /**
   * @notice Returns the link balance of the fee manager
   * @return link balance of the fee manager
   */
  function linkAvailableForPayment() external returns (uint256);

  /**
   * @notice Admin function to pay the LINK deficit for a given config digest
   * @param configDigest the config digest to pay the deficit for
   */
  function payLinkDeficit(bytes32 configDigest) external;

  /**
   * @notice The structure to hold a fee and reward to verify a report
   * @param digest the digest linked to the fee and reward
   * @param fee the fee paid to verify the report
   * @param reward the reward paid upon verification
   & @param appliedDiscount the discount applied to the reward
   */
  struct FeeAndReward {
    bytes32 configDigest;
    Common.Asset fee;
    Common.Asset reward;
    uint256 appliedDiscount;
  }

  /**
   * @notice The structure to hold quote metadata
   * @param quoteAddress the address of the quote
   */
  struct Quote {
    address quoteAddress;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC165} from "../../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../../libraries/Common.sol";

interface IRewardManager is IERC165 {
  /**
   * @notice Record the fee received for a particular pool
   * @param payments array of structs containing pool id and amount
   * @param payee the user the funds should be retrieved from
   */
  function onFeePaid(FeePayment[] calldata payments, address payee) external;

  /**
   * @notice Claims the rewards in a specific pool
   * @param poolIds array of poolIds to claim rewards for
   */
  function claimRewards(bytes32[] calldata poolIds) external;

  /**
   * @notice Set the RewardRecipients and weights for a specific pool. This should only be called once per pool Id. Else updateRewardRecipients should be used.
   * @param poolId poolId to set RewardRecipients and weights for
   * @param rewardRecipientAndWeights array of each RewardRecipient and associated weight
   */
  function setRewardRecipients(bytes32 poolId, Common.AddressAndWeight[] calldata rewardRecipientAndWeights) external;

  /**
   * @notice Updates a subset the reward recipients for a specific poolId. The collective weight of the recipients should add up to the recipients existing weights. Any recipients with a weight of 0 will be removed.
   * @param poolId the poolId to update
   * @param newRewardRecipients array of new reward recipients
   */
  function updateRewardRecipients(bytes32 poolId, Common.AddressAndWeight[] calldata newRewardRecipients) external;

  /**
   * @notice Pays all the recipients for each of the pool ids
   * @param poolId the pool id to pay recipients for
   * @param recipients array of recipients to pay within the pool
   */
  function payRecipients(bytes32 poolId, address[] calldata recipients) external;

  /**
   * @notice Sets the fee manager. This needs to be done post construction to prevent a circular dependency.
   * @param newFeeManager address of the new verifier proxy
   */
  function setFeeManager(address newFeeManager) external;

  /**
   * @notice Gets a list of pool ids which have reward for a specific recipient.
   * @param recipient address of the recipient to get pool ids for
   * @param startIndex the index to start from
   * @param endIndex the index to stop at
   */
  function getAvailableRewardPoolIds(
    address recipient,
    uint256 startIndex,
    uint256 endIndex
  ) external view returns (bytes32[] memory);

  /**
   * @notice The structure to hold a fee payment notice
   * @param poolId the poolId receiving the payment
   * @param amount the amount being paid
   */
  struct FeePayment {
    bytes32 poolId;
    uint192 amount;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC165} from "../../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../../libraries/Common.sol";

interface IVerifierFeeManager is IERC165 {
  /**
   * @notice Handles fees for a report from the subscriber and manages rewards
   * @param payload report and quote to process the fee for
   * @param subscriber address of the fee will be applied
   */
  function processFee(bytes calldata payload, address subscriber) external payable;

  /**
   * @notice Processes the fees for each report in the payload, billing the subscriber and paying the reward manager
   * @param payloads reports and quotes to process
   * @param subscriber address of the user to process fee for
   */
  function processFeeBulk(bytes[] calldata payloads, address subscriber) external payable;

  /**
   * @notice Sets the fee recipients according to the fee manager
   * @param configDigest digest of the configuration
   * @param rewardRecipientAndWeights the address and weights of all the recipients to receive rewards
   */
  function setFeeRecipients(
    bytes32 configDigest,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ConfirmedOwner} from "../../shared/access/ConfirmedOwner.sol";
import {IRewardManager} from "./interfaces/IRewardManager.sol";
import {IERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC20.sol";
import {TypeAndVersionInterface} from "../../interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../libraries/Common.sol";
import {SafeERC20} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title FeeManager
 * @author Michael Fletcher
 * @author Austin Born
 * @notice This contract will be used to reward any configured recipients within a pool. Recipients will receive a share of their pool relative to their configured weight.
 */
contract RewardManager is IRewardManager, ConfirmedOwner, TypeAndVersionInterface {
  using SafeERC20 for IERC20;

  // @dev The mapping of total fees collected for a particular pot: s_totalRewardRecipientFees[poolId]
  mapping(bytes32 => uint256) public s_totalRewardRecipientFees;

  // @dev The mapping of fee balances for each pot last time the recipient claimed: s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient]
  mapping(bytes32 => mapping(address => uint256)) public s_totalRewardRecipientFeesLastClaimedAmounts;

  // @dev The mapping of RewardRecipient weights for a particular poolId: s_rewardRecipientWeights[poolId][rewardRecipient].
  mapping(bytes32 => mapping(address => uint256)) public s_rewardRecipientWeights;

  // @dev Keep track of the reward recipient weights that have been set to prevent duplicates
  mapping(bytes32 => bool) public s_rewardRecipientWeightsSet;

  // @dev Store a list of pool ids that have been registered, to make off chain lookups easier
  bytes32[] public s_registeredPoolIds;

  // @dev The address for the LINK contract
  address private immutable i_linkAddress;

  // The total weight of all RewardRecipients. 1e18 = 100% of the pool fees
  uint64 private constant PERCENTAGE_SCALAR = 1e18;

  // The fee manager address
  address public s_feeManagerAddress;

  // @notice Thrown whenever the RewardRecipient weights are invalid
  error InvalidWeights();

  // @notice Thrown when any given address is invalid
  error InvalidAddress();

  // @notice Thrown when the pool id is invalid
  error InvalidPoolId();

  // @notice Thrown when the calling contract is not within the authorized contracts
  error Unauthorized();

  // @notice Thrown when getAvailableRewardPoolIds parameters are incorrectly set
  error InvalidPoolLength();

  // Events emitted upon state change
  event RewardRecipientsUpdated(bytes32 indexed poolId, Common.AddressAndWeight[] newRewardRecipients);
  event RewardsClaimed(bytes32 indexed poolId, address indexed recipient, uint192 quantity);
  event FeeManagerUpdated(address newFeeManagerAddress);
  event FeePaid(FeePayment[] payments, address payer);

  /**
   * @notice Constructor
   * @param linkAddress address of the wrapped LINK token
   */
  constructor(address linkAddress) ConfirmedOwner(msg.sender) {
    //ensure that the address ia not zero
    if (linkAddress == address(0)) revert InvalidAddress();

    i_linkAddress = linkAddress;
  }

  // @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "RewardManager 1.0.0";
  }

  // @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == this.onFeePaid.selector;
  }

  modifier onlyOwnerOrFeeManager() {
    if (msg.sender != owner() && msg.sender != s_feeManagerAddress) revert Unauthorized();
    _;
  }

  modifier onlyOwnerOrRecipientInPool(bytes32 poolId) {
    if (msg.sender != owner() && s_rewardRecipientWeights[poolId][msg.sender] == 0) revert Unauthorized();
    _;
  }

  modifier onlyFeeManager() {
    if (msg.sender != s_feeManagerAddress) revert Unauthorized();
    _;
  }

  /// @inheritdoc IRewardManager
  function onFeePaid(FeePayment[] calldata payments, address payer) external override onlyFeeManager {
    uint256 totalFeeAmount;
    for (uint256 i; i < payments.length; ++i) {
      unchecked {
        //the total amount for any ERC20 asset cannot exceed 2^256 - 1
        s_totalRewardRecipientFees[payments[i].poolId] += payments[i].amount;

        //tally the total payable fees
        totalFeeAmount += payments[i].amount;
      }
    }

    //transfer the fees to this contract
    IERC20(i_linkAddress).safeTransferFrom(payer, address(this), totalFeeAmount);

    emit FeePaid(payments, payer);
  }

  /// @inheritdoc IRewardManager
  function claimRewards(bytes32[] memory poolIds) external override {
    _claimRewards(msg.sender, poolIds);
  }

  // wrapper impl for claimRewards
  function _claimRewards(address recipient, bytes32[] memory poolIds) internal returns (uint256) {
    //get the total amount claimable for this recipient
    uint256 claimAmount;

    //loop and claim all the rewards in the poolId pot
    for (uint256 i; i < poolIds.length; ++i) {
      //get the poolId to be claimed
      bytes32 poolId = poolIds[i];

      //get the total fees for the pot
      uint256 totalFeesInPot = s_totalRewardRecipientFees[poolId];

      unchecked {
        //avoid unnecessary storage reads if there's no fees in the pot
        if (totalFeesInPot == 0) continue;

        //get the claimable amount for this recipient, this calculation will never exceed the amount in the pot
        uint256 claimableAmount = totalFeesInPot - s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient];

        //calculate the recipients share of the fees, which is their weighted share of the difference between the last amount they claimed and the current amount in the pot. This can never be more than the total amount in existence
        uint256 recipientShare = (claimableAmount * s_rewardRecipientWeights[poolId][recipient]) / PERCENTAGE_SCALAR;

        //if there's no fees to claim, continue as there's nothing to update
        if (recipientShare == 0) continue;

        //keep track of the total amount claimable, this can never be more than the total amount in existence
        claimAmount += recipientShare;

        //set the current total amount of fees in the pot as it's used to calculate future claims
        s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient] = totalFeesInPot;

        //emit event if the recipient has rewards to claim
        emit RewardsClaimed(poolIds[i], recipient, uint192(recipientShare));
      }
    }

    //check if there's any rewards to claim in the given poolId
    if (claimAmount != 0) {
      //transfer the reward to the recipient
      IERC20(i_linkAddress).safeTransfer(recipient, claimAmount);
    }

    return claimAmount;
  }

  /// @inheritdoc IRewardManager
  function setRewardRecipients(
    bytes32 poolId,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights
  ) external override onlyOwnerOrFeeManager {
    //revert if there are no recipients to set
    if (rewardRecipientAndWeights.length == 0) revert InvalidAddress();

    //check that the weights have not been previously set
    if (s_rewardRecipientWeightsSet[poolId]) revert InvalidPoolId();

    //keep track of the registered poolIds to make off chain lookups easier
    s_registeredPoolIds.push(poolId);

    //keep track of which pools have had their reward recipients set
    s_rewardRecipientWeightsSet[poolId] = true;

    //set the reward recipients, this will only be called once and contain the full set of RewardRecipients with a total weight of 100%
    _setRewardRecipientWeights(poolId, rewardRecipientAndWeights, PERCENTAGE_SCALAR);

    emit RewardRecipientsUpdated(poolId, rewardRecipientAndWeights);
  }

  function _setRewardRecipientWeights(
    bytes32 poolId,
    Common.AddressAndWeight[] calldata rewardRecipientAndWeights,
    uint256 expectedWeight
  ) internal {
    //we can't update the weights if it contains duplicates
    if (Common.hasDuplicateAddresses(rewardRecipientAndWeights)) revert InvalidAddress();

    //loop all the reward recipients and validate the weight and address
    uint256 totalWeight;
    for (uint256 i; i < rewardRecipientAndWeights.length; ++i) {
      //get the weight
      uint256 recipientWeight = rewardRecipientAndWeights[i].weight;
      //get the address
      address recipientAddress = rewardRecipientAndWeights[i].addr;

      //ensure the reward recipient address is not zero
      if (recipientAddress == address(0)) revert InvalidAddress();
      //ensure the weight is not zero
      if (recipientWeight == 0) revert InvalidWeights();

      //save/overwrite the weight for the reward recipient
      s_rewardRecipientWeights[poolId][recipientAddress] = recipientWeight;

      unchecked {
        //keep track of the cumulative weight, this cannot overflow as the total weight is restricted at 1e18
        totalWeight += recipientWeight;
      }
    }

    //if total weight is not met, the fees will either be under or over distributed
    if (totalWeight != expectedWeight) revert InvalidWeights();
  }

  /// @inheritdoc IRewardManager
  function updateRewardRecipients(
    bytes32 poolId,
    Common.AddressAndWeight[] calldata newRewardRecipients
  ) external override onlyOwner {
    //create an array of poolIds to pass to _claimRewards if required
    bytes32[] memory poolIds = new bytes32[](1);
    poolIds[0] = poolId;

    //loop all the reward recipients and claim their rewards before updating their weights
    uint256 existingTotalWeight;
    for (uint256 i; i < newRewardRecipients.length; ++i) {
      //get the address
      address recipientAddress = newRewardRecipients[i].addr;
      //get the existing weight
      uint256 existingWeight = s_rewardRecipientWeights[poolId][recipientAddress];

      //if the existing weight is 0, the recipient isn't part of this configuration
      if (existingWeight == 0) revert InvalidAddress();

      //if a recipient is updated, the rewards must be claimed first as they can't claim previous fees at the new weight
      _claimRewards(newRewardRecipients[i].addr, poolIds);

      unchecked {
        //keep tally of the weights so that the expected collective weight is known
        existingTotalWeight += existingWeight;
      }
    }

    //update the reward recipients, if the new collective weight isn't equal to the previous collective weight, the fees will either be under or over distributed
    _setRewardRecipientWeights(poolId, newRewardRecipients, existingTotalWeight);

    //emit event
    emit RewardRecipientsUpdated(poolId, newRewardRecipients);
  }

  /// @inheritdoc IRewardManager
  function payRecipients(bytes32 poolId, address[] calldata recipients) external onlyOwnerOrRecipientInPool(poolId) {
    //convert poolIds to an array to match the interface of _claimRewards
    bytes32[] memory poolIdsArray = new bytes32[](1);
    poolIdsArray[0] = poolId;

    //loop each recipient and claim the rewards for each of the pools and assets
    for (uint256 i; i < recipients.length; ++i) {
      _claimRewards(recipients[i], poolIdsArray);
    }
  }

  /// @inheritdoc IRewardManager
  function setFeeManager(address newFeeManagerAddress) external onlyOwner {
    if (newFeeManagerAddress == address(0)) revert InvalidAddress();

    s_feeManagerAddress = newFeeManagerAddress;

    emit FeeManagerUpdated(newFeeManagerAddress);
  }

  /// @inheritdoc IRewardManager
  function getAvailableRewardPoolIds(
    address recipient,
    uint256 startIndex,
    uint256 endIndex
  ) external view returns (bytes32[] memory) {
    //get the length of the pool ids which we will loop through and potentially return
    uint256 registeredPoolIdsLength = s_registeredPoolIds.length;

    uint256 lastIndex = endIndex > registeredPoolIdsLength ? registeredPoolIdsLength : endIndex;

    if (startIndex > lastIndex) revert InvalidPoolLength();

    //create a new array with the maximum amount of potential pool ids
    bytes32[] memory claimablePoolIds = new bytes32[](lastIndex - startIndex);
    //we want the pools which a recipient has funds for to be sequential, so we need to keep track of the index
    uint256 poolIdArrayIndex;

    //loop all the pool ids, and check if the recipient has a registered weight and a claimable amount
    for (uint256 i = startIndex; i < lastIndex; ++i) {
      //get the poolId
      bytes32 poolId = s_registeredPoolIds[i];

      //if the recipient has a weight, they are a recipient of this poolId
      if (s_rewardRecipientWeights[poolId][recipient] != 0) {
        //get the total in this pool
        uint256 totalPoolAmount = s_totalRewardRecipientFees[poolId];
        //if the recipient has any LINK, then add the poolId to the array
        unchecked {
          //s_totalRewardRecipientFeesLastClaimedAmounts can never exceed total pool amount, and the number of pools can't exceed the max array length
          if (totalPoolAmount - s_totalRewardRecipientFeesLastClaimedAmounts[poolId][recipient] != 0) {
            claimablePoolIds[poolIdArrayIndex++] = poolId;
          }
        }
      }
    }

    return claimablePoolIds;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IERC165} from "../../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../../libraries/Common.sol";

interface IVerifier is IERC165 {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @param sender The address that requested to verify the contract.
   * This is only used for logging purposes.
   * @dev Verification is typically only done through the proxy contract so
   * we can't just use msg.sender to log the requester as the msg.sender
   * contract will always be the proxy.
   * @return verifierResponse The encoded verified response.
   */
  function verify(bytes calldata signedReport, address sender) external returns (bytes memory verifierResponse);

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param feedId Feed ID to set config for
   * @param signers addresses with which oracles sign the reports
   * @param offchainTransmitters CSA key for the ith Oracle
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   * @param recipientAddressesAndWeights the addresses and weights of all the recipients to receive rewards
   */
  function setConfig(
    bytes32 feedId,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig,
    Common.AddressAndWeight[] memory recipientAddressesAndWeights
  ) external;

  /**
   * @notice identical to `setConfig` except with args for sourceChainId and sourceAddress
   * @param feedId Feed ID to set config for
   * @param sourceChainId Chain ID of source config
   * @param sourceAddress Address of source config Verifier
   * @param signers addresses with which oracles sign the reports
   * @param offchainTransmitters CSA key for the ith Oracle
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   * @param recipientAddressesAndWeights the addresses and weights of all the recipients to receive rewards
   */
  function setConfigFromSource(
    bytes32 feedId,
    uint256 sourceChainId,
    address sourceAddress,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig,
    Common.AddressAndWeight[] memory recipientAddressesAndWeights
  ) external;

  /**
   * @notice Activates the configuration for a config digest
   * @param feedId Feed ID to activate config for
   * @param configDigest The config digest to activate
   * @dev This function can be called by the contract admin to activate a configuration.
   */
  function activateConfig(bytes32 feedId, bytes32 configDigest) external;

  /**
   * @notice Deactivates the configuration for a config digest
   * @param feedId Feed ID to deactivate config for
   * @param configDigest The config digest to deactivate
   * @dev This function can be called by the contract admin to deactivate an incorrect configuration.
   */
  function deactivateConfig(bytes32 feedId, bytes32 configDigest) external;

  /**
   * @notice Activates the given feed
   * @param feedId Feed ID to activated
   * @dev This function can be called by the contract admin to activate a feed
   */
  function activateFeed(bytes32 feedId) external;

  /**
   * @notice Deactivates the given feed
   * @param feedId Feed ID to deactivated
   * @dev This function can be called by the contract admin to deactivate a feed
   */
  function deactivateFeed(bytes32 feedId) external;

  /**
   * @notice returns the latest config digest and epoch for a feed
   * @param feedId Feed ID to fetch data for
   * @return scanLogs indicates whether to rely on the configDigest and epoch
   * returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
  function latestConfigDigestAndEpoch(
    bytes32 feedId
  ) external view returns (bool scanLogs, bytes32 configDigest, uint32 epoch);

  /**
   * @notice information about current offchain reporting protocol configuration
   * @param feedId Feed ID to fetch data for
   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   * @return configDigest domain-separation tag for current config
   */
  function latestConfigDetails(
    bytes32 feedId
  ) external view returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Common} from "../../libraries/Common.sol";
import {AccessControllerInterface} from "../../shared/interfaces/AccessControllerInterface.sol";
import {IVerifierFeeManager} from "./../dev/interfaces/IVerifierFeeManager.sol";

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payload The encoded data to be verified, including the signed
   * report and any metadata for billing.
   * @return verifierResponse The encoded report from the verifier.
   */
  function verify(bytes calldata payload) external payable returns (bytes memory verifierResponse);

  /**
   * @notice Bulk verifies that the data encoded has been signed
   * correctly by routing to the correct verifier, and bills the user if applicable.
   * @param payloads The encoded payloads to be verified, including the signed
   * report and any metadata for billing.
   * @return verifiedReports The encoded reports from the verifier.
   */
  function verifyBulk(bytes[] calldata payloads) external payable returns (bytes[] memory verifiedReports);

  /**
   * @notice Sets the verifier address initially, allowing `setVerifier` to be set by this Verifier in the future
   * @param verifierAddress The address of the verifier contract to initialize
   */
  function initializeVerifier(address verifierAddress) external;

  /**
   * @notice Sets a new verifier for a config digest
   * @param currentConfigDigest The current config digest
   * @param newConfigDigest The config digest to set
   * @param addressesAndWeights The addresses and weights of reward recipients
   * reports for a given config digest.
   */
  function setVerifier(
    bytes32 currentConfigDigest,
    bytes32 newConfigDigest,
    Common.AddressAndWeight[] memory addressesAndWeights
  ) external;

  /**
   * @notice Removes a verifier for a given config digest
   * @param configDigest The config digest of the verifier to remove
   */
  function unsetVerifier(bytes32 configDigest) external;

  /**
   * @notice Retrieves the verifier address that verifies reports
   * for a config digest.
   * @param configDigest The config digest to query for
   * @return verifierAddress The address of the verifier contract that verifies
   * reports for a given config digest.
   */
  function getVerifier(bytes32 configDigest) external view returns (address verifierAddress);

  /**
   * @notice Called by the admin to set an access controller contract
   * @param accessController The new access controller to set
   */
  function setAccessController(AccessControllerInterface accessController) external;

  /**
   * @notice Updates the fee manager
   * @param feeManager The new fee manager
   */
  function setFeeManager(IVerifierFeeManager feeManager) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IVerifier} from "../../interfaces/IVerifier.sol";
import {Common} from "../../../libraries/Common.sol";

contract ErroredVerifier is IVerifier {
  function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
    return interfaceId == this.verify.selector;
  }

  function verify(
    bytes memory,
    /**
     * signedReport*
     */
    address
  )
    external
    pure
    override
    returns (
      /**
       * sender*
       */
      bytes memory
    )
  {
    revert("Failed to verify");
  }

  function setConfig(
    bytes32,
    address[] memory,
    bytes32[] memory,
    uint8,
    bytes memory,
    uint64,
    bytes memory,
    Common.AddressAndWeight[] memory
  ) external pure override {
    revert("Failed to set config");
  }

  function setConfigFromSource(
    bytes32,
    uint256,
    address,
    address[] memory,
    bytes32[] memory,
    uint8,
    bytes memory,
    uint64,
    bytes memory,
    Common.AddressAndWeight[] memory
  ) external pure override {
    revert("Failed to set config");
  }

  function activateConfig(bytes32, bytes32) external pure {
    revert("Failed to activate config");
  }

  function deactivateConfig(bytes32, bytes32) external pure {
    revert("Failed to deactivate config");
  }

  function activateFeed(bytes32) external pure {
    revert("Failed to activate feed");
  }

  function deactivateFeed(bytes32) external pure {
    revert("Failed to deactivate feed");
  }

  function latestConfigDigestAndEpoch(bytes32) external pure override returns (bool, bytes32, uint32) {
    revert("Failed to get latest config digest and epoch");
  }

  function latestConfigDetails(bytes32) external pure override returns (uint32, uint32, bytes32) {
    revert("Failed to get latest config details");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// ExposedVerifier exposes certain internal Verifier
// methods/structures so that golang code can access them, and we get
// reliable type checking on their usage
contract ExposedVerifier {
  constructor() {}

  function _configDigestFromConfigData(
    bytes32 feedId,
    uint256 chainId,
    address contractAddress,
    uint64 configCount,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) internal pure returns (bytes32) {
    uint256 h = uint256(
      keccak256(
        abi.encode(
          feedId,
          chainId,
          contractAddress,
          configCount,
          signers,
          offchainTransmitters,
          f,
          onchainConfig,
          offchainConfigVersion,
          offchainConfig
        )
      )
    );
    uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
    uint256 prefix = 0x0006 << (256 - 16); // 0x000600..00
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  function exposedConfigDigestFromConfigData(
    bytes32 _feedId,
    uint256 _chainId,
    address _contractAddress,
    uint64 _configCount,
    address[] memory _signers,
    bytes32[] memory _offchainTransmitters,
    uint8 _f,
    bytes calldata _onchainConfig,
    uint64 _encodedConfigVersion,
    bytes memory _encodedConfig
  ) public pure returns (bytes32) {
    return
      _configDigestFromConfigData(
        _feedId,
        _chainId,
        _contractAddress,
        _configCount,
        _signers,
        _offchainTransmitters,
        _f,
        _onchainConfig,
        _encodedConfigVersion,
        _encodedConfig
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../dev/interfaces/IFeeManager.sol";

contract FeeManagerProxy {
  IFeeManager internal i_feeManager;

  function processFee(bytes calldata payload) public payable {
    i_feeManager.processFee{value: msg.value}(payload, msg.sender);
  }

  function processFeeBulk(bytes[] calldata payloads) public payable {
    i_feeManager.processFeeBulk{value: msg.value}(payloads, msg.sender);
  }

  function setFeeManager(IFeeManager feeManager) public {
    i_feeManager = feeManager;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ConfirmedOwner} from "../shared/access/ConfirmedOwner.sol";
import {IVerifier} from "./interfaces/IVerifier.sol";
import {IVerifierProxy} from "./interfaces/IVerifierProxy.sol";
import {TypeAndVersionInterface} from "../interfaces/TypeAndVersionInterface.sol";
import {IERC165} from "../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {Common} from "../libraries/Common.sol";

// OCR2 standard
uint256 constant MAX_NUM_ORACLES = 31;

/*
 * The verifier contract is used to verify offchain reports signed
 * by DONs. A report consists of a price, block number and feed Id. It
 * represents the observed price of an asset at a specified block number for
 * a feed. The verifier contract is used to verify that such reports have
 * been signed by the correct signers.
 **/
contract Verifier is IVerifier, ConfirmedOwner, TypeAndVersionInterface {
  // The first byte of the mask can be 0, because we only ever have 31 oracles
  uint256 internal constant ORACLE_MASK = 0x0001010101010101010101010101010101010101010101010101010101010101;

  enum Role {
    // Default role for an oracle address.  This means that the oracle address
    // is not a signer
    Unset,
    // Role given to an oracle address that is allowed to sign feed data
    Signer
  }

  struct Signer {
    // Index of oracle in a configuration
    uint8 index;
    // The oracle's role
    Role role;
  }

  struct Config {
    // Fault tolerance
    uint8 f;
    // Marks whether or not a configuration is active
    bool isActive;
    // Map of signer addresses to oracles
    mapping(address => Signer) oracles;
  }

  struct VerifierState {
    // The number of times a new configuration
    /// has been set
    uint32 configCount;
    // The block number of the block the last time
    /// the configuration was updated.
    uint32 latestConfigBlockNumber;
    // The latest epoch a report was verified for
    uint32 latestEpoch;
    // Whether or not the verifier for this feed has been deactivated
    bool isDeactivated;
    /// The latest config digest set
    bytes32 latestConfigDigest;
    /// The historical record of all previously set configs by feedId
    mapping(bytes32 => Config) s_verificationDataConfigs;
  }

  /// @notice This event is emitted when a new report is verified.
  /// It is used to keep a historical record of verified reports.
  event ReportVerified(bytes32 indexed feedId, address requester);

  /// @notice This event is emitted whenever a new configuration is set for a feed.  It triggers a new run of the offchain reporting protocol.
  event ConfigSet(
    bytes32 indexed feedId,
    uint32 previousConfigBlockNumber,
    bytes32 configDigest,
    uint64 configCount,
    address[] signers,
    bytes32[] offchainTransmitters,
    uint8 f,
    bytes onchainConfig,
    uint64 offchainConfigVersion,
    bytes offchainConfig
  );

  /// @notice This event is emitted whenever a configuration is deactivated
  event ConfigDeactivated(bytes32 indexed feedId, bytes32 configDigest);

  /// @notice This event is emitted whenever a configuration is activated
  event ConfigActivated(bytes32 indexed feedId, bytes32 configDigest);

  /// @notice This event is emitted whenever a feed is activated
  event FeedActivated(bytes32 indexed feedId);

  /// @notice This event is emitted whenever a feed is deactivated
  event FeedDeactivated(bytes32 indexed feedId);

  /// @notice This error is thrown whenever an address tries
  /// to exeecute a transaction that it is not authorized to do so
  error AccessForbidden();

  /// @notice This error is thrown whenever a zero address is passed
  error ZeroAddress();

  /// @notice This error is thrown whenever the feed ID passed in
  /// a signed report is empty
  error FeedIdEmpty();

  /// @notice This error is thrown whenever the config digest
  /// is empty
  error DigestEmpty();

  /// @notice This error is thrown whenever the config digest
  /// passed in has not been set in this verifier
  /// @param feedId The feed ID in the signed report
  /// @param configDigest The config digest that has not been set
  error DigestNotSet(bytes32 feedId, bytes32 configDigest);

  /// @notice This error is thrown whenever the config digest
  /// has been deactivated
  /// @param feedId The feed ID in the signed report
  /// @param configDigest The config digest that is inactive
  error DigestInactive(bytes32 feedId, bytes32 configDigest);

  /// @notice This error is thrown whenever trying to set a config
  /// with a fault tolerance of 0
  error FaultToleranceMustBePositive();

  /// @notice This error is thrown whenever a report is signed
  /// with more than the max number of signers
  /// @param numSigners The number of signers who have signed the report
  /// @param maxSigners The maximum number of signers that can sign a report
  error ExcessSigners(uint256 numSigners, uint256 maxSigners);

  /// @notice This error is thrown whenever a report is signed
  /// with less than the minimum number of signers
  /// @param numSigners The number of signers who have signed the report
  /// @param minSigners The minimum number of signers that need to sign a report
  error InsufficientSigners(uint256 numSigners, uint256 minSigners);

  /// @notice This error is thrown whenever a report is signed
  /// with an incorrect number of signers
  /// @param numSigners The number of signers who have signed the report
  /// @param expectedNumSigners The expected number of signers that need to sign
  /// a report
  error IncorrectSignatureCount(uint256 numSigners, uint256 expectedNumSigners);

  /// @notice This error is thrown whenever the R and S signer components
  /// have different lengths
  /// @param rsLength The number of r signature components
  /// @param ssLength The number of s signature components
  error MismatchedSignatures(uint256 rsLength, uint256 ssLength);

  /// @notice This error is thrown whenever setting a config with duplicate signatures
  error NonUniqueSignatures();

  /// @notice This error is thrown whenever a report fails to verify due to bad or duplicate signatures
  error BadVerification();

  /// @notice This error is thrown whenever the admin tries to deactivate
  /// the latest config digest
  /// @param feedId The feed ID in the signed report
  /// @param configDigest The latest config digest
  error CannotDeactivateLatestConfig(bytes32 feedId, bytes32 configDigest);

  /// @notice This error is thrown whenever the feed ID passed in is deactivated
  /// @param feedId The feed ID
  error InactiveFeed(bytes32 feedId);

  /// @notice This error is thrown whenever the feed ID passed in is not found
  /// @param feedId The feed ID
  error InvalidFeed(bytes32 feedId);

  /// @notice The address of the verifier proxy
  address private immutable i_verifierProxyAddr;

  /// @notice Verifier states keyed on Feed ID
  mapping(bytes32 => VerifierState) s_feedVerifierStates;

  /// @param verifierProxyAddr The address of the VerifierProxy contract
  constructor(address verifierProxyAddr) ConfirmedOwner(msg.sender) {
    if (verifierProxyAddr == address(0)) revert ZeroAddress();
    i_verifierProxyAddr = verifierProxyAddr;
  }

  modifier checkConfigValid(uint256 numSigners, uint256 f) {
    if (f == 0) revert FaultToleranceMustBePositive();
    if (numSigners > MAX_NUM_ORACLES) revert ExcessSigners(numSigners, MAX_NUM_ORACLES);
    if (numSigners <= 3 * f) revert InsufficientSigners(numSigners, 3 * f + 1);
    _;
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 interfaceId) external pure override returns (bool isVerifier) {
    return interfaceId == this.verify.selector;
  }

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "Verifier 1.1.0";
  }

  /// @inheritdoc IVerifier
  function verify(
    bytes calldata signedReport,
    address sender
  ) external override returns (bytes memory verifierResponse) {
    if (msg.sender != i_verifierProxyAddr) revert AccessForbidden();
    (
      bytes32[3] memory reportContext,
      bytes memory reportData,
      bytes32[] memory rs,
      bytes32[] memory ss,
      bytes32 rawVs
    ) = abi.decode(signedReport, (bytes32[3], bytes, bytes32[], bytes32[], bytes32));

    // The feed ID is the first 32 bytes of the report data.
    bytes32 feedId = bytes32(reportData);

    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

    // If the feed has been deactivated, do not verify the report
    if (feedVerifierState.isDeactivated) {
      revert InactiveFeed(feedId);
    }

    // reportContext consists of:
    // reportContext[0]: ConfigDigest
    // reportContext[1]: 27 byte padding, 4-byte epoch and 1-byte round
    // reportContext[2]: ExtraHash
    bytes32 configDigest = reportContext[0];
    Config storage s_config = feedVerifierState.s_verificationDataConfigs[configDigest];

    _validateReport(feedId, configDigest, rs, ss, s_config);
    _updateEpoch(reportContext, feedVerifierState);

    bytes32 hashedReport = keccak256(reportData);

    _verifySignatures(hashedReport, reportContext, rs, ss, rawVs, s_config);
    emit ReportVerified(feedId, sender);

    return reportData;
  }

  /// @notice Validates parameters of the report
  /// @param feedId Feed ID from the report
  /// @param configDigest Config digest from the report
  /// @param rs R components from the report
  /// @param ss S components from the report
  /// @param config Config for the given feed ID keyed on the config digest
  function _validateReport(
    bytes32 feedId,
    bytes32 configDigest,
    bytes32[] memory rs,
    bytes32[] memory ss,
    Config storage config
  ) private view {
    uint8 expectedNumSignatures = config.f + 1;

    if (!config.isActive) revert DigestInactive(feedId, configDigest);
    if (rs.length != expectedNumSignatures) revert IncorrectSignatureCount(rs.length, expectedNumSignatures);
    if (rs.length != ss.length) revert MismatchedSignatures(rs.length, ss.length);
  }

  /**
   * @notice Conditionally update the epoch for a feed
   * @param reportContext Report context containing the epoch and round
   * @param feedVerifierState Feed verifier state to conditionally update
   */
  function _updateEpoch(bytes32[3] memory reportContext, VerifierState storage feedVerifierState) private {
    uint40 epochAndRound = uint40(uint256(reportContext[1]));
    uint32 epoch = uint32(epochAndRound >> 8);
    if (epoch > feedVerifierState.latestEpoch) {
      feedVerifierState.latestEpoch = epoch;
    }
  }

  /// @notice Verifies that a report has been signed by the correct
  /// signers and that enough signers have signed the reports.
  /// @param hashedReport The keccak256 hash of the raw report's bytes
  /// @param reportContext The context the report was signed in
  /// @param rs ith element is the R components of the ith signature on report. Must have at most MAX_NUM_ORACLES entries
  /// @param ss ith element is the S components of the ith signature on report. Must have at most MAX_NUM_ORACLES entries
  /// @param rawVs ith element is the the V component of the ith signature
  /// @param s_config The config digest the report was signed for
  function _verifySignatures(
    bytes32 hashedReport,
    bytes32[3] memory reportContext,
    bytes32[] memory rs,
    bytes32[] memory ss,
    bytes32 rawVs,
    Config storage s_config
  ) private view {
    bytes32 h = keccak256(abi.encodePacked(hashedReport, reportContext));
    // i-th byte counts number of sigs made by i-th signer
    uint256 signedCount;

    Signer memory o;
    address signerAddress;
    uint256 numSigners = rs.length;
    for (uint256 i; i < numSigners; ++i) {
      signerAddress = ecrecover(h, uint8(rawVs[i]) + 27, rs[i], ss[i]);
      o = s_config.oracles[signerAddress];
      if (o.role != Role.Signer) revert BadVerification();
      unchecked {
        signedCount += 1 << (8 * o.index);
      }
    }

    if (signedCount & ORACLE_MASK != signedCount) revert BadVerification();
  }

  /// @inheritdoc IVerifier
  function setConfig(
    bytes32 feedId,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig,
    Common.AddressAndWeight[] memory recipientAddressesAndWeights
  ) external override checkConfigValid(signers.length, f) onlyOwner {
    _setConfig(
      feedId,
      block.chainid,
      address(this),
      signers,
      offchainTransmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig,
      recipientAddressesAndWeights
    );
  }

  /// @inheritdoc IVerifier
  function setConfigFromSource(
    bytes32 feedId,
    uint256 sourceChainId,
    address sourceAddress,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig,
    Common.AddressAndWeight[] memory recipientAddressesAndWeights
  ) external override checkConfigValid(signers.length, f) onlyOwner {
    _setConfig(
      feedId,
      sourceChainId,
      sourceAddress,
      signers,
      offchainTransmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig,
      recipientAddressesAndWeights
    );
  }

  /// @notice Sets config based on the given arguments
  /// @param feedId Feed ID to set config for
  /// @param sourceChainId Chain ID of source config
  /// @param sourceAddress Address of source config Verifier
  /// @param signers addresses with which oracles sign the reports
  /// @param offchainTransmitters CSA key for the ith Oracle
  /// @param f number of faulty oracles the system can tolerate
  /// @param onchainConfig serialized configuration used by the contract (and possibly oracles)
  /// @param offchainConfigVersion version number for offchainEncoding schema
  /// @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
  /// @param recipientAddressesAndWeights the addresses and weights of all the recipients to receive rewards
  function _setConfig(
    bytes32 feedId,
    uint256 sourceChainId,
    address sourceAddress,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig,
    Common.AddressAndWeight[] memory recipientAddressesAndWeights
  ) internal {
    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

    // Increment the number of times a config has been set first
    feedVerifierState.configCount++;

    bytes32 configDigest = _configDigestFromConfigData(
      feedId,
      sourceChainId,
      sourceAddress,
      feedVerifierState.configCount,
      signers,
      offchainTransmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig
    );

    feedVerifierState.s_verificationDataConfigs[configDigest].f = f;
    feedVerifierState.s_verificationDataConfigs[configDigest].isActive = true;
    for (uint8 i; i < signers.length; ++i) {
      address signerAddr = signers[i];
      if (signerAddr == address(0)) revert ZeroAddress();

      // All signer roles are unset by default for a new config digest.
      // Here the contract checks to see if a signer's address has already
      // been set to ensure that the group of signer addresses that will
      // sign reports with the config digest are unique.
      bool isSignerAlreadySet = feedVerifierState.s_verificationDataConfigs[configDigest].oracles[signerAddr].role !=
        Role.Unset;
      if (isSignerAlreadySet) revert NonUniqueSignatures();
      feedVerifierState.s_verificationDataConfigs[configDigest].oracles[signerAddr] = Signer({
        role: Role.Signer,
        index: i
      });
    }

    IVerifierProxy(i_verifierProxyAddr).setVerifier(
      feedVerifierState.latestConfigDigest,
      configDigest,
      recipientAddressesAndWeights
    );

    emit ConfigSet(
      feedId,
      feedVerifierState.latestConfigBlockNumber,
      configDigest,
      feedVerifierState.configCount,
      signers,
      offchainTransmitters,
      f,
      onchainConfig,
      offchainConfigVersion,
      offchainConfig
    );

    feedVerifierState.latestEpoch = 0;
    feedVerifierState.latestConfigBlockNumber = uint32(block.number);
    feedVerifierState.latestConfigDigest = configDigest;
  }

  /// @notice Generates the config digest from config data
  /// @param feedId Feed ID to set config for
  /// @param sourceChainId Chain ID of source config
  /// @param sourceAddress Address of source config Verifier
  /// @param configCount ordinal number of this config setting among all config settings over the life of this contract
  /// @param signers ith element is address ith oracle uses to sign a report
  /// @param offchainTransmitters ith element is address ith oracle used to transmit reports (in this case used for flexible additional field, such as CSA pub keys)
  /// @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
  /// @param onchainConfig serialized configuration used by the contract (and possibly oracles)
  /// @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
  /// @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
  /// @dev This function is a modified version of the method from OCR2Abstract
  function _configDigestFromConfigData(
    bytes32 feedId,
    uint256 sourceChainId,
    address sourceAddress,
    uint64 configCount,
    address[] memory signers,
    bytes32[] memory offchainTransmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) internal pure returns (bytes32) {
    uint256 h = uint256(
      keccak256(
        abi.encode(
          feedId,
          sourceChainId,
          sourceAddress,
          configCount,
          signers,
          offchainTransmitters,
          f,
          onchainConfig,
          offchainConfigVersion,
          offchainConfig
        )
      )
    );
    uint256 prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
    // 0x0006 corresponds to ConfigDigestPrefixMercuryV02 in libocr
    uint256 prefix = 0x0006 << (256 - 16); // 0x000600..00
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  /// @inheritdoc IVerifier
  function activateConfig(bytes32 feedId, bytes32 configDigest) external onlyOwner {
    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

    if (configDigest == bytes32("")) revert DigestEmpty();
    if (feedVerifierState.s_verificationDataConfigs[configDigest].f == 0) revert DigestNotSet(feedId, configDigest);
    feedVerifierState.s_verificationDataConfigs[configDigest].isActive = true;
    emit ConfigActivated(feedId, configDigest);
  }

  /// @inheritdoc IVerifier
  function deactivateConfig(bytes32 feedId, bytes32 configDigest) external onlyOwner {
    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

    if (configDigest == bytes32("")) revert DigestEmpty();
    if (feedVerifierState.s_verificationDataConfigs[configDigest].f == 0) revert DigestNotSet(feedId, configDigest);
    if (configDigest == feedVerifierState.latestConfigDigest) {
      revert CannotDeactivateLatestConfig(feedId, configDigest);
    }
    feedVerifierState.s_verificationDataConfigs[configDigest].isActive = false;
    emit ConfigDeactivated(feedId, configDigest);
  }

  /// @inheritdoc IVerifier
  function activateFeed(bytes32 feedId) external onlyOwner {
    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

    if (feedVerifierState.configCount == 0) revert InvalidFeed(feedId);
    feedVerifierState.isDeactivated = false;
    emit FeedActivated(feedId);
  }

  /// @inheritdoc IVerifier
  function deactivateFeed(bytes32 feedId) external onlyOwner {
    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];

    if (feedVerifierState.configCount == 0) revert InvalidFeed(feedId);
    feedVerifierState.isDeactivated = true;
    emit FeedDeactivated(feedId);
  }

  /// @inheritdoc IVerifier
  function latestConfigDigestAndEpoch(
    bytes32 feedId
  ) external view override returns (bool scanLogs, bytes32 configDigest, uint32 epoch) {
    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];
    return (false, feedVerifierState.latestConfigDigest, feedVerifierState.latestEpoch);
  }

  /// @inheritdoc IVerifier
  function latestConfigDetails(
    bytes32 feedId
  ) external view override returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest) {
    VerifierState storage feedVerifierState = s_feedVerifierStates[feedId];
    return (
      feedVerifierState.configCount,
      feedVerifierState.latestConfigBlockNumber,
      feedVerifierState.latestConfigDigest
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ConfirmedOwner} from "../shared/access/ConfirmedOwner.sol";
import {IVerifierProxy} from "./interfaces/IVerifierProxy.sol";
import {IVerifier} from "./interfaces/IVerifier.sol";
import {TypeAndVersionInterface} from "../interfaces/TypeAndVersionInterface.sol";
import {AccessControllerInterface} from "../shared/interfaces/AccessControllerInterface.sol";
import {IERC165} from "../vendor/openzeppelin-solidity/v4.8.0/contracts/interfaces/IERC165.sol";
import {IVerifierFeeManager} from "./dev/interfaces/IVerifierFeeManager.sol";
import {Common} from "../libraries/Common.sol";

/**
 * The verifier proxy contract is the gateway for all report verification requests
 * on a chain.  It is responsible for taking in a verification request and routing
 * it to the correct verifier contract.
 */
contract VerifierProxy is IVerifierProxy, ConfirmedOwner, TypeAndVersionInterface {
  /// @notice This event is emitted whenever a new verifier contract is set
  /// @param oldConfigDigest The config digest that was previously the latest config
  /// digest of the verifier contract at the verifier address.
  /// @param oldConfigDigest The latest config digest of the verifier contract
  /// at the verifier address.
  /// @param verifierAddress The address of the verifier contract that verifies reports for
  /// a given digest
  event VerifierSet(bytes32 oldConfigDigest, bytes32 newConfigDigest, address verifierAddress);

  /// @notice This event is emitted whenever a new verifier contract is initialized
  /// @param verifierAddress The address of the verifier contract that verifies reports
  event VerifierInitialized(address verifierAddress);

  /// @notice This event is emitted whenever a verifier is unset
  /// @param configDigest The config digest that was unset
  /// @param verifierAddress The Verifier contract address unset
  event VerifierUnset(bytes32 configDigest, address verifierAddress);

  /// @notice This event is emitted when a new access controller is set
  /// @param oldAccessController The old access controller address
  /// @param newAccessController The new access controller address
  event AccessControllerSet(address oldAccessController, address newAccessController);

  /// @notice This event is emitted when a new fee manager is set
  /// @param oldFeeManager The old fee manager address
  /// @param newFeeManager The new fee manager address
  event FeeManagerSet(address oldFeeManager, address newFeeManager);

  /// @notice This error is thrown whenever an address tries
  /// to exeecute a transaction that it is not authorized to do so
  error AccessForbidden();

  /// @notice This error is thrown whenever a zero address is passed
  error ZeroAddress();

  /// @notice This error is thrown when trying to set a verifier address
  /// for a digest that has already been initialized
  /// @param configDigest The digest for the verifier that has
  /// already been set
  /// @param verifier The address of the verifier the digest was set for
  error ConfigDigestAlreadySet(bytes32 configDigest, address verifier);

  /// @notice This error is thrown when trying to set a verifier address that has already been initialized
  error VerifierAlreadyInitialized(address verifier);

  /// @notice This error is thrown when the verifier at an address does
  /// not conform to the verifier interface
  error VerifierInvalid();

  /// @notice This error is thrown when the fee manager at an address does
  /// not conform to the fee manager interface
  error FeeManagerInvalid();

  /// @notice This error is thrown whenever a verifier is not found
  /// @param configDigest The digest for which a verifier is not found
  error VerifierNotFound(bytes32 configDigest);

  /// @notice This error is thrown whenever billing fails.
  error BadVerification();

  /// @notice Mapping of authorized verifiers
  mapping(address => bool) private s_initializedVerifiers;

  /// @notice Mapping between config digests and verifiers
  mapping(bytes32 => address) private s_verifiersByConfig;

  /// @notice The contract to control addresses that are allowed to verify reports
  AccessControllerInterface public s_accessController;

  /// @notice The contract to control fees for report verification
  IVerifierFeeManager public s_feeManager;

  constructor(AccessControllerInterface accessController) ConfirmedOwner(msg.sender) {
    s_accessController = accessController;
  }

  modifier checkAccess() {
    AccessControllerInterface ac = s_accessController;
    if (address(ac) != address(0) && !ac.hasAccess(msg.sender, msg.data)) revert AccessForbidden();
    _;
  }

  modifier onlyInitializedVerifier() {
    if (!s_initializedVerifiers[msg.sender]) revert AccessForbidden();
    _;
  }

  modifier onlyValidVerifier(address verifierAddress) {
    if (verifierAddress == address(0)) revert ZeroAddress();
    if (!IERC165(verifierAddress).supportsInterface(IVerifier.verify.selector)) revert VerifierInvalid();
    _;
  }

  modifier onlyUnsetConfigDigest(bytes32 configDigest) {
    address configDigestVerifier = s_verifiersByConfig[configDigest];
    if (configDigestVerifier != address(0)) revert ConfigDigestAlreadySet(configDigest, configDigestVerifier);
    _;
  }

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return "VerifierProxy 1.1.0";
  }

  /// @inheritdoc IVerifierProxy
  function verify(bytes calldata payload) external payable checkAccess returns (bytes memory) {
    IVerifierFeeManager feeManager = s_feeManager;

    // Bill the verifier
    if (address(feeManager) != address(0)) {
      feeManager.processFee{value: msg.value}(payload, msg.sender);
    }

    return _verify(payload);
  }

  /// @inheritdoc IVerifierProxy
  function verifyBulk(bytes[] calldata payloads) external payable checkAccess returns (bytes[] memory verifiedReports) {
    IVerifierFeeManager feeManager = s_feeManager;

    // Bill the verifier
    if (address(feeManager) != address(0)) {
      feeManager.processFeeBulk{value: msg.value}(payloads, msg.sender);
    }

    //verify the reports
    verifiedReports = new bytes[](payloads.length);
    for (uint256 i; i < payloads.length; ++i) {
      verifiedReports[i] = _verify(payloads[i]);
    }

    return verifiedReports;
  }

  function _verify(bytes calldata payload) internal returns (bytes memory verifiedReport) {
    // First 32 bytes of the signed report is the config digest
    bytes32 configDigest = bytes32(payload);
    address verifierAddress = s_verifiersByConfig[configDigest];
    if (verifierAddress == address(0)) revert VerifierNotFound(configDigest);

    return IVerifier(verifierAddress).verify(payload, msg.sender);
  }

  /// @inheritdoc IVerifierProxy
  function initializeVerifier(address verifierAddress) external override onlyOwner onlyValidVerifier(verifierAddress) {
    if (s_initializedVerifiers[verifierAddress]) revert VerifierAlreadyInitialized(verifierAddress);

    s_initializedVerifiers[verifierAddress] = true;
    emit VerifierInitialized(verifierAddress);
  }

  /// @inheritdoc IVerifierProxy
  function setVerifier(
    bytes32 currentConfigDigest,
    bytes32 newConfigDigest,
    Common.AddressAndWeight[] calldata addressesAndWeights
  ) external override onlyUnsetConfigDigest(newConfigDigest) onlyInitializedVerifier {
    s_verifiersByConfig[newConfigDigest] = msg.sender;

    // Empty recipients array will be ignored and must be set off chain
    if (addressesAndWeights.length > 0) {
      if (address(s_feeManager) == address(0)) {
        revert ZeroAddress();
      }

      s_feeManager.setFeeRecipients(newConfigDigest, addressesAndWeights);
    }

    emit VerifierSet(currentConfigDigest, newConfigDigest, msg.sender);
  }

  /// @inheritdoc IVerifierProxy
  function unsetVerifier(bytes32 configDigest) external override onlyOwner {
    address verifierAddress = s_verifiersByConfig[configDigest];
    if (verifierAddress == address(0)) revert VerifierNotFound(configDigest);
    delete s_verifiersByConfig[configDigest];
    emit VerifierUnset(configDigest, verifierAddress);
  }

  /// @inheritdoc IVerifierProxy
  function getVerifier(bytes32 configDigest) external view override returns (address) {
    return s_verifiersByConfig[configDigest];
  }

  /// @inheritdoc IVerifierProxy
  function setAccessController(AccessControllerInterface accessController) external onlyOwner {
    address oldAccessController = address(s_accessController);
    s_accessController = accessController;
    emit AccessControllerSet(oldAccessController, address(accessController));
  }

  /// @inheritdoc IVerifierProxy
  function setFeeManager(IVerifierFeeManager feeManager) external onlyOwner {
    if (address(feeManager) == address(0)) revert ZeroAddress();

    if (
      !IERC165(feeManager).supportsInterface(IVerifierFeeManager.processFee.selector) ||
      !IERC165(feeManager).supportsInterface(IVerifierFeeManager.processFeeBulk.selector)
    ) revert FeeManagerInvalid();

    address oldFeeManager = address(s_feeManager);
    s_feeManager = IVerifierFeeManager(feeManager);
    emit FeeManagerSet(oldFeeManager, address(feeManager));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is IOwnable {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface IERC677Receiver {
  function onTokenTransfer(address sender, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOwnable {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITypeAndVersion {
  function typeAndVersion() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWERC20 {
  function deposit() external payable;

  function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITypeAndVersion} from "../interfaces/ITypeAndVersion.sol";

abstract contract OCR2Abstract is ITypeAndVersion {
  // Maximum number of oracles the offchain reporting protocol is designed for
  uint256 internal constant maxNumOracles = 31;
  uint256 private constant prefixMask = type(uint256).max << (256 - 16); // 0xFFFF00..00
  uint256 private constant prefix = 0x0001 << (256 - 16); // 0x000100..00

  /**
   * @notice triggers a new run of the offchain reporting protocol
   * @param previousConfigBlockNumber block in which the previous config was set, to simplify historic analysis
   * @param configDigest configDigest of this configuration
   * @param configCount ordinal number of this config setting among all config settings over the life of this contract
   * @param signers ith element is address ith oracle uses to sign a report
   * @param transmitters ith element is address ith oracle uses to transmit a report via the transmit method
   * @param f maximum number of faulty/dishonest oracles the protocol can tolerate while still working correctly
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version of the serialization format used for "offchainConfig" parameter
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  event ConfigSet(
    uint32 previousConfigBlockNumber,
    bytes32 configDigest,
    uint64 configCount,
    address[] signers,
    address[] transmitters,
    uint8 f,
    bytes onchainConfig,
    uint64 offchainConfigVersion,
    bytes offchainConfig
  );

  /**
   * @notice sets offchain reporting protocol configuration incl. participating oracles
   * @param signers addresses with which oracles sign the reports
   * @param transmitters addresses oracles use to transmit the reports
   * @param f number of faulty oracles the system can tolerate
   * @param onchainConfig serialized configuration used by the contract (and possibly oracles)
   * @param offchainConfigVersion version number for offchainEncoding schema
   * @param offchainConfig serialized configuration used by the oracles exclusively and only passed through the contract
   */
  function setConfig(
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) external virtual;

  /**
   * @notice information about current offchain reporting protocol configuration
   * @return configCount ordinal number of current config, out of all configs applied to this contract so far
   * @return blockNumber block at which this config was set
   * @return configDigest domain-separation tag for current config (see _configDigestFromConfigData)
   */
  function latestConfigDetails()
    external
    view
    virtual
    returns (uint32 configCount, uint32 blockNumber, bytes32 configDigest);

  function _configDigestFromConfigData(
    uint256 chainId,
    address contractAddress,
    uint64 configCount,
    address[] memory signers,
    address[] memory transmitters,
    uint8 f,
    bytes memory onchainConfig,
    uint64 offchainConfigVersion,
    bytes memory offchainConfig
  ) internal pure returns (bytes32) {
    uint256 h = uint256(
      keccak256(
        abi.encode(
          chainId,
          contractAddress,
          configCount,
          signers,
          transmitters,
          f,
          onchainConfig,
          offchainConfigVersion,
          offchainConfig
        )
      )
    );
    return bytes32((prefix & prefixMask) | (h & ~prefixMask));
  }

  /**
  * @notice optionally emited to indicate the latest configDigest and epoch for
     which a report was successfully transmited. Alternatively, the contract may
     use latestConfigDigestAndEpoch with scanLogs set to false.
  */
  event Transmitted(bytes32 configDigest, uint32 epoch);

  /**
   * @notice optionally returns the latest configDigest and epoch for which a
     report was successfully transmitted. Alternatively, the contract may return
     scanLogs set to true and use Transmitted events to provide this information
     to offchain watchers.
   * @return scanLogs indicates whether to rely on the configDigest and epoch
     returned or whether to scan logs for the Transmitted event instead.
   * @return configDigest
   * @return epoch
   */
  function latestConfigDigestAndEpoch()
    external
    view
    virtual
    returns (bool scanLogs, bytes32 configDigest, uint32 epoch);

  /**
   * @notice transmit is called to post a new report to the contract
   * @param reportContext [0]: ConfigDigest, [1]: 27 byte padding, 4-byte epoch and 1-byte round, [2]: ExtraHash
   * @param report serialized report, which the signatures are signing.
   * @param rs ith element is the R components of the ith signature on report. Must have at most maxNumOracles entries
   * @param ss ith element is the S components of the ith signature on report. Must have at most maxNumOracles entries
   * @param rawVs ith element is the the V component of the ith signature
   */
  function transmit(
    // NOTE: If these parameters are changed, expectedMsgDataLength and/or
    // TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT need to be changed accordingly
    bytes32[3] calldata reportContext,
    bytes calldata report,
    bytes32[] calldata rs,
    bytes32[] calldata ss,
    bytes32 rawVs // signatures
  ) external virtual;
}

pragma solidity 0.8.16;

contract AutomationConsumerBenchmark {
  event PerformingUpkeep(uint256 id, address from, uint256 initialCall, uint256 nextEligible, uint256 blockNumber);

  mapping(uint256 => uint256) public initialCall;
  mapping(uint256 => uint256) public nextEligible;
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup
  mapping(uint256 => uint256) public count;
  uint256 deployedAt;

  constructor() {
    deployedAt = block.number;
  }

  function checkUpkeep(bytes calldata checkData) external view returns (bool, bytes memory) {
    (
      uint256 id,
      uint256 interval,
      uint256 range,
      uint256 checkBurnAmount,
      uint256 performBurnAmount,
      uint256 firstEligibleBuffer
    ) = abi.decode(checkData, (uint256, uint256, uint256, uint256, uint256, uint256));
    uint256 startGas = gasleft();
    bytes32 dummyIndex = blockhash(block.number - 1);
    bool dummy;
    // burn gas
    if (checkBurnAmount > 0 && eligible(id, range, firstEligibleBuffer)) {
      while (startGas - gasleft() < checkBurnAmount) {
        dummy = dummy && dummyMap[dummyIndex]; // arbitrary storage reads
        dummyIndex = keccak256(abi.encode(dummyIndex, address(this)));
      }
    }
    return (eligible(id, range, firstEligibleBuffer), checkData);
  }

  function performUpkeep(bytes calldata performData) external {
    (
      uint256 id,
      uint256 interval,
      uint256 range,
      uint256 checkBurnAmount,
      uint256 performBurnAmount,
      uint256 firstEligibleBuffer
    ) = abi.decode(performData, (uint256, uint256, uint256, uint256, uint256, uint256));
    require(eligible(id, range, firstEligibleBuffer));
    uint256 startGas = gasleft();
    if (initialCall[id] == 0) {
      initialCall[id] = block.number;
    }
    nextEligible[id] = block.number + interval;
    count[id]++;
    emit PerformingUpkeep(id, tx.origin, initialCall[id], nextEligible[id], block.number);
    // burn gas
    bytes32 dummyIndex = blockhash(block.number - 1);
    bool dummy;
    while (startGas - gasleft() < performBurnAmount) {
      dummy = dummy && dummyMap[dummyIndex]; // arbitrary storage reads
      dummyIndex = keccak256(abi.encode(dummyIndex, address(this)));
    }
  }

  function getCountPerforms(uint256 id) public view returns (uint256) {
    return count[id];
  }

  function eligible(uint256 id, uint256 range, uint256 firstEligibleBuffer) internal view returns (bool) {
    return
      initialCall[id] == 0
        ? block.number >= firstEligibleBuffer + deployedAt
        : (block.number - initialCall[id] < range && block.number > nextEligible[id]);
  }

  function checkEligible(uint256 id, uint256 range, uint256 firstEligibleBuffer) public view returns (bool) {
    return eligible(id, range, firstEligibleBuffer);
  }

  function reset() external {
    deployedAt = block.number;
  }
}

pragma solidity 0.8.16;

import "../automation/interfaces/AutomationCompatibleInterface.sol";
import "../dev/automation/2_1/interfaces/StreamsLookupCompatibleInterface.sol";
import {ArbSys} from "../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";

interface IVerifierProxy {
  /**
   * @notice Verifies that the data encoded has been signed
   * correctly by routing to the correct verifier.
   * @param signedReport The encoded data to be verified.
   * @return verifierResponse The encoded response from the verifier.
   */
  function verify(bytes memory signedReport) external returns (bytes memory verifierResponse);
}

contract StreamsLookupUpkeep is AutomationCompatibleInterface, StreamsLookupCompatibleInterface {
  event MercuryPerformEvent(address indexed sender, uint256 indexed blockNumber, bytes v0, bytes verifiedV0, bytes ed);

  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);
  // keep these in sync with verifier proxy in RDD
  IVerifierProxy internal constant PRODUCTION_TESTNET_VERIFIER_PROXY =
    IVerifierProxy(0x09DFf56A4fF44e0f4436260A04F5CFa65636A481);
  IVerifierProxy internal constant STAGING_TESTNET_VERIFIER_PROXY =
    IVerifierProxy(0x60448B880c9f3B501af3f343DA9284148BD7D77C);

  uint256 public testRange;
  uint256 public interval;
  uint256 public previousPerformBlock;
  uint256 public initialBlock;
  uint256 public counter;
  string[] public feeds;
  string public feedParamKey;
  string public timeParamKey;
  bool public immutable useArbBlock;
  bool public staging;
  bool public verify;
  bool public shouldRevertCallback;
  bool public callbackReturnBool;

  constructor(uint256 _testRange, uint256 _interval, bool _useArbBlock, bool _staging, bool _verify) {
    testRange = _testRange;
    interval = _interval;
    previousPerformBlock = 0;
    initialBlock = 0;
    counter = 0;
    useArbBlock = _useArbBlock;
    feedParamKey = "feedIDs"; // feedIDs for v0.3
    timeParamKey = "timestamp"; // timestamp
    // search feeds in notion: "Schema and Feed ID Registry"
    feeds = [
      //"0x4554482d5553442d415242495452554d2d544553544e45540000000000000000", // ETH / USD in production testnet v0.2
      //"0x4254432d5553442d415242495452554d2d544553544e45540000000000000000" // BTC / USD in production testnet v0.2
      "0x00028c915d6af0fd66bba2d0fc9405226bca8d6806333121a7d9832103d1563c" // ETH / USD in staging testnet v0.3
    ];
    staging = _staging;
    verify = _verify;
    callbackReturnBool = true;
  }

  function setParamKeys(string memory _feedParamKey, string memory _timeParamKey) external {
    feedParamKey = _feedParamKey;
    timeParamKey = _timeParamKey;
  }

  function setFeeds(string[] memory _feeds) external {
    feeds = _feeds;
  }

  function setShouldRevertCallback(bool value) public {
    shouldRevertCallback = value;
  }

  function setCallbackReturnBool(bool value) public {
    callbackReturnBool = value;
  }

  function reset() public {
    previousPerformBlock = 0;
    initialBlock = 0;
    counter = 0;
  }

  function checkCallback(bytes[] memory values, bytes memory extraData) external view returns (bool, bytes memory) {
    require(!shouldRevertCallback, "shouldRevertCallback is true");
    // do sth about the chainlinkBlob data in values and extraData
    bytes memory performData = abi.encode(values, extraData);
    return (callbackReturnBool, performData);
  }

  function checkUpkeep(bytes calldata data) external view returns (bool, bytes memory) {
    if (!eligible()) {
      return (false, data);
    }
    uint256 timeParam;
    if (keccak256(abi.encodePacked(feedParamKey)) == keccak256(abi.encodePacked("feedIdHex"))) {
      if (useArbBlock) {
        timeParam = ARB_SYS.arbBlockNumber();
      } else {
        timeParam = block.number;
      }
    } else {
      // assume this will be feedIDs for v0.3
      timeParam = block.timestamp;
    }

    // encode ARB_SYS as extraData to verify that it is provided to checkCallback correctly.
    // in reality, this can be any data or empty
    revert StreamsLookup(feedParamKey, feeds, timeParamKey, timeParam, abi.encodePacked(address(ARB_SYS)));
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 blockNumber;
    if (useArbBlock) {
      blockNumber = ARB_SYS.arbBlockNumber();
    } else {
      blockNumber = block.number;
    }
    if (initialBlock == 0) {
      initialBlock = blockNumber;
    }
    (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
    previousPerformBlock = blockNumber;
    counter = counter + 1;

    bytes memory v0 = "";
    bytes memory v1 = "";
    if (verify) {
      if (staging) {
        v0 = STAGING_TESTNET_VERIFIER_PROXY.verify(values[0]);
      } else {
        v0 = PRODUCTION_TESTNET_VERIFIER_PROXY.verify(values[0]);
      }
    }
    emit MercuryPerformEvent(msg.sender, blockNumber, values[0], v0, extraData);
  }

  function eligible() public view returns (bool) {
    if (initialBlock == 0) {
      return true;
    }

    uint256 blockNumber;
    if (useArbBlock) {
      blockNumber = ARB_SYS.arbBlockNumber();
    } else {
      blockNumber = block.number;
    }
    return (blockNumber - initialBlock) < testRange && (blockNumber - previousPerformBlock) >= interval;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../vendor/openzeppelin-solidity/v4.7.3/contracts/utils/structs/EnumerableSet.sol";
import "../dev/automation/2_1/interfaces/IKeeperRegistryMaster.sol";
import {ArbSys} from "../vendor/@arbitrum/nitro-contracts/src/precompiles/ArbSys.sol";
import "../dev/automation/2_1/AutomationRegistrar2_1.sol";
import {LogTriggerConfig} from "../dev/automation/2_1/AutomationUtils2_1.sol";

abstract contract VerifiableLoadBase is ConfirmedOwner {
  error IndexOutOfRange();
  event LogEmitted(uint256 indexed upkeepId, uint256 indexed blockNum, address indexed addr);
  event LogEmittedAgain(uint256 indexed upkeepId, uint256 indexed blockNum, address indexed addr);
  event UpkeepTopUp(uint256 upkeepId, uint96 amount, uint256 blockNum);

  using EnumerableSet for EnumerableSet.UintSet;
  ArbSys internal constant ARB_SYS = ArbSys(0x0000000000000000000000000000000000000064);
  //bytes32 public constant emittedSig = 0x97009585a4d2440f981ab6f6eec514343e1e6b2aa9b991a26998e6806f41bf08; //keccak256(LogEmitted(uint256,uint256,address))
  bytes32 public immutable emittedSig = LogEmitted.selector;
  // bytes32 public constant emittedAgainSig = 0xc76416badc8398ce17c93eab7b4f60f263241694cf503e4df24f233a8cc1c50d; //keccak256(LogEmittedAgain(uint256,uint256,address))
  bytes32 public immutable emittedAgainSig = LogEmittedAgain.selector;

  mapping(uint256 => uint256) public lastTopUpBlocks;
  mapping(uint256 => uint256) public intervals;
  mapping(uint256 => uint256) public previousPerformBlocks;
  mapping(uint256 => uint256) public firstPerformBlocks;
  mapping(uint256 => uint256) public counters;
  mapping(uint256 => uint256) public performGasToBurns;
  mapping(uint256 => uint256) public checkGasToBurns;
  mapping(uint256 => uint256) public performDataSizes;
  mapping(uint256 => uint256) public gasLimits;
  mapping(bytes32 => bool) public dummyMap; // used to force storage lookup
  mapping(uint256 => uint256[]) public delays; // how to query for delays for a certain past period: calendar day and/or past 24 hours

  mapping(uint256 => mapping(uint16 => uint256[])) public bucketedDelays;
  mapping(uint256 => uint16) public buckets;
  EnumerableSet.UintSet internal s_upkeepIDs;
  AutomationRegistrar2_1 public registrar;
  LinkTokenInterface public linkToken;
  IKeeperRegistryMaster public registry;
  // check if an upkeep is eligible for adding funds at this interval
  uint256 public upkeepTopUpCheckInterval = 5;
  // an upkeep will get this amount of LINK for every top up
  uint96 public addLinkAmount = 200000000000000000; // 0.2 LINK
  // if an upkeep's balance is less than this threshold * min balance, this upkeep is eligible for adding funds
  uint8 public minBalanceThresholdMultiplier = 20;
  // if this contract is using arbitrum block number
  bool public immutable useArbitrumBlockNum;

  // the following fields are immutable bc if they are adjusted, the existing upkeeps' delays will be stored in
  // different sizes of buckets. it's better to redeploy this contract with new values.
  uint16 public immutable BUCKET_SIZE = 100;

  // search feeds in notion: "Schema and Feed ID Registry"
  string[] public feedsHex = [
    "0x4554482d5553442d415242495452554d2d544553544e45540000000000000000",
    "0x4254432d5553442d415242495452554d2d544553544e45540000000000000000"
  ];
  string public feedParamKey = "feedIdHex"; // feedIDs for v0.3
  string public timeParamKey = "blockNumber"; // timestamp for v0.3

  /**
   * @param _registrar a automation registrar 2.1 address
   * @param _useArb if this contract will use arbitrum block number
   */
  constructor(AutomationRegistrar2_1 _registrar, bool _useArb) ConfirmedOwner(msg.sender) {
    registrar = _registrar;
    (address registryAddress, ) = registrar.getConfig();
    registry = IKeeperRegistryMaster(payable(address(registryAddress)));
    linkToken = registrar.LINK();
    useArbitrumBlockNum = _useArb;
  }

  receive() external payable {}

  function setParamKeys(string memory _feedParamKey, string memory _timeParamKey) external {
    feedParamKey = _feedParamKey;
    timeParamKey = _timeParamKey;
  }

  function setFeeds(string[] memory _feeds) external {
    feedsHex = _feeds;
  }

  /**
   * @notice withdraws LINKs from this contract to msg sender when testing is finished.
   */
  function withdrawLinks() external onlyOwner {
    uint256 balance = linkToken.balanceOf(address(this));
    linkToken.transfer(msg.sender, balance);
  }

  function getBlockNumber() internal view returns (uint256) {
    if (useArbitrumBlockNum) {
      return ARB_SYS.arbBlockNumber();
    } else {
      return block.number;
    }
  }

  /**
   * @notice sets registrar, registry, and link token address.
   * @param newRegistrar the new registrar address
   */
  function setConfig(AutomationRegistrar2_1 newRegistrar) external {
    registrar = newRegistrar;
    (address registryAddress, ) = registrar.getConfig();
    registry = IKeeperRegistryMaster(payable(address(registryAddress)));
    linkToken = registrar.LINK();
  }

  /**
   * @notice gets an array of active upkeep IDs.
   * @param startIndex the start index of upkeep IDs
   * @param maxCount the max number of upkeep IDs requested
   * @return an array of active upkeep IDs
   */
  function getActiveUpkeepIDsDeployedByThisContract(
    uint256 startIndex,
    uint256 maxCount
  ) external view returns (uint256[] memory) {
    uint256 maxIdx = s_upkeepIDs.length();
    if (startIndex >= maxIdx) revert IndexOutOfRange();
    if (maxCount == 0) {
      maxCount = maxIdx - startIndex;
    }
    uint256[] memory ids = new uint256[](maxCount);
    for (uint256 idx = 0; idx < maxCount; idx++) {
      ids[idx] = s_upkeepIDs.at(startIndex + idx);
    }
    return ids;
  }

  /**
   * @notice gets an array of active upkeep IDs.
   * @param startIndex the start index of upkeep IDs
   * @param maxCount the max number of upkeep IDs requested
   * @return an array of active upkeep IDs
   */
  function getAllActiveUpkeepIDsOnRegistry(
    uint256 startIndex,
    uint256 maxCount
  ) external view returns (uint256[] memory) {
    return registry.getActiveUpkeepIDs(startIndex, maxCount);
  }

  /**
   * @notice register an upkeep via the registrar.
   * @param params a registration params struct
   * @return an upkeep ID
   */
  function _registerUpkeep(AutomationRegistrar2_1.RegistrationParams memory params) private returns (uint256) {
    uint256 upkeepId = registrar.registerUpkeep(params);
    s_upkeepIDs.add(upkeepId);
    gasLimits[upkeepId] = params.gasLimit;
    return upkeepId;
  }

  /**
   * @notice returns a log trigger config
   */
  function getLogTriggerConfig(
    address addr,
    uint8 selector,
    bytes32 topic0,
    bytes32 topic1,
    bytes32 topic2,
    bytes32 topic3
  ) external view returns (bytes memory logTrigger) {
    LogTriggerConfig memory cfg = LogTriggerConfig({
      contractAddress: addr,
      filterSelector: selector,
      topic0: topic0,
      topic1: topic1,
      topic2: topic2,
      topic3: topic3
    });
    return abi.encode(cfg);
  }

  // this function sets pipeline data and trigger config for log trigger upkeeps
  function batchPreparingUpkeeps(
    uint256[] calldata upkeepIds,
    uint8 selector,
    bytes32 topic0,
    bytes32 topic1,
    bytes32 topic2,
    bytes32 topic3
  ) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 upkeepId = upkeepIds[i];

      this.updateUpkeepPipelineData(upkeepId, abi.encode(upkeepId));

      uint8 triggerType = registry.getTriggerType(upkeepId);
      if (triggerType == 1) {
        // currently no using a filter selector
        bytes memory triggerCfg = this.getLogTriggerConfig(address(this), selector, topic0, topic2, topic2, topic3);
        registry.setUpkeepTriggerConfig(upkeepId, triggerCfg);
      }
    }
  }

  // this function sets pipeline data and trigger config for log trigger upkeeps
  function batchPreparingUpkeepsSimple(uint256[] calldata upkeepIds, uint8 log, uint8 selector) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 upkeepId = upkeepIds[i];

      this.updateUpkeepPipelineData(upkeepId, abi.encode(upkeepId));

      uint8 triggerType = registry.getTriggerType(upkeepId);
      if (triggerType == 1) {
        // currently no using a filter selector
        bytes32 sig = emittedSig;
        if (log != 0) {
          sig = emittedAgainSig;
        }
        bytes memory triggerCfg = this.getLogTriggerConfig(
          address(this),
          selector,
          sig,
          bytes32(abi.encode(upkeepId)),
          bytes32(0),
          bytes32(0)
        );
        registry.setUpkeepTriggerConfig(upkeepId, triggerCfg);
      }
    }
  }

  function updateLogTriggerConfig1(
    uint256 upkeepId,
    address addr,
    uint8 selector,
    bytes32 topic0,
    bytes32 topic1,
    bytes32 topic2,
    bytes32 topic3
  ) external {
    registry.setUpkeepTriggerConfig(upkeepId, this.getLogTriggerConfig(addr, selector, topic0, topic1, topic2, topic3));
  }

  function updateLogTriggerConfig2(uint256 upkeepId, bytes calldata cfg) external {
    registry.setUpkeepTriggerConfig(upkeepId, cfg);
  }

  /**
   * @notice batch registering upkeeps.
   * @param number the number of upkeeps to be registered
   * @param gasLimit the gas limit of each upkeep
   * @param triggerType the trigger type of this upkeep, 0 for conditional, 1 for log trigger
   * @param triggerConfig the trigger config of this upkeep
   * @param amount the amount of LINK to fund each upkeep
   * @param checkGasToBurn the amount of check gas to burn
   * @param performGasToBurn the amount of perform gas to burn
   */
  function batchRegisterUpkeeps(
    uint8 number,
    uint32 gasLimit,
    uint8 triggerType,
    bytes memory triggerConfig,
    uint96 amount,
    uint256 checkGasToBurn,
    uint256 performGasToBurn
  ) external {
    AutomationRegistrar2_1.RegistrationParams memory params = AutomationRegistrar2_1.RegistrationParams({
      name: "test",
      encryptedEmail: bytes(""),
      upkeepContract: address(this),
      gasLimit: gasLimit,
      adminAddress: address(this), // use address of this contract as the admin
      triggerType: triggerType,
      checkData: bytes(""), // update pipeline data later bc upkeep id is not available now
      triggerConfig: triggerConfig,
      offchainConfig: bytes(""),
      amount: amount
    });

    linkToken.approve(address(registrar), amount * number);

    uint256[] memory upkeepIds = new uint256[](number);
    for (uint8 i = 0; i < number; i++) {
      uint256 upkeepId = _registerUpkeep(params);
      upkeepIds[i] = upkeepId;
      checkGasToBurns[upkeepId] = checkGasToBurn;
      performGasToBurns[upkeepId] = performGasToBurn;
    }
  }

  function topUpFund(uint256 upkeepId, uint256 blockNum) public {
    if (blockNum - lastTopUpBlocks[upkeepId] > upkeepTopUpCheckInterval) {
      KeeperRegistryBase2_1.UpkeepInfo memory info = registry.getUpkeep(upkeepId);
      uint96 minBalance = registry.getMinBalanceForUpkeep(upkeepId);
      if (info.balance < minBalanceThresholdMultiplier * minBalance) {
        addFunds(upkeepId, addLinkAmount);
        lastTopUpBlocks[upkeepId] = blockNum;
        emit UpkeepTopUp(upkeepId, addLinkAmount, blockNum);
      }
    }
  }

  function getMinBalanceForUpkeep(uint256 upkeepId) external view returns (uint96) {
    return registry.getMinBalanceForUpkeep(upkeepId);
  }

  function getForwarder(uint256 upkeepID) external view returns (address) {
    return registry.getForwarder(upkeepID);
  }

  function getBalance(uint256 id) external view returns (uint96 balance) {
    return registry.getBalance(id);
  }

  function getTriggerType(uint256 upkeepId) external view returns (uint8) {
    return registry.getTriggerType(upkeepId);
  }

  function burnPerformGas(uint256 upkeepId, uint256 startGas, uint256 blockNum) public {
    uint256 performGasToBurn = performGasToBurns[upkeepId];
    while (startGas - gasleft() + 10000 < performGasToBurn) {
      dummyMap[blockhash(blockNum)] = false;
    }
  }

  /**
   * @notice adds fund for an upkeep.
   * @param upkeepId the upkeep ID
   * @param amount the amount of LINK to be funded for the upkeep
   */
  function addFunds(uint256 upkeepId, uint96 amount) public {
    linkToken.approve(address(registry), amount);
    registry.addFunds(upkeepId, amount);
  }

  /**
   * @notice updates pipeline data for an upkeep. In order for the upkeep to be performed, the pipeline data must be the abi encoded upkeep ID.
   * @param upkeepId the upkeep ID
   * @param pipelineData the new pipeline data for the upkeep
   */
  function updateUpkeepPipelineData(uint256 upkeepId, bytes calldata pipelineData) external {
    registry.setUpkeepCheckData(upkeepId, pipelineData);
  }

  function withdrawLinks(uint256 upkeepId) external {
    registry.withdrawFunds(upkeepId, address(this));
  }

  function batchWithdrawLinks(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint32 i = 0; i < len; i++) {
      this.withdrawLinks(upkeepIds[i]);
    }
  }

  /**
   * @notice batch canceling upkeeps.
   * @param upkeepIds an array of upkeep IDs
   */
  function batchCancelUpkeeps(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint8 i = 0; i < len; i++) {
      registry.cancelUpkeep(upkeepIds[i]);
      s_upkeepIDs.remove(upkeepIds[i]);
    }
  }

  function eligible(uint256 upkeepId) public view returns (bool) {
    if (firstPerformBlocks[upkeepId] == 0) {
      return true;
    }
    return (getBlockNumber() - previousPerformBlocks[upkeepId]) >= intervals[upkeepId];
  }

  //  /**
  //   * @notice set a new add LINK amount.
  //   * @param amount the new value
  //   */
  //  function setAddLinkAmount(uint96 amount) external {
  //    addLinkAmount = amount;
  //  }
  //
  //  function setUpkeepTopUpCheckInterval(uint256 newInterval) external {
  //    upkeepTopUpCheckInterval = newInterval;
  //  }
  //
  //  function setMinBalanceThresholdMultiplier(uint8 newMinBalanceThresholdMultiplier) external {
  //    minBalanceThresholdMultiplier = newMinBalanceThresholdMultiplier;
  //  }

  //  function setPerformGasToBurn(uint256 upkeepId, uint256 value) public {
  //    performGasToBurns[upkeepId] = value;
  //  }
  //
  //  function setCheckGasToBurn(uint256 upkeepId, uint256 value) public {
  //    checkGasToBurns[upkeepId] = value;
  //  }

  function setPerformDataSize(uint256 upkeepId, uint256 value) public {
    performDataSizes[upkeepId] = value;
  }

  function setUpkeepGasLimit(uint256 upkeepId, uint32 gasLimit) public {
    registry.setUpkeepGasLimit(upkeepId, gasLimit);
    gasLimits[upkeepId] = gasLimit;
  }

  function setInterval(uint256 upkeepId, uint256 _interval) external {
    intervals[upkeepId] = _interval;
    firstPerformBlocks[upkeepId] = 0;
    counters[upkeepId] = 0;

    delete delays[upkeepId];
    uint16 currentBucket = buckets[upkeepId];
    for (uint16 i = 0; i <= currentBucket; i++) {
      delete bucketedDelays[upkeepId][i];
    }
    delete buckets[upkeepId];
  }

  /**
   * @notice batch setting intervals for an array of upkeeps.
   * @param upkeepIds an array of upkeep IDs
   * @param interval a new interval
   */
  function batchSetIntervals(uint256[] calldata upkeepIds, uint32 interval) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      this.setInterval(upkeepIds[i], interval);
    }
  }

  /**
   * @notice batch updating pipeline data for all upkeeps.
   * @param upkeepIds an array of upkeep IDs
   */
  function batchUpdatePipelineData(uint256[] calldata upkeepIds) external {
    uint256 len = upkeepIds.length;
    for (uint256 i = 0; i < len; i++) {
      uint256 upkeepId = upkeepIds[i];
      this.updateUpkeepPipelineData(upkeepId, abi.encode(upkeepId));
    }
  }

  /**
   * @notice finds all log trigger upkeeps and emits logs to serve as the initial trigger for upkeeps
   */
  function batchSendLogs(uint8 log) external {
    uint256[] memory upkeepIds = this.getActiveUpkeepIDsDeployedByThisContract(0, 0);
    uint256 len = upkeepIds.length;
    uint256 blockNum = getBlockNumber();
    for (uint256 i = 0; i < len; i++) {
      uint256 upkeepId = upkeepIds[i];
      uint8 triggerType = registry.getTriggerType(upkeepId);
      if (triggerType == 1) {
        if (log == 0) {
          emit LogEmitted(upkeepId, blockNum, address(this));
        } else {
          emit LogEmittedAgain(upkeepId, blockNum, address(this));
        }
      }
    }
  }

  function getUpkeepInfo(uint256 upkeepId) public view returns (KeeperRegistryBase2_1.UpkeepInfo memory) {
    return registry.getUpkeep(upkeepId);
  }

  function getUpkeepTriggerConfig(uint256 upkeepId) public view returns (bytes memory) {
    return registry.getUpkeepTriggerConfig(upkeepId);
  }

  function getUpkeepPrivilegeConfig(uint256 upkeepId) public view returns (bytes memory) {
    return registry.getUpkeepPrivilegeConfig(upkeepId);
  }

  function setUpkeepPrivilegeConfig(uint256 upkeepId, bytes memory cfg) external {
    registry.setUpkeepPrivilegeConfig(upkeepId, cfg);
  }

  function sendLog(uint256 upkeepId, uint8 log) external {
    uint256 blockNum = getBlockNumber();
    if (log == 0) {
      emit LogEmitted(upkeepId, blockNum, address(this));
    } else {
      emit LogEmittedAgain(upkeepId, blockNum, address(this));
    }
  }

  function getDelaysLength(uint256 upkeepId) public view returns (uint256) {
    return delays[upkeepId].length;
  }

  function getBucketedDelaysLength(uint256 upkeepId) public view returns (uint256) {
    uint16 currentBucket = buckets[upkeepId];
    uint256 len = 0;
    for (uint16 i = 0; i <= currentBucket; i++) {
      len += bucketedDelays[upkeepId][i].length;
    }
    return len;
  }

  function getDelays(uint256 upkeepId) public view returns (uint256[] memory) {
    return delays[upkeepId];
  }

  function getBucketedDelays(uint256 upkeepId, uint16 bucket) public view returns (uint256[] memory) {
    return bucketedDelays[upkeepId][bucket];
  }

  function getSumDelayLastNPerforms(uint256 upkeepId, uint256 n) public view returns (uint256, uint256) {
    uint256[] memory delays = delays[upkeepId];
    return getSumDelayLastNPerforms(delays, n);
  }

  function getSumDelayInBucket(uint256 upkeepId, uint16 bucket) public view returns (uint256, uint256) {
    uint256[] memory delays = bucketedDelays[upkeepId][bucket];
    return getSumDelayLastNPerforms(delays, delays.length);
  }

  function getSumDelayLastNPerforms(uint256[] memory delays, uint256 n) internal view returns (uint256, uint256) {
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256 sum = 0;

    for (i = 0; i < n; i++) sum = sum + delays[len - i - 1];
    return (sum, n);
  }

  function getPxDelayLastNPerforms(uint256 upkeepId, uint256 p, uint256 n) public view returns (uint256) {
    return getPxDelayLastNPerforms(delays[upkeepId], p, n);
  }

  function getPxDelayLastNPerforms(uint256[] memory delays, uint256 p, uint256 n) internal view returns (uint256) {
    uint256 i;
    uint256 len = delays.length;
    if (n == 0 || n >= len) {
      n = len;
    }
    uint256[] memory subArr = new uint256[](n);

    for (i = 0; i < n; i++) subArr[i] = (delays[len - i - 1]);
    quickSort(subArr, int256(0), int256(subArr.length - 1));

    if (p == 100) {
      return subArr[subArr.length - 1];
    }
    return subArr[(p * subArr.length) / 100];
  }

  function quickSort(uint256[] memory arr, int256 left, int256 right) private pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
      while (arr[uint256(i)] < pivot) i++;
      while (pivot < arr[uint256(j)]) j--;
      if (i <= j) {
        (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) quickSort(arr, left, j);
    if (i < right) quickSort(arr, i, right);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./VerifiableLoadBase.sol";
import "../dev/automation/2_1/interfaces/ILogAutomation.sol";
import "../dev/automation/2_1/interfaces/StreamsLookupCompatibleInterface.sol";

contract VerifiableLoadLogTriggerUpkeep is VerifiableLoadBase, StreamsLookupCompatibleInterface, ILogAutomation {
  bool public useMercury;
  uint8 public logNum;

  /**
   * @param _registrar a automation registrar 2.1 address
   * @param _useArb if this contract will use arbitrum block number
   * @param _useMercury if the log trigger upkeeps will use mercury lookup
   */
  constructor(
    AutomationRegistrar2_1 _registrar,
    bool _useArb,
    bool _useMercury
  ) VerifiableLoadBase(_registrar, _useArb) {
    useMercury = _useMercury;
    logNum = 0;
  }

  function setLog(uint8 _log) external {
    logNum = _log;
  }

  function checkLog(Log calldata log, bytes memory checkData) external returns (bool, bytes memory) {
    uint256 startGas = gasleft();
    uint256 blockNum = getBlockNumber();
    uint256 uid = abi.decode(checkData, (uint256));

    bytes32 sig = emittedSig;
    if (logNum != 0) {
      sig = emittedAgainSig;
    }
    // filter by event signature
    if (log.topics[0] == sig) {
      bytes memory t1 = abi.encodePacked(log.topics[1]); // bytes32 to bytes
      uint256 upkeepId = abi.decode(t1, (uint256));
      if (upkeepId != uid) {
        revert("upkeep ids don't match");
      }
      bytes memory t2 = abi.encodePacked(log.topics[2]);
      uint256 blockNum = abi.decode(t2, (uint256));

      bytes memory t3 = abi.encodePacked(log.topics[3]);
      address addr = abi.decode(t3, (address));

      uint256 checkGasToBurn = checkGasToBurns[upkeepId];
      while (startGas - gasleft() + 15000 < checkGasToBurn) {
        dummyMap[blockhash(blockNum)] = false;
      }

      uint256 timeParam;
      if (keccak256(abi.encodePacked(feedParamKey)) == keccak256(abi.encodePacked("feedIdHex"))) {
        timeParam = blockNum;
      } else {
        // assume this will be feedIDs for v0.3
        timeParam = block.timestamp;
      }

      if (useMercury) {
        revert StreamsLookup(feedParamKey, feedsHex, timeParamKey, timeParam, abi.encode(upkeepId, blockNum, addr));
      }

      // if we don't use mercury, create a perform data which resembles the output of checkCallback
      bytes[] memory values = new bytes[](feedsHex.length);
      bytes memory extraData = abi.encode(upkeepId, blockNum, addr);
      return (true, abi.encode(values, extraData));
    }
    revert("unexpected event sig");
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 startGas = gasleft();
    (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
    (uint256 upkeepId, uint256 logBlockNumber, address addr) = abi.decode(extraData, (uint256, uint256, address));

    uint256 firstPerformBlock = firstPerformBlocks[upkeepId];
    uint256 previousPerformBlock = previousPerformBlocks[upkeepId];
    uint256 currentBlockNum = getBlockNumber();

    if (firstPerformBlock == 0) {
      firstPerformBlocks[upkeepId] = currentBlockNum;
    } else {
      uint256 delay = currentBlockNum - logBlockNumber;
      uint16 bucket = buckets[upkeepId];
      uint256[] memory bucketDelays = bucketedDelays[upkeepId][bucket];
      if (bucketDelays.length == BUCKET_SIZE) {
        bucket++;
        buckets[upkeepId] = bucket;
      }
      bucketedDelays[upkeepId][bucket].push(delay);
      delays[upkeepId].push(delay);
    }

    uint256 counter = counters[upkeepId] + 1;
    counters[upkeepId] = counter;
    previousPerformBlocks[upkeepId] = currentBlockNum;

    // for every upkeepTopUpCheckInterval (5), check if the upkeep balance is at least
    // minBalanceThresholdMultiplier (20) * min balance. If not, add addLinkAmount (0.2) to the upkeep
    // upkeepTopUpCheckInterval, minBalanceThresholdMultiplier, and addLinkAmount are configurable
    topUpFund(upkeepId, currentBlockNum);
    emit LogEmitted(upkeepId, currentBlockNum, address(this));
    burnPerformGas(upkeepId, startGas, currentBlockNum);
  }

  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external pure override returns (bool, bytes memory) {
    bytes memory performData = abi.encode(values, extraData);
    return (true, performData);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./VerifiableLoadBase.sol";
import "../dev/automation/2_1/interfaces/StreamsLookupCompatibleInterface.sol";

contract VerifiableLoadStreamsLookupUpkeep is VerifiableLoadBase, StreamsLookupCompatibleInterface {
  constructor(AutomationRegistrar2_1 _registrar, bool _useArb) VerifiableLoadBase(_registrar, _useArb) {}

  function checkCallback(
    bytes[] memory values,
    bytes memory extraData
  ) external pure override returns (bool, bytes memory) {
    // do sth about the chainlinkBlob data in values and extraData
    bytes memory performData = abi.encode(values, extraData);
    return (true, performData);
  }

  function checkUpkeep(bytes calldata checkData) external returns (bool, bytes memory) {
    uint256 startGas = gasleft();
    uint256 upkeepId = abi.decode(checkData, (uint256));

    uint256 performDataSize = performDataSizes[upkeepId];
    uint256 checkGasToBurn = checkGasToBurns[upkeepId];
    bytes memory pData = abi.encode(upkeepId, new bytes(performDataSize));
    uint256 blockNum = getBlockNumber();
    bool needed = eligible(upkeepId);
    while (startGas - gasleft() + 10000 < checkGasToBurn) {
      // 10K margin over gas to burn
      // Hard coded check gas to burn
      dummyMap[blockhash(blockNum)] = false; // arbitrary storage writes
    }
    if (!needed) {
      return (false, pData);
    }

    uint256 timeParam;
    if (keccak256(abi.encodePacked(feedParamKey)) == keccak256(abi.encodePacked("feedIdHex"))) {
      timeParam = blockNum;
    } else {
      // assume this will be feedIDs for v0.3
      timeParam = block.timestamp;
    }

    revert StreamsLookup(feedParamKey, feedsHex, timeParamKey, timeParam, abi.encode(upkeepId));
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 startGas = gasleft();
    (bytes[] memory values, bytes memory extraData) = abi.decode(performData, (bytes[], bytes));
    uint256 upkeepId = abi.decode(extraData, (uint256));
    uint256 firstPerformBlock = firstPerformBlocks[upkeepId];
    uint256 previousPerformBlock = previousPerformBlocks[upkeepId];
    uint256 blockNum = getBlockNumber();

    if (firstPerformBlock == 0) {
      firstPerformBlocks[upkeepId] = blockNum;
    } else {
      uint256 delay = blockNum - previousPerformBlock - intervals[upkeepId];
      uint16 bucket = buckets[upkeepId];
      uint256[] memory bucketDelays = bucketedDelays[upkeepId][bucket];
      if (bucketDelays.length == BUCKET_SIZE) {
        bucket++;
        buckets[upkeepId] = bucket;
      }
      bucketedDelays[upkeepId][bucket].push(delay);
      delays[upkeepId].push(delay);
    }

    uint256 counter = counters[upkeepId] + 1;
    counters[upkeepId] = counter;
    previousPerformBlocks[upkeepId] = blockNum;

    topUpFund(upkeepId, blockNum);
    burnPerformGas(upkeepId, startGas, blockNum);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./VerifiableLoadBase.sol";

contract VerifiableLoadUpkeep is VerifiableLoadBase {
  constructor(AutomationRegistrar2_1 _registrar, bool _useArb) VerifiableLoadBase(_registrar, _useArb) {}

  function checkUpkeep(bytes calldata checkData) external returns (bool, bytes memory) {
    uint256 startGas = gasleft();
    uint256 upkeepId = abi.decode(checkData, (uint256));

    uint256 performDataSize = performDataSizes[upkeepId];
    uint256 checkGasToBurn = checkGasToBurns[upkeepId];
    bytes memory pData = abi.encode(upkeepId, new bytes(performDataSize));
    uint256 blockNum = getBlockNumber();
    bool needed = eligible(upkeepId);
    while (startGas - gasleft() + 10000 < checkGasToBurn) {
      dummyMap[blockhash(blockNum)] = false;
      blockNum--;
    }
    return (needed, pData);
  }

  function performUpkeep(bytes calldata performData) external {
    uint256 startGas = gasleft();
    (uint256 upkeepId, ) = abi.decode(performData, (uint256, bytes));
    uint256 firstPerformBlock = firstPerformBlocks[upkeepId];
    uint256 previousPerformBlock = previousPerformBlocks[upkeepId];
    uint256 blockNum = getBlockNumber();
    if (firstPerformBlock == 0) {
      firstPerformBlocks[upkeepId] = blockNum;
    } else {
      uint256 delay = blockNum - previousPerformBlock - intervals[upkeepId];
      uint16 bucket = buckets[upkeepId];
      uint256[] memory bucketDelays = bucketedDelays[upkeepId][bucket];
      if (bucketDelays.length == BUCKET_SIZE) {
        bucket++;
        buckets[upkeepId] = bucket;
      }
      bucketedDelays[upkeepId][bucket].push(delay);
      delays[upkeepId].push(delay);
    }

    uint256 counter = counters[upkeepId] + 1;
    counters[upkeepId] = counter;
    previousPerformBlocks[upkeepId] = blockNum;

    topUpFund(upkeepId, blockNum);
    burnPerformGas(upkeepId, startGas, blockNum);
  }
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

interface ArbGasInfo {
    // return gas prices in wei, assuming the specified aggregator is used
    //        (
    //            per L2 tx,
    //            per L1 calldata unit, (zero byte = 4 units, nonzero byte = 16 units)
    //            per storage allocation,
    //            per ArbGas base,
    //            per ArbGas congestion,
    //            per ArbGas total
    //        )
    function getPricesInWeiWithAggregator(address aggregator) external view returns (uint, uint, uint, uint, uint, uint);

    // return gas prices in wei, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInWei() external view returns (uint, uint, uint, uint, uint, uint);

    // return prices in ArbGas (per L2 tx, per L1 calldata unit, per storage allocation),
    //       assuming the specified aggregator is used
    function getPricesInArbGasWithAggregator(address aggregator) external view returns (uint, uint, uint);

    // return gas prices in ArbGas, as described above, assuming the caller's preferred aggregator is used
    //     if the caller hasn't specified a preferred aggregator, the default aggregator is assumed
    function getPricesInArbGas() external view returns (uint, uint, uint);

    // return gas accounting parameters (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams() external view returns (uint, uint, uint);

    // get ArbOS's estimate of the L1 gas price in wei
    function getL1GasPriceEstimate() external view returns(uint);

    // set ArbOS's estimate of the L1 gas price in wei
    // reverts unless called by chain owner or designated gas oracle (if any)
    function setL1GasPriceEstimate(uint priceInWei) external;

    // get L1 gas fees paid by the current transaction (txBaseFeeWei, calldataFeeWei)
    function getCurrentTxL1GasFees() external view returns(uint);
}

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/nitro/blob/master/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/**
 * @title System level functionality
 * @notice For use by contracts to interact with core L2-specific functionality.
 * Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064.
 */
interface ArbSys {
    /**
     * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
     * @return block number as int
     */
    function arbBlockNumber() external view returns (uint256);

    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);

    /**
     * @notice Gets the rollup's unique chain identifier
     * @return Chain identifier as int
     */
    function arbChainID() external view returns (uint256);

    /**
     * @notice Get internal version number identifying an ArbOS build
     * @return version number as int
     */
    function arbOSVersion() external view returns (uint256);

    /**
     * @notice Returns 0 since Nitro has no concept of storage gas
     * @return uint 0
     */
    function getStorageGasAvailable() external view returns (uint256);

    /**
     * @notice (deprecated) check if current call is top level (meaning it was triggered by an EoA or a L1 contract)
     * @dev this call has been deprecated and may be removed in a future release
     * @return true if current execution frame is not a call by another L2 contract
     */
    function isTopLevelCall() external view returns (bool);

    /**
     * @notice map L1 sender contract address to its L2 alias
     * @param sender sender address
     * @param unused argument no longer used
     * @return aliased sender address
     */
    function mapL1SenderContractAddressToL2Alias(address sender, address unused)
        external
        pure
        returns (address);

    /**
     * @notice check if the caller (of this caller of this) is an aliased L1 contract address
     * @return true iff the caller's address is an alias for an L1 contract address
     */
    function wasMyCallersAddressAliased() external view returns (bool);

    /**
     * @notice return the address of the caller (of this caller of this), without applying L1 contract address aliasing
     * @return address of the caller's caller, without applying L1 contract address aliasing
     */
    function myCallersAddressWithoutAliasing() external view returns (address);

    /**
     * @notice Send given amount of Eth to dest from sender.
     * This is a convenience function, which is equivalent to calling sendTxToL1 with empty data.
     * @param destination recipient address on L1
     * @return unique identifier for this L2-to-L1 transaction.
     */
    function withdrawEth(address destination)
        external
        payable
        returns (uint256);

    /**
     * @notice Send a transaction to L1
     * @dev it is not possible to execute on the L1 any L2-to-L1 transaction which contains data
     * to a contract address without any code (as enforced by the Bridge contract).
     * @param destination recipient address on L1
     * @param data (optional) calldata for L1 contract call
     * @return a unique identifier for this L2-to-L1 transaction.
     */
    function sendTxToL1(address destination, bytes calldata data)
        external
        payable
        returns (uint256);

    /**
     * @notice Get send Merkle tree state
     * @return size number of sends in the history
     * @return root root hash of the send history
     * @return partials hashes of partial subtrees in the send history tree
     */
    function sendMerkleTreeState()
        external
        view
        returns (
            uint256 size,
            bytes32 root,
            bytes32[] memory partials
        );

    /**
     * @notice creates a send txn from L2 to L1
     * @param position = (level << 192) + leaf = (0 << 192) + leaf = leaf
     */
    event L2ToL1Tx(
        address caller,
        address indexed destination,
        uint256 indexed hash,
        uint256 indexed position,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /// @dev DEPRECATED in favour of the new L2ToL1Tx event above after the nitro upgrade
    event L2ToL1Transaction(
        address caller,
        address indexed destination,
        uint256 indexed uniqueId,
        uint256 indexed batchNumber,
        uint256 indexInBatch,
        uint256 arbBlockNum,
        uint256 ethBlockNum,
        uint256 timestamp,
        uint256 callvalue,
        bytes data
    );

    /**
     * @notice logs a merkle branch for proof synthesis
     * @param reserved an index meant only to align the 4th index with L2ToL1Transaction's 4th event
     * @param hash the merkle hash
     * @param position = (level << 192) + leaf
     */
    event SendMerkleUpdate(
        uint256 indexed reserved,
        bytes32 indexed hash,
        uint256 indexed position
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* External Imports */
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title OVM_GasPriceOracle
 * @dev This contract exposes the current l2 gas price, a measure of how congested the network
 * currently is. This measure is used by the Sequencer to determine what fee to charge for
 * transactions. When the system is more congested, the l2 gas price will increase and fees
 * will also increase as a result.
 *
 * All public variables are set while generating the initial L2 state. The
 * constructor doesn't run in practice as the L2 state generation script uses
 * the deployed bytecode instead of running the initcode.
 */
contract OVM_GasPriceOracle is Ownable {
  /*************
   * Variables *
   *************/

  // Current L2 gas price
  uint256 public gasPrice;
  // Current L1 base fee
  uint256 public l1BaseFee;
  // Amortized cost of batch submission per transaction
  uint256 public overhead;
  // Value to scale the fee up by
  uint256 public scalar;
  // Number of decimals of the scalar
  uint256 public decimals;

  /***************
   * Constructor *
   ***************/

  /**
   * @param _owner Address that will initially own this contract.
   */
  constructor(address _owner) Ownable() {
    transferOwnership(_owner);
  }

  /**********
   * Events *
   **********/

  event GasPriceUpdated(uint256);
  event L1BaseFeeUpdated(uint256);
  event OverheadUpdated(uint256);
  event ScalarUpdated(uint256);
  event DecimalsUpdated(uint256);

  /********************
   * Public Functions *
   ********************/

  /**
   * Allows the owner to modify the l2 gas price.
   * @param _gasPrice New l2 gas price.
   */
  // slither-disable-next-line external-function
  function setGasPrice(uint256 _gasPrice) public onlyOwner {
    gasPrice = _gasPrice;
    emit GasPriceUpdated(_gasPrice);
  }

  /**
   * Allows the owner to modify the l1 base fee.
   * @param _baseFee New l1 base fee
   */
  // slither-disable-next-line external-function
  function setL1BaseFee(uint256 _baseFee) public onlyOwner {
    l1BaseFee = _baseFee;
    emit L1BaseFeeUpdated(_baseFee);
  }

  /**
   * Allows the owner to modify the overhead.
   * @param _overhead New overhead
   */
  // slither-disable-next-line external-function
  function setOverhead(uint256 _overhead) public onlyOwner {
    overhead = _overhead;
    emit OverheadUpdated(_overhead);
  }

  /**
   * Allows the owner to modify the scalar.
   * @param _scalar New scalar
   */
  // slither-disable-next-line external-function
  function setScalar(uint256 _scalar) public onlyOwner {
    scalar = _scalar;
    emit ScalarUpdated(_scalar);
  }

  /**
   * Allows the owner to modify the decimals.
   * @param _decimals New decimals
   */
  // slither-disable-next-line external-function
  function setDecimals(uint256 _decimals) public onlyOwner {
    decimals = _decimals;
    emit DecimalsUpdated(_decimals);
  }

  /**
   * Computes the L1 portion of the fee
   * based on the size of the RLP encoded tx
   * and the current l1BaseFee
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return L1 fee that should be paid for the tx
   */
  // slither-disable-next-line external-function
  function getL1Fee(bytes memory _data) public view returns (uint256) {
    uint256 l1GasUsed = getL1GasUsed(_data);
    uint256 l1Fee = l1GasUsed * l1BaseFee;
    uint256 divisor = 10 ** decimals;
    uint256 unscaled = l1Fee * scalar;
    uint256 scaled = unscaled / divisor;
    return scaled;
  }

  // solhint-disable max-line-length
  /**
   * Computes the amount of L1 gas used for a transaction
   * The overhead represents the per batch gas overhead of
   * posting both transaction and state roots to L1 given larger
   * batch sizes.
   * 4 gas for 0 byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L33
   * 16 gas for non zero byte
   * https://github.com/ethereum/go-ethereum/blob/9ada4a2e2c415e6b0b51c50e901336872e028872/params/protocol_params.go#L87
   * This will need to be updated if calldata gas prices change
   * Account for the transaction being unsigned
   * Padding is added to account for lack of signature on transaction
   * 1 byte for RLP V prefix
   * 1 byte for V
   * 1 byte for RLP R prefix
   * 32 bytes for R
   * 1 byte for RLP S prefix
   * 32 bytes for S
   * Total: 68 bytes of padding
   * @param _data Unsigned RLP encoded tx, 6 elements
   * @return Amount of L1 gas used for a transaction
   */
  // solhint-enable max-line-length
  function getL1GasUsed(bytes memory _data) public view returns (uint256) {
    uint256 total = 0;
    for (uint256 i = 0; i < _data.length; i++) {
      if (_data[i] == 0) {
        total += 4;
      } else {
        total += 16;
      }
    }
    uint256 unsigned = total + overhead;
    return unsigned + (68 * 16);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

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

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
    // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
    // the target address contains contract code and also asserts for success in the low-level call.

    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      // Return data is optional
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
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
  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
  function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
  function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
      if (value >= 10 ** 64) {
        value /= 10 ** 64;
        result += 64;
      }
      if (value >= 10 ** 32) {
        value /= 10 ** 32;
        result += 32;
      }
      if (value >= 10 ** 16) {
        value /= 10 ** 16;
        result += 16;
      }
      if (value >= 10 ** 8) {
        value /= 10 ** 8;
        result += 8;
      }
      if (value >= 10 ** 4) {
        value /= 10 ** 4;
        result += 4;
      }
      if (value >= 10 ** 2) {
        value /= 10 ** 2;
        result += 2;
      }
      if (value >= 10 ** 1) {
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
      return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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