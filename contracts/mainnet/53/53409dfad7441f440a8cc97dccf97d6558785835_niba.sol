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

contract niba is ERC20, Ownable {
    using SafeTransferLib for address payable;
    using SafeMath for uint256;
    using PriceHelper for uint256;

    ILBRouter public joeRouter;
    ILBPair public pair;
    address public vault; //staking contract
    address public immutable NATIVE; //weth
    address private founderWallet;
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
    uint24 public REBALANCE_THRESHOLD = 19;

    // @dev blacklisting dexes to only provision liq to traderjoe
    // give me a mapping of address to bool
    mapping(address => bool) public blacklist;

    constructor(
        ILBRouter joeRouter_,
        address native_,
        uint256 maxSupply_,
        uint256 _xPerBin,
        address devWallet_,
        address founderWallet_
    ) ERC20("niba", "niba", 18) {
        address uniswapv3 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
        address sushiswap = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        address sushiswapTrident = 0xD9988b4B5bBC53A794240496cfA9Bf5b1F8E0523;
        address balancer = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
        address camelot = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
        address chronos = 0xdd94018F54e565dbfc939F7C44a16e163FaAb331;
        address curve = 0x4c2Af2Df2a7E567B5155879720619EA06C5BB15D;
        address joev1 = 0xaE4EC9901c3076D0DdBe76A520F9E90a6227aCB7;
        address joev2 = 0x7BFd7192E76D950832c77BB412aaE841049D8D9B;
        blacklist[uniswapv3] = true;
        blacklist[sushiswap] = true;
        blacklist[sushiswapTrident] = true;
        blacklist[balancer] = true;
        blacklist[camelot] = true;
        blacklist[chronos] = true;
        blacklist[curve] = true;
        blacklist[joev1] = true;
        blacklist[joev2] = true;
        tradingEnabled = true;

        joeRouter = joeRouter_;
        NATIVE = native_;
        devWallet = devWallet_;
        founderWallet = founderWallet_;

        maxSupply = maxSupply_ * 1 ether;
        rebalancesEnabled = true;
        feesEnabled = true;
        xPerBin = _xPerBin * 1 ether;
    }

    modifier rebalanceAllowed() {
        if (binStep == 0 || floorLiquidityBin == getActiveBinId()) {
            revert("At floor");
        }

        if (
            getActiveBinId() - lastRecordedActiveBin > REBALANCE_THRESHOLD &&
            rebalancesEnabled
        ) {
            _;
        } else {
            revert("Out of range");
        }
    }

    //====================================================================================================================
    // Initialize functions - messy cause developed via hackaton and would run out of gas otherwise. works on my machine.
    //====================================================================================================================

    function initialize(
        address pair_,
        int256[] memory deltaIds,
        uint256[] memory distributionX,
        uint256[] memory distributionY,
        address _vault
    ) external payable onlyOwner {
        require(seedLiquidityTimes < 12, "initialized");

        if (seedLiquidityTimes == 0) {
            vault = _vault;
            pair = ILBPair(pair_);

            binStep = pair.getBinStep();

            startBin = getActiveBinId();
            lastRecordedActiveBin = getActiveBinId() + 1; // add one because it's where our liquidity sits

            approvals();

            maxBin = getActiveBinId() + 1200;
        }

        _mint(address(this), maxSupply / 12);

        //     maxBin = getActiveBinId() + 100;
        // }

        // _mint(address(this), maxSupply);
        
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

        // burn the MOAT that is received from removeLiquidity.
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
            // buy tax
            if (from == address(pair) && to != (address(this))) {
                // todo: figure out fee split
                uint256 devFee = calculateFee(_amount, 15); // 1.5%
                uint256 founderFee = calculateFee(_amount, 10); // 1%

                balanceOf[devWallet] += devFee;
                emit Transfer(from, devWallet, devFee);

                balanceOf[founderWallet] += founderFee;
                emit Transfer(from, founderWallet, founderFee);

                _amount -= devFee;
                _amount -= founderFee;
            }

            // sell tax
            if (from == address(joeRouter) && to == address(pair)) {
                uint256 sendToVault;
                if (getActiveBinId() == floorLiquidityBin) {
                    sendToVault = calculateFee(_amount, stakeFee);
                    balanceOf[vault] += sendToVault;
                    emit Transfer(from, vault, sendToVault);
                    _amount -= sendToVault;
                } else {
                    sendToVault = calculateFee(_amount, stakeFee);
                    balanceOf[vault] += sendToVault;
                    emit Transfer(from, vault, sendToVault);
                    _amount -= (sendToVault);
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
        // @dev check that to and from aren't on blacklist
        require(
            !blacklist[to] && !blacklist[from],
            "error: invalid liquidity pool"
        );

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

    function openTrading(bool trading) external onlyOwner {
        tradingEnabled = trading;
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

    function setBlacklist(address[] memory dexList, bool isBlacklisted) external onlyOwner {
        for (uint256 i = 0; i < dexList.length; i++) {
            blacklist[dexList[i]] = isBlacklisted;
        }
    }
    
    function setRebalanceThreshold(uint24 _REBALANCE_THRESHOLD) external onlyOwner {
        REBALANCE_THRESHOLD = _REBALANCE_THRESHOLD;
    }

    receive() external payable {}
}