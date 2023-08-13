/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

//  Created By: PandaTool
//  Website: https://PandaTool.org
//  Telegram: https://t.me/PandaTool
//  The Best Tool for Token Management

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
   function decimals() external view returns (uint256);

   function symbol() external view returns (string memory);

   function name() external view returns (string memory);

   function totalSupply() external view returns (uint256);

   function balanceOf(address who) external view returns (uint);

   function transfer(
       address recipient,
       uint256 amount
   ) external returns (bool);

   function allowance(
       address owner,
       address spender
   ) external view returns (uint256);

   function approve(address _spender, uint _value) external;

   function transferFrom(address _from, address _to, uint _value) external ;

   event Transfer(address indexed from, address indexed to, uint256 value);
   event Approval(
       address indexed owner,
       address indexed spender,
       uint256 value
   );
}

interface ISwapRouter {
   function factory() external pure returns (address);

   function WETH() external pure returns (address);

   function swapExactTokensForTokensSupportingFeeOnTransferTokens(
       uint256 amountIn,
       uint256 amountOutMin,
       address[] calldata path,
       address to,
       uint256 deadline
   ) external;

   function swapExactTokensForETHSupportingFeeOnTransferTokens(
       uint256 amountIn,
       uint256 amountOutMin,
       address[] calldata path,
       address to,
       uint256 deadline
   ) external;

