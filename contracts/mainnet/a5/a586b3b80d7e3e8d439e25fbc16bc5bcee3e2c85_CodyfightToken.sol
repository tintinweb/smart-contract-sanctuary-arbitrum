/**
 *Submitted for verification at Arbiscan.io on 2024-04-23
*/

// Sources flattened with hardhat v2.19.4 https://hardhat.org

// SPDX-License-Identifier: MIT

// File lib/lossless/flattened/LERC20BurnableFlat.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.25;

/**
 * @title Context
 * @dev Context library from OpenZeppelin contracts.
 * @notice Context provides information about the transaction sender.
 */
abstract contract Context {
  /**
   * @dev Returns the transaction sender address.
   * @return sender_ The transaction sender address.
   */
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  /**
   * @dev Returns the transaction data.
   * @return data_ The transaction data.
   */
  function _msgData() internal view virtual returns (bytes calldata) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * @dev Interface of the LssController.
 * @notice LssController is a contract that implements the lossless feature. It is used to control the lossless feature of the LERC20Burnable contract.
 * @notice The LssController contract must implement the beforeTransfer, beforeTransferFrom, beforeApprove, beforeIncreaseAllowance, beforeDecreaseAllowance, and beforeBurn functions.
 * @notice The LssController contract must be set in the LERC20Burnable contract.
 */
interface ILssController {
  /**
   * @dev Function to be called before a transfer.
   * @param sender The sender address.
   * @param recipient The recipient address.
   * @param amount The transfer amount.
   */
  function beforeTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Function to be called before a transfer from.
   * @param msgSender The transaction sender address.
   * @param sender The sender address.
   * @param recipient The recipient address.
   * @param amount The transfer amount.
   */
  function beforeTransferFrom(
    address msgSender,
    address sender,
    address recipient,
    uint256 amount
  ) external;

  /**
   * @dev Function to be called before an approve.
   * @param sender The sender address.
   * @param spender The spender address.
   * @param amount The approve amount.
   */
  function beforeApprove(
    address sender,
    address spender,
    uint256 amount
  ) external;

  /**
   * @dev Function to be called before an increase allowance.
   * @param msgSender The transaction sender address.
   * @param spender The spender address.
   * @param addedValue The added allowance amount.
   */
  function beforeIncreaseAllowance(
    address msgSender,
    address spender,
    uint256 addedValue
  ) external;

  /**
   * @dev Function to be called before a decrease allowance.
   * @param msgSender The transaction sender address.
   * @param spender The spender address.
   * @param subtractedValue The subtracted allowance amount.
   */
  function beforeDecreaseAllowance(
    address msgSender,
    address spender,
    uint256 subtractedValue
  ) external;

  /**
   * @dev Function to be called before a burn.
   * @param account The account address.
   * @param amount The burn amount.
   */
  function beforeBurn(address account, uint256 amount) external;
}

/**
 * @title LERC20Burnable
 * @dev LERC20Burnable contract from Lossless.io. Extends the Context contract.
 * @notice LERC20Burnable is a contract that implements the ERC20 standard with burn and lossless features.
 * @notice The LERC20Burnable contract is based on the OpenZeppelin Context contract.
 */
contract LERC20Burnable is Context {
  // --- ERC20 variables ---

  /**
   * @dev Mapping of balances.
   * @notice _balances is a mapping of addresses to token balances.
   */
  mapping(address => uint256) private _balances;

  /**
   * @dev Mapping of allowances.
   * @notice _allowances is a mapping of addresses to mapping of addresses to allowance amounts.
   */
  mapping(address => mapping(address => uint256)) private _allowances;

  /**
   * @dev Total supply variable.
   * @notice _totalSupply is the total supply of the token.
   */
  uint256 private _totalSupply;

  /**
   * @dev Name variable.
   * @notice _name is the name of the token.
   */
  string private _name;

  /**
   * @dev Symbol variable.
   * @notice _symbol is the symbol of the token.
   */
  string private _symbol;

  // --- Lossless variables ---

  /**
   * @dev Recovery admin variable.
   * @notice recoveryAdmin is the address of the recovery admin, who can change the admin and turn off the lossless feature.
   */
  address public recoveryAdmin;

  /**
   * @dev Recovery admin candidate variable.
   * @notice recoveryAdminCandidate is the address of the recovery admin candidate, who can accept the recovery admin ownership.
   */
  address private recoveryAdminCandidate;

  /**
   * @dev Recovery admin key hash variable.
   * @notice recoveryAdminKeyHash is the hash of the recovery admin key, which is used to accept the recovery admin ownership.
   */
  bytes32 private recoveryAdminKeyHash;

  /**
   * @dev Admin variable.
   * @notice admin is the address of the admin, who will hold the minted tokens and have governance rights.
   */
  address public admin;

  /**
   * @dev Timelock period variable.
   * @notice timelockPeriod is the period in seconds that the recovery admin must wait to turn off the lossless feature.
   */
  uint256 public timelockPeriod;

  /**
   * @dev Lossless turn off timestamp variable.
   * @notice losslessTurnOffTimestamp is the timestamp when the lossless feature will be turned off.
   */
  uint256 public losslessTurnOffTimestamp;

  /**
   * @dev Lossless on variable.
   * @notice isLosslessOn is a boolean that indicates if the lossless feature is on.
   */
  bool public isLosslessOn = true;

  /**
   * @dev Lossless controller variable.
   * @notice lossless is the address of the LssController contract, which implements the lossless feature.
   */
  ILssController public lossless;

  /**
   * @dev Constructor function.
   * @notice Constructor sets the initial values of the contract. It mints the total supply to the admin address.
   * @param totalSupply_ The total supply of the token.
   * @param name_ The name of the token.
   * @param symbol_ The symbol of the token.
   * @param admin_ The address of the admin.
   * @param recoveryAdmin_ The address of the recovery admin.
   * @param timelockPeriod_ The timelock period in seconds.
   * @param lossless_ The address of the LssController contract.
   */
  constructor(
    uint256 totalSupply_,
    string memory name_,
    string memory symbol_,
    address admin_,
    address recoveryAdmin_,
    uint256 timelockPeriod_,
    address lossless_
  ) {
    require(
      lossless_ != address(0),
      'LERC20: Lossless controller cannot be zero address'
    );

    _mint(admin_, totalSupply_);
    _name = name_;
    _symbol = symbol_;
    admin = admin_;
    recoveryAdmin = recoveryAdmin_;
    recoveryAdminCandidate = address(0);
    recoveryAdminKeyHash = '';
    timelockPeriod = timelockPeriod_;
    losslessTurnOffTimestamp = 0;
    lossless = ILssController(lossless_);
  }

  // --- Events ---

  /**
   * @dev Transfer event.
   * @param _from The sender address.
   * @param _to The recipient address.
   * @param _value The transfer amount.
   */
  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  /**
   * @dev Approval event.
   * @param _owner The owner address.
   * @param _spender The spender address.
   * @param _value The approve amount.
   */
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  /**
   * @dev New admin event.
   * @param _newAdmin The new admin address.
   */
  event NewAdmin(address indexed _newAdmin);

  /**
   * @dev New recovery admin proposal event.
   * @param _candidate The candidate address.
   */
  event NewRecoveryAdminProposal(address indexed _candidate);

  /**
   * @dev New recovery admin event.
   * @param _newAdmin The new recovery admin address.
   */
  event NewRecoveryAdmin(address indexed _newAdmin);

  /**
   * @dev Lossless turn off proposal event.
   * @param _turnOffDate The turn off date timestamp.
   */
  event LosslessTurnOffProposal(uint256 _turnOffDate);

  /**
   * @dev Lossless off event.
   */
  event LosslessOff();

  /**
   * @dev Lossless on event.
   */
  event LosslessOn();

  // --- LOSSLESS modifiers ---

  /**
   * @dev Lossless approve modifier.
   * @notice The lssAprove modifier calls the beforeApprove function of the lossless contract.
   * @param spender The spender address.
   * @param amount The approve amount.
   */
  modifier lssAprove(address spender, uint256 amount) {
    if (isLosslessOn) {
      lossless.beforeApprove(_msgSender(), spender, amount);
    }
    _;
  }

  /**
   * @dev Lossless transfer modifier.
   * @notice The lssTransfer modifier calls the beforeTransfer function of the lossless contract.
   * @param recipient The recipient address.
   * @param amount The transfer amount.
   */
  modifier lssTransfer(address recipient, uint256 amount) {
    if (isLosslessOn) {
      lossless.beforeTransfer(_msgSender(), recipient, amount);
    }
    _;
  }

  /**
   * @dev Lossless transfer from modifier.
   * @notice The lssTransferFrom modifier calls the beforeTransferFrom function of the lossless contract.
   * @param sender The sender address.
   * @param recipient The recipient address.
   * @param amount The transfer amount.
   */
  modifier lssTransferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) {
    if (isLosslessOn) {
      lossless.beforeTransferFrom(_msgSender(), sender, recipient, amount);
    }
    _;
  }

  /**
   * @dev Lossless burn modifier.
   * @notice The lssBurn modifier calls the beforeBurn function of the lossless contract.
   * @param account The account address.
   * @param amount The burn amount.
   */
  modifier lssBurn(address account, uint256 amount) {
    if (isLosslessOn) {
      lossless.beforeBurn(account, amount);
    }
    _;
  }

  /**
   * @dev Lossless increase allowance modifier.
   * @notice The lssIncreaseAllowance modifier calls the beforeIncreaseAllowance function of the lossless contract.
   * @param spender The spender address.
   * @param addedValue The added allowance amount.
   */
  modifier lssIncreaseAllowance(address spender, uint256 addedValue) {
    if (isLosslessOn) {
      lossless.beforeIncreaseAllowance(_msgSender(), spender, addedValue);
    }
    _;
  }

  /**
   * @dev Lossless decrease allowance modifier.
   * @notice The lssDecreaseAllowance modifier calls the beforeDecreaseAllowance function of the lossless contract.
   * @param spender The spender address.
   * @param subtractedValue The subtracted allowance amount.
   */
  modifier lssDecreaseAllowance(address spender, uint256 subtractedValue) {
    if (isLosslessOn) {
      lossless.beforeDecreaseAllowance(_msgSender(), spender, subtractedValue);
    }
    _;
  }

  /**
   * @dev Recovery admin modifier.
   * @notice The onlyRecoveryAdmin modifier restricts access to the recovery admin.
   */
  modifier onlyRecoveryAdmin() {
    require(_msgSender() == recoveryAdmin, 'LERC20: Must be recovery admin');
    _;
  }

  // --- LOSSLESS management ---

  /**
   * @dev Function to transfer out blacklisted funds.
   * @notice This function allows the lossless contract to transfer out blacklisted funds.
   * @param from The array of addresses from which the funds will be transferred.
   */
  function transferOutBlacklistedFunds(address[] calldata from) external {
    require(
      _msgSender() == address(lossless),
      'LERC20: Only lossless contract'
    );
    require(isLosslessOn, 'LERC20: Lossless is off');

    uint256 fromLength = from.length;
    uint256 totalAmount = 0;

    for (uint256 i = 0; i < fromLength; i++) {
      address fromAddress = from[i];
      uint256 fromBalance = _balances[fromAddress];
      _balances[fromAddress] = 0;
      totalAmount += fromBalance;
      emit Transfer(fromAddress, address(lossless), fromBalance);
    }

    _balances[address(lossless)] += totalAmount;
  }

  /**
   * @dev Function to set new admin.
   * @notice This function allows the recovery admin to set a new admin.
   * @param newAdmin The new admin address.
   */
  function setLosslessAdmin(address newAdmin) external onlyRecoveryAdmin {
    require(newAdmin != admin, 'LERC20: Cannot set same address');
    emit NewAdmin(newAdmin);
    admin = newAdmin;
  }

  /**
   * @dev Function to transfer recovery admin ownership.
   * @notice This function allows the recovery admin to transfer the recovery admin ownership to a candidate address.
   * @param candidate The candidate address.
   * @param keyHash The key hash.
   */
  function transferRecoveryAdminOwnership(
    address candidate,
    bytes32 keyHash
  ) external onlyRecoveryAdmin {
    recoveryAdminCandidate = candidate;
    recoveryAdminKeyHash = keyHash;
    emit NewRecoveryAdminProposal(candidate);
  }

  /**
   * @dev Function to accept recovery admin ownership.
   * @notice This function allows the candidate address to accept the recovery admin ownership.
   * @param key The key.
   */
  function acceptRecoveryAdminOwnership(bytes memory key) external {
    require(
      _msgSender() == recoveryAdminCandidate,
      'LERC20: Must be canditate'
    );
    require(keccak256(key) == recoveryAdminKeyHash, 'LERC20: Invalid key');
    emit NewRecoveryAdmin(recoveryAdminCandidate);
    recoveryAdmin = recoveryAdminCandidate;
    recoveryAdminCandidate = address(0);
  }

  /**
   * @dev Function to propose lossless turn off.
   * @notice This function allows the recovery admin to propose to turn off the lossless features.
   */
  function proposeLosslessTurnOff() external onlyRecoveryAdmin {
    require(losslessTurnOffTimestamp == 0, 'LERC20: TurnOff already proposed');
    require(isLosslessOn, 'LERC20: Lossless already off');
    losslessTurnOffTimestamp = block.timestamp + timelockPeriod;
    emit LosslessTurnOffProposal(losslessTurnOffTimestamp);
  }

  /**
   * @dev Function to execute lossless turn off.
   * @notice This function allows the recovery admin to execute the lossless turn off, when the timelock period has passed.
   */
  function executeLosslessTurnOff() external onlyRecoveryAdmin {
    require(losslessTurnOffTimestamp != 0, 'LERC20: TurnOff not proposed');
    require(
      losslessTurnOffTimestamp <= block.timestamp,
      'LERC20: Time lock in progress'
    );
    isLosslessOn = false;
    losslessTurnOffTimestamp = 0;
    emit LosslessOff();
  }

  /**
   * @dev Function to execute lossless turn on.
   * @notice This function allows the recovery admin to execute the lossless turn on.
   */
  function executeLosslessTurnOn() external onlyRecoveryAdmin {
    require(!isLosslessOn, 'LERC20: Lossless already on');
    losslessTurnOffTimestamp = 0;
    isLosslessOn = true;
    emit LosslessOn();
  }

  /**
   * @dev Function to get the admin address.
   * @return The admin address.
   */
  function getAdmin() public view virtual returns (address) {
    return admin;
  }

  // --- ERC20 methods ---

  /**
   * @dev Function to get the name of the token.
   * @return The name of the token.
   */
  function name() public view virtual returns (string memory) {
    return _name;
  }

  /**
   * @dev Function to get the symbol of the token.
   * @return The symbol of the token.
   */
  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Function to get the decimals of the token.
   * @return The decimals of the token.
   */
  function decimals() public view virtual returns (uint8) {
    return 18;
  }

  /**
   * @dev Function to get the total supply of the token.
   * @return The total supply of the token.
   */
  function totalSupply() public view virtual returns (uint256) {
    return _totalSupply;
  }

  /**
   * @dev Function to get the balance of an account.
   * @param account The account address.
   * @return The balance of the account.
   */
  function balanceOf(address account) public view virtual returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Function to transfer tokens. Uses the lssTransfer modifier to call the beforeTransfer function of the lossless contract.
   * @param recipient The recipient address.
   * @param amount The transfer amount.
   * @return A boolean that indicates if the operation was successful.
   */
  function transfer(
    address recipient,
    uint256 amount
  ) public virtual lssTransfer(recipient, amount) returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  /**
   * @dev Function to get the allowance of a spender on an owner's tokens.
   * @param owner The owner address.
   * @param spender The spender address.
   * @return The allowance of the spender on the owner's tokens.
   */
  function allowance(
    address owner,
    address spender
  ) public view virtual returns (uint256) {
    return _allowances[owner][spender];
  }

  /**
   * @dev Function to approve a spender to spend an amount of tokens. Uses the lssAprove modifier to call the beforeApprove function of the lossless contract.
   * @param spender The spender address.
   * @param amount The approve amount.
   * @return A boolean that indicates if the operation was successful.
   */
  function approve(
    address spender,
    uint256 amount
  ) public virtual lssAprove(spender, amount) returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  /**
   * @dev Function to transfer tokens from an owner to a recipient. Uses the lssTransferFrom modifier to call the beforeTransferFrom function of the lossless contract.
   * @param sender The sender address.
   * @param recipient The recipient address.
   * @param amount The transfer amount.
   * @return A boolean that indicates if the operation was successful.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual lssTransferFrom(sender, recipient, amount) returns (bool) {
    uint256 currentAllowance = _allowances[sender][_msgSender()];
    require(
      currentAllowance >= amount,
      'LERC20: transfer amount exceeds allowance'
    );
    _transfer(sender, recipient, amount);

    _approve(sender, _msgSender(), currentAllowance - amount);

    return true;
  }

  /**
   * @dev Function to increase the allowance of a spender. Uses the lssIncreaseAllowance modifier to call the beforeIncreaseAllowance function of the lossless contract.
   * @param spender The spender address.
   * @param addedValue The added allowance amount.
   * @return A boolean that indicates if the operation was successful.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  ) public virtual lssIncreaseAllowance(spender, addedValue) returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender] + addedValue
    );
    return true;
  }

  /**
   * @dev Function to decrease the allowance of a spender. Uses the lssDecreaseAllowance modifier to call the beforeDecreaseAllowance function of the lossless contract.
   * @param spender The spender address.
   * @param subtractedValue The subtracted allowance amount.
   * @return A boolean that indicates if the operation was successful.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    virtual
    lssDecreaseAllowance(spender, subtractedValue)
    returns (bool)
  {
    uint256 currentAllowance = _allowances[_msgSender()][spender];
    require(
      currentAllowance >= subtractedValue,
      'LERC20: decreased allowance below zero'
    );
    _approve(_msgSender(), spender, currentAllowance - subtractedValue);

    return true;
  }

  // --- Internal functions ---

  /**
   * @dev Internal function to transfer tokens. Overrides the _transfer function of the Context contract to enforce specific conditions.
   * @param sender The sender address.
   * @param recipient The recipient address.
   * @param amount The transfer amount.
   */
  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), 'LERC20: transfer from the zero address');

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, 'LERC20: transfer amount exceeds balance');
    _balances[sender] = senderBalance - amount;
    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  /**
   * @dev Internal function to mint tokens. Overrides the _mint function of the Context contract to enforce specific conditions.
   * @notice Mint function is only executed at contract deployment. No mint function is available after deployment.
   * @param account The account address.
   * @param amount The mint amount.
   */
  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'LERC20: mint to the zero address');

    _totalSupply += amount;

    // Cannot overflow because the sum of all user
    // balances can't exceed the max uint256 value.
    unchecked {
      _balances[account] += amount;
    }
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function to burn tokens. Overrides the _burn function of the Context contract to enforce specific conditions.
   * @param account The account address.
   * @param amount The burn amount.
   */
  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    uint256 accountBalance = _balances[account];
    require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
    unchecked {
      _balances[account] = accountBalance - amount;
    }
    _totalSupply -= amount;

    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Internal function to approve a spender to spend an amount of tokens.
   * @param owner The owner address.
   * @param spender The spender address.
   * @param amount The approve amount.
   */
  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  // --- ERC20Burnable methods ---

  /**
   * @dev Function to burn tokens. Uses the lssBurn modifier to call the beforeBurn function of the lossless contract.
   * @notice Burn function may not be allowed if the lossless feature is on, Lossless controller may block the burn.
   * @param amount The burn amount.
   */
  function burn(uint256 amount) public virtual lssBurn(_msgSender(), amount) {
    _burn(_msgSender(), amount);
  }

  /**
   * @dev Function to burn tokens from an account. Uses the lssBurn modifier to call the beforeBurn function of the lossless contract.
   * @notice Burn function may not be allowed if the lossless feature is on, Lossless controller may block the burn.
   * @param account The account address.
   * @param amount The burn amount.
   */
  function burnFrom(
    address account,
    uint256 amount
  ) public virtual lssBurn(account, amount) {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, 'ERC20: burn amount exceeds allowance');
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }
}

