/**
 *Submitted for verification at Arbiscan on 2022-06-05
*/

//创建不同的募资活动，用来募集以太坊
//记录相应活动下的募资总体信息（参与人数，募集的以太坊数量），以及记录参与的用户地址以及投入的数量
//业务逻辑（用户参与，添加新的募集活动，活动结束后进行资金提取）

pragma solidity 0.8.11;

contract CrowdFunding{
    //Campaign结构体, 一个campaign即一个筹款活动
    struct Campaign{
        address payable receiver; //募集地址
        uint numFunders; //多少个资助者
        uint fundingGoal; //募集目标
        uint totalAmount; //总共金额
    }

    //Funder结构体，包括funder地址和捐赠数量
    struct Funder{
        address addr;
        uint amount;
    }

    uint public numCampaigns;  //活动个数
    mapping(uint => Campaign) campaigns; //mapping映射，用活动编号对应一个活动，这个mapping名字叫campaigns
    mapping(uint => Funder[]) funders; //mapping映射，对应funder

    mapping(uint => mapping(address =>bool)) public isParticipate; //构建一个叫isParticipate的嵌套mapping,来查用户是否参与了（活动ID，（用户，是否参与））

    //modifier函数修饰器，在函数执行前自动检查某个条件：传入一个活动ID, 要求用户没参加过;[msg.sender]当前调用的账户地址
    modifier judgeParticipate(uint campaignID){
        require(isParticipate[campaignID][msg.sender] == false);
        _; //通过require的判断条件后，会执行函数的name
    }


    //创建新的募集活动,传入募集地址和目标，传出campaignID
    function newCampaign(address payable receiver, uint goal) external returns(uint campaignID){
        campaignID= numCampaigns++; //活动个数+1,作为新活动的ID
        Campaign storage c=campaigns[campaignID]; // 用新活动的ID作为key mapping到一个新活动，存为c
        c.receiver = receiver; 
        c.fundingGoal=goal;
    }

    //用户参与
    function bid(uint campaignID) external payable judgeParticipate(campaignID){
        Campaign storage c= campaigns[campaignID];

        c.totalAmount += msg.value; //msg.value 交易发送的以太数量
        c.numFunders += 1; //Funder数量+1

        funders[campaignID].push(  //push:在数组末尾加一个funder结构体
            Funder( //给funder结构体赋值
                { 
                addr: msg.sender, //msg.sender当前调用的账户地址
                 amount: msg.value  //msg.value 交易发送的以太数量
                }
                 
             )
        );
        
        isParticipate[campaignID][msg.sender]= true;
    }

    //活动结束后进行资金提取,传入活动ID, 返回是否成功提取
    function withdraw(uint campaignID)external returns(bool reached){
        Campaign storage c= campaigns[campaignID];

        if(c.totalAmount<c.fundingGoal){ //判断是否达到目标，没有返回false
            return false;
        }

        //达到目标，则：
        uint amount= c.totalAmount; 
        c.totalAmount=0; //把总余额置为0
        c.receiver.transfer(amount); //把钱转出

        return true;



    }
}