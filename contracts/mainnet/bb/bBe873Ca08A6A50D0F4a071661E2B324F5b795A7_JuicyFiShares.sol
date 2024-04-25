// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

//import "@openzeppelin/contracts/access/Ownable.sol";

import "./Ownable.sol";
// TODO: Events, final pricing model, 

contract JuicyFiShares is Ownable {
    address public protocolFeeDestination;
    uint256 public protocolFeePercent       = 35000000000000000;
    uint256 public subjectFeePercent        = 50000000000000000;
    uint256 public referralFeePercent       = 10000000000000000;
    uint256 public referral2LevelFeePercent = 5000000000000000;

    event Trade(
        uint256 orderId,
        address trader, 
        address subject, 
        bool isBuy, 
        TradeDetail referralInfo,
        uint256 supply);

    struct TradeDetail{
        uint256 shareAmount; 
        uint256 ethAmount; 
        uint256 protocolEthAmount; 
        uint256 subjectEthAmount;
        address referralMainAddress;
        uint256 referralMainEthAmount;
        address referralSubAddress;
        uint256 referralSubEthAmount;
    }

    // SharesSubject => (Holder => Balance)
    mapping(address => mapping(address => uint256)) public sharesBalance;

    // SharesSubject => Supply
    mapping(address => uint256) public sharesSupply;

    function setFeeDestination(address _feeDestination) public onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function getPrice(uint256 supply, uint256 amount) public pure returns (uint256) {
        uint256 sum1 = supply == 0 ? 0 : (supply - 1 )* (supply) * (2 * (supply - 1) + 1) / 6;
        uint256 sum2 = supply == 0 && amount == 1 ? 0 : (supply - 1 + amount) * (supply + amount) * (2 * (supply - 1 + amount) + 1) / 6;
        uint256 summation = sum2 - sum1;
        return summation * 1 ether / 20000;
    }

    function getBuyPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject], amount);
    }

    function getSellPrice(address sharesSubject, uint256 amount) public view returns (uint256) {
        return getPrice(sharesSupply[sharesSubject] - amount, amount);
    }

    function getBuyPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getBuyPrice(sharesSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 referralFee = price * referralFeePercent / 1 ether;
        uint256 referral2LevelFee = price * referral2LevelFeePercent / 1 ether;
        return price + protocolFee + subjectFee + referralFee + referral2LevelFee;
    }

    function getSellPriceAfterFee(address sharesSubject, uint256 amount) public view returns (uint256) {
        uint256 price = getSellPrice(sharesSubject, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 referralFee = price * referralFeePercent / 1 ether;
        uint256 referral2LevelFee = price * referral2LevelFeePercent / 1 ether;
        return price - protocolFee - subjectFee - referralFee - referral2LevelFee;
    }

    function buyShares(address sharesSubject, address referralAddress, address referral2LevelAddress, uint256 amount, uint256 orderId) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        require(supply > 0 || sharesSubject == msg.sender, "E05 : Only the creator can buy the first share");
        require(referralAddress != msg.sender,"E07 : user can't be referral.");
        require(referral2LevelAddress != msg.sender,"E08 : user can't be 2nd level referral.");

        uint256 price = getPrice(supply, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 referralFee = price * referralFeePercent / 1 ether;
        uint256 referral2LevelFee = price * referral2LevelFeePercent / 1 ether;
        
        require(msg.value == price + protocolFee + subjectFee + referralFee + referral2LevelFee, "E01 - Insufficient balance");
        
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] + amount;
        sharesSupply[sharesSubject] = supply + amount;

        TradeDetail memory td = TradeDetail(amount, price, protocolFee, subjectFee, referralAddress,referralFee,referral2LevelAddress,referral2LevelFee);

        emit Trade(orderId, msg.sender, sharesSubject, true, td,supply + amount);
        (bool success1, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success2, ) = sharesSubject.call{value: subjectFee}("");
        (bool success3, ) = referralAddress.call{value: referralFee}("");
        (bool success4, ) = referral2LevelAddress.call{value: referral2LevelFee}("");
        
        require(success1 && success2 && success3 && success4, "E02 - Fail to transfer the funds");
    }

    function sellShares(address sharesSubject, address referralAddress, address referral2LevelAddress, uint256 amount, uint256 orderId) public payable {
        uint256 supply = sharesSupply[sharesSubject];
        
        if(msg.sender==sharesSubject)
            require(sharesBalance[sharesSubject][msg.sender] > 1, "E06 : Creator cannot sell the last share");

        require(referralAddress != msg.sender,"E07 : user can't be referral.");
        require(referral2LevelAddress != msg.sender,"E08 : user can't be 2nd level referral.");
        
        uint256 price = getPrice(supply - amount, amount);
        uint256 protocolFee = price * protocolFeePercent / 1 ether;
        uint256 subjectFee = price * subjectFeePercent / 1 ether;
        uint256 referralFee = price * referralFeePercent / 1 ether;
        uint256 referral2LevelFee = price * referral2LevelFeePercent / 1 ether;
        
        require(sharesBalance[sharesSubject][msg.sender] >= amount, "E03 - Insufficient shares");
        
        sharesBalance[sharesSubject][msg.sender] = sharesBalance[sharesSubject][msg.sender] - amount;
        sharesSupply[sharesSubject] = supply - amount;

        TradeDetail memory td = TradeDetail(amount, price, protocolFee, subjectFee, referralAddress,referralFee,referral2LevelAddress,referral2LevelFee);

        emit Trade(orderId, msg.sender, sharesSubject, false, td, supply - amount);
        (bool success1, ) = msg.sender.call{value: price - protocolFee - subjectFee - referralFee - referral2LevelFee}("");
        (bool success2, ) = protocolFeeDestination.call{value: protocolFee}("");
        (bool success3, ) = sharesSubject.call{value: subjectFee}("");
        (bool success4, ) = referralAddress.call{value: referralFee}("");
        (bool success5, ) = referral2LevelAddress.call{value: referral2LevelFee}("");
        
        require(success1 && success2 && success3 && success4 && success5, "E02 - Fail to transfer the funds");
    }
}