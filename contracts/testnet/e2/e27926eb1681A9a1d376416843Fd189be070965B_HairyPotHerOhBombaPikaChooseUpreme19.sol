/**
 *Submitted for verification at Arbiscan.io on 2023-08-29
*/

/**

                                    o
                                   $""$o
                                  $"  $$
                                   $$$$
                                   o "$o
                                  o"  "$
             oo"$$$"  oo$"$ooo   o$    "$    ooo"$oo  $$$"o
o o o o    oo"  o"      "o    $$o$"     o o$""  o$      "$  "oo   o o o o
"$o   ""$$$"   $$         $      "   o   ""    o"         $   "o$$"    o$$
  ""o       o  $          $"       $$$$$       o          $  ooo     o""
     "o   $$$$o $o       o$        $$$$$"       $o        " $$$$   o"
      ""o $$$$o  oo o  o$"         $$$$$"        "o o o o"  "$$$  $
        "" "$"     """""            ""$"            """      """ "
         "oooooooooooooooooooooooooooooooooooooooooooooooooooooo$
          "$$$$"$$$$" $$$$$$$"$$$$$$ " "$$$$$"$$$$$$"  $$$""$$$$
           $$$oo$$$$   $$$$$$o$$$$$$o" $$$$$$$$$$$$$$ o$$$$o$$$"
           $"""""""""""""""""""""""""""""""""""""""""""""""""""$
           $"                                                 "$
           $"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$"$


KingdomlyTestShitcoinGenerator (KING)
Website:  https://www.kingdomly.app/
Twitter:  https://twitter.com/KingdomlyApp/

**/

// SPDX-License-Identifier: NONE

pragma solidity 0.8.19;

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

contract HairyPotHerOhBombaPikaChooseUpreme19 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    mapping (address => uint256) private _holderLastTransferTimestamp;
    bool public transferDelayEnabled = false;
    uint8 private constant _decimals = 18;
    uint256 private _buyCount=0;
    address payable private _companyWallet = payable(0xFfDD202184de72c8b7B79F4b1109892d375Cf5dA); //SET HERE
    uint256 private _preventSwapBefore=20;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

// |---------- Set all these based on user settings ----------|

    // Name of the coin
    string private _name = unicode"HairyPotHerOhBombaPikaChooseUpreme19";
    
    // Symbol or ticker of the coin
    string private _symbol = unicode"COVID19";

    // Wallet address to send the tax money too
    address payable private _taxWallet = payable(0x979c341edb41E42b3c7E1206DF38fE27c0557A34);

    // Total supply of the token
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;

    // Amount to transfer to the owner on initial deployment of the contract
    uint256 private _ownerAllocation = 1000000 * 10**_decimals;

    // Max amount per transaction to prevent people from sniping large amounts early
    uint256 public _maxTxAmount =   10000000 * 10**_decimals;

    // Max amount any one wallet can hold when limits are in place
    uint256 public _maxWalletSize = 100000000 * 10**_decimals;

    // Buy and sell taxes
    uint256 private buyTax = 1;
    uint256 private sellTax = 1;

