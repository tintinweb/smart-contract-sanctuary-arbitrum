// SPDX-License-Identifier: MIT

pragma solidity >=0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./libs/SushiLibs.sol";

contract VaultMiner is Context, Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;
    
    IERC20 private token;

    // where the tokens get sent too after buys, default to burn
    address private tokenReceiver = address(0xdead);

    IUniswapV2Router02 public immutable swapRouter;
    address private  swapPair;

    uint256 public constant COST_FOR_SHARE = 1080000;
    uint256 private PSN = 10000;
    uint256 private PSNH = 5000;
    

    bool private initialized = false;
    address payable private treasuryWallet;
    address payable private investWallet;
    address payable private devWallet;

    mapping (address => uint256) private userShares;
    mapping (address => uint256) private claimedWorkers;
    mapping (address => address) private referrals;
    mapping (address => uint256) private lastClaim;
    mapping (address => IERC20) public harvestToken;

    mapping(address => bool) private canGive;
    uint256 public marketWorkers;

    uint256 public totalShares;    

    // hard cap Penalty fee of 60% max
    uint256 private constant MAX_PENALTY_FEE = 600;

    // hard cap buy in fee of 20% max
    uint256 private constant MAX_BUY_FEE = 200;

    // hard cap of 15% on the referral fees
    uint256 private constant MAX_REF_FEE = 150;

    struct ActiveFeatures {
        bool minerActive;
        bool lpEnabled; // if we add to lp or not
        bool minerBuy; // buying/selling in the miner 
        bool minerCompound; // compounding 
    }

    struct FeesInfo {
        uint256 refFee;
        uint256 buyFee;
        uint256 devFee;
        uint256 treasuryFee;
        uint256 investFee;
        uint256 buyPenalty;
        uint256 devPenalty;
        uint256 treasuryPenalty;
        uint256 investPenalty;
    }

    struct UserStats {
        uint256 purchases; // how many times they bought shares
        uint256 purchaseAmount; // total amount they have purchased
        uint256 purchaseValue; // total value they have purchased 
        uint256 compounds; // how many times they have compounded
        uint256 compoundAmount; // total amount they have compounded
        uint256 compoundValue; // total value they have compounded (at time of compound) 
        uint256 lastSell; // timestamp of last sell
        uint256 sells; // how many times they sold shares
        uint256 sellAmount; // total amount they have sold
        uint256 sellValue; // total value they have sold
        uint256 firstBuy; //when they made their first buy
        uint256 refRewards; // total value of ref rewards (at time of purchase) 
        uint256 lastReset; // the time stamp if they reset the account and GTFO
    }

    

    struct MultiplierInfo {
        uint256 nftId; 
        uint256 lifetime; // time in seconds this is active 
        uint256 startTime; // time stamp it was staked
        uint256 endTime; // time stamp it when it ends
        uint256 multiplier;  // multiply new shares by this amount (only applies to type 1)
    }

    struct MinerSettings {
        uint256 maxPerAddress;
        uint256 minBuy;
        uint256 maxBuy;
        uint256 minRefAmount;
        uint256 maxRefMultiplier;
        uint256 sellDuration;
        // bool buyFromTokenEnabled;
        bool noSell;
        bool refCompoundEnabled;
        uint256 pendingLock;
    }
  
    
    mapping(address => MultiplierInfo) public currentMultiplier;
    mapping(address => UserStats) public userStats;
    ActiveFeatures public activeFeatures;
    FeesInfo public fees;
    MinerSettings public minerSettings;

    // event FeeChanged(uint256 refFee, uint256 fee, uint256 penaltyFees, uint256 timestamp);

    constructor(
        address payable _devWallet, 
        address payable _treasuryWallet, 
        address payable _investWallet, 
        IERC20 _token, 
        address _router) {

        treasuryWallet = payable(_treasuryWallet);
        investWallet = payable(_investWallet);
        devWallet = payable(_devWallet);

        token = _token;

        
        // 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        IUniswapV2Router02 _swapRouter = IUniswapV2Router02(
            _router
        );
        // get a uniswap pair for this token
        swapPair = IUniswapV2Factory(_swapRouter.factory()).createPair(address(this), _swapRouter.WETH());
        
        swapRouter = _swapRouter;

        IERC20(swapPair).approve(address(_swapRouter), type(uint256).max);
        token.approve(address(this), type(uint256).max);
        

        // default fees
        fees = FeesInfo({
            refFee: 90,
            buyFee: 20,
            devFee: 6,
            treasuryFee: 34,
            investFee: 0,
            buyPenalty: 200,
            devPenalty: 60,
            treasuryPenalty: 340,
            investPenalty: 0
        });

        // default settings
        minerSettings = MinerSettings({
            maxPerAddress: 10000 * 1 ether,
            minBuy: 5 * 1 ether,
            maxBuy: 1000 * 1 ether,
            minRefAmount: 50 * 1 ether,
            maxRefMultiplier: 30,
            sellDuration: 6 days,
            // buyFromTokenEnabled: true,
            noSell: false,
            refCompoundEnabled: false,
            pendingLock: 3
        });
    }
    
    event SetHarvestToken(address indexed user, IERC20 token);
    function setHarvestToken(IERC20 _harvestToken)  external {
        harvestToken[msg.sender] = _harvestToken;
        emit SetHarvestToken(msg.sender, _harvestToken);
    }
    
    function claimWorkers(address ref) public _isInitialized nonReentrant {
        _claimWorkers(msg.sender,ref, false);
    }

    function vaultClaimWorkers(address addr, address ref) public _isInitialized {
        require(canGive[msg.sender], "Not Allowed");
        _claimWorkers(addr,ref, false);
    }

    function getMaxRefRewards(address addr) public view returns(uint256){
        return (userStats[addr].purchaseValue * minerSettings.maxRefMultiplier) / 10;
    }

    function getLastReset(address _addr) external view returns(uint256){
        return userStats[_addr].lastReset; 
    }
    
    event WorkersClaimed(address indexed user, address indexed ref, bool isBuy, uint256 newShares, uint256 userWorkers, uint256 refWorkers, uint256 refRewards, uint256 compoundValue, uint256 marketWorkers, uint256 timestamp);
    function _claimWorkers(address addr, address ref, bool isBuy) private {
        require(activeFeatures.minerActive && activeFeatures.minerCompound, 'disabled');
        // require(isBuy || block.timestamp > (lastClaim[addr] + compoundDuration), 'Too soon' );
        if(ref == addr) {
            ref = address(0);
        }
        
        if(referrals[addr] == address(0) && referrals[addr] != addr && referrals[referrals[addr]] != addr) {
            referrals[addr] = ref;
        }

        bool hasRef = referrals[addr] != address(0) && referrals[addr] != addr && userStats[referrals[addr]].purchaseValue >= minerSettings.minRefAmount;
        
        uint256 workersUsed = getMyWorkers(addr);
        // uint256 userWorkers;
        uint256 refWorkers;
        uint256 refRewards;
        if(hasRef && (isBuy || minerSettings.refCompoundEnabled)) {
            refWorkers = getFee(workersUsed,fees.refFee);
            refRewards = calculateWorkerSell(refWorkers);
            // check if we hit max ref rewards
            if((userStats[referrals[addr]].refRewards + refRewards) < getMaxRefRewards(referrals[addr]) ){
                
                //send referral workers
                claimedWorkers[referrals[addr]] = claimedWorkers[referrals[addr]] + refWorkers;
                userStats[referrals[addr]].refRewards = userStats[referrals[addr]].refRewards + refRewards;
            } else {
                refWorkers = 0;
                refRewards = 0;
            }
        }
       
        uint256 compoundValue = 0;

        if(isBuy){
            userStats[addr].purchases = userStats[addr].purchases + 1;
            userStats[addr].purchaseAmount = userStats[addr].purchaseAmount + workersUsed; 
        } else {
            compoundValue = calculateWorkerSell(workersUsed);
            userStats[addr].compounds = userStats[addr].compounds + 1;
            userStats[addr].compoundAmount = userStats[addr].compoundAmount + workersUsed; 
            userStats[addr].compoundValue = userStats[addr].compoundValue + compoundValue; 
        }

        // uint256 newShares = userWorkers/COST_FOR_SHARE;
        uint256 newShares = workersUsed/COST_FOR_SHARE;
        
        userShares[addr] = userShares[addr] + newShares;
        totalShares = totalShares + newShares;

        claimedWorkers[addr] = 0;
        lastClaim[addr] = block.timestamp;
         
        //boost market to nerf shares hoarding
        marketWorkers = marketWorkers + (workersUsed/5);

        emit WorkersClaimed(addr, referrals[addr], isBuy, newShares, workersUsed, refWorkers, refRewards, compoundValue, marketWorkers, block.timestamp);
    }


    event WorkersSold(address indexed user,  uint256 amount, uint256 workersSold, uint256 marketWorkers, uint256 toUser, uint256 toFees, uint256 timestamp );
    function sellWorkers() public _isInitialized nonReentrant {
        require(activeFeatures.minerActive && activeFeatures.minerBuy && (!minerSettings.noSell || block.timestamp > (userStats[msg.sender].lastSell + minerSettings.sellDuration)), 'too soon to sell');

        uint256 hasWorkers = getMyWorkers(msg.sender);
        uint256 workerValue = calculateWorkerSell(hasWorkers);

        uint256 fee = getFee(workerValue,totalFees());
        uint256 toBuy = getFee(workerValue,fees.buyFee);
        uint256 toDev = getFee(workerValue,fees.devFee);
        uint256 toTreasury = getFee(workerValue,fees.treasuryFee);
        uint256 toInvest = getFee(workerValue,fees.investFee);

        uint256 sellTime = userStats[msg.sender].lastSell + minerSettings.sellDuration;

        if(!minerSettings.noSell && block.timestamp < sellTime){
            // use the penalty fees
            // scale down from penalty fee to 2x the normal fee over time
            uint256 timeDelta = block.timestamp - userStats[msg.sender].lastSell;
            uint256 penaltyMod = (timeDelta * 10000)/minerSettings.sellDuration;
            uint256 feeCheck = (totalPenalty() * penaltyMod)/10000;
            uint256 minFee = totalFees() * 2;
            

            if( feeCheck > minFee){
                fee = (getFee(workerValue, (totalPenalty())) * penaltyMod)/10000;
                toBuy = (getFee(workerValue,fees.buyPenalty) * penaltyMod)/10000;
                toDev = (getFee(workerValue,fees.devPenalty) * penaltyMod)/10000;
                toTreasury = (getFee(workerValue,fees.treasuryPenalty) * penaltyMod)/10000;
                toInvest = (getFee(workerValue,fees.investPenalty) * penaltyMod)/10000;
            } else {
                fee = getFee(workerValue,totalFees() * 2);
                toBuy = getFee(workerValue,fees.buyFee * 2);
                toDev = getFee(workerValue,fees.devFee * 2);
                toTreasury = getFee(workerValue,fees.treasuryFee * 2);
                toInvest = getFee(workerValue,fees.investFee * 2);
            }
        }

        claimedWorkers[msg.sender] = 0;
        lastClaim[msg.sender] = block.timestamp;
        marketWorkers = marketWorkers + hasWorkers;

        userStats[msg.sender].lastSell = block.timestamp; 
        userStats[msg.sender].sells = userStats[msg.sender].sells + 1; 
        userStats[msg.sender].sellAmount = userStats[msg.sender].sellAmount + hasWorkers;
        userStats[msg.sender].sellValue = userStats[msg.sender].sellValue + (workerValue-fee);

        bool sent;
        if(toDev > 0) {
            (sent,) = devWallet.call{value: (toDev)}("");
            require(sent,"send failed");
        }

        if(toTreasury > 0) {
            (sent,) = treasuryWallet.call{value: (toTreasury)}("");
            require(sent,"send failed");
        }

        if(toInvest > 0) {
            (sent,) = investWallet.call{value: (toInvest)}("");
            require(sent,"send failed");
        }

        if(toBuy > 0) {
            swapFromFees(toBuy);
        }

        uint256 toSend = workerValue - toDev - toTreasury - toInvest - toBuy;
        if(harvestToken[msg.sender] == IERC20(address(0))){
            // send to the user
            (sent,) = payable(msg.sender).call{value: toSend}("");
            require(sent,"send failed");
        } else {
            _swapNativeForToken(toSend, harvestToken[msg.sender], msg.sender); 
        }

        emit WorkersSold(msg.sender, workerValue, hasWorkers, marketWorkers, toSend, (workerValue - toSend), block.timestamp);
    }
    
    function pendingRewards(address adr) public view returns(uint256) {
        uint256 hasWorkers = getMyWorkers(adr);
        if(hasWorkers == 0){
            return 0;
        }
        uint256 workerValue = calculateWorkerSell(hasWorkers);
        return workerValue;
    }
    
    function buyWorkers(address ref) public payable _isInitialized nonReentrant {
        return _buyWorkers(msg.sender, msg.value, ref, false);
    }

    function contractBuyWorkers(address _user, address _ref) public payable _isInitialized nonReentrant {
        require(canGive[msg.sender], "Not Allowed");
        return _buyWorkers(_user, msg.value, _ref, true);
    }

    function setCurrentMultiplier(
        address _user, 
        uint256 _nftId, 
        uint256 _lifetime, 
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _multiplier
    ) public {
        require(canGive[msg.sender], "Not Allowed");

        currentMultiplier[_user].nftId = _nftId;
        currentMultiplier[_user].lifetime = _lifetime;
        currentMultiplier[_user].startTime = _startTime;
        currentMultiplier[_user].endTime = _endTime;
        currentMultiplier[_user].multiplier = _multiplier;

    }

    event WorkersBought(address indexed user, address indexed ref, uint256 amount, uint256 workersBought, bool fromSwap, uint256 timestamp );
    function _buyWorkers(address user, uint256 amount, address ref,  bool fromSwap) private {
        // require(amount >= minerSettings.minBuy, 'Buy too small');
        require(activeFeatures.minerActive && activeFeatures.minerBuy && amount >= minerSettings.minBuy && amount <= minerSettings.maxBuy, 'Cant Buy');
        require(minerSettings.maxPerAddress == 0 || (userStats[user].purchaseValue + amount) <= minerSettings.maxPerAddress, 'Max buy amount reached');

        uint256 fee = totalFees();
        
        uint256 workersBought = calculateWorkerBuy(amount,(address(this).balance - amount));
        workersBought = workersBought - getFee(workersBought,fee);

        // see if we have a valid multiplier nft
        if(currentMultiplier[user].startTime > 0) {
            if(currentMultiplier[user].endTime < block.timestamp) {
                // expired, reset the current multiplier
                delete currentMultiplier[user];
            } else {
                // valid multiplier, multiply the post fee amount 
                workersBought = ((workersBought * currentMultiplier[user].multiplier)/100);
            }
        }

        uint256 toBuy = getFee(amount,fees.buyFee);
        uint256 toDev = getFee(amount,fees.devFee);
        uint256 toTreasury = getFee(amount,fees.treasuryFee);
        uint256 toInvest = getFee(amount,fees.investFee);

        if(userStats[user].firstBuy == 0){
            userStats[user].firstBuy = block.timestamp;
        }

        userStats[user].purchaseValue = userStats[user].purchaseValue + amount; 
        
        bool sent;
        // send the fee to the treasuryWallet
        if(toDev > 0) {
            (sent,) = devWallet.call{value: (toDev)}("");
            require(sent,"send failed");
        }

        if(toTreasury > 0) {
            (sent,) = treasuryWallet.call{value: (toTreasury)}("");
            require(sent,"send failed");
        }

        // send to the invest wallet
        if(toInvest > 0) {
            (sent,) = investWallet.call{value: (toInvest)}("");
            require(sent,"send failed");
        }

        // do the buyback
        if(toBuy > 0) {
            swapFromFees(toBuy);
        }

        claimedWorkers[user] = claimedWorkers[user] + workersBought;

        emit WorkersBought(user, ref, amount, workersBought, fromSwap, block.timestamp );

        _claimWorkers(msg.sender,ref,true);
    }

    


    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private view returns(uint256) {
        return (PSN * bs)/(PSNH + ( ((PSN * rs) + (PSNH * rt))/rt) );
    }
    
    function calculateWorkerSell(uint256 workers) public view returns(uint256) {
        return calculateTrade(workers,marketWorkers,address(this).balance);
    }
    
    function calculateWorkerBuy(uint256 amount,uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(amount,contractBalance,marketWorkers);
    }
    
    function calculateWorkerBuySimple(uint256 amount) public view returns(uint256) {
        return calculateWorkerBuy(amount,address(this).balance);
    }
    
    function totalFees() private view returns(uint256) {
        return fees.buyFee + fees.devFee + fees.treasuryFee + fees.investFee;
    }

    function totalPenalty() private view returns(uint256) {
        return fees.buyPenalty + fees.devPenalty + fees.treasuryPenalty + fees.investPenalty;
    }

    function getFee(uint256 amount, uint256 fee) private pure returns(uint256) {
        return (amount * fee)/1000;
    }
    
    event MarketInitialized(uint256 startTime, uint256 marketWorkers);
    function seedMarket() public payable onlyOwner {
        require(marketWorkers == 0);

        initialized = true;
        marketWorkers = 108000000000;

        emit MarketInitialized(block.timestamp, marketWorkers);
    }


    function setContracts(IERC20 _token) public onlyOwner {
        token = _token;
    }
    
    // manage which contracts/addresses can give shares to allow other contracts to interact
    function setCanGive(address _addr, bool _canGive) public onlyOwner {
        canGive[_addr] = _canGive;
    }


    function setWallets(
        address _devWallet, 
        address _treasuryWallet, 
        address _investWallet, 
        address _tokenReceiver 
    ) public onlyOwner {
        devWallet = payable(_devWallet);
        treasuryWallet = payable(_treasuryWallet);
        investWallet = payable(_investWallet);
        tokenReceiver = _tokenReceiver;
    }

    event FeeChanged(
        uint256 refFee, 
        uint256 buyFee, 
        uint256 devFee,
        uint256 treasuryFee, 
        uint256 investFee, 
        uint256 buyPenalty, 
        uint256 devPenalty, 
        uint256 treasuryPenalty,
        uint256 investPenalty
    );

    function setFees(
        uint256 _refFee,
        uint256 _buyFee, 
        uint256 _devFee, 
        uint256 _treasuryFee,
        uint256 _investFee,
        uint256 _buyPenalty, 
        uint256 _devPenalty, 
        uint256 _treasuryPenalty,
        uint256 _investPenalty
    ) public onlyOwner {

        require(_refFee <= MAX_REF_FEE && (_buyFee + _devFee + _treasuryFee + _investFee) <= MAX_BUY_FEE && (_buyPenalty + _devPenalty + _treasuryPenalty + _investPenalty) <= MAX_PENALTY_FEE, 'fee too high');
        // require((_buyFee + _devFee + _investFee) <= MAX_BUY_FEE, "Fee capped at 20%");
        // require((_buyPenalty + _devPenalty + _investPenalty) <= MAX_PENALTY_FEE, "Penalty capped at 60%");

         fees = FeesInfo({
            refFee: _refFee,
            buyFee: _buyFee,
            devFee: _devFee,
            treasuryFee: _treasuryFee,
            investFee: _investFee,
            buyPenalty: _buyPenalty,
            devPenalty: _devPenalty,
            treasuryPenalty: _treasuryPenalty,
            investPenalty: _investPenalty
        });

         
         emit FeeChanged(
            _refFee,
            _buyFee,
            _devFee,
            _treasuryFee,
            _investFee,
            _buyPenalty,
            _devPenalty,
            _treasuryPenalty,
            _investPenalty
        );
        // emit FeeChanged(_refFee, (_buyFee + _devFee + _treasuryFee + _investFee), (_buyPenalty + _devPenalty + _treasuryPenalty + _investPenalty), block.timestamp);
    }

    event ActiveFeaturesSet(bool minerActive, bool lpEnabled, bool minerBuy, bool minerCompound);
    function setActiveFeatures(
        bool _minerActive,
        bool _lpEnabled, // if we add to lp or not
        bool _minerBuy, 
        bool _minerCompound
    ) public onlyOwner {
        activeFeatures.minerActive = _minerActive;
        activeFeatures.lpEnabled = _lpEnabled;
        activeFeatures.minerBuy = _minerBuy;
        activeFeatures.minerCompound = _minerCompound;
        emit ActiveFeaturesSet(_minerActive, _lpEnabled, _minerBuy, _minerCompound);
    }

    event MinerSettingsSet(
        uint256 maxPerAddress, 
        uint256 minBuy, 
        uint256 maxBuy,
        uint256 minRefAmount, 
        uint256 maxRefMultiplier,
        uint256 sellDuration,
        // bool _buyFromTokenEnabled,
        bool noSell,
        bool refCompoundEnabled,
        uint256 pendingLock);

    function setMinerSettings(
        uint256 _maxPerAddress, 
        uint256 _minBuy, 
        uint256 _maxBuy,
        uint256 _minRefAmount, 
        uint256 _maxRefMultiplier,
        uint256 _sellDuration,
        // bool _buyFromTokenEnabled,
        bool _noSell,
        bool _refCompoundEnabled,
        uint256 _pendingLock
    ) public onlyOwner {
        

         minerSettings = MinerSettings({
            maxPerAddress: _maxPerAddress,
            minBuy: _minBuy,
            maxBuy: _maxBuy,
            minRefAmount: _minRefAmount,
            maxRefMultiplier: _maxRefMultiplier,
            sellDuration: _sellDuration,
            // buyFromTokenEnabled: _buyFromTokenEnabled,
            noSell: _noSell,
            refCompoundEnabled: _refCompoundEnabled,
            pendingLock: _pendingLock
        });

         emit MinerSettingsSet(
            _maxPerAddress,
            _minBuy,
            _maxBuy,
            _minRefAmount,
            _maxRefMultiplier,
            _sellDuration,
            _noSell,
            _refCompoundEnabled,
            _pendingLock
        );
    }
    
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    function getTotalShares() external view returns(uint256) {
        return totalShares;
    }

    function getMyShares(address adr) public view returns(uint256) {
        return userShares[adr];
    }
    
    function getMyWorkers(address adr) public view returns(uint256) {
        return claimedWorkers[adr] + getWorkersSinceLastClaim(adr);
    }
    
    function getWorkersSinceLastClaim(address adr) public view returns(uint256) {
        uint256 secondsPassed;

        // if last claim is > 24 hours lock it
        if(minerSettings.pendingLock > 0 && (lastClaim[adr] + (minerSettings.pendingLock * 1 days)) < block.timestamp ){
            secondsPassed = (minerSettings.pendingLock * 1 days);
        } else {
            secondsPassed=min(COST_FOR_SHARE,(block.timestamp - lastClaim[adr]));
        }
        return secondsPassed * userShares[adr];
    }

    function getReferral(address adr) public view returns(address) {
        return referrals[adr];
    }

    function getLastClaim(address adr) public view returns(uint256) {
        return lastClaim[adr];
    }

    function getSharesValue(uint256 shares) public view returns(uint256) {
        return calculateWorkerSell(shares * COST_FOR_SHARE);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    function isInitialized() external view returns (bool){
        return initialized;
    }

    function giveShares(address _addr, uint256 _amount, bool _forceClaim) public {
        require(canGive[msg.sender], "Can't give");
        _addShares(_addr,_amount,_forceClaim);
    }

    function removeShares(address _addr, uint256 _amount) public {
        require(canGive[msg.sender], "Can't remove");
        _removeShares(_addr,_amount,false);
    }

    //adds shares
    function _addShares(address _addr, uint256 _amount, bool _forceClaim) private {

        claimedWorkers[_addr] = claimedWorkers[_addr] + (_amount * COST_FOR_SHARE) / 1 ether;
        if(_forceClaim){
            _claimWorkers(_addr,_addr,false);
        }
    }

    event SharesRemoved(address indexed user, uint256 amount, uint256 marketWorkers);
    //removes shares
    function _removeShares(address _addr, uint256 _amount, bool direct) private {
        // claim first
        if(!direct){
            _claimWorkers(_addr,_addr,false);
        }

        uint256 toRemove = _amount/ 1 ether;
        userShares[_addr] = userShares[_addr] - toRemove;
        totalShares = totalShares - toRemove;
        
        // remove workers from the market

        marketWorkers = marketWorkers - ((toRemove * COST_FOR_SHARE)/5);
        emit SharesRemoved(_addr, toRemove, marketWorkers);
    }

    /**
     * @dev Exit the vault by giving up all of your shares
     * We give up to 50% of the shares value, up to their initial investment
     * user data is reset 
     */
    event UserGTFO(address indexed user, uint256 shares, uint256 amount, uint256 timestamp); 
    function GTFO() public nonReentrant {
        require(userStats[msg.sender].purchaseValue > 0, 'No Bought Shares');
        require(block.timestamp >= (userStats[msg.sender].lastSell + minerSettings.sellDuration), 'too soon');
        _claimWorkers(msg.sender,msg.sender,false);

        uint256 shares = getMyShares(msg.sender);
        uint256 maxReturn = getSharesValue(shares)/2;
        uint256 toSend = maxReturn;

        if(maxReturn > userStats[msg.sender].purchaseValue){
            toSend = userStats[msg.sender].purchaseValue;
        }


        // reset the user
        delete userStats[msg.sender];

        // flag the reset
        userStats[msg.sender].lastReset = block.timestamp;

        // remove the shares
        _removeShares(msg.sender,shares * 1 ether,true);

        if(toSend > 0) {
            (bool sent,) = payable(msg.sender).call{value: (toSend)}("");
            require(sent,"send failed");
        }

        emit UserGTFO(msg.sender, shares, toSend, block.timestamp);

    }
/*
    function buyFromToken(uint256 tokenAmount, IERC20 tokenAddress, address ref) public isInitialized {
        require(minerSettings.buyFromTokenEnabled,'not enabled');

        // transfer the ERC20 token
        tokenAddress.safeTransferFrom(address(msg.sender), address(this), tokenAmount);

        // get current balance
        uint256 currentBalance = address(this).balance;

        // do the swap
        swapTokenForNative(tokenAmount, tokenAddress);

        // get new balance and amount to buy
        uint256 toBuy = address(this).balance - currentBalance;

        // make the buy
        _buyWorkers(msg.sender,toBuy,ref,true);
    }


    function swapTokenForNative(uint256 tokenAmount, IERC20 tokenAddress) private {
        _swapTokenForNative(tokenAmount, tokenAddress, address(this));
    }


    //swaps tokens on the contract for Native
    function _swapTokenForNative(uint256 tokenAmount, IERC20 fromToken, address toAddress) private {
        address[] memory path = new address[](2);
        path[0] = address(fromToken);
        path[1] = swapRouter.WETH();

        swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(toAddress),
            block.timestamp
        );
    }

*/    
    function swapFromFees(uint256 amount) private {
         _swapNativeForToken(amount, token, address(tokenReceiver));
    }

    //swaps Native for a token
    function _swapNativeForToken(uint256 amount, IERC20 toToken, address toAddress) private {
        address[] memory path = new address[](2);
        path[0] = swapRouter.WETH();
        path[1] = address(toToken);

        swapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            address(toAddress),
            block.timestamp
        );
    }

    // LP Functions
    //Adds Liquidity directly to the contract where LP are locked
    function _addLiquidity(uint256 tokenamount, uint256 nativeamount) private {
        // vaultStats.totalLPNative+=nativeamount;
        // vaultStats.totalLPToken+=tokenamount;
        token.approve(address(swapRouter), tokenamount);
        try swapRouter.addLiquidityETH{value: nativeamount}(
            address(token),
            tokenamount,
            0,
            0,
            address(this),
            block.timestamp
        ){}
        catch{}
    }

    function extendLiquidityLock(uint256 secondsUntilUnlock) public onlyOwner {
        uint256 newUnlockTime = secondsUntilUnlock+block.timestamp;
        require(newUnlockTime>liquidityUnlockTime);
        liquidityUnlockTime=newUnlockTime;
    }

    // unlock time for contract LP
    uint256 public liquidityUnlockTime;

    // default for new lp added after release
    uint256 private constant DefaultLiquidityLockTime=3 days;

    //Release Liquidity Tokens once unlock time is over
    function releaseLiquidity() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= liquidityUnlockTime, "Locked");
        liquidityUnlockTime=block.timestamp+DefaultLiquidityLockTime;       
        IERC20Uniswap liquidityToken = IERC20Uniswap(swapPair);
        // uint256 amount = liquidityToken.balanceOf(address(this));

        // only allow 20% 
        // amount=amount*2/10;
        liquidityToken.transfer(treasuryWallet, (liquidityToken.balanceOf(address(this)) * 2) / 10);
    }

    event OnVaultReceive(address indexed sender, uint256 amount, uint256 toHolders, uint256 toLp);
    receive() external payable {

        // @TODO
        // Check if it's coming from the gateway address
        // don't add LP (LP added to sidechains pool)

        // Send half to LP
        uint256 lpBal = msg.value / 2;
        uint256 shareBal = msg.value - lpBal;

        //if we have no shares 100% LP    
        if(totalShares <= 0){
            lpBal = msg.value;
            shareBal = 0;
        }

        // return change to all the share holders 
        if(!activeFeatures.lpEnabled || msg.sender == address(swapRouter)){
            lpBal = 0;
            shareBal = msg.value;
        } else {

            // split the LP part in half
            uint256 nativeToSpend = lpBal / 2;
            uint256 nativeToPost = lpBal - nativeToSpend;

            // get the current mPCKT balance
            uint256 contractTokenBal = token.balanceOf(address(this));
           
            // do the swap
            _swapNativeForToken(nativeToSpend,token, address(this));

            //new balance
            uint256 tokenToPost = token.balanceOf(address(this)) - contractTokenBal;

            // add LP
            _addLiquidity(tokenToPost, nativeToPost);
        }

        emit OnVaultReceive(msg.sender, msg.value, shareBal, lpBal);
    }

    // move any tokens sent to the contract
    function teamTransferToken(address tokenAddress, address recipient, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid Address");
        IERC20 _token = IERC20(tokenAddress);
        _token.safeTransfer(recipient, amount);
    }


    // pull all the native out of the contract, needed for migrations/emergencies
    function withdrawETH() external onlyOwner {
         (bool sent,) =address(owner()).call{value: (address(this).balance)}("");
        require(sent,"withdraw failed");
    }

    modifier _isInitialized {
      require(initialized, "Vault Miner has not been initialized");
      _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IUniswapV2Pair {
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

interface IUniswapV2Router01 {
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

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}