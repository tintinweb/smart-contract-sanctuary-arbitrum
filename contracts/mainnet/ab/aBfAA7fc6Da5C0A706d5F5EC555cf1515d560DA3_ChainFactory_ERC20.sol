// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

interface IDEXRouterV2 {
  function factory() external pure returns (address);
  function WETH() external pure returns (address);
  function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, address referrer, uint256 deadline) external;
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, address referrer, uint256 deadline) external;
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
  string internal constant _version = "1.0.3";

  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  mapping(address => holderAccount) internal _holder;
  mapping(uint8 => taxBeneficiary) internal _taxBeneficiary;
  mapping(address => uint256) internal _tokensForTaxDistribution;

  address[] internal _holders;

  bool internal _autoSwapEnabled;
  bool internal _swapping;
  bool internal _suspendTaxes;
  bool internal _distributing;
  bool internal immutable _initialized;

  uint8 internal immutable _decimals;
  uint24 internal constant _denominator = 1000;
  uint24 internal _totalTxTax;
  uint24 internal _totalBuyTax;
  uint24 internal _totalSellTax;
  uint24 internal _minAutoSwapPercent;
  uint24 internal _maxAutoSwapPercent;
  uint24 internal _minAutoAddLiquidityPercent;
  uint24 internal _maxAutoAddLiquidityPercent;
  uint32 internal _lastTaxDistribution;
  uint32 internal _tradingEnabled;
  uint32 internal _lastSwap;
  uint256 internal _totalSupply;
  uint256 internal _minAutoSwapAmount;
  uint256 internal _maxAutoSwapAmount;
  uint256 internal _minAutoAddLiquidityAmount;
  uint256 internal _maxAutoAddLiquidityAmount;
  uint256 internal _amountForLiquidity;
  uint256 internal _ethForLiquidity;
  uint256 internal _totalTaxCollected;
  uint256 internal _totalTaxUnclaimed;
  uint256 internal _amountForTaxDistribution;
  uint256 internal _amountSwappedForTaxDistribution;
  uint256 internal _ethForTaxDistribution;

  struct Renounced {
    bool Taxable;
    bool DEXRouterV2;
  }

  struct holderAccount {
    bool exists;
  }

  struct taxBeneficiary {
    bool exists;
    address account;
    uint24[3] percent; // 0: tx, 1: buy, 2: sell
    uint256 unclaimed;
  }

  struct DEXRouterV2 {
    address router;
    address pair;
    address token0;
    address WETH;
    address receiver;
  }

  Renounced internal _renounced;
  IERC20 internal _taxToken;
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
  event SetTaxBeneficiary(uint8 slot, address account, uint24[3] percent);
  event TaxDistributed(uint256 amount);
  event RenouncedTaxable();

  struct taxBeneficiaryView {
    address account;
    uint24[3] percent;
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
      return from == address(this) || from == _dex.pair ? 0 : _totalTxTax;
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
      return from == address(this) || from == _dex.pair ? 0 : _totalBuyTax;
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
      return to == address(this) || to == _owner || to == _dex.pair || to == _dex.router ? 0 : _totalSellTax;
    }
  }

  /// @notice List of all tax beneficiaries and their assigned percentage, according to type of transfer
  /// @custom:return `list[].account` Beneficiary address
  /// @custom:return `list[].percent[3]` Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  function listTaxBeneficiaries() external view returns (taxBeneficiaryView[] memory list) {
    list = new taxBeneficiaryView[](5);

    unchecked {
      for (uint8 i = 1; i < 6; i++) { list[i - 1] = taxBeneficiaryView(_taxBeneficiary[i].account, _taxBeneficiary[i].percent, _taxBeneficiary[i].unclaimed); }
    }
  }

  /// @notice Sets a tax beneficiary
  /// @dev Maximum of 5 wallets can be assigned
  /// @param slot Slot number (1 to 5)
  /// @param account Beneficiary address
  /// @param percent[3] Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  function setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent) external onlyOwner {
    require(!_renounced.Taxable);
    require(slot >= 1 && slot <= 5, "Reserved");

    _setTaxBeneficiary(slot, account, percent);
  }

  function _setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent) internal {
    require(slot <= 5);
    require(account != address(this) && account != address(0xdEaD) && account != address(0));

    taxBeneficiary storage taxBeneficiarySlot = _taxBeneficiary[slot];

    unchecked {
      _totalTxTax += percent[0] - taxBeneficiarySlot.percent[0];
      _totalBuyTax += percent[1] - taxBeneficiarySlot.percent[1];
      _totalSellTax += percent[2] - taxBeneficiarySlot.percent[2];

      require(_totalTxTax <= 25 * _denominator && ((_totalBuyTax <= 25 * _denominator && _totalSellTax <= 25 * _denominator) && (_totalBuyTax + _totalSellTax <= 25 * _denominator)), "High Tax");
      taxBeneficiarySlot.account = account;
      taxBeneficiarySlot.percent = percent;
    }

    if (!taxBeneficiarySlot.exists) { taxBeneficiarySlot.exists = true; }

    emit SetTaxBeneficiary(slot, account, percent);
  }

  /// @notice Triggers the tax distribution
  /// @dev Will only be executed if there is no ongoing swap or tax distribution
  function autoTaxDistribute() external onlyOwner {
    require(!_swapping && !_distributing);

    _autoTaxDistribute();
  }

  function _autoTaxDistribute() internal lockDistributing {
    if (_totalTaxUnclaimed == 0) { return; }

    unchecked {
      uint256 distributedTaxes;

      for (uint8 i = 1; i < 6; i++) {
        taxBeneficiary storage taxBeneficiarySlot = _taxBeneficiary[i];
        address account = taxBeneficiarySlot.account;

        if (taxBeneficiarySlot.unclaimed == 0 || account == _dex.pair) { continue; }

        uint256 unclaimed = _percentage(address(_taxToken) == address(this) ? _amountForTaxDistribution : _amountSwappedForTaxDistribution, (100 * uint256(_denominator) * taxBeneficiarySlot.unclaimed) / _totalTaxUnclaimed);
        uint256 _distributedTaxes = _distribute(account, unclaimed);

        if (_distributedTaxes > 0) {
          taxBeneficiarySlot.unclaimed -= _distributedTaxes;
          distributedTaxes += _distributedTaxes;
        }
      }

      _lastTaxDistribution = _timestamp();

      if (distributedTaxes > 0) {
        _totalTaxUnclaimed -= distributedTaxes;

        emit TaxDistributed(distributedTaxes);
      }
    }
  }

  function _distribute(address account, uint256 unclaimed) private returns (uint256) {
    if (unclaimed == 0) { return 0; }

    unchecked {
      if (address(_taxToken) == address(this)) {
        super._transfer(address(this), account, unclaimed);

        _amountForTaxDistribution -= unclaimed;
      } else {
        uint256 percent = (100 * uint256(_denominator) * unclaimed) / _amountSwappedForTaxDistribution;
        uint256 amount;

        if (address(_taxToken) == _dex.WETH) {
          amount = _percentage(_ethForTaxDistribution, percent);

          (bool success, ) = payable(account).call{ value: amount, gas: 30000 }("");

          if (!success) { return 0; }

          _ethForTaxDistribution -= amount;
        } else {
          amount = _percentage(_tokensForTaxDistribution[address(_taxToken)], percent);

          try _taxToken.transfer(account, amount) { _tokensForTaxDistribution[address(_taxToken)] -= amount; } catch { return 0; }
        }

        _amountSwappedForTaxDistribution -= unclaimed;
      }
    }

    return unclaimed;
  }

  /// @notice Suspend or reinstate tax collection
  /// @param status True to suspend, False to reinstate existent taxes
  function suspendTaxes(bool status) external onlyOwner {
    require(!_renounced.Taxable);

    _suspendTaxes = status;
  }

  /// @notice Checks if tax collection is currently suspended
  function taxesSuspended() external view returns (bool) {
    return _suspendTaxes;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";
import "./CF_Taxable.sol";

abstract contract CF_DEXRouterV2 is CF_Common, CF_Ownable, CF_ERC20, CF_Taxable {
  event AddedLiquidity(uint256 tokenAmount, uint256 ethAmount, uint256 liquidity);
  event SwappedTokensForNative(uint256 tokenAmount, uint256 ethAmount);
  event SwappedTokensForTokens(address token, uint256 token0Amount, uint256 token1Amount);
  event SetDEXRouterV2(address indexed router, address indexed pair);
  event TradingEnabled();
  event RenouncedDEXRouterV2();

  modifier lockSwapping {
    _swapping = true;
    _;
    _swapping = false;
  }

  /// @notice Permanently renounce and prevent the owner from being able to update the DEX features
  /// @dev Existing settings will continue to be effective
  function renounceDEXRouterV2() external onlyOwner {
    _renounced.DEXRouterV2 = true;

    emit RenouncedDEXRouterV2();
  }

  /// @notice Creates the LP contract on Camelot V2
  /// @dev Must be executed even if you manually created the LP using Camelot V2 interface
  function createDEXPairV2() external {
    require(_dex.pair == address(0));

    IDEXFactoryV2 factory = IDEXFactoryV2(IDEXRouterV2(_dex.router).factory());
    _dex.pair = factory.getPair(address(this), _dex.token0);

    if (_dex.pair == address(0)) { _dex.pair = factory.createPair(address(this), _dex.token0); }

    _setTaxBeneficiary(1, _dex.pair, [ uint24(0), uint24(10000), uint24(10000) ]);

    emit SetDEXRouterV2(_dex.router, _dex.pair);
  }

  function _setDEXRouterV2(address router, address token0) internal {
    IDEXRouterV2 _router = IDEXRouterV2(router);

    _dex = DEXRouterV2(router, address(0), token0, _router.WETH(), address(0));
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

  /// @notice Returns address of the LP tokens receiver
  /// @dev Used for automated liquidity injection through taxes
  function getDEXLPTokenReceiver() external view returns (address) {
    return _dex.receiver;
  }

  /// @notice Set the address of the LP tokens receiver
  /// @dev Used for automated liquidity injection through taxes
  function setDEXLPTokenReceiver(address receiver) external onlyOwner {
    _setDEXLPTokenReceiver(receiver);
  }

  function _setDEXLPTokenReceiver(address receiver) internal {
    _dex.receiver = receiver;
  }

  /// @notice Checks the status of the auto-swapping feature
  function isAutoSwapEnabled() external view returns (bool) {
    return _autoSwapEnabled;
  }

  /// @notice Returns the percentage range of the total supply over which the auto-swap will operate when accumulating taxes in the contract balance
  function getAutoSwapPercent() external view returns (uint24 min, uint24 max) {
    return (_minAutoSwapPercent, _maxAutoSwapPercent);
  }

  /// @notice Sets the percentage range of the total supply over which the auto-swap will operate when accumulating taxes in the contract balance
  /// @param min Desired min. percentage to trigger the auto-swap, multiplied by denominator (0.001% to 1% of total supply)
  /// @param max Desired max. percentage to limit the auto-swap, multiplied by denominator (0.001% to 1% of total supply)
  function setAutoSwapPercent(uint24 min, uint24 max) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(min >= 1 && min <= 1000, "0.001% to 1%");
    require(max >= min && max <= 1000, "0.001% to 1%");

    _setAutoSwapPercent(min, max);
  }

  function _setAutoSwapPercent(uint24 min, uint24 max) internal {
    _minAutoSwapPercent = min;
    _maxAutoSwapPercent = max;
    _minAutoSwapAmount = _percentage(_totalSupply, uint256(min));
    _maxAutoSwapAmount = _percentage(_totalSupply, uint256(max));
  }

  /// @notice Enables or disables the auto-swap function
  /// @param status True to enable, False to disable
  function enableAutoSwap(bool status) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(!status || _dex.router != address(0), "No DEX");

    _autoSwapEnabled = status;
  }

  /// @notice Swaps the assigned amount to inject liquidity and prepare collected taxes for its distribution
  /// @dev Will only be executed if there is no ongoing swap or tax distribution and the min. threshold has been reached
  function autoSwap() external {
    require(_autoSwapEnabled && !_swapping && !_distributing);

    _autoSwap(false);
  }

  /// @notice Swaps the assigned amount to inject liquidity and prepare collected taxes for its distribution
  /// @dev Will only be executed if there is no ongoing swap or tax distribution and the min. threshold has been reached unless forced
  /// @param force Ignore the min. and max. threshold amount
  function autoSwap(bool force) external onlyOwner {
    require((force || _autoSwapEnabled) && !_swapping && !_distributing);

    _autoSwap(force);
  }

  function _autoSwap(bool force) internal lockSwapping {
    if (!force && !_autoSwapEnabled) { return; }

    unchecked {
      uint256 amountForLiquidityToSwap = _amountForLiquidity > 0 ? _amountForLiquidity / 2 : 0;
      uint256 amountForTaxDistributionToSwap = (address(_taxToken) == _dex.WETH ? _amountForTaxDistribution : 0);
      uint256 amountToSwap = amountForTaxDistributionToSwap + amountForLiquidityToSwap;

      if (!force && amountToSwap > _maxAutoSwapAmount) {
        amountForLiquidityToSwap = amountForLiquidityToSwap > 0 ? _percentage(_maxAutoSwapAmount, (100 * uint256(_denominator) * amountForLiquidityToSwap) / amountToSwap) : 0;
        amountForTaxDistributionToSwap = amountForTaxDistributionToSwap > 0 ? _percentage(_maxAutoSwapAmount, (100 * uint256(_denominator) * amountForTaxDistributionToSwap) / amountToSwap) : 0;
        amountToSwap = amountForTaxDistributionToSwap + amountForLiquidityToSwap;
      }

      if ((force || amountToSwap >= _minAutoSwapAmount) && _balance[address(this)] >= amountToSwap + amountForLiquidityToSwap) {
        uint256 ethBalance = address(this).balance;
        address[] memory pathToSwapExactTokensForNative = new address[](2);
        pathToSwapExactTokensForNative[0] = address(this);
        pathToSwapExactTokensForNative[1] = _dex.WETH;

        _approve(address(this), _dex.router, amountToSwap);

        try IDEXRouterV2(_dex.router).swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, pathToSwapExactTokensForNative, address(this), address(0), block.timestamp) {
          if (_amountForLiquidity > 0) { _amountForLiquidity -= amountForLiquidityToSwap; }

          uint256 ethAmount = address(this).balance - ethBalance;

          emit SwappedTokensForNative(amountToSwap, ethAmount);

          if (ethAmount > 0) {
            _ethForLiquidity += _percentage(ethAmount, (100 * uint256(_denominator) * amountForLiquidityToSwap) / amountToSwap);

            if (address(_taxToken) == _dex.WETH) {
              _ethForTaxDistribution += _percentage(ethAmount, (100 * uint256(_denominator) * amountForTaxDistributionToSwap) / amountToSwap);
              _amountSwappedForTaxDistribution += amountForTaxDistributionToSwap;
              _amountForTaxDistribution -= amountForTaxDistributionToSwap;
            }
          }
        } catch {
          _approve(address(this), _dex.router, 0);
        }
      }

      if (address(_taxToken) != address(this) && address(_taxToken) != _dex.WETH) {
        amountForTaxDistributionToSwap = _amountForTaxDistribution;

        if (!force && amountForTaxDistributionToSwap > _maxAutoSwapAmount) { amountForTaxDistributionToSwap = _maxAutoSwapAmount; }

        if ((force || amountForTaxDistributionToSwap >= _minAutoSwapAmount) && _balance[address(this)] >= amountForTaxDistributionToSwap) {
          uint256 tokenAmount = _swapTokensForTokens(_taxToken, amountForTaxDistributionToSwap);

          if (tokenAmount > 0) {
            _tokensForTaxDistribution[address(_taxToken)] += tokenAmount;
            _amountSwappedForTaxDistribution += amountForTaxDistributionToSwap;
            _amountForTaxDistribution -= amountForTaxDistributionToSwap;
          }
        }
      }
    }

    _addLiquidity(force);
    _lastSwap = _timestamp();
  }

  function _swapTokensForTokens(IERC20 token, uint256 amount) private returns (uint256 tokenAmount) {
    uint256 tokenBalance = token.balanceOf(address(this));
    address[] memory pathToSwapExactTokensForTokens = new address[](3);
    pathToSwapExactTokensForTokens[0] = address(this);
    pathToSwapExactTokensForTokens[1] = _dex.WETH;
    pathToSwapExactTokensForTokens[2] = address(token);

    _approve(address(this), _dex.router, amount);

    try IDEXRouterV2(_dex.router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, pathToSwapExactTokensForTokens, address(this), address(0), block.timestamp) {
      tokenAmount = token.balanceOf(address(this)) - tokenBalance;

      emit SwappedTokensForTokens(address(token), amount, tokenAmount);
    } catch {
      _approve(address(this), _dex.router, 0);
    }
  }

  function _addLiquidity(bool force) private {
    if (!force && (_amountForLiquidity < _minAutoAddLiquidityAmount || _ethForLiquidity == 0)) { return; }

    unchecked {
      uint256 amountForLiquidityToAdd = !force && _amountForLiquidity > _maxAutoAddLiquidityAmount ? _maxAutoAddLiquidityAmount : _amountForLiquidity;
      uint256 ethForLiquidityToAdd = !force && _amountForLiquidity > _maxAutoAddLiquidityAmount ? _percentage(_ethForLiquidity, 100 * uint256(_denominator) * (_maxAutoAddLiquidityAmount / _amountForLiquidity)) : _ethForLiquidity;

      _approve(address(this), _dex.router, amountForLiquidityToAdd);

      try IDEXRouterV2(_dex.router).addLiquidityETH{ value: ethForLiquidityToAdd }(address(this), amountForLiquidityToAdd, 0, 0, _dex.receiver, block.timestamp) returns (uint256 tokenAmount, uint256 ethAmount, uint256 liquidity) {
        emit AddedLiquidity(tokenAmount, ethAmount, liquidity);

        _amountForLiquidity -= amountForLiquidityToAdd;
        _ethForLiquidity -= ethForLiquidityToAdd;
      } catch {
        _approve(address(this), _dex.router, 0);
      }
    }
  }

  /// @notice Returns the percentage range of the total supply over which the auto add liquidity will operate when accumulating taxes in the contract balance
  /// @dev Applies only if a Tax Beneficiary is the liquidity pool
  function getAutoAddLiquidityPercent() external view returns (uint24 min, uint24 max) {
    return (_minAutoAddLiquidityPercent, _maxAutoAddLiquidityPercent);
  }

  /// @notice Sets the percentage range of the total supply over which the auto add liquidity will operate when accumulating taxes in the contract balance
  /// @param min Desired min. percentage to trigger the auto add liquidity, multiplied by denominator (0.01% to 100% of total supply)
  /// @param max Desired max. percentage to limit the auto add liquidity, multiplied by denominator (0.01% to 100% of total supply)
  function setAutoAddLiquidityPercent(uint24 min, uint24 max) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(min >= 10 && min <= 100 * _denominator, "0.01% to 100%");
    require(max >= min && max <= 100 * _denominator, "0.01% to 100%");

    _setAutoAddLiquidityPercent(min, max);
  }

  function _setAutoAddLiquidityPercent(uint24 min, uint24 max) internal {
    _minAutoAddLiquidityPercent = min;
    _maxAutoAddLiquidityPercent = max;
    _minAutoAddLiquidityAmount = _percentage(_totalSupply, uint256(min));
    _maxAutoAddLiquidityAmount = _percentage(_totalSupply, uint256(max));
  }

  /// @notice Returns the token for tax distribution
  function getTaxToken() external view returns (address) {
    return address(_taxToken);
  }

  function _setTaxToken(address token) internal {
    require((!_initialized && token == address(0)) || token == address(this) || token == _dex.WETH || IDEXFactoryV2(IDEXRouterV2(_dex.router).factory()).getPair(_dex.WETH, token) != address(0), "No Pair");

    _taxToken = IERC20(token == address(0) ? address(this) : token);
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

  My Token CamelotV2

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
    _name = unicode"My Token CamelotV2";
    _symbol = unicode"M";
    _decimals = 18;
    _totalSupply = 1000000000000000000000000; // 1,000,000 M
    _transferOwnership(0xBA799d418D1356ff5d225096d08951a3b45b6e4A);
    _transferInitialSupply(0xBA799d418D1356ff5d225096d08951a3b45b6e4A, 100000); // 100%
    _setDEXRouterV2(0xc873fEcbd354f5A56E00E710B90EF4201db2448d, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    _setDEXLPTokenReceiver(0xBA799d418D1356ff5d225096d08951a3b45b6e4A);
    _setTaxToken(address(this));
    _autoSwapEnabled = true;
    _setAutoSwapPercent(50, 250); // 0.05% -> 0.25% of total supply
    _setAutoAddLiquidityPercent(100, 1000); // 0.1% -> 1% of total supply

    _initialized = true;
  }

  function _transfer(address from, address to, uint256 amount) internal virtual override {
    if (!_distributing && !_swapping && (from != _dex.pair && from != _dex.router)) {
      _autoSwap(false);
      _autoTaxDistribute();
    }

    if (amount > 0 && from != _owner && to != _owner && from != address(this) && to != address(this) && to != _dex.router) {
      require((from != _dex.pair && to != _dex.pair) || ((from == _dex.pair || to == _dex.pair) && _tradingEnabled > 0), "Trading disabled");

      unchecked {
        if (!_suspendTaxes && !_distributing && !_swapping) {
          uint256 appliedTax;
          uint8 taxType;

          if (from == _dex.pair || to == _dex.pair) { taxType = from == _dex.pair ? 1 : 2; }

          for (uint8 i = 1; i < 6; i++) {
            uint256 percent = uint256(taxType > 0 ? (taxType == 1 ? _taxBeneficiary[i].percent[1] : _taxBeneficiary[i].percent[2]) : _taxBeneficiary[i].percent[0]);

            if (percent == 0) { continue; }

            uint256 taxAmount = _percentage(amount, percent);

            super._transfer(from, address(this), taxAmount);

            if (_taxBeneficiary[i].account == _dex.pair) {
              _amountForLiquidity += taxAmount;
            } else {
              _taxBeneficiary[i].unclaimed += taxAmount;
              _amountForTaxDistribution += taxAmount;
              _totalTaxUnclaimed += taxAmount;
            }

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