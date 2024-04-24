// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import {IAaveCLRobotOperator} from '../interfaces/IAaveCLRobotOperator.sol';
import {IInitializableRobotOperator} from '../interfaces/IInitializableRobotOperator.sol';
import {IKeeperRegistrar} from '../interfaces/IKeeperRegistrar.sol';
import {IKeeperRegistry} from '../interfaces/IKeeperRegistry.sol';
import {IERC20} from 'solidity-utils/contracts/oz-common/interfaces/IERC20.sol';
import {SafeERC20} from 'solidity-utils/contracts/oz-common/SafeERC20.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';
import {Initializable} from 'solidity-utils/contracts/transparent-proxy/Initializable.sol';
import {EnumerableSet} from 'solidity-utils/contracts/oz-common/EnumerableSet.sol';

/**
 * @title AaveCLRobotOperator
 * @author BGD Labs
 * @dev Operator contract to perform admin actions on the automation keepers.
 *      The contract can register keepers, cancel it, pause it, withdraw excess link,
 *      refill the keeper, configure the keeper.
 */
contract AaveCLRobotOperator is OwnableWithGuardian, Initializable, IAaveCLRobotOperator {
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.UintSet;

  // stores the keepers registered which are not in cancelled state by the operator contract.
  EnumerableSet.UintSet internal _keepers;

  mapping(uint256 id => KeeperInfo) internal _keepersInfo;

  address internal _keeperRegistry;
  address internal _keeperRegistrar;
  address internal _linkToken;
  address internal _linkWithdrawAddress;

  /// @inheritdoc IInitializableRobotOperator
  function initialize(
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner,
    address operatorGuardian
  ) external initializer {
    _keeperRegistry = keeperRegistry;
    _keeperRegistrar = keeperRegistrar;
    _linkWithdrawAddress = linkWithdrawAddress;
    _linkToken = IKeeperRegistry(_keeperRegistry).getLinkAddress();
    _transferOwnership(operatorOwner);
    _updateGuardian(operatorGuardian);
    emit Initialized(keeperRegistry, keeperRegistrar, linkWithdrawAddress, operatorOwner, operatorGuardian);
  }

  /// @notice In order to fund the keeper we need to approve the Link token amount to this contract
  /// @inheritdoc IAaveCLRobotOperator
  function register(
    string calldata name,
    address upkeepContract,
    bytes calldata upkeepCheckData,
    uint32 gasLimit,
    uint96 amountToFund,
    uint8 triggerType,
    bytes calldata triggerConfig
  ) external onlyOwner returns (uint256) {
    IERC20(_linkToken).safeTransferFrom(msg.sender, address(this), amountToFund);

    IKeeperRegistrar.RegistrationParams memory params = IKeeperRegistrar.RegistrationParams({
      name: name, // name of the keeper to register
      encryptedEmail: '', // encryptedEmail to send alerts to, unused
      upkeepContract: upkeepContract, // address of the upkeep contract
      gasLimit: gasLimit, // max gasLimit which can be used for an performUpkeep action
      adminAddress: address(this), // admin of the keeper is set to this address of AaveCLRobotOperator
      triggerType: triggerType, // 0 for conditional type keeper, 1 for log type
      checkData: upkeepCheckData, // checkData of the keeper which get passed to the checkUpkeep
      triggerConfig: triggerConfig, // configuration for log type keeper, else unused
      offchainConfig: '', // unused
      amount: amountToFund // amount of link to fund the keeper with
    });

    IERC20(_linkToken).forceApprove(_keeperRegistrar, amountToFund);
    uint256 id = IKeeperRegistrar(_keeperRegistrar).registerUpkeep(params);

    if (id != 0) {
      _keepersInfo[id].upkeep = upkeepContract;
      _keepersInfo[id].name = name;
      _keepers.add(id);

      emit KeeperRegistered(id, upkeepContract, amountToFund);

      return id;
    } else {
      revert('AUTO_APPROVE_DISABLED');
    }
  }

  /// @inheritdoc IAaveCLRobotOperator
  function cancel(uint256 id) external onlyOwner {
    IKeeperRegistry(_keeperRegistry).cancelUpkeep(id);
    _keepers.remove(id);

    emit KeeperCancelled(id, _keepersInfo[id].upkeep);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function withdrawLink(uint256 id) external {
    IKeeperRegistry(_keeperRegistry).withdrawFunds(id, _linkWithdrawAddress);
    emit LinkWithdrawn(id, _keepersInfo[id].upkeep, _linkWithdrawAddress);
  }

  /// @notice In order to refill the keeper we need to approve the Link token amount to this contract
  /// @inheritdoc IAaveCLRobotOperator
  function refillKeeper(uint256 id, uint96 amount) external {
    IERC20(_linkToken).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(_linkToken).forceApprove(_keeperRegistry, amount);
    IKeeperRegistry(_keeperRegistry).addFunds(id, amount);
    emit KeeperRefilled(id, msg.sender, amount);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function pause(uint256 id) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).pauseUpkeep(id);
    emit KeeperPaused(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function unpause(uint256 id) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).unpauseUpkeep(id);
    emit KeeperUnpaused(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function migrate(address newRegistry, address newRegistrar) external onlyOwner {
    IKeeperRegistry(_keeperRegistry).migrateUpkeeps(_keepers.values(), newRegistry);

    setRegistry(newRegistry);
    setRegistrar(newRegistrar);
    emit KeepersMigrated(_keepers.values(), newRegistry, newRegistrar);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setGasLimit(uint256 id, uint32 gasLimit) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).setUpkeepGasLimit(id, gasLimit);
    emit GasLimitSet(id, _keepersInfo[id].upkeep, gasLimit);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setTriggerConfig(uint256 id, bytes calldata triggerConfig) external onlyOwnerOrGuardian {
    IKeeperRegistry(_keeperRegistry).setUpkeepTriggerConfig(id, triggerConfig);
    emit TriggerConfigSet(id);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setWithdrawAddress(address withdrawAddress) external onlyOwner {
    _linkWithdrawAddress = withdrawAddress;
    emit WithdrawAddressSet(withdrawAddress);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setRegistry(address newRegistry) public onlyOwner {
    _keeperRegistry = newRegistry;
    emit KeeperRegistrySet(newRegistry);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setRegistrar(address newRegistrar) public onlyOwner {
    _keeperRegistrar = newRegistrar;
    emit KeeperRegistrarSet(newRegistrar);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getWithdrawAddress() external view returns (address) {
    return _linkWithdrawAddress;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getKeeperInfo(uint256 id) external view returns (KeeperInfo memory) {
    return _keepersInfo[id];
  }

  /// @inheritdoc IAaveCLRobotOperator
  function isPaused(uint256 id) external view returns (bool) {
    return IKeeperRegistry(_keeperRegistry).getUpkeep(id).paused;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getRegistry() public view returns (address) {
    return _keeperRegistry;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getRegistrar() public view returns (address) {
    return _keeperRegistrar;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getKeepersList() public view returns (uint256[] memory) {
    return _keepers.values();
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getLinkToken() external view returns (address) {
    return _linkToken;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IInitializableRobotOperator} from './IInitializableRobotOperator.sol';

/**
 * @title IAaveCLRobotOperator
 * @author BGD Labs
 * @notice Defines the interface for the robot operator contract to perform admin actions on the automation keepers.
 **/
interface IAaveCLRobotOperator is IInitializableRobotOperator {
  /**
   * @dev Emitted when a keeper is registered using the operator contract.
   * @param id id of the keeper registered.
   * @param upkeep address of the keeper contract.
   * @param amount amount of link the keeper has been registered with.
   */
  event KeeperRegistered(uint256 indexed id, address indexed upkeep, uint96 indexed amount);

  /**
   * @dev Emitted when a keeper is cancelled using the operator contract.
   * @param id id of the keeper cancelled.
   * @param upkeep address of the keeper contract.
   */
  event KeeperCancelled(uint256 indexed id, address indexed upkeep);

  /**
   * @dev Emitted when a keeper is already cancelled, and link is being withdrawn using the operator contract.
   * @param id id of the keeper to withdraw link from.
   * @param upkeep address of the keeper contract.
   * @param to address where link needs to be withdrawn to.
   */
  event LinkWithdrawn(uint256 indexed id, address indexed upkeep, address indexed to);

  /**
   * @dev Emitted when a keeper is refilled using the operator contract.
   * @param id id of the keeper which has been refilled.
   * @param from address which refilled the keeper.
   * @param amount amount of link which has been refilled for the keeper.
   */
  event KeeperRefilled(uint256 indexed id, address indexed from, uint96 indexed amount);

  /**
   * @dev Emitted when a keeper is paused using the operator contract.
   * @param id id of the keeper which has been paused.
   */
  event KeeperPaused(uint256 indexed id);

  /**
   * @dev Emitted when a keeper is unpaused using the operator contract.
   * @param id id of the keeper which has been unpaused.
   */
  event KeeperUnpaused(uint256 indexed id);

  /**
   * @dev Emitted when the link withdraw address has been changed of the keeper.
   * @param newWithdrawAddress address of the new withdraw address where link will be withdrawn to.
   */
  event WithdrawAddressSet(address indexed newWithdrawAddress);

  /**
   * @dev Emitted when gas limit is configured using the operator contract.
   * @param id id of the keeper for which gas limit has been configured.
   * @param upkeep address of the keeper contract.
   * @param gasLimit max gas limit which has been configured for the keeper.
   */
  event GasLimitSet(uint256 indexed id, address indexed upkeep, uint32 indexed gasLimit);

  /**
   * @dev Emitted when trigger config is configured for a log type robot using the operator contract.
   * @param id id of the keeper for which trigger config has been configured.
   */
  event TriggerConfigSet(uint256 indexed id);

  /**
   * @dev Emitted when a new chainlink keeper registry is set on the operator contract.
   * @param newKeeperRegistry address of the new chainlink keeper registry contract.
   */
  event KeeperRegistrySet(address indexed newKeeperRegistry);

  /**
   * @dev Emitted when a new chainlink keeper registrar is set on the operator contract.
   * @param newKeeperRegistrar address of the new chainlink keeper registrar contract.
   */
  event KeeperRegistrarSet(address indexed newKeeperRegistrar);

  /**
   * @dev Emitted when a the keepers are migrated to a new chainlink keeper registry contract.
   * @param ids array of ids all the chainlink keepers to migrate.
   * @param newKeeperRegistry address of the new chainlink keeper registry contract to migrate to.
   * @param newKeeperRegistrar address of the new chainlink keeper registrar contract associated with the registry.
   */
  event KeepersMigrated(
    uint256[] indexed ids,
    address indexed newKeeperRegistry,
    address indexed newKeeperRegistrar
  );

  /**
   * @notice holds the keeper info registered via the operator.
   * @param upkeep address of the keeper contract registered.
   * @param name name of the registered keeper.
   */
  struct KeeperInfo {
    address upkeep;
    string name;
  }

  /**
   * @notice method called by owner to register the automation robot keeper.
   * @param name name of keeper.
   * @param upkeepContract upkeepContract of the keeper.
   * @param upkeepCheckData checkData of the keeper which get passed to the checkUpkeep.
   * @param gasLimit max gasLimit which the chainlink automation node can execute for the automation.
   * @param amountToFund amount of link to fund the keeper with.
   * @param triggerType type of robot keeper to register, 0 for conditional and 1 for event log based.
   * @param triggerConfig encoded trigger config for event log based robots, unused for conditional type robots.
   * @return chainlink id for the registered keeper.
   **/
  function register(
    string calldata name,
    address upkeepContract,
    bytes calldata upkeepCheckData,
    uint32 gasLimit,
    uint96 amountToFund,
    uint8 triggerType,
    bytes calldata triggerConfig
  ) external returns (uint256);

  /**
   * @notice method called to refill the keeper.
   * @param id - id of the chainlink registered keeper to refill.
   * @param amount - amount of LINK to refill the keeper with.
   **/
  function refillKeeper(uint256 id, uint96 amount) external;

  /**
   * @notice method called by the owner to cancel the automation robot keeper.
   * @param id - id of the chainlink registered keeper to cancel.
   **/
  function cancel(uint256 id) external;

  /**
   * @notice method called permissionlessly to withdraw link of automation robot keeper to the withdraw address.
   *         this method should only be called after the automation robot keeper is cancelled.
   * @param id - id of the chainlink registered keeper to withdraw funds of.
   **/
  function withdrawLink(uint256 id) external;

  /**
   * @notice method called by the owner to migrate the keepers to a newer version of chainlink automation.
   * @param newRegistry address of the new chainlink registry to migrate the keepers to.
   * @param newRegistrar address of the new associated chainlink registrar of the new registry.
   **/
  function migrate(address newRegistry, address newRegistrar) external;

  /**
   * @notice method called by owner / robot guardian to pause the upkeep robot keeper.
   * @param id - id of the chainlink registered keeper to pause.
   **/
  function pause(uint256 id) external;

  /**
   * @notice method called by owner / robot guardian to unpause the upkeep robot keeper.
   * @param id - id of the chainlink registered keeper to unpause.
   **/
  function unpause(uint256 id) external;

  /**
   * @notice method to check if the keeper is paused or not.
   * @param id - id of the chainlink registered keeper to check.
   * @return true if the keeper is paused, false otherwise.
   **/
  function isPaused(uint256 id) external returns (bool);

  /**
   * @notice method called by owner / robot guardian to set the max gasLimit of upkeep robot keeper.
   * @param id - id of the chainlink registered keeper to set the gasLimit.
   * @param gasLimit max gasLimit which the chainlink automation node can execute.
   **/
  function setGasLimit(uint256 id, uint32 gasLimit) external;

  /**
   * @notice method called by owner to set the withdraw address when withdrawing excess link from the automation robot keeeper.
   * @param withdrawAddress withdraw address to withdaw link to.
   **/
  function setWithdrawAddress(address withdrawAddress) external;

  /**
   * @notice method called by owner / guardian to set the trigger configuration for event log type robots.
   * @param id - id of the chainlink registered keeper to set the trigger config.
   * @param triggerConfig encoded data containing the configuration
   *        Ex:
   *        abi.encode(
   *          address contractAddress, (address that will be emitting the log)
   *          uint8 filterSelector, (denoting which topics apply to filter ex 000, 101, 111...only last 3 bits apply)
   *          bytes32 topic0, (signature of the emitted event)
   *          bytes32 topic1, (filter on indexed topic 1)
   *          bytes32 topic2, (filter on indexed topic 2)
   *          bytes32 topic3 (filter on indexed topic 3)
   *        );
   **/
  function setTriggerConfig(uint256 id, bytes calldata triggerConfig) external;

  /**
   * @notice method called by owner to set the address of chainlink keeper registry contract.
   * @param newRegistry address of the new chainlink keeper registry contract to set.
   */
  function setRegistry(address newRegistry) external;

  /**
   * @notice method called by owner to set the address of chainlink keeper registrar contract.
   * @param newRegistrar address of the new chainlink keeper registrar contract to set.
   */
  function setRegistrar(address newRegistrar) external;

  /**
   * @notice method to get the withdraw address for the robot operator contract.
   * @return withdraw address to send excess link to.
   **/
  function getWithdrawAddress() external view returns (address);

  /**
   * @notice method to get the keeper information registered via the operator.
   * @param id - id of the chainlink registered keeper.
   * @return Struct containing the following information about the keeper:
   *         - uint256 chainlink id of the registered keeper.
   *         - string name of the registered keeper.
   **/
  function getKeeperInfo(uint256 id) external view returns (KeeperInfo memory);

  /**
   * @notice method to get the address of chainlink keeper registry contract.
   * @return keeper registry address.
   */
  function getRegistry() external returns (address);

  /**
   * @notice method to get the address of chainlink keeper registrar contract.
   * @return keeper registrar address.
   */
  function getRegistrar() external returns (address);

  /**
   * @notice method to get the address of ERC-677 link token.
   * @return link token address.
   */
  function getLinkToken() external returns (address);

  /**
   * @notice method to get of all the ids of keepers registered by the robot operator which have not been cancelled.
   * @return array of registered keeper ids.
   */
  function getKeepersList() external returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IInitializableRobotOperator
 * @author BGD Labs
 * @notice Interface for the initialize function on AaveCLRobotOperator
 **/
interface IInitializableRobotOperator {
  /**
   * @dev Emitted when a AaveCLRobotOperator is initialized
   * @param keeperRegistry address of the chainlink registry.
   * @param keeperRegistrar address of the chainlink registrar.
   * @param linkWithdrawAddress withdrawal address of the operator contract.
   * @param operatorOwner owner of the operator contract.
   * @param operatorGuardian guardian of the operator contract.
   **/
  event Initialized(
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner,
    address operatorGuardian
  );

  /**
   * @dev Initializes the AaveCLRobotOperator
   * @param keeperRegistry address of the chainlink registry.
   * @param keeperRegistrar address of the chainlink registrar.
   * @param linkWithdrawAddress withdrawal address to send the exccess link after cancelling the keeper.
   * @param operatorOwner address to set as the owner of the operator contract.
   * @param operatorGuardian address to set as the guardian of the operator contract.
   */
  function initialize(
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner,
    address operatorGuardian
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeeperRegistrar {
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

  function setTriggerConfig(
    uint8 triggerType,
    AutoApproveType autoApproveType,
    uint32 autoApproveMaxAllowed
  ) external;

  function setAutoApproveAllowedSender(address senderAddress, bool allowed) external;

  function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IKeeperRegistry {
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

  function addFunds(uint256 id, uint96 amount) external;

  function cancelUpkeep(uint256 id) external;

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

  function getBalance(uint256 id) external view returns (uint96 balance);

  function getForwarder(uint256 upkeepID) external view returns (address);

  function getLinkAddress() external view returns (address);

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

  function getTriggerType(uint256 upkeepId) external pure returns (uint8);

  function getUpkeep(uint256 id) external view returns (UpkeepInfo memory upkeepInfo);

  function getUpkeepTriggerConfig(uint256 upkeepId) external view returns (bytes memory);

  function pauseUpkeep(uint256 id) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function unpauseUpkeep(uint256 id) external;

  function upkeepVersion() external pure returns (uint8);

  function withdrawFunds(uint256 id, address to) external;

  function migrateUpkeeps(uint256[] calldata upkeepIDs, address destination) external;

  function transferUpkeepAdmin(uint256 id, address proposed) external;

  function acceptUpkeepAdmin(uint256 id) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/a035b235b4f2c9af4ba88edc4447f02e37f8d124

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)
// Modified From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/00cbf5a236564c3b7aacdad1f378cae22d890ca6

pragma solidity ^0.8.0;

import {IERC20} from "./interfaces/IERC20.sol";
import {IERC20Permit} from "./interfaces/IERC20Permit.sol";
import {Address} from "./Address.sol";

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
   * @dev An operation with an ERC20 token failed.
     */
  error SafeERC20FailedOperation(address token);

  /**
   * @dev Indicates a failed `decreaseAllowance` request.
     */
  error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

  /**
   * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
  }

  /**
   * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
  }

  /**
   * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 oldAllowance = token.allowance(address(this), spender);
    forceApprove(token, spender, oldAllowance + value);
  }

  /**
   * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
  function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
    unchecked {
      uint256 currentAllowance = token.allowance(address(this), spender);
      if (currentAllowance < requestedDecrease) {
        revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
      }
      forceApprove(token, spender, currentAllowance - requestedDecrease);
    }
  }

  /**
   * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
  function forceApprove(IERC20 token, address spender, uint256 value) internal {
    bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

    if (!_callOptionalReturnBool(token, approvalCall)) {
      _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
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
    if (nonceAfter != nonceBefore + 1) {
      revert SafeERC20FailedOperation(address(token));
    }
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

    bytes memory returndata = address(token).functionCall(data);
    if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
      revert SafeERC20FailedOperation(address(token));
    }
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
    return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import {IWithGuardian} from './interfaces/IWithGuardian.sol';
import {Ownable} from '../oz-common/Ownable.sol';

abstract contract OwnableWithGuardian is Ownable, IWithGuardian {
  address private _guardian;

  constructor() {
    _updateGuardian(_msgSender());
  }

  modifier onlyGuardian() {
    _checkGuardian();
    _;
  }

  modifier onlyOwnerOrGuardian() {
    _checkOwnerOrGuardian();
    _;
  }

  function guardian() public view override returns (address) {
    return _guardian;
  }

  /// @inheritdoc IWithGuardian
  function updateGuardian(address newGuardian) external override onlyOwnerOrGuardian {
    _updateGuardian(newGuardian);
  }

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function _updateGuardian(address newGuardian) internal {
    address oldGuardian = _guardian;
    _guardian = newGuardian;
    emit GuardianUpdated(oldGuardian, newGuardian);
  }

  function _checkGuardian() internal view {
    require(guardian() == _msgSender(), 'ONLY_BY_GUARDIAN');
  }

  function _checkOwnerOrGuardian() internal view {
    require(_msgSender() == owner() || _msgSender() == guardian(), 'ONLY_BY_OWNER_OR_GUARDIAN');
  }
}

// SPDX-License-Identifier: MIT

/**
 * @dev OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)
 * From https://github.com/OpenZeppelin/openzeppelin-contracts/tree/8b778fa20d6d76340c5fac1ed66c80273f05b95a
 *
 * BGD Labs adaptations:
 * - Added a constructor disabling initialization for implementation contracts
 * - Linting
 */

pragma solidity ^0.8.2;

import '../oz-common/Address.sol';

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
   * @dev OPINIONATED. Generally is not a good practise to allow initialization of implementations
   */
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
   * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
   */
  modifier initializer() {
    bool isTopLevelCall = !_initializing;
    require(
      (isTopLevelCall && _initialized < 1) ||
        (!Address.isContract(address(this)) && _initialized == 1),
      'Initializable: contract is already initialized'
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
   * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
   * initialization step. This is essential to configure modules that are added through upgrades and that require
   * initialization.
   *
   * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
   * a contract, executing them in the right order is up to the developer or operator.
   */
  modifier reinitializer(uint8 version) {
    require(
      !_initializing && _initialized < version,
      'Initializable: contract is already initialized'
    );
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
    require(_initializing, 'Initializable: contract is not initializing');
    _;
  }

  /**
   * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
   * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
   * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
   * through proxies.
   */
  function _disableInitializers() internal virtual {
    require(!_initializing, 'Initializable: contract is initializing');
    if (_initialized < type(uint8).max) {
      _initialized = type(uint8).max;
      emit Initialized(type(uint8).max);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/54b3f14346da01ba0d159114b399197fea8b7cda

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
 * ```solidity
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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)
// Modified from https://github.com/OpenZeppelin/openzeppelin-contracts/commit/00cbf5a236564c3b7aacdad1f378cae22d890ca6
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
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
    return functionCallWithValue(target, data, 0, 'Address: low-level call failed');
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
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return verifyCallResultFromTarget(target, success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data
  ) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
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
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: call to non-contract');
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
pragma solidity >=0.7.0;

interface IWithGuardian {
  /**
   * @dev Event emitted when guardian gets updated
   * @param oldGuardian address of previous guardian
   * @param newGuardian address of the new guardian
   */
  event GuardianUpdated(address oldGuardian, address newGuardian);

  /**
   * @dev get guardian address;
   */
  function guardian() external view returns (address);

  /**
   * @dev method to update the guardian
   * @param newGuardian the new guardian address
   */
  function updateGuardian(address newGuardian) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

pragma solidity ^0.8.0;

import './Context.sol';

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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
// From commit https://github.com/OpenZeppelin/openzeppelin-contracts/commit/8b778fa20d6d76340c5fac1ed66c80273f05b95a

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