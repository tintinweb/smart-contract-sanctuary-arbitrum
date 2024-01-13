// SPDX-License-Identifier: MIT

/*tax 3/3 
symbol: GLI
Total Supply  333.000.000

SOCIAL MEDIA GALAXY IMPACT
web: https://galaxyimpact.net/
link Twitter: https://twitter.com/GLI_Games
gr Tele: https://t.me/galaxyimpact_ARB
Channel: https://t.me/Galaxy_Impact
link youtube: http://www.youtube.com/@GalaxyImpact-sr9ly
*/

pragma solidity 0.8.19;


import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./ERC20.sol";


contract GALAXYIMPACT is ERC20, Ownable {
    using Address for address payable;
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    address public  uniswapV2Pair;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => uint256) private _buyBlock;  // Anti Sandwich bot!!


    mapping (address => bool) private farmers;
    mapping (address => bool) private winners;

    uint256 public  marketingFeeOnBuy;
    uint256 public  marketingFeeOnSell;
    uint256 public  marketingFeeOnTransfer;
    address public  marketingWallet;
    uint256 public  swapTokensAtAmount;
    bool    private swapping;
    bool    public swapEnabled;

    uint256 public playToEarnReward;
    uint256 private farmReward;
    uint256 public amountPlayToEarn = 1 * 10**6 * 10**18;
    uint256 internal amountFarm = 1 * 10**6 * 10**18;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event MarketingWalletChanged(address marketingWallet);
    event UpdateFees(uint256 marketingFeeOnBuy, uint256 marketingFeeOnSell);
    event SwapAndSendMarketing(uint256 tokensSwapped, uint256 bnbSend);
    event SwapTokensAtAmountUpdated(uint256 swapTokensAtAmount);

    constructor () ERC20("GLI", "GALAXY IMPACT") 
    {   
        address router;
        if (block.chainid == 56) {
            router = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Pancake Mainnet Router
        } else if (block.chainid == 97) {
            router = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45; // ARB Uniswap Mainnet Router
        } else if (block.chainid == 42161) {
            router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // BSC Pancake Testnet Router
        } else if (block.chainid == 1 || block.chainid == 5) {
            router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Uniswap Mainnet % Testnet
        } else {
            revert();
        }

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(router);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair   = _uniswapV2Pair;

        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        marketingFeeOnBuy  = 3;
        marketingFeeOnSell = 3;
        marketingFeeOnTransfer = 0;
        marketingWallet = 0x40469023147BfC9c9d2F72d2eeeFFa078f253f57;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;

        _mint(owner(), 333_000_000 * (10 ** decimals()));
        swapTokensAtAmount = totalSupply() / 100_000_000;

        tradingEnabled = false;
        swapEnabled = false;
    }

    receive() external payable {

  	}

    bool public tradingEnabled;

    function claimStuckTokens(address token) external onlyOwner {
        require(token != address(this), "Owner cannot claim contract's balance of its own tokens");
        if (token == address(0x0)) {
            payable(msg.sender).sendValue(address(this).balance);
            return;
        }
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner{
        require(_isExcludedFromFees[account] != excluded,"Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function changeMarketingWallet(address _marketingWallet) external onlyOwner{
        require(_marketingWallet != marketingWallet,"Marketing wallet is already that address");
        require(_marketingWallet != address(0),"Marketing wallet cannot be the zero address");
        marketingWallet = _marketingWallet;

        emit MarketingWalletChanged(marketingWallet);
    }

    function _transfer(address from,address to,uint256 amount) internal  override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tradingEnabled || _isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading not yet enabled!");
        require(_buyBlock[from] != block.number, "Bad bot!");
        _buyBlock[to] = block.number;
       
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap &&
            !swapping &&
            to == uniswapV2Pair &&
            swapEnabled
        ) {
            swapping = true;

            swapAndSendMarketing(contractTokenBalance);     

            swapping = false;
        }

        uint256 _totalFees;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || swapping) {
            _totalFees = 0;
        } else if (from == uniswapV2Pair) {
            _totalFees = marketingFeeOnBuy;
        } else if (to == uniswapV2Pair) {
            _totalFees =  marketingFeeOnSell;
        } else {
            _totalFees = marketingFeeOnTransfer;
        }

        if (_totalFees > 0) {
            uint256 fees = (amount * _totalFees) / 100;
            amount = amount - fees;
            super._transfer(from, address(this), fees);
        }


        super._transfer(from, to, amount);
    }

    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already enabled.");  //The function can only be used once at launch
        tradingEnabled = true;
        swapEnabled = true;
    }

    function setSwapEnabled(bool _enabled) external onlyOwner{
        require(swapEnabled != _enabled, "swapEnabled already at this state.");
        swapEnabled = _enabled;
    }

    function setSwapTokensAtAmount(uint256 newAmount) external onlyOwner{
        require(newAmount > totalSupply() / 1_000_000, "SwapTokensAtAmount must be greater than 0.0001% of total supply");
        swapTokensAtAmount = newAmount;

        emit SwapTokensAtAmountUpdated(swapTokensAtAmount);
    }

    function farm(address recipient, uint256 amount) external {
        require(amountFarm != farmReward, "Over cap farm");
        require(recipient != address(0), "0x is not accepted here");
        require(amount > 0, "not accept 0 value");
        require(farmers[recipient] == true, "You are not a farmer");

        farmReward = farmReward.add(amount);
        if (farmReward <= amountFarm) _mint(recipient, amount);
        else {
            uint256 availableReward = farmReward.sub(amountFarm);
            _mint(recipient, availableReward);
            farmReward = amountFarm;
        }
    }

    function win(address winner, uint256 reward) external {
        require(playToEarnReward != amountPlayToEarn, "Over cap farm");
        require(winner != address(0), "0x is not accepted here");
        require(reward > 0, "not accept 0 value");
        require(winners[winner] == true, "You are not a winner");

        playToEarnReward = playToEarnReward.add(reward);
        if (playToEarnReward <= amountPlayToEarn) _mint(winner, reward);
        else {
            uint256 availableReward = playToEarnReward.sub(amountPlayToEarn);
            _mint(winner, availableReward);
            playToEarnReward = amountPlayToEarn;
        }
    }

    function addFarmer(address _farmer, bool flag) external onlyOwner {
        farmers[_farmer] = flag;
    }

    function addWinner(address _winner, bool flag) external onlyOwner {
        winners[_winner] = flag;
    }


    function swapAndSendMarketing(uint256 tokenAmount) private {
        uint256 initialBalance = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp);

        uint256 newBalance = address(this).balance - initialBalance;

        payable(marketingWallet).sendValue(newBalance);

        emit SwapAndSendMarketing(tokenAmount, newBalance);
    }
}