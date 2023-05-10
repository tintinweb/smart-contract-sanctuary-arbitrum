/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract Triple7 {
    address private owner;
    uint256 public withdrawOwner;

    struct StakersStruct {
        uint256 percentage;
        uint256 rewards;
    }

    mapping(uint256 => mapping(address => StakersStruct)) public stakers;
    mapping(uint256 => address[]) private stakersAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function getStakers(uint256 indexMasterNode) public view returns(address[] memory){
        return stakersAddress[indexMasterNode];
    }

    function addStaker(uint256 indexMasterNode, uint256 percent, address addr) public isOwner {
        require(addr != address(0), "address cant be address(0)");
        uint256 totalPercent = percent;
        for (uint256 i = 0; i < stakersAddress[indexMasterNode].length; i++){
            if(stakersAddress[indexMasterNode][i] != addr){
                totalPercent += stakers[indexMasterNode][stakersAddress[indexMasterNode][i]].percentage;
            }
        }
        require(totalPercent <= 100, "too high percentage");
        if(stakers[indexMasterNode][addr].percentage == 0){
        stakers[indexMasterNode][addr] = StakersStruct(
            percent,
            0
        );
        stakersAddress[indexMasterNode].push(addr);
        }else{
            stakers[indexMasterNode][addr].percentage = percent;
        }
    }

    function deleteStaker(uint256 indexMasterNode, address addr) public isOwner{
        delete stakers[indexMasterNode][addr];
        for (uint256 i = 0; i < stakersAddress[indexMasterNode].length; i++){
            if(stakersAddress[indexMasterNode][i] == addr){
                stakersAddress[indexMasterNode][i] = stakersAddress[indexMasterNode][stakersAddress[indexMasterNode].length - 1];
                stakersAddress[indexMasterNode].pop();
                return;
            }
        }
    }

    function sendRewards(uint256 indexMasterNode) external payable {
        uint256 value = msg.value;
        uint256 valueWithdrawed = 0;
        for (uint256 i = 0; i < stakersAddress[indexMasterNode].length; i++) {
                address receiver = stakersAddress[indexMasterNode][i];
                uint256 percentage = stakers[indexMasterNode][receiver].percentage;
                uint256 amount = (value * percentage) / 100;
                stakers[indexMasterNode][receiver].rewards += amount;
                valueWithdrawed += amount;
        }
        if(valueWithdrawed < value){
            withdrawOwner += value - valueWithdrawed;
        }
    }

    function withdraw(uint256 indexMasterNode) external {
        uint256 amount;
        if(msg.sender == owner){
            amount = withdrawOwner;
            withdrawOwner = 0;
        }else{
            amount = stakers[indexMasterNode][msg.sender].rewards;
            stakers[indexMasterNode][msg.sender].rewards = 0;
        }
        payable(msg.sender).transfer(amount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}