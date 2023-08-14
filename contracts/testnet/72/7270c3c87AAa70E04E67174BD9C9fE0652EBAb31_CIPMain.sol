//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import "./CIPUniversal.sol";

contract CIPMain  is CIPUniversal {

using SafeMath for uint256;

    constructor(address _ciptokencontract,address owner,address _CIPADDREFREE) {
        ciptokencontract = IARB20(_ciptokencontract);
        CIPADDREFREE=ICIPADDREFREE(_CIPADDREFREE);
        _owner=owner;
        users[_owner].lastUpdateTime = block.timestamp;
        users[_owner].userId = block.timestamp; 
        Last_Universal_Pool_Distributed=block.timestamp;  
    }

    function addReferee(address ref) public {
        require(ref != msg.sender, "You cannot refer yourself !");
        require(users[ref].userId != 0,"Referrer not registered yet !");
        User storage user = users[msg.sender];
        require(user.userId == 0,"Already registered !");
        user.referrer = ref;
        address upline = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    if(user.userId == 0){
                        users[upline].noOfReferral[i] = users[upline].noOfReferral[i].add(1);
                    }
                    upline = users[upline].referrer;
                } 
                else break;
        }
        user.userId = block.timestamp;
        CIPADDREFREE.addReferee(msg.sender,ref);
        emit Joining(msg.sender,ref);
    }

    function getReferees(address ref,uint256 level) public view returns (address[] memory) {
        address[] memory referees;
        referees=CIPADDREFREE.getReferees(ref,level);
        return referees;
    }

    function staking(uint256 amount) public updateReward(msg.sender){
       _Staking(amount,msg.sender);  
    }

    function _Staking(uint256 _amount,address _user) internal {
        require(_amount >= MIN_STAKE_AMOUNT,"Minimum staking does not meet !");
        require(users[_user].userId != 0,"Register yourself before stake !");
        User storage user = users[_user];
        if(user.firstTimeStaked==0)  {
            user.firstTimeStaked=_amount;
        }
        user.selfTotalStaked+=_amount;
        Total_Staked_CIP+=_amount;
        user.paidSecond=0;   
        address upline = user.referrer;
        users[upline].directTotalStaked+=_amount;
        for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    if(user.userId != 0){
                        users[upline].teamTotalStaked += _amount;
                    }
                    upline = users[upline].referrer;
                } 
                else break;
        } 
        ciptokencontract.transferFrom(_user, address(this), _amount);
        _CalculateRank(_user);
        _CalculateUniversalPoolRank(1,_user);
        emit Staking(_amount,_user);
    }

    function unStake(uint _amount) public updateReward(msg.sender) {
        User storage user = users[msg.sender];
        UserBonus storage userbonus = usersBonus[msg.sender];
        require(_amount <= user.selfTotalStaked,"Insufficient Unstake CIP !");
        if(userbonus.roiUnSettled.add(userbonus.roiBonus).add(userbonus.referralBonus)>=(user.selfTotalStaked.mul(INCOME_CAPPING_X))){
            require(false,"Capping Limits Reached !");
        }
        user.selfTotalStaked -= _amount;
        Total_Staked_CIP-=_amount;
        //Get Penalty Percentage
        uint noofSecond=view_GetNoofSecondBetweenTwoDate(user.lastUpdateTime,block.timestamp);
        uint paidNoofSecond=user.paidSecond;
        uint penaltyPer=0;
        if(noofSecond.add(paidNoofSecond)<TOTAL_ROI_SECOND){ penaltyPer=PREMATURE_UNSTAKE_PENALTY;}
        else { penaltyPer=0; }
        //Get Penalty Amount
        uint256 penalty=_amount.mul(penaltyPer).div(100);
        //Update Penalty Collected
        user.penaltyCollected +=penalty;
        //Update Unstake Section
        user.selfTotalUnStaked +=_amount;
        //Get Net Receivable Unstake Amount
        uint256 _payableamount=_amount-penalty;
        ciptokencontract.transfer(msg.sender, _payableamount);
    }

    function rewardWithdrawal() public updateReward(msg.sender) {
        UserBonus storage userbonus = usersBonus[msg.sender];
        uint256 reward = userbonus.roiUnSettled;
        _CalculateROILevelIncome(reward,msg.sender);
        _CalculateRankIncome(reward,msg.sender);
        // Set Reward 0
        userbonus.roiUnSettled = 0;
        // Reward Withdrawal Section
        userbonus.roiBonus +=reward;
        _CalculateUniversalPoolRank(2,msg.sender);
        ciptokencontract.transfer(msg.sender, reward);
    }

    function _Withdrawal(uint256 _amount) external {
        UserBonus storage userbonus = usersBonus[msg.sender];
        require(_amount <= userbonus.totalAvailableBonus,"Insufficient Fund");
        uint256 AdminCharge = _amount.mul(WITHDRAWAL_ADMIN_CHARGE).div(100);
        uint256 withdrawalableAmount=_amount-AdminCharge;
        userbonus.totalAvailableBonus = userbonus.totalAvailableBonus.sub(_amount);
        userbonus.totalWithdrawalBonus = userbonus.totalWithdrawalBonus.add(_amount);
        userbonus.totalAdminChargeCollected+=AdminCharge;
        ciptokencontract.transfer(msg.sender, withdrawalableAmount);
    }

}