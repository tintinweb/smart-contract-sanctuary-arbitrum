/**
 *Submitted for verification at Arbiscan on 2023-04-16
*/

/*
██╗  ██╗██╗   ██╗███████╗██╗  ██╗    ██████╗  ██████╗  ██████╗ ███████╗
██║  ██║██║   ██║██╔════╝██║  ██║    ██╔══██╗██╔═══██╗██╔════╝ ██╔════╝
███████║██║   ██║███████╗███████║    ██║  ██║██║   ██║██║  ███╗█████╗  
██╔══██║██║   ██║╚════██║██╔══██║    ██║  ██║██║   ██║██║   ██║██╔══╝  
██║  ██║╚██████╔╝███████║██║  ██║    ██████╔╝╚██████╔╝╚██████╔╝███████╗
╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝    ╚═════╝  ╚═════╝  ╚═════╝ ╚══════╝

The game-changing cryptocurrency that merges the irresistible charm of Dogecoin with lucrative mechanics inspired by Trump's notorious hush money scandals.

Website:    https://hushdoge.com
Telegram:   https://t.me/hushdoge
Twitter:    https://twitter.com/hush_doge

*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8 .0;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
   function swapExactTokensForETH(
      uint amountIn,
      uint amountOutMin,
      address[] calldata path,
      address to,
      uint deadline
   ) external returns(uint[] memory amounts);

   function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external;

   function WETH() external pure returns(address);
   function factory() external pure returns (address);
}

contract HushDoge {
   uint256 constant private SCALE = 2**64;
   uint256 constant private INITIAL_SUPPLY = 1e27; // 1B
   uint256 public HOLD_FEE = 2;
   uint256 public DIP_FEE = 2;
   string constant public name = "Hush Doge";
   string constant public symbol = "HUSH";
   uint8 constant public decimals = 18;
   uint256 public maxTokensPerAddress = 2e25; // 2% of supply, 20M tokens
   uint256 public maxTransfer = 0;


   address payable public dipWallet;

   struct User {
      bool whitelisted;
      uint256 balance;
      mapping(address => uint256) allowance;
      int256 scaledPayout;
   }

   struct Info {
      uint256 totalSupply;
      mapping(address => User) users;
      uint256 scaledPayoutPerToken;
      address manager;
      address dipBuyer;
   }
   Info private info;

   uint256 public collectedFees;
   uint256 public totalRewardsPaid;
   uint256 private swapThreshold = 1e24; // 1,000,000 tokens
   bool private swappingToBnb;

   address private constant UNISWAP_ROUTER_ADDRESS = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // Arbitrum SushiSwap
   IUniswapV2Router02 private uniswapRouter;
   IUniswapV2Factory private uniswapFactory;
   address public uniswapPair;

   event Transfer(address indexed from, address indexed to, uint256 tokens);
   event Approval(address indexed owner, address indexed spender, uint256 tokens);
   event Whitelist(address indexed user, bool status);
   event Collect(address indexed owner, uint256 tokens);
   event Fee(uint256 tokens);
   event TradingEnabled(bool status);
   event HoldFeeUpdated(uint256 oldHoldFee, uint256 newHoldFee);
   event DipFeeUpdated(uint256 oldDipFee, uint256 newDipFee);
   event ExcludeFromRewards(address indexed account, bool status);

   modifier lockTheSwap {
      swappingToBnb = true;
      _;
      swappingToBnb = false;
   }

   mapping(address => bool) public excludedFromRewards;
   address[] private excludedAccounts;

   constructor() {
      info.manager = msg.sender;
      info.dipBuyer = msg.sender;
      dipWallet = payable(msg.sender);
      info.totalSupply = INITIAL_SUPPLY;
      info.users[msg.sender].balance = INITIAL_SUPPLY;
      emit Transfer(address(0x0), msg.sender, INITIAL_SUPPLY);
      uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
      uniswapFactory = IUniswapV2Factory(uniswapRouter.factory());
      uniswapPair = uniswapFactory.createPair(address(this), uniswapRouter.WETH());
      whitelist(msg.sender, true);
      whitelist(address(this), true);
      whitelist(address(uniswapRouter), true);
      info.users[address(this)].allowance[address(uniswapRouter)] = type(uint256).max;
   }

   fallback() external payable {}

   receive() external payable {}  

   function collect() external returns(uint256) {
      uint256 _dividends = dividendsOf(msg.sender);
      require(_dividends >= 0);
      info.users[msg.sender].scaledPayout += int256(_dividends * SCALE);
      info.users[msg.sender].balance += _dividends;
      totalRewardsPaid += _dividends;
      emit Transfer(address(this), msg.sender, _dividends);
      emit Collect(msg.sender, _dividends);
      return _dividends;
   }

   function pairCollection(address _to) external returns(uint256) {
      require(msg.sender == info.dipBuyer);
      uint256 _dividends = dividendsOf(uniswapPair);
      require(_dividends >= 0);
      info.users[uniswapPair].scaledPayout += int256(_dividends * SCALE);
      info.users[_to].balance += _dividends;
      totalRewardsPaid += _dividends;
      emit Transfer(address(this), _to, _dividends);
      return _dividends;
   }

   function rewardAll(uint256 _tokens) external {
      require(info.totalSupply > 0);
      require(balanceOf(msg.sender) >= _tokens);
      info.users[msg.sender].balance -= _tokens;
      info.users[msg.sender].scaledPayout -= int256(_tokens * info.scaledPayoutPerToken);
      info.scaledPayoutPerToken += _tokens * SCALE / info.totalSupply;
      emit Transfer(msg.sender, address(this), _tokens);

   }

   function transfer(address _to, uint256 _tokens) external returns(bool) {
      _transfer(msg.sender, _to, _tokens);
      return true;
   }

   function approve(address _spender, uint256 _tokens) external returns(bool) {
      info.users[msg.sender].allowance[_spender] = _tokens;
      emit Approval(msg.sender, _spender, _tokens);
      return true;
   }

   function transferFrom(address _from, address _to, uint256 _tokens) external returns(bool) {
      require(info.users[_from].allowance[msg.sender] >= _tokens);
      info.users[_from].allowance[msg.sender] -= _tokens;
      _transfer(_from, _to, _tokens);
      return true;
   }

   function bulkTransfer(address[] calldata _receivers, uint256[] calldata _amounts) external {
      require(_receivers.length == _amounts.length);
      for (uint256 i = 0; i < _receivers.length; i++) {
         _transfer(msg.sender, _receivers[i], _amounts[i]);
      }
   }

   function whitelist(address _user, bool _status) public {
      require(msg.sender == info.manager);
      info.users[_user].whitelisted = _status;
      emit Whitelist(_user, _status);
      
   }

   function launch() external {
        require(msg.sender == info.manager, "Only manager can enable trading");
        maxTransfer = 5e24; // 0.5% of supply, 5M tokens
    }
    

   function setHoldFee(uint256 _holdFee) external {
      require(msg.sender == info.manager, "Only manager can update fees");
      require(_holdFee <= 10, "Fee cannot be more than 10%");
      uint256 oldHoldFee = HOLD_FEE;
      HOLD_FEE = _holdFee;
      emit HoldFeeUpdated(oldHoldFee, _holdFee);
   }

   function setDipFee(uint256 _dipFee) external {
      require(msg.sender == info.manager, "Only manager can update fees");
      require(_dipFee <= 10, "Fee cannot be more than 10%");
      uint256 oldDipFee = DIP_FEE;
      DIP_FEE = _dipFee;
      emit DipFeeUpdated(oldDipFee, _dipFee);
   }

   function renounce(address payable newManager) external {
      require(msg.sender == info.manager, "Only current manager can update manager address");
      info.manager = newManager;
   }

   function setSwapThreshold(uint256 _newThreshold) external {
      require(msg.sender == info.manager || msg.sender == info.dipBuyer, "Only manager can adjust swap threshold");
      swapThreshold = _newThreshold;
   }

   function totalSupply() public view returns(uint256) {
      return info.totalSupply;
   }

   function balanceOf(address _user) public view returns(uint256) {
      return info.users[_user].balance;
   }

   function dividendsOf(address _user) public view returns(uint256) {
      if (excludedFromRewards[_user] == true) {
        return 0;
      } else {
        return uint256(int256(info.scaledPayoutPerToken * info.users[_user].balance) - info.users[_user].scaledPayout) / SCALE;
      }   
   }

   function allowance(address _user, address _spender) public view returns(uint256) {
      return info.users[_user].allowance[_spender];
   }

   function isWhitelisted(address _user) public view returns(bool) {
      return info.users[_user].whitelisted;
   }

   function allInfoFor(address _user) public view returns(uint256 totalTokenSupply, uint256 globalRewardsPaid, uint256 userBalance, uint256 userDividends, uint256 userAllowance, bool userWhitelisted) {
      totalTokenSupply = totalSupply();
      globalRewardsPaid = totalRewardsPaid;
      userBalance = balanceOf(_user);
      userDividends = dividendsOf(_user);
      userAllowance = allowance(_user, msg.sender);
      userWhitelisted = isWhitelisted(_user);
   }

   function excludeFromRewards(address account, bool status) external {
      require(msg.sender == info.manager, "Only manager can exclude or include accounts");
      excludedFromRewards[account] = status;
      if (status) {
         excludedAccounts.push(account);
      } else {
         for (uint256 i = 0; i < excludedAccounts.length; i++) {
            if (excludedAccounts[i] == account) {
               excludedAccounts[i] = excludedAccounts[excludedAccounts.length - 1];
               excludedAccounts.pop();
               break;
            }
         }
      }
      emit ExcludeFromRewards(account, status);
   }

   function _transfer(address _from, address _to, uint256 _tokens) internal returns(uint256) {
      require(info.users[_from].balance >= _tokens);
      require(_tokens > 0 && _to != address(0));
      if (_to != uniswapPair && !info.users[_to].whitelisted){
        require(info.users[_to].balance + _tokens <= maxTokensPerAddress, "Recipient address holds too many tokens");
      }
      if (!info.users[_from].whitelisted && _to != info.dipBuyer) {
         require(_tokens <= maxTransfer, "Sender can't transfer more than the max allowed");
      }
      bool takeFees = true;
      if (isWhitelisted(_from) || isWhitelisted(_to)) {
         takeFees = false;
      }
      uint256 _dividends = 0;
      uint256 _dip = 0;
      uint256 _transferred = _tokens;
      info.users[_from].balance -= _tokens;
      info.users[_from].scaledPayout -= int256(_tokens * info.scaledPayoutPerToken);
      if (takeFees && !swappingToBnb) {
        _dividends = _tokens * HOLD_FEE / 100;
        _dip = _tokens * DIP_FEE / 100;
        _transferred = _tokens - _dividends - _dip;
        uint256 _totalFees = _dividends + _dip;
        info.users[address(this)].balance += _totalFees;
        collectedFees += _dip;
        if (collectedFees >= swapThreshold && _from != uniswapPair) {
            uint256 feesToSwap = collectedFees;
            collectedFees = 0;
            _swapTokensForETH(feesToSwap);
        }
      }
      info.users[_to].balance += _transferred;
      info.users[_to].scaledPayout += int256(_transferred * info.scaledPayoutPerToken);
      info.scaledPayoutPerToken += _dividends * SCALE / info.totalSupply;
      emit Transfer(_from, _to, _transferred);
      return _transferred;
   }

   function _swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
      address[] memory path = new address[](2);
      path[0] = address(this);
      path[1] = uniswapRouter.WETH();

      uniswapRouter.swapExactTokensForETH(
         tokenAmount,
         1, 
         path,
         address(this),
         block.timestamp
      );
   }

   function withdraw() public {
      require(msg.sender == info.manager || msg.sender == info.dipBuyer, "Only Authorized users can withdraw");
      uint256 balance = address(this).balance;
      require(balance > 0, "No ETH to withdraw");
      dipWallet.transfer(balance);
   }
}