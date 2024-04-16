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

abstract contract CF_Common {
  string internal constant _version = "1.0.4";

  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;

  bool internal immutable _initialized;

  uint8 internal immutable _decimals;
  uint24 internal constant _denominator = 1000;
  uint32 internal _tradingEnabled;
  uint256 internal _totalSupply;

  struct Renounced {
    bool DEXRouterV2;
  }

  struct DEXRouterV2 {
    address router;
    address pair;
    address token0;
    address WETH;
  }

  Renounced internal _renounced;
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

  function _setDEXRouterV2(address router, address token0) internal returns (address) {
    IDEXRouterV2 _router = IDEXRouterV2(router);
    IDEXFactoryV2 factory = IDEXFactoryV2(_router.factory());
    address pair = factory.createPair(address(this), token0);

    _dex = DEXRouterV2(router, pair, token0, _router.WETH());

    emit SetDEXRouterV2(router, _dex.pair);

    return _dex.pair;
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

    _tradingEnabled = _timestamp();

    emit TradingEnabled();
  }
}

/*

  TEST

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";
import "./CF_DEXRouterV2.sol";

contract ChainFactory_ERC20 is CF_Common, CF_Ownable, CF_ERC20, CF_DEXRouterV2 {
  constructor() {
    _name = unicode"TEST";
    _symbol = unicode"TEST";
    _decimals = 18;
    _totalSupply = 10000000000000000000000000; // 10,000,000 TEST
    _transferOwnership(0x2d8250e6767EE656fbfB7E5c63C89706220dD863);
    _transferInitialSupply(0x2d8250e6767EE656fbfB7E5c63C89706220dD863, 100000); // 100%
    _setDEXRouterV2(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

    _initialized = true;
  }

  function _transferInitialSupply(address account, uint24 percent) private {
    require(!_initialized);

    uint256 amount = _percentage(_totalSupply, uint256(percent));

    _balance[account] = amount;

    emit Transfer(address(0), account, amount);
  }

  /// @notice Returns a list specifying the renounce status of each feature
  function renounced() external view returns (bool DEXRouterV2) {
    return (_renounced.DEXRouterV2);
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