// |------------------ End user set variables -----------------|

    // These should be updated to match the total supply and be a certain percentage of each
    uint256 public _taxSwapThreshold= 6000000 * 10**_decimals;
    uint256 public _maxTaxSwap= 6000000 * 10**_decimals;

    event MaxTxAmountUpdated(uint _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        require(_ownerAllocation <= _tTotal);
        //Update balances
        _balances[msg.sender] = _ownerAllocation;
        _balances[address(this)] = _tTotal - _ownerAllocation;

        //Set fee exclusions
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        //Emit Transfer
        if(_ownerAllocation > 0){
            emit Transfer(address(0), _msgSender(), _ownerAllocation);
        }
    }
        
    // Returns the name of the contract
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns the symbol/ticker of the contract
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the amount of decimals to use on the token
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    // Returns the total supply of the token
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    // Returns the amount of tokens that the inputted address owns
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    // Transfers the amount of tokens from the caller to the recipient
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Returns the amount of owners tokens that spender is allowed to transfer
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Approves amount of tokens to be spend by spender on behalf of the caller
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Transfers amount of tokens from the sender to the recipient
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // Helper function called when approve() function is called
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Helper function called upon a transfer. Does the actual updating of balances,
    // checks limit conditions, and takes taxes from the transfer
    function _transfer(address from, address to, uint256 amount) private {
        // Require Checks
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        // Fee calculation
        uint256 taxAmount = 0;
        uint256 companyFee = 0;
        uint256 totalFees = 0;

        // Owner exempt from conditions
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            
            // Add delay on transfer to prevent sandwiching
            if (transferDelayEnabled) {
                if (to != address(uniswapV2Router) && to != address(uniswapV2Pair)) {
                    require(_holderLastTransferTimestamp[tx.origin] < block.number, "Only one transfer per block allowed.");
                    _holderLastTransferTimestamp[tx.origin] = block.number;
                }
            }

            // Checks to make sure TX is within constraints allowed
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                _buyCount++;
            }

            // Calculate the company fee
            companyFee = amount.mul(1).div(100);

            // Calculate the tax
            taxAmount = amount.mul(buyTax).div(100);
            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul(sellTax).div(100);
            }

            // Calculate the total fees to be transferred to the contract
            totalFees = taxAmount.add(companyFee);
            uint256 remainingAmount = amount.sub(totalFees);

            if(totalFees > 0){
                _balances[address(this)] = _balances[address(this)].add(totalFees);
                emit Transfer(from, address(this), totalFees);
            }

            // Swap tokens and send to fee wallet if conditions are correct
            // This condition checks if the contract is not currently in the middle of a swap, 
            // the recipient is the Uniswap pair (indicating a sell), swapping is enabled, 
            // the contract's token balance is greater than the tax swap threshold, and the buy count is 
            // greater than the number after which swaps are prevented. This condition is used to decide whether 
            // to perform a swap and send ETH to the fee wallet.
            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && to == uniswapV2Pair && swapEnabled && contractTokenBalance > _taxSwapThreshold && _buyCount > _preventSwapBefore) {
                swapTokensForEth(min(remainingAmount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    // Distribute the ETH proportionally to the company wallet and tax wallet
                    uint256 companyETHFee = contractETHBalance.mul(companyFee).div(totalFees);
                    sendETHToCompany(companyETHFee);
                    sendETHToFee(contractETHBalance.sub(companyETHFee));
                }
            }
        }

        // Update balances
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(totalFees));
        emit Transfer(from, to, amount.sub(totalFees));
    }


    // Return the minimum of two uint256 numbers
    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    // Swaps the tokens to eth
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if(tokenAmount==0){return;}
        if(!tradingOpen){return;}
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

    // Removes the buy limits like max TX amount and max wallet amount
    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        transferDelayEnabled = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    // Sends Eth to the tax wallet
    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    // Sends eth to the company wallet
    function sendETHToCompany(uint256 amount) private {
        _companyWallet.transfer(amount);
    }

    // Checks if a wallet is a bot
    function isBot(address a) public view returns (bool){
      return bots[a];
    }

    // Function to tke the token balance and eth balance of this contract and add them as a liquidity pair on uniswap
    // ... This is the "Go Live" function
    function feedTheRealm() external onlyOwner() {
        require(!tradingOpen,"trading is already open");

        // Switch the address of the router to correspond with the different chains router addresses
        // ETH, ARBITRUM, GOERLI (uniswap): 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        // Base (sushiswap): 0x6BDED42c6DA8FBf0d2bA55B2fa120C5e0c8D7891
        // BSC (Pancakeswap): 0x10ED43C718714eb63d5aA57B78B54704E256024E 
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    // Manually swap the tokens in the contract for eth and send to tax wallet
    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance > 0){
            swapTokensForEth(contractTokenBalance);
        }
        
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0){
            // Calculate the company fee
            uint256 companyETHFee = contractETHBalance.div(4); // 1/4 to company wallet
            sendETHToCompany(companyETHFee);
            
            // Send the remaining ETH to the tax wallet
            uint256 remainingETH = contractETHBalance.sub(companyETHFee);
            sendETHToFee(remainingETH);
        }
    }

    // Add list of addresses to flag as bots
    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    // Delete lists of addresses from bot list
    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }
}