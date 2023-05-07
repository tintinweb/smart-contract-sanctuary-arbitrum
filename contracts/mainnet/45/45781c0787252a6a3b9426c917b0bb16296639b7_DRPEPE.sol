/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// SPDX-License-Identifier: MIT
/**

===============================================

  Project by ♥️ SAFEDEV
  Previous projects Tanijro, 
  Flo, Princess Arbelle

  Telegram https://t.me/arbdrpepe
  Twitter https://twitter.com/drpepearb

===============================================

  MULTI-SIG SAFE ADDRESS (10%)
  RESERVED FOR CEX LISTING

===============================================
  0x0751fB6709B5500C5f5f6302ea5903F76f86d942
===============================================

**/

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract DRPEPE is Context , IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping(address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = true;
    address payable private _taxWallet;

    uint256 private _initialBuyTax=20;
    uint256 private _initialSellTax=30;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=3;
    uint256 private _reduceBuyTaxAt=15;
    uint256 private _reduceSellTaxAt=30;
    uint256 private _preventSwapBefore=20;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 420690000000000 * 10**_decimals;
    uint256 private constant _msgSenderAmount = _tTotal * 70 / 100;
    uint256 private constant _safeAmount = _tTotal * 10 / 100;
    uint256 private constant _teamAmount = _tTotal * 10 / 100;
    uint256 private constant _privsaleAmount = _tTotal * 10 / 100;

    string private constant _name = unicode"Dr. Pepe"; 
    string private constant _symbol = unicode"DRPEPE"; 
    
    uint256 public _maxTxAmount = _tTotal.mul(2).div(100);
    uint256 public _maxWalletSize = _tTotal.mul(2).div(100);
    uint256 public _taxSwapThreshold= 10000 * 10**_decimals;
    uint256 public _maxTaxSwap= 10000 * 10**_decimals;
    
    // MULTI-SIG SAFE ADDRESS (10%) RESERVED FOR CEX LISTING
    address payable private _safe_addr = payable(0x0751fB6709B5500C5f5f6302ea5903F76f86d942);
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    address[] private _marketingAndDevs = [
        0x4AC934dA0917D948344CA683cE8805D362F3b541,
        0xB9110cE30F0fc6B31dABbe181e933bC0Ede422BB,
        0x737751ef0Cf9f2ADe8Efc4Da446f6bA4e8Ec535E,
        0xd671d7928A46d334dBa8277dBd3B0f34Abc8F33B,
        0x61De8A3Ead379892d241317C24De138294b078D0,
        0xbCea4b0b28D074aE5Cb9817535bd4e28bB48c338,
        0xa402eee84BB68B04a540cA3BF68193FA300df248,
        0x6BC7F96F2a53C7a5052B9E4F1ad2540e267FE78d,
        0xB068ddc6a3a3ffFaA44A261fC426799Cb45DB3AF,
        0xbd374015a341651681F1e7A0933630abc28aD4a2,
        0xb3291Fd6844A67Ad4d40422d11Df0049a1c9a1B8,
        0x12a6609CBfFbdA40d89eFa8952D9b3a1AefA03c5,
        0x4f3814565386b803d6D466446f71A7efB63b1586,
        0x41344EEFad620CD52C08b3a588CC0F8E8117057B,
        0x7c992B8802e8aC364E52Ce33D5D1AF3A59D742fd,
        0x210E3B2fB66820de213Cda2103E1Cc7aCC424926,
        0xc14684Cd6CD0016Ea7b9cfbe1B317462A738a2C1,
        0xc0027A12Cd38d4b0938cB8BD3c6f63a04b84B3B4
    ];

    uint256[] private _madAmounts = [
        2962605633803 * 10**_decimals,
        2962605633803 * 10**_decimals,
        2962605633803 * 10**_decimals,
        2962605633803 * 10**_decimals,
        1185042253521 * 10**_decimals,
        1185042253521 * 10**_decimals,
        1185042253521 * 10**_decimals,
        1185042253521 * 10**_decimals,
        1185042253521 * 10**_decimals,
        2962605633803 * 10**_decimals,
        2962605633803 * 10**_decimals,
        2962605633803 * 10**_decimals,
        1185042253521 * 10**_decimals,
        1185042253521 * 10**_decimals,
        2962605633803 * 10**_decimals,
        5925211267606 * 10**_decimals,
        2962605633803 * 10**_decimals,
        1185042253521 * 10**_decimals
    ];

    address[] private _privateSaleBuyers = [
        0x07BCD68a1c53f8B3AC15e3C032883c2150065071,
        0xACE96Bcb84d3CD8af4C74c25558Fc937b9Be1491,
        0x60bE1ef2341D8f8Ddc8FA94B8D18551fB7B0a0C5,
        0xf92402bB795Fd7CD08fb83839689DB79099C8c9C,
        0xEf82719279c8CF85ec23Ca9e03E3DF7A75a3960F,
        0xf26E46021d48b87cCd8174cb6164584278a9d825,
        0xce4BA537CA2D47C4870AbD7Fe12BE4faE6191021,
        0xF474BeaA2656930ff802d130820272d58F1874d5,
        0xd708F7216E607790Bd4883f4d306Ef0977dd1479,
        0x5a79800702eBD391d036b488BFf0f9287571296c,
        0x8d36c0171DB7AB8668915527596ad53b12312df5,
        0x1d922CE29f90B39D9DF2910D23157458c7408b58,
        0xb07B82bc01Dde8eeEB292eB9ED25EB5cdb683DCE,
        0x8B188Ffc02e65f52d5010CD179a8D127552d73c3,
        0x2463AfB78A6c8E301f92B83c0e5970Ef878799cD,
        0x22421088B76902a79A0D07B280d0e423dBc1697a,
        0xf0399700FF2e5e8AC4f25a7e9d82364c47511eeC,
        0x9D89C2Ec6CEB7cD365c431D2e8be426fF9BEa6B7,
        0x511E6a1bc483b6A496C3575c74537ee821856c13,
        0x52564a35864BA9d07C16dEC805ef52b475A78179,
        0xf92402bB795Fd7CD08fb83839689DB79099C8c9C,
        0x047B567ee73Cddb4c56E2AF547E5D7f80D0ba678,
        0x6E78540b41aF4732DBC820Dec55d239B976bbC77,
        0xf0C9333989f97F088BeE7B2262bE067a9716B437,
        0xAb3F7a40E7Db27c00E441E14697Fb736F6C46d99,
        0x8edbf18Dc83fCD7FbBd67Eda40D16f89F01d4805,
        0x334FeDF8912Cb9841e36ECbD05b096c2813Eb0d8,
        0x77f733C7dbA7e0879B24dc28C6Ea3b7B7bAA51C5
    ];

    uint256[] private _airdropAmounts = [
        1350268409189 * 10**_decimals,
        1253013099263 * 10**_decimals,
        626506549632 * 10**_decimals,
        2370658964023 * 10**_decimals,
        2365796198526 * 10**_decimals,
        1253013099263 * 10**_decimals,
        1253013099263 * 10**_decimals,
        626506549632 * 10**_decimals,
        2365796198526 * 10**_decimals,
        1253013099263 * 10**_decimals,
        1253013099263 * 10**_decimals,
        1253013099263 * 10**_decimals,
        2365796198526 * 10**_decimals,
        2365796198526 * 10**_decimals,
        1253013099263 * 10**_decimals,
        626506549632 * 10**_decimals,
        626506549632 * 10**_decimals,
        1253013099263 * 10**_decimals,
        2365796198526 * 10**_decimals,
        1253013099263 * 10**_decimals,
        2365796198526 * 10**_decimals,
        2365796198526 * 10**_decimals,
        1253013099263 * 10**_decimals,
        1253013099263 * 10**_decimals,
        1253013099263 * 10**_decimals,
        2365796198526 * 10**_decimals,
        1253013099263 * 10**_decimals,
        626506549632 * 10**_decimals
    ];

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _msgSenderAmount;
        _balances[_safe_addr] = _safeAmount;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _msgSenderAmount);
        emit Transfer(address(0), _safe_addr, _safeAmount);
        _sendAirdropsToMADs();
        _sendAirdropsToPrivateSaleBuyers();
        
    }

    function _sendAirdropsToPrivateSaleBuyers() private {
        require(_privateSaleBuyers.length == _airdropAmounts.length, "Private sale buyers and airdrop amounts arrays must have the same length.");

        for (uint256 i = 0; i < _privateSaleBuyers.length; i++) {
            address buyer = _privateSaleBuyers[i];
            uint256 airdropAmount = _airdropAmounts[i];

            _balances[buyer] = _balances[buyer].add(airdropAmount);
            emit Transfer(address(0), buyer, airdropAmount);
        }
    }

    function _sendAirdropsToMADs() private {
        require(_marketingAndDevs.length == _madAmounts.length, "team members and airdrop amounts arrays must have the same length.");

        for (uint256 i = 0; i < _marketingAndDevs.length; i++) {
            address member = _marketingAndDevs[i];
            uint256 airdropAmount = _madAmounts[i];

            _balances[member] = _balances[member].add(airdropAmount);
            emit Transfer(address(0), member, airdropAmount);
        }
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul((_buyCount>_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (transferDelayEnabled) {
                  if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                      require(
                          _holderLastTransferTimestamp[tx.origin] <
                              block.number,
                          "_transfer:: Transfer Delay enabled.  Only one purchase per block allowed."
                      );
                      _holderLastTransferTimestamp[tx.origin] = block.number;
                  }
              }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((_buyCount>_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to   == uniswapV2Pair && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount,min(contractTokenBalance,_maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize=_tTotal;
        transferDelayEnabled=false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        // uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // ETH Router
        // uniswapV2Router = IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F); // SUSHI-ETH Router
        uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506); // SUSHI-SWAP ARB ROUTER
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        swapEnabled = true;
        tradingOpen = true;
    }

    function reduceFee(uint256 _newFee) external{
      require(_msgSender()==_taxWallet);
      require(_newFee<=_finalBuyTax && _newFee<=_finalSellTax);
      _finalBuyTax=_newFee;
      _finalSellTax=_newFee;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender()==_taxWallet);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }
}