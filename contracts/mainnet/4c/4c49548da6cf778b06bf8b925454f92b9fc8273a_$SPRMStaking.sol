/**
 *Submitted for verification at Arbiscan.io on 2024-03-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20{
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) ;
}

contract $SPRMStaking
    {
       
        address  public owner;

        address USDTcontract=0xD1a9F89B49D4a0BacBE7EE2069234C3606fF488d;
        address USDTTOKENcontract=0xD1a9F89B49D4a0BacBE7EE2069234C3606fF488d;
        uint public totalUSDTInvestors;
        uint public min_Stake_amount=1*10**18;  
        uint public max_Stake_amount=50000000000000000*10**18; 
        
        uint public investmentPeriod1=7 days;
        uint public investmentPeriod2=28 days;
        uint public investmentPeriod3=63 days;
        uint public investmentPeriod4=112 days;
        uint public investmentPeriod5=175 days;
        uint public investmentPeriod6=252 days;
        uint public investmentPeriod7=343 days;



        uint public totalbusiness; 
        uint rew_till_done;


        struct allInvestments{
            uint investedAmount;
            uint withdrawnTime;
            uint DepositTime;
            uint investmentNum;
            uint unstakeTime;
            bool unstake;
        }

        struct ref_data{
            uint reward;
            uint count;
        }

        struct Data{
            mapping(uint=>allInvestments) investment;
            uint reward;
            uint noOfInvestment;
            uint totalInvestment;
            uint totalWithdraw_reward;
            bool investBefore;
            uint stakeTime;
        }
  
        mapping(address=>Data) public USDTinvestor;


        constructor(){
            owner=msg.sender;              //here we are setting the owner of this contract
        }

        modifier onlyOwner(){
            require(msg.sender==owner,"only Owner can call this function");
            _;
            
        }



        function Stake(uint _investedamount, uint _lockType) external returns(bool success){

            require(_investedamount >= min_Stake_amount && _investedamount <= max_Stake_amount,"value is not greater than 1 and less than 5000000");     //ensuring that investment amount is not less than zero
            require(_lockType ==1 || _lockType == 2 || _lockType == 3 || _lockType == 4 || _lockType == 5 || _lockType == 6 || _lockType == 7, "invalid period");
            
            if(USDTinvestor[msg.sender].investBefore == false)
            { 
                totalUSDTInvestors++;                                     
            }
            if(USDTinvestor[msg.sender].totalInvestment == 0)
            {   
                if(_lockType == 1){

                    USDTinvestor[msg.sender].stakeTime = block.timestamp + investmentPeriod1;
                }else if(_lockType == 2){

                    USDTinvestor[msg.sender].stakeTime = block.timestamp + investmentPeriod2;
                }else if(_lockType == 3){

                    USDTinvestor[msg.sender].stakeTime = block.timestamp + investmentPeriod3;
                }else if(_lockType == 4){
                        
                    USDTinvestor[msg.sender].stakeTime = block.timestamp + investmentPeriod4;
                }
            }

            uint num = USDTinvestor[msg.sender].noOfInvestment;
            USDTinvestor[msg.sender].investment[num].investedAmount =_investedamount;
            USDTinvestor[msg.sender].investment[num].DepositTime=block.timestamp;
            uint _period = _lockType==1?investmentPeriod1:(_lockType==2?investmentPeriod2:(_lockType==3?investmentPeriod3:investmentPeriod4));
            USDTinvestor[msg.sender].investment[num].withdrawnTime=block.timestamp + _period;
            USDTinvestor[msg.sender].investment[num].investmentNum=num;
            USDTinvestor[msg.sender].totalInvestment+=_investedamount;
            USDTinvestor[msg.sender].noOfInvestment++;
            totalbusiness+=_investedamount;
            IERC20(USDTcontract).transferFrom(msg.sender,address(this),_investedamount);
            
            USDTinvestor[msg.sender].investBefore=true;

            return true;
            
        }
        function getReward() view public returns(uint){ //this function is get the total reward balance of the investor
            uint totalReward;
            uint depTime;
            uint rew;
            uint temp = USDTinvestor[msg.sender].noOfInvestment;
            for( uint i = 0;i < temp;i++)
            {   
                if(!USDTinvestor[msg.sender].investment[i].unstake)
                {
                    depTime =block.timestamp - USDTinvestor[msg.sender].investment[i].DepositTime;
                }
                else{
                    depTime =USDTinvestor[msg.sender].investment[i].unstakeTime - USDTinvestor[msg.sender].investment[i].DepositTime;
                }
                depTime=depTime; //1 second

                if(depTime>0)
                {
                    rew  = (((USDTinvestor[msg.sender].investment[i].investedAmount)/4)/31536000);
                    totalReward += depTime * rew;
                }
            }
            totalReward -= USDTinvestor[msg.sender].totalWithdraw_reward;

            return totalReward;
        }

        function withdrawReward() external returns (bool success){
            
            uint Total_reward = getReward();
            require(Total_reward>0,"you dont have rewards to withdrawn");   
        
            IERC20(USDTTOKENcontract).transfer(msg.sender,Total_reward);// transfering the reward to investor          
            USDTinvestor[msg.sender].totalWithdraw_reward+=Total_reward;

            return true;

        }


        function unStake() external  returns (bool success){

            require(USDTinvestor[msg.sender].totalInvestment>0,"you dont have investment to withdrawn"); //checking that he invested any amount or not
            require(USDTinvestor[msg.sender].stakeTime<block.timestamp, "Unstake time not passed");
            uint amount=USDTinvestor[msg.sender].totalInvestment;

            IERC20(USDTcontract).transfer(msg.sender,amount);//transferring this specific investment to the investor
            
            rew_till_done =USDTinvestor[msg.sender].noOfInvestment;                                       
            USDTinvestor[msg.sender].totalInvestment=0;           // decrease this invested amount from the total investment

            return true;

        }

        function getTotalInvestmentUSDT() public view returns(uint) {   //this function is to get the total investment of the ivestor
            return USDTinvestor[msg.sender].totalInvestment;

        }

        function getAllUSDTinvestments() public view returns (allInvestments[] memory) { //this function will return the all investments of the investor and withware date
            uint num = USDTinvestor[msg.sender].noOfInvestment;
            uint temp;
            uint currentIndex;
            for(uint i=0;i<num;i++)
            {
               if( USDTinvestor[msg.sender].investment[i].investedAmount > 0 ){
                   temp++;
               }

            }
         
            allInvestments[] memory Invested =  new allInvestments[](temp) ;

            for(uint i=0;i<num;i++)
            {
               if( USDTinvestor[msg.sender].investment[i].investedAmount > 0 ){
                 //allInvestments storage currentitem=USDTinvestor[msg.sender].investment[i];
                   Invested[currentIndex]=USDTinvestor[msg.sender].investment[i];
                   currentIndex++;
               }

            }
            return Invested;

        }
       
        function set_min_Stake_amount(uint _amount) public
        {
            min_Stake_amount = _amount;
        }
        function set_max_Stake_amount(uint _amount) public 
        {
            max_Stake_amount = _amount;
        }
        function set_values(uint min_stake,uint max_stake) public 
        {
            max_Stake_amount = max_stake;
            min_Stake_amount = min_stake;
            
            
        }

        function withdrawToken(address _address, uint _amount, address _receiver) public onlyOwner{
            IERC20(_address).transfer(_receiver, _amount);
        }

        function withdraw(uint _amount, address _receiver) public onlyOwner {

            payable(_receiver).transfer(_amount);
        }


        function transferOwnership(address _newOwner) public onlyOwner {
            owner = _newOwner;
        }

        function renounceOwnership() public onlyOwner {
            owner = address(0);
        }

        function setUnstakeTImes(uint _time1, uint _time2, uint _time3, uint _time4) public onlyOwner {
            investmentPeriod1 = _time1;
            investmentPeriod2 = _time2;
            investmentPeriod3 = _time3;
            investmentPeriod4 = _time4;
        }



    }