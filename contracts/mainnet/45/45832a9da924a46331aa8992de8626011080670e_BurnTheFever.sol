/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


interface ERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function burn(address _to, uint256 _amount) external;
    function mint(address _to, uint256 _amount) external;
    function checkBuyBack(uint256 _burnAmount) external;
    function infect(address _toInfect) external;
    function approveMax(address spender) external returns (bool);
}


contract BurnTheFever is Ownable {
    
    ERC20 token;
    IUniswapV2Router02 public router;

    address public AVFAddress;

    uint256 public nbCases = 10;
    uint256 public enterPrice = 40000 ether;    
    uint256 public minAmount = 40000 ether;

    mapping(address => bool) public isUserEnter;
    mapping(address => uint256) public numberChosen;    

    struct oneNumber {
        bool isNumberChosen;
        address whoChoseNumber;
        bool haveLost;
    }

    mapping(uint256 => oneNumber) public AllNumber;

    bool public isGameOpen;

    uint256 public timeLastGame;
    uint256 public percentage = 70; //% of cashprize redistribued to winners
    uint256 public jackpotPercentage = 10;//% of cashprize redistrbued to the player who has the perfect number
    uint256 public teamFees = 15;
    uint256 public burnFees = 5;
    uint256 public delayBetweenGames;

    uint256 public cashprize;
    uint256 numberOfTicket;

    uint256 public numberOfGames;
    uint256 public amountOfTokensPlayed;

    uint256 public amountTokensBurned;

    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    mapping(address => uint256) public numberOfGamePlayedPerUser;
    mapping(address => uint256) public numberOfGameWonPerUser;
    mapping(address => uint256) public numberOfJackpotPerUser;

    mapping(address => uint256) public totalRewards;
    
    event enterGame(address indexed user, uint256 number);
    event gameFinished(uint256 numberOfPlayers, uint256 cashprize, uint256 cashprizePerPlayer, uint256 jackpot, uint256 number, bool lowOrHigh);
    event result(address indexed user, uint256 _result);

    constructor (ERC20 _token) {
        token = _token;
        AVFAddress = address(_token);
        router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        bool temp;
        temp = token.approveMax(address(this));
    }

    function play(uint256 number) external payable {
        require(token.balanceOf(msg.sender) >= minAmount, "Balance of $AFV too low");
        require(!AllNumber[number].isNumberChosen, "case already occuped");
        require(!isUserEnter[msg.sender], "Only one enter per address");
        require(number > 0 && number <= nbCases, "Number not valid");
        require(isGameOpen, "Game is closed");
        require((delayBetweenGames + timeLastGame <= block.timestamp) || timeLastGame == 0, "please wait");

        bool tmpSuccess = token.transferFrom(msg.sender, address(this), enterPrice);
        require(tmpSuccess, "transfer failed");

        numberChosen[msg.sender] = number;
        AllNumber[number].whoChoseNumber = msg.sender;

        isUserEnter[msg.sender] = true;
        AllNumber[number].isNumberChosen = true;

        numberOfTicket ++;
        amountOfTokensPlayed += enterPrice;
        cashprize += enterPrice;
        numberOfGamePlayedPerUser[msg.sender] ++;

        emit enterGame(msg.sender, number);

        if(numberOfTicket == nbCases) {
            launchGame(number, numberOfTicket, cashprize);
        }
    }

    function launchGame(uint256 lastPlayer, uint256 numberOfPlayers, uint256 _cashprize) internal {
        uint256 random = _rand(lastPlayer) % numberOfPlayers + 1;
        uint256 _lowOrHigh = _rand(lastPlayer + 1) % 2;
        bool lowOrHigh;
        uint256 numberOfLosers;
        numberOfGames++;
        timeLastGame = block.timestamp;

        if(_lowOrHigh == 1) lowOrHigh = true;

        if(lowOrHigh) {
            for(uint256 i = 1; i <= numberOfPlayers; i++) {
                if(random < i) {
                    AllNumber[i].haveLost = true;
                    numberOfLosers++;
                }
            }
        } else {
            for(uint256 i = 1; i <= numberOfPlayers; i++) {
                if(random > i) {
                    AllNumber[i].haveLost = true;
                    numberOfLosers++;
                }
            }
        }

        sendRewards(numberOfPlayers, numberOfLosers, _cashprize, random, lowOrHigh);
    }

    function sendRewards(uint256 numberOfPlayers, uint256 numberOfLosers, uint256 _cashprize, uint256 random, bool lowOrHigh) internal {


        uint256 _totalRewards = _cashprize / (numberOfPlayers - numberOfLosers);
        uint256 cashprizePerPlayer = _totalRewards * percentage / 100;
        uint256 jackpot = _cashprize * jackpotPercentage / 100;
        uint256 feesForTeam = _cashprize * teamFees / 100;
        uint256 feesForBurn = _cashprize * burnFees / 100;

        bool temp;
        temp = token.transferFrom(address(this), AVFAddress, feesForTeam);
        temp = token.transferFrom(address(this), DEAD, feesForBurn);

        amountTokensBurned  += feesForBurn;

        for(uint256 i = 1; i <= numberOfPlayers; i++) {
            if(!AllNumber[i].haveLost) {
                if(random == i) {
                    numberOfJackpotPerUser[AllNumber[i].whoChoseNumber] ++;
                    temp = token.transferFrom(address(this), AllNumber[i].whoChoseNumber, cashprizePerPlayer + jackpot);
                    totalRewards[AllNumber[i].whoChoseNumber] += cashprizePerPlayer + jackpot;
                    emit result(AllNumber[i].whoChoseNumber, 3);
                } else {
                    temp = token.transferFrom(address(this), AllNumber[i].whoChoseNumber, cashprizePerPlayer);
                    totalRewards[AllNumber[i].whoChoseNumber] += cashprizePerPlayer;
                    emit result(AllNumber[i].whoChoseNumber, 2);
                }
                numberOfGameWonPerUser[AllNumber[i].whoChoseNumber] ++;
            } else {
                emit result(AllNumber[i].whoChoseNumber, 1);
            }
        }

        emit gameFinished(numberOfPlayers, _cashprize, cashprizePerPlayer, jackpot, random, lowOrHigh);

        deleteMapping();
    }

    function deleteMapping() internal {

        for(uint256 i = 1; i <= nbCases; i++) {
            delete isUserEnter[AllNumber[i].whoChoseNumber];
            delete numberChosen[AllNumber[i].whoChoseNumber];
            delete AllNumber[i];
        }

        delete numberOfTicket;
        delete cashprize; 
    }

    function setPrice (uint256 _enterPrice) external onlyOwner {
        enterPrice = _enterPrice;
    }

    function setMinBalance(uint256 _minAmount) external onlyOwner {
        minAmount = _minAmount;
    }

    function setRepartition(uint256 _percentage, uint256 _jackpotPercentage, uint256 _teamFees, uint256 _burnFees) external onlyOwner {
        percentage = _percentage;
        jackpotPercentage = _jackpotPercentage;
        teamFees = _teamFees;
        burnFees = _burnFees;
    }

    function OwnerDeleteMapping () external onlyOwner {
        deleteMapping();
    }

    function setAmountOfCases(uint256 amountOfCases) external onlyOwner {
        nbCases = amountOfCases;
    }

    function setDelayBetweenGames(uint256 _delayBetweenGames) external onlyOwner {
        delayBetweenGames = _delayBetweenGames;
    }

    function setIsGameOpen(bool _isGameOpen) external onlyOwner {
        isGameOpen = _isGameOpen;
    }

    function transferBlockedTokens() external onlyOwner {
        bool temp;
        temp = token.transferFrom(address(this), msg.sender, token.balanceOf(address(this)));
    }

    function _rand(uint256 _seed) internal view returns (uint256) {
        require(tx.origin == msg.sender, "Only EOA");
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 4),
                        blockhash(block.number - 1),
                        tx.origin,
                        blockhash(block.number - 2),
                        _seed,
                        blockhash(block.number - 3),
                        block.timestamp
                    )
                )
            );
    }
}