// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {SafeTransferLib} from "./SafeTransferLib.sol";
import {ERC20} from "./ERC20.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./SafeMath.sol";
import "./Constants.sol";
import {PriceHelper} from "./PriceHelper.sol";

contract LGIFT is ERC20, Ownable {
    address public LETHToken;

    uint256 public rewardRate;

    uint256 public totalCirculatingSupply;

    address private deadBurn = 0x000000000000000000000000000000000000dEaD;

    bool public autoRewardRateEnabled = false;

    uint256 public maxRewardRate = 0;

    bool public claimRewardEnabled = false;

    constructor(
        address LETHToken_,
        uint256 maxSupply_
    ) ERC20("LGIFT", "LGIFT", 18) {
        LETHToken = LETHToken_;
        uint256 maxSupply = maxSupply_ * 1 ether;
        _mint(LETHToken, maxSupply);
    }

    function updateRewardRate() public onlyOwner{
        uint256 totalLETHInContract = IERC20(LETHToken).balanceOf(address(this));
        uint256 totalLGIFTinPool = balanceOf[LETHToken];
        totalCirculatingSupply = totalSupply - (totalLGIFTinPool + balanceOf[deadBurn]);
        rewardRate = (totalLETHInContract * Constants.PRECISION) / (totalCirculatingSupply);
    }

    function setAutoRewardRateEnabled(bool _claimRewardEnabled, bool _autoReward, uint256 _maxRate) public onlyOwner{
        claimRewardEnabled = _claimRewardEnabled;
        autoRewardRateEnabled = _autoReward;
        maxRewardRate = _maxRate;
    }

    function setRewardRate(uint256 _rewardRate) public onlyOwner{
        rewardRate = _rewardRate;
    }

    function claimReward(uint256 _amount) external {
        require(claimRewardEnabled , "can not claim now.");

        uint256 userBalance = balanceOf[msg.sender];

        require(userBalance>=_amount , "can not claim so much.");

        if(autoRewardRateEnabled){
            //update rate
            uint256 totalLETHInContract = IERC20(LETHToken).balanceOf(address(this));
            uint256 totalLGIFTinPool = balanceOf[LETHToken];
            totalCirculatingSupply = totalSupply - (totalLGIFTinPool + balanceOf[deadBurn]);
            rewardRate = (totalLETHInContract * Constants.PRECISION) / (totalCirculatingSupply);
        }

        uint256 reward = (_amount*rewardRate)/Constants.PRECISION;

        if(maxRewardRate > 0){
            uint256 maxReward = _amount*maxRewardRate/1000;
            if(reward > maxReward){
                reward = maxReward;
            }
        }

        require(reward>0 , "reward is zero");

        //send LGIFT
        IERC20(address(this)).transferFrom(msg.sender, LETHToken, _amount);

        //send LETH
        IERC20(LETHToken).approve(address(this), 2 ** 256 - 1);
        IERC20(LETHToken).transferFrom(address(this), msg.sender, reward);
    }

    function circulatingSupply() public view returns (uint256){
        uint256 totalLGIFTinPool = balanceOf[LETHToken];
        return (totalSupply - (totalLGIFTinPool + balanceOf[deadBurn]));
    }

    function checkClaimReward(uint256 _amountLGIFT) public view returns (uint256){

        uint256 reward = (_amountLGIFT*rewardRate)/Constants.PRECISION;

        if(maxRewardRate > 0){
            uint256 maxReward = _amountLGIFT * maxRewardRate/1000;
            if(reward > maxReward){
                reward = maxReward;
            }
        }

        return reward;
    }

    function rewardBalance(address _addr) public view returns (uint256){

        uint256 amountLGIFT = balanceOf[_addr];

        uint256 reward = (amountLGIFT*rewardRate)/Constants.PRECISION;

        if(maxRewardRate > 0){
            uint256 maxReward = amountLGIFT * maxRewardRate/1000;
            if(reward > maxReward){
                reward = maxReward;
            }
        }

        return reward;
    }

    function getRewardRate() public view returns (uint256){
        uint256 _rwRate = rewardRate;
        if(autoRewardRateEnabled){
            uint256 totalLETHInContract = IERC20(LETHToken).balanceOf(address(this));
            uint256 totalLGIFTinPool = balanceOf[LETHToken];
            uint256 totalViewCirculatingSupply = totalSupply - (totalLGIFTinPool + balanceOf[deadBurn]);
            _rwRate = (totalLETHInContract * Constants.PRECISION) / (totalViewCirculatingSupply);
        }
        return _rwRate;
    }
}