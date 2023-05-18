/*
 ||||||||                   ||||||||
 ||||||||                   ||||||||
 ||||||||   ▄▀▀▀▀▄          ||||||||
 ||||||||   █    █          ||||||||
 ||||||||   ▐    █          ||||||||
 ||||||||        █          ||||||||
 ||||||||       ▄▀▄▄▄▄▄▄▀   ||||||||
 ||||||||       █           ||||||||  
 ||||||||       ▐           ||||||||
 ||||||||-------------------||||||||
 ||||||||-------------------||||||||
 ||||||||      ▄▀▀█▄        ||||||||
 ||||||||     ▐ ▄▀ ▀▄       ||||||||
 ||||||||       █▄▄▄█       |||||||| 
 ||||||||      ▄▀   █       ||||||||
 ||||||||      █   ▄▀       |||||||| 
 ||||||||      ▐   ▐        ||||||||
 ||||||||-------------------||||||||
 ||||||||-------------------||||||||
 ||||||||     ▄▀▀█▄▄        ||||||||
 ||||||||     █ ▄▀   █      |||||||| 
 ||||||||     ▐ █    █      ||||||||
 ||||||||       █    █      ||||||||
 ||||||||      ▄▀▄▄▄▄▀      ||||||||
 ||||||||     █     ▐       ||||||||
 ||||||||     ▐             ||||||||
 ||||||||-------------------||||||||
 ||||||||-------------------||||||||
 ||||||||     ▄▀▀█▄▄        ||||||||
 ||||||||     █ ▄▀   █      |||||||| 
 ||||||||     ▐ █    █      ||||||||
 ||||||||       █    █      ||||||||
 ||||||||      ▄▀▄▄▄▄▀      ||||||||
 ||||||||     █     ▐       ||||||||
 ||||||||     ▐             ||||||||
 ||||||||-------------------||||||||
 ||||||||-------------------||||||||
 ||||||||    ▄▀▀█▄▄▄▄       ||||||||
 ||||||||    ▐  ▄▀   ▐      ||||||||
 ||||||||       █▄▄▄▄▄      |||||||| 
 ||||||||       █    ▌      ||||||||
 ||||||||      ▄▀▄▄▄▄       ||||||||
 ||||||||      █    ▐       ||||||||         
 ||||||||-------------------||||||||
 ||||||||-------------------||||||||
 ||||||||     ▄▀▀▄▀▀▀▄      ||||||||
 ||||||||    █   █   █      ||||||||
 ||||||||    ▐  █▀▀█▀       ||||||||
 ||||||||     ▄▀    █       ||||||||
 ||||||||    █     █        |||||||| 
 ||||||||    ▐     ▐        |||||||| 
 ||||||||                   ||||||||
 ||||||||                   ||||||||
 
 

LADDER is an experimental self-marketmaking token using liquidity bins on Trader Joe v2.1
Forked from White Lotus Token
80% of rebalance goes to floor, 20% goes to wall 
If price moves from wall into floor, the function punishFloorSellers can be activated by anyone to burn the price wall resistance bin.
Because of this new burn mechanic, the sell tax which previously was split between stakers and a burn now all goes to stakers.
This token is an attempt at a store of value cryptocurrency, with a likely floor price. The floor price is not guaranteed. This token is not an investment vehicle, it is an experiment. 
 
LADDER is a fully decentralized protocol. There will be no continued development besides the contracts herein. Full ownership will be revoked and further development
(such as an interface for staking, rebalancing etc) will be the onus of the community
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

contract LADDER is ERC20, Ownable {
    using SafeTransferLib for address payable;
    using SafeMath for uint256;
    using PriceHelper for uint256;

    ILBRouter public joeRouter;
    ILBPair public pair;
    address public vault; //staking contract
    address public immutable NATIVE; //weth
    address private marketWallet;
    address private devWallet;

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
    uint256 public stakeFee = 100; //10%

    uint24 public seedLiquidityTimes; //for initialize function

    uint256 public maxSupply;
    bool public tradingEnabled;

    address[] pairsList;
    bool flagDexPair = false;

    uint256 public devFee = 15; //1.5%
    uint256 public marketFee = 10; //1%
    uint256 public lotusFee = 50; //5%
    uint256 public stakeSellFee = 50; //5%
    address private lotusBuybackWallet;

    constructor(
        ILBRouter joeRouter_,
        address native_,
        uint256 maxSupply_,
        uint256 _xPerBin,
        address devWallet_,
        address marketWallet_
    ) ERC20("SOIL", "SOIL", 18) {

        joeRouter = joeRouter_;
        NATIVE = native_;
        devWallet = devWallet_;
        marketWallet = marketWallet_;

        maxSupply = maxSupply_ * 1 ether;
        rebalancesEnabled = true;
        feesEnabled = true;
        xPerBin = _xPerBin * 1 ether;
        vault = marketWallet_;
        lotusBuybackWallet = marketWallet_;
    }

    modifier rebalanceAllowed() {
        if (binStep == 0 || floorLiquidityBin == getActiveBinId()) {
            revert("At floor");
        }

        if (
            getActiveBinId() - lastRecordedActiveBin > 19 && rebalancesEnabled
        ) {
            _;
        } else {
            revert("Out of range");
        }
    }

    function testMint() external onlyOwner{
        uint256 mintAmount = maxSupply / 12;
        _mint(address(msg.sender), mintAmount);
    }
    //====================================================================================================================
    // Initialize functions - messy cause developed via hackaton and would run out of gas otherwise. works on my machine.
    //====================================================================================================================

    function initialize(
        address pair_,
        int256[] memory deltaIds,
        uint256[] memory distributionX,
        uint256[] memory distributionY
    ) external payable onlyOwner {
        require(seedLiquidityTimes < 12, "initialized");

        if (seedLiquidityTimes == 0) {
            pair = ILBPair(pair_);

            binStep = pair.getBinStep();

            startBin = getActiveBinId();
            lastRecordedActiveBin = getActiveBinId() + 1; // add one because it's where our liquidity sits

            approvals();

            maxBin = getActiveBinId() + 1200;
        }

        _mint(address(this), maxSupply / 12);

        isRebalancing = true;
        addLiquidity(deltaIds, distributionX, distributionY, getActiveBinId());
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
        distributionY[0] = (Constants.PRECISION * 80) / 100;
        distributionY[1] = (Constants.PRECISION * 20) / 100;

        addLiquidity(deltaIds, distributionX, distributionY, getActiveBinId());

        isRebalancing = false;
    }

    function punishFloorSellers() external {
        // Have to be at floor
        require(
            getActiveBinId() == floorLiquidityBin,
            "active bin must be floor"
        );
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory ids = new uint256[](1);
        ids[0] = tightLiqBin;
        amounts[0] = pair.balanceOf(address(this), tightLiqBin) - 1;
        // remove liquidity from tightLiqBin
        pair.burn(address(this), address(this), ids, amounts);

        _burn(address(this), balanceOf[address(this)]);
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
                numberOfBinsToWithdraw++;
            }
        }

        uint256[] memory amounts = new uint256[](numberOfBinsToWithdraw);
        uint256[] memory ids = new uint256[](numberOfBinsToWithdraw);

        for (uint256 i; i < numberOfBinsToWithdraw; i++) {
            ids[i] = lastRecordedActiveBin + i;
        }

        if (floorLiquidityBin != 0) {
            ids[ids.length - 1] = floorLiquidityBin;

            if (!isInsideRange) ids[numberOfBinsToWithdraw - 2] = tightLiqBin;
        }

        lastRecordedActiveBin = getActiveBinId();

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

    function setAllFee(uint256 devFee_ , uint256 marketFee_ , uint256 lotusFee_ , uint256 stakeSellFee_ , uint256 stakeFee_) public onlyOwner{
        devFee = devFee_;
        marketFee = marketFee_;
        lotusFee = lotusFee_;
        stakeFee = stakeFee_;
        stakeSellFee = stakeSellFee_;
    }

    function setAllWallet(address devWallet_ , address marketWallet_ , address lotusBuybackWallet_) public onlyOwner{
        devWallet = devWallet_;
        marketWallet = marketWallet_;
        lotusBuybackWallet = lotusBuybackWallet_;
    }

    function setDexPairs(address[] calldata _pairs) public onlyOwner{
        //require(msg.sender == _owner, "Ownable: caller is not the owner");
        pairsList = _pairs;
    }

    function isDexPair(address _pair) internal {
        flagDexPair = false;
        for(uint256 i=0; i< pairsList.length; i++) {
            if(address(pairsList[i]) == _pair) {
                flagDexPair = true;
            }
        }
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
        _amount = amount;
        if (feesEnabled && !isRebalancing) {

            isDexPair(from);
            // buy tax
            if ((from == address(pair) || flagDexPair) && to != (address(this))) {
                // todo: figure out fee split
                uint256 devFeeAmount = calculateFee(_amount, devFee); // 1.5%
                uint256 marketFeeAmount = calculateFee(_amount, marketFee); // 1%

                balanceOf[devWallet] += devFeeAmount;
                emit Transfer(from, devWallet, devFeeAmount);

                balanceOf[marketWallet] += marketFeeAmount;
                emit Transfer(from, marketWallet, marketFeeAmount);

                _amount -= devFeeAmount;
                _amount -= marketFeeAmount;
            }

            isDexPair(to);
            // sell tax
            if ((flagDexPair && to != (address(this))) || (from == address(joeRouter) && to == address(pair))) {
                uint256 sendToVault;
                uint256 sendToLotusVault;

                if (seedLiquidityTimes >0 && getActiveBinId() == floorLiquidityBin) {
                    sendToVault = calculateFee(_amount, stakeFee);
                    balanceOf[vault] += sendToVault;
                    emit Transfer(from, vault, sendToVault);
                    _amount -= sendToVault;
                } else {
                    sendToVault = calculateFee(_amount, stakeSellFee);
                    sendToLotusVault = calculateFee(_amount, lotusFee);

                    balanceOf[vault] += sendToVault;
                    emit Transfer(from, vault, sendToVault);

                    balanceOf[lotusBuybackWallet] += sendToLotusVault;
                    emit Transfer(from, lotusBuybackWallet, sendToLotusVault);

                    _amount -= sendToVault;
                    _amount -= sendToLotusVault;
                }
            }
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        if (tradingEnabled == false) {
            revert("Trading is not enabled");
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
        if (tradingEnabled == false) {
            require(from == address(this));
        }

        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) {
            allowance[from][msg.sender] = allowed - amount;
        }

        balanceOf[from] -= amount;

        uint256 _amount = chargeTax(msg.sender, to, amount);

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
        uint256 pct
    ) public pure returns (uint256) {
        uint256 feePercentage = Constants.PRECISION.mul(pct).div(1000); // x pct
        return amount.mul(feePercentage).div(Constants.PRECISION);
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

    function openTrading() external onlyOwner {
        tradingEnabled = true;
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

    receive() external payable {}
}