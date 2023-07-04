// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IAaveCLRobotOperator} from '../interfaces/IAaveCLRobotOperator.sol';
import {LinkTokenInterface} from 'chainlink-brownie-contracts/interfaces/LinkTokenInterface.sol';
import {IKeeperRegistrar} from '../interfaces/IKeeperRegistrar.sol';
import {IKeeperRegistry} from '../interfaces/IKeeperRegistry.sol';
import {OwnableWithGuardian} from 'solidity-utils/contracts/access-control/OwnableWithGuardian.sol';

/**
 * @title AaveCLRobotOperator
 * @author BGD Labs
 * @dev Operator contract to perform admin actions on the automation keepers.
 *      The contract can register keepers, cancel it, withdraw excess link,
 *      refill the keeper, configure the gasLimit.
 */
contract AaveCLRobotOperator is OwnableWithGuardian, IAaveCLRobotOperator {
  /// @inheritdoc IAaveCLRobotOperator
  address public immutable LINK_TOKEN;

  /// @inheritdoc IAaveCLRobotOperator
  address public immutable KEEPER_REGISTRY;

  /// @inheritdoc IAaveCLRobotOperator
  address public immutable KEEPER_REGISTRAR;

  address internal _linkWithdrawAddress;

  mapping(uint256 id => KeeperInfo) internal _keepers;

  /**
   * @param linkTokenAddress address of the ERC-677 link token contract.
   * @param keeperRegistry address of the chainlink registry.
   * @param keeperRegistrar address of the chainlink registrar.
   * @param linkWithdrawAddress withdrawal address to send the exccess link after cancelling the keeper.
   * @param operatorOwner address to set as the owner of the operator contract.
   */
  constructor(
    address linkTokenAddress,
    address keeperRegistry,
    address keeperRegistrar,
    address linkWithdrawAddress,
    address operatorOwner
  ) {
    KEEPER_REGISTRY = keeperRegistry;
    KEEPER_REGISTRAR = keeperRegistrar;
    LINK_TOKEN = linkTokenAddress;
    _linkWithdrawAddress = linkWithdrawAddress;
    _transferOwnership(operatorOwner);
  }

  /// @notice In order to fund the keeper we need to approve the Link token amount to this contract
  /// @inheritdoc IAaveCLRobotOperator
  function register(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    uint96 amountToFund
  ) external onlyOwner returns (uint256) {
    LinkTokenInterface(LINK_TOKEN).transferFrom(msg.sender, address(this), amountToFund);
    (IKeeperRegistry.State memory state, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();
    // nonce of the registry before the keeper has been registered
    uint256 oldNonce = state.nonce;

    bytes memory payload = abi.encode(
      name, // name of the keeper to register
      0x0, // encryptedEmail to send alerts to, unused currently
      upkeepContract, // address of the upkeep contract
      gasLimit, // max gasLimit which can be used for an performUpkeep action
      address(this), // admin of the keeper is set to this address of AaveCLRobotOperator
      '', // checkData of the keeper which get passed to the checkUpkeep, unused currently
      amountToFund, // amount of link to fund the keeper with
      0, // source application sending this request
      address(this) // address of the sender making the request
    );
    LinkTokenInterface(LINK_TOKEN).transferAndCall(
      KEEPER_REGISTRAR,
      amountToFund,
      bytes.concat(IKeeperRegistrar.register.selector, payload)
    );

    (state, , ) = IKeeperRegistry(KEEPER_REGISTRY).getState();

    // checks if the keeper has been registered succesfully by checking that nonce has been incremented on the registry
    if (state.nonce == oldNonce + 1) {
      // calculates the id for the keeper registered
      uint256 id = uint256(
        keccak256(abi.encodePacked(blockhash(block.number - 1), KEEPER_REGISTRY, uint32(oldNonce)))
      );
      _keepers[id].upkeep = upkeepContract;
      _keepers[id].name = name;
      emit KeeperRegistered(id, upkeepContract, amountToFund);

      return id;
    } else {
      revert('AUTO_APPROVE_DISABLED');
    }
  }

  /// @inheritdoc IAaveCLRobotOperator
  function cancel(uint256 id) external onlyOwner {
    IKeeperRegistry(KEEPER_REGISTRY).cancelUpkeep(id);
    emit KeeperCancelled(id, _keepers[id].upkeep);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function withdrawLink(uint256 id) external {
    IKeeperRegistry(KEEPER_REGISTRY).withdrawFunds(id, _linkWithdrawAddress);
    emit LinkWithdrawn(id, _keepers[id].upkeep, _linkWithdrawAddress);
  }

  /// @notice In order to refill the keeper we need to approve the Link token amount to this contract
  /// @inheritdoc IAaveCLRobotOperator
  function refillKeeper(uint256 id, uint96 amount) external {
    LinkTokenInterface(LINK_TOKEN).transferFrom(msg.sender, address(this), amount);
    LinkTokenInterface(LINK_TOKEN).approve(KEEPER_REGISTRY, amount);
    IKeeperRegistry(KEEPER_REGISTRY).addFunds(id, amount);
    emit KeeperRefilled(id, msg.sender, amount);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setGasLimit(uint256 id, uint32 gasLimit) external onlyOwnerOrGuardian {
    IKeeperRegistry(KEEPER_REGISTRY).setUpkeepGasLimit(id, gasLimit);
    emit GasLimitSet(id, _keepers[id].upkeep, gasLimit);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function setWithdrawAddress(address withdrawAddress) external onlyOwner {
    _linkWithdrawAddress = withdrawAddress;
    emit WithdrawAddressSet(withdrawAddress);
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getWithdrawAddress() external view returns (address) {
    return _linkWithdrawAddress;
  }

  /// @inheritdoc IAaveCLRobotOperator
  function getKeeperInfo(uint256 id) external view returns (KeeperInfo memory) {
    return _keepers[id];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IAaveCLRobotOperator
 * @author BGD Labs
 * @notice Defines the interface for the robot operator contract to perform admin actions on the automation keepers.
 **/
interface IAaveCLRobotOperator {
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
   * @dev Emitted when the link withdraw address has been changed of the keeper.
   * @param newWithdrawAddress address of the new withdraw address where link will be withdrawn to.
   */
  event WithdrawAddressSet(address indexed newWithdrawAddress);

  /**
   * @dev Emitted when gas limit is configured using the operator contract.
   * @param id id of the keeper which gas limit has been configured.
   * @param upkeep address of the keeper contract.
   * @param gasLimit max gas limit which has been configured for the keeper.
   */
  event GasLimitSet(uint256 indexed id, address indexed upkeep, uint32 indexed gasLimit);

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
   * @param name - name of keeper.
   * @param upkeepContract - upkeepContract of the keeper.
   * @param gasLimit - max gasLimit which the chainlink automation node can execute for the automation.
   * @param amountToFund - amount of link to fund the keeper with.
   * @return chainlink id for the registered keeper.
   **/
  function register(
    string memory name,
    address upkeepContract,
    uint32 gasLimit,
    uint96 amountToFund
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
   *         - address chainlink registry of the registered keeper.
   **/
  function getKeeperInfo(uint256 id) external view returns (KeeperInfo memory);

  /**
   * @notice method to get the address of ERC-677 link token.
   * @return link token address.
   */
  function LINK_TOKEN() external returns (address);

  /**
   * @notice method to get the address of chainlink keeper registry contract.
   * @return keeper registry address.
   */
  function KEEPER_REGISTRY() external returns (address);

  /**
   * @notice method to get the address of chainlink keeper registrar contract.
   * @return keeper registrar address.
   */
  function KEEPER_REGISTRAR() external returns (address);
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

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeeperRegistrar {
  function register(
    string memory name,
    bytes calldata encryptedEmail,
    address upkeepContract,
    uint32 gasLimit,
    address adminAddress,
    bytes calldata checkData,
    uint96 amount,
    uint8 source,
    address sender
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeeperRegistry {
  /**
   * @notice config of the registry
   * @dev only used in params and return values
   * @member paymentPremiumPPB payment premium rate oracles receive on top of
   * being reimbursed for gas, measured in parts per billion
   * @member flatFeeMicroLink flat fee paid to oracles for performing upkeeps,
   * priced in MicroLink; can be used in conjunction with or independently of
   * paymentPremiumPPB
   * @member blockCountPerTurn number of blocks each oracle has during their turn to
   * perform upkeep before it will be the next keeper's turn to submit
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
  struct Config {
    uint32 paymentPremiumPPB;
    uint32 flatFeeMicroLink; // min 0.000001 LINK, max 4294 LINK
    uint24 blockCountPerTurn;
    uint32 checkGasLimit;
    uint24 stalenessSeconds;
    uint16 gasCeilingMultiplier;
    uint96 minUpkeepSpend;
    uint32 maxPerformGas;
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
   * @member numUpkeeps total number of upkeeps on the registry
   */
  struct State {
    uint32 nonce;
    uint96 ownerLinkBalance;
    uint256 expectedLinkBalance;
    uint256 numUpkeeps;
  }

  function cancelUpkeep(uint256 id) external;

  function addFunds(uint256 id, uint96 amount) external;

  function withdrawFunds(uint256 id, address to) external;

  function setUpkeepGasLimit(uint256 id, uint32 gasLimit) external;

  function getUpkeep(
    uint256 id
  )
    external
    view
    returns (
      address target,
      uint32 executeGas,
      bytes memory checkData,
      uint96 balance,
      address lastKeeper,
      address admin,
      uint64 maxValidBlocknumber,
      uint96 amountSpent
    );

  function getState() external view returns (State memory, Config memory, address[] memory);
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
  function updateGuardian(address newGuardian) external override onlyGuardian {
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