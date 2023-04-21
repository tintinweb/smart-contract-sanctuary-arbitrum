/**
 *Submitted for verification at Arbiscan on 2023-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath: subtraction overflow');
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, 'SafeMath: division by zero');
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, 'SafeMath: modulo by zero');
    return a % b;
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

contract ERC20 is Context, IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;

  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply;

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name_, string memory symbol_) public {
    _name = name_;
    _symbol = symbol_;
    _decimals = 18;
  }

  function name() public view virtual returns (string memory) {
    return _name;
  }

  function symbol() public view virtual returns (string memory) {
    return _symbol;
  }

  function decimals() public view virtual returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view virtual override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
    return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, 'ERC20: decreased allowance below zero')
    );
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal virtual {
    require(sender != address(0), 'ERC20: transfer from the zero address');
    require(recipient != address(0), 'ERC20: transfer to the zero address');

    _beforeTokenTransfer(sender, recipient, amount);

    _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _mint(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: mint to the zero address');

    _beforeTokenTransfer(address(0), account, amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal virtual {
    require(account != address(0), 'ERC20: burn from the zero address');

    _beforeTokenTransfer(account, address(0), amount);

    _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal virtual {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _setupDecimals(uint8 decimals_) internal virtual {
    _decimals = decimals_;
  }

  function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract ERC20Burnable is Context, ERC20 {
  using SafeMath for uint256;

  function burn(uint256 amount) public virtual {
    _burn(_msgSender(), amount);
  }

  function burnFrom(address account, uint256 amount) public virtual {
    uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, 'ERC20: burn amount exceeds allowance');

    _approve(account, _msgSender(), decreasedAllowance);
    _burn(account, amount);
  }
}

library Math {
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function average(uint256 a, uint256 b) internal pure returns (uint256) {
    // (a + b) / 2 can overflow, so we distribute
    return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
  }
}

library SafeMath8 {
  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
    require(b <= a, errorMessage);
    uint8 c = a - b;

    return c;
  }

  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    if (a == 0) {
      return 0;
    }

    uint8 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
    require(b > 0, errorMessage);
    uint8 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint8 a, uint8 b) internal pure returns (uint8) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(uint8 a, uint8 b, string memory errorMessage) internal pure returns (uint8) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Operator is Context, Ownable {
  address private _operator;

  event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

  constructor() internal {
    _operator = _msgSender();
    emit OperatorTransferred(address(0), _operator);
  }

  function operator() public view returns (address) {
    return _operator;
  }

  modifier onlyOperator() {
    require(_operator == msg.sender, 'operator: caller is not the operator');
    _;
  }

  function isOperator() public view returns (bool) {
    return _msgSender() == _operator;
  }

  function transferOperator(address newOperator_) public onlyOwner {
    _transferOperator(newOperator_);
  }

  function _transferOperator(address newOperator_) internal {
    require(newOperator_ != address(0), 'operator: zero address given for new operator');
    emit OperatorTransferred(address(0), newOperator_);
    _operator = newOperator_;
  }
}

interface IOracle {
  function update() external;

  function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

  function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

contract Sky is ERC20Burnable, Operator {
  using SafeMath8 for uint8;
  using SafeMath for uint256;

  // Initial distribution for the first 48h genesis pools
  uint256 public constant INITIAL_GENESIS_POOL_DISTRIBUTION = 20000 ether;

  // Have the rewards been distributed to the pools
  bool public rewardPoolDistributed = false;

  /* ================= Taxation =============== */
  // Address of the Oracle
  address public skyOracle;
  // Address of the Tax Office
  address public taxOffice;

  // Current tax rate
  uint256 public taxRate;
  // Price threshold below which taxes will get burned
  uint256 public burnThreshold = 1.10e18;
  // Address of the tax collector wallet
  address public taxCollectorAddress;

  // Should the taxes be calculated using the tax tiers
  bool public autoCalculateTax;

  // Tax Tiers
  uint256[] public taxTiersTwaps = [
    0,
    5e17,
    6e17,
    7e17,
    8e17,
    9e17,
    9.5e17,
    1e18,
    1.05e18,
    1.10e18,
    1.20e18,
    1.30e18,
    1.40e18,
    1.50e18
  ];
  uint256[] public taxTiersRates = [2000, 1900, 1800, 1700, 1600, 1500, 1500, 1500, 1500, 1400, 900, 400, 200, 100];

  // Sender addresses excluded from Tax
  mapping(address => bool) public excludedAddresses;

  event TaxOfficeTransferred(address oldAddress, address newAddress);

  modifier onlyTaxOffice() {
    require(taxOffice == msg.sender, 'Caller is not the tax office');
    _;
  }

  modifier onlyOperatorOrTaxOffice() {
    require(isOperator() || taxOffice == msg.sender, 'Caller is not the operator or the tax office');
    _;
  }

  /**
   * @notice Constructs the SKY ERC-20 contract.
   */
  constructor(uint256 _taxRate, address _taxCollectorAddress) public ERC20('SKY', 'SKY') {
    require(_taxRate < 10000, 'tax equal or bigger to 100%');
    require(_taxCollectorAddress != address(0), 'tax collector address must be non-zero address');

    excludeAddress(address(this));

    // For initial liquidity
    _mint(msg.sender, 1500 ether);
    taxRate = _taxRate;
    taxCollectorAddress = _taxCollectorAddress;
  }

  /* ============= Taxation ============= */

  function getTaxTiersTwapsCount() public view returns (uint256 count) {
    return taxTiersTwaps.length;
  }

  function getTaxTiersRatesCount() public view returns (uint256 count) {
    return taxTiersRates.length;
  }

  function isAddressExcluded(address _address) public view returns (bool) {
    return excludedAddresses[_address];
  }

  function setTaxTiersTwap(uint8 _index, uint256 _value) public onlyTaxOffice returns (bool) {
    require(_index >= 0, 'Index has to be higher than 0');
    require(_index < getTaxTiersTwapsCount(), 'Index has to lower than count of tax tiers');
    if (_index > 0) {
      require(_value > taxTiersTwaps[_index - 1]);
    }
    if (_index < getTaxTiersTwapsCount().sub(1)) {
      require(_value < taxTiersTwaps[_index + 1]);
    }
    taxTiersTwaps[_index] = _value;
    return true;
  }

  function setTaxTiersRate(uint8 _index, uint256 _value) public onlyTaxOffice returns (bool) {
    require(_index >= 0, 'Index has to be higher than 0');
    require(_index < getTaxTiersRatesCount(), 'Index has to lower than count of tax tiers');
    taxTiersRates[_index] = _value;
    return true;
  }

  function setBurnThreshold(uint256 _burnThreshold) public onlyTaxOffice returns (bool) {
    burnThreshold = _burnThreshold;
  }

  function _getSkyPrice() internal view returns (uint256 _skyPrice) {
    try IOracle(skyOracle).consult(address(this), 1e18) returns (uint144 _price) {
      return uint256(_price);
    } catch {
      revert('Sky: failed to fetch SKY price from Oracle');
    }
  }

  function _updateTaxRate(uint256 _skyPrice) internal returns (uint256) {
    if (autoCalculateTax) {
      for (uint8 tierId = uint8(getTaxTiersTwapsCount()).sub(1); tierId >= 0; --tierId) {
        if (_skyPrice >= taxTiersTwaps[tierId]) {
          require(taxTiersRates[tierId] < 10000, 'tax equal or bigger to 100%');
          taxRate = taxTiersRates[tierId];
          return taxTiersRates[tierId];
        }
      }
    }
  }

  function enableAutoCalculateTax() public onlyTaxOffice {
    autoCalculateTax = true;
  }

  function disableAutoCalculateTax() public onlyTaxOffice {
    autoCalculateTax = false;
  }

  function setSkyOracle(address _skyOracle) public onlyOperatorOrTaxOffice {
    require(_skyOracle != address(0), 'oracle address cannot be 0 address');
    skyOracle = _skyOracle;
  }

  function setTaxOffice(address _taxOffice) public onlyOperatorOrTaxOffice {
    require(_taxOffice != address(0), 'tax office address cannot be 0 address');
    emit TaxOfficeTransferred(taxOffice, _taxOffice);
    taxOffice = _taxOffice;
  }

  function setTaxCollectorAddress(address _taxCollectorAddress) public onlyTaxOffice {
    require(_taxCollectorAddress != address(0), 'tax collector address must be non-zero address');
    taxCollectorAddress = _taxCollectorAddress;
  }

  function setTaxRate(uint256 _taxRate) public onlyTaxOffice {
    require(!autoCalculateTax, 'auto calculate tax cannot be enabled');
    require(_taxRate < 10000, 'tax equal or bigger to 100%');
    taxRate = _taxRate;
  }

  function excludeAddress(address _address) public onlyOperatorOrTaxOffice returns (bool) {
    require(!excludedAddresses[_address], "address can't be excluded");
    excludedAddresses[_address] = true;
    return true;
  }

  function includeAddress(address _address) public onlyOperatorOrTaxOffice returns (bool) {
    require(excludedAddresses[_address], "address can't be included");
    excludedAddresses[_address] = false;
    return true;
  }

  /**
   * @notice Operator mints SKY to a recipient
   * @param recipient_ The address of recipient
   * @param amount_ The amount of SKY to mint to
   * @return whether the process has been done
   */
  function mint(address recipient_, uint256 amount_) public onlyOperator returns (bool) {
    uint256 balanceBefore = balanceOf(recipient_);
    _mint(recipient_, amount_);
    uint256 balanceAfter = balanceOf(recipient_);

    return balanceAfter > balanceBefore;
  }

  function burn(uint256 amount) public override {
    super.burn(amount);
  }

  function burnFrom(address account, uint256 amount) public override onlyOperator {
    super.burnFrom(account, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    uint256 currentTaxRate = 0;
    bool burnTax = false;

    if (autoCalculateTax) {
      uint256 currentSkyPrice = _getSkyPrice();
      currentTaxRate = _updateTaxRate(currentSkyPrice);
      if (currentSkyPrice < burnThreshold) {
        burnTax = true;
      }
    }

    if (currentTaxRate == 0 || excludedAddresses[sender]) {
      _transfer(sender, recipient, amount);
    } else {
      _transferWithTax(sender, recipient, amount, burnTax);
    }

    _approve(
      sender,
      _msgSender(),
      allowance(sender, _msgSender()).sub(amount, 'ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  function _transferWithTax(address sender, address recipient, uint256 amount, bool burnTax) internal returns (bool) {
    uint256 taxAmount = amount.mul(taxRate).div(10000);
    uint256 amountAfterTax = amount.sub(taxAmount);

    if (burnTax) {
      // Burn tax
      super.burnFrom(sender, taxAmount);
    } else {
      // Transfer tax to tax collector
      _transfer(sender, taxCollectorAddress, taxAmount);
    }

    // Transfer amount after tax to recipient
    _transfer(sender, recipient, amountAfterTax);

    return true;
  }

  /**
   * @notice distribute to reward pool (only once)
   */
  function distributeReward(address _genesisPool) external onlyOperator {
    require(!rewardPoolDistributed, 'only can distribute once');
    require(_genesisPool != address(0), '!_genesisPool');
    rewardPoolDistributed = true;
    _mint(_genesisPool, INITIAL_GENESIS_POOL_DISTRIBUTION);
  }

  function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOperator {
    _token.transfer(_to, _amount);
  }
}