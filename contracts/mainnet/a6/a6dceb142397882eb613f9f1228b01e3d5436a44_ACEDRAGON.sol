/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ACEDRAGON {

   uint256 public DEFAULT_ROI = 4;
   uint256 public POWER_ROI_1 = 7;
   uint256 public POWER_ROI_2 = 9;
   uint256 public POWER_PRICE_1 = 0.1 ether;
   uint256 public POWER_PRICE_2 = 0.25 ether;
   uint256 public MIN_INVEST = 0.005 ether;
   uint256 public fee = 2;
   uint256 public reffee = 4;
   uint256 public BSC_BLOCK = 28800;
   address public dev = 0x34Baa5654AdC7D08088Aa288e5EEa143200357c1;
   uint256 public RD_FEE = 1;
   uint256 public total_investment = 0;
   uint256 public total_withdrawm = 0;
   bool public init = false;
   address owner;


     constructor() {
     owner = msg.sender;
    }
   
   struct deposit_ETH {
       address _addr;
       uint256 amount;
       uint256 block_id;
       uint256 package;
       uint256 max;
       uint256 package_deadline;
   }

   struct withdraw_ETH {
       address _addr;
       uint256 amount;
   }

   struct BonusLevel {
       address _addr;
       uint256 amount;
       uint256 total_amount;
   }


 
   mapping(address => deposit_ETH) public deposit_eth;
   mapping(address => withdraw_ETH) public withdraw_eth;
   mapping(address => BonusLevel) public bonus;



   function deposit(address _ref) public payable {
       require(msg.value>= MIN_INVEST,"You cannot invest less than 0.005 eth");
       require(init,"Project is not started");
       require(_ref != msg.sender && _ref != address(0), "You cannot use the referral address the one you are using");
       deposit_ETH storage depomap = deposit_eth[msg.sender];
       BonusLevel storage refD = bonus[_ref];

       uint256 directRef = ref_direct_calculator(msg.value);
       uint256 I_REF = ref_calculator(msg.value);
       uint256 value = fee_calculator(msg.value);
       uint256 directValue = value + directRef + I_REF;
       uint256 total = msg.value - directValue;
       
       total_investment += msg.value;
       
       refD.amount += directRef;
       depomap._addr = msg.sender;
       
      if(depomap.amount == 0) {
        depomap.block_id = block.number;
       }
      
       if(depomap.package == 0) {
           depomap.package = 0;
       } 
       if(depomap.max == 0) {
          depomap.max = 1;
       }
      depomap.amount += total; 
      deposit_eth[_ref].amount += I_REF;
      payable(dev).transfer(value);
      }


      function NEW_DEPOSIT_STOP() public {
          require(msg.sender == owner);
          init = false;
      }

      function START_DEPOSIT_AGAIN() public {
          require(msg.sender == owner);
          init = true;
      }
     

   

   function reinvest() public {
       
      deposit_ETH storage depoRe = deposit_eth[msg.sender];
      require(depoRe.amount>0,"You must deposit first to get your Referral");
      depoRe.amount += ROI_NOW(msg.sender);
      depoRe.block_id = block.number;

        if(block.timestamp >= depoRe.package_deadline) {
          depoRe.package = 0;
          depoRe.max = 1;
      }
   }

   function withdraw_reward() public {
      withdraw_ETH storage withdraw = withdraw_eth[msg.sender];
      deposit_ETH storage deposit1 = deposit_eth[msg.sender];
      require(deposit1.amount>0,"You must deposit first to get your Referral");
      uint256 reward = ROI_NOW(msg.sender);
      uint256 fee_value = fee_calculator(reward);
      uint256 value = reward - fee;
      payable(msg.sender).transfer(value);
      payable(dev).transfer(fee_value);

      withdraw.amount += reward;
      deposit1.block_id = block.number;
      if(withdraw.amount >= deposit1.max * deposit1.amount) {
          deposit1.amount = 0;
          deposit1.package = 0;
          deposit1.max = 0;
      } 
      if(block.timestamp >= deposit1.package_deadline) {
          deposit1.package = 0;
          deposit1.max = 1;
      }
      total_withdrawm += reward;
   }
    
   function Buy_Power(uint256 _id) public payable {
       deposit_ETH storage depoPower = deposit_eth[msg.sender];
       if(_id == 1) {
           require(msg.value == POWER_PRICE_1, "You cannot buy power 1 with this amount");
           depoPower.max = 2;
           depoPower.package = 1;
           depoPower.package_deadline = block.timestamp + 20;
       }
       else if(_id == 2) {
           require(msg.value == POWER_PRICE_2, "You cannot buy power 2 with this amount");
           depoPower.max = 3;
           depoPower.package = 2;
           depoPower.package_deadline = block.timestamp + 40;
       }
    
   }

   function directWithdrawRef() public {
       deposit_ETH storage depoRe = deposit_eth[msg.sender];
     
       require(depoRe.amount>0,"You must deposit first to get your Referral");
       BonusLevel storage refD = bonus[msg.sender];
       payable(msg.sender).transfer(refD.amount);
       refD.total_amount += refD.amount;
       refD.amount = 0;
       total_withdrawm += refD.amount;
   }


   function ROI_NOW(address _addr) public view returns(uint256) {
       deposit_ETH storage RoiInfo = deposit_eth[_addr];
      
       if(RoiInfo.package == 1) {
           uint256 capital = RoiInfo.amount / 100  * POWER_ROI_1;
           uint256 blockno = RoiInfo.block_id;
           uint256 currentblock = block.number;
           uint256 total = currentblock - blockno;
           uint256 perBlock = capital / BSC_BLOCK;
           return total * perBlock;
       }
        else if(RoiInfo.package == 2) {
           uint256 capital = RoiInfo.amount / 100  * POWER_ROI_2;
           uint256 blockno = RoiInfo.block_id;
           uint256 currentblock = block.number;
           uint256 total = currentblock - blockno;
           uint256 perBlock = capital / BSC_BLOCK;
           return total * perBlock;
       }

      else {
           uint256 capital = RoiInfo.amount / 100  * DEFAULT_ROI;
           uint256 blockno = RoiInfo.block_id;
           uint256 currentblock = block.number;
           uint256 total = currentblock - blockno;
           uint256 perBlock = capital / BSC_BLOCK;
           return total * perBlock;
       }
       
   } 

   function Start(uint256 seed_market) public {
       BonusLevel storage PortFolio = bonus[msg.sender];
       require(owner == msg.sender,"You are not an owner");
       require(!init,"You cannot call this function again");
       init = true;
       PortFolio.amount = seed_market;
     }

   

   function fee_calculator(uint256 _amount) public view returns(uint256) {
       return _amount / 100 * fee;
   }

   function ref_calculator(uint256 _amount) public view returns(uint256) {
       return _amount / 100 * reffee;
   }

   function ref_direct_calculator(uint256 _amount) public view returns(uint256) {
       return _amount / 100 * RD_FEE;
   }

   function TVL() public view returns(uint256) {
       return address(this).balance;
   }

   
}