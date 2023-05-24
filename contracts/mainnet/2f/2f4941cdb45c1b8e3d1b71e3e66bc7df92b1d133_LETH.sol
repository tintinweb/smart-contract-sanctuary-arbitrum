/*

LETH is an experimental self-marketmaking token using liquidity bins on Trader Joe v2.1
Forked from Lotus Token
This token is an attempt at a store of value cryptocurrency, with a likely floor price. 
The floor price is not guaranteed. This token is not an investment vehicle, it is an experiment. 

 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeTransferLib} from "./SafeTransferLib.sol";
import {ERC20} from "./ERC20.sol";

import "./Ownable.sol";
import "./ILBPair.sol";
import "./ILBRouter.sol";
import "./ILBToken.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

import "./Constants.sol";
import {PriceHelper} from "./PriceHelper.sol";

contract LETH is ERC20, Ownable {
    using SafeTransferLib for address payable;
    using SafeMath for uint256;
    using PriceHelper for uint256;

    ILBRouter public joeRouter;
    ILBPair public pair;
    address public vault; //staking contract
    address public immutable NATIVE; //weth
    address private devWallet;
    address private stakedLGIFTWallet;

    bool public rebalancesEnabled;
    bool public feesEnabled;
    bool isRebalancing;

    // JOE LIQ
    uint16 public binStep; //bin steps
    uint24 public startBin; //starting bin
    uint256 public lastRecordedActiveBin; //recorded bin to know where rebalances occur.
    uint24 public maxBin; //this is the last bin where we have liq
    uint256 public xPerBin; //xToken amount per bin
    uint256 public slippageToleranceMultiplier = 99;

    uint24 public floorLiquidityBin; //the floor where bin liquidity sits.
    uint24 public tightLiqBin; //bin for active trading

    /// @dev updated fee breakdown
    uint24 public seedLiquidityTimes; //for initialize function

    uint256 public maxSupply;
    bool public beginGame;

    mapping(address => bool) public isDexFeePair;
    bool flagDexPair = false;

    mapping(address => bool) public isDexSellPair;
    bool flagSellPair = false;

    uint256 public stakeFloorFee = 100; //5~10%     7.5%
    uint256 public devFee = 10; //0.2~1%            0.6%
    uint256 public marketFee = 30; //0.6~3% burn    1.8%
    uint256 public burnFee = 30; //0.6~3% burn      1.8%
    uint256 public stakeSellFee = 20; //0.4~2%      1.2%
    uint256 public stakeLGIFTFee = 10; //0.2~1%     0.6%

    uint256 public rebalanceBinCounter = 5;

    //Auto Fee
    bool public autoFeeRateEnabled = false;
    uint256 public buyFloorMoveFee = 1;
    uint256 public sellFloorMoveFee = 1;
    uint256 public sellFloorMoveLimitFee = 50;
    uint64 public autoFloorFeeInterval = 28800;
    uint256 public buyOnFloorTotal = 0;
    uint256 public sellOnFloorTotal = 0;
    uint64 public lastFloorRateUpdateTime = uint64(block.timestamp);
    bool public floorFeeRateCounterState = false;
    uint256 public lastFloorstakeFloorFee = 50;
    uint256 public lastFloordevFee = 0;
    uint256 public lastFloormarketFee = 0;

    //More reward for buyer
    bool public floorBuyerGetLGIFTEnabled = false;
    address public LGIFTToken;

    //rebalanceMax add Bin
    bool public rebalanceMaxBinEnabled = false;

    //rebalanceFloorBinEnabled
    bool public rebalanceFloorBinEnabled = false;

    //initialize
    int256 public lastseedIndex = 0;

    constructor(
        ILBRouter joeRouter_,
        address native_,
        uint256 maxSupply_,
        address devWallet_
    ) ERC20("LETH", "LETH", 18) {

        joeRouter = joeRouter_;
        NATIVE = native_;
        devWallet = devWallet_;
        maxSupply = maxSupply_ * 1 ether;
        rebalancesEnabled = true;
        feesEnabled = true;
        vault = devWallet_;
        stakedLGIFTWallet = devWallet_;
        _mint(address(this), maxSupply);
    }

    modifier rebalanceAllowed() {
        if (binStep == 0 || floorLiquidityBin == getActiveBinId()) {
            revert("At floor");
        }
        if ((getActiveBinId() - lastRecordedActiveBin) > rebalanceBinCounter 
        && maxBin >= (getActiveBinId() + 1) && rebalancesEnabled) {
            _;
        } else {
            revert("Out of range");
        }
    }

    //====================================================================================================================
    // Initialize functions - messy cause developed via hackaton and would run out of gas otherwise. works on my machine.
    //====================================================================================================================

    function initialize(
        address pair_
    ) external payable onlyOwner {
        require(seedLiquidityTimes < 10, "initialized");

        uint24 binNum = 1000;
        if (seedLiquidityTimes == 0) {
            pair = ILBPair(pair_);

            binStep = pair.getBinStep();

            startBin = getActiveBinId();
            lastRecordedActiveBin = getActiveBinId() + 1; // add one because it's where our liquidity sits

            approvals();

            maxBin = getActiveBinId() + binNum;

            xPerBin = maxSupply / binNum;
        }

        uint256 seedIndex = 100;
        uint256 seedLiquidityLETH = maxSupply/10;

        isRebalancing = true;

        int256[] memory deltaIds = new int256[](seedIndex);
        uint256[] memory distributionX = new uint256[](seedIndex);
        uint256[] memory distributionY = new uint256[](seedIndex);

        for (uint256 i = 0; i < seedIndex; i++) {

            deltaIds[i] = lastseedIndex + (int256(i)+1);
            distributionX[i] = seedLiquidityLETH/100;
            distributionY[i] = 0;
        }

        lastseedIndex += 100;

        addLiquidity(deltaIds,distributionX,distributionY,getActiveBinId());

        isRebalancing = false;

        seedLiquidityTimes = seedLiquidityTimes + 1;
    }

    //=============================================================================
    // Rebalance
    //=============================================================================

    // Rebalance liquidity
    function rebalanceLiquidity() external rebalanceAllowed {

        isRebalancing = true;

        removeLiquidity();

        uint256 totalEthInContract = IERC20(NATIVE).balanceOf(address(this));

        uint256 totalLotusInPool = (maxBin - (getActiveBinId() + 1)) * xPerBin;

        uint256 totalCirculatingSupply = totalSupply -
            (totalLotusInPool +
                balanceOf[0x000000000000000000000000000000000000dEaD]);

        uint256 newFloorPrice = getAverageTokenPrice(
            totalEthInContract,
            totalCirculatingSupply
        );

        uint24 expectedFloorBin = joeRouter.getIdFromPrice(
            pair,
            newFloorPrice.convertDecimalPriceTo128x128()
        );

        floorLiquidityBin = expectedFloorBin > getActiveBinId()
            ? getActiveBinId() - 1
            : expectedFloorBin;

        int256 deltaForMainLiq = -(int24(getActiveBinId()) -
            int256(int24(floorLiquidityBin)));

        tightLiqBin = getActiveBinId() - 1;

        int256[] memory deltaIds = new int256[](2);
        deltaIds[0] = deltaForMainLiq;
        deltaIds[1] = -1;

        uint256[] memory distributionX = new uint256[](2);
        distributionX[0] = 0;
        distributionX[1] = 0;

        uint256[] memory distributionY = new uint256[](2);

        // @dev changed %'s
        distributionY[0] = (Constants.PRECISION * 90) / 100;
        distributionY[1] = (Constants.PRECISION * 10) / 100;

        addLiquidity(deltaIds, distributionX, distributionY, getActiveBinId());

        isRebalancing = false;
    }

    //if we finish lotus side supply in the pool, burns happen so floor can still go up, need dedicated rebalance
    function rebalanceMax() external {
        require(
            getActiveBinId() > maxBin && rebalancesEnabled,
            "Not there yet"
        );

        if(rebalanceMaxBinEnabled){
            if((getActiveBinId() - lastRecordedActiveBin) > rebalanceBinCounter){
                
            }
            else{
                revert("Not there yet");
            }
        }

        isRebalancing = true;

        if(rebalanceFloorBinEnabled){
            removeMaxToFloorBinLiquidity();
        }

        // step 1 remove liquidity only from the floor bin
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory ids = new uint256[](1);

        ids[0] = floorLiquidityBin;
        amounts[0] = pair.balanceOf(address(this), ids[0]);

        pair.burn(address(this), address(this), ids, amounts);

        // step 2 calculate new floor price and add liq to that price
        uint256 totalEthInContract = IERC20(NATIVE).balanceOf(address(this));

        uint256 totalLotusInPool = 0; // 0 because we finished our range

        uint256 totalCirculatingSupply = totalSupply -
            (totalLotusInPool +
                balanceOf[0x000000000000000000000000000000000000dEaD]);

        uint256 newFloorPrice = getAverageTokenPrice(
            totalEthInContract,
            totalCirculatingSupply
        );

        uint24 expectedFloorBin = joeRouter.getIdFromPrice(
            pair,
            newFloorPrice.convertDecimalPriceTo128x128()
        );

        require(expectedFloorBin > floorLiquidityBin, "no");

        floorLiquidityBin = expectedFloorBin > getActiveBinId()
            ? getActiveBinId() - 1
            : expectedFloorBin;

        lastRecordedActiveBin = getActiveBinId();

        int256 deltaForMainLiq = -(int24(getActiveBinId()) -
            int(int24(floorLiquidityBin)));

        int256[] memory deltaIds = new int256[](1);
        deltaIds[0] = deltaForMainLiq;

        uint256[] memory distributionX = new uint256[](1);
        distributionX[0] = 0;

        uint256[] memory distributionY = new uint256[](1);

        distributionY[0] = Constants.PRECISION;

        addLiquidity(deltaIds, distributionX, distributionY, getActiveBinId());

        isRebalancing = false;

        //require(IERC20(NATIVE).balanceOf(address(this)) < 1 ether, "failed");
    }


    function removeLiquidity() internal {
        bool isInsideRange = false;

        uint256 numberOfBinsToWithdraw = (getActiveBinId() -
            lastRecordedActiveBin);

        numberOfBinsToWithdraw = floorLiquidityBin == 0
            ? numberOfBinsToWithdraw
            : numberOfBinsToWithdraw + 1;

        if (
            tightLiqBin >= lastRecordedActiveBin &&
            tightLiqBin <= lastRecordedActiveBin + numberOfBinsToWithdraw
        ) {
            isInsideRange = true;
        } else {
            if (floorLiquidityBin > 0) {
                isInsideRange = false;
                if(tightLiqBin < getActiveBinId() && tightLiqBin > 0){
                    numberOfBinsToWithdraw++;
                }
            }
        }

        uint256[] memory amounts = new uint256[](numberOfBinsToWithdraw);
        uint256[] memory ids = new uint256[](numberOfBinsToWithdraw);

        for (uint256 i; i < numberOfBinsToWithdraw; i++) {
            ids[i] = lastRecordedActiveBin + i;
        }

        if (floorLiquidityBin != 0) {
            ids[ids.length - 1] = floorLiquidityBin;

            if(tightLiqBin < getActiveBinId() && tightLiqBin > 0){
                if (!isInsideRange) ids[numberOfBinsToWithdraw - 2] = tightLiqBin;
            }
        }

        lastRecordedActiveBin = getActiveBinId();

        for (uint256 i; i < numberOfBinsToWithdraw; i++) {
            uint256 LBTokenAmount = pair.balanceOf(address(this), ids[i]);

            amounts[i] = LBTokenAmount;
        }

        pair.burn(address(this), address(this), ids, amounts);
    }

    function removeMaxToFloorBinLiquidity() internal {

        uint256 numberOfBinsToWithdraw = (getActiveBinId() -
            floorLiquidityBin);

        uint256[] memory amounts = new uint256[](numberOfBinsToWithdraw);
        uint256[] memory ids = new uint256[](numberOfBinsToWithdraw);

        for (uint256 i; i < numberOfBinsToWithdraw; i++) {
            ids[i] = (floorLiquidityBin + i + 1);
        }

        for (uint256 i; i < numberOfBinsToWithdraw; i++) {
            uint256 LBTokenAmount = pair.balanceOf(address(this), ids[i]);

            amounts[i] = LBTokenAmount;
        }

        pair.burn(address(this), address(this), ids, amounts);
    }

    function addLiquidity(
        int256[] memory deltaIds,
        uint256[] memory distributionX,
        uint256[] memory distributionY,
        uint24 activeIdDesired
    ) internal {
        uint256 amountX = balanceOf[address(this)];
        uint256 amountY = IERC20(NATIVE).balanceOf(address(this));

        uint256 amountXmin = (amountX * slippageToleranceMultiplier) / 100; // We allow 1% amount slippage
        uint256 amountYmin = (amountY * slippageToleranceMultiplier) / 100; // We allow 1% amount slippage

        uint256 idSlippage = 0;

        ILBRouter.LiquidityParameters memory liquidityParameters = ILBRouter
            .LiquidityParameters(
                IERC20(address(this)),
                IERC20(NATIVE),
                binStep,
                amountX,
                amountY,
                amountXmin,
                amountYmin,
                activeIdDesired, //activeIdDesired
                idSlippage,
                deltaIds,
                distributionX,
                distributionY,
                address(this),
                address(this),
                block.timestamp
            );

        joeRouter.addLiquidity(liquidityParameters);
    }



    // remove LP only from floorBin
    function removeFloorBinLiquidity() internal {

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = floorLiquidityBin;
        amounts[0] = pair.balanceOf(address(this), floorLiquidityBin);

        pair.burn(address(this), address(this), ids, amounts);
    }

    // remove LP only from tightLiqBin
    function _removeTightLiqBinLiquidity() internal {

        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = tightLiqBin;
        amounts[0] = pair.balanceOf(address(this), tightLiqBin);

        pair.burn(address(this), address(this), ids, amounts);
    }

    function addLiquidityForNewBin(
        uint256 tokenXbalance, uint24 binId
    ) internal {
        addLiquidityForBin(tokenXbalance,0,binId);
    }

    function addLiquidityForFloorBin(
        uint256 tokenXbalance, uint256 tokenYbalance, uint24 binId
    ) internal {
        addLiquidityForBin(tokenXbalance,tokenYbalance,binId);
    }

    function addLiquidityForBin(
        uint256 tokenXbalance, uint256 tokenYbalance, uint24 binId
    ) internal {

        // memory
        int256[] memory deltaIds = new int256[](1);
        uint256[] memory distributionX = new uint256[](1);
        uint256[] memory distributionY = new uint256[](1);

        // distribute 100%
        deltaIds[0] = 0;
        distributionX[0] = tokenXbalance;
        distributionY[0] = tokenYbalance;

        addLiquidity(deltaIds,distributionX,distributionY,binId);
    }

    //rebalance FloorBin Liquidity
    function rebalanceFloorBinLiquidity() external {
        //floor bin
        require(rebalanceFloorBinEnabled);
        require(getActiveBinId() == floorLiquidityBin);

        uint256 _tokenX;
        uint256 _tokenY;
        (_tokenX, _tokenY) = pair.getBin(uint24(floorLiquidityBin));

        require(_tokenX > xPerBin);
        require(canRebalanceFloorBin());

        //check tokenX > xPerBin
        isRebalancing = true;

        //check lastRecordedActiveBin
        //remove FBL
        removeFloorBinLiquidity();

        //check tightLiqBin
        //reset tightLiqBin
        uint256 tmpTightLiqBin = tightLiqBin;
        if(tightLiqBin > 0){
            uint256 _tbtokenX;
            uint256 _tbtokenY;
            (_tbtokenX, _tbtokenY) = pair.getBin(uint24(tightLiqBin));

            if(_tbtokenX > xPerBin){
                _removeTightLiqBinLiquidity();
                addLiquidityForNewBin(xPerBin,uint24(tightLiqBin));
                tightLiqBin = 0;
            }
        }

        uint256 tokenXbalance = balanceOf[address(this)];
        uint256 tokenYbalance = IERC20(NATIVE).balanceOf(address(this));

        bool addToNewBin = false;

        if(lastRecordedActiveBin > (getActiveBinId()+1)){
            lastRecordedActiveBin = lastRecordedActiveBin - 1;

            if(lastRecordedActiveBin == tmpTightLiqBin){
                lastRecordedActiveBin = lastRecordedActiveBin - 1;
            }

            if(lastRecordedActiveBin<=getActiveBinId()){
                lastRecordedActiveBin = getActiveBinId()+1;
            }

            uint256 _lrtokenX;
            uint256 _lrtokenY;
            (_lrtokenX, _lrtokenY) = pair.getBin(uint24(lastRecordedActiveBin));

            if(_lrtokenX < xPerBin && lastRecordedActiveBin > getActiveBinId()){
                //tokenX to lastRecordedActiveBin
                addLiquidityForNewBin(xPerBin,uint24(lastRecordedActiveBin));
                addToNewBin = true;
            }
        }

        if(!addToNewBin){
            if(maxBin < getActiveBinId()){
                maxBin = getActiveBinId();
            }

            //new maxBin
            maxBin = maxBin + 1;

            //tokenX to maxBin
            addLiquidityForNewBin(xPerBin,maxBin);
            addToNewBin = true;
        }

        //add LP back to floorbin
        uint256 tokenXFloorBalance = tokenXbalance;
        if(addToNewBin){
            tokenXFloorBalance = tokenXbalance - xPerBin;
        }

        addLiquidityForFloorBin(tokenXFloorBalance,tokenYbalance,floorLiquidityBin);
        
        isRebalancing = false;
    }

    function setFee(uint256 devFee_ , uint256 marketFee_ , uint256 burnFee_ , uint256 stakeSellFee_ , uint256 stakeFloorFee_ , uint256 stakeLGIFTFee_) public onlyOwner{
        if(devFee_<=30){
            devFee = devFee_;
        }
        if(marketFee_<=30){
            marketFee = marketFee_;
        }
        if(burnFee_<=100){
            burnFee = burnFee_;
        }
        if(stakeFloorFee_<=150){
            stakeFloorFee = stakeFloorFee_;
        }
        if(stakeSellFee_<=100){
            stakeSellFee = stakeSellFee_;
        }
        if(stakeLGIFTFee_<=30){
            stakeLGIFTFee = stakeLGIFTFee_;
        }
    }

    function setFloorAutoFee(uint256 buyFloorMoveFee_, uint256 sellFloorMoveFee_, uint256 sellFloorMoveLimitFee_, uint64 autoFloorFeeInterval_) public onlyOwner{
        buyFloorMoveFee = buyFloorMoveFee_;
        sellFloorMoveFee = sellFloorMoveFee_;
        sellFloorMoveLimitFee = sellFloorMoveLimitFee_;
        autoFloorFeeInterval = autoFloorFeeInterval_;
    }

    function setWallet(address devWallet_ , address stakedLGIFTWallet_) public onlyOwner{
        devWallet = devWallet_;
        stakedLGIFTWallet = stakedLGIFTWallet_;
    }

    function setSellPairs(address _onlySellpair, bool _enabled) public onlyOwner{
        isDexSellPair[_onlySellpair] = _enabled;
    }

    function isSellPair(address _pair) internal {
        flagSellPair = true;
        if(!isDexSellPair[_pair]){
            flagSellPair = false;
        }
    }

    function setDexPairs(address _dexpair, bool _enabled) public onlyOwner{
        isDexFeePair[_dexpair] = _enabled;
    }

    function isDexPair(address _pair) internal {
        flagDexPair = true;
        if(!isDexFeePair[_pair]){
            flagDexPair = false;
        }
    }

    function setAutoFeeRateEnabled(bool _autoFee) external onlyOwner {
        autoFeeRateEnabled = _autoFee;
    }

    function setRebalanceFloorBinEnabled(bool _fbEnabled) external onlyOwner {
        rebalanceFloorBinEnabled = _fbEnabled;
    }

    function setRebalanceMaxBinEnabled(bool _rmEnabled) external onlyOwner {
        rebalanceMaxBinEnabled = _rmEnabled;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    function sendLGIFTToken(address to, uint256 amount) internal returns (bool){
        uint256 totalLGIFT = IERC20(LGIFTToken).balanceOf(address(this));
        if(totalLGIFT>amount && !isContract(to))
        {
            IERC20(LGIFTToken).approve(address(this), 2 ** 256 - 1);
            IERC20(LGIFTToken).transferFrom(address(this), to, amount);
        }
        return true;
    }

    function setFloorBuyerGetLGIFTEnabled(bool payLGIFT, address token) external onlyOwner {
        floorBuyerGetLGIFTEnabled = payLGIFT;
        LGIFTToken = token;
    }
    //=============================================================================
    // Tax and transfer mechanism
    //=============================================================================

    /**
     * @notice charge tax on sells and buys functions.
     *     @return _amount remaining to the sender
     */

    function chargeTax(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256 _amount) {
        address fFrom = address(from);
        _amount = amount;
        uint256 rate = 0;

        uint256 fdevFee = devFee;
        uint256 fmarketFee = marketFee;
        uint256 fstakeFloorFee = stakeFloorFee;
        uint256 fstakeSellFee = stakeSellFee;
        uint256 fburnFee = burnFee;
        uint256 fstakeLGIFTFee = stakeLGIFTFee;

        bool isFloorBin = false;
        if (seedLiquidityTimes >0 && getActiveBinId() == floorLiquidityBin){
            isFloorBin = true;
        }

        if (feesEnabled && !isRebalancing && from != (address(this)) && to != (address(this))) {

            if(autoFeeRateEnabled){
                if(seedLiquidityTimes>0){
                    if(getActiveBinId() > lastRecordedActiveBin){
                        uint256 currMoveBin = getActiveBinId() - lastRecordedActiveBin;
                        if(currMoveBin > rebalanceBinCounter){
                            currMoveBin = rebalanceBinCounter;
                        }
                        if(currMoveBin >= 0){
                            rate = currMoveBin;
                        }
                    }
                }

                //FloorBin Auto Fee
                if(isFloorBin){
                    uint64 currFloorRateUpdateTime = uint64(block.timestamp);
                    if(!floorFeeRateCounterState){
                        floorFeeRateCounterState = true;
                        lastFloorRateUpdateTime = uint64(block.timestamp);

                        lastFloorstakeFloorFee = fstakeFloorFee;
                        lastFloordevFee = devFee;
                        lastFloormarketFee = marketFee;
                    }

                    //set last Floor Fee
                    fdevFee = lastFloordevFee;
                    fmarketFee = lastFloormarketFee;
                    fstakeFloorFee = lastFloorstakeFloorFee;

                    uint64 floorRuningTime = currFloorRateUpdateTime - lastFloorRateUpdateTime;
                    if(floorRuningTime>autoFloorFeeInterval){
                        //change Fee
                        if(buyOnFloorTotal>sellOnFloorTotal){
                            lastFloordevFee += buyFloorMoveFee;
                            lastFloormarketFee += buyFloorMoveFee;
                            if(lastFloorstakeFloorFee>sellFloorMoveFee){
                                lastFloorstakeFloorFee -= sellFloorMoveFee;
                                if(lastFloorstakeFloorFee<sellFloorMoveLimitFee){
                                    lastFloorstakeFloorFee = sellFloorMoveLimitFee;
                                }
                            }
                        }else if(buyOnFloorTotal<sellOnFloorTotal){
                            if(lastFloordevFee>buyFloorMoveFee){
                                lastFloordevFee -= buyFloorMoveFee;
                            }
                            if(lastFloormarketFee>buyFloorMoveFee){
                                lastFloormarketFee -= buyFloorMoveFee;
                            }
                            lastFloorstakeFloorFee += sellFloorMoveFee;
                        }else if(buyOnFloorTotal == 0 && sellOnFloorTotal == 0){
                            if(lastFloordevFee>buyFloorMoveFee){
                                lastFloordevFee -= buyFloorMoveFee;
                            }
                            if(lastFloormarketFee>buyFloorMoveFee){
                                lastFloormarketFee -= buyFloorMoveFee;
                            }
                            if(lastFloorstakeFloorFee>sellFloorMoveFee){
                                lastFloorstakeFloorFee -= sellFloorMoveFee;
                                if(lastFloorstakeFloorFee<sellFloorMoveLimitFee){
                                    lastFloorstakeFloorFee = sellFloorMoveLimitFee;
                                }
                            }
                        }

                        //check Fee
                        if(lastFloordevFee>devFee){
                            lastFloordevFee = devFee;
                        }
                        if(lastFloormarketFee>marketFee){
                            lastFloormarketFee = marketFee;
                        }
                        if(lastFloorstakeFloorFee>stakeFloorFee){
                            lastFloorstakeFloorFee = stakeFloorFee;
                        }
                        //updage New Fee
                        fdevFee = lastFloordevFee;
                        fmarketFee = lastFloormarketFee;
                        fstakeFloorFee = lastFloorstakeFloorFee;

                        //reset
                        buyOnFloorTotal = 0;
                        sellOnFloorTotal = 0;
                        lastFloorRateUpdateTime = uint64(block.timestamp);
                    }
                }else{
                    floorFeeRateCounterState = false;
                    buyOnFloorTotal = 0;
                    sellOnFloorTotal = 0;
                    lastFloorRateUpdateTime = uint64(block.timestamp);
                }
            }

            isDexPair(from);
            // buy tax
            if (flagDexPair || from == address(pair)) {

                // todo: figure out fee split
                uint256 devFeeAmount = calculateFee(_amount, fdevFee, rate); // 1.5%
                uint256 marketFeeAmount = calculateFee(_amount, fmarketFee, rate); // 1%

                if(autoFeeRateEnabled){
                    if (isFloorBin) {
                        buyOnFloorTotal += _amount;
                    }
                }

                balanceOf[devWallet] += devFeeAmount;
                emit Transfer(fFrom, devWallet, devFeeAmount);

                unchecked {
                    totalSupply -= marketFeeAmount;
                }
                emit Transfer(fFrom, address(0), marketFeeAmount);

                if(floorBuyerGetLGIFTEnabled){
                    if(isFloorBin){
                        sendLGIFTToken(to, _amount);
                    }
                }

                _amount -= devFeeAmount;
                _amount -= marketFeeAmount;
            }

            isDexPair(to);
            isSellPair(to);
            // sell tax
            if (flagDexPair || (fFrom == address(joeRouter) && to == address(pair))) {
                uint256 sendToVault;
                uint256 burn;
                uint256 sendToLotusVault;
                
                if(!flagSellPair)
                {
                    if (isFloorBin) {
                        sendToVault = calculateFee(_amount, fstakeFloorFee, 0);
                        balanceOf[vault] += sendToVault;
                        emit Transfer(fFrom, vault, sendToVault);

                        sellOnFloorTotal += _amount;

                        _amount -= sendToVault;
                    } else {
                        sendToVault = calculateFee(_amount, fstakeSellFee, rate);
                        burn = calculateFee(_amount, fburnFee, rate);
                        sendToLotusVault = calculateFee(_amount, fstakeLGIFTFee, rate);

                        balanceOf[vault] += sendToVault;
                        emit Transfer(fFrom, vault, sendToVault);

                        balanceOf[stakedLGIFTWallet] += sendToLotusVault;
                        emit Transfer(fFrom, stakedLGIFTWallet, sendToLotusVault);

                        unchecked {
                            totalSupply -= burn;
                        }
                        emit Transfer(fFrom, address(0), burn);

                        _amount -= (sendToVault + burn + sendToLotusVault);
                    }
                }
                else
                {
                    if (isFloorBin) {
                        sendToVault = calculateFee(_amount, fstakeFloorFee, 0);

                        balanceOf[vault] += sendToVault;
                        balanceOf[fFrom] -= sendToVault;

                        sellOnFloorTotal += _amount;
                        
                        emit Transfer(fFrom, vault, sendToVault);
                    } else {
                        sendToVault = calculateFee(_amount, fstakeSellFee, rate);
                        burn = calculateFee(_amount, fburnFee, rate);
                        sendToLotusVault = calculateFee(_amount, fstakeLGIFTFee, rate);

                        balanceOf[vault] += sendToVault;
                        balanceOf[fFrom] -= sendToVault;
                        emit Transfer(fFrom, vault, sendToVault);

                        balanceOf[stakedLGIFTWallet] += sendToLotusVault;
                        balanceOf[fFrom] -= sendToLotusVault;
                        emit Transfer(fFrom, stakedLGIFTWallet, sendToLotusVault);

                        balanceOf[fFrom] -= burn;
                        unchecked {
                            totalSupply -= burn;
                        }
                        emit Transfer(fFrom, address(0), burn);
                    }
                }
            }
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (beginGame == false) {
            revert("Game is not enabled");
        }

        balanceOf[msg.sender] -= amount;

        uint256 _amount = chargeTax(msg.sender, to, amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += _amount;
        }

        emit Transfer(msg.sender, to, _amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (beginGame == false) {
            require(from == address(this) || to == address(this));
        }

        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        //uint256 _amount = chargeTax(msg.sender, to, amount);
        uint256 _amount = chargeTax(from, to, amount);

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += _amount;
        }

        emit Transfer(from, to, _amount);

        return true;
    }

    //=============================================================================
    // Helpers
    //=============================================================================

    function calculateFee(
        uint256 amount,
        uint256 pct,
        uint256 rate
    ) public pure returns (uint256) {
        uint256 feePercentage = Constants.PRECISION.mul(pct).div(1000); // x pct

        if(rate > 0)
        {
            feePercentage = Constants.PRECISION.mul(pct).div((1000*rate));
        }

        return amount.mul(feePercentage).div(Constants.PRECISION);
    }

    function canRebalance() public view returns (bool){
        return ((getActiveBinId() - lastRecordedActiveBin) > rebalanceBinCounter && 
        maxBin >= (getActiveBinId() + 1) && rebalancesEnabled);
    }

    function canRebalanceFloorBin() public view returns (bool){
        bool isFloorActive = (getActiveBinId() == floorLiquidityBin);
        
        uint256 _tokenX;
        uint256 _tokenY;
        (_tokenX, _tokenY) = pair.getBin(uint24(floorLiquidityBin));

        bool isFloorBinTokenXFull = (_tokenX > xPerBin);

        return isFloorActive && isFloorBinTokenXFull && rebalanceFloorBinEnabled;
    }

    function canRebalanceMax() public view returns (bool){
        bool canRMax = false;
        if(getActiveBinId() > maxBin && rebalancesEnabled){
            canRMax =true;

            if(rebalanceMaxBinEnabled){
                if((getActiveBinId() - lastRecordedActiveBin) > rebalanceBinCounter){
                    
                }
                else{
                    canRMax = false;
                }
            }
        }
        return canRMax;        
    }

    /**
     * @notice Helper func.
     */
    function getAverageTokenPrice(
        uint256 totalETH,
        uint256 totalTokens
    ) public pure returns (uint256) {
        require(totalETH < totalTokens, "ETH must be less than total tokens");
        return (totalETH * Constants.PRECISION) / (totalTokens);
    }

    /**
     * @notice returns the current floor price
     */
    function getFloorPrice() public view returns (uint256) {
        return joeRouter.getPriceFromId(pair, floorLiquidityBin);
    }

    /**
     * @notice Get's the pool active bin id.
     */
    function getActiveBinId() public view returns (uint24) {
        return pair.getActiveId();
    }

    function feeReceiver() public view returns (address) {
        return owner();
    }

    //=============================================================================
    // ADMIN
    //=============================================================================

    /**
     * @notice approvals for joe router.
     */
    function approvals() public onlyOwner {
        allowance[address(this)][address(joeRouter)] = 2 ** 256 - 1;
        IERC20(NATIVE).approve(address(joeRouter), 2 ** 256 - 1);

        ILBToken(address(pair)).approveForAll(address(joeRouter), true);
        ILBToken(address(pair)).approveForAll(address(pair), true);
    }

    /**
     * @notice only admin function to disable rebalances and fees in case of bugs.
     *     @param rebalances bool rebalances enabled?.
     *     @param fees bool fees enabled?
     */
    function disableRebalances(bool rebalances, bool fees) external onlyOwner {
        rebalancesEnabled = rebalances;
        feesEnabled = fees;
    }

    // in case of bugs in the staking contract we send to a new vault
    function setNewVault(address newVault) external onlyOwner {
        vault = newVault;
    }

    function startGame() external onlyOwner {
        beginGame = true;
    }

    function setSlippageToleranceMultiplier(
        uint256 newSlippageTolerance
    ) external onlyOwner {
        require(
            newSlippageTolerance > 0 && newSlippageTolerance <= 99,
            "out of slippage range (1-99)"
        );
        slippageToleranceMultiplier = newSlippageTolerance;
    }

    //receive() external payable {}
}