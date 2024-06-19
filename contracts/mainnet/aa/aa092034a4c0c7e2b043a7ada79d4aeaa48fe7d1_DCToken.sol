/**
 *Submitted for verification at Arbiscan.io on 2024-06-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DCToken {
    string public name = "Democracy Currency";//货币全称民主货币/个人主权货币
    string public symbol = "DC"; //货币符号
   
    mapping(address => uint256) public balanceOf; //账户余额
    mapping(address => bool) public verified;//是否验证
    mapping(address => uint) public lastverifiedtime;//上次认证时间
    mapping(address => bool) public voter;//是否成为了投票者
    mapping(address => uint) public lastclaimtime;//上次领取空投时间
    mapping(address => string) public application_URL;//申请认证证明网络地址
    mapping(address => bool) public isappling;//是否在申请认证中
    mapping(address => uint) public agree;//投票同意人数
    mapping(address => uint) public opposition;//投票反对人数
    mapping(address => uint) public lastvotetime;//验证者上次投票时间
    mapping(address=>address) public voteto;//投票给了谁
    mapping(address=>bool) public voting;//验证者是否在投票中
    mapping(address => uint) public lastdectime;//上次衰减时间
   
    address[] private applyList;
    
    
    uint private  dectime = 0;
    uint private dec = 3;// 账户资金衰减：1 个月减少千分之3
    uint private declong = 3600*24*30;
    uint public whitelist=10000;//白名单个数，构建初始社区，运作起来后会弃权掉剩下的白名单
    address private creater;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    
    constructor() {
        balanceOf[msg.sender] = 1000000;//创建者初始代币，用于建设初始社区
        verified[msg.sender] = true;
        application_URL[msg.sender]="whitelist";
        lastverifiedtime[msg.sender]=block.timestamp;  
        dectime = block.timestamp;
        creater=msg.sender;
    }
    //小数位数为0，一个只有整数的代币
    function decimals() public pure returns (uint8) {
        return 0;
    }
    //查询申请人个数
    function refreshapplicants()public view returns(uint256)
    {
        return  applyList.length;
    }
   //刷新账户余额，账户余额衰减周期为1个月,每月衰减千分之3左右，一个月刷新一次就可以了
    function refreshbalance() public{

         if (lastdectime[msg.sender] == 0) {
            lastdectime[msg.sender] = dectime;
        }

        if (block.timestamp - dectime >= declong) {
            dectime = block.timestamp;
        }

        require (lastdectime[msg.sender] < dectime,"No need to decbalance") ;
        
            balanceOf[msg.sender] = balanceOf[msg.sender] * (1000 - (dec * (dectime - lastdectime[msg.sender]) / declong>1000?1000:dec * (dectime - lastdectime[msg.sender]) / declong)) / 1000;
            
            lastdectime[msg.sender] = dectime;
        
        
    }
    //创建者一票验证
    function whitevote(address _Address,bool approve)public{
        require(msg.sender==creater, "You are not creater");
        require(isappling[_Address], "Address is not an applicant");
        require(whitelist>0, "No whitelist left");

        verified[_Address] = approve;
        isappling[_Address] = false;
        lastverifiedtime[_Address] = block.timestamp;

         for (uint i = 0; i < applyList.length; i++) {
                if (applyList[i] == _Address) {
                    applyList[i] = applyList[applyList.length - 1];
                    applyList.pop();
                    break;
                }
            }
       whitelist--;
    }
    //丢弃创建者权限
   function dropwhitelist()public{
      require(msg.sender==creater, "You are not creater");
      require(whitelist>0, "No whitelist left");
      whitelist=0;

   }
    //投票功能，100票决定是否通过
    function vote(address _Address, bool approve) public {
        require(voter[msg.sender], "You are not voter, please apply to be a voter");
        require(balanceOf[msg.sender] >= 100, "Coins less than 100");
        require(isappling[_Address], "Address is not an applicant");
        require(agree[_Address] + opposition[_Address] < 100, "Voted arrived 100 tickets");
        require(block.timestamp - lastvotetime[msg.sender] >= 3600*24, "1 day only vote 1 time");
        //一年后个人身份失效，需要重新提交申身份认证申请
        require(block.timestamp - lastverifiedtime[msg.sender] < 3600 * 24 * 365 ,"Identity verification expired " );

        if (approve) {
            agree[_Address]++;
        } else {
            opposition[_Address]++;
        }

        balanceOf[msg.sender] -= 100;
        voteto[msg.sender] = _Address;
        voting[msg.sender] = true;
        lastvotetime[msg.sender] = block.timestamp;
        //验证个人身份
        if (agree[_Address] + opposition[_Address] >= 100) {
            if (agree[_Address] > opposition[_Address]) {
                verified[_Address] = true;
                isappling[_Address] = false;
                lastverifiedtime[_Address] = block.timestamp;
            } else {
                isappling[_Address] = false;
            }

            for (uint i = 0; i < applyList.length; i++) {
                if (applyList[i] == _Address) {
                    applyList[i] = applyList[applyList.length - 1];
                    applyList.pop();
                    break;
                }
            }
        }
    }
   //从申请列表中获取他们的地址，如果有5个人申请，那么输入参数就是0到4
    function get_address_from_applylist(uint index) public view returns (address) {
        require(index < applyList.length, "Index out of bounds");
        return applyList[index];
    }
   //获取验证者投票奖励,获胜将拿到 200 DC,失败就会拿不到 DC
    function getrewards() public {
        require(voter[msg.sender], "you are not voter, please apply to be a voter");
        require(voting[msg.sender], "You have no voting");
        require(agree[voteto[msg.sender]] + opposition[voteto[msg.sender]] >= 30, "Tickets not enough 30");

        if (verified[voteto[msg.sender]] == true) {
            voting[msg.sender] = false;
            balanceOf[msg.sender] += 200;
        } else {
            voting[msg.sender] = false;
        }
    }
    //申请个人身份认证，需要输入证明自己身份的视频地址连接，供验证者查看验证 花费 5000 DC
    function application(string memory _URL) public {
        require(balanceOf[msg.sender] >= 5000, "Coins less than 5000");
        require(verified[msg.sender] == false, "You are already vertified");
        require(applyList.length < 200, "Waiting to apply, over 200 people applicants");
        require(isappling[msg.sender] == false, "You are in applying");

        balanceOf[msg.sender] -= 5000;
        application_URL[msg.sender] = _URL;
        applyList.push(msg.sender);
        isappling[msg.sender] = true;
        agree[msg.sender] = 0;
        opposition[msg.sender] = 0;
    }
   //转账
    function transfer(address to, uint256 value) public {
        if (block.timestamp - dectime >= declong) {
            dectime = block.timestamp;
        }

        if (lastdectime[msg.sender] == 0) {
            lastdectime[msg.sender] = dectime;
        }

        if (lastdectime[to] == 0) {
            lastdectime[to] = dectime;
        }

        if (lastdectime[msg.sender] < dectime) {
            balanceOf[msg.sender] = balanceOf[msg.sender] * (1000 - (dec * (dectime - lastdectime[msg.sender]) / declong>1000?1000:dec * (dectime - lastdectime[msg.sender]) / declong)) / 1000;
            lastdectime[msg.sender] = dectime;
        }

        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
    }
    //领取每日空投 1000 DC
    function claim() public {
        require(verified[msg.sender], "Address not verified");
        require(block.timestamp - lastclaimtime[msg.sender] > 3600*24, "Please wait more than 1 day to claim");

        if (block.timestamp - lastverifiedtime[msg.sender] >= 3600 * 24 * 365 && lastverifiedtime[msg.sender] != 0) {
            verified[msg.sender] = false;
            return;
        }

        if (lastdectime[msg.sender] == 0) {
            lastdectime[msg.sender] = dectime;
        }

        if (block.timestamp - dectime >= declong) {
            dectime = block.timestamp;
        }

        if (lastdectime[msg.sender] < dectime) {
            balanceOf[msg.sender] = balanceOf[msg.sender] * (1000 - (dec * (dectime - lastdectime[msg.sender]) / declong>1000?1000:dec * (dectime - lastdectime[msg.sender]) / declong)) / 1000;
            lastdectime[msg.sender] = dectime;
        }

            balanceOf[msg.sender] += 1000;
            lastclaimtime[msg.sender] = block.timestamp;
        
    }
   //成为验证者,花费 3000 DC
    function bevoter() public {
        require(voter[msg.sender] == false, "You are already a voter");
        require(balanceOf[msg.sender] >= 3000, "Coins less than 3000");
        balanceOf[msg.sender] -= 3000;
        voter[msg.sender] = true;
    }
}