// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeERC20.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract stakingPlatform{

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address public owner;

    struct Users{
        uint256 amount;
        uint256 stakeTime;
        uint claimTime;
    }

    struct stakingPools{
        IERC20 stakingToken;
        IERC20 rewardToken;
        uint stakingTokenDecimals;
        uint rewardTokenDecimals;
        uint256 ratio; //1000000000000000000 * stakingToken / rewardToken
        uint APY;
        uint stakers;
        uint256 totalStaked;
        uint lockDays;
        uint earlyUnstakePenalty;
        mapping(address => Users) users;
    }

    mapping(uint => stakingPools) public sTOKENs;

    constructor(){        
        addToken(0, 6, 6, 0x38c2fBdF53b451Ae5c4027711D6Fe5E1B2191B1C, 0x38c2fBdF53b451Ae5c4027711D6Fe5E1B2191B1C, 1000000000000000000, 112, 0, 0); //AIA -> AIA
        addToken(1, 6, 18, 0x38c2fBdF53b451Ae5c4027711D6Fe5E1B2191B1C, 0x912CE59144191C1204E64559FE8253a0e49E6548, 485300, 100, 0, 0); //AIA -> ARB
        addToken(2, 18, 6, 0x912CE59144191C1204E64559FE8253a0e49E6548, 0x38c2fBdF53b451Ae5c4027711D6Fe5E1B2191B1C, 2060282334986 * 10**18, 122, 0, 0); //ARB -> AIA
    }

    function stakeToken(uint _poolID, uint256 _amount) public {
        stakingPools storage sToken = sTOKENs[_poolID];
        require(_amount > 0, "Amount should be greater than 0");
        if(sToken.users[_msgSender()].amount == 0){
            sToken.stakers++;
        }else{
            claimRewards(_poolID);
        }

        sToken.users[_msgSender()].stakeTime = block.timestamp;
        sToken.users[_msgSender()].claimTime = block.timestamp;
        sToken.users[_msgSender()].amount = sToken.users[_msgSender()].amount.add(_amount);
        sToken.totalStaked = sToken.totalStaked.add(_amount);
        
        
        sToken.stakingToken.safeTransferFrom(_msgSender(), address(this), _amount);
    }

    function unstakeToken(uint _poolID) public {
        stakingPools storage sToken = sTOKENs[_poolID];
        require(sToken.users[_msgSender()].amount > 0, "No active stake!");

        if((block.timestamp - sToken.users[_msgSender()].stakeTime) / 60 / 60 / 24 >= sToken.lockDays){
            uint256 _amount = sToken.users[_msgSender()].amount;
            sToken.users[_msgSender()].amount = 0;
            sToken.totalStaked -= _amount;
            sToken.stakingToken.safeTransfer(_msgSender(), _amount);
        }else{
            uint256 _amount = sToken.users[_msgSender()].amount;
            sToken.users[_msgSender()].amount = 0;
            sToken.totalStaked -= _amount;
            sToken.stakingToken.safeTransfer(_msgSender(), getPercent(_amount, (100 - sToken.earlyUnstakePenalty)));
        }
        sToken.users[_msgSender()].stakeTime = 0;
        sToken.stakers--;
    }

    function claimRewards(uint _poolID) public {
        stakingPools storage sToken = sTOKENs[_poolID];
        require(sToken.users[_msgSender()].amount > 0, "No active stake!");

        uint256 pft = ((getPercent(sToken.users[_msgSender()].amount, sToken.APY) * (block.timestamp - sToken.users[_msgSender()].claimTime)) / 60 / 60 / 24) / 365;
        pft = (pft * sToken.ratio * (10**sToken.rewardTokenDecimals) / (10**sToken.stakingTokenDecimals)) / (10**18);
        
        sToken.users[_msgSender()].claimTime = block.timestamp;

        sToken.rewardToken.safeTransfer(_msgSender(), pft);
    }

    function getData(uint _poolID, address _user) public view returns(uint, uint256, uint256, uint256){
        stakingPools storage sToken = sTOKENs[_poolID];
        return(sToken.stakers, sToken.users[_user].amount, sToken.users[_user].stakeTime, sToken.users[_user].claimTime);
    }

    // Add a new token to stake
    function addToken(uint _poolID,
                    uint _stakingTKNdecimal,
                    uint _rewardTKNdecimal,
                    address _stakingTKNadr,
                    address _rewardTKNadr,
                    uint256 _ratio,
                    uint _APY,
                    uint _lockDays,
                    uint _earlyUnstakePenalty)
                    private{
        require(sTOKENs[_poolID].ratio == 0, "Token already exists");

        stakingPools storage sToken = sTOKENs[_poolID];
        sToken.stakingTokenDecimals = _stakingTKNdecimal;
        sToken.rewardTokenDecimals = _rewardTKNdecimal;
        sToken.stakingToken = IERC20(_stakingTKNadr);
        sToken.rewardToken = IERC20(_rewardTKNadr);
        sToken.ratio = _ratio;
        sToken.APY = _APY;
        sToken.lockDays = _lockDays;
        sToken.earlyUnstakePenalty = _earlyUnstakePenalty;

    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint vald;
        vald = (_val * _percent) / 100 ;
        return vald;
    }
}