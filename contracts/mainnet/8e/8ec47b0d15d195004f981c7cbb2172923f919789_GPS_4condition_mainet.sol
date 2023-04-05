/**
 *Submitted for verification at Arbiscan on 2023-04-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract GPS_4condition_mainet {

    address public nullAdd = 0x0000000000000000000000000000000000000000;
    address public _manager;
    mapping (address => address) _sender; // address reciever ==> address sender
    mapping (address => address) _reciever; // address sender ==> address reciever
    mapping(address => uint) _balance;
    mapping (address => int256) _lat;
    mapping (address => int256) _long;
    mapping (address => uint) _status;

    event Create(
        address sender,
        address indexed reciever,
        int256 indexed lat,
        int256 indexed long,
        uint balance);
    
    event Verify(
        address indexed sender,
        address indexed reciever,
        uint balance);


    constructor() {
        _manager = msg.sender;
    }

    // create condition contract

    function createCondition (address reciever , int256 lat , int256 long) public payable{
        require(_balance[msg.sender] == 0, "Your Already Create Conditiob Payment , Please Try Again with another Wallet Address");
        require(msg.value>0 , "Amount must > 0 !!!");
        _sender[reciever] = msg.sender ;
        _reciever[msg.sender] = reciever;
        _lat[msg.sender] = lat;
        _long[msg.sender] = long;
        _balance[msg.sender] = msg.value;
        emit Create(msg.sender,reciever,lat,long,msg.value);
    }

    //Function for check balance in contract
    function checkInfoBySender(address sender) public view returns(address reciever ,uint balance){
        return(_reciever[sender] , _balance[sender]);
    }

    // Function check receiver claimable
    function checkInfoByReceiver(address receiver) public view returns(uint balance){
        return(_balance[_sender[receiver]]);
    }

    //Chenck Lat-Long Just for check !!!
    function checklatlong(address sender) public view returns(int256 lat,int256 long)
    {
        return(_lat[sender],_long[sender]);
    }

    //Chenck sender Just for check !!!
    function checkSender (address reciever) public view returns(address sender)
    {
        return(_sender[reciever]);
    }

    // Check lat, long
    function check(int256 a , int256 b) public pure returns (bool result) {
        int256 difference = a -b;
        int256 difference_1 = difference >= 0 ? difference : -difference;
        return difference_1 < 2;
        }  

    //Function Check and transfer
    function verifyAndPay(int256 lat, int256 long) public returns (string memory response) {
        require(_sender[msg.sender] != nullAdd,"Unauthorized");
        address senderAdd = _sender[msg.sender];
        if (check(lat,_lat[senderAdd])){
            if (check(long,_long[senderAdd]))
            {
                emit Verify(senderAdd,msg.sender,_balance[senderAdd]);
                payable(msg.sender).transfer(_balance[senderAdd]);
                _balance[senderAdd] = 0;
                _lat[senderAdd] = 0;
                _long[senderAdd] = 0;
                _status[senderAdd] = 0;
                _reciever[senderAdd] = nullAdd;
                _status[msg.sender] = 0;

                _sender[msg.sender] = nullAdd; 
                return("Thanks You");           
            }
            return("Not Verify");
        }
        return("Not Verify");
    }

    function cancleByManager(address reciever) public{
        require(msg.sender == _manager, "You are Not manager");
        address senderAdd = _sender[reciever];

        payable(_sender[reciever]).transfer(_balance[senderAdd]);
        _balance[senderAdd] = 0;
        _lat[senderAdd] = 0;
        _long[senderAdd] = 0;
        _status[senderAdd] = 0;
        _reciever[senderAdd] = nullAdd;
        _status[msg.sender] = 0;
        _sender[msg.sender] = nullAdd;
    }
}