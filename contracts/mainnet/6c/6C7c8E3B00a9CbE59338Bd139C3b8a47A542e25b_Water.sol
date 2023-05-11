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

contract Water is ERC20, Ownable {
    using SafeTransferLib for address payable;
    using SafeMath for uint256;
    using PriceHelper for uint256;

    address WATER_MARKETING = 0x8f4671e739ABb3fCBA7a9b0843AC679A4d4C073d; // To be used for actual marketing
    ILBRouter public joeRouter;
    ILBPair public pair;
    address public vault; //staking contract
    address public immutable NATIVE; //weth

    bool public rebalancesEnabled;
    bool public feesEnabled;
    bool isRebalancing;

    // JOE LIQ
    uint16 public binStep; //bin steps
    uint24 public startBin; //starting bin
    uint256 public lastRecordedActiveBin; //recorded bin to know where rebalances occur.
    uint24 public maxBin; //this is the last bin where we have liq
    uint256 public xPerBin; //xToken amount per bin

    uint24 public floorLiquidityBin; //the floor where bin liquidity sits.
    uint24 public tightLiqBin; //bin for active trading

    uint256 public burnFee = 80; //8%
    uint256 public stakeFee = 20; //2%

    uint24 public seedLiquidityTimes; //for initialize function

    uint256 public maxSupply;

    bool private trading = false;

    constructor(
        ILBRouter joeRouter_,
        address native_,
        uint256 maxSupply_,
        uint256 _xPerBin
    ) ERC20("Water", "WATER", 18) {
        joeRouter = joeRouter_;
        NATIVE = native_;

        maxSupply = maxSupply_ * 1 ether;
        rebalancesEnabled = true;
        feesEnabled = true;
        xPerBin = _xPerBin * 1 ether;
    }

    modifier rebalanceAllowed() {
        if (binStep == 0 || floorLiquidityBin == getActiveBinId())
            revert("At floor");

        if (getActiveBinId() - lastRecordedActiveBin > 5 && rebalancesEnabled) {
            _;
        } else {
            revert("Out of range");
        }
    }

    function toggleTrading() external onlyOwner {
        trading = !trading;
    }

    function initialize(
        address pair_,
        int256[] memory deltaIds,
        uint256[] memory distributionX,
        uint256[] memory distributionY,
        address _vault
    ) external payable onlyOwner {
        require(seedLiquidityTimes < 4, "initialized");

        if (seedLiquidityTimes == 0) {
            vault = _vault;
            pair = ILBPair(pair_);

            binStep = pair.getBinStep();

            startBin = getActiveBinId();
            lastRecordedActiveBin = getActiveBinId() + 1; // add one because it's where our liquidity sits

            approvals();

            maxBin = getActiveBinId() + 300;
        }

        _mint(address(this), maxSupply / 3);

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

        uint256 totalWaterInPool = (maxBin - (getActiveBinId() + 1)) * xPerBin;

        uint256 totalCirculatingSupply = totalSupply -
            (totalWaterInPool +
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
            int(int24(floorLiquidityBin)));

        tightLiqBin = getActiveBinId() - 1;

        int256[] memory deltaIds = new int256[](2);
        deltaIds[0] = deltaForMainLiq;
        deltaIds[1] = -1;

        uint256[] memory distributionX = new uint256[](2);
        distributionX[0] = 0;
        distributionX[1] = 0;

        uint256[] memory distributionY = new uint256[](2);

        distributionY[0] = (Constants.PRECISION * 90) / 100;
        distributionY[1] = (Constants.PRECISION * 10) / 100;

        addLiquidity(deltaIds, distributionX, distributionY, getActiveBinId());

        isRebalancing = false;
    }

    //if we finish water side supply in the pool, burns happen so floor can still go up, need dedicated rebalance
    function rebalanceMax() external {
        require(
            getActiveBinId() > maxBin && rebalancesEnabled,
            "Not there yet"
        );

        isRebalancing = true;

        // step 1 remove liquidity only from the floor bin
        uint256[] memory amounts = new uint256[](1);
        uint256[] memory ids = new uint256[](1);

        ids[0] = floorLiquidityBin;
        amounts[0] = pair.balanceOf(address(this), ids[0]);

        pair.burn(address(this), address(this), ids, amounts);

        // step 2 calculate new floor price and add liq to that price
        uint256 totalEthInContract = IERC20(NATIVE).balanceOf(address(this));

        uint256 totalWaterInPool = 0; // 0 because we finished our range

        uint256 totalCirculatingSupply = totalSupply -
            (totalWaterInPool +
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

        require(IERC20(NATIVE).balanceOf(address(this)) < 1 ether, "failed");
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

        uint256 amountXmin = (amountX * 99) / 100; // We allow 1% amount slippage
        uint256 amountYmin = (amountY * 99) / 100; // We allow 1% amount slippage

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
        @notice charge tax on sells and buys functions.
        @return _amount remaining to the sender
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
                uint256 daoFee = calculateFee(_amount, 75); // 7.5 (5% to be burned in multisig)

                balanceOf[WATER_MARKETING] += daoFee;
                emit Transfer(from, WATER_MARKETING, daoFee);
                _amount -= daoFee;
            }

            // sell tax
            if (from == address(joeRouter) && to == address(pair)) {
                uint256 sendToVault;
                if (getActiveBinId() == floorLiquidityBin) {
                    sendToVault = calculateFee(_amount, (stakeFee + burnFee));
                    balanceOf[vault] += sendToVault;
                    emit Transfer(from, vault, sendToVault);

                    _amount -= sendToVault;
                } else {
                    uint256 burn = calculateFee(_amount, burnFee);
                    sendToVault = calculateFee(_amount, stakeFee);

                    balanceOf[vault] += sendToVault;
                    emit Transfer(from, vault, sendToVault);

                    unchecked {
                        totalSupply -= burn;
                    }
                    emit Transfer(from, address(0), burn);

                    _amount -= (sendToVault + burn);
                }
            }
        }
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(trading || msg.sender == owner(), "Trading hasn't been enabled yet");

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
        require(trading || msg.sender == owner(), "Trading hasn't been enabled yet");
        
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

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
        @notice Helper func.
     */
    function getAverageTokenPrice(
        uint256 totalETH,
        uint256 totalTokens
    ) public pure returns (uint256) {
        require(totalETH < totalTokens, "ETH must be less than total tokens");

        return (totalETH * Constants.PRECISION) / (totalTokens);
    }

    /**
        @notice returns the current floor price
     */
    function getFloorPrice() public view returns (uint256) {
        return joeRouter.getPriceFromId(pair, floorLiquidityBin);
    }

    /**
        @notice Get's the pool active bin id.
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
        @notice approvals for joe router.
     */
    function approvals() public onlyOwner {
        allowance[address(this)][address(joeRouter)] = 2 ** 256 - 1;
        IERC20(NATIVE).approve(address(joeRouter), 2 ** 256 - 1);

        ILBToken(address(pair)).approveForAll(address(joeRouter), true);
        ILBToken(address(pair)).approveForAll(address(pair), true);
    }

    /**
        @notice only admin function to disable rebalances and fees in case of bugs.
        @param rebalances bool rebalances enabled?.
        @param fees bool fees enabled?
     */
    function disableRebalances(bool rebalances, bool fees) external onlyOwner {
        rebalancesEnabled = rebalances;
        feesEnabled = fees;
    }

    // in case of bugs in the staking contract we send to a new vault
    function setNewVault(address newVault) external onlyOwner {
        vault = newVault;
    }

    receive() external payable {}
}