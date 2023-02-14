/**
 *Submitted for verification at Arbiscan on 2023-02-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract GrandFond{
    uint public counter;

    uint256 public bank;

    address public owner;

    struct Grandchild{
        string name;
        uint256 birthday; //https://www.epochconverter.com/
        bool allreadyGotMoney;
        bool exist;
    }
    address[] public arrGrandchilds;

    mapping(address => Grandchild)public grandchilds;

    constructor(){
        owner = msg.sender;
        counter = 0;
    }
    modifier onlyOwner(){
        require(msg.sender == owner, "not owner");
        _;     
    }
    //add grandchild
    function addGrandchild(
        address walletAdd,
        string memory name,
        uint256 birthday
    )public onlyOwner{
        require(birthday > 0, "check birthday");
        require(
            grandchilds[walletAdd].exist == false, 
            "there is already such a grandchild!"
        );
        grandchilds[walletAdd]=(
            Grandchild(name, birthday, false, true)
        );
        arrGrandchilds.push(walletAdd);
        counter++;
       emit NewGrandChild(walletAdd, name, birthday); 
    }

    receive() external payable{
        bank += msg.value;
    }
    function balanceOf()public view returns(uint){
        return address(this).balance;
    }
    function withdraw() public{
        address payable walletAdd = payable(msg.sender);

        require(
            grandchilds[walletAdd].exist == true,
            "there is no such grandchild"
        );
        require(
            block.timestamp > grandchilds[walletAdd].birthday,
            "birthday hasn't arrived yet"
        );
        uint256 amount = bank /counter;
        grandchilds[walletAdd].allreadyGotMoney = true;

        (bool success, ) = walletAdd.call{value: amount}("");
        require(success);

        emit GotMoney(walletAdd);
    }

        function readGrandChildsArray(uint cursor, uint length)public view returns(address[] memory){
            address[] memory array = new address[](length);
            uint counter2 = 0;
            for (uint i = cursor; i < cursor+length; i++){
                array[counter2] = arrGrandchilds[i];
                counter2 ++;
            }
            return array;
        }
       
    event NewGrandChild(address indexed walletAdd, string name, uint256 birthday);
    event GotMoney(address indexed walletAdd);

}