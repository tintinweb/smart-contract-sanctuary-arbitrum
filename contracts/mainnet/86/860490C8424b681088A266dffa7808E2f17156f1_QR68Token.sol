// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./BEP20Detailed.sol";
import "./BEP20_nopause.sol";
import "./IUniswap.sol";
import "./SafeMathInt.sol";

contract QR68Token is BEP20Detailed, BEP20 {
  using SafeMath for uint256;
  using SafeMathInt for int256;
  mapping(address => bool) public liquidityPool;
  mapping(address => bool) public whitelistTax;

  uint8 public buyTax;
  uint8 public sellTax; 
  uint8 public transferTax;
  uint256 private taxAmount;
  address public marketingPool;
  address public Treasury;
  address public Pool2;
  uint8 public mktTaxPercent;
  uint8 public TreasuryTaxPercent;
  uint8 private Pool2TaxPercent;

  IUniswapV2Router02 public uniswapV2Router;
  address public  uniswapV2Pair;

  uint256 public swapTokensAtAmount;
  uint256 public swapTokensMaxAmount;
  bool public swapping;
  bool public enableTax;

  event changeTax(bool _enableTax, uint8 _sellTax, uint8 _buyTax, uint8 _transferTax);
  event changeTaxPercent(uint8 _mktTaxPercent,uint8 _TreasuryTaxPercent,uint8 _Pool2TaxPercent);
  event changeLiquidityPoolStatus(address lpAddress, bool status);
  event changeMarketingPool(address marketingPool);
  event changePool2(address Pool2);
  event changeTreasury(address Treasury);
  event changeWhitelistTax(address _address, bool status);  
  event UpdateUniswapV2Router(address indexed newAddress,address indexed oldAddress);
  
 
  constructor() payable BEP20Detailed("QR68", "QR68", 18) {
    uint256 totalTokens = 10000000 * 10**uint256(decimals());
    _mint(msg.sender, totalTokens);
    sellTax = 1;
    buyTax = 1;
    transferTax = 0;
    enableTax = true;
    marketingPool = 0x1b69f9aCb045Ad62d06bdB9b0cE5D838264fB177;
    Treasury = 0x1dbA4Ccef8c7CDc9b4187CC286C13b31933416f7;
    Pool2 = 0xE1aFaf37b323d8856B37416f88A1f89478c6f164;
    mktTaxPercent = 100;
    TreasuryTaxPercent = 0;
    Pool2TaxPercent = 0;

    whitelistTax[address(this)] = true;
    whitelistTax[marketingPool] = true;
    whitelistTax[Pool2] = true;
    whitelistTax[Treasury] = true;
    whitelistTax[owner()] = true;
    whitelistTax[address(0)] = true;

    //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);//BNB
    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);//SHUSHI On Arbitrum
    address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
    uniswapV2Router = _uniswapV2Router;
    uniswapV2Pair   = _uniswapV2Pair;
    _approve(address(this), address(uniswapV2Router), ~uint256(0));
    swapTokensAtAmount = totalTokens*2/10**6; 
    swapTokensMaxAmount = totalTokens*2/10**4; 

    liquidityPool[uniswapV2Pair] = true;
  }

  

  //update fee
  function setLiquidityPoolStatus(address _lpAddress, bool _status) external onlyOwner {
    liquidityPool[_lpAddress] = _status;
    emit changeLiquidityPoolStatus(_lpAddress, _status);
  }

  function setMarketingPool(address _marketingPool) external onlyOwner {
    marketingPool = _marketingPool;
    whitelistTax[marketingPool] = true;
    emit changeMarketingPool(_marketingPool);
  }  
  function setPool2(address _Pool2) external onlyOwner {
    Pool2 = _Pool2;
    whitelistTax[Pool2] = true;
    emit changePool2(_Pool2);
  }  
  function setTreasury(address _Treasury) external onlyOwner {
    Treasury = _Treasury;
    whitelistTax[Treasury] = true;
    emit changeTreasury(_Treasury);
  }  
  function setTaxes(bool _enableTax, uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) external onlyOwner {
    require(_sellTax < 9);
    require(_buyTax < 9);
    require(_transferTax < 9);
    enableTax = _enableTax;
    sellTax = _sellTax;
    buyTax = _buyTax;
    transferTax = _transferTax;
    emit changeTax(_enableTax,_sellTax,_buyTax,_transferTax);
  }
  function setTaxPercent(uint8 _mktTaxPercent, uint8 _TreasuryTaxPercent,  uint8 _Pool2TaxPercent) external onlyOwner {
    require(_mktTaxPercent +  _TreasuryTaxPercent + _Pool2TaxPercent == 100);
    mktTaxPercent = _mktTaxPercent;
    TreasuryTaxPercent = _TreasuryTaxPercent;
    Pool2TaxPercent = _Pool2TaxPercent;
    emit changeTaxPercent(_mktTaxPercent,_TreasuryTaxPercent,_Pool2TaxPercent);
  }

  function setWhitelist(address _address, bool _status) external onlyOwner {
    whitelistTax[_address] = _status;
    emit changeWhitelistTax(_address, _status);
  }
  function getTaxes() external view returns (uint8 _sellTax, uint8 _buyTax, uint8 _transferTax) {
    return (sellTax, buyTax, transferTax);
  } 
  function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
    swapTokensAtAmount = amount;
  }
  function setSwapTokensMaxAmount(uint256 amount) external onlyOwner {
    swapTokensMaxAmount = amount;
  }
  function sentT2marketingPool() external onlyOwner {
    uint256 contractTokenBalance = balanceOf(address(this));
    if(contractTokenBalance>0){
      super._transfer(address(this), marketingPool, contractTokenBalance);
    }
  }
  function sentT2Pool2token(address tokenaddress) external onlyOwner {
    uint256 newBalance = IBEP20(tokenaddress).balanceOf(address(this));
    if(newBalance>0){
      IBEP20(tokenaddress).transfer(Pool2, newBalance);
    }
  }
  function sentT2Pool2BNB() external onlyOwner {
    uint256 newBalance = address(this).balance;
    if(newBalance>0){
      payable(Pool2).transfer(newBalance);
    }
  }

  function _transfer(address sender, address receiver, uint256 amount) internal virtual override {
    if (amount == 0) {
        super._transfer(sender, receiver, 0);
        return;
    }

    if(enableTax && !whitelistTax[sender] && !whitelistTax[receiver]){
      //swap
      uint256 contractTokenBalance = balanceOf(address(this));
      bool canSwap = contractTokenBalance >= swapTokensAtAmount;
      if ( canSwap && !swapping && sender != owner() && receiver != owner() ) {
          if(contractTokenBalance > swapTokensMaxAmount){
            contractTokenBalance = swapTokensMaxAmount;
          }
          swapping = true;
          swapAndSendToFee(contractTokenBalance);
          swapping = false;
      }

      if(liquidityPool[sender] == true) {
        //It's an LP Pair and it's a buy
        taxAmount = (amount * buyTax) / 100;
      } else if(liquidityPool[receiver] == true) {      
        //It's an LP Pair and it's a sell
        taxAmount = (amount * sellTax) / 100;
      } else {
        taxAmount = (amount * transferTax) / 100;
      }
      
      if(taxAmount > 0) {
        uint256 mktTax = taxAmount.mul(mktTaxPercent).div(100);
        uint256 TreasuryTax = taxAmount.mul(TreasuryTaxPercent).div(100);
        uint256 Pool2Tax = taxAmount - mktTax - TreasuryTax;
        if(mktTax>0){
          super._transfer(sender, marketingPool, mktTax);
        }
        if(TreasuryTax>0){
          super._transfer(sender, Treasury, TreasuryTax);
        }
        if(Pool2Tax>0){
          super._transfer(sender, address(this) , Pool2Tax);
        }
      }    
      super._transfer(sender, receiver, amount - taxAmount);
    }else{
      super._transfer(sender, receiver, amount);
    }
  }

  function swapAndSendToFee(uint256 tokens) private {
    swapTokensForEth(tokens);
    uint256 newBalance = address(this).balance;
    if(newBalance>0){
      payable(Pool2).transfer(newBalance);
    }
  }

  function swapTokensForEth(uint256 tokenAmount) private {
      // generate the uniswap pair path of token -> weth
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapV2Router.WETH();
      // make the swap
      try
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        )
      {} catch {}
  }

  //common
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  receive() external payable {}
}