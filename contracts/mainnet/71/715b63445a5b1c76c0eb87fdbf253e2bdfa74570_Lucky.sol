/**
 *Submitted for verification at Arbiscan on 2023-07-19
*/

// SPDX-License-Identifier: MIT

// website：https://www.berc20.cash/

//'########::'########:'########:::'######:::'#######::::'#####:::
//##.... ##: ##.....:: ##.... ##:'##... ##:'##.... ##::'##.. ##::
//##:::: ##: ##::::::: ##:::: ##: ##:::..::..::::: ##:'##:::: ##:
//########:: ######::: ########:: ##::::::::'#######:: ##:::: ##:
//##.... ##: ##...:::: ##.. ##::: ##:::::::'##:::::::: ##:::: ##:
//##:::: ##: ##::::::: ##::. ##:: ##::: ##: ##::::::::. ##:: ##::
//########:: ########: ##:::. ##:. ######:: #########::. #####:::
//........:::........::..:::::..:::......:::.........::::.....::::
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lucky is Ownable {

    struct LuckyRound {
        uint256 round;
        uint256 luckyCounts;
        address tokenAddress;
        uint256 totalAmounts;
        address winner;
        uint256 startTime;
        bool ended;
    }

    uint256 private nonce;

    LuckyRound[] public luckyRounds;
    uint256 public currentRound; 
    uint256 public luckyMinAmount=100000000000000000000;

    address public bercAddress = 0xbC8E35221904F61b4200Ca44a08e4daC387Ac83A;
    address public devAddress = 0x26F24d1EeC2Cc9454e174803E44a7627E318aE09;
    address public blackAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 public winnerPer=60;
    uint256 public devPer=10;
    uint256 public blackAdsPer=10;
    uint256 public nextRundPer=20;

    uint256 private lastRandomNumber;

    mapping(uint256 => address[]) public roundParticipants;
    uint256 public maxLuckyCounts=100;

    event LotteryStarted(uint256 round, uint256 requiredTokens, uint256 winningNumber);
    event LotteryEnded(uint256 round, address winner, uint256 winningNumber, uint256 tokensWon);

    constructor() {
        currentRound = 1;
        luckyRounds.push(LuckyRound(currentRound,maxLuckyCounts,bercAddress, 0, address(0),block.timestamp, false));
    }

    function lucky(uint256 count,uint randm) external {
        require(count > 0, "Count must be greater than zero.");
        IERC20 token = IERC20(bercAddress);
        require(token.transferFrom(msg.sender, address(this), count*luckyMinAmount), "Insufficient balance $berc!");
        LuckyRound storage currentLuncky = luckyRounds[currentRound - 1];
        if (currentLuncky.ended) {
            currentRound++;
            currentLuncky = luckyRounds[currentRound-1];
        }
        currentLuncky.totalAmounts += count*luckyMinAmount;
        for (uint256 i = 0; i < count; i++) {
            roundParticipants[currentLuncky.round].push(msg.sender); 
        }
        if(roundParticipants[currentLuncky.round].length>maxLuckyCounts){
            uint256 lunckyNumber = random(roundParticipants[currentLuncky.round].length,msg.sender,randm);
            address lunckyAddress = roundParticipants[currentLuncky.round][lunckyNumber];

            currentLuncky.winner = lunckyAddress;
            currentLuncky.ended = true;

            token.transfer(lunckyAddress, currentLuncky.totalAmounts * winnerPer / 100);
            token.transfer(devAddress, currentLuncky.totalAmounts * devPer / 100);
            token.transfer(blackAddress, currentLuncky.totalAmounts * blackAdsPer / 100);

            currentRound++;
            luckyRounds.push(LuckyRound(currentRound,maxLuckyCounts,bercAddress, currentLuncky.totalAmounts*nextRundPer/100, address(0),block.timestamp, false));
        }
    }

    function addToPrizePool(uint256 amount) external {
        IERC20 token = IERC20(bercAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Failed to transfer funds to the prize pool.");
        LuckyRound storage currentLucky = luckyRounds[currentRound - 1];
        require(!currentLucky.ended, "Cannot add funds to the ended round.");
        currentLucky.totalAmounts += amount;
    }

    function getLastNRounds(uint256 n) public view returns (LuckyRound[] memory) {
        uint256 totalRounds = luckyRounds.length;
        uint256 startIndex = totalRounds > n ? totalRounds - n : 0;
        uint256 resultSize = totalRounds - startIndex;

        LuckyRound[] memory result = new LuckyRound[](resultSize);

        for (uint256 i = 0; i < resultSize; i++) {
            result[resultSize - i - 1] = luckyRounds[startIndex + i];
        }
        return result;
    }

    function getCurrentRound() public view returns (LuckyRound memory) {
        return luckyRounds[currentRound - 1];
    }

    function random(uint number,address ads,uint256 nonce) public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,nonce,block.difficulty,  
            ads))) % number;
    }

    function getLastRandomNumber() public view returns (uint256) {
        return lastRandomNumber;
    }

    function setBercAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        bercAddress = newAddress;
    }

    function setDevAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        devAddress = newAddress;
    }

    function setBlackAddress(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid address");
        blackAddress = newAddress;
    }

    function setWinnerPer(uint256 newWinnerPer) external onlyOwner {
        require(newWinnerPer <= 100, "Invalid percentage");
        winnerPer = newWinnerPer;
    }

    function setNextRundPer(uint256 newNextRundPer) external onlyOwner {
        require(nextRundPer <= 100, "Invalid nextRundPer");
        nextRundPer = newNextRundPer;
    }

    function setDevPer(uint256 newDevPer) external onlyOwner {
        require(newDevPer <= 100, "Invalid percentage");
        devPer = newDevPer;
    }

    function setMaxLuckyCounts(uint256 _maxLuckyCounts) external onlyOwner {
        maxLuckyCounts = _maxLuckyCounts;
    }
    
    function setBlackAdsPer(uint256 newBlackAdsPer) external onlyOwner {
        require(newBlackAdsPer <= 100, "Invalid percentage");
        blackAdsPer = newBlackAdsPer;
    }

    function setLuckyMinAmount(uint256 amount) external onlyOwner{
        luckyMinAmount = amount;
    }

    function getRoundParticipants(uint256 round) public view returns (address[] memory) {
        return roundParticipants[round];
    }

}