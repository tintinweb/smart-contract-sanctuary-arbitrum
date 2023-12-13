/**
 *Submitted for verification at Arbiscan.io on 2023-12-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface portal {
    function convert(address _token, uint256 _minReceived, uint256 _deadline) external;
    function getPendingRewards(address _rewarder) external view returns(uint256 claimableReward);
    function claimRewardsHLPandHMX() external;
    function claimRewardsManual(address[] memory _pools, address[][] memory _rewarders) external;
}

interface AggregatorV3Interface{
    function latestRoundData() external view returns(uint80,int,uint,uint,uint80);
}

error ExpectedProfitToLow(uint256);
error FinancialLoss(uint256);
error NotProfitable(uint256);

//////////////////////////////////////////////////////////
//                wrote by mahdi rostami                //
//      if you found any issue, please let me know.     //
//                twitter: 0xmahdirostami               //
//////////////////////////////////////////////////////////

// Feel free to contribute
// todo
// 1. price oracle for PSM
// 2. another price orcale for ARB
// 3. price oracle for USDCe
// 4. events
// 5. more errors

contract dApp {

    address constant HLP_PORTAL_ADDRESS = 0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa;
    address constant USDCE = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant ARB = 0x912CE59144191C1204E64559FE8253a0e49E6548;
    address constant PSM = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address constant USDCE_REWARDER = 0x665099B3e59367f02E5f9e039C3450E31c338788;
    address constant ARB_POOL = 0xbE8f8AF5953869222eA8D39F1Be9d03766010B1C;
    address constant ARB_REWARDER = 0x238DAF7b15342113B00fA9e3F3E60a11Ab4274fD;

    uint256 constant AMOUNT = 10*23; // 100k = 10**(2+3+18)
    uint256 constant ONE = 100;
    uint256 constant USDCE_DECIMALS = 10**6;
    uint256 constant ARB_DECIMALS = 10**18;
    uint256 constant PRICE_FEED_DECIMALS = 10**8;

    portal constant HLP_PORTAL = portal(HLP_PORTAL_ADDRESS);
    AggregatorV3Interface constant ARB_DATA_FEED = AggregatorV3Interface(0xb2A824043730FE05F3DA2efaFa1CBbe83fa548D6); //8 Decimals

    uint48 public fee;
    uint48 public minProfit;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    // @_price = Worth of 100K PSM in dollar
    // @_expectedprofit = expected profit in dollar
    function convertUSDCE(uint256 _price, uint256 _expectedprofit) public {
        (uint256 total, uint256 profit) = _checkProfit(USDCE,_price, _expectedprofit);
        HLP_PORTAL.claimRewardsHLPandHMX();
        IERC20(PSM).transferFrom(msg.sender, address(this), AMOUNT);
        IERC20(PSM).approve(HLP_PORTAL_ADDRESS, AMOUNT);
        HLP_PORTAL.convert(USDCE, total, block.timestamp);
        _transfer(USDCE, profit);
    }
    // @_price = Worth of 100K PSM in dollar
    // @_expectedprofit = expected profit in dollar
    function convertARB(uint256 _price, uint256 _expectedprofit) public {
        (uint256 total, uint256 profit) = _checkProfit(ARB,_price, _expectedprofit);
        address[] memory pools = new address[](1);
        pools[0] = ARB_POOL;
        address[][] memory rewarders = new address[][](1);
        rewarders[0] = new address[](1);
        rewarders[0][0] = ARB_REWARDER;
        HLP_PORTAL.claimRewardsManual(pools, rewarders);
        IERC20(PSM).transferFrom(msg.sender, address(this), AMOUNT);
        IERC20(PSM).approve(HLP_PORTAL_ADDRESS, AMOUNT);
        HLP_PORTAL.convert(ARB, total, block.timestamp);
        _transfer(ARB, profit);
    }
    function _checkProfit(address _token, uint256 _price, uint256 _expectedprofit) public view returns(uint256 total, uint256 profit){
        if(_expectedprofit < minProfit){revert ExpectedProfitToLow(minProfit);}
        if (_token == USDCE){
            (profit, total) = checkUSDCE(_price);
            if(profit < _expectedprofit*USDCE_DECIMALS){revert NotProfitable(profit/USDCE_DECIMALS);}
        } else if (_token == ARB){
            (profit, total) = checkARB(_price);
            if(profit < _expectedprofit*ARB_DECIMALS){revert NotProfitable(profit/ARB_DECIMALS);}
        } else {
            revert();
        }
        return (total, profit);
    }
    // @_price = Worth of 100K PSM in dollar
    function checkUSDCE(uint256 _price) public view returns(uint256 profit, uint256 total){
        // uint256 psmWorth = psmWorth(); todo remove _price and fetch PSM price
        uint256 psmWorth = _price*USDCE_DECIMALS;
        uint256 balance = IERC20(USDCE).balanceOf(HLP_PORTAL_ADDRESS);
        uint256 pending = HLP_PORTAL.getPendingRewards(USDCE_REWARDER);
        total = balance + pending;
        if(total < psmWorth){revert FinancialLoss(total/USDCE_DECIMALS);}
        profit = total - psmWorth; 
    }
    // @_price = Worth of 100K PSM in dollar
    function checkARB(uint256 _price) public view returns(uint256 profit, uint256 total){
        // uint256 psmWorth = psmWorth(); todo remove _price and fetch PSM price
        uint256 psmWorth = _price*ARB_DECIMALS;
        uint256 balance = IERC20(ARB).balanceOf(HLP_PORTAL_ADDRESS);
        uint256 pending = HLP_PORTAL.getPendingRewards(ARB_REWARDER);
        total = balance + pending;
        uint256 ARBprice = getARBPriceChainLink();
        uint256 worth = ARBprice * total / PRICE_FEED_DECIMALS; //(8 decimals + 18 decimals) - (8 decimal) = 18 decimals 
        if(worth < psmWorth){revert FinancialLoss(worth/ARB_DECIMALS);}
        profit = worth - psmWorth; 
    }   
    function getARBPriceChainLink() public view returns(uint256){
        (,int answer,,,) = ARB_DATA_FEED.latestRoundData();
        return uint256(answer);
    }
    // todo remove _price and fetch PSM price
    // function psmWorth() public view returns(uint265){
    //     uint256 psmPrice = ...;
    //     retun(psmPrice * AMOUNT / pricefeeddecimals);
    // }
    function _transfer(address _token, uint256 profit) internal {
        if (msg.sender != owner){
            uint256 protocolFee = profit * fee / ONE;
            IERC20(_token).transfer(owner, protocolFee);
        }
        IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
    }

    // owner functions
    function getTOKEN(address _token) public onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }
    function getETH() public onlyOwner {
        payable(owner).call{value: address(this).balance};
    }
    function changeFee(uint48 _fee) public onlyOwner {
        require(_fee < ONE/2);
        fee = _fee;
    }
    function changeMinProfit(uint48 _minProfit) public onlyOwner {
        require(_minProfit >= 1);
        minProfit = _minProfit;
    }    
    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    receive() external payable {} 
}