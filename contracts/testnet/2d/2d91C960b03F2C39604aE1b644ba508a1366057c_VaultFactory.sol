// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "../interfaces/IController.sol";
import "../interfaces/IProxyControlled.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITetuVaultV2.sol";
import "../interfaces/IVaultInsurance.sol";
import "../interfaces/ISplitter.sol";
import "../openzeppelin/Clones.sol";

/// @title Factory for vaults.
/// @author belbix
contract VaultFactory {

  // *************************************************************
  //                        VARIABLES
  // *************************************************************

  /// @dev Platform controller, need for restrictions.
  address public immutable controller;

  /// @dev ProxyControlled contract address
  address public proxyImpl;
  /// @dev TetuVaultV2 contract address
  address public vaultImpl;
  /// @dev VaultInsurance contract address
  address public vaultInsuranceImpl;
  /// @dev StrategySplitterV2 contract address
  address public splitterImpl;

  /// @dev Array of deployed vaults.
  address[] public deployedVaults;

  // *************************************************************
  //                        EVENTS
  // *************************************************************

  event VaultDeployed(
    address sender,
    address asset,
    string name,
    string symbol,
    address gauge,
    uint buffer,
    address vaultProxy,
    address vaultLogic,
    address insurance,
    address splitterProxy,
    address splitterLogic
  );

  constructor(
    address _controller,
    address _proxyImpl,
    address _vaultImpl,
    address _vaultInsuranceImpl,
    address _splitterImpl
  ) {
    controller = _controller;
    proxyImpl = _proxyImpl;
    vaultImpl = _vaultImpl;
    vaultInsuranceImpl = _vaultInsuranceImpl;
    splitterImpl = _splitterImpl;
  }

  function deployedVaultsLength() external view returns (uint) {
    return deployedVaults.length;
  }

  // *************************************************************
  //                        RESTRICTIONS
  // *************************************************************

  /// @dev Only governance
  modifier onlyGov() {
    require(msg.sender == IController(controller).governance(), "!GOV");
    _;
  }

  /// @dev Only platform operators
  modifier onlyOperator() {
    require(IController(controller).isOperator(msg.sender), "!OPERATOR");
    _;
  }

  // *************************************************************
  //                        GOV ACTIONS
  // *************************************************************

  /// @dev Set ProxyControlled contract address
  function setProxyImpl(address value) external onlyGov {
    proxyImpl = value;
  }

  /// @dev Set TetuVaultV2 contract address
  function setVaultImpl(address value) external onlyGov {
    vaultImpl = value;
  }

  /// @dev Set VaultInsurance contract address
  function setVaultInsuranceImpl(address value) external onlyGov {
    vaultInsuranceImpl = value;
  }

  /// @dev Set StrategySplitterV2 contract address
  function setSplitterImpl(address value) external onlyGov {
    splitterImpl = value;
  }

  // *************************************************************
  //                    OPERATOR ACTIONS
  // *************************************************************

  /// @dev Create and init vault with given attributes.
  function createVault(
    IERC20 asset,
    string memory name,
    string memory symbol,
    address gauge,
    uint buffer
  ) external onlyOperator {
    // clone vault implementations
    address vaultProxy = Clones.clone(proxyImpl);
    address vaultLogic = Clones.clone(vaultImpl);
    // init proxy
    IProxyControlled(vaultProxy).initProxy(vaultLogic);
    // init vault
    ITetuVaultV2(vaultProxy).init(
      controller,
      asset,
      name,
      symbol,
      gauge,
      buffer
    );
    // clone insurance
    IVaultInsurance insurance = IVaultInsurance(Clones.clone(vaultInsuranceImpl));
    // init insurance
    insurance.init(vaultProxy, address(asset));
    // set insurance to vault
    ITetuVaultV2(vaultProxy).initInsurance(insurance);

    // clone splitter
    address splitterProxy = Clones.clone(proxyImpl);
    address splitterLogic = Clones.clone(splitterImpl);
    // init proxy
    IProxyControlled(splitterProxy).initProxy(splitterLogic);
    // init splitter
    ISplitter(splitterProxy).init(controller, address(asset), vaultProxy);
    // set splitter to vault
    ITetuVaultV2(vaultProxy).setSplitter(splitterProxy);

    deployedVaults.push(vaultProxy);

    emit VaultDeployed(
      msg.sender,
      address(asset),
      name,
      symbol,
      gauge,
      buffer,
      vaultProxy,
      vaultLogic,
      address(insurance),
      splitterProxy,
      splitterLogic
    );
  }


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IController {

  // --- DEPENDENCY ADDRESSES
  function governance() external view returns (address);

  function voter() external view returns (address);

  function vaultController() external view returns (address);

  function liquidator() external view returns (address);

  function forwarder() external view returns (address);

  function investFund() external view returns (address);

  function veDistributor() external view returns (address);

  function platformVoter() external view returns (address);

  // --- VAULTS

  function vaults(uint id) external view returns (address);

  function vaultsList() external view returns (address[] memory);

  function vaultsListLength() external view returns (uint);

  function isValidVault(address _vault) external view returns (bool);

  // --- restrictions

  function isOperator(address _adr) external view returns (bool);


}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IProxyControlled {

  function initProxy(address _logic) external;

  function upgrade(address _newImplementation) external;

  function implementation() external view returns (address);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint);

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
  function approve(address spender, uint amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./IVaultInsurance.sol";
import "./IERC20.sol";

interface ITetuVaultV2 {

  function init(
    address controller_,
    IERC20 _asset,
    string memory _name,
    string memory _symbol,
    address _gauge,
    uint _buffer
  ) external;

  function setSplitter(address _splitter) external;

  function coverLoss(uint amount) external;

  function initInsurance(IVaultInsurance _insurance) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IVaultInsurance {

  function init(address _vault, address _asset) external;

  function vault() external view returns (address);

  function asset() external view returns (address);

  function transferToVault(uint amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface ISplitter {

  function init(address controller_, address _asset, address _vault) external;

  // *************** ACTIONS **************

  function withdrawAllToVault() external;

  function withdrawToVault(uint256 amount) external;

  function doHardWork() external;

  function investAll() external;

  // **************** VIEWS ***************

  function asset() external view returns (address);

  function vault() external view returns (address);

  function totalAssets() external view returns (uint256);

  function isHardWorking() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0-rc.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.7/contracts/proxy/Clones.sol
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
  /**
   * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
  function clone(address implementation) internal returns (address instance) {
    /// @solidity memory-safe-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      instance := create(0, ptr, 0x37)
    }
    require(instance != address(0), "ERC1167: create failed");
  }

  /**
   * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
  function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
    /// @solidity memory-safe-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      instance := create2(0, ptr, 0x37, salt)
    }
    require(instance != address(0), "ERC1167: create2 failed");
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
  function predictDeterministicAddress(
    address implementation,
    bytes32 salt,
    address deployer
  ) internal pure returns (address predicted) {
    /// @solidity memory-safe-assembly
    assembly {
      let ptr := mload(0x40)
      mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(ptr, 0x14), shl(0x60, implementation))
      mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
      mstore(add(ptr, 0x38), shl(0x60, deployer))
      mstore(add(ptr, 0x4c), salt)
      mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
      predicted := keccak256(add(ptr, 0x37), 0x55)
    }
  }

  /**
   * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
  function predictDeterministicAddress(address implementation, bytes32 salt)
  internal
  view
  returns (address predicted)
  {
    return predictDeterministicAddress(implementation, salt, address(this));
  }
}