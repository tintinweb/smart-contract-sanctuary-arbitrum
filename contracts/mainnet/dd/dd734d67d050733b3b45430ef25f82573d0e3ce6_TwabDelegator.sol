// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Clones } from "openzeppelin/proxy/Clones.sol";
import { ERC20, IERC20 } from "openzeppelin/token/ERC20/ERC20.sol";
import { IERC20Permit } from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import { SafeERC20 } from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import { IERC4626 } from "openzeppelin/interfaces/IERC4626.sol";
import { Address } from "openzeppelin/utils/Address.sol";

import { TwabController, SPONSORSHIP_ADDRESS } from "pt-v5-twab-controller/TwabController.sol";

import { Delegation } from "./Delegation.sol";
import { LowLevelDelegator } from "./LowLevelDelegator.sol";
import { PermitAndMulticall } from "./PermitAndMulticall.sol";

/**
 * @title Delegate chances to win to multiple accounts.
 * @notice This contract allows accounts to easily delegate a portion of their Vault shares to multiple delegatees.
  The delegatees chance of winning prizes is increased by the delegated amount.
  If a delegator doesn't want to actively manage the delegations, then they can stake on the contract and appoint representatives.
 */
contract TwabDelegator is ERC20, LowLevelDelegator, PermitAndMulticall {
  using Address for address;
  using Clones for address;
  using SafeERC20 for IERC20;

  /* ============ Events ============ */

  /**
   * @notice Emitted when TwabController associated with this contract has been set.
   * @param twabController Address of the TwabController
   */
  event TwabControllerSet(TwabController indexed twabController);

  /**
   * @notice Emitted when Vault associated with this contract has been set.
   * @param vault Address of the Vault
   */
  event VaultSet(IERC20 indexed vault);

  /**
   * @notice Emitted when Vault shares have been staked.
   * @param delegator Address of the delegator
   * @param amount Amount of Vault shares shares staked
   */
  event VaultSharesStaked(address indexed delegator, uint256 amount);

  /**
   * @notice Emitted when Vault shares have been unstaked.
   * @param delegator Address of the delegator
   * @param recipient Address of the recipient that will receive the Vault shares
   * @param amount Amount of Vault shares unstaked
   */
  event VaultSharesUnstaked(address indexed delegator, address indexed recipient, uint256 amount);

  /**
   * @notice Emitted when a new delegation is created.
   * @param delegator Delegator of the delegation
   * @param slot Slot of the delegation
   * @param lockUntil Timestamp until which the delegation is locked
   * @param delegatee Address of the delegatee
   * @param delegation Address of the delegation that was created
   * @param user Address of the user who created the delegation
   */
  event DelegationCreated(
    address indexed delegator,
    uint256 indexed slot,
    uint96 lockUntil,
    address indexed delegatee,
    Delegation delegation,
    address user
  );

  /**
   * @notice Emitted when a delegatee is updated.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param delegatee Address of the delegatee
   * @param lockUntil Timestamp until which the delegation is locked
   * @param user Address of the user who updated the delegatee
   */
  event DelegateeUpdated(
    address indexed delegator,
    uint256 indexed slot,
    address indexed delegatee,
    uint96 lockUntil,
    address user
  );

  /**
   * @notice Emitted when a delegation is funded.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of Vault shares that were sent to the delegation
   * @param user Address of the user who funded the delegation
   */
  event DelegationFunded(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when a delegation is funded from the staked amount.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of Vault shares that were sent to the delegation
   * @param user Address of the user who pulled funds from the delegator stake to the delegation
   */
  event DelegationFundedFromStake(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when an amount of Vault shares has been withdrawn from a delegation.
   * @dev The Vault shares are held by this contract and the delegator stake is increased.
   * @param delegator Address of the delegator
   * @param slot Slot of the delegation
   * @param amount Amount of Vault shares withdrawn
   * @param user Address of the user who withdrew the Vault shares
   */
  event WithdrewDelegationToStake(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed user
  );

  /**
   * @notice Emitted when a delegator withdraws an amount of Vault shares from a delegation to a specified wallet.
   * @param delegator Address of the delegator
   * @param slot  Slot of the delegation
   * @param amount Amount of Vault shares withdrawn
   * @param to Recipient address of withdrawn Vault shares
   */
  event TransferredDelegation(
    address indexed delegator,
    uint256 indexed slot,
    uint256 amount,
    address indexed to
  );

  /**
   * @notice Emitted when a representative is set.
   * @param delegator Address of the delegator
   * @param representative Address of the representative
   * @param set Boolean indicating if the representative was set or unset
   */
  event RepresentativeSet(address indexed delegator, address indexed representative, bool set);

  /* ============ Variables ============ */

  /// @notice Vault to which this contract is tied to.
  IERC20 private immutable _vault;

  /// @notice TwabController to which this contract is tied to.
  TwabController private immutable _twabController;

  /// @notice Max lock time during which a delegation cannot be updated.
  uint256 public constant MAX_LOCK = 180 days;

  /**
   * @notice Representative elected by the delegator to handle delegation.
   * @dev Representative can only handle delegation and cannot withdraw Vault shares to their wallet.
   * @dev delegator => representative => bool allowing representative to represent the delegator
   */
  mapping(address => mapping(address => bool)) internal representatives;

  /* ============ Constructor ============ */

  /**
   * @notice Creates a new TWAB Delegator that is bound to the given vault contract.
   * @param name_ The name for the staked vault token
   * @param symbol_ The symbol for the staked vault token
   * @param twabController_ Address of the TwabController contract
   * @param vault_ Address of the Vault contract
   */
  constructor(
    string memory name_,
    string memory symbol_,
    TwabController twabController_,
    IERC20 vault_
  ) LowLevelDelegator() ERC20(name_, symbol_) {
    require(address(twabController_) != address(0), "TD/twabController-not-zero-addr");
    require(address(vault_) != address(0), "TD/vault-not-zero-addr");

    _twabController = twabController_;
    _vault = vault_;

    // We don't want any latent vault tokens to cause this contract to win unrecoverable
    // prizes, so we will sponsor the vault to ensure this contract can't win prizes.
    twabController_.delegate(address(_vault), SPONSORSHIP_ADDRESS);

    emit TwabControllerSet(twabController_);
    emit VaultSet(vault_);
  }

  /* ============ External Functions ============ */

  /**
   * @notice Stake `_amount` of Vault shares in this contract.
   * @dev Vault Shares can be staked on behalf of a `_to` user.
   * @param _to Address to which the stake will be attributed
   * @param _amount Amount of Vault shares to stake
   */
  function stake(address _to, uint256 _amount) external {
    _requireAmountGtZero(_amount);

    _vault.safeTransferFrom(msg.sender, address(this), _amount);
    _mint(_to, _amount);

    emit VaultSharesStaked(_to, _amount);
  }

  /**
   * @notice Unstake `_amount` of Vault shares from this contract. Transfers Vault shares to the passed `_to` address.
   * @dev If delegator has delegated his whole stake, he will first have to withdraw from a delegation to be able to unstake.
   * @param _to Address of the recipient that will receive the Vault shares
   * @param _amount Amount of Vault shares to unstake
   */
  function unstake(address _to, uint256 _amount) external {
    _requireRecipientNotZeroAddress(_to);
    _requireAmountGtZero(_amount);

    _burn(msg.sender, _amount);

    _vault.safeTransfer(_to, _amount);

    emit VaultSharesUnstaked(msg.sender, _to, _amount);
  }

  /**
   * @notice Creates a new delegation.
   This will create a new Delegation contract for the given slot and have it delegate its Vault shares to the given delegatee.
   If a non-zero lock duration is passed, then the delegatee cannot be changed, nor funding withdrawn, until the lock has expired.
   * @dev The `_delegator` and `_slot` params are used to compute the salt of the delegation
   * @param _delegator Address of the delegator that will be able to handle the delegation
   * @param _slot Slot of the delegation
   * @param _delegatee Address of the delegatee
   * @param _lockDuration Duration of time for which the delegation is locked. Must be less than the max duration.
   * @return Returns the address of the Delegation contract that will hold the Vault shares
   */
  function createDelegation(
    address _delegator,
    uint256 _slot,
    address _delegatee,
    uint96 _lockDuration
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireDelegateeNotZeroAddress(_delegatee);
    _requireLockDuration(_lockDuration);

    uint96 _lockUntil = _computeLockUntil(_lockDuration);

    Delegation _delegation = _createDelegation(
      _computeSalt(_delegator, bytes32(_slot)),
      _lockUntil
    );

    _setDelegateeCall(_delegation, _delegatee);

    emit DelegationCreated(_delegator, _slot, _lockUntil, _delegatee, _delegation, msg.sender);

    return _delegation;
  }

  /**
   * @notice Updates the delegatee and lock duration for a delegation slot.
   * @dev Only callable by the `_delegator` or their representative.
   * @dev Will revert if delegation is still locked.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _delegatee Address of the delegatee
   * @param _lockDuration Duration of time during which the delegatee cannot be changed nor withdrawn
   * @return The address of the Delegation
   */
  function updateDelegatee(
    address _delegator,
    uint256 _slot,
    address _delegatee,
    uint96 _lockDuration
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireDelegateeNotZeroAddress(_delegatee);
    _requireLockDuration(_lockDuration);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
    _requireDelegationUnlocked(_delegation);

    uint96 _lockUntil = _computeLockUntil(_lockDuration);

    if (_lockDuration > 0) {
      _delegation.setLockUntil(_lockUntil);
    }

    _setDelegateeCall(_delegation, _delegatee);

    emit DelegateeUpdated(_delegator, _slot, _delegatee, _lockUntil, msg.sender);

    return _delegation;
  }

  /**
   * @notice Fund a delegation by transferring Vault shares from the caller to the delegation.
   * @dev Callable by anyone.
   * @dev Will revert if delegation does not exist.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of Vault shares to transfer
   * @return The address of the Delegation
   */
  function fundDelegation(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    require(_delegator != address(0), "TD/dlgtr-not-zero-adr");
    _requireAmountGtZero(_amount);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));
    _vault.safeTransferFrom(msg.sender, address(_delegation), _amount);

    emit DelegationFunded(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Fund a delegation using the `_delegator` stake.
   * @dev Callable only by the `_delegator` or a representative.
   * @dev Will revert if delegation does not exist.
   * @dev Will revert if `_amount` is greater than the staked amount.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of Vault shares to send to the delegation from the staked amount
   * @return The address of the Delegation
   */
  function fundDelegationFromStake(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);
    _requireAmountGtZero(_amount);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

    _burn(_delegator, _amount);

    _vault.safeTransfer(address(_delegation), _amount);

    emit DelegationFundedFromStake(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Withdraw Vault shares from a delegation. The Vault shares will be held by this contract and the delegator's stake will increase.
   * @dev Only callable by the `_delegator` or a representative.
   * @dev Will send the Vault shares to this contract and increase the `_delegator` staked amount.
   * @dev Will revert if delegation is still locked.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @param _amount Amount of Vault shares to withdraw
   * @return The address of the Delegation
   */
  function withdrawDelegationToStake(
    address _delegator,
    uint256 _slot,
    uint256 _amount
  ) external returns (Delegation) {
    _requireDelegatorOrRepresentative(_delegator);

    Delegation _delegation = Delegation(_computeAddress(_delegator, _slot));

    _transfer(_delegation, address(this), _amount);

    _mint(_delegator, _amount);

    emit WithdrewDelegationToStake(_delegator, _slot, _amount, msg.sender);

    return _delegation;
  }

  /**
   * @notice Withdraw an `_amount` of Vault shares from a delegation. The delegator is assumed to be the caller.
   * @dev Vault Shares are sent directly to the passed `_to` address.
   * @dev Will revert if delegation is still locked.
   * @param _slot Slot of the delegation
   * @param _amount Amount to withdraw
   * @param _to Account to transfer the withdrawn Vault shares to
   * @return The address of the Delegation
   */
  function transferDelegationTo(
    uint256 _slot,
    uint256 _amount,
    address _to
  ) external returns (Delegation) {
    _requireRecipientNotZeroAddress(_to);

    Delegation _delegation = Delegation(_computeAddress(msg.sender, _slot));
    _transfer(_delegation, _to, _amount);

    emit TransferredDelegation(msg.sender, _slot, _amount, _to);

    return _delegation;
  }

  /**
   * @notice Allow an account to set or unset a `_representative` to handle delegation.
   * @dev If `_set` is `true`, `_representative` will be set as representative of `msg.sender`.
   * @dev If `_set` is `false`, `_representative` will be unset as representative of `msg.sender`.
   * @param _representative Address of the representative
   * @param _set Set or unset the representative
   */
  function setRepresentative(address _representative, bool _set) external {
    require(_representative != address(0), "TD/rep-not-zero-addr");

    representatives[msg.sender][_representative] = _set;

    emit RepresentativeSet(msg.sender, _representative, _set);
  }

  /**
   * @notice Returns whether or not the given rep is a representative of the delegator.
   * @param _delegator The delegator
   * @param _representative The representative to check for
   * @return True if the rep is a rep, false otherwise
   */
  function isRepresentativeOf(
    address _delegator,
    address _representative
  ) external view returns (bool) {
    return representatives[_delegator][_representative];
  }

  /**
   * @notice Allows a user to call multiple functions on the same contract.  Useful for EOA who wants to batch transactions.
   * @param _data An array of encoded function calls.  The calls must be abi-encoded calls to this contract.
   * @return The results from each function call
   */
  function multicall(bytes[] calldata _data) external returns (bytes[] memory) {
    return _multicall(_data);
  }

  /**
   * @notice Alow a user to approve Vault shares and run various calls in one transaction.
   * @param _amount Amount of Vault shares to approve
   * @param _permitSignature Permit signature
   * @param _data Datas to call with `functionDelegateCall`
   */
  function permitAndMulticall(
    uint256 _amount,
    Signature calldata _permitSignature,
    bytes[] calldata _data
  ) external {
    _permitAndMulticall(IERC20Permit(address(_vault)), _amount, _permitSignature, _data);
  }

  /**
   * @notice Allows the caller to easily get the details for a delegation.
   * @param _delegator The delegator address
   * @param _slot The delegation slot they are using
   * @return delegation The address that holds Vault shares for the delegation
   * @return delegatee The address that Vault shares are being delegated to
   * @return balance The balance of Vault shares in the delegation
   * @return lockUntil The timestamp at which the delegation unlocks
   * @return wasCreated Whether or not the delegation has been created
   */
  function getDelegation(
    address _delegator,
    uint256 _slot
  )
    external
    view
    returns (
      Delegation delegation,
      address delegatee,
      uint256 balance,
      uint256 lockUntil,
      bool wasCreated
    )
  {
    delegation = Delegation(_computeAddress(_delegator, _slot));
    wasCreated = address(delegation).isContract();
    delegatee = _twabController.delegateOf(address(_vault), address(delegation));
    balance = _vault.balanceOf(address(delegation));

    if (wasCreated) {
      lockUntil = delegation.lockUntil();
    }
  }

  /**
   * @notice Computes the address of the delegation for the delegator + slot combination.
   * @param _delegator The user who is delegating Vault shares
   * @param _slot The delegation slot
   * @return The address of the delegation.  This is the address that holds the balance of Vault shares.
   */
  function computeDelegationAddress(
    address _delegator,
    uint256 _slot
  ) external view returns (address) {
    return _computeAddress(_delegator, _slot);
  }

  /**
   * @notice Returns the ERC20 token decimals.
   * @dev This value is equal to the decimals of the Vault shares being delegated.
   * @return ERC20 token decimals
   */
  function decimals() public view virtual override returns (uint8) {
    return ERC20(address(_vault)).decimals();
  }

  /**
   * @notice Returns the TwabController address.
   * @return TwabController address
   */
  function twabController() external view returns (address) {
    return address(_twabController);
  }

  /**
   * @notice Returns the Vault address.
   * @return Vault address
   */
  function vault() external view returns (address) {
    return address(_vault);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Computes the address of a delegation contract using the delegator and slot as a salt.
   The contract is a clone, also known as minimal proxy contract.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @return Address at which the delegation contract will be deployed
   */
  function _computeAddress(address _delegator, uint256 _slot) internal view returns (address) {
    return _computeAddress(_computeSalt(_delegator, bytes32(_slot)));
  }

  /**
   * @notice Computes the timestamp at which the delegation unlocks, after which the delegatee can be changed and Vault shares withdrawn.
   * @param _lockDuration The duration of the lock
   * @return The lock expiration timestamp
   */
  function _computeLockUntil(uint96 _lockDuration) internal view returns (uint96) {
    unchecked {
      return uint96(block.timestamp) + _lockDuration;
    }
  }

  /**
   * @notice Delegates Vault shares from the `_delegation` contract to the `_delegatee` address.
   * @param _delegation Address of the delegation contract
   * @param _delegatee Address of the delegatee
   */
  function _setDelegateeCall(Delegation _delegation, address _delegatee) internal {
    bytes4 _selector = _twabController.delegate.selector;
    bytes memory _data = abi.encodeWithSelector(_selector, address(_vault), _delegatee);

    _executeCall(_delegation, address(_twabController), _data);
  }

  /**
   * @notice Tranfers Vault shares from the Delegation contract to the `_to` address.
   * @param _delegation Address of the delegation contract
   * @param _to Address of the recipient
   * @param _amount Amount of Vault shares to transfer
   */
  function _transferCall(Delegation _delegation, address _to, uint256 _amount) internal {
    bytes4 _selector = _vault.transfer.selector;
    bytes memory _data = abi.encodeWithSelector(_selector, _to, _amount);

    _executeCall(_delegation, address(_vault), _data);
  }

  /**
   * @notice Execute a function call on the delegation contract.
   * @param _delegation Address of the delegation contract
   * @param _to The address that will be called
   * @param _data The call data that will be executed
   * @return The return datas from the calls
   */
  function _executeCall(
    Delegation _delegation,
    address _to,
    bytes memory _data
  ) internal returns (bytes[] memory) {
    Delegation.Call[] memory _calls = new Delegation.Call[](1);
    _calls[0] = Delegation.Call({ to: _to, data: _data });

    return _delegation.executeCalls(_calls);
  }

  /**
   * @notice Transfers Vault shares from a delegation contract to `_to`.
   * @param _delegation Address of the delegation contract
   * @param _to Address of the recipient
   * @param _amount Amount of Vault shares to transfer
   */
  function _transfer(Delegation _delegation, address _to, uint256 _amount) internal {
    _requireAmountGtZero(_amount);
    _requireDelegationUnlocked(_delegation);

    _transferCall(_delegation, _to, _amount);
  }

  /* ============ Modifier/Require Functions ============ */

  /**
   * @notice Require to only allow the delegator or representative to call a function.
   * @param _delegator Address of the delegator
   */
  function _requireDelegatorOrRepresentative(address _delegator) internal view {
    require(
      _delegator == msg.sender || representatives[_delegator][msg.sender],
      "TD/not-dlgtr-or-rep"
    );
  }

  /**
   * @notice Require to verify that `_delegatee` is not address zero.
   * @param _delegatee Address of the delegatee
   */
  function _requireDelegateeNotZeroAddress(address _delegatee) internal pure {
    require(_delegatee != address(0), "TD/dlgt-not-zero-addr");
  }

  /**
   * @notice Require to verify that `_amount` is greater than 0.
   * @param _amount Amount to check
   */
  function _requireAmountGtZero(uint256 _amount) internal pure {
    require(_amount > 0, "TD/amount-gt-zero");
  }

  /**
   * @notice Require to verify that `_to` is not address zero.
   * @param _to Address to check
   */
  function _requireRecipientNotZeroAddress(address _to) internal pure {
    require(_to != address(0), "TD/to-not-zero-addr");
  }

  /**
   * @notice Require to verify if a `_delegation` is locked.
   * @param _delegation Delegation to check
   */
  function _requireDelegationUnlocked(Delegation _delegation) internal view {
    require(block.timestamp >= _delegation.lockUntil(), "TD/delegation-locked");
  }

  /**
   * @notice Require to verify that a `_lockDuration` does not exceed the maximum lock duration.
   * @param _lockDuration Lock duration to check
   */
  function _requireLockDuration(uint256 _lockDuration) internal pure {
    require(_lockDuration <= MAX_LOCK, "TD/lock-too-long");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
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
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { SafeCast } from "openzeppelin/utils/math/SafeCast.sol";
import { TwabLib } from "./libraries/TwabLib.sol";
import { ObservationLib } from "./libraries/ObservationLib.sol";

/// @notice Emitted when an account already points to the same delegate address that is being set
error SameDelegateAlreadySet(address delegate);

/// @notice Emitted when an account tries to transfer to the sponsorship address
error CannotTransferToSponsorshipAddress();

/// @notice Emitted when the period length is too short
error PeriodLengthTooShort();

/// @notice Emitted when the period offset is not in the past.
/// @param periodOffset The period offset that was passed in
error PeriodOffsetInFuture(uint32 periodOffset);

/// @notice Emitted when a user tries to mint or transfer to the zero address
error TransferToZeroAddress();

// The minimum period length
uint32 constant MINIMUM_PERIOD_LENGTH = 1 hours;

// Allows users to revoke their chances to win by delegating to the sponsorship address.
address constant SPONSORSHIP_ADDRESS = address(1);

/**
 * @title  PoolTogether V5 Time-Weighted Average Balance Controller
 * @author PoolTogether Inc. & G9 Software Inc.
 * @dev    Time-Weighted Average Balance Controller for ERC20 tokens.
 * @notice This TwabController uses the TwabLib to provide token balances and on-chain historical
            lookups to a user(s) time-weighted average balance. Each user is mapped to an
            Account struct containing the TWAB history (ring buffer) and ring buffer parameters.
            Every token.transfer() creates a new TWAB observation. The new TWAB observation is
            stored in the circular ring buffer as either a new observation or rewriting a
            previous observation with new parameters. One observation per period is stored.
            The TwabLib guarantees minimum 1 year of search history if a period is a day.
 */
contract TwabController {
  using SafeCast for uint256;

  /// @notice Sets the minimum period length for Observations. When a period elapses, a new Observation is recorded, otherwise the most recent Observation is updated.
  uint32 public immutable PERIOD_LENGTH;

  /// @notice Sets the beginning timestamp for the first period. This allows us to maximize storage as well as line up periods with a chosen timestamp.
  /// @dev Ensure that the PERIOD_OFFSET is in the past.
  uint32 public immutable PERIOD_OFFSET;

  /* ============ State ============ */

  /// @notice Record of token holders TWABs for each account for each vault.
  mapping(address => mapping(address => TwabLib.Account)) internal userObservations;

  /// @notice Record of tickets total supply and ring buff parameters used for observation.
  mapping(address => TwabLib.Account) internal totalSupplyObservations;

  /// @notice vault => user => delegate.
  mapping(address => mapping(address => address)) internal delegates;

  /* ============ Events ============ */

  /**
   * @notice Emitted when a balance or delegateBalance is increased.
   * @param vault the vault for which the balance increased
   * @param user the users whose balance increased
   * @param amount the amount the balance increased by
   * @param delegateAmount the amount the delegateBalance increased by
   */
  event IncreasedBalance(
    address indexed vault,
    address indexed user,
    uint96 amount,
    uint96 delegateAmount
  );

  /**
   * @notice Emitted when a balance or delegateBalance is decreased.
   * @param vault the vault for which the balance decreased
   * @param user the users whose balance decreased
   * @param amount the amount the balance decreased by
   * @param delegateAmount the amount the delegateBalance decreased by
   */
  event DecreasedBalance(
    address indexed vault,
    address indexed user,
    uint96 amount,
    uint96 delegateAmount
  );

  /**
   * @notice Emitted when an Observation is recorded to the Ring Buffer.
   * @param vault the vault for which the Observation was recorded
   * @param user the users whose Observation was recorded
   * @param balance the resulting balance
   * @param delegateBalance the resulting delegated balance
   * @param isNew whether the observation is new or not
   * @param observation the observation that was created or updated
   */
  event ObservationRecorded(
    address indexed vault,
    address indexed user,
    uint96 balance,
    uint96 delegateBalance,
    bool isNew,
    ObservationLib.Observation observation
  );

  /**
   * @notice Emitted when a user delegates their balance to another address.
   * @param vault the vault for which the balance was delegated
   * @param delegator the user who delegated their balance
   * @param delegate the user who received the delegated balance
   */
  event Delegated(address indexed vault, address indexed delegator, address indexed delegate);

  /**
   * @notice Emitted when the total supply or delegateTotalSupply is increased.
   * @param vault the vault for which the total supply increased
   * @param amount the amount the total supply increased by
   * @param delegateAmount the amount the delegateTotalSupply increased by
   */
  event IncreasedTotalSupply(address indexed vault, uint96 amount, uint96 delegateAmount);

  /**
   * @notice Emitted when the total supply or delegateTotalSupply is decreased.
   * @param vault the vault for which the total supply decreased
   * @param amount the amount the total supply decreased by
   * @param delegateAmount the amount the delegateTotalSupply decreased by
   */
  event DecreasedTotalSupply(address indexed vault, uint96 amount, uint96 delegateAmount);

  /**
   * @notice Emitted when a Total Supply Observation is recorded to the Ring Buffer.
   * @param vault the vault for which the Observation was recorded
   * @param balance the resulting balance
   * @param delegateBalance the resulting delegated balance
   * @param isNew whether the observation is new or not
   * @param observation the observation that was created or updated
   */
  event TotalSupplyObservationRecorded(
    address indexed vault,
    uint96 balance,
    uint96 delegateBalance,
    bool isNew,
    ObservationLib.Observation observation
  );

  /* ============ Constructor ============ */

  /**
   * @notice Construct a new TwabController.
   * @dev Reverts if the period offset is in the future.
   * @param _periodLength Sets the minimum period length for Observations. When a period elapses, a new Observation
   *      is recorded, otherwise the most recent Observation is updated.
   * @param _periodOffset Sets the beginning timestamp for the first period. This allows us to maximize storage as well
   *      as line up periods with a chosen timestamp.
   */
  constructor(uint32 _periodLength, uint32 _periodOffset) {
    if (_periodLength < MINIMUM_PERIOD_LENGTH) {
      revert PeriodLengthTooShort();
    }
    if (_periodOffset > block.timestamp) {
      revert PeriodOffsetInFuture(_periodOffset);
    }
    PERIOD_LENGTH = _periodLength;
    PERIOD_OFFSET = _periodOffset;
  }

  /* ============ External Read Functions ============ */

  /**
   * @notice Returns whether the TwabController has been shutdown at the given timestamp
   * If the twab is queried at or after this time, whether an absolute timestamp or time range, it will return 0.
   * @dev This function will return true for any timestamp after the lastObservationAt()
   * @param timestamp The timestamp to check
   * @return True if the TwabController is shutdown at the given timestamp, false otherwise.
   */
  function isShutdownAt(uint256 timestamp) external view returns (bool) {
    return TwabLib.isShutdownAt(timestamp, PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Computes the timestamp after which no more observations will be made.
   * @return The largest timestamp at which the TwabController can record a new observation.
   */
  function lastObservationAt() external view returns (uint256) {
    return TwabLib.lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Loads the current TWAB Account data for a specific vault stored for a user.
   * @dev Note this is a very expensive function
   * @param vault the vault for which the data is being queried
   * @param user the user whose data is being queried
   * @return The current TWAB Account data of the user
   */
  function getAccount(address vault, address user) external view returns (TwabLib.Account memory) {
    return userObservations[vault][user];
  }

  /**
   * @notice Loads the current total supply TWAB Account data for a specific vault.
   * @dev Note this is a very expensive function
   * @param vault the vault for which the data is being queried
   * @return The current total supply TWAB Account data
   */
  function getTotalSupplyAccount(address vault) external view returns (TwabLib.Account memory) {
    return totalSupplyObservations[vault];
  }

  /**
   * @notice The current token balance of a user for a specific vault.
   * @param vault the vault for which the balance is being queried
   * @param user the user whose balance is being queried
   * @return The current token balance of the user
   */
  function balanceOf(address vault, address user) external view returns (uint256) {
    return userObservations[vault][user].details.balance;
  }

  /**
   * @notice The total supply of tokens for a vault.
   * @param vault the vault for which the total supply is being queried
   * @return The total supply of tokens for a vault
   */
  function totalSupply(address vault) external view returns (uint256) {
    return totalSupplyObservations[vault].details.balance;
  }

  /**
   * @notice The total delegated amount of tokens for a vault.
   * @dev Delegated balance is not 1:1 with the token total supply. Users may delegate their
   *      balance to the sponsorship address, which will result in those tokens being subtracted
   *      from the total.
   * @param vault the vault for which the total delegated supply is being queried
   * @return The total delegated amount of tokens for a vault
   */
  function totalSupplyDelegateBalance(address vault) external view returns (uint256) {
    return totalSupplyObservations[vault].details.delegateBalance;
  }

  /**
   * @notice The current delegate of a user for a specific vault.
   * @param vault the vault for which the delegate balance is being queried
   * @param user the user whose delegate balance is being queried
   * @return The current delegate balance of the user
   */
  function delegateOf(address vault, address user) external view returns (address) {
    return _delegateOf(vault, user);
  }

  /**
   * @notice The current delegateBalance of a user for a specific vault.
   * @dev the delegateBalance is the sum of delegated balance to this user
   * @param vault the vault for which the delegateBalance is being queried
   * @param user the user whose delegateBalance is being queried
   * @return The current delegateBalance of the user
   */
  function delegateBalanceOf(address vault, address user) external view returns (uint256) {
    return userObservations[vault][user].details.delegateBalance;
  }

  /**
   * @notice Looks up a users balance at a specific time in the past.
   * @param vault the vault for which the balance is being queried
   * @param user the user whose balance is being queried
   * @param periodEndOnOrAfterTime The time in the past for which the balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The balance of the user at the target time
   */
  function getBalanceAt(
    address vault,
    address user,
    uint256 periodEndOnOrAfterTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return
      TwabLib.getBalanceAt(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(periodEndOnOrAfterTime)
      );
  }

  /**
   * @notice Looks up the total supply at a specific time in the past.
   * @param vault the vault for which the total supply is being queried
   * @param periodEndOnOrAfterTime The time in the past for which the balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The total supply at the target time
   */
  function getTotalSupplyAt(
    address vault,
    uint256 periodEndOnOrAfterTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return
      TwabLib.getBalanceAt(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(periodEndOnOrAfterTime)
      );
  }

  /**
   * @notice Looks up the average balance of a user between two timestamps.
   * @dev Timestamps are Unix timestamps denominated in seconds
   * @param vault the vault for which the average balance is being queried
   * @param user the user whose average balance is being queried
   * @param startTime the start of the time range for which the average balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @param endTime the end of the time range for which the average balance is being queried. The time will be snapped to a period end time on or after the timestamp.
   * @return The average balance of the user between the two timestamps
   */
  function getTwabBetween(
    address vault,
    address user,
    uint256 startTime,
    uint256 endTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = userObservations[vault][user];
    // We snap the timestamps to the period end on or after the timestamp because the total supply records will be sparsely populated.
    // if two users update during a period, then the total supply observation will only exist for the last one.
    return
      TwabLib.getTwabBetween(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(startTime),
        _periodEndOnOrAfter(endTime)
      );
  }

  /**
   * @notice Looks up the average total supply between two timestamps.
   * @dev Timestamps are Unix timestamps denominated in seconds
   * @param vault the vault for which the average total supply is being queried
   * @param startTime the start of the time range for which the average total supply is being queried
   * @param endTime the end of the time range for which the average total supply is being queried
   * @return The average total supply between the two timestamps
   */
  function getTotalSupplyTwabBetween(
    address vault,
    uint256 startTime,
    uint256 endTime
  ) external view returns (uint256) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    // We snap the timestamps to the period end on or after the timestamp because the total supply records will be sparsely populated.
    // if two users update during a period, then the total supply observation will only exist for the last one.
    return
      TwabLib.getTwabBetween(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account.observations,
        _account.details,
        _periodEndOnOrAfter(startTime),
        _periodEndOnOrAfter(endTime)
      );
  }

  /**
   * @notice Computes the period end timestamp on or after the given timestamp.
   * @param _timestamp The timestamp to check
   * @return The end timestamp of the period that ends on or immediately after the given timestamp
   */
  function periodEndOnOrAfter(uint256 _timestamp) external view returns (uint256) {
    return _periodEndOnOrAfter(_timestamp);
  }

  /**
   * @notice Computes the period end timestamp on or after the given timestamp.
   * @param _timestamp The timestamp to compute the period end time for
   * @return A period end time.
   */
  function _periodEndOnOrAfter(uint256 _timestamp) internal view returns (uint256) {
    if (_timestamp < PERIOD_OFFSET) {
      return PERIOD_OFFSET;
    }
    if ((_timestamp - PERIOD_OFFSET) % PERIOD_LENGTH == 0) {
      return _timestamp;
    }
    uint256 period = TwabLib.getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, _timestamp);
    return TwabLib.getPeriodEndTime(PERIOD_LENGTH, PERIOD_OFFSET, period);
  }

  /**
   * @notice Looks up the newest observation for a user.
   * @param vault the vault for which the observation is being queried
   * @param user the user whose observation is being queried
   * @return index The index of the observation
   * @return observation The observation of the user
   */
  function getNewestObservation(
    address vault,
    address user
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return TwabLib.getNewestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the oldest observation for a user.
   * @param vault the vault for which the observation is being queried
   * @param user the user whose observation is being queried
   * @return index The index of the observation
   * @return observation The observation of the user
   */
  function getOldestObservation(
    address vault,
    address user
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = userObservations[vault][user];
    return TwabLib.getOldestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the newest total supply observation for a vault.
   * @param vault the vault for which the observation is being queried
   * @return index The index of the observation
   * @return observation The total supply observation
   */
  function getNewestTotalSupplyObservation(
    address vault
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return TwabLib.getNewestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Looks up the oldest total supply observation for a vault.
   * @param vault the vault for which the observation is being queried
   * @return index The index of the observation
   * @return observation The total supply observation
   */
  function getOldestTotalSupplyObservation(
    address vault
  ) external view returns (uint16, ObservationLib.Observation memory) {
    TwabLib.Account storage _account = totalSupplyObservations[vault];
    return TwabLib.getOldestObservation(_account.observations, _account.details);
  }

  /**
   * @notice Calculates the period a timestamp falls into.
   * @param time The timestamp to check
   * @return period The period the timestamp falls into
   */
  function getTimestampPeriod(uint256 time) external view returns (uint256) {
    return TwabLib.getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, time);
  }

  /**
   * @notice Checks if the given timestamp is before the current overwrite period.
   * @param time The timestamp to check
   * @return True if the given time is finalized, false if it's during the current overwrite period.
   */
  function hasFinalized(uint256 time) external view returns (bool) {
    return TwabLib.hasFinalized(PERIOD_LENGTH, PERIOD_OFFSET, time);
  }

  /**
   * @notice Computes the timestamp at which the current overwrite period started.
   * @dev The overwrite period is the period during which observations are collated.
   * @return period The timestamp at which the current overwrite period started.
   */
  function currentOverwritePeriodStartedAt() external view returns (uint256) {
    return TwabLib.currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /* ============ External Write Functions ============ */

  /**
   * @notice Mints new balance and delegateBalance for a given user.
   * @dev Note that if the provided user to mint to is delegating that the delegate's
   *      delegateBalance will be updated.
   * @dev Mint is expected to be called by the Vault.
   * @param _to The address to mint balance and delegateBalance to
   * @param _amount The amount to mint
   */
  function mint(address _to, uint96 _amount) external {
    if (_to == address(0)) {
      revert TransferToZeroAddress();
    }
    _transferBalance(msg.sender, address(0), _to, _amount);
  }

  /**
   * @notice Burns balance and delegateBalance for a given user.
   * @dev Note that if the provided user to burn from is delegating that the delegate's
   *      delegateBalance will be updated.
   * @dev Burn is expected to be called by the Vault.
   * @param _from The address to burn balance and delegateBalance from
   * @param _amount The amount to burn
   */
  function burn(address _from, uint96 _amount) external {
    _transferBalance(msg.sender, _from, address(0), _amount);
  }

  /**
   * @notice Transfers balance and delegateBalance from a given user.
   * @dev Note that if the provided user to transfer from is delegating that the delegate's
   *      delegateBalance will be updated.
   * @param _from The address to transfer the balance and delegateBalance from
   * @param _to The address to transfer balance and delegateBalance to
   * @param _amount The amount to transfer
   */
  function transfer(address _from, address _to, uint96 _amount) external {
    if (_to == address(0)) {
      revert TransferToZeroAddress();
    }
    _transferBalance(msg.sender, _from, _to, _amount);
  }

  /**
   * @notice Sets a delegate for a user which forwards the delegateBalance tied to the user's
   *          balance to the delegate's delegateBalance.
   * @param _vault The vault for which the delegate is being set
   * @param _to the address to delegate to
   */
  function delegate(address _vault, address _to) external {
    _delegate(_vault, msg.sender, _to);
  }

  /**
   * @notice Delegate user balance to the sponsorship address.
   * @dev Must only be called by the Vault contract.
   * @param _from Address of the user delegating their balance to the sponsorship address.
   */
  function sponsor(address _from) external {
    _delegate(msg.sender, _from, SPONSORSHIP_ADDRESS);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Transfers a user's vault balance from one address to another.
   * @dev If the user is delegating, their delegate's delegateBalance is also updated.
   * @dev If we are minting or burning tokens then the total supply is also updated.
   * @param _vault the vault for which the balance is being transferred
   * @param _from the address from which the balance is being transferred
   * @param _to the address to which the balance is being transferred
   * @param _amount the amount of balance being transferred
   */
  function _transferBalance(address _vault, address _from, address _to, uint96 _amount) internal {
    if (_to == SPONSORSHIP_ADDRESS) {
      revert CannotTransferToSponsorshipAddress();
    }

    if (_from == _to) {
      return;
    }

    // If we are transferring tokens from a delegated account to an undelegated account
    address _fromDelegate = _delegateOf(_vault, _from);
    address _toDelegate = _delegateOf(_vault, _to);
    if (_from != address(0)) {
      bool _isFromDelegate = _fromDelegate == _from;

      _decreaseBalances(_vault, _from, _amount, _isFromDelegate ? _amount : 0);

      // If the user is not delegating to themself, decrease the delegate's delegateBalance
      // If the user is delegating to the sponsorship address, don't adjust the delegateBalance
      if (!_isFromDelegate && _fromDelegate != SPONSORSHIP_ADDRESS) {
        _decreaseBalances(_vault, _fromDelegate, 0, _amount);
      }

      // Burn balance if we're transferring to address(0)
      // Burn delegateBalance if we're transferring to address(0) and burning from an address that is not delegating to the sponsorship address
      // Burn delegateBalance if we're transferring to an address delegating to the sponsorship address from an address that isn't delegating to the sponsorship address
      if (
        _to == address(0) ||
        (_toDelegate == SPONSORSHIP_ADDRESS && _fromDelegate != SPONSORSHIP_ADDRESS)
      ) {
        // If the user is delegating to the sponsorship address, don't adjust the total supply delegateBalance
        _decreaseTotalSupplyBalances(
          _vault,
          _to == address(0) ? _amount : 0,
          (_to == address(0) && _fromDelegate != SPONSORSHIP_ADDRESS) ||
            (_toDelegate == SPONSORSHIP_ADDRESS && _fromDelegate != SPONSORSHIP_ADDRESS)
            ? _amount
            : 0
        );
      }
    }

    // If we are transferring tokens to an address other than address(0)
    if (_to != address(0)) {
      bool _isToDelegate = _toDelegate == _to;

      // If the user is delegating to themself, increase their delegateBalance
      _increaseBalances(_vault, _to, _amount, _isToDelegate ? _amount : 0);

      // Otherwise, increase their delegates delegateBalance if it is not the sponsorship address
      if (!_isToDelegate && _toDelegate != SPONSORSHIP_ADDRESS) {
        _increaseBalances(_vault, _toDelegate, 0, _amount);
      }

      // Mint balance if we're transferring from address(0)
      // Mint delegateBalance if we're transferring from address(0) and to an address not delegating to the sponsorship address
      // Mint delegateBalance if we're transferring from an address delegating to the sponsorship address to an address that isn't delegating to the sponsorship address
      if (
        _from == address(0) ||
        (_fromDelegate == SPONSORSHIP_ADDRESS && _toDelegate != SPONSORSHIP_ADDRESS)
      ) {
        _increaseTotalSupplyBalances(
          _vault,
          _from == address(0) ? _amount : 0,
          (_from == address(0) && _toDelegate != SPONSORSHIP_ADDRESS) ||
            (_fromDelegate == SPONSORSHIP_ADDRESS && _toDelegate != SPONSORSHIP_ADDRESS)
            ? _amount
            : 0
        );
      }
    }
  }

  /**
   * @notice Looks up the delegate of a user.
   * @param _vault the vault for which the user's delegate is being queried
   * @param _user the address to query the delegate of
   * @return The address of the user's delegate
   */
  function _delegateOf(address _vault, address _user) internal view returns (address) {
    address _userDelegate;

    if (_user != address(0)) {
      _userDelegate = delegates[_vault][_user];

      // If the user has not delegated, then the user is the delegate
      if (_userDelegate == address(0)) {
        _userDelegate = _user;
      }
    }

    return _userDelegate;
  }

  /**
   * @notice Transfers a user's vault delegateBalance from one address to another.
   * @param _vault the vault for which the delegateBalance is being transferred
   * @param _fromDelegate the address from which the delegateBalance is being transferred
   * @param _toDelegate the address to which the delegateBalance is being transferred
   * @param _amount the amount of delegateBalance being transferred
   */
  function _transferDelegateBalance(
    address _vault,
    address _fromDelegate,
    address _toDelegate,
    uint96 _amount
  ) internal {
    // If we are transferring tokens from a delegated account to an undelegated account
    if (_fromDelegate != address(0) && _fromDelegate != SPONSORSHIP_ADDRESS) {
      _decreaseBalances(_vault, _fromDelegate, 0, _amount);

      // If we are delegating to the zero address, decrease total supply
      // If we are delegating to the sponsorship address, decrease total supply
      if (_toDelegate == address(0) || _toDelegate == SPONSORSHIP_ADDRESS) {
        _decreaseTotalSupplyBalances(_vault, 0, _amount);
      }
    }

    // If we are transferring tokens from an undelegated account to a delegated account
    if (_toDelegate != address(0) && _toDelegate != SPONSORSHIP_ADDRESS) {
      _increaseBalances(_vault, _toDelegate, 0, _amount);

      // If we are removing delegation from the zero address, increase total supply
      // If we are removing delegation from the sponsorship address, increase total supply
      if (_fromDelegate == address(0) || _fromDelegate == SPONSORSHIP_ADDRESS) {
        _increaseTotalSupplyBalances(_vault, 0, _amount);
      }
    }
  }

  /**
   * @notice Sets a delegate for a user which forwards the delegateBalance tied to the user's
   * balance to the delegate's delegateBalance. "Sponsoring" means the funds aren't delegated
   * to anyone; this can be done by passing address(0) or the SPONSORSHIP_ADDRESS as the delegate.
   * @param _vault The vault for which the delegate is being set
   * @param _from the address to delegate from
   * @param _to the address to delegate to
   */
  function _delegate(address _vault, address _from, address _to) internal {
    address _currentDelegate = _delegateOf(_vault, _from);
    // address(0) is interpreted as sponsoring, so they don't need to know the sponsorship address.
    address to = _to == address(0) ? SPONSORSHIP_ADDRESS : _to;
    if (to == _currentDelegate) {
      revert SameDelegateAlreadySet(to);
    }

    delegates[_vault][_from] = to;

    _transferDelegateBalance(
      _vault,
      _currentDelegate,
      _to,
      SafeCast.toUint96(userObservations[_vault][_from].details.balance)
    );

    emit Delegated(_vault, _from, to);
  }

  /**
   * @notice Increases a user's balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the balance is being increased
   * @param _user the address of the user whose balance is being increased
   * @param _amount the amount of balance being increased
   * @param _delegateAmount the amount of delegateBalance being increased
   */
  function _increaseBalances(
    address _vault,
    address _user,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = userObservations[_vault][_user];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.increaseBalances(PERIOD_LENGTH, PERIOD_OFFSET, _account, _amount, _delegateAmount);

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit IncreasedBalance(_vault, _user, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit ObservationRecorded(
        _vault,
        _user,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Decreases the a user's balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being decreased
   * @param _amount the amount of balance being decreased
   * @param _delegateAmount the amount of delegateBalance being decreased
   */
  function _decreaseBalances(
    address _vault,
    address _user,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = userObservations[_vault][_user];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.decreaseBalances(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account,
        _amount,
        _delegateAmount,
        "TC/observation-burn-lt-delegate-balance"
      );

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit DecreasedBalance(_vault, _user, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit ObservationRecorded(
        _vault,
        _user,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Decreases the totalSupply balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being decreased
   * @param _amount the amount of balance being decreased
   * @param _delegateAmount the amount of delegateBalance being decreased
   */
  function _decreaseTotalSupplyBalances(
    address _vault,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = totalSupplyObservations[_vault];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.decreaseBalances(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        _account,
        _amount,
        _delegateAmount,
        "TC/burn-amount-exceeds-total-supply-balance"
      );

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit DecreasedTotalSupply(_vault, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit TotalSupplyObservationRecorded(
        _vault,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }

  /**
   * @notice Increases the totalSupply balance and delegateBalance for a specific vault.
   * @param _vault the vault for which the totalSupply balance is being increased
   * @param _amount the amount of balance being increased
   * @param _delegateAmount the amount of delegateBalance being increased
   */
  function _increaseTotalSupplyBalances(
    address _vault,
    uint96 _amount,
    uint96 _delegateAmount
  ) internal {
    TwabLib.Account storage _account = totalSupplyObservations[_vault];

    (
      ObservationLib.Observation memory _observation,
      bool _isNewObservation,
      bool _isObservationRecorded,
      TwabLib.AccountDetails memory accountDetails
    ) = TwabLib.increaseBalances(PERIOD_LENGTH, PERIOD_OFFSET, _account, _amount, _delegateAmount);

    // Always emit the balance change event
    if (_amount != 0 || _delegateAmount != 0) {
      emit IncreasedTotalSupply(_vault, _amount, _delegateAmount);
    }

    // Conditionally emit the observation recorded event
    if (_isObservationRecorded) {
      emit TotalSupplyObservationRecorded(
        _vault,
        accountDetails.balance,
        accountDetails.delegateBalance,
        _isNewObservation,
        _observation
      );
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title Contract instantiated via CREATE2 to handle a Delegation by a delegator to a delegatee.
 * @notice A Delegation allows his owner to execute calls on behalf of the contract.
 * @dev This contract is intended to be counterfactually instantiated via CREATE2 through the LowLevelDelegator contract.
 * @dev This contract will hold tickets that will be delegated to a chosen delegatee.
 */
contract Delegation {
  /**
   * @notice A structure to define arbitrary contract calls.
   * @param to The address to call
   * @param data The call data
   */
  struct Call {
    address to;
    bytes data;
  }

  /// @notice Contract owner.
  address private _owner;

  /// @notice Timestamp until which the delegation is locked.
  uint96 public lockUntil;

  /**
   * @notice Initializes the delegation.
   * @param _lockUntil Timestamp until which the delegation is locked
   */
  function initialize(uint96 _lockUntil) external {
    require(_owner == address(0), "Delegation/already-init");
    _owner = msg.sender;
    lockUntil = _lockUntil;
  }

  /**
   * @notice Executes calls on behalf of this contract.
   * @param calls The array of calls to be executed
   * @return An array of the return values for each of the calls
   */
  function executeCalls(Call[] calldata calls) external onlyOwner returns (bytes[] memory) {
    uint256 _callsLength = calls.length;
    bytes[] memory response = new bytes[](_callsLength);
    Call memory call;

    for (uint256 i; i < _callsLength; i++) {
      call = calls[i];
      response[i] = _executeCall(call.to, call.data);
    }

    return response;
  }

  /**
   * @notice Set the timestamp until which the delegation is locked.
   * @param _lockUntil The timestamp until which the delegation is locked
   */
  function setLockUntil(uint96 _lockUntil) external onlyOwner {
    lockUntil = _lockUntil;
  }

  /**
   * @notice Executes a call to another contract.
   * @param to The address to call
   * @param data The call data
   * @return The return data from the call
   */
  function _executeCall(address to, bytes memory data) internal returns (bytes memory) {
    (bool succeeded, bytes memory returnValue) = to.call{ value: 0 }(data);
    require(succeeded, string(returnValue));
    return returnValue;
  }

  /// @notice Modifier to only allow the contract owner to call a function
  modifier onlyOwner() {
    require(msg.sender == _owner, "Delegation/only-owner");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Clones } from "openzeppelin/proxy/Clones.sol";

import { Delegation } from "./Delegation.sol";

/// @title The LowLevelDelegator allows users to create delegations very cheaply.
contract LowLevelDelegator {
  using Clones for address;

  /// @notice The instance to which all proxies will point.
  Delegation public delegationInstance;

  /// @notice Contract constructor.
  constructor() {
    delegationInstance = new Delegation();
    delegationInstance.initialize(uint96(0));
  }

  /**
   * @notice Creates a clone of the delegation.
   * @param _salt Random number used to deterministically deploy the clone
   * @param _lockUntil Timestamp until which the delegation is locked
   * @return The newly created delegation
   */
  function _createDelegation(bytes32 _salt, uint96 _lockUntil) internal returns (Delegation) {
    Delegation _delegation = Delegation(address(delegationInstance).cloneDeterministic(_salt));
    _delegation.initialize(_lockUntil);
    return _delegation;
  }

  /**
   * @notice Computes the address of a clone, also known as minimal proxy contract.
   * @param _salt Random number used to compute the address
   * @return Address at which the clone will be deployed
   */
  function _computeAddress(bytes32 _salt) internal view returns (address) {
    return address(delegationInstance).predictDeterministicAddress(_salt, address(this));
  }

  /**
   * @notice Computes salt used to deterministically deploy a clone.
   * @param _delegator Address of the delegator
   * @param _slot Slot of the delegation
   * @return Salt used to deterministically deploy a clone.
   */
  function _computeSalt(address _delegator, bytes32 _slot) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_delegator, _slot));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC20Permit } from "openzeppelin/token/ERC20/extensions/IERC20Permit.sol";
import { Address } from "openzeppelin/utils/Address.sol";

/**
 * @notice Allows a user to permit token spend and then call multiple functions on a contract.
 */
contract PermitAndMulticall {
  /**
   * @notice Secp256k1 signature values.
   * @param deadline Timestamp at which the signature expires
   * @param v `v` portion of the signature
   * @param r `r` portion of the signature
   * @param s `s` portion of the signature
   */
  struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  /**
   * @notice Allows a user to call multiple functions on the same contract.  Useful for EOA who want to batch transactions.
   * @param _data An array of encoded function calls.  The calls must be abi-encoded calls to this contract.
   * @return The results from each function call
   */
  function _multicall(bytes[] calldata _data) internal virtual returns (bytes[] memory) {
    uint256 _dataLength = _data.length;
    bytes[] memory results = new bytes[](_dataLength);

    for (uint256 i; i < _dataLength; i++) {
      results[i] = Address.functionDelegateCall(address(this), _data[i]);
    }

    return results;
  }

  /**
   * @notice Allow a user to approve an ERC20 token and run various calls in one transaction.
   * @param _permitToken Address of the ERC20 token
   * @param _amount Amount of tickets to approve
   * @param _permitSignature Permit signature
   * @param _data Datas to call with `functionDelegateCall`
   */
  function _permitAndMulticall(
    IERC20Permit _permitToken,
    uint256 _amount,
    Signature calldata _permitSignature,
    bytes[] calldata _data
  ) internal {
    _permitToken.permit(
      msg.sender,
      address(this),
      _amount,
      _permitSignature.deadline,
      _permitSignature.v,
      _permitSignature.r,
      _permitSignature.s
    );

    _multicall(_data);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "ring-buffer-lib/RingBufferLib.sol";

import { ObservationLib, MAX_CARDINALITY } from "./ObservationLib.sol";

type PeriodOffsetRelativeTimestamp is uint32;

/// @notice Emitted when a balance is decreased by an amount that exceeds the amount available.
/// @param balance The current balance of the account
/// @param amount The amount being decreased from the account's balance
/// @param message An additional message describing the error
error BalanceLTAmount(uint96 balance, uint96 amount, string message);

/// @notice Emitted when a delegate balance is decreased by an amount that exceeds the amount available.
/// @param delegateBalance The current delegate balance of the account
/// @param delegateAmount The amount being decreased from the account's delegate balance
/// @param message An additional message describing the error
error DelegateBalanceLTAmount(uint96 delegateBalance, uint96 delegateAmount, string message);

/// @notice Emitted when a request is made for a twab that is not yet finalized.
/// @param timestamp The requested timestamp
/// @param currentOverwritePeriodStartedAt The current overwrite period start time
error TimestampNotFinalized(uint256 timestamp, uint256 currentOverwritePeriodStartedAt);

/// @notice Emitted when a TWAB time range start is after the end.
/// @param start The start time
/// @param end The end time
error InvalidTimeRange(uint256 start, uint256 end);

/// @notice Emitted when there is insufficient history to lookup a twab time range
/// @param requestedTimestamp The timestamp requested
/// @param oldestTimestamp The oldest timestamp that can be read
error InsufficientHistory(
  PeriodOffsetRelativeTimestamp requestedTimestamp,
  PeriodOffsetRelativeTimestamp oldestTimestamp
);

/**
 * @title  PoolTogether V5 TwabLib (Library)
 * @author PoolTogether Inc. & G9 Software Inc.
 * @dev    Time-Weighted Average Balance Library for ERC20 tokens.
 * @notice This TwabLib adds on-chain historical lookups to a user(s) time-weighted average balance.
 *         Each user is mapped to an Account struct containing the TWAB history (ring buffer) and
 *         ring buffer parameters. Every token.transfer() creates a new TWAB checkpoint. The new
 *         TWAB checkpoint is stored in the circular ring buffer, as either a new checkpoint or
 *         rewriting a previous checkpoint with new parameters. One checkpoint per day is stored.
 *         The TwabLib guarantees minimum 1 year of search history.
 * @notice There are limitations to the Observation data structure used. Ensure your token is
 *         compatible before using this library. Ensure the date ranges you're relying on are
 *         within safe boundaries.
 */
library TwabLib {
  /**
   * @notice Struct ring buffer parameters for single user Account.
   * @param balance Current token balance for an Account
   * @param delegateBalance Current delegate balance for an Account (active balance for chance)
   * @param nextObservationIndex Next uninitialized or updatable ring buffer checkpoint storage slot
   * @param cardinality Current total "initialized" ring buffer checkpoints for single user Account.
   *                    Used to set initial boundary conditions for an efficient binary search.
   */
  struct AccountDetails {
    uint96 balance;
    uint96 delegateBalance;
    uint16 nextObservationIndex;
    uint16 cardinality;
  }

  /**
   * @notice Account details and historical twabs.
   * @dev The size of observations is MAX_CARDINALITY from the ObservationLib.
   * @param details The account details
   * @param observations The history of observations for this account
   */
  struct Account {
    AccountDetails details;
    ObservationLib.Observation[17520] observations;
  }

  /**
   * @notice Increase a user's balance and delegate balance by a given amount.
   * @dev This function mutates the provided account.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _account The account to update
   * @param _amount The amount to increase the balance by
   * @param _delegateAmount The amount to increase the delegate balance by
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return isObservationRecorded Whether or not an observation was recorded to storage
   */
  function increaseBalances(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    Account storage _account,
    uint96 _amount,
    uint96 _delegateAmount
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      bool isObservationRecorded,
      AccountDetails memory accountDetails
    )
  {
    accountDetails = _account.details;
    // record a new observation if the delegateAmount is non-zero and time has not overflowed.
    isObservationRecorded =
      _delegateAmount != uint96(0) &&
      block.timestamp <= lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);

    accountDetails.balance += _amount;
    accountDetails.delegateBalance += _delegateAmount;

    // Only record a new Observation if the users delegateBalance has changed.
    if (isObservationRecorded) {
      (observation, isNew, accountDetails) = _recordObservation(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        accountDetails,
        _account
      );
    }

    _account.details = accountDetails;
  }

  /**
   * @notice Decrease a user's balance and delegate balance by a given amount.
   * @dev This function mutates the provided account.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _account The account to update
   * @param _amount The amount to decrease the balance by
   * @param _delegateAmount The amount to decrease the delegate balance by
   * @param _revertMessage The revert message to use if the balance is insufficient
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return isObservationRecorded Whether or not the observation was recorded to storage
   */
  function decreaseBalances(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    Account storage _account,
    uint96 _amount,
    uint96 _delegateAmount,
    string memory _revertMessage
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      bool isObservationRecorded,
      AccountDetails memory accountDetails
    )
  {
    accountDetails = _account.details;

    if (accountDetails.balance < _amount) {
      revert BalanceLTAmount(accountDetails.balance, _amount, _revertMessage);
    }
    if (accountDetails.delegateBalance < _delegateAmount) {
      revert DelegateBalanceLTAmount(
        accountDetails.delegateBalance,
        _delegateAmount,
        _revertMessage
      );
    }

    // record a new observation if the delegateAmount is non-zero and time has not overflowed.
    isObservationRecorded =
      _delegateAmount != uint96(0) &&
      block.timestamp <= lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);

    unchecked {
      accountDetails.balance -= _amount;
      accountDetails.delegateBalance -= _delegateAmount;
    }

    // Only record a new Observation if the users delegateBalance has changed.
    if (isObservationRecorded) {
      (observation, isNew, accountDetails) = _recordObservation(
        PERIOD_LENGTH,
        PERIOD_OFFSET,
        accountDetails,
        _account
      );
    }

    _account.details = accountDetails;
  }

  /**
   * @notice Looks up the oldest observation in the circular buffer.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the oldest observation
   * @return observation The oldest observation in the circular buffer
   */
  function getOldestObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  ) internal view returns (uint16 index, ObservationLib.Observation memory observation) {
    // If the circular buffer has not been fully populated, we go to the beginning of the buffer at index 0.
    if (_accountDetails.cardinality < MAX_CARDINALITY) {
      index = 0;
      observation = _observations[0];
    } else {
      index = _accountDetails.nextObservationIndex;
      observation = _observations[index];
    }
  }

  /**
   * @notice Looks up the newest observation in the circular buffer.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the newest observation
   * @return observation The newest observation in the circular buffer
   */
  function getNewestObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  ) internal view returns (uint16 index, ObservationLib.Observation memory observation) {
    index = uint16(
      RingBufferLib.newestIndex(_accountDetails.nextObservationIndex, MAX_CARDINALITY)
    );
    observation = _observations[index];
  }

  /**
   * @notice Looks up a users balance at a specific time in the past. The time must be before the current overwrite period.
   * @dev Ensure timestamps are safe using requireFinalized
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _targetTime The time to look up the balance at
   * @return balance The balance at the target time
   */
  function getBalanceAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _targetTime
  ) internal view requireFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _targetTime) returns (uint256) {
    if (_targetTime < PERIOD_OFFSET) {
      return 0;
    }
    // if this is for an overflowed time period, return 0
    if (isShutdownAt(_targetTime, PERIOD_LENGTH, PERIOD_OFFSET)) {
      return 0;
    }
    ObservationLib.Observation memory prevOrAtObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(_targetTime - PERIOD_OFFSET))
    );
    return prevOrAtObservation.balance;
  }

  /**
   * @notice Returns whether the TwabController has been shutdown at the given timestamp
   * If the twab is queried at or after this time, whether an absolute timestamp or time range, it will return 0.
   * @param timestamp The timestamp to check
   * @param PERIOD_OFFSET The offset of the first period
   * @return True if the TwabController is shutdown at the given timestamp, false otherwise.
   */
  function isShutdownAt(
    uint256 timestamp,
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal pure returns (bool) {
    return timestamp > lastObservationAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Computes the largest timestamp at which the TwabController can record a new observation.
   * @param PERIOD_OFFSET The offset of the first period
   * @return The largest timestamp at which the TwabController can record a new observation.
   */
  function lastObservationAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal pure returns (uint256) {
    return uint256(PERIOD_OFFSET) + (type(uint32).max / PERIOD_LENGTH) * PERIOD_LENGTH;
  }

  /**
   * @notice Looks up a users TWAB for a time range. The time must be before the current overwrite period.
   * @dev If the timestamps in the range are not exact matches of observations, the balance is extrapolated using the previous observation.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _startTime The start of the time range
   * @param _endTime The end of the time range
   * @return twab The TWAB for the time range
   */
  function getTwabBetween(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _startTime,
    uint256 _endTime
  ) internal view requireFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _endTime) returns (uint256) {
    if (_endTime < _startTime) {
      revert InvalidTimeRange(_startTime, _endTime);
    }

    // if the range extends into the shutdown period, return 0
    if (isShutdownAt(_endTime, PERIOD_LENGTH, PERIOD_OFFSET)) {
      return 0;
    }

    uint256 offsetStartTime = _startTime - PERIOD_OFFSET;
    uint256 offsetEndTime = _endTime - PERIOD_OFFSET;

    ObservationLib.Observation memory endObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetEndTime))
    );

    if (offsetStartTime == offsetEndTime) {
      return endObservation.balance;
    }

    ObservationLib.Observation memory startObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetStartTime))
    );

    if (startObservation.timestamp != offsetStartTime) {
      startObservation = _calculateTemporaryObservation(
        startObservation,
        PeriodOffsetRelativeTimestamp.wrap(uint32(offsetStartTime))
      );
    }

    if (endObservation.timestamp != offsetEndTime) {
      endObservation = _calculateTemporaryObservation(
        endObservation,
        PeriodOffsetRelativeTimestamp.wrap(uint32(offsetEndTime))
      );
    }

    // Difference in amount / time
    return
      (endObservation.cumulativeBalance - startObservation.cumulativeBalance) /
      (offsetEndTime - offsetStartTime);
  }

  /**
   * @notice Given an AccountDetails with updated balances, either updates the latest Observation or records a new one
   * @param PERIOD_LENGTH The overwrite period length
   * @param PERIOD_OFFSET The overwrite period offset
   * @param _accountDetails The updated account details
   * @param _account The account to update
   * @return observation The new/updated observation
   * @return isNew Whether or not the observation is new or overwrote a previous one
   * @return newAccountDetails The new account details
   */
  function _recordObservation(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    AccountDetails memory _accountDetails,
    Account storage _account
  )
    internal
    returns (
      ObservationLib.Observation memory observation,
      bool isNew,
      AccountDetails memory newAccountDetails
    )
  {
    PeriodOffsetRelativeTimestamp currentTime = PeriodOffsetRelativeTimestamp.wrap(
      uint32(block.timestamp - PERIOD_OFFSET)
    );

    uint16 nextIndex;
    ObservationLib.Observation memory newestObservation;
    (nextIndex, newestObservation, isNew) = _getNextObservationIndex(
      PERIOD_LENGTH,
      PERIOD_OFFSET,
      _account.observations,
      _accountDetails
    );

    if (isNew) {
      // If the index is new, then we increase the next index to use
      _accountDetails.nextObservationIndex = uint16(
        RingBufferLib.nextIndex(uint256(nextIndex), MAX_CARDINALITY)
      );

      // Prevent the Account specific cardinality from exceeding the MAX_CARDINALITY.
      // The ring buffer length is limited by MAX_CARDINALITY. IF the account.cardinality
      // exceeds the max cardinality, new observations would be incorrectly set or the
      // observation would be out of "bounds" of the ring buffer. Once reached the
      // Account.cardinality will continue to be equal to max cardinality.
      _accountDetails.cardinality = _accountDetails.cardinality < MAX_CARDINALITY
        ? _accountDetails.cardinality + 1
        : MAX_CARDINALITY;
    }

    observation = ObservationLib.Observation({
      cumulativeBalance: _extrapolateFromBalance(newestObservation, currentTime),
      balance: _accountDetails.delegateBalance,
      timestamp: PeriodOffsetRelativeTimestamp.unwrap(currentTime)
    });

    // Write to storage
    _account.observations[nextIndex] = observation;
    newAccountDetails = _accountDetails;
  }

  /**
   * @notice Calculates a temporary observation for a given time using the previous observation.
   * @dev This is used to extrapolate a balance for any given time.
   * @param _observation The previous observation
   * @param _time The time to extrapolate to
   */
  function _calculateTemporaryObservation(
    ObservationLib.Observation memory _observation,
    PeriodOffsetRelativeTimestamp _time
  ) private pure returns (ObservationLib.Observation memory) {
    return
      ObservationLib.Observation({
        cumulativeBalance: _extrapolateFromBalance(_observation, _time),
        balance: _observation.balance,
        timestamp: PeriodOffsetRelativeTimestamp.unwrap(_time)
      });
  }

  /**
   * @notice Looks up the next observation index to write to in the circular buffer.
   * @dev If the current time is in the same period as the newest observation, we overwrite it.
   * @dev If the current time is in a new period, we increment the index and write a new observation.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @return index The index of the next observation slot to overwrite
   * @return newestObservation The newest observation in the circular buffer
   * @return isNew True if the observation slot is new, false if we're overwriting
   */
  function _getNextObservationIndex(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails
  )
    private
    view
    returns (uint16 index, ObservationLib.Observation memory newestObservation, bool isNew)
  {
    uint16 newestIndex;
    (newestIndex, newestObservation) = getNewestObservation(_observations, _accountDetails);

    uint256 currentPeriod = getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, block.timestamp);

    uint256 newestObservationPeriod = getTimestampPeriod(
      PERIOD_LENGTH,
      PERIOD_OFFSET,
      PERIOD_OFFSET + uint256(newestObservation.timestamp)
    );

    // Create a new Observation if it's the first period or the current time falls within a new period
    if (_accountDetails.cardinality == 0 || currentPeriod > newestObservationPeriod) {
      return (_accountDetails.nextObservationIndex, newestObservation, true);
    }

    // Otherwise, we're overwriting the current newest Observation
    return (newestIndex, newestObservation, false);
  }

  /**
   * @notice Computes the start time of the current overwrite period
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @return The start time of the current overwrite period
   */
  function _currentOverwritePeriodStartedAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) private view returns (uint256) {
    uint256 period = getTimestampPeriod(PERIOD_LENGTH, PERIOD_OFFSET, block.timestamp);
    return getPeriodStartTime(PERIOD_LENGTH, PERIOD_OFFSET, period);
  }

  /**
   * @notice Calculates the next cumulative balance using a provided Observation and timestamp.
   * @param _observation The observation to extrapolate from
   * @param _offsetTimestamp The timestamp to extrapolate to
   * @return cumulativeBalance The cumulative balance at the timestamp
   */
  function _extrapolateFromBalance(
    ObservationLib.Observation memory _observation,
    PeriodOffsetRelativeTimestamp _offsetTimestamp
  ) private pure returns (uint128) {
    // new cumulative balance = provided cumulative balance (or zero) + (current balance * elapsed seconds)
    unchecked {
      return
        uint128(
          uint256(_observation.cumulativeBalance) +
            uint256(_observation.balance) *
            (PeriodOffsetRelativeTimestamp.unwrap(_offsetTimestamp) - _observation.timestamp)
        );
    }
  }

  /**
   * @notice Computes the overwrite period start time given the current time
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @return The start time for the current overwrite period.
   */
  function currentOverwritePeriodStartedAt(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET
  ) internal view returns (uint256) {
    return _currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Calculates the period a timestamp falls within.
   * @dev Timestamp prior to the PERIOD_OFFSET are considered to be in period 0.
   * @param PERIOD_LENGTH The length of an overwrite period
   * @param PERIOD_OFFSET The offset of the first period
   * @param _timestamp The timestamp to calculate the period for
   * @return period The period
   */
  function getTimestampPeriod(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _timestamp
  ) internal pure returns (uint256) {
    if (_timestamp <= PERIOD_OFFSET) {
      return 0;
    }
    return (_timestamp - PERIOD_OFFSET) / uint256(PERIOD_LENGTH);
  }

  /**
   * @notice Calculates the start timestamp for a period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _period The period to check
   * @return _timestamp The timestamp at which the period starts
   */
  function getPeriodStartTime(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _period
  ) internal pure returns (uint256) {
    return _period * PERIOD_LENGTH + PERIOD_OFFSET;
  }

  /**
   * @notice Calculates the last timestamp for a period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _period The period to check
   * @return _timestamp The timestamp at which the period ends
   */
  function getPeriodEndTime(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _period
  ) internal pure returns (uint256) {
    return (_period + 1) * PERIOD_LENGTH + PERIOD_OFFSET;
  }

  /**
   * @notice Looks up the newest observation before or at a given timestamp.
   * @dev If an observation is available at the target time, it is returned. Otherwise, the newest observation before the target time is returned.
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _targetTime The timestamp to look up
   * @return prevOrAtObservation The observation
   */
  function getPreviousOrAtObservation(
    uint32 PERIOD_OFFSET,
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    uint256 _targetTime
  ) internal view returns (ObservationLib.Observation memory prevOrAtObservation) {
    if (_targetTime < PERIOD_OFFSET) {
      return ObservationLib.Observation({ cumulativeBalance: 0, balance: 0, timestamp: 0 });
    }
    uint256 offsetTargetTime = _targetTime - PERIOD_OFFSET;
    // if this is for an overflowed time period, return 0
    if (offsetTargetTime > type(uint32).max) {
      return
        ObservationLib.Observation({
          cumulativeBalance: 0,
          balance: 0,
          timestamp: type(uint32).max
        });
    }
    prevOrAtObservation = _getPreviousOrAtObservation(
      _observations,
      _accountDetails,
      PeriodOffsetRelativeTimestamp.wrap(uint32(offsetTargetTime))
    );
  }

  /**
   * @notice Looks up the newest observation before or at a given timestamp.
   * @dev If an observation is available at the target time, it is returned. Otherwise, the newest observation before the target time is returned.
   * @param _observations The circular buffer of observations
   * @param _accountDetails The account details to query with
   * @param _offsetTargetTime The timestamp to look up (offset by the period offset)
   * @return prevOrAtObservation The observation
   */
  function _getPreviousOrAtObservation(
    ObservationLib.Observation[MAX_CARDINALITY] storage _observations,
    AccountDetails memory _accountDetails,
    PeriodOffsetRelativeTimestamp _offsetTargetTime
  ) private view returns (ObservationLib.Observation memory prevOrAtObservation) {
    // If there are no observations, return a zeroed observation
    if (_accountDetails.cardinality == 0) {
      return ObservationLib.Observation({ cumulativeBalance: 0, balance: 0, timestamp: 0 });
    }

    uint16 oldestTwabIndex;

    (oldestTwabIndex, prevOrAtObservation) = getOldestObservation(_observations, _accountDetails);

    // if the requested time is older than the oldest observation
    if (PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime) < prevOrAtObservation.timestamp) {
      // if the user didn't have any activity prior to the oldest observation, then we know they had a zero balance
      if (_accountDetails.cardinality < MAX_CARDINALITY) {
        return
          ObservationLib.Observation({
            cumulativeBalance: 0,
            balance: 0,
            timestamp: PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime)
          });
      } else {
        // if we are missing their history, we must revert
        revert InsufficientHistory(
          _offsetTargetTime,
          PeriodOffsetRelativeTimestamp.wrap(prevOrAtObservation.timestamp)
        );
      }
    }

    // We know targetTime >= oldestObservation.timestamp because of the above if statement, so we can return here.
    if (_accountDetails.cardinality == 1) {
      return prevOrAtObservation;
    }

    // Find the newest observation
    (
      uint16 newestTwabIndex,
      ObservationLib.Observation memory afterOrAtObservation
    ) = getNewestObservation(_observations, _accountDetails);

    // if the target time is at or after the newest, return it
    if (PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime) >= afterOrAtObservation.timestamp) {
      return afterOrAtObservation;
    }
    // if we know there is only 1 observation older than the newest
    if (_accountDetails.cardinality == 2) {
      return prevOrAtObservation;
    }

    // Otherwise, we perform a binarySearch to find the observation before or at the timestamp
    (prevOrAtObservation, oldestTwabIndex, afterOrAtObservation, newestTwabIndex) = ObservationLib
      .binarySearch(
        _observations,
        newestTwabIndex,
        oldestTwabIndex,
        PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime),
        _accountDetails.cardinality
      );

    // If the afterOrAt is at, we can skip a temporary Observation computation by returning it here
    if (afterOrAtObservation.timestamp == PeriodOffsetRelativeTimestamp.unwrap(_offsetTargetTime)) {
      return afterOrAtObservation;
    }

    return prevOrAtObservation;
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @dev A timestamp is safe if it is before the current overwrite period
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _time The timestamp to check
   * @return isSafe Whether or not the timestamp is safe
   */
  function hasFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _time
  ) internal view returns (bool) {
    return _hasFinalized(PERIOD_LENGTH, PERIOD_OFFSET, _time);
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @dev A timestamp is safe if it is on or before the current overwrite period start time
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _time The timestamp to check
   * @return isSafe Whether or not the timestamp is safe
   */
  function _hasFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _time
  ) private view returns (bool) {
    // It's safe if equal to the overwrite period start time, because the cumulative balance won't be impacted
    return _time <= _currentOverwritePeriodStartedAt(PERIOD_LENGTH, PERIOD_OFFSET);
  }

  /**
   * @notice Checks if the given timestamp is safe to perform a historic balance lookup on.
   * @param PERIOD_LENGTH The period length to use to calculate the period
   * @param PERIOD_OFFSET The period offset to use to calculate the period
   * @param _timestamp The timestamp to check
   */
  modifier requireFinalized(
    uint32 PERIOD_LENGTH,
    uint32 PERIOD_OFFSET,
    uint256 _timestamp
  ) {
    // The current period can still be changed; so the start of the period marks the beginning of unsafe timestamps.
    uint256 overwritePeriodStartTime = _currentOverwritePeriodStartedAt(
      PERIOD_LENGTH,
      PERIOD_OFFSET
    );
    // timestamp == overwritePeriodStartTime doesn't matter, because the cumulative balance won't be impacted
    if (_timestamp > overwritePeriodStartTime) {
      revert TimestampNotFinalized(_timestamp, overwritePeriodStartTime);
    }
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "ring-buffer-lib/RingBufferLib.sol";

/**
 * @dev Sets max ring buffer length in the Account.observations Observation list.
 *         As users transfer/mint/burn tickets new Observation checkpoints are recorded.
 *         The current `MAX_CARDINALITY` guarantees a one year minimum, of accurate historical lookups.
 * @dev The user Account.Account.cardinality parameter can NOT exceed the max cardinality variable.
 *      Preventing "corrupted" ring buffer lookup pointers and new observation checkpoints.
 */
uint16 constant MAX_CARDINALITY = 17520; // with min period of 1 hour, this allows for minimum two years of history

/**
 * @title PoolTogether V5 Observation Library
 * @author PoolTogether Inc. & G9 Software Inc.
 * @notice This library allows one to store an array of timestamped values and efficiently search them.
 * @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
 */
library ObservationLib {
  /**
   * @notice Observation, which includes an amount and timestamp.
   * @param cumulativeBalance the cumulative time-weighted balance at `timestamp`.
   * @param balance `balance` at `timestamp`.
   * @param timestamp Recorded `timestamp`.
   */
  struct Observation {
    uint128 cumulativeBalance;
    uint96 balance;
    uint32 timestamp;
  }

  /**
   * @notice Fetches Observations `beforeOrAt` and `afterOrAt` a `_target`, eg: where [`beforeOrAt`, `afterOrAt`] is satisfied.
   * The result may be the same Observation, or adjacent Observations.
   * @dev The _target must fall within the boundaries of the provided _observations.
   * Meaning the _target must be: older than the most recent Observation and younger, or the same age as, the oldest Observation.
   * @dev  If `_newestObservationIndex` is less than `_oldestObservationIndex`, it means that we've wrapped around the circular buffer.
   *       So the most recent observation will be at `_oldestObservationIndex + _cardinality - 1`, at the beginning of the circular buffer.
   * @param _observations List of Observations to search through.
   * @param _newestObservationIndex Index of the newest Observation. Right side of the circular buffer.
   * @param _oldestObservationIndex Index of the oldest Observation. Left side of the circular buffer.
   * @param _target Timestamp at which we are searching the Observation.
   * @param _cardinality Cardinality of the circular buffer we are searching through.
   * @return beforeOrAt Observation recorded before, or at, the target.
   * @return beforeOrAtIndex Index of observation recorded before, or at, the target.
   * @return afterOrAt Observation recorded at, or after, the target.
   * @return afterOrAtIndex Index of observation recorded at, or after, the target.
   */
  function binarySearch(
    Observation[MAX_CARDINALITY] storage _observations,
    uint24 _newestObservationIndex,
    uint24 _oldestObservationIndex,
    uint32 _target,
    uint16 _cardinality
  )
    internal
    view
    returns (
      Observation memory beforeOrAt,
      uint16 beforeOrAtIndex,
      Observation memory afterOrAt,
      uint16 afterOrAtIndex
    )
  {
    uint256 leftSide = _oldestObservationIndex;
    uint256 rightSide = _newestObservationIndex < leftSide
      ? leftSide + _cardinality - 1
      : _newestObservationIndex;
    uint256 currentIndex;

    while (true) {
      // We start our search in the middle of the `leftSide` and `rightSide`.
      // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
      currentIndex = (leftSide + rightSide) / 2;

      beforeOrAtIndex = uint16(RingBufferLib.wrap(currentIndex, _cardinality));
      beforeOrAt = _observations[beforeOrAtIndex];
      uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

      afterOrAtIndex = uint16(RingBufferLib.nextIndex(currentIndex, _cardinality));
      afterOrAt = _observations[afterOrAtIndex];

      bool targetAfterOrAt = beforeOrAtTimestamp <= _target;

      // Check if we've found the corresponding Observation.
      if (targetAfterOrAt && _target <= afterOrAt.timestamp) {
        break;
      }

      // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
      if (!targetAfterOrAt) {
        rightSide = currentIndex - 1;
      } else {
        // Otherwise, we keep searching higher. To the right of the current index.
        leftSide = currentIndex + 1;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * NOTE: There is a difference in meaning between "cardinality" and "count":
 *  - cardinality is the physical size of the ring buffer (i.e. max elements).
 *  - count is the number of elements in the buffer, which may be less than cardinality.
 */
library RingBufferLib {
    /**
    * @notice Returns wrapped TWAB index.
    * @dev  In order to navigate the TWAB circular buffer, we need to use the modulo operator.
    * @dev  For example, if `_index` is equal to 32 and the TWAB circular buffer is of `_cardinality` 32,
    *       it will return 0 and will point to the first element of the array.
    * @param _index Index used to navigate through the TWAB circular buffer.
    * @param _cardinality TWAB buffer cardinality.
    * @return TWAB index.
    */
    function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
        return _index % _cardinality;
    }

    /**
    * @notice Computes the negative offset from the given index, wrapped by the cardinality.
    * @dev  We add `_cardinality` to `_index` to be able to offset even if `_amount` is superior to `_cardinality`.
    * @param _index The index from which to offset
    * @param _amount The number of indices to offset.  This is subtracted from the given index.
    * @param _count The number of elements in the ring buffer
    * @return Offsetted index.
     */
    function offset(
        uint256 _index,
        uint256 _amount,
        uint256 _count
    ) internal pure returns (uint256) {
        return wrap(_index + _count - _amount, _count);
    }

    /// @notice Returns the index of the last recorded TWAB
    /// @param _nextIndex The next available twab index.  This will be recorded to next.
    /// @param _count The count of the TWAB history.
    /// @return The index of the last recorded TWAB
    function newestIndex(uint256 _nextIndex, uint256 _count)
        internal
        pure
        returns (uint256)
    {
        if (_count == 0) {
            return 0;
        }

        return wrap(_nextIndex + _count - 1, _count);
    }

    function oldestIndex(uint256 _nextIndex, uint256 _count, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        if (_count < _cardinality) {
            return 0;
        } else {
            return wrap(_nextIndex + _cardinality, _cardinality);
        }
    }

    /// @notice Computes the ring buffer index that follows the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The next index relative to the given index.  Will wrap around to 0 if the next index == cardinality
    function nextIndex(uint256 _index, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        return wrap(_index + 1, _cardinality);
    }

    /// @notice Computes the ring buffer index that preceeds the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The prev index relative to the given index.  Will wrap around to the end if the prev index == 0
    function prevIndex(uint256 _index, uint256 _cardinality)
    internal
    pure
    returns (uint256) 
    {
        return _index == 0 ? _cardinality - 1 : _index - 1;
    }
}