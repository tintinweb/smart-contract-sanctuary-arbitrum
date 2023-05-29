// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "Ownable.sol";

contract AWARD is Ownable{
    uint public cycle;
    uint public awardRankSize;
    uint256 public cycleAwardBlockNumber;
    uint256 public startAwardBlockNumber;
    mapping(uint256 => uint256) public awardMap;
    mapping(uint => uint256) public rankMap;

    constructor() {      
        // __Ownable_init();
        cycle = 0;
        awardRankSize = 5;
        cycleAwardBlockNumber = 0;
        startAwardBlockNumber = 0;
        rankMap[1] = 35;
        rankMap[2] = 25;
        rankMap[3] = 20;
        rankMap[4] = 10;
        rankMap[5] = 10;
    }

    function setAwardRankSize(uint inAwardRankSize)public onlyOwner{
        require(inAwardRankSize != 0, "award size number not 0");
        awardRankSize = inAwardRankSize;
    }

    function setStartAwardBlockNumber(uint256 blockNumber)public onlyOwner{
        require(blockNumber != 0, "award block number not 0");
        // console.log("b:%d b:%d",blockNumber,block.number);
        require(blockNumber > block.number, "award block <= cur block number");
        startAwardBlockNumber = blockNumber;
    }

    function setCycleAwardBlockNumber(uint256 blockNumber)public onlyOwner{
        require(blockNumber != 0, "award block number not 0");
        cycleAwardBlockNumber = blockNumber;
    }

    function award(address[][] calldata userAddrs)public onlyOwner{
        require(userAddrs.length > 0,"user address length is 0");
        require(userAddrs.length == awardRankSize,"awards not award rank size");

        address contractsAddress = address(this);
        uint256 balance = contractsAddress.balance;
        require(balance != 0, "address balance is 0");
        uint256 receiveAwardValue = awardMap[cycle];
        require(receiveAwardValue != 0, "receive award is 0");
        require(balance >= receiveAwardValue, "balance < award amount");
        
        for(uint i=0;i<userAddrs.length;i++){
            uint rankNumber = i + 1;
            uint256 rankRate = rankMap[rankNumber];
            require(rankRate > 0,"rate is 0");
            address[] calldata tmpUserAddrs = userAddrs[i];
            uint256 sumAmount = 0;
            uint256 perAmount = 0;
            if(tmpUserAddrs.length > 0){
                unchecked {
                    sumAmount = receiveAwardValue / 100 * rankRate ;
                    perAmount = sumAmount / tmpUserAddrs.length;
                }
                require(sumAmount > 0,"sumAmount is 0");
                require(perAmount > 0,"perAmount is 0");
                // console.log("rank:%ld sum:%ld per:%ld",rankRate,sumAmount,perAmount);
            }else{
                // console.log("rank:%ld sum:%ld per:%ld",rankRate,sumAmount,perAmount);
                continue;
            }
            
            for(uint j=0;j<tmpUserAddrs.length;j++){
                address userAddr = tmpUserAddrs[j];
                require(userAddr != address(0), "award from the zero address");
                payable(userAddr).transfer(perAmount);
            }
        }
        cycle += 1;
    }

    function getContractsBalance()public view virtual returns(uint256){
        address contractsAddress = address(this);
        uint256 balance = contractsAddress.balance;
        return balance;
    }

    receive() external payable{
        require(msg.value >= 0, "receive is 0");
        if(startAwardBlockNumber == 0||cycleAwardBlockNumber ==0){
            awardMap[cycle] += msg.value ;
        }else{
            uint256 tmpAwardBlockNumber = block.number - startAwardBlockNumber;
            uint256 cycleNum = tmpAwardBlockNumber / cycleAwardBlockNumber;
            awardMap[cycleNum] += msg.value;
        }
    }
    
    fallback() external payable{}

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

}