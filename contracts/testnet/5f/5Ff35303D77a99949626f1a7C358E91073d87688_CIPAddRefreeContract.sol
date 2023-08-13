/**
 *Submitted for verification at Arbiscan on 2023-08-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICIPADDREFREE {
    function addReferee(address ref) external returns (bool);
    function getReferees(address ref,uint256 level) external view returns (address[] memory);
}

contract CIPAddRefreeContract is ICIPADDREFREE {

    struct User {
        uint256 userId;
        address referrer;
    }

    mapping (address => User) public users;

    event Joining(address indexed _user,address _referrer);

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

    function addReferee(address ref) public override returns(bool) {
        require(ref != msg.sender, "You cannot refer yourself !");
        require(users[ref].userId != 0,"Referrer not registered yet !");
        User storage user = users[msg.sender];
        require(user.userId == 0,"Already registered !");
        user.referrer = ref;
        address upline = user.referrer;
        for (uint i = 0; i < 20; i++) {
                if (upline == address(0)) break;
                    if(user.userId == 0){
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
        user.userId = block.timestamp; 
        emit Joining(msg.sender,ref);
        return true;
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

    constructor() {
        address owner=0xf913EFC77fFEA67361A6a47f3868feF813D7B930;
        users[owner].userId = block.timestamp;   
    }
}