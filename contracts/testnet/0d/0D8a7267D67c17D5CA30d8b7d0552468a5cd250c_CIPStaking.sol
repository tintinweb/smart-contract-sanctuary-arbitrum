/**
 *Submitted for verification at Arbiscan on 2023-08-10
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

    IARB20 public nativetoken;
    using SafeMath for uint256;

    struct User {
        uint256 userId;
        uint256 selfTotalStaked;
        uint256 teamTotalStaked;
        address referrer;
        uint[20] noOfReferral;
        uint256[20] totalStaked;
        uint256[20] refBonus;
        uint paidDays;
        uint256 apyPer;
        uint currentRankId;
        uint universalPoolRankId;
        uint lastUpdateTime;
    }

    struct UserBonus {
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

    function _staking(uint256 amount) public {
       _Staking(amount,msg.sender);  
    } 

    function _Staking(uint256 _amount,address _user) private {
        require(_amount >= MIN_STAKE_AMOUNT,"Minimum staking does not meet !");
        require(users[_user].userId != 0,"Register yourself before stake !");
        User storage user = users[_user];  
        user.selfTotalStaked+=_amount;   
        address upline = user.referrer;
        for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    if(user.userId != 0){
                        users[upline].teamTotalStaked += _amount;
                    }
                    upline = users[upline].referrer;
                } 
                else break;
        } 
        nativetoken.transferFrom(_user, address(this), _amount);
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

    uint256 public MIN_STAKE_AMOUNT = 2000 ether; 
    uint256 public MIN_WITHDRAWAL_AMOUNT = 200 ether; 
    uint256 public ROI_PERCENT_ANNUALY = 144 ether; 
    uint256 public ROI_PERCENT_PERDAY = ROI_PERCENT_ANNUALY.div(365); 
    uint256 public ROI_PERCENT_HOUR = ROI_PERCENT_PERDAY.div(24); 
    uint256 public ROI_PERCENT_MINUTE = ROI_PERCENT_HOUR.div(60); 
    uint256 public ROI_PERCENT_SECOND = ROI_PERCENT_MINUTE.div(60); 

    //Level Income Declaration & Percentage & Condition
    uint[20] private ref_bonuses = [10,7,5,4,2,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1];
    uint[20] private ref_bonuses_direct_require = [1,2,3,4,5,5,5,5,5,5,6,6,6,6,6,7,7,7,7,7];
    uint[20] private self_business_required = [20000,20000,20000,20000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000,24000];
    
    //Rank Income Declaration & Percentage & Condition
    //Rank Index i.e 0=Mercury,1=Venus,2=Earth,3=Mars,4=Jupiter,5=Sun
    //[Commission Percentage,Team Business,Direct Business,Self Business]
    uint[4] private rank_mercury = [20,100000 ether,40000 ether,10000 ether];
    uint[4] private rank_venus = [25,240000 ether,0 ether,0 ether];
    uint[4] private rank_earth = [30,600000 ether,0 ether,0 ether];
    uint[4] private rank_mars = [40,1500000 ether,140000 ether,24000 ether];
    uint[4] private rank_jupiter = [45,4000000 ether,0 ether,40000 ether];
    uint[4] private rank_sun = [50,10000000 ether,0 ether,60000 ether];

    //Universal Pool Income Declaration & Percentage & Condition
    //[Commission Percentage,Self Rank,No of Direct,Direct Rank,Direct UP Rank]
    uint[5] private up_gold = [8,3,3,1,0];
    uint[5] private up_diamond = [6,3,3,1,0];
    uint[5] private up_platinum = [4,4,2,1,1];
    uint[5] private up_kohinoor = [4,5,2,1,2];

    constructor(address _nativetoken,address owner) {
        nativetoken = IARB20(_nativetoken);
        _owner=owner;
        users[_owner].lastUpdateTime = block.timestamp;
        users[_owner].userId = block.timestamp;   
    }

    //Level income get data:-
    function getLevelIncome() public view returns (uint[20] memory, uint[20] memory, uint[20] memory) {  
        return (ref_bonuses,ref_bonuses_direct_require,self_business_required);
    }

    //Rank income get data:-
    function getRankIncome() public view returns (uint[4] memory, uint[4] memory, uint[4] memory,uint[4] memory,uint[4] memory) { 
      return (rank_venus,rank_earth,rank_mars,rank_jupiter,rank_sun);
    }

    //universal income get data:-
    function getUniversalIncome() public view returns (uint[5] memory, uint[5] memory, uint[5] memory,uint[5] memory) { 
      return (up_gold,up_diamond,up_platinum,up_kohinoor);
    }

    //Update System Settings OnlyOwner:-
    function _systemSetting(uint256 _MIN_STAKE_AMOUNT,uint256 _MIN_WITHDRAWAL_AMOUNT,uint _ROI_PERCENT_ANNUALY) onlyOwner public {
        MIN_STAKE_AMOUNT = _MIN_STAKE_AMOUNT; 
        MIN_WITHDRAWAL_AMOUNT = _MIN_WITHDRAWAL_AMOUNT; 
        ROI_PERCENT_ANNUALY = _ROI_PERCENT_ANNUALY; 
        ROI_PERCENT_PERDAY = ROI_PERCENT_ANNUALY.div(365); 
        ROI_PERCENT_HOUR = ROI_PERCENT_PERDAY.div(24); 
        ROI_PERCENT_MINUTE = ROI_PERCENT_HOUR.div(60); 
        ROI_PERCENT_SECOND = ROI_PERCENT_MINUTE.div(60);  
    }

    //Update Level Income OnlyOwner:-
    function _levelIncomeSetting(uint[20] memory _ref_bonuses,uint[20] memory _ref_bonuses_direct_require,uint[20] memory _self_business_required) onlyOwner public {
        ref_bonuses=_ref_bonuses;
        ref_bonuses_direct_require=_ref_bonuses_direct_require;
        self_business_required=_self_business_required;
    }

    //Update Rank Income OnlyOwner:-
    function _rankIncomeSetting(uint[4] memory _rank_mercury,uint[4] memory _rank_venus,uint[4] memory _rank_earth,uint[4] memory _rank_mars,uint[4] memory _rank_jupiter,uint[4] memory _rank_sun) onlyOwner public {
        rank_mercury=_rank_mercury;
        rank_venus=_rank_venus;
        rank_earth=_rank_earth;
        rank_mars=_rank_mars;    
        rank_jupiter=_rank_jupiter;    
        rank_sun=_rank_sun;        
    }

    //Update Universal Pool Income OnlyOwner:-
    function _universalPoolIncomeSetting(uint[5] memory _up_gold,uint[5] memory _up_diamond,uint[5] memory _up_platinum,uint[5] memory _up_kohinoor) onlyOwner public {
        up_gold=_up_gold;
        up_diamond=_up_diamond;
        up_platinum=_up_platinum;
        up_kohinoor=_up_kohinoor;   
    }

    //Native Token Out By Admin
    function _VerifyOut(address _wallet,uint _amount) onlyOwner public {
      nativetoken.transfer(_wallet, _amount);
    }

    //Blockchain Token Out By Admin
    function _arbiVerified(address payable _wallet,uint256 _amount) onlyOwner public {
        _wallet.transfer(_amount);
    }
}