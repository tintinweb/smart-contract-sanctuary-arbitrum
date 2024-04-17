// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

interface IDEXRouterV2 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
}

interface IDEXFactoryV2 {
  function createPair(address tokenA, address tokenB) external returns (address pair);
  function getPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";

abstract contract CF_ERC20 is CF_Common {
  string internal _name;
  string internal _symbol;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function name() external view returns (string memory) {
    return _name;
  }

  function symbol() external view returns (string memory) {
    return _symbol;
  }

  function decimals() external view returns (uint8) {
    return _decimals;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balance[account];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowance[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    _approve(msg.sender, spender, amount);

    return true;
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    _transfer(msg.sender, to, amount);

    return true;
  }

  function transferFrom(address from, address to, uint256 amount) external returns (bool) {
    _spendAllowance(from, msg.sender, amount);
    _transfer(from, to, amount);

    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
    unchecked {
      _approve(msg.sender, spender, allowance(msg.sender, spender) + addedValue);
    }

    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
    uint256 currentAllowance = allowance(msg.sender, spender);

    require(currentAllowance >= subtractedValue, "Negative allowance");

    unchecked {
      _approve(msg.sender, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    _allowance[owner][spender] = amount;

    emit Approval(owner, spender, amount);
  }

  function _spendAllowance(address owner, address spender, uint256 amount) internal {
    uint256 currentAllowance = allowance(owner, spender);

    require(currentAllowance >= amount, "Insufficient allowance");

    unchecked {
      _approve(owner, spender, currentAllowance - amount);
    }
  }

  function _transfer(address from, address to, uint256 amount) internal virtual {
    require(from != address(0) && to != address(0), "Transfer from/to zero address");
    require(_balance[from] >= amount, "Exceeds balance");

    if (amount > 0) {
      unchecked {
        _balance[from] -= amount;
        _balance[to] += amount;
      }
    }

    emit Transfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./IDEXV2.sol";
import "./IERC20.sol";

abstract contract CF_Common {
  string internal constant _version = "1.0.4";

  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  mapping(address => holderAccount) internal _holder;
  mapping(uint8 => taxBeneficiary) internal _taxBeneficiary;

  address[] internal _holders;

  bool internal _suspendTaxes;
  bool internal _distributing;
  bool internal immutable _initialized;

  uint8 internal immutable _decimals;
  uint24 internal constant _denominator = 1000;
  uint24 internal _totalTxTax;
  uint24 internal _totalBuyTax;
  uint24 internal _totalSellTax;
  uint24 internal _totalPenaltyTxTax;
  uint24 internal _totalPenaltyBuyTax;
  uint24 internal _totalPenaltySellTax;
  uint32 internal _tradingEnabled;
  uint32 internal _earlyPenaltyTime;
  uint256 internal _totalSupply;
  uint256 internal _totalTaxCollected;
  uint256 internal _totalTaxUnclaimed;
  uint256 internal _amountForTaxDistribution;

  struct Renounced {
    bool Taxable;
    bool DEXRouterV2;
  }

  struct holderAccount {
    bool exists;
    bool penalty;
  }

  struct taxBeneficiary {
    bool exists;
    address account;
    uint24[3] percent; // 0: tx, 1: buy, 2: sell
    uint24[3] penalty;
    uint256 unclaimed;
  }

  struct DEXRouterV2 {
    address router;
    address pair;
    address token0;
    address WETH;
  }

  Renounced internal _renounced;
  IERC20 internal _taxToken = IERC20(address(this));
  DEXRouterV2 internal _dex;

  function _percentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    unchecked {
      return (amount * bps) / (100 * uint256(_denominator));
    }
  }

  function _timestamp() internal view returns (uint32) {
    unchecked {
      return uint32(block.timestamp % 2**32);
    }
  }

  function denominator() external pure returns (uint24) {
    return _denominator;
  }

  function version() external pure returns (string memory) {
    return _version;
  }
}

// SPDX-License-Identifier: MIT

import "./CF_Common.sol";

pragma solidity 0.8.25;

abstract contract CF_Ownable is CF_Common {
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(_owner == msg.sender, "Unauthorized");

    _;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  function renounceOwnership() external onlyOwner {
    _renounced.Taxable = true;
    _renounced.DEXRouterV2 = true;

    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));

    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";

abstract contract CF_Taxable is CF_Common, CF_Ownable, CF_ERC20 {
  event SetTaxBeneficiary(uint8 slot, address account, uint24[3] percent, uint24[3] penalty);
  event SetEarlyPenaltyTime(uint32 time);
  event TaxDistributed(uint256 amount);
  event RenouncedTaxable();

  struct taxBeneficiaryView {
    address account;
    uint24[3] percent;
    uint24[3] penalty;
    uint256 unclaimed;
  }

  modifier lockDistributing {
    _distributing = true;
    _;
    _distributing = false;
  }

  /// @notice Permanently renounce and prevent the owner from being able to update the tax features
  /// @dev Existing settings will continue to be effective
  function renounceTaxable() external onlyOwner {
    _renounced.Taxable = true;

    emit RenouncedTaxable();
  }

  /// @notice Total amount of taxes collected so far
  function totalTaxCollected() external view returns (uint256) {
    return _totalTaxCollected;
  }
  /// @notice Tax applied per transfer
  /// @dev Taking in consideration your wallet address
  function txTax() external view returns (uint24) {
    return txTax(msg.sender);
  }

  /// @notice Tax applied per transfer
  /// @param from Sender address
  function txTax(address from) public view returns (uint24) {
    unchecked {
      return from == address(this) || from == _dex.pair ? 0 : (_holder[from].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltyTxTax : _totalTxTax);
    }
  }

  /// @notice Tax applied for buying
  /// @dev Taking in consideration your wallet address
  function buyTax() external view returns (uint24) {
    return buyTax(msg.sender);
  }

  /// @notice Tax applied for buying
  /// @param from Buyer's address
  function buyTax(address from) public view returns (uint24) {
    if (_suspendTaxes) { return 0; }

    unchecked {
      return from == address(this) || from == _dex.pair ? 0 : (_holder[from].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltyBuyTax : _totalBuyTax);
    }
  }
  /// @notice Tax applied for selling
  /// @dev Taking in consideration your wallet address
  function sellTax() external view returns (uint24) {
    return sellTax(msg.sender);
  }

  /// @notice Tax applied for selling
  /// @param to Seller's address
  function sellTax(address to) public view returns (uint24) {
    if (_suspendTaxes) { return 0; }

    unchecked {
      return to == address(this) || to == _owner || to == _dex.pair || to == _dex.router ? 0 : (_holder[to].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltySellTax : _totalSellTax);
    }
  }

  /// @notice List of all tax beneficiaries and their assigned percentage, according to type of transfer
  /// @custom:return `list[].account` Beneficiary address
  /// @custom:return `list[].percent[3]` Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  /// @custom:return `list[].penalty[3]` Index 0 is for tx penalty, 1 is for buy penalty, 2 is for sell penalty, multiplied by denominator
  function listTaxBeneficiaries() external view returns (taxBeneficiaryView[] memory list) {
    list = new taxBeneficiaryView[](6);

    unchecked {
      for (uint8 i; i < 6; i++) { list[i] = taxBeneficiaryView(_taxBeneficiary[i].account, _taxBeneficiary[i].percent, _taxBeneficiary[i].penalty, _taxBeneficiary[i].unclaimed); }
    }
  }

  /// @notice Sets a tax beneficiary
  /// @dev Maximum of 5 wallets can be assigned
  /// @dev Slot 0 is reserved for ChainFactory revenue
  /// @param slot Slot number (1 to 5)
  /// @param account Beneficiary address
  /// @param percent[3] Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  /// @param penalty[3] Index 0 is for tx penalty, 1 is for buy penalty, 2 is for sell penalty, multiplied by denominator
  function setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent, uint24[3] memory penalty) external onlyOwner {
    require(!_renounced.Taxable);
    require(slot >= 1 && slot <= 5, "Reserved");

    _setTaxBeneficiary(slot, account, percent, penalty);
  }

  function _setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent, uint24[3] memory penalty) internal {
    require(slot <= 5);
    require(account != address(this) && account != address(0xdEaD) && account != address(0));

    taxBeneficiary storage taxBeneficiarySlot = _taxBeneficiary[slot];

    unchecked {
      _totalTxTax += percent[0] - taxBeneficiarySlot.percent[0];
      _totalBuyTax += percent[1] - taxBeneficiarySlot.percent[1];
      _totalSellTax += percent[2] - taxBeneficiarySlot.percent[2];
      _totalPenaltyTxTax += penalty[0] - taxBeneficiarySlot.penalty[0];
      _totalPenaltyBuyTax += penalty[1] - taxBeneficiarySlot.penalty[1];
      _totalPenaltySellTax += penalty[2] - taxBeneficiarySlot.penalty[2];

      require(_totalTxTax <= 25 * _denominator && ((_totalBuyTax <= 25 * _denominator && _totalSellTax <= 25 * _denominator) && (_totalBuyTax + _totalSellTax <= 25 * _denominator)), "High Tax");
      require(_totalPenaltyTxTax <= 90 * _denominator && _totalPenaltyBuyTax <= 90 * _denominator && _totalPenaltySellTax <= 90 * _denominator, "Invalid Penalty");

      taxBeneficiarySlot.account = account;
      taxBeneficiarySlot.percent = percent;

      if (_initialized && slot > 0) { _setTaxBeneficiary(0, _taxBeneficiary[0].account, [ uint24(0), uint24(0), uint24(0) ], [ _taxBeneficiary[0].penalty[0] + uint24((penalty[0] * 10 / 100) - (taxBeneficiarySlot.penalty[0] * 10 / 100)), _taxBeneficiary[0].penalty[1] + uint24((penalty[1] * 10 / 100) - (taxBeneficiarySlot.penalty[1] * 10 / 100)), _taxBeneficiary[0].penalty[2] + uint24((penalty[2] * 10 / 100) - (taxBeneficiarySlot.penalty[2] * 10 / 100)) ]); }

      taxBeneficiarySlot.penalty = penalty;
    }

    if (!taxBeneficiarySlot.exists) { taxBeneficiarySlot.exists = true; }

    emit SetTaxBeneficiary(slot, account, percent, penalty);
  }

  /// @notice Triggers the tax distribution
  /// @dev Will only be executed if there is no ongoing tax distribution
  function autoTaxDistribute() external onlyOwner {
    require(!_distributing);

    _autoTaxDistribute();
  }

  function _autoTaxDistribute() internal lockDistributing {
    if (_totalTaxUnclaimed == 0) { return; }

    unchecked {
      uint256 distributedTaxes;

      for (uint8 i; i < 6; i++) {
        taxBeneficiary storage taxBeneficiarySlot = _taxBeneficiary[i];
        address account = taxBeneficiarySlot.account;

        if (taxBeneficiarySlot.unclaimed == 0 || account == _dex.pair) { continue; }

        uint256 unclaimed = _percentage(_amountForTaxDistribution, (100 * uint256(_denominator) * taxBeneficiarySlot.unclaimed) / _totalTaxUnclaimed);
        uint256 _distributedTaxes = _distribute(account, unclaimed);

        if (_distributedTaxes > 0) {
          taxBeneficiarySlot.unclaimed -= _distributedTaxes;
          distributedTaxes += _distributedTaxes;
        }
      }

      if (distributedTaxes > 0) {
        _totalTaxUnclaimed -= distributedTaxes;

        emit TaxDistributed(distributedTaxes);
      }
    }
  }

  function _distribute(address account, uint256 unclaimed) private returns (uint256) {
    if (unclaimed == 0) { return 0; }

    unchecked {
      super._transfer(address(this), account, unclaimed);

      _amountForTaxDistribution -= unclaimed;
    }

    return unclaimed;
  }

  /// @notice Suspend or reinstate tax collection
  /// @dev Also applies to early penalties
  /// @param status True to suspend, False to reinstate existent taxes
  function suspendTaxes(bool status) external onlyOwner {
    require(!_renounced.Taxable);

    _suspendTaxes = status;
  }

  /// @notice Checks if tax collection is currently suspended
  function taxesSuspended() external view returns (bool) {
    return _suspendTaxes;
  }

  /// @notice Removes the penalty status of a wallet
  /// @param account Address to depenalize
  function removePenalty(address account) external onlyOwner {
    require(!_renounced.Taxable);

    _holder[account].penalty = false;
  }

  /// @notice Check if a wallet is penalized due to an early transaction
  /// @param account Address to check
  function isPenalized(address account) external view returns (bool) {
    return _holder[account].penalty;
  }

  /// @notice Returns the period of time during which early buyers will be penalized from the time trading was enabled
  function getEarlyPenaltyTime() external view returns (uint32) {
    return _earlyPenaltyTime;
  }

  /// @notice Defines the period of time during which early buyers will be penalized from the time trading was enabled
  /// @dev Must be less or equal to 1 hour
  /// @param time Time, in seconds
  function setEarlyPenaltyTime(uint32 time) external onlyOwner {
    require(!_renounced.Taxable);
    require(time <= 600);

    _setEarlyPenaltyTime(time);
  }

  function _setEarlyPenaltyTime(uint32 time) internal {
    _earlyPenaltyTime = time;

    emit SetEarlyPenaltyTime(time);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";

abstract contract CF_DEXRouterV2 is CF_Common, CF_Ownable, CF_ERC20 {
  event SetDEXRouterV2(address indexed router, address indexed pair);
  event TradingEnabled();
  event RenouncedDEXRouterV2();

  /// @notice Permanently renounce and prevent the owner from being able to update the DEX features
  /// @dev Existing settings will continue to be effective
  function renounceDEXRouterV2() external onlyOwner {
    _renounced.DEXRouterV2 = true;

    emit RenouncedDEXRouterV2();
  }

  function createDEXPairV2() external {
    require(_dex.pair == address(0));

    IDEXFactoryV2 factory = IDEXFactoryV2(IDEXRouterV2(_dex.router).factory());
    _dex.pair = factory.createPair(address(this), _dex.token0);

    emit SetDEXRouterV2(_dex.router, _dex.pair);
  }

  function _setDEXRouterV2(address router, address token0) internal {
    IDEXRouterV2 _router = IDEXRouterV2(router);

    _dex = DEXRouterV2(router, address(0), token0, _router.WETH());
  }

  /// @notice Returns the DEX router currently in use
  function getDEXRouterV2() external view returns (address) {
    return _dex.router;
  }

  /// @notice Returns the trading pair
  function getDEXPairV2() external view returns (address) {
    return _dex.pair;
  }

  /// @notice Checks whether the token can be traded through the assigned DEX
  function isTradingEnabled() external view returns (bool) {
    return _tradingEnabled > 0;
  }

  /// @notice Enables the trading capability via the DEX set up
  /// @dev Once enabled, it cannot be reverted
  function enableTrading() external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(_tradingEnabled == 0, "Already enabled");
    require(_dex.pair != address(0), "No Pair");

    _tradingEnabled = _timestamp();

    emit TradingEnabled();
  }
}

/*

  My Token Camelot

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";
import "./CF_Taxable.sol";
import "./CF_DEXRouterV2.sol";

contract ChainFactory_ERC20 is CF_Common, CF_Ownable, CF_ERC20, CF_Taxable, CF_DEXRouterV2 {
  constructor() {
    _name = unicode"My Token Camelot";
    _symbol = unicode"MyToken";
    _decimals = 18;
    _totalSupply = 1000000000000000000000000; // 1,000,000 MyToken
    _transferOwnership(0xBA799d418D1356ff5d225096d08951a3b45b6e4A);
    _transferInitialSupply(0xBA799d418D1356ff5d225096d08951a3b45b6e4A, 100000); // 100%
    _setDEXRouterV2(0xc873fEcbd354f5A56E00E710B90EF4201db2448d, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    _setEarlyPenaltyTime(180); // 3min
    _setTaxBeneficiary(0, 0x8881d9869aC7C7840971cAac043D7f4D144Abd10, [ uint24(0), uint24(0), uint24(0) ], [ uint24(0), uint24(0), uint24(0) ]); // ChainFactory Anti-Sniper revenue (10%)
    _setTaxBeneficiary(1, 0xBA799d418D1356ff5d225096d08951a3b45b6e4A, [ uint24(0), uint24(0), uint24(0) ], [ uint24(0), uint24(0), uint24(0) ]);

    _initialized = true;
  }

  function _transfer(address from, address to, uint256 amount) internal virtual override {
    if (!_distributing) {
      _autoTaxDistribute();
    }

    if (amount > 0 && from != _owner && to != _owner && from != address(this) && to != address(this) && to != _dex.router) {
      require((from != _dex.pair && to != _dex.pair) || ((from == _dex.pair || to == _dex.pair) && _tradingEnabled > 0), "Trading disabled");

      unchecked {
        if (!_suspendTaxes && !_distributing) {
          uint256 appliedTax;
          uint8 taxType;

          if (from == _dex.pair || to == _dex.pair) { taxType = from == _dex.pair ? 1 : 2; }

          address _account = taxType == 1 ? to : from;

          if (_tradingEnabled + _earlyPenaltyTime >= _timestamp() && !_holder[_account].penalty) { _holder[_account].penalty = true; }

          for (uint8 i; i < 6; i++) {
            uint256 percent = uint256(taxType > 0 ? (taxType == 1 ? (_holder[_account].penalty ? _taxBeneficiary[i].penalty[1] : _taxBeneficiary[i].percent[1]) : (_holder[_account].penalty ? _taxBeneficiary[i].penalty[2] : _taxBeneficiary[i].percent[2])) : (_holder[_account].penalty ? _taxBeneficiary[i].penalty[0] : _taxBeneficiary[i].percent[0]));

            if (percent == 0) { continue; }

            uint256 taxAmount = _percentage(amount, percent);

            super._transfer(from, address(this), taxAmount);

            _taxBeneficiary[i].unclaimed += taxAmount;
            _amountForTaxDistribution += taxAmount;
            _totalTaxUnclaimed += taxAmount;

            appliedTax += taxAmount;
          }

          if (appliedTax > 0) {
            _totalTaxCollected += appliedTax;

            amount -= appliedTax;
          }
        }
      }
    }

    super._transfer(from, to, amount);
  }

  function _transferInitialSupply(address account, uint24 percent) private {
    require(!_initialized);

    uint256 amount = _percentage(_totalSupply, uint256(percent));

    _balance[account] = amount;

    emit Transfer(address(0), account, amount);
  }

  /// @notice Returns a list specifying the renounce status of each feature
  function renounced() external view returns (bool DEXRouterV2, bool Taxable) {
    return (_renounced.DEXRouterV2, _renounced.Taxable);
  }

  /// @notice Returns basic information about this Smart-Contract
  function info() external view returns (string memory name, string memory symbol, uint8 decimals, address owner, uint256 totalSupply, string memory version) {
    return (_name, _symbol, _decimals, _owner, _totalSupply, _version);
  }

  receive() external payable { }
  fallback() external payable { }
}

/*
   ________          _       ______           __                  
  / ____/ /_  ____ _(_)___  / ____/___ ______/ /_____  _______  __
 / /   / __ \/ __ `/ / __ \/ /_  / __ `/ ___/ __/ __ \/ ___/ / / /
/ /___/ / / / /_/ / / / / / __/ / /_/ / /__/ /_/ /_/ / /  / /_/ / 
\____/_/ /_/\__,_/_/_/ /_/_/    \__,_/\___/\__/\____/_/   \__, /  
                                                         /____/   

  Smart-Contract generated by ChainFactory.app

  By using this Smart-Contract generated by ChainFactory.app, you
  acknowledge and agree that ChainFactory shall not be liable for
  any damages arising from the use of this Smart-Contract,
  including but not limited to any damages resulting from any
  malicious or illegal use of the Smart-Contract by any third
  party or by the owner.

  The owner of the Smart-Contract generated by ChainFactory.app
  agrees not to misuse the Smart-Contract, including but not
  limited to:

  - Using the Smart-Contract to engage in any illegal or
    fraudulent activity, including but not limited to scams,
    theft, or money laundering.

  - Using the Smart-Contract in any manner that could cause harm
    to others, including but not limited to disrupting financial
    markets or causing financial loss to others.

  - Using the Smart-Contract to infringe upon the intellectual
    property rights of others, including but not limited to
    copyright, trademark, or patent infringement.

  The owner of the Smart-Contract generated by ChainFactory.app
  acknowledges that any misuse of the Smart-Contract may result in
  legal action, and agrees to indemnify and hold harmless
  ChainFactory from any and all claims, damages, or expenses
  arising from any such misuse.

*/