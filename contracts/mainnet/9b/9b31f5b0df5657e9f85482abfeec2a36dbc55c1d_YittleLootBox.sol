/**
 *Submitted for verification at Arbiscan.io on 2024-01-15
*/

// SPDX-License-Identifier: MIT
// Create by 0xYittle
// Lootbox demo
// ระบบทุกอย่างน่าจะใช้งานได้แล้ว แต่ต้องปรับวิธีการ Random ให้มันเป็นนอกเชน ไม่งั้นจะสามารถ reverse ระบบได้

pragma solidity ^0.8.0;

contract YittleLootBox {

    event Won(uint256 indexed Game, uint256 indexed Round, uint256 [] PlayerRandom , uint256 [] GameRandom, address [] attens, uint256 prize, address winner );
    event Lost(uint256 indexed Game, uint256 indexed Round, uint256 [] PlayerRandom , uint256 [] GameRandom, address [] attens, uint256 currentPrize );

    address public OWNER;
    address _winner = address(this);

    uint256 public game = 1 ; // เกมที่เท่าไหร่
    uint256 public round = 1 ; // ในเกมที่ 1 เป็นรอบที่เท่าไหร่ที่คนเล่น

    uint256 public playFees = 0.005 ether; // ค่าธรรมเนียมการเล่นต่อครั้ง

    address[] public attendees ; // รายชื่อผู้เข้าร่วมทั้งหมด
    uint256[] public ThisGamesRandom; // ประวัติตัวเลขของ "เกม" ที่ถูกสุ่มในเกมนี้ทั้งหมด
    uint256[] public ThisPlayersRandom; // ประวัติตัวเลขของ "ผู้เข้าร่วม" ที่ถูกสุ่มในเกมนี้ทั้งหมด

    struct Account {
        uint256 Balance ; // player winner balance to withdraw
    }

    mapping(address => Account) public _account ;

    struct Treasure {
        uint256 Fees ; // Platform fees
        uint256 Bonus ; // Bonus for Next Round
        uint256 RewardPool ; // Reward for this round
    }

    Treasure public treasure ;

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier onlyOwner() {
        require(OWNER == msg.sender, "You're not the owner");
        _;
    }

    constructor() {
        OWNER = msg.sender ;
    }


    function play() public payable {
        // จ่ายเงินเข้าร่วม
        require( playFees <= msg.value, "Insufficient funds");

        // สุ่มตัวเลขของผู้เข้าร่วม
        uint256 MainRandom = MainRandomizer(); // MainRandomizer
        // สุ่มตัวเลขของระบบ
        uint256 PlayerRandom = PlayerRandonizer(); // PlayerRandonizer

        // เก็ยเงินเข้าระบบ
        treasure.Fees += playFees*5/100 ;
        treasure.Bonus += playFees*10/100 ;
        treasure.RewardPool += playFees*85/100 ;

        // เช็คว่าชนะมั้ย
        if(MainRandom == PlayerRandom) {
            // ถ้าชนะได้รับรางวัล

                // เพิ่มเงินให้กับ Player
                _account[msg.sender].Balance += treasure.RewardPool ;

                // เรียก withdrawPlayer() เพื่อถอนเงินให้กับผู้ชนะ
                withdrawPlayer();
                withdrawFees();

                // EMIT
                attendees.push(msg.sender);
                ThisGamesRandom.push(MainRandom);
                ThisPlayersRandom.push(PlayerRandom);
                emit Won(game, round, ThisGamesRandom, ThisPlayersRandom, attendees, treasure.RewardPool, msg.sender);
                
                //เริ่มต้นใหม่ รีเซ็ทเกม

                    //ล้าง attendees array
                    delete attendees ;
                    delete ThisGamesRandom ;
                    delete ThisPlayersRandom ;

                    // ล้าง RewardPool
                    treasure.RewardPool = 0 ;

                    // นับว่าเป็นเกมถัดไป
                    round = 1 ;
                    game += 1 ;

        } else {

            // ถ้าแพ้ไม่ได้ะไร

                // เพิ่มรายชื่อเข้าไปใน array attendees
                attendees.push(msg.sender);
                ThisGamesRandom.push(MainRandom);
                ThisPlayersRandom.push(PlayerRandom);

                //withdrawFees
                withdrawFees();

                // EMIT
                emit Lost(game, round, ThisGamesRandom, ThisPlayersRandom, attendees, treasure.RewardPool);

                // นับว่าเป็นรอบถัดไป
                round += 1; 
    
        }
                    
    }

// ~~~~~~~~~~~ Start View Zone ~~~~~~~~~~~~

    function checkAttened() public view returns (address [] memory) {
        return attendees ;
    }  // รายชื่อผู้เข้าร่วมแบบ Array

    function checkAttenedNumber() public view returns (uint256) {
        return attendees.length ;
    }  // จำนวนผู้เข้าร่วมทั้งหมด

    function checkGamesNumber() public view returns (uint256 [] memory) {
        return ThisGamesRandom ;
    } // รายการตัวเลขของ Game ที่ถูกสุ่มไปแล้วทั้งหมด ในเกมนี้ แบบ Array

    function checkPlayersNumber() public view returns (uint256 [] memory) {
        return ThisPlayersRandom  ;
    } // รายการตัวเลขของ Player ที่ถูกสุ่มไปแล้วทั้งหมด ในเกมนี้ แบบ Array

    function PlayerRandonizer() internal view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.timestamp ,msg.sender, block.number)));
        return randomHash % 10;
    }  // โปรแกรมสุ่มเลขสำหรับ Player

    function MainRandomizer() internal view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(attendees,block.timestamp,msg.sender)));
        return randomHash % 10;
    } // โปรแกรมสุ่มเลขสำหรับ Game/Main

