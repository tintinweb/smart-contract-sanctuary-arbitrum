//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ArrayUint.sol";

contract ReceiveArbitrimEth {
    address public owner;
    uint256 public allIndexListCounter = 0; 
    mapping (address => uint256[]) allAddressIndexList; 

    struct IndexToState{
        bool isSend;
        bool isBack; 
        uint256 receiveAmount; 
        address senderAddress;
        uint256 sendGoerliEthAmount;
        string doneHash;
    }

    mapping (uint256 => IndexToState) public allIndexStateList; 
    
    uint256[] notPayIndexList; 
    uint256[1] notPayIndexListLens; 

    uint256 public price = 100;

    event ReceivedNew(address sender,uint256 amount,uint256 index);
    event PayGoerliEth(address to,uint256 amount,string _hash);
    event BackArbitrumEth(address to,uint256 amount);
    event BackArbitrumEthHash(address to,string _hash);
    event SetPrice(uint256 _price);

    constructor(){
        owner = msg.sender;
        notPayIndexListLens[0] = 0; 

    }


    fallback() payable external{
        whenReceiveEth();
    }

    receive() payable external{
        whenReceiveEth();
    }

    function whenReceiveEth() public payable{
        require(msg.value >= 0.001 ether,"Send at least 0.001 ether");
        allIndexStateList[allIndexListCounter] = IndexToState(
            false,
            false,
            msg.value,
            msg.sender,
            0,
            ""
        );
        ArrayUint.addArrayNewValue(notPayIndexList, notPayIndexListLens, allIndexListCounter);
        allAddressIndexList[msg.sender].push(allIndexListCounter);
        allIndexListCounter += 1;
        emit ReceivedNew(msg.sender, msg.value, allIndexListCounter - 1);
    }


    modifier _isOwner(){
        require(msg.sender == owner,"Not Owner.");
        _;
    }

    modifier _isIndexTooLarge(uint256 _index){
        require(_index < allIndexListCounter,"_index is too large.");
        _;
    }

    function payGoerliEth(uint256 _index,uint256 _payAmount,string memory _hash) public _isOwner _isIndexTooLarge(_index){
        require(allIndexStateList[_index].isBack == false,"Had backed yet.");
        ArrayUint.removeArrayByValue(notPayIndexList, notPayIndexListLens, _index);
        allIndexStateList[_index].isSend = true;
        allIndexStateList[_index].sendGoerliEthAmount = _payAmount;
        allIndexStateList[_index].doneHash = _hash;
        emit PayGoerliEth(allIndexStateList[_index].senderAddress,_payAmount,_hash);
    }

    function backArbitrumEth(uint256 _index) public _isOwner _isIndexTooLarge(_index){
        require( allIndexStateList[_index].isSend == false,"Had payed yet.");
        uint256 amount = allIndexStateList[_index].receiveAmount;
        amount = amount - 500000000000000;
        ArrayUint.removeArrayByValue(notPayIndexList, notPayIndexListLens, _index);
        allIndexStateList[_index].isBack = true;
        allIndexStateList[_index].sendGoerliEthAmount = 0;
        payable(allIndexStateList[_index].senderAddress).transfer(amount);
        emit BackArbitrumEth(allIndexStateList[_index].senderAddress,amount);
    }

    function backArbitrumEthHash(uint256 _index,string memory _hash) public _isOwner _isIndexTooLarge(_index){
        require( allIndexStateList[_index].isBack == true,"Don not back yet.");
        allIndexStateList[_index].doneHash = _hash;
        emit BackArbitrumEthHash(allIndexStateList[_index].senderAddress,_hash);
    }

    function setPrice(uint256 _price) public _isOwner{
        if(_price > 0 && _price <= 10000){
            price = _price;
            emit SetPrice(_price);
        }
    }

    function WithDrawAllEth() external _isOwner{
        payable(owner).transfer(address(this).balance);
    }

    function WithDrawEth(uint256 _a) external _isOwner{
        if(address(this).balance >= _a){
            payable(owner).transfer(_a);
        }
    }

    function getNotPayList() public view returns(uint256[] memory noPay){
        noPay = new uint256[](notPayIndexListLens[0]);
        for(uint256 i = 0;i < notPayIndexListLens[0];i++){
            noPay[i] = notPayIndexList[i];
        }
    }

    function getOneIndexAllState(uint256 _index) public view _isIndexTooLarge(_index) returns(IndexToState memory){
        return allIndexStateList[_index];
    }

    //1,had send goerli eth;2,had back arb eth;0,hadn't done.
    function getOneIndexState(uint256 _index) public view _isIndexTooLarge(_index) returns(uint256){
        if(allIndexStateList[_index].isSend == true){
            return 1;
        }else{
            if(allIndexStateList[_index].isBack == true){
                return 2;
            }else{
                return 0;
            }
        }
    }

    function getOneIndexDoneHash(uint256 _index) public view _isIndexTooLarge(_index) returns(string memory){
        if(allIndexStateList[_index].isSend == true){
            return string(abi.encodePacked("goerli:",allIndexStateList[_index].doneHash));
        }else{
            if(allIndexStateList[_index].isBack == true){
                return string(abi.encodePacked("arbitrum:",allIndexStateList[_index].doneHash));
            }else{
                return "";
            }
        }
    }

    function getOneIndexSendAmount(uint256 _index) public view _isIndexTooLarge(_index) returns(uint256){
        return allIndexStateList[_index].receiveAmount;
    }

    function getOneIndexReceiveAmount(uint256 _index) public view _isIndexTooLarge(_index) returns(uint256){
        return allIndexStateList[_index].sendGoerliEthAmount;
    }

    function getOneIndexSendAddress(uint256 _index) public view _isIndexTooLarge(_index) returns(address){
        return allIndexStateList[_index].senderAddress;
    }

    function getOneAddressAllIndex(address _a) public view returns(uint256[] memory){
        return allAddressIndexList[_a];
    }

}