   function addLiquidity(
       address tokenA,
       address tokenB,
       uint256 amountADesired,
       uint256 amountBDesired,
       uint256 amountAMin,
       uint256 amountBMin,
       address to,
       uint256 deadline
   ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
       returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

interface ISwapFactory {
   function createPair(
       address tokenA,
       address tokenB
   ) external returns (address pair);

   function getPair(
       address tokenA,
       address tokenB
   ) external view returns (address pair);
}

interface ISwapPair {
   function getReserves()
       external
       view
       returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

   function token0() external view returns (address);

   function balanceOf(address account) external view returns (uint256);

   function totalSupply() external view returns (uint256);
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
}

contract PandaToken is IERC20 {
   using SafeMath for uint256;

   mapping(address => uint256) public _rOwned;
   mapping(address => mapping(address => uint256)) private _allowances;

   address public fundAddress;

   string private _name;
   string private _symbol;
   uint256 private _decimals;

   uint256 public _tTotal;
   uint256 public _rTotal;
   uint256 public _tFeeTotal;

   mapping(address => bool) public _feeWhiteList;



   ISwapRouter public _swapRouter;
   address public currency;
   mapping(address => bool) public _swapPairList;


   uint256 private constant MAX = ~uint256(0);

   uint256 public _buyFundFee;
   uint256 public _buyLPFee;
   uint256 public _buyReflectFee;
   uint256 public buy_burnFee;
   uint256 public _sellFundFee;
   uint256 public _sellLPFee;
   uint256 public _sellReflectFee;
   uint256 public sell_burnFee;

   bool public airdropEnable;
   uint256 public airdropNumbs;

   address public _mainPair;

   constructor(
       string[] memory stringParams,
       address[] memory addressParams,
       uint256[] memory numberParams,
       bool[] memory boolParams
   ) {
       _name = stringParams[0];
       _symbol = stringParams[1];
       _decimals = numberParams[0];
       _tTotal = numberParams[1];
       _rTotal = (MAX - (MAX % _tTotal));


       fundAddress = addressParams[0];
       currency = addressParams[1];
       _swapRouter = ISwapRouter(addressParams[2]);
       address ReceiveAddress = addressParams[3];


       IERC20(currency).approve(address(_swapRouter), MAX);

       _allowances[address(this)][address(_swapRouter)] = MAX;

       ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
       _mainPair = swapFactory.createPair(address(this), currency);

       _swapPairList[_mainPair] = true;

       _buyFundFee = numberParams[2];
       _buyLPFee = numberParams[3];
       _buyReflectFee = numberParams[4];
       buy_burnFee = numberParams[5];

       _sellFundFee = numberParams[6];
       _sellLPFee = numberParams[7];
       _sellReflectFee = numberParams[8];

       sell_burnFee = numberParams[9];

       require(
           _buyFundFee + _buyLPFee + _buyReflectFee + buy_burnFee < 2500 && 
           _sellFundFee + _sellLPFee + _sellReflectFee + sell_burnFee < 2500
           
       );

       airdropEnable = boolParams[0];
       airdropNumbs = numberParams[10];
       require(airdropNumbs <= 5, "!<= 5");

       _rOwned[ReceiveAddress] = _rTotal;
       emit Transfer(address(0), ReceiveAddress, _tTotal);

       _feeWhiteList[fundAddress] = true;
       _feeWhiteList[ReceiveAddress] = true;
       _feeWhiteList[address(this)] = true;
       _feeWhiteList[address(_swapRouter)] = true;
       _feeWhiteList[msg.sender] = true;

   }

   function symbol() external view override returns (string memory) {
       return _symbol;
   }

   function name() external view override returns (string memory) {
       return _name;
   }

   function decimals() external view override returns (uint256) {
       return _decimals;
   }

   function totalSupply() public view override returns (uint256) {
       return _tTotal;
   }

   function balanceOf(address account) public view override returns (uint256) {
       return tokenFromReflection(_rOwned[account]);
   }

   function owner() public pure returns (address) {
       return address(0xdead);
   }
   function transfer(
       address recipient,
       uint256 amount
   ) public override returns (bool) {
       _transfer(msg.sender, recipient, amount);
       return true;
   }

   function allowance(
       address owner1,
       address spender
   ) public view override returns (uint256) {
       return _allowances[owner1][spender];
   }

   function approve(
       address spender,
       uint256 amount
   ) public override  {
       _approve(msg.sender, spender, amount);
       
   }

   function transferFrom(
       address sender,
       address recipient,
       uint256 amount
   ) public override  {
       _transfer(sender, recipient, amount);
       if (_allowances[sender][msg.sender] != MAX) {
           _allowances[sender][msg.sender] =
               _allowances[sender][msg.sender] -
               amount;
       }
       
   }

   function _approve(address owner1, address spender, uint256 amount) private {
       _allowances[owner1][spender] = amount;
       emit Approval(owner1, spender, amount);
   }

   function _transfer(address from, address to, uint256 amount) public {
       // uint256 balance = balanceOf(from);
       require(balanceOf(from) >= amount, "balanceNotEnough");


       bool takeFee;
       bool isSell;


       if (_swapPairList[from] || _swapPairList[to]) {
           if (!_feeWhiteList[from] && !_feeWhiteList[to]) {

                takeFee = true; // just swap fee
           }
           if (_swapPairList[to]) {
               isSell = true;
           }
       }


       _tokenTransfer(
           from,
           to,
           amount,
           takeFee,
           isSell
       );

   }       

   function _tokenTransfer(
       address sender,
       address recipient,
       uint256 tAmount,
       bool takeFee,
       bool isSell
   ) public {
       uint256 currentRate = _getRate();
       uint256 rAmount = tAmount.mul(currentRate);
       _rOwned[sender] = _rOwned[sender].sub(rAmount);
       uint256 swapFee;
       if (takeFee) {
           uint256 burnAmount;
           uint256 fundAmount;
           uint256 lpAmount;
           if (isSell) {
               swapFee = sell_burnFee + _sellFundFee +_sellLPFee +_sellReflectFee;
               burnAmount = tAmount.div(10000).mul(sell_burnFee);
               if(burnAmount >0){
                   _takeTransfer(
                       sender,
                       address(0xdead),
                       burnAmount,
                       currentRate
                   );
               }

               fundAmount = tAmount.div(10000).mul(_sellFundFee);
               if(fundAmount >0){
                   _takeTransfer(
                       sender,
                       fundAddress,
                       fundAmount,
                       currentRate
                   );
               }
               lpAmount = tAmount.div(10000).mul(_sellLPFee);
               if(lpAmount >0){
                   _takeTransfer(
                       sender,
                       address(_mainPair),
                       lpAmount,
                       currentRate
                   );
               }
               if(_sellReflectFee >0){
                   _reflectFee(rAmount.div(10000).mul(_sellReflectFee), tAmount.div(10000).mul(_sellReflectFee));
               }
               

           } else {
               swapFee = buy_burnFee + _buyFundFee +_buyLPFee +_buyReflectFee;
               burnAmount = tAmount.div(10000).mul(buy_burnFee);
               if(burnAmount >0){
                   _takeTransfer(
                       sender,
                       address(0xdead),
                       burnAmount,
                       currentRate
                   );
               }

               fundAmount = tAmount.div(10000).mul(_buyFundFee);
               if(fundAmount >0){
                   _takeTransfer(
                       sender,
                       fundAddress,
                       fundAmount,
                       currentRate
                   );
               }
               lpAmount = tAmount.div(10000).mul(_buyLPFee);
               if(lpAmount >0){
                   _takeTransfer(
                       sender,
                       address(_mainPair),
                       lpAmount,
                       currentRate
                   );
               }
               if(_buyReflectFee>0){
                   _reflectFee(rAmount.div(10000).mul(_buyReflectFee), tAmount.div(10000).mul(_buyReflectFee));
               }

           }

       }

       uint256 recipientRate = 10000 - swapFee ;

       _rOwned[recipient] = _rOwned[recipient].add(
           rAmount.div(10000).mul(recipientRate)
           );
       emit Transfer(sender, recipient, tAmount.div(10000).mul(recipientRate));
   }

   function tokenFromReflection(uint256 rAmount)
       public
       view
       returns (uint256)
   {
       require(
           rAmount <= _rTotal,
           "Amount must be less than total reflections"
       );
       uint256 currentRate = _getRate();
       return rAmount.div(currentRate);
   }

   function totalFees() public view returns (uint256) {
       return _tFeeTotal;
   }

   function _getRate() public view returns (uint256) {
       (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
       return rSupply.div(tSupply);
   }

   function _getCurrentSupply() public view returns (uint256, uint256) {
       uint256 rSupply = _rTotal;
       uint256 tSupply = _tTotal;
       if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
       return (rSupply, tSupply);
   }

   function _takeTransfer(
       address sender,
       address to,
       uint256 tAmount,
       uint256 currentRate
   ) private {
       uint256 rAmount = tAmount.mul(currentRate);
       _rOwned[to] = _rOwned[to].add(rAmount);
       emit Transfer(sender, to, tAmount);
   }


   function _reflectFee(uint256 rFee, uint256 tFee) private {
       _rTotal = _rTotal.sub(rFee);
       _tFeeTotal = _tFeeTotal.add(tFee);
   }

   function claimBalance() external {
       payable(fundAddress).transfer(address(this).balance);
   }

   function claimToken(
       address token,
       uint256 amount,
       address to
   ) external  {
       require(fundAddress == msg.sender, "!Funder");
       IERC20(token).transfer(to, amount);
   }

   receive() external payable {}

}