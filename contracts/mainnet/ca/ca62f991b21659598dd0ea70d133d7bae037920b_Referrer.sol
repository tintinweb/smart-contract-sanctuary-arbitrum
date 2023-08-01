/**
 *Submitted for verification at Arbiscan on 2023-07-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    
}

contract Referrer {
	using SafeMath for uint256;
    mapping(address => address) public user_referrer;
    mapping(address => address[]) public user_directR;
    mapping(address =>uint256) public user_team_num;
    uint256 public LEVEL_NUM = 7;
    address public rootAddr = address(0xDC3e0B9223cc9179dfA12c59a40991827aC8A0Cc);

    constructor () {
		user_referrer[rootAddr] = rootAddr;
	}

	function IsRegisterEnable(address _user,address _userReferrer) public view returns (bool){
		return (
			_user != address(0) && 
			user_referrer[_user] == address(0) &&
			_userReferrer != address(0) &&
			_user != _userReferrer && 
			user_referrer[_userReferrer] != address(0) &&
			user_referrer[_userReferrer] != _user);
	}
	
	function getUserDirectReferNum(address _user) external view returns (uint256) {
		return user_directR[_user].length;
	}

	function getUserDirectRefers(address _user,uint256 pos,uint256 num) external view returns( address[] memory){
		address[] memory refers;
		uint256 len = user_directR[_user].length;
		if(pos>=len){
			refers = new address[](0);
		}else{
			if(pos.add(num) >len) num = len.sub(pos);
			refers = new address[](num);
			uint256 end = pos.add(num);
			uint256 index = 0;
			for(uint256 i = pos;i<end;i++){
				refers[index] = user_directR[_user][i];
				index++;
			}
		}
		return refers;
	}

	function register(address _userReferrer) external returns (bool){
		if(IsRegisterEnable(msg.sender ,_userReferrer)){
			user_referrer[msg.sender] = _userReferrer;
			user_directR[_userReferrer].push(msg.sender);
			uint256 level = 0;
			address up = _userReferrer;
			while(up != rootAddr && level < LEVEL_NUM){
                user_team_num[up] = user_team_num[up] + 1;
                up = user_referrer[up];
                level++;
            }
			return true;
		}
		return false;
	}

	receive () external payable {
	    revert();
	}
}