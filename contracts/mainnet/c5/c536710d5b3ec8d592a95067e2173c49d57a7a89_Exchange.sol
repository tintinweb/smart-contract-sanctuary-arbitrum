// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ReentrancyGuard.sol";
import "./Address.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract Exchange is Ownable,ReentrancyGuard,MinterRole{

    event ExchangeFinish(ExcahngeInfo exchangeInfo);

    mapping(address => uint256) private boom_balance;

    uint256 private total_eth;

    uint256 private total_boom;

    address private market_address;

    struct ExcahngeInfo{
        address wallet_address;
        uint256 eth_amount;
        uint256 boom_amount;
    }

    function setMarketAddress(address _market_address) public onlyOwner {
        market_address = _market_address;
    }

    function getMarketAddress() public view returns (address) {
        return market_address;
    }

    function getBoomBalance(address wallet_address) public view returns (uint256) {
        return boom_balance[wallet_address];
    }

    function subBoomBalance(address wallet_address,uint256 sub_amount) public onlyMinter{
        require(sub_amount > 0,"sub amount must bigger than zero!");
        require(boom_balance[wallet_address] >= sub_amount,"boom balance is not enough!");
        boom_balance[wallet_address] = SafeMath.sub(boom_balance[wallet_address],sub_amount);
    }


    function exchange() public payable {
        uint256 eth_amount = msg.value;
        require(eth_amount > 0,"eth amount can not be zero!!");
        payable(address(market_address)).transfer(eth_amount);
        total_eth += eth_amount;
        uint256 boom_amount = getBoomAmount(eth_amount);
        total_boom += boom_amount;
        require(total_boom < 10**33,"The number of Boom reaches the upper limit");
        boom_balance[msg.sender] += boom_amount;
        ExcahngeInfo memory exchangeInfo;
        exchangeInfo.wallet_address = msg.sender;
        exchangeInfo.eth_amount = eth_amount;
        exchangeInfo.boom_amount = boom_amount;
        emit ExchangeFinish(exchangeInfo);
    }

     function getTotalBoom() public view returns(uint256){
        return total_boom;
     }

     function getTotalBalance() public view returns(uint256){
        return total_eth;
     }

    function getBoomAmount(uint256 eth_amount) public view returns(uint256){
        uint256 y = 0;
        if(total_boom>=900000 * 10**27){
            y = eth_amount*(10**40)/(25*total_boom - 2*10**34);
        }else if(total_boom>=800000 * 10**27){
            y = eth_amount*(10**39)/(total_boom - 65*10**31);
        }else if(total_boom>=600000 * 10**27){
            y = eth_amount*(10**40)/(4*total_boom - 17*10**32);
        }else if(total_boom>=400000 * 10**27){
            y = eth_amount*(10**40)/(2*total_boom - 5*10**32);
        }else if(total_boom>=200000 * 10**27){
            y = eth_amount*(10**40)/(total_boom - 10**32);
        }else if(total_boom>=73143 * 10**27){
            y = eth_amount*(10**44)/(7489*total_boom - 498*10**33);
        }else if(total_boom>=57143 * 10**27){
            y = eth_amount*(10**44)/(2344*total_boom - 121*10**33);
        }else{
            y = eth_amount*(10**44)/(131*total_boom + 5*10**33);
        }
        uint256 boom_amount_ret = y;
        return boom_amount_ret;
    }

    constructor(address _market_address){
        total_boom = 0;
        market_address = _market_address;
    }
}