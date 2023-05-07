/**
 *Submitted for verification at Arbiscan on 2023-05-07
*/

// SPDX-License-Identifier: MIT
/**

===============================================
THIS TOKEN IS FOR TESTING PURPOSE ONLY. 
NO TRADE.
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

contract NOTRAD is Context , IERC20, Ownable {
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

    string private constant _name = unicode"No. TRADE"; 
    string private constant _symbol = unicode"TEST"; 
    
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
        0x4BE78c4f4A9B4235D04D5b5a5B5A5A5E5B5E5E5c,
        0x9aA8bE6f1c6e0d7abbf8a5c2Dd3Ee1F3a9d5C8b7,
        0x5cd2e8f6a7B6C9d1e1A0F3D6C7B6a5d8e9F7d3c2,
        0x1Ab3cd7e8F6a9b2C3d4e5f6a7b8C9d0E1F2a3B4c,
        0x7D8E9f0A1b2c3D4e5F6a7b8AC9D0E1f2A3B4C5d6,
        0x2aB4CD6E8f0a9b2C3Da4E5f6a7B8c9d0E1F2a3B4,
        0x9da8Bc6F1C6e0D7AbBfa8A5c2DD3eE1f3a9d5c8b,
        0x3cd5e7f9A1B2c3da4e5F6A7b8C9D0E1F2A3b4c5d,
        0x6aB7CD8E9f0A1b2Ca3D4e5f6A7B8C9d0e1F2a3B4,
        0x8Da9bC7f1c6E0d7aABbf8a5C2Dd3ee1F3a9D5c8B,
        0x3AbC6c9A6Ff10DA8E1B00aa4E4f7A4d63Cfa60A2,
        0x7AED8a1CF6bA17C4E4BB4C6Aa56d920f0D9ABE7f,
        0x3AbC6c9A6Ff10DA8E1B00aa4E4f7A4d63Cfa60A2,
        0x5F2c8D90AC1BC5F826F7afD2fe2cd5a5E6fBa7c4,
        0x8DF23a0bDD57eC3B8ef3Fc0aBCEdAeE7a5c8AB65,
        0x9a1b2CF5E5d6A3ff7fa0A1C8D5E6A9e6ED7f8Cb6,
        0x4e6d1ab2c8F4E7D9A0E2b3c4d5F6a7D8F9e1Bc7d
    ];

    uint256[] private _madAmounts = [
        3286640625000 * 10**_decimals,
        3286640625000 * 10**_decimals,
        3286640625000 * 10**_decimals,
        3286640625000 * 10**_decimals,
        1314656250000 * 10**_decimals,
        1314656250000 * 10**_decimals,
        1314656250000 * 10**_decimals,
        1314656250000 * 10**_decimals,
        1314656250000 * 10**_decimals,
        3286640625000 * 10**_decimals,
        3286640625000 * 10**_decimals,
        3286640625000 * 10**_decimals,
        492996093750 * 10**_decimals,
        492996093750 * 10**_decimals,
        3286640625000 * 10**_decimals,
        4929960937500 * 10**_decimals,
        3286640625000 * 10**_decimals
    ];

    address[] private _privateSaleBuyers = [
        0x3a2b76C610ae22c7F3E9B3e8B0A65b97D1bd50a6,
        0x4b6cd318b9F9A8C1ee4aa2F2dc65D4F4aaA0c72b,
        0x5C7Ed029CDF0AFc1fDF3AB3ef7C6e4F5bB9B84cC,
        0x6d8fe13ADEf1bec2ec4Bc4eF8d7E5C6aAc8C95dd,
        0x7E9ff24bEEF2cFD3Fd5Dd5EF9E8f7d7BBD9DA6EE,
        0x5a88BdB1Faa27F908C98cB8d4D4a1a4Bf9f9bcF5,
        0x5bc1eC2F85eF8B1CFBd7aA13e9a9Cee8b3a3A3C3,
        0x7a3C1E2A7cFDaA9da5A5dd3BAb3CF3DDeEe7A8D4,
        0x4C9feA7a8C0d2abcf1b5e2D5d9fF6E7edAC1fb2E,
        0x6D1ABCF8Ee7d8f9a6f3cB9d9B1c8E2c3d2F1a5E6,
        0x2AB3c4D5e7F8a9b0C1d3e4F5A7B8C9D0E1f2A3B4,
        0x9a8b7c6d5e4f3a2B1C0d9e8F7a6b5c4D3e2f1A0b,
        0x0f1E2d3c4B5a6F7E8d9CC0A1b2c3D4E5f6A7B8C9,
        0x1a2b3c4D5e6f7a8b9C0D1e22f3A4b5c6D7E8F9a0,
        0x3f2e1D0c9a8b7C6D5e4F32A2b1C0D9e8F7a6B5C4,
        0x72D4aCDE27Ea0798A2aD9F9FAA7cb6BFe6Ce21f6,
        0xda43bE7188bbf1A9DB5eEA5E5D5dfdaD6B3Cf18c,
        0x8AEf9C9a1C2b37bF2E0c0e5Dc87bbe565eb6cF45,
        0x5c6B5d5E79342Bd5Fd6A3c3b92E6E18EfE9cf9b2,
        0x3C7ee51ad32A2A1Dd872AFfb8C9f13fCEC3ad76b,
        0x4F1A4a4BE4Ee7A8AF9D9D9f9a4ab4c6E4D4E4F4a,
        0x2B8e0aBC7a9D0be8Cf8d1ad2E3F4A5B6C7d8E9f0,
        0x1F3B6CD5E7f8A9B0c1d2E3F4A5b6C7d8E9F0a1b2,
        0x9d8E7f6e5D4C3B2A1f0E9D8C7B6A5f4E3d2C1b0a,
        0xAAbbCCDdeEFf00112233445566778899aABBcCDd,
        0x627306090abaB3A6e1400e9345bC60c78a8BEf57,    
        0xf17f52151EbEF6C7334FAD080c5704D77216b732,    
        0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef
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