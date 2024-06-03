// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

interface IDEXFactory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
   function factory() external pure returns (address);
   function WETH() external pure returns (address);
   function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IDEXReward {
   function updatePool() external payable;
   function contractStatus() external pure returns (bool);
   function isWhitelistForSendFund(address fundContract) external pure returns (bool);
}

contract t is ERC20, Ownable {
	address public pair;
	
	uint256 public buyFee;
	uint256 public sellFee;
	
	uint256 public swapThreshold;
	uint256 public rewardThreshold;
	uint256 public tokenLimitPerWallet;
	
	address[3] private treasury;
	uint256[4] private fundShare;
	
	bool private swapping;
	IDEXRouter public router;
	IDEXReward public reward;
	
	mapping(address => bool) public isWalletTaxFree;
	mapping(address => bool) public isLiquidityPair;
	mapping(address => bool) public isWalletWhiteListFromLimit;
	
	event BuyFeeUpdated(uint256 newFee);
	event SellFeeUpdated(uint256 newFee);
	event WalletWhiteListFromTokenLimit(address wallet, bool value);
	event SwapingThresholdUpdated(uint256 amount);
	event RewardThresholdUpdated(uint256 amount);
	event RewardAddressUpdated(IDEXReward newAddress);
	event ETHRescueFromContract(address receiver, uint256 ETH);
	event TokenPerWalletLimitUpdated(uint256 amount);
	event NewLiquidityPairUpdated(address pair, bool value);
	event WalletWhiteListFromFee(address wallet, bool value);
	event TreasuryWalletUpdated(address treasury1, address treasury2, address treasury3);
	event FundShareUpdated(uint256 rewardShare, uint256 treasury1Share, uint256 treasury2Share, uint256 treasury3Share);
	
    constructor(address _owner) ERC20("t", "$ts") {
	   require(_owner != address(0), "Owner:: zero address");
	   
	   router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
       pair = IDEXFactory(router.factory()).createPair(address(this), router.WETH());
	   
	   treasury = [address(0x3Ce0BD786DB39fb4237810F2Bf199BF4353f08ea), address(0x7147608590C8F5FA7A4737a028D8eA5670E359a2), address(0x969fD6783b4D12934dccFE5068f3B981466b51a7)];
	   fundShare = [2000, 3000, 3000, 2000];
	   
	   buyFee = 500;
	   sellFee = 500;
	   
	   isLiquidityPair[address(pair)] = true;
	   
	   isWalletTaxFree[address(this)] = true;
	   isWalletTaxFree[address(_owner)] = true;
	   
	   isWalletWhiteListFromLimit[address(this)] = true;
	   isWalletWhiteListFromLimit[address(pair)] = true;
	   isWalletWhiteListFromLimit[address(_owner)] = true;
	   
	   rewardThreshold = 1 * 10**18;
	   swapThreshold = 10000 * (10**18);
	   tokenLimitPerWallet = 140000 * (10**18);
	   
       _mint(address(_owner), 70000000 * (10**18));
	   _transferOwnership(address(_owner));
    }
	
	receive() external payable {}
	
	function updateSellFees(uint256 newSellFee) external onlyOwner {
	   require(newSellFee <= 9000 , "Max fee limit reached for 'Sell'");
	   
	   sellFee = newSellFee;
	   emit SellFeeUpdated(newSellFee);
	}
	
	function updateBuyFees(uint256 newBuyFee) external onlyOwner {
	   require(newBuyFee <= 9000 , "Max fee limit reached for 'Buy'");
	   
	   buyFee = newBuyFee;
	   emit BuyFeeUpdated(newBuyFee);
	}
	
	function whiteListFromTokenLimit(address wallet, bool status) external onlyOwner {
	   require(wallet != address(0), "Zero address");
	   require(isWalletWhiteListFromLimit[wallet] != status, "Wallet is already the value of 'status'");
	   
	   isWalletWhiteListFromLimit[wallet] = status;
	   emit WalletWhiteListFromTokenLimit(wallet, status);
	}
	
	function whiteListFromFees(address wallet, bool status) external onlyOwner{
        require(wallet != address(0), "Zero address");
		require(isWalletTaxFree[wallet] != status, "Wallet is already the value of 'status'");
		
		isWalletTaxFree[wallet] = status;
        emit WalletWhiteListFromFee(wallet, status);
    }
	
	function updateSwappingThreshold(uint256 amount) external onlyOwner {
  	    require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= (100 * 10**18), "Amount cannot be less than `100` token.");
		
		swapThreshold = amount;
		emit SwapingThresholdUpdated(amount);
  	}
	
	function updateRewardThreshold(uint256 amount) external onlyOwner {
		require(amount >= 0, "Amount cannot be zero");
		
		rewardThreshold = amount;
		emit RewardThresholdUpdated(amount);
  	}
	
	function updateLiquidityPair(address newPair, bool value) external onlyOwner {
        require(newPair != address(0), "Zero address");
		require(isLiquidityPair[newPair] != value, "Pair is already the value of 'value'");
		
        isLiquidityPair[newPair] = value;
        emit NewLiquidityPairUpdated(newPair, value);
    }
	
	function updateTokenLimitPerWallet(uint256 amount) external onlyOwner {
		require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 100 * (10**18), "Minimum `100` token per wallet required");
		
		tokenLimitPerWallet = amount;
		emit TokenPerWalletLimitUpdated(amount);
	}
	
	function updateTreasuryWallet(address[3] calldata newWallet) external onlyOwner {
		require(newWallet[0] != address(0) && newWallet[1] != address(0) && newWallet[2] != address(0), "Zero address");
		require(!isContract(newWallet[0]) && !isContract(newWallet[1]) && !isContract(newWallet[2]), "Contract address is not allowed");
		
		treasury[0] = address(newWallet[0]);
		treasury[1] = address(newWallet[1]);
		treasury[2] = address(newWallet[2]);
        emit TreasuryWalletUpdated(address(newWallet[0]), address(newWallet[1]), address(newWallet[2]));
    }
	
	function setFundShare(uint256[4] calldata newShare) external onlyOwner {
		require(newShare[0] + newShare[1] + newShare[2] + newShare[3] == 10000, "Share is not correct");
		
		fundShare[0] = newShare[0];
		fundShare[1] = newShare[1];
		fundShare[2] = newShare[2];
		fundShare[3] = newShare[3];
        emit FundShareUpdated(newShare[0], newShare[1], newShare[2], newShare[3]);
    }
	
	function updateRewardAddress(IDEXReward newAddress) external onlyOwner {
	    require(address(newAddress) != address(0), "Zero address");
		
	    reward = IDEXReward(newAddress);
		isWalletTaxFree[address(reward)] = true;
		isWalletWhiteListFromLimit[address(reward)] = true;
	    emit RewardAddressUpdated(newAddress);
    }
	
	function rescueETH(address receiver, uint256 amount) external onlyOwner {
	   require(receiver != address(0), "Zero address");
	   require((address(this).balance) >= amount, "Insufficient ETH balance in contract");
	   
	   payable(address(receiver)).transfer(amount);
	   emit ETHRescueFromContract(address(receiver), amount);
    }
	
	function manualSendReward(uint256 amount) external onlyOwner {
	   require(address(this).balance >= amount, "Insufficient ETH balance in contract");
	   
	   if(isEligibleToDistributeReward())
	   {
		  reward.updatePool{value: amount}();
	   }
    }
	
	function isEligibleToDistributeReward() internal view returns(bool){
	   if(reward.contractStatus() && reward.isWhitelistForSendFund(address(this)) && address(reward) != address(0))
	   {
	       return true;
	   }
	   else
	   {
	       return false;
	   }
	}
	
	function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20) {      
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
		
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapThreshold;
		
		if(!swapping && canSwap && isLiquidityPair[recipient]) 
		{
			swapping = true;
			
			uint256 oldBalance = address(this).balance;
			swapTokensForETH(swapThreshold);
			uint256 newBalance = (address(this).balance) - oldBalance;
			
			uint256 treasury1Share = ((newBalance * fundShare[1]) / 10000);
			uint256 treasury2Share = ((newBalance * fundShare[2]) / 10000);
			uint256 treasury3Share = ((newBalance * fundShare[3]) / 10000);
			
			if(treasury1Share > 0)
			{
			    payable(treasury[0]).transfer(treasury1Share);
			}
			if(treasury2Share > 0)
			{
			    payable(treasury[1]).transfer(treasury2Share);
			}
			if(treasury3Share > 0)
			{
			   payable(treasury[2]).transfer(treasury3Share);
			}
			if(isEligibleToDistributeReward() && address(this).balance >= rewardThreshold)
			{
			   reward.updatePool{value: address(this).balance}();
			}
			swapping = false; 
		}
		
		if(isWalletTaxFree[sender] || isWalletTaxFree[recipient])
		{
		    super._transfer(sender, recipient, amount);
		}
		else
		{
		    uint256 fees;
		    if(isLiquidityPair[recipient])
		    {
		        fees = ((amount * sellFee) / 10000);
		    }
		    else if(isLiquidityPair[sender] && recipient != address(router))
		    {
               fees = ((amount * buyFee) / 10000);	   
		    }
			
			if(!isWalletWhiteListFromLimit[recipient])
		    {
		       require(((balanceOf(recipient) + amount) - fees) <= tokenLimitPerWallet, "Transfer amount exceeds the `tokenLimitPerWallet`.");   
		    }
		    if(fees > 0) 
		    {
			   super._transfer(sender, address(this), fees);
		    }
		    super._transfer(sender, recipient, amount - fees);
		}
    }
	
	function swapTokensForETH(uint256 amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
		
        _approve(address(this), address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
	
	function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
}