// ~~~~~~~~~~~ End View Zone ~~~~~~~~~~~~
// ~~~~~~~~~~~ Start Player Zone ~~~~~~~~~~~~

    function withdrawPlayer() public payable { 

        uint256 _pay = _account[msg.sender].Balance ;

        require(address(this).balance > 0, "No ETH left");
        require(_account[msg.sender].Balance > 0, "No ETH left");

        require(payable(msg.sender).send(_pay));

        _account[msg.sender].Balance = 0;

    }

    function withdrawFees() public payable { 

        uint256 _pay = treasure.Fees ;

        require(address(this).balance > 0, "No ETH left");
        require(treasure.Fees > 0, "No ETH left");

        require(payable(OWNER).send(_pay));

        treasure.Fees = 0;


    }

// ~~~~~~~~~~~ End Player Zone ~~~~~~~~~~~~
// ~~~~~~~~~~~ Start BONUS Zone ~~~~~~~~~~~~

    function addBonus() public payable {
        require( playFees <= msg.value, "Insufficient funds");

        treasure.Bonus += msg.value ;
    }
    
// ~~~~~~~~~~~ End BONUS Zone ~~~~~~~~~~~~

    function transferOwnership(address newOwner) public onlyOwner {
        OWNER = newOwner ;
    }

//!!!!!!! start - TEST ZONE, DELETE LATER !!!!!!!!!!!!!!!!!!
    // function withdrawBonus() public payable onlyOwner { 

    //     uint256 _pay = treasure.Bonus ;

    //     require(address(this).balance > 0, "No ETH left");
    //     require(treasure.Bonus > 0, "No ETH left");

    //     require(payable(OWNER).send(_pay));

    //     treasure.Bonus = 0;


    // }
    // ความจริงน่าจะไม่ได้ใช้ เพราะไม่ควรถอนโบนัสได้

    function emergencyWithdraw() public payable onlyOwner {
        require(address(this).balance > 0, "No ETH left");

        uint256 _pay= address(this).balance;
        
        require(payable(OWNER).send(_pay));

        treasure.Fees = 0;
        treasure.Bonus = 0;
        treasure.RewardPool = 0;


    }
    // ความจริงน่าจะไม่ได้ใช้ เพราะเจ้าของไม่ควรถอนเงินได้

//!!!!!!! end - TEST ZONE, DELETE LATER !!!!!!!!!!!!!!!!!!
    

}