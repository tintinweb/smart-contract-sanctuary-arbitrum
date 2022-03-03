/**
 *Submitted for verification at arbiscan.io on 2022-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// pragma solidity >=0.5.0;

interface IV2Factory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

  function feeTo() external view returns (address);

  function feeToSetter() external view returns (address);

  function getPair(address tokenA, address tokenB) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function allPairsLength() external view returns (uint256);

  function createPair(address tokenA, address tokenB) external returns (address pair);

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;
}

// pragma solidity >=0.5.0;

interface IV2Pair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(
    address indexed sender,
    uint256 amount0In,
    uint256 amount1In,
    uint256 amount0Out,
    uint256 amount1Out,
    address indexed to
  );
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function kLast() external view returns (uint256);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

interface IV2Router01 {
  function factory() external pure returns (address);

  function WETH() external pure returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
}

// pragma solidity >=0.6.2;

interface IRouterV2 is IV2Router01 {
  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external;
}

contract EMAX is Context, Ownable, IERC20 {
  using SafeMath for uint256;
  using Address for address;

  address payable private treasuryWallet = payable(0xfF23A7d437D1a36e47C91A6287F78D04E8D55506); // treasury  Wallet

  uint256 public deadBlocks = 2;
  uint256 public launchedAt;

  mapping(address => uint256) private _balances;
  mapping(address => bool) private _isExcludedFromFee;
  mapping(address => bool) private _isMaxWalletExempt;
  mapping(address => bool) private _isTrusted;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isSniper;
  mapping(address => uint256) public wards;
  mapping(address => uint256) public nonces;

  address DEAD = 0x000000000000000000000000000000000000dEaD;

  uint8 private constant _decimals = 18;

  uint256 private constant MAX = ~uint256(0);
  uint256 public _totalSupply;

  string public constant _name = "EthereumMax";
  string public constant _symbol = "EMAX";
  string public constant version = "1";

  uint256 public _buyLiquidityFee = 10;
  uint256 public _buytreasuryFee = 10;

  uint256 public _sellLiquidityFee = 30;
  uint256 public _selltreasuryFee = 30;

  uint256 public transferFee = 60;

  uint256 private _status;

  uint256 private sellTotalFee = _sellLiquidityFee.add(_selltreasuryFee);

  //0.1
  uint256 public thresholdPercent = 40;
  uint256 public thresholdDivisor = 1000;

  IRouterV2 public RouterV2;
  address public Pair;

  bool inSwap;

  bool public tradingOpen = false;
  bool public zeroBuyTax = true;
  bool private antiBotmode = true;
  bool private autoLiquidate = true;
  bool private shouldManualSend = false;

  uint256 public immutable deploymentChainId;
  bytes32 private immutable _DOMAIN_SEPARATOR;
  bytes32 public constant PERMIT_TYPEHASH =
    keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  // eip-712
  function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
    return
      keccak256(
        abi.encode(
          keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
          ),
          keccak256(bytes(_name)),
          keccak256(bytes(version)),
          chainId,
          address(this)
        )
      );
  }

  function DOMAIN_SEPARATOR() external view returns (bytes32) {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    return chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
  }

  modifier onlyL2Gateway() {
    require(wards[msg.sender] == 1, "NOT_GATEWAY");
    _;
  }

  function rely(address usr) external onlyL2Gateway {
    _isExcludedFromFee[usr];
    wards[usr] = 1;
    emit Rely(usr);
  }

  function deny(address usr) external onlyOwner {
    wards[usr] = 0;
    emit Deny(usr);
  }

  modifier lockTheSwap() {
    require(inSwap != true, "ReentrancyGuard: reentrant call");
    inSwap = true;
    _;
    inSwap = false;
  }

  event Rely(address indexed usr);
  event Deny(address indexed usr);
  event SwapETHForTokens(uint256 indexed amountIn, address[] indexed path);
  event SwapTokensForETH(uint256 indexed amountIn, address[] indexed path);
  event OpenTrading(uint256 indexed _block, bool indexed _state);
  event SetZeroBuyTax(bool indexed _state);
  event SetAntiBotmode(bool indexed _state);
  event NewRouter(address indexed _newRouter);
  event ExcludeMultiple(address[] indexed _accounts, bool indexed _state);
  event ExcludeFromFee(address indexed _acount, bool indexed _state);
  event IncludeInFee(address indexed _acount, bool indexed _state);
  event SetWallet(address indexed _oldFeeWallet, address indexed _newFeeWallet);
  event Manage_Snipers(address[] indexed _accounts, bool indexed _state);
  event Manage_trusted(address[] indexed _accounts, bool indexed _state);
  event WithDrawLeftoverETH(address indexed _account, bool indexed _state);
  event WithdrawStuck(uint256 indexed _amount, address indexed _acount);
  event ToggelManualSend(bool indexed _state);
  event SetZeroBuyTaxmode(bool indexed _status);
  event SetMaxWallet(uint256 indexed _maxWallet);
  event SetNewRouter(address _newRouter);
  event SetSwapSettings(uint256 indexed _thresholdPercent, uint256 indexed thresholdDivisor);
  event SetTaxBuy(
    uint256 indexed _bLiquidity,
    uint256 indexed _btreasuryFee,
    uint256 indexed _transferFee
  );
  event SetTaxSell(
    uint256 indexed _sLiquidiy,
    uint256 indexed _streasuryFee,
    uint256 indexed _transferFee
  );

  constructor() public {
    wards[msg.sender] = 1;
    emit Rely(msg.sender);
    //arbitrum 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
    //l1 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D

    IRouterV2 _routerV2 = IRouterV2(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    Pair = IV2Factory(_routerV2.factory()).createPair(address(this), _routerV2.WETH());

    RouterV2 = _routerV2;

    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    deploymentChainId = chainId;
    _DOMAIN_SEPARATOR = _calculateDomainSeparator(chainId);

    _isExcludedFromFee[msg.sender] = true;
    _isExcludedFromFee[address(this)] = true;
    _isTrusted[msg.sender] = true;
    _isTrusted[Pair] = true;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _balances[account];
  }

  function name() external pure returns (string memory) {
    return _name;
  }

  function symbol() external pure returns (string memory) {
    return _symbol;
  }

  function decimals() external pure returns (uint8) {
    return _decimals;
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(subtractedValue, "Emax/insufficient-allowance")
    );
    return true;
  }

  function totalSupply() external view override returns (uint256) {
    return _totalSupply;
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(amount > 0, "Transfer amount must be greater than zero");
    require(!_isSniper[to], "No Snippers");
    require(!_isSniper[from], "No Snippers");
    if (from != owner() && to != owner()) require(tradingOpen, "Trading not enabled."); //transfers disabled before openTrading

    uint256 currenttotalFee;
    // transfer tax
    if (!(from == Pair || to == Pair) && !(_isExcludedFromFee[from] || _isExcludedFromFee[to])) {
      //transfer
      currenttotalFee = transferFee;
    }

    if (to == Pair) {
      //sell
      currenttotalFee = _sellLiquidityFee.add(_selltreasuryFee);
    }

    //antibot - first X blocks
    if (launchedAt > 0 && (launchedAt + deadBlocks) > block.number) {
      _isSniper[to] = true;
    }

    //high slippage bot txns
    if (
      launchedAt > 0 && from != owner() && block.number <= (launchedAt + deadBlocks) && antiBotmode
    ) {
      currenttotalFee = 900; //90%
    }

    if (from == Pair) {
      //buy
      currenttotalFee = _buyLiquidityFee.add(_buytreasuryFee);
    }

    if (zeroBuyTax) {
      if (from == Pair) {
        //buys
        currenttotalFee = 0;
      }
    }

    if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || from == owner() || to == owner()) {
      //privileged
      currenttotalFee = 0;
    }

    //sell
    if ((!inSwap && tradingOpen && to == Pair)) {
      uint256 contractTokenBalance = balanceOf(address(this));
      uint256 swapThreshold = curentSwapThreshold();
      if ((contractTokenBalance >= swapThreshold) && autoLiquidate) {
        swapTokens();
      }
      if ((contractTokenBalance >= swapThreshold) && !autoLiquidate) {
        IERC20(address(this)).transfer(treasuryWallet, contractTokenBalance);
      }
    }

    _transferStandard(from, to, amount, currenttotalFee);
  }

  function swapTokens() private lockTheSwap {
    uint256 amountToLiquify = 0;
    if (_sellLiquidityFee > 0) {
      amountToLiquify = curentSwapThreshold().mul(_sellLiquidityFee).div(sellTotalFee).div(2);
    }

    uint256 amountToSwap = curentSwapThreshold().sub(amountToLiquify);

    swapTokensForEth(amountToSwap);
    if (!shouldManualSend) {
      sendEth(amountToLiquify);
    }
  }

  function sendEth(uint256 amountToLiquify) private {
    uint256 amountETH = address(this).balance;

    uint256 totalETHFee = sellTotalFee.sub(_sellLiquidityFee.div(2));

    if (sellTotalFee > 0) {
      uint256 amountETHLiquidity = amountETH.mul(_sellLiquidityFee).div(totalETHFee).div(2);

      uint256 amountETHtreasury = amountETH.mul(_selltreasuryFee).div(totalETHFee);
      //Send to treasury wallet and liquidity
      if (amountETH > 0) {
        treasuryWallet.transfer(amountETHtreasury);
        emit Transfer(address(this), treasuryWallet, amountETHtreasury);
      }
      if (amountToLiquify > 0) {
        addLiquidity(amountToLiquify, amountETHLiquidity);
      }
    } else {
      if (amountETH > 0) {
        treasuryWallet.transfer(amountETH);
        emit Transfer(address(this), treasuryWallet, amountETH);
      }
    }
  }

  function swapTokensForEth(uint256 tokenAmount) private {
    // generate the pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = RouterV2.WETH();

    _approve(address(this), address(RouterV2), tokenAmount);
    uint256[] memory amount = RouterV2.getAmountsOut(tokenAmount, path);
    uint256 amountMin = amount[1].sub(amount[1].div(50));

    // make the swap
    RouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      amountMin, // accept any amount of ETH
      path,
      address(this), // The contract
      block.timestamp
    );

    emit SwapTokensForETH(tokenAmount, path);
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(RouterV2), tokenAmount);

    // add the liquidity
    RouterV2.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      address(this),
      block.timestamp
    );
  }

  function _sendTransfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual {
    require(sender != address(0), "ERC20: transfer from the zero address");
    require(recipient != address(0), "ERC20: transfer to the zero address");

    uint256 senderBalance = _balances[sender];
    require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
    _balances[sender] = senderBalance.sub(amount);

    _balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount,
    uint256 curentTotalFee
  ) private {
    if (curentTotalFee == 0) {
      _sendTransfer(sender, recipient, tAmount);
    } else {
      uint256 calcualatedFee = tAmount.mul(curentTotalFee).div(10**3);
      uint256 amountForRecipient = tAmount.sub(calcualatedFee);
      _sendTransfer(sender, recipient, amountForRecipient);
      _sendTransfer(sender, address(this), calcualatedFee);
    }
  }

  function curentSwapThreshold() public view returns (uint256 swapThreshold) {
    if (_totalSupply == 0) {
      return 0;
    }
    return (balanceOf(Pair).mul(thresholdPercent).div(thresholdDivisor)); //swap % based off pooled emax in pair
  }

  function transferToAddressETH(address payable recipient, uint256 amount) private {
    recipient.transfer(amount);
    emit Transfer(address(this), recipient, amount);
  }

  function isSniper(address account) external view returns (bool) {
    return _isSniper[account];
  }

  function mint(address to, uint256 value) external onlyL2Gateway {
    require(to != address(0) && to != address(this), "Emax/invalid-address");
    _balances[to] = _balances[to] + value; // note: we don't need an overflow check here b/c balanceOf[to] <= _totalSupply and there is an overflow check below
    _totalSupply = _totalSupply.add(value);
    emit Transfer(address(0), to, value);
  }

  function burn(address from, uint256 value) external {
    uint256 balance = _balances[from];
    require(balance >= value, "Emax/insufficient-balance");

    if (from != msg.sender && wards[msg.sender] != 1) {
      uint256 allowed = _allowances[from][msg.sender];
      if (allowed != type(uint256).max) {
        require(allowed >= value, "Emax/insufficient-allowance");

        _allowances[from][msg.sender] = allowed - value;
      }
    }

    _balances[from] = balance - value; // note: we don't need overflow checks b/c require(balance >= value) and balance <= totalSupply
    _totalSupply = _totalSupply - value;

    emit Transfer(from, address(0), value);
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(block.timestamp <= deadline, "Emax/permit-expired");

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    bytes32 digest = keccak256(
      abi.encodePacked(
        "\x19\x01",
        chainId == deploymentChainId ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId),
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
      )
    );

    require(owner != address(0) && owner == ecrecover(digest, v, r, s), "Emax/invalid-permit");

    _allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function openTrading(bool state, uint256 _deadBlocks) external onlyOwner {
    tradingOpen = state;
    if (tradingOpen && launchedAt == 0) {
      launchedAt = block.number;
      deadBlocks = _deadBlocks;
    }
    emit OpenTrading(launchedAt, tradingOpen);
  }

  function setZeroBuyTax(bool state) external onlyOwner {
    zeroBuyTax = state;
    emit SetZeroBuyTaxmode(zeroBuyTax);
  }

  function setAntiBotmode(bool state) external onlyOwner {
    antiBotmode = state;
    emit SetAntiBotmode(antiBotmode);
  }

  function setNewRouter(address newRouter) external onlyOwner {
    require(newRouter != address(0));
    IRouterV2 _newRouter = IRouterV2(newRouter);
    address get_pair = IV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
    if (get_pair == address(0)) {
      Pair = IV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
    } else {
      Pair = get_pair;
    }
    RouterV2 = _newRouter;

    emit SetNewRouter(newRouter);
  }

  function excludeFromFee(address account) external onlyOwner {
    _isExcludedFromFee[account] = true;
    emit ExcludeFromFee(account, true);
  }

  function toggelManualSend(bool _state) external onlyOwner {
    shouldManualSend = _state; //if true eth stays on contract
    emit ToggelManualSend(shouldManualSend);
  }

  function excludeMultiple(address[] calldata addresses) external onlyOwner {
    for (uint256 i; i < addresses.length; ++i) {
      _isExcludedFromFee[addresses[i]] = true;
    }
    emit ExcludeMultiple(addresses, true);
  }

  function includeInFee(address account) external onlyOwner {
    require(account != address(0));
    _isExcludedFromFee[account] = false;
    emit IncludeInFee(account, false);
  }

  function settreasuryWallet(address _treasuryWallet) external onlyOwner {
    require(_treasuryWallet != address(0));
    address oldWallet = treasuryWallet;
    treasuryWallet = payable(_treasuryWallet);
    emit SetWallet(oldWallet, treasuryWallet);
  }

  function manage_Snipers(
    address[] calldata addresses,
    bool status,
    bool _override
  ) external onlyOwner {
    for (uint256 i; i < addresses.length; ++i) {
      require(!_isTrusted[addresses[i]] || _override, "account is already trusted use overide");
      _isSniper[addresses[i]] = status;
    }
    emit Manage_Snipers(addresses, status);
  }

  function manage_trusted(address[] calldata addresses, bool status) external onlyOwner {
    for (uint256 i; i < addresses.length; ++i) {
      _isTrusted[addresses[i]] = status;
    }
    emit Manage_trusted(addresses, status);
  }

  function withDrawLeftoverETH(address payable receipient) external onlyOwner {
    (bool os, ) = payable(receipient).call{value: address(this).balance}("");
    require(os);

    emit WithDrawLeftoverETH(receipient, os);
  }

  function withdrawStuckTokens(IERC20 token, address to) external onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    token.transfer(to, balance);

    emit Transfer(address(this), to, balance);
  }

  function setSwapSettings(uint256 _thresholdPercent, uint256 _thresholdDivisor)
    external
    onlyOwner
  {
    thresholdDivisor = _thresholdDivisor;
    thresholdPercent = _thresholdPercent;

    emit SetSwapSettings(thresholdPercent, thresholdDivisor);
  }

  function setTaxesBuy(
    uint256 _liquidityFee,
    uint256 _treasuryFee,
    uint256 _transferFee
  ) external onlyOwner {
    _buyLiquidityFee = _liquidityFee;
    _buytreasuryFee = _treasuryFee;
    transferFee = _transferFee;

    emit SetTaxBuy(_buyLiquidityFee, _buytreasuryFee, transferFee);
  }

  function setTaxesSell(
    uint256 _liquidityFee,
    uint256 _treasuryFee,
    uint256 _transferFee
  ) external onlyOwner {
    _sellLiquidityFee = _liquidityFee;
    _selltreasuryFee = _treasuryFee;
    transferFee = _transferFee;

    sellTotalFee = _sellLiquidityFee.add(_selltreasuryFee);

    emit SetTaxSell(_sellLiquidityFee, _selltreasuryFee, transferFee);
  }

  //to recieve ETH from RouterV2 when swaping
  receive() external payable {}
}