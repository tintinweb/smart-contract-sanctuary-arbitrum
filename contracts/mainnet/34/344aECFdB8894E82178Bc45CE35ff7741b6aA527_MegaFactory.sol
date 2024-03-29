// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IPoolFactory {
  function deploy(address _storage, address _vault) external returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IStrategyFactory {
  function deploy(address _storage, address _vault, address _providedStrategyAddress) external returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IVaultFactory {
  function deploy(address _storage, address _underlying) external returns (address);
  function info(address vault) external view returns(address Underlying, address NewVault);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IStrategyFactory.sol";
import "./interface/IVaultFactory.sol";
import "./interface/IPoolFactory.sol";

import "../interface/IVault.sol";
import "../inheritance/Governable.sol";

contract MegaFactory is Ownable {

  enum VaultType {
    None,
    Regular
  }

  enum StrategyType {
    None,
    Upgradable
  }

  address public potPoolFactory;
  mapping(uint256 => address) public vaultFactories;
  mapping(uint256 => address) public strategyFactories;

  struct CompletedDeployment {
    VaultType vaultType;
    address Underlying;
    address NewVault;
    address NewStrategy;
    address NewPool;
  }

  event DeploymentCompleted(string id);

  mapping (string => CompletedDeployment) public completedDeployments;
  mapping (address => bool) public authorizedDeployers;

  address public multisig;
  address public actualStorage;

  /* methods to make compatible with Storage */
  function governance() external view returns (address) {
    return address(this); // fake governance
  }

  function isGovernance(address addr) external view returns (bool) {
    return addr == address(this); // fake governance
  }

  function isController(address addr) external view returns (bool) {
    return addr == address(this); // fake controller
  }

  modifier onlyAuthorizedDeployer(string memory id) {
    require(completedDeployments[id].vaultType == VaultType.None, "cannot reuse id");
    require(authorizedDeployers[msg.sender], "unauthorized deployer");
    _;
    emit DeploymentCompleted(id);
  }

  constructor(address _storage, address _multisig) public {
    multisig = _multisig;
    actualStorage = _storage;
    setAuthorization(owner(), true);
    setAuthorization(multisig, true);
  }

  function setAuthorization(address userAddress, bool isDeployer) public onlyOwner {
    authorizedDeployers[userAddress] = isDeployer;
  }

  function setVaultFactory(uint256 vaultType, address factoryAddress) external onlyOwner {
    vaultFactories[vaultType] = factoryAddress;
  }

  function setStrategyFactory(uint256 strategyType, address factoryAddress) external onlyOwner {
    strategyFactories[strategyType] = factoryAddress;
  }

  function setPotPoolFactory(address factoryAddress) external onlyOwner {
    potPoolFactory = factoryAddress;
  }

  function createRegularVault(string calldata id, address underlying) external onlyAuthorizedDeployer(id) {
    address vault = IVaultFactory(vaultFactories[uint256(VaultType.Regular)]).deploy(
     actualStorage,
     underlying
    );

    completedDeployments[id] = CompletedDeployment(
      VaultType.Regular,
      underlying,
      vault,
      address(0),
      IPoolFactory(potPoolFactory).deploy(actualStorage, vault)
    );
  }

  function createRegularVaultUsingUpgradableStrategy(string calldata id, address underlying, address strategyImplementation) external onlyAuthorizedDeployer(id) {
    address vault = IVaultFactory(vaultFactories[uint256(VaultType.Regular)]).deploy(
     address(this), // using this as initial storage, then switching to actualStorage
     underlying
    );

    address strategy = IStrategyFactory(strategyFactories[uint256(StrategyType.Upgradable)]).deploy(actualStorage, vault, strategyImplementation);
    IVault(vault).setStrategy(strategy);
    Governable(vault).setStorage(actualStorage);

    completedDeployments[id] = CompletedDeployment(
      VaultType.Regular,
      underlying,
      vault,
      strategy,
      IPoolFactory(potPoolFactory).deploy(actualStorage, vault)
    );
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "./Storage.sol";

contract Governable {

  Storage public store;

  constructor(address _store) public {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  modifier onlyGovernance() {
    require(store.isGovernance(msg.sender), "Not governance");
    _;
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    store = Storage(_store);
  }

  function governance() public view returns (address) {
    return store.governance();
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

contract Storage {

  address public governance;
  address public controller;

  constructor() public {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

interface IVault {

    function initializeVault(
        address _storage,
        address _underlying,
        uint256 _toInvestNumerator,
        uint256 _toInvestDenominator
    ) external;

    function balanceOf(address _holder) external view returns (uint256);

    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function underlyingUnit() external view returns (uint);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function announceStrategyUpdate(address _strategy) external;

    function setVaultFractionToInvest(uint256 _numerator, uint256 _denominator) external;

    function deposit(uint256 _amount) external;

    function depositFor(uint256 _amount, address _holder) external;

    function withdrawAll() external;

    function withdraw(uint256 _numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address _holder) view external returns (uint256);

    /**
     * The total amount available to be deposited from this vault into the strategy, while adhering to the
     * `vaultFractionToInvestNumerator` and `vaultFractionToInvestDenominator` rules
     */
    function availableToInvestOut() external view returns (uint256);

    /**
     * This should be callable only by the controller (by the hard worker) or by governance
     */
    function doHardWork() external;
}