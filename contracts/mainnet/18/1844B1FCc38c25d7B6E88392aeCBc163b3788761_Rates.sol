// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.17;

import {IRates} from "./IRates.sol";
import {IMUSDManager} from "./IMUSDManager.sol";
import {Governable} from "./Governable.sol";
import {Constants} from "./Constants.sol";

contract Rates is IRates, Governable {
    uint256 public holdingFee = Constants.HOLDING_FEE;

    uint256 public safeCollateralRate = Constants.SAFE_COLLATERAL_LIMIT;
    uint256 public badCollateralRate = Constants.BAD_COLLATERAL_LIMIT;

    uint256 public redemptionFee = Constants.REDEMPTION_FEE;
    uint256 public keeperRate = Constants.KEEPER_RATE;

    uint256 public edReward = Constants.MAX_EXCESS_DISTRIBUTION_REWARD;
    uint256 public treasuryFee = Constants.MAX_TREASURY_FEE;

    IMUSDManager mUSDManager;

    // holding fee variables
    uint256 public lastReportTime;
    uint256 public feeStored;

    address public treasury;

    constructor(address _mUSDManager) Governable(msg.sender) {
        mUSDManager = IMUSDManager(_mUSDManager);
    }

    function setHoldingFee(
        uint256 _newFee
    ) external override onlyGov returns (bool) {
        require(_newFee <= Constants.MAX_HOLDING_FEE, "MR: Invalid holding fee");
        this.saveFees();
        holdingFee = _newFee;
        emit HoldingFeeChanged(_newFee);
        return true;
    }

    function setSafeCollateralRate( uint256 _newSafeRate)  external override onlyGov returns (bool) {
        require(_newSafeRate > this.getBadCR() , "MR: Invalid safe collateral rate");
        safeCollateralRate = _newSafeRate;
        emit SafeCollateralRateChanged(_newSafeRate);
        return true;
    }

    function setBadCollateralRate(uint256 _newBadRate) external override onlyGov returns (bool) {
        require(_newBadRate >= Constants.HUNDRED_PERCENT && _newBadRate < this.getSafeCR(), "MR: Invalid bad collateral rate");
        badCollateralRate = _newBadRate;
        emit BadCollateralRateChanged(badCollateralRate);
        return true;
    }

    function setKeeperRate(uint256 _newRate) external override onlyGov 
    returns (bool) {
        require(_newRate <= Constants.MAX_KEEPER_RATE, "MR: Invalid keeper rate");
        keeperRate = _newRate;
        emit KeeperRateChanged(_newRate);
        return true;
    }

    function setRedemptionFee(uint256 _newFee) external override onlyGov returns (bool) {
        require(_newFee <= Constants.REDEMPTION_FEE, "MR: Invalid redemption fee");
        redemptionFee = _newFee;
        emit RedemptionFeeChanged(_newFee);
        return true;
    }

    function setTreasuryFee(uint256 _newFee) external override onlyGov returns (bool) {
        require(_newFee <= Constants.HUNDRED_PERCENT, "MR: Invalid treasury fee");
        treasuryFee = _newFee;
        emit TresuryFeeChanged(treasuryFee);
        return true;
    }

    function setExcessDistributionReward(uint256 _newRate) external override onlyGov returns (bool) {
        require(_newRate <= Constants.MAX_EXCESS_DISTRIBUTION_REWARD, "MR: Invalided reward");
        edReward = _newRate;
        emit ExcessDistributionRewardChanged(_newRate);
        return true;
    }

    function setTreasury(address _treasury) external override onlyGov returns (bool) {
        require(_treasury != address(0) && _treasury != address(this), "MR: Invalid address");
        treasury = _treasury;
        return true;
    }

    function saveFees() external override {
        feeStored = feeStored + this.newHoldingFee();
        lastReportTime = block.timestamp;
    }

    function setMUSDManager(address _mUSDManager) public onlyGov {
        require(_mUSDManager != address(0), "MR: Invalid mUSDManager");
        mUSDManager = IMUSDManager(_mUSDManager);
    }

    function newHoldingFee() external view returns (uint256) {
        uint256 fee = mUSDManager.totalSupply() * ( block.timestamp - lastReportTime);
        fee = (fee * holdingFee) / (Constants.YEAR_IN_SECONDS * Constants.HUNDRED_PERCENT);
        return fee;
    }

    function getBadCR() external view override returns (uint256) {
        return badCollateralRate;
    }

    function getSafeCR() external view override returns (uint256) {
        return safeCollateralRate;
    }

    function getRFee() external view override returns (uint256) {
        return redemptionFee;
    }

    function getKR() external view override returns (uint256) {
        return keeperRate;
    }

    function getHoldingFee() external view override returns (uint256) {
        return feeStored;
    }

    function getTFee() external view override returns (uint256) {
        return treasuryFee;
    }

    function getEDR() external view override returns (uint256) {
        return edReward;
    }

    function getTreasury() external view override returns (address) {
        return treasury;
    }

    function setAccumulatedFee(uint256 _fee) external override {
        require(msg.sender == address(mUSDManager), "RATE: Invalid caller"); 
        feeStored = _fee;
        lastReportTime = block.timestamp;
    }
}