// File contracts/CTOK.sol

// Original license: SPDX_License_Identifier: MIT

/**
 * @title CodyfightToken - CTOK contract.
 * @dev CodyfightToken fully inherits the LERC20Burnable contract, which implements the ERC20 standard with burn and lossless features.
 * @notice CodyfightToken is the official token of Codyfight. Tokens are only minted at contract deployment. No mint function is available after deployment. Tokens can be burned.
 */
contract CodyfightToken is LERC20Burnable {
  /**
   * @dev Constructor function.
   * @notice Constructor sets the initial values of the contract. It mints the total supply to the admin address.
   * @param totalSupply_ The total supply of the token.
   * @param name_ The name of the token.
   * @param symbol_ The symbol of the token.
   * @param admin_ The address of the admin.
   * @param recoveryAdmin_ The address of the recovery admin.
   * @param timelockPeriod_ The timelock period in seconds.
   * @param lossless_ The address of the LssController contract.
   */
  constructor(
    uint256 totalSupply_,
    string memory name_,
    string memory symbol_,
    address admin_,
    address recoveryAdmin_,
    uint256 timelockPeriod_,
    address lossless_
  )
    LERC20Burnable(
      totalSupply_,
      name_,
      symbol_,
      admin_,
      recoveryAdmin_,
      timelockPeriod_,
      lossless_
    )
  {}
}