/**
 *Submitted for verification at Arbiscan on 2023-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IARB20 {
    function transfer( address recipient, uint256 amount ) external returns (bool);
    function transferFrom( address sender, address recipient, uint256 amount ) external returns (bool);
}

contract Ownable  {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }  
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */

library SafeMath {
    /*Addition*/
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /*Subtraction*/
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /*Multiplication*/
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /*Divison*/
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    /* Modulus */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract CIPStaking is Ownable{

    IARB20 public ciptokencontract;
    using SafeMath for uint256;

    struct User {
        uint256 userId;
        uint256 selfTotalStaked;
        uint256 selfTotalUnStaked;
        uint256 penaltyCollected;
        uint256 teamTotalStaked;
        uint256 directTotalStaked;
        address referrer;
        uint[20] noOfReferral;
        uint256[20] totalStaked;
        uint256[20] refBonus;
        uint paidSecond;
        uint currentRankId;
        uint universalPoolRankId;
        uint lastUpdateTime;
    }

    struct UserBonus {
        uint256 roiUnSettled;
        uint256 roiBonus;
        uint256 referralBonus;
        uint256 rankBonus;
        uint256 universalPoolBonus;
        uint256 totalCreditedBonus;
        uint256 totalWithdrawalBonus;
        uint256 totalAvailableBonus;
	}

    mapping (address => User) public users;
    mapping (address => UserBonus) public usersBonus;

    mapping(address => address[]) internal referrals_level_1;
    mapping(address => address[]) internal referrals_level_2;
    mapping(address => address[]) internal referrals_level_3;
    mapping(address => address[]) internal referrals_level_4;
    mapping(address => address[]) internal referrals_level_5;
    mapping(address => address[]) internal referrals_level_6;
    mapping(address => address[]) internal referrals_level_7;
    mapping(address => address[]) internal referrals_level_8;
    mapping(address => address[]) internal referrals_level_9;
    mapping(address => address[]) internal referrals_level_10;
    mapping(address => address[]) internal referrals_level_11;
    mapping(address => address[]) internal referrals_level_12;
    mapping(address => address[]) internal referrals_level_13;
    mapping(address => address[]) internal referrals_level_14;
    mapping(address => address[]) internal referrals_level_15;
    mapping(address => address[]) internal referrals_level_16;
    mapping(address => address[]) internal referrals_level_17;
    mapping(address => address[]) internal referrals_level_18;
    mapping(address => address[]) internal referrals_level_19;
    mapping(address => address[]) internal referrals_level_20;

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
                        users[upline].noOfReferral[i] = SafeMath.add(users[upline].noOfReferral[i],1);
                        if(i==0){referrals_level_1[upline].push(msg.sender);}
                        else if(i==1){referrals_level_2[upline].push(msg.sender);}
                        else if(i==2){referrals_level_3[upline].push(msg.sender);}
                        else if(i==3){referrals_level_4[upline].push(msg.sender);}
                        else if(i==4){referrals_level_5[upline].push(msg.sender);}
                        else if(i==5){referrals_level_6[upline].push(msg.sender);}
                        else if(i==6){referrals_level_7[upline].push(msg.sender);}
                        else if(i==7){referrals_level_8[upline].push(msg.sender);}
                        else if(i==8){referrals_level_9[upline].push(msg.sender);}
                        else if(i==9){referrals_level_10[upline].push(msg.sender);}
                        else if(i==10){referrals_level_11[upline].push(msg.sender);}
                        else if(i==11){referrals_level_12[upline].push(msg.sender);}
                        else if(i==12){referrals_level_13[upline].push(msg.sender);}
                        else if(i==13){referrals_level_14[upline].push(msg.sender);}
                        else if(i==14){referrals_level_15[upline].push(msg.sender);}
                        else if(i==15){referrals_level_16[upline].push(msg.sender);}
                        else if(i==16){referrals_level_17[upline].push(msg.sender);}
                        else if(i==17){referrals_level_18[upline].push(msg.sender);}
                        else if(i==18){referrals_level_19[upline].push(msg.sender);}
                        else if(i==19){referrals_level_20[upline].push(msg.sender);}
                    }
                    upline = users[upline].referrer;
                } 
                else break;
        }
        user.userId = block.timestamp; 
        emit Joining(msg.sender,ref);
    }

    event Staking(uint256 _amount,address _user);
    event Joining(address indexed _user,address _referrer);

    function staking(uint256 amount) public updateReward(msg.sender){
       _Staking(amount,msg.sender);  
    }

    function rewardPerSecondToken(address account) public view returns (uint256 _persecondinterest) {
        uint256 persecondinterest=0;
        if (users[account].selfTotalStaked <= 0) {
            return persecondinterest;
        }
        else{
            uint256 StakingToken=users[account].selfTotalStaked;
            uint256 perSecondPer=ROI_PERCENT_SECOND;
            persecondinterest=((StakingToken*perSecondPer)/100)/1e18;
            return persecondinterest;
        }
    }

    //View No Of Days Between Two Date & Time
    function view_GetNoofDaysBetweenTwoDate(uint _startDate,uint _endDate) public pure returns(uint _days){
        uint startDate = _startDate;
        uint endDate = _endDate;
        uint daysdiff = (endDate - startDate)/ 60 / 60 / 24;
        return (daysdiff);
    }

    //View No Of Second Between Two Date & Time
    function view_GetNoofSecondBetweenTwoDate(uint _startDate,uint _endDate) public pure returns(uint _second){
        uint startDate = _startDate;
        uint endDate = _endDate;
        uint seconddiff = (endDate - startDate);
        return (seconddiff);
    }


    function isUserExists(address user) public view returns (bool) {
        return (users[user].userId != 0);
    }

    function earned(address account) public view returns (uint256 _totalroi,uint _noofSecond) {
        if(!isUserExists(account)){ 
            return(0,0);
        }
        User storage user = users[account];
        uint noofSecond=view_GetNoofSecondBetweenTwoDate(user.lastUpdateTime,block.timestamp);
        if(user.paidSecond.add(noofSecond)>TOTAL_ROI_SECOND){
            noofSecond=TOTAL_ROI_SECOND.sub(user.paidSecond);
        }
        uint256 _persecondinterest=rewardPerSecondToken(account);
        return(((_persecondinterest * noofSecond)+usersBonus[account].roiUnSettled),noofSecond);
    }

    modifier updateReward(address account) {
        User storage user = users[account];
        UserBonus storage userbonus = usersBonus[account];
        (uint256 totalroi, uint256 noofSecond) = earned(account);
        userbonus.roiUnSettled = totalroi;
        user.lastUpdateTime = block.timestamp;
        user.paidSecond+=noofSecond;
        _;
    }

    function unStake(uint _amount) public updateReward(msg.sender) {
        User storage user = users[msg.sender];
        UserBonus storage userbonus = usersBonus[msg.sender];
        require(_amount < user.selfTotalStaked,"Insufficient Unstake CIP !");
        if(userbonus.roiUnSettled.add(userbonus.roiBonus).add(userbonus.referralBonus)>=(user.selfTotalStaked.mul(INCOME_CAPPING_X))){
            require(false,"Capping Limits Reached !");
        }
        user.selfTotalStaked -= _amount;
        //Get Penalty Percentage
        uint noofSecond=view_GetNoofSecondBetweenTwoDate(user.lastUpdateTime,block.timestamp);
        uint paidNoofSecond=user.paidSecond;
        uint penaltyPer=0;
        if(noofSecond.add(paidNoofSecond)<TOTAL_ROI_SECOND){ penaltyPer=PREMATURE_UNSTAKE_PENALTY;}
        else { penaltyPer=0; }
        //Get Penalty Amount
        uint256 penalty=_amount * penaltyPer / 100;
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
        // Set Reward 0
        userbonus.roiUnSettled = 0;
        // Reward Withdrawal Section
        userbonus.roiBonus +=reward;
        ciptokencontract.transfer(msg.sender, reward);
    }

    function _Staking(uint256 _amount,address _user) internal {
        require(_amount >= MIN_STAKE_AMOUNT,"Minimum staking does not meet !");
        require(users[_user].userId != 0,"Register yourself before stake !");
        User storage user = users[_user];  
        user.selfTotalStaked+=_amount;
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
        emit Staking(_amount,_user);
    }

    function getReferees(address ref,uint256 level) public view returns (address[] memory) {
        address[] memory referees;
        if (level == 1) {
            referees = referrals_level_1[ref];
        }else if (level == 2) {
            referees = referrals_level_2[ref];
        }else if (level == 3) {
            referees = referrals_level_3[ref];
        }else if (level == 4) {
            referees = referrals_level_4[ref];
        }else if (level == 5) {
            referees = referrals_level_5[ref];
        }else if (level == 6) {
            referees = referrals_level_6[ref];
        }else if (level == 7) {
            referees = referrals_level_7[ref];
        }else if (level == 8) {
            referees = referrals_level_8[ref];
        }else if (level == 9) {
            referees = referrals_level_9[ref];
        }else if (level == 10) {
            referees = referrals_level_10[ref];
        }else if (level == 11) {
            referees = referrals_level_11[ref];
        }else if (level == 12) {
            referees = referrals_level_12[ref];
        }else if (level == 13) {
            referees = referrals_level_13[ref];
        }else if (level == 14) {
            referees = referrals_level_14[ref];
        }else if (level == 15) {
            referees = referrals_level_15[ref];
        }else if (level == 16) {
            referees = referrals_level_16[ref];
        }else if (level == 17) {
            referees = referrals_level_17[ref];
        }else if (level == 18) {
            referees = referrals_level_18[ref];
        }else if (level == 19) {
            referees = referrals_level_19[ref];
        }else {
            referees = referrals_level_20[ref];
        }
        return referees;
    }

    uint256 internal MIN_STAKE_AMOUNT = 2000 ether; 
    uint256 internal MIN_WITHDRAWAL_AMOUNT = 200 ether; 
    uint internal PREMATURE_UNSTAKE_PENALTY = 25;
    uint internal INCOME_CAPPING_X = 5;
    uint internal TOTAL_ROI_DAYS = 365; 
    uint internal TOTAL_ROI_SECOND = TOTAL_ROI_DAYS.mul(24).mul(60).mul(60);
    uint256 internal ROI_PERCENT_ANNUALY = 144 ether; 
    uint256 internal ROI_PERCENT_PERDAY = ROI_PERCENT_ANNUALY.div(365); 
    uint256 internal ROI_PERCENT_HOUR = ROI_PERCENT_PERDAY.div(24); 
    uint256 internal ROI_PERCENT_MINUTE = ROI_PERCENT_HOUR.div(60); 
    uint256 internal ROI_PERCENT_SECOND = ROI_PERCENT_MINUTE.div(60); 

    //Level Income Declaration & Percentage & Condition
    uint[20] internal ref_bonuses = [10,7,5,4,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
    uint[20] internal ref_bonuses_direct_require = [1,2,3,4,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7];
    uint[20] internal self_business_required = [20000,20000,20000,20000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000];
    
    //Rank Income Declaration & Percentage & Condition
    //Rank Index i.e 0=Mercury,1=Venus,2=Earth,3=Mars,4=Jupiter,5=Sun
    //[Commission Percentage,Team Business,Direct Business,Self Business]
    uint[4] internal rank_mercury = [20,100000,40000,10000];
    uint[4] internal rank_venus = [25,240000,0,0];
    uint[4] internal rank_earth = [30,600000,0,0];
    uint[4] internal rank_mars = [40,1500000,140000,24000];
    uint[4] internal rank_jupiter = [45,4000000,0,40000];
    uint[4] internal rank_sun = [50,10000000,0,60000];

    //Universal Pool Income Declaration & Percentage & Condition
    //[Commission Percentage,Self Rank,No of Direct,Direct Rank,Direct UP Rank]
    uint[5] internal up_gold = [8,3,3,1,0];
    uint[5] internal up_diamond = [6,3,3,1,0];
    uint[5] internal up_platinum = [4,4,2,1,1];
    uint[5] internal up_kohinoor = [4,5,2,1,2];

    constructor(address _ciptokencontract,address owner) {
        ciptokencontract = IARB20(_ciptokencontract);
        _owner=owner;
        users[_owner].lastUpdateTime = block.timestamp;
        users[_owner].userId = block.timestamp;   
    }

    //Level income get data:-
    function getSystemSetting() public view returns (uint256 _MIN_STAKE_AMOUNT,uint256 _MIN_WITHDRAWAL_AMOUNT,uint256 _ROI_PERCENT_ANNUALY,uint256 _ROI_PERCENT_PERDAY,uint256 _ROI_PERCENT_HOUR,uint256 _ROI_PERCENT_MINUTE,uint256 _ROI_PERCENT_SECOND,uint _TOTAL_ROI_DAYS,uint _PREMATURE_UNSTAKE_PENALTY,uint _INCOME_CAPPING_X) {  
        return (MIN_STAKE_AMOUNT,MIN_WITHDRAWAL_AMOUNT,ROI_PERCENT_ANNUALY,ROI_PERCENT_PERDAY,ROI_PERCENT_HOUR,ROI_PERCENT_MINUTE,ROI_PERCENT_SECOND,TOTAL_ROI_DAYS,PREMATURE_UNSTAKE_PENALTY,INCOME_CAPPING_X);
    }

    //Level income get data:-
    function getLevelSetting() public view returns (uint[20] memory _ref_bonuses, uint[20] memory _ref_bonuses_direct_require, uint[20] memory _self_business_required) {  
        return (ref_bonuses,ref_bonuses_direct_require,self_business_required);
    }

    //Rank income get data:-
    function getRankSetting() public view returns (uint[4] memory _rank_venus, uint[4] memory _rank_earth, uint[4] memory _rank_mars,uint[4] memory _rank_jupiter,uint[4] memory _rank_sun) { 
      return (rank_venus,rank_earth,rank_mars,rank_jupiter,rank_sun);
    }

    //universal income get data:-
    function getUniversalSetting() public view returns (uint[5] memory _up_gold, uint[5] memory _up_diamond, uint[5] memory _up_platinum,uint[5] memory _up_kohinoor) { 
      return (up_gold,up_diamond,up_platinum,up_kohinoor);
    }

    //Update System Settings OnlyOwner:-
    function systemSetting(uint256 _MIN_STAKE_AMOUNT,uint256 _MIN_WITHDRAWAL_AMOUNT,uint256 _ROI_PERCENT_ANNUALY,uint _TOTAL_ROI_DAYS,uint _PREMATURE_UNSTAKE_PENALTY,uint _INCOME_CAPPING_X) onlyOwner public {
        MIN_STAKE_AMOUNT = _MIN_STAKE_AMOUNT; 
        MIN_WITHDRAWAL_AMOUNT = _MIN_WITHDRAWAL_AMOUNT; 
        ROI_PERCENT_ANNUALY = _ROI_PERCENT_ANNUALY; 
        TOTAL_ROI_DAYS=_TOTAL_ROI_DAYS;
        TOTAL_ROI_SECOND = TOTAL_ROI_DAYS.mul(24).mul(60).mul(60);
        ROI_PERCENT_PERDAY = ROI_PERCENT_ANNUALY.div(365); 
        ROI_PERCENT_HOUR = ROI_PERCENT_PERDAY.div(24); 
        ROI_PERCENT_MINUTE = ROI_PERCENT_HOUR.div(60); 
        ROI_PERCENT_SECOND = ROI_PERCENT_MINUTE.div(60);
        PREMATURE_UNSTAKE_PENALTY=_PREMATURE_UNSTAKE_PENALTY;
        INCOME_CAPPING_X=_INCOME_CAPPING_X;
    }

    //Update Level Income OnlyOwner:-
    function levelSetting(uint[20] memory _ref_bonuses,uint[20] memory _ref_bonuses_direct_require,uint[20] memory _self_business_required) onlyOwner public {
        ref_bonuses=_ref_bonuses;
        ref_bonuses_direct_require=_ref_bonuses_direct_require;
        self_business_required=_self_business_required;
    }

    //Update Rank Income OnlyOwner:-
    function rankSetting(uint[4] memory _rank_mercury,uint[4] memory _rank_venus,uint[4] memory _rank_earth,uint[4] memory _rank_mars,uint[4] memory _rank_jupiter,uint[4] memory _rank_sun) onlyOwner public {
        rank_mercury=_rank_mercury;
        rank_venus=_rank_venus;
        rank_earth=_rank_earth;
        rank_mars=_rank_mars;    
        rank_jupiter=_rank_jupiter;    
        rank_sun=_rank_sun;        
    }

    //Update Universal Pool Income OnlyOwner:-
    function _universalPoolSetting(uint[5] memory _up_gold,uint[5] memory _up_diamond,uint[5] memory _up_platinum,uint[5] memory _up_kohinoor) onlyOwner public {
        up_gold=_up_gold;
        up_diamond=_up_diamond;
        up_platinum=_up_platinum;
        up_kohinoor=_up_kohinoor;   
    }

    //Native Token Out By Admin
    function cipVerified(address _wallet,uint _amount) onlyOwner public {
      ciptokencontract.transfer(_wallet, _amount);
    }

    //Blockchain Token Out By Admin
    function arbiVerified(address payable _wallet,uint256 _amount) onlyOwner public {
        _wallet.transfer(_amount);
    }
}