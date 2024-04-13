/**
 *Submitted for verification at Arbiscan.io on 2024-04-10
*/

// File: @openzeppelin\[email protected]\utils\Context.sol

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

// File: @openzeppelin\[email protected]\access\Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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

// File: @openzeppelin\[email protected]\utils\Pausable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Pausable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    bool private _paused;

    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    /**
     * @dev The operation failed because the contract is paused.
     */
    error EnforcedPause();

    /**
     * @dev The operation failed because the contract is not paused.
     */
    error ExpectedPause();

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        if (paused()) {
            revert EnforcedPause();
        }
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        if (!paused()) {
            revert ExpectedPause();
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin\[email protected]\utils\ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: contracts\SupplyChainCertify.sol

pragma solidity ^0.8.20;
contract SupplyChainCertify is Ownable, Pausable, ReentrancyGuard {

  bytes1 private constant NOT_APPROVED = 0x00;
  bytes1 private constant APPROVED = 0xFF;
  uint256 private disablingThresholdWei = 1000000000000000; // 10^15 WEI = 0.001 ETH
  uint256 private warningThresholdWei = 1000000000000000000; // 10^18 WEI = 1 ETH
  uint16 private counterThreshold = 1000;

  struct User {
    bytes1 approved; // default: 0x00
    bool suspended;
    bool enabled;
    uint256 balance;
  }

  address private manager;
  uint16 private operationCounter;
  uint256 private operationAccumulatedFunds;
  mapping(address => User) private users;
  address[] private userAddresses;
  string private groupHash;

  //====================  EVENTS  ====================

  /**
   * @notice Event for logging user status.
   * @param user Address of the user who notify user suspended status. Indexed.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param suspended True if user is suspended, False is not suspended.
   */
  event UserSuspendedStatus(address indexed user, uint256 indexed chainId, bool suspended);

  /**
   * @notice Event for logging user status.
   * @param user Address of the user who notify user enabled status. Indexed.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param enabled True if user is enabled, False is disabled.
   */
  event UserEnabledStatus(address indexed user, uint256 indexed chainId, bool enabled);

  /**
   * @notice Event for logging master deposits into the contract.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The amount of Ether (in wei) deposited by the owner.
   */
  event MasterDeposit(uint256 indexed chainId, uint256 value);

  /**
   * @notice Event for logging master withdraw from the contract.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The amount of Ether (in wei) withdrawed by the owner.
   */
  event MasterWithdraw(uint256 indexed chainId, uint256 value);

  /**
   * @notice Event for logging deposits into the contract.
   * @param user Address of the user who made the deposit. Indexed.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The amount of Ether (in wei) deposited by the user.
   */
  event Deposit(address indexed user, uint256 indexed chainId, uint256 value);

  /**
   * @notice Event for logging withdrawals from the contract.
   * @param user Address of the user who made the withdrawal. Indexed.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The amount of Ether (in wei) withdrawal by the user.
   */
  event Withdraw(address indexed user, uint256 indexed chainId, uint256 value);

  /**
   * @notice Event for logging certification paid by user.
   * @param user Address of the user who paid for certification. Indexed.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The amount of Ether (in wei) paid by the user.
   */
  event CertificationPaid(address indexed user, uint256 indexed chainId, uint256 value);

  /**
   * @notice Event for logging paid between users.
   * @param from Address of the user who made the payment. Indexed.
   * @param to Address of the user who receive the payment. Indexed.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The amount of Ether (in wei) the payment.
   */
  event UserPaid(address indexed from, address indexed to, uint256 indexed chainId, uint256 value);

  /**
   * @notice Event for logging low level funding by manager.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The remaining amount of Ether (in wei) of the user.
   */
  event ManagerLowLevelFunding(uint256 indexed chainId, uint256 value);
  
  /**
   * @notice Event for logging low level funding by user.
   * @param user Address of the user who have low level funding on contract. Indexed.
   * @param chainId Hexadecimal id of the blockchain on which the event was generated. Indexed.
   * @param value The remaining amount of Ether (in wei) of the user.
   */
  event LowLevelFunding(address indexed user, uint256 indexed chainId, uint256 value);

  //====================  CONSTRUCTOR  ====================
 
  /**
   * @notice Empty
   */
  constructor() Ownable(msg.sender) {} 

  //====================  OVERRIDE FUNCTIONS FROM INHERITANCE  ====================
  
  /**
    * @notice Override funtion to make it impossible renounce to the ownrship.
    */
  function renounceOwnership() public override onlyOwner {
    revert("It's not possible renounce to the ownership!");
  }

  /**
    * @notice Override funtion to add onlyOwner modifier, and make the function no longer overwritable in any child contracts.
    */
  function pause() external whenNotPaused onlyOwner nonReentrant {
    super._pause();
  }

  /**
    * @notice Override funtion to add onlyOwner modifier, and make the function no longer overwritable in any child contracts.
    */
  function unpause() external whenPaused onlyOwner nonReentrant {
    super._unpause();
  }

  //====================  FUNCTIONS  ====================

  /**
   * @notice Sets manager of smart contract.
   * @param _manager The new value for the operation counter threshold.
   */
  function setManger(address _manager) external whenNotPaused onlyOwner nonReentrant {
    manager = _manager;
  }

  /**
   * @notice Retrieves manager of smart contract.
   */
  function getManager() external view onlyOwner returns(address) {
    return manager;
  }

  /**
   * @notice Sets the disablingThresholdWei.
   * @param _disablingThresholdWei The new value for the disablingThresholdWei.
   */
  function setDisablingThresholdWei(uint256 _disablingThresholdWei) external whenNotPaused onlyManager nonReentrant {
    disablingThresholdWei = _disablingThresholdWei;
  }

  /**
   * @notice Retrieves the current disablingThresholdWei.
   */
  function getDisablingThresholdWei() external view onlyManager returns(uint256) {
    return disablingThresholdWei;
  }

  /**
   * @notice Sets the warningThresholdWei.
   * @param _warningThresholdWei The new value for the warningThresholdWei.
   */
  function setWarningThresholdWei(uint256 _warningThresholdWei) external whenNotPaused onlyManager nonReentrant {
    warningThresholdWei = _warningThresholdWei;
  }

  /**
   * @notice Retrieves the current warningThresholdWei.
   */
  function getWarningThresholdWei() external view onlyManager returns(uint256) {
    return warningThresholdWei;
  }

  /**
   * @notice Sets the threshold for the operation counter.
   * @param _counterThreshold The new value for the operation counter threshold.
   */
  function setCounterThreshold(uint16 _counterThreshold) external whenNotPaused onlyManager nonReentrant {
    counterThreshold = _counterThreshold;
  }

  /**
   * @notice Retrieves the current threshold for the operation counter.
   */
  function getCounterThreshold() external view onlyManager returns(uint16) {
    return counterThreshold;
  }

  /**
   * @notice Adds a new user to the list of approved users if not already approved.
   * @param _newUser The address of the new user to be added.
   */
  function addUser(address _newUser) external whenNotPaused onlyManager notZeroAddress(_newUser) nonReentrant {
    require(users[_newUser].approved == NOT_APPROVED, "This user has already been approved!");
    users[_newUser].approved = APPROVED;
    userAddresses.push(_newUser);
  }

  /**
   * @notice Retrieve all user approved for this smart contract.
   * @return toRet Approved users array.
   */
  function getUsers() external view whenNotPaused onlyManager returns(User[] memory) {
    User[] memory toRet = new User[](userAddresses.length);
    for (uint i; i<userAddresses.length; i++) {
        toRet[i] = users[userAddresses[i]];
    }
    return toRet;
  }

  /// SISTEMA DI SICUREZZA SUPPLEMENTARE!!!
  /**
   * @notice Changes the suspended state of an approved user.
   * @param _user The address of the user whose suspended state is to be changed.
   * @param _suspended The new state to set for the user (true for suspended, false for not supended).
   */
  function setUserSuspendedState(address _user, bool _suspended) external whenNotPaused onlyManager approvedAddress(_user) nonReentrant {
      require(users[_user].suspended != _suspended, "The user is already in the desired suspended state.");
      users[_user].suspended = _suspended;
      emit UserSuspendedStatus(_user, block.chainid, _suspended);
  }

  /**
   * @notice Changes the enabled state of an approved user.
   * @param _user The address of the user whose enabled state is to be changed.
   * @param _enabled The new state to set for the user (true for enabled, false for disabled).
   */
  function setUserEnabledState(address _user, bool _enabled) private {
      require(users[_user].enabled != _enabled, "The user is already in the desired enabled state.");
      users[_user].enabled = _enabled;
      emit UserEnabledStatus(_user, block.chainid, _enabled);
  }

  /**
   * @notice Checks the balance of a specified user and updates their enabled state based on defined thresholds. Emits events for low balance warnings or changes in user status.
   * @param _user The address of the user whose balance and status are to be checked.
   */
  function checkBalanceAndEmitEvents(address _user) private {
    if(users[_user].enabled) {
      if(users[_user].balance < disablingThresholdWei) {
        setUserEnabledState(_user, false);
      } else if(users[_user].balance < warningThresholdWei) {
        emit LowLevelFunding(_user, block.chainid, users[_user].balance);
      } 
    } else {
      if(users[_user].balance > disablingThresholdWei) {
        setUserEnabledState(_user, true);
      }
    }
  }

  /**
   * @notice Allows an approved and not suspended user to deposit ETH into smart contract account.
   */
  function userDeposit() external payable whenNotPaused onlyApprovedAndNotSuspended nonReentrant {
    users[_msgSender()].balance += msg.value;
    emit Deposit(_msgSender(), block.chainid, msg.value);
    checkBalanceAndEmitEvents(_msgSender());
  }

  /**
   * @notice Enables an approved and not suspended user to withdraw ETH from smart contract account.
   * @param _amount The amount of ETH to withdraw.
   */
  function userWithdraw(uint256 _amount) external whenNotPaused onlyApprovedAndNotSuspended nonReentrant {
    require(users[_msgSender()].balance >= _amount, "Insufficient funds for withdraw!");
    users[_msgSender()].balance -= _amount;
    emit Withdraw(_msgSender(), block.chainid, _amount);
    checkBalanceAndEmitEvents(_msgSender());
    payable(_msgSender()).transfer(_amount);
  }

  /**
   * @notice Checks if the operation counter exceeds the threshold and performs necessary actions.
   * @param _gasEstimation The gas estimation for the operation being checked.
   */
  function checkOperationThreshold(uint256 _gasEstimation) private {
    operationCounter++;
    operationAccumulatedFunds += _gasEstimation;
    if(operationCounter >= counterThreshold) {
      uint256 accumulatedFunds = operationAccumulatedFunds;
      operationCounter = 0;
      operationAccumulatedFunds = 0;
      payable(manager).transfer(accumulatedFunds);
    }
    if(manager.balance < warningThresholdWei) {
      emit ManagerLowLevelFunding(block.chainid, manager.balance);
    }
  }

  /// DEVO FORNIRE UNA STIMA DEL GAS (maggiorala del 5%)!!!
  /**
   * @notice Allows the manager to deduct a specified amount for certification from an approved user's account.
   * @param _from The user from whom the certification fee will be deducted.
   * @param _gasEstimation The amount to be deducted for certification.
   * @param _groupHash The new group hash to be set.
   */
  function payCertification(address _from, uint256 _gasEstimation, string memory _groupHash) external whenNotPaused onlyManager approvedAddress(_from) enabledAddress(_from) nonReentrant {
    if(users[_from].balance < _gasEstimation) {
      setUserEnabledState(_from, false);
    } else {
      users[_from].balance -= _gasEstimation;
      emit CertificationPaid(_from, block.chainid, _gasEstimation);
      setGroupHash(_groupHash);
      checkOperationThreshold(_gasEstimation);
    }
  }

  /// DEVO FORNIRE UNA STIMA DEL GAS (maggiorala del 5%)!!!
  /**
   * @notice Transfers funds from one approved user to another.
   * @param _from The address of the user sending funds.
   * @param _to The address of the recipient user.
   * @param _amount The amount of funds to transfer.
   * @param _gasEstimation The amount to be deducted for payment.
   */
  function payUser(address _from, address _to, uint _amount, uint256 _gasEstimation) external whenNotPaused onlyManager approvedAddress(_from) enabledAddress(_from) approvedAddress(_to) nonReentrant {
    require(_from != _to, "The recipient cannot be the same as the sender!");
    if(users[_from].balance < _gasEstimation) {
      setUserEnabledState(_from, false);
    } else {
      if(users[_from].balance < (_amount + _gasEstimation)) {
        checkBalanceAndEmitEvents(_from);
      } else {
        users[_from].balance -= _amount;
        users[_to].balance += _amount;
        checkBalanceAndEmitEvents(_to);
        emit UserPaid(_from, _to, block.chainid, _amount);
      }
      users[_from].balance -= _gasEstimation;
      checkOperationThreshold(_gasEstimation);
    }
  }

  /**
    * @notice Check your balance as an approved user.
    */
  function checkMyBalance() external view approvedAddress(_msgSender()) returns(uint256) {
    return users[_msgSender()].balance;
  }

  /**
    * @notice Checks the balance of a specified approved user. This function is restricted to the contract manager.
    * @param _user The address of the user whose balance is to be checked.
    * @return _userBalance The balance of the specified user.
    */
  function checkBalanceUser(address _user) external view onlyManager approvedAddress(_user) returns(uint256) {
    return users[_user].balance;
  }

  /**
    * @notice Checks the balance of smart contract. This function is restricted to the contract manager.
    * @return _balance The balance of the smart contract.
    */
  function checkBalance() external view onlyManager returns(uint256) {
    return address(this).balance;
  }

  /**
   * @notice Handles direct ETH deposits to the contract by the owner.
   */
  receive() external payable whenNotPaused onlyOwner nonReentrant {
    emit MasterDeposit(block.chainid, msg.value);
  }

  /**
   * WARNING: CAN REMOVE ALL FUNDS FROM SMART CONTRACT!!!
   *
   * @notice It manages the direct withdrawal of any amount from the funds from the smart contract.
   * @param _amount The amount of funds to transfer.
   */
  function withdraw(uint _amount) external whenNotPaused onlyOwner nonReentrant {
    require(_amount <= address(this).balance, "The amount of funds to be withdrawn exceeds the balance!");
    emit MasterWithdraw(block.chainid, _amount);
    payable(owner()).transfer(_amount);
  }

  /**
   * @notice It manages the direct withdrawal of any amount of funds present on the smart contract that belong to the owner of the same.
   */
  function withdrawOnlyOwnerFunds() external whenNotPaused onlyOwner nonReentrant {
    uint256 usersFunds;
    for (uint i; i<userAddresses.length; i++) {
      usersFunds += users[userAddresses[i]].balance;
    }
    require(address(this).balance >= usersFunds, "The amount of funds to be withdrawn exceeds the balance!");
    uint256 amount = address(this).balance - usersFunds;
    emit MasterWithdraw(block.chainid, amount);
    payable(owner()).transfer(amount);
  }

  /**
   * @notice Sets a new group hash for the contract.
   * @param _groupHash The new group hash to be set.
   */
  //function setGroupHash(string memory _groupHash) external onlyOwner {
  function setGroupHash(string memory _groupHash) private {
    groupHash = _groupHash;
  }

  /**
   * @notice Returns the current group hash of the contract. Can only be called by the current manager.
   */
  function getGroupHash() external view onlyManager returns(string memory) {
    return groupHash;
  }

  //====================  MODIFIERS  ====================

  /**
   * @notice Modifier that restricts the execution of functions to only the manager of the contract.
   */
  modifier onlyManager() {
    require(manager != address(0), "Must to set up the manager to perform this operation!");
    require(_msgSender() == manager, "Only manager can execute this function!");
    _;
  }

  /**
   * @notice Modifier that checks if an address is not the zero address.
   * @param _newOwner The address to be checked.
   */
  modifier notZeroAddress(address _newOwner) {
    require(_newOwner != address(0), "New address cannot be the zero address!");
    _;
  }

  /**
   * @notice Restricts function execution to users who are approved.
   */
  modifier onlyApprovedAndNotSuspended() {
    require(users[_msgSender()].approved == APPROVED, "Only approved users can managing their funds!");
    require(!users[_msgSender()].suspended, "Only not suspended users can managing their funds!");
    _;
  }

  /**
   * @notice Verifies that an address has been approved to interact with restricted functions.
   * @param _user Address of the user to check for approval.
   */
  modifier approvedAddress(address _user) {
    require(users[_user].approved == APPROVED, "Address must to be an approved user!");
    _;
  }

  /**
   * @notice Verifies that an address has been enabled to interact with restricted functions.
   * @param _user Address of the user to check for enabled.
   */
  modifier enabledAddress(address _user) {
    require(users[_user].enabled, "Address must to be an enabled user!");
    _;
  }

}