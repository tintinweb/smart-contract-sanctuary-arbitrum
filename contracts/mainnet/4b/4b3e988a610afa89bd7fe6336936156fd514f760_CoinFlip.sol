// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Strings.sol";


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}



contract CoinFlip {
    using SafeMath for uint256;
    address public owner;
    uint256 public balance;

    uint256 _ethBetHighLimit;
    uint256 _ethBetLowLimit;
    uint8 _min;
    uint8 _max;

    uint256 _allInvestements;

    uint256 _indexCounter;

    enum Side { Heads, Tails }
    enum Result { Win, Lose }

    struct Game {
        uint256 Id;
        address Player;
        
        uint256 SafeBalance;
    }

    struct Investement {
        address owner;

        uint256 balance;
        int256 revenue;
    }

    mapping(address => uint256) private _currentPlayersToGameIdMap;
    mapping(uint256 => Game) private _idsToGameMap;
    mapping(address => uint256) private _OwnerToIds;

    Investement[] private _investements;

    constructor() {
        owner = msg.sender;
        _min = 1;
        _max = 10;
    }

    event CoinFlipped(address indexed player, Side chosenSide, Side winningSide, Result result);
    event AmountInvested(address indexed investor, uint256 amount);
    event CashOutEvent(uint256 indexed GameId, address indexed Player, uint256 indexed Amount);
    event CashOutInvestEvent(address indexed Player, uint256 indexed Amount);
    event BeforeValueTransferEvent(uint256 indexed GameId, address indexed Player, uint256 indexed Amount);
    event AfterValueTransferEvent(address indexed Player);
    

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier gameExist(){
        require(_currentPlayersToGameIdMap[msg.sender] > 0, "No current game");
        _;
    }

    modifier investExist(){
        require(_OwnerToIds[msg.sender] > 0, "No current investement");
        _;
    }

     /**
     * @dev Modifiers
     */
    modifier IsValidAddr() {
        require(msg.sender != address(0x0), "Address_INV");
        _;
    }

    function changeLimit(uint8 newMax, uint8 newMin) external  onlyOwner {
        _min = newMin;
        _max = newMax;
    }

    function invest() external payable {
        require(msg.value > 0, "Send ETH to invest");

        balance += msg.value;
        _allInvestements += msg.value;
        Investement memory investement;

        if (_OwnerToIds[msg.sender] > 0)
        {
            investement = _investements[_OwnerToIds[msg.sender] - 1];
            investement.balance += msg.value;
            _investements[_OwnerToIds[msg.sender] - 1] = investement;
        }

        if (_OwnerToIds[msg.sender] < 1)
        {
            investement.owner = msg.sender;
            investement.revenue = 0;
            investement.balance += msg.value;
            _investements.push(investement);
            _OwnerToIds[msg.sender] = _investements.length;
        }

        updateBetLimit();
        emit AmountInvested(investement.owner, msg.value);
    }
    
    function updateIvestement(uint256 value, bool positif) private {
        for (uint i =0; i < _investements.length; i++) 
        {
            uint percent = (10**9*_investements[i].balance)/ _allInvestements;

            uint revenue = (value * percent) / 10**9;

            if (positif){
                _investements[i].balance += revenue;
                _investements[i].revenue += int(revenue);
                continue;
            }

            _investements[i].revenue -= int(revenue);
            _investements[i].balance -= revenue;
        }
        if (positif)
            {
                _allInvestements += value;
                return;
            }
        
        _allInvestements -= value;
    }

    function updateBetLimit() private {
        uint max = (balance * _max) / 100;
        if ((balance * _max) & 99 != 0) {
            max += 1;
        }
        _ethBetHighLimit = max;

        uint min = (balance * _min) / 100;
        if ((balance * _min) & 99 != 0) {
            min += 1;
        }
        _ethBetLowLimit = min;
    }

    function GetBetLimit() external view returns (uint min, uint max){
        min = _ethBetLowLimit;
        max = _ethBetHighLimit;
    } 

    function flipCoin(Side side, uint256 amount)  external payable {

        require(amount >= _ethBetLowLimit && amount <= _ethBetHighLimit, "Bet_Limit"); // Ensure bet is within limits
        require(side == Side.Heads || side == Side.Tails, "Invalid side");

        Game memory game;
        uint256 tempId = _currentPlayersToGameIdMap[msg.sender];
        if (tempId == 0){
            game.Player = msg.sender;
            game.Id = ++_indexCounter;
            _currentPlayersToGameIdMap[msg.sender] = game.Id;
            game.SafeBalance = msg.value;

            _idsToGameMap[game.Id] = game;
        }else{
            game = _idsToGameMap[tempId];
            game.SafeBalance += msg.value;
        }

        require(game.SafeBalance >= amount, "You need to send some Ether");


        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % 2;
        Side winningSide = random == 0 ? Side.Heads : Side.Tails;

        Result result;

        if (side == winningSide) {
            result = Result.Win;
            if (balance >= amount) {
                balance -= amount;
                updateIvestement(amount, false);
                game.SafeBalance += amount;
            }
        } else {
            result = Result.Lose;
            balance += amount;
            game.SafeBalance -= amount;
            updateIvestement(amount, true);
        }

        _idsToGameMap[game.Id] = game;

        updateBetLimit();
        emit CoinFlipped(msg.sender, side, winningSide, result);
    }

    function CashOutInvest() IsValidAddr investExist external {

        Investement memory investement = _investements[_OwnerToIds[msg.sender] - 1];
        
        uint256 tempBalance = investement.balance;
        if(address(this).balance >= 0 && address(this).balance < investement.balance) {
            tempBalance = address(this).balance;
        }

        assert(address(this).balance >= tempBalance);
        
        BeforeValueTransferInvest(msg.sender);

        balance -= investement.balance;

        uint twoPercent = (tempBalance * 2) / 100;
        if ((tempBalance * 2) & 99 != 0) {
                twoPercent += 1;
         }

        payable(msg.sender).transfer(tempBalance-twoPercent);
        payable(owner).transfer(twoPercent);

        AfterValueTransferInvest(msg.sender);

        assert(_OwnerToIds[msg.sender] == 0);


        emit CashOutInvestEvent(msg.sender, tempBalance);
    }

    function BeforeValueTransferInvest(address playerAddress) private {
        // Update before transfer to prevent re-entrancy.

        uint256 investId = _OwnerToIds[playerAddress] - 1;
        uint256 tempBalance = _investements[investId].balance;

        _OwnerToIds[playerAddress] = 0;
        delete _investements[investId];

        emit BeforeValueTransferEvent(investId, playerAddress, tempBalance);
    }

    function AfterValueTransferInvest(address playerAddress) private {
        emit AfterValueTransferEvent(playerAddress);
    }

    function CashOut() IsValidAddr external {
        
        require(_currentPlayersToGameIdMap[msg.sender] != 0, "Game_DNE");

        Game memory game = _idsToGameMap[_currentPlayersToGameIdMap[msg.sender]];
        
        uint256 tempBalance = game.SafeBalance;
        if(address(this).balance >= 0 && address(this).balance < game.SafeBalance) {
            tempBalance = address(this).balance;
        }

        assert(address(this).balance >= tempBalance);
        
        BeforeValueTransfer(msg.sender);

        uint twoPercent = (tempBalance * 2) / 100;
        if ((tempBalance * 2) & 99 != 0) {
                twoPercent += 1;
         }

        payable(msg.sender).transfer(tempBalance-twoPercent);
        payable(owner).transfer(twoPercent);

        AfterValueTransfer(msg.sender);

        assert(_currentPlayersToGameIdMap[msg.sender] == 0);

        updateBetLimit();

        emit CashOutEvent(game.Id, msg.sender, tempBalance);
    }

    function BeforeValueTransfer(address playerAddress) private {
        // Update before transfer to prevent re-entrancy.

        uint256 gameId = _idsToGameMap[_currentPlayersToGameIdMap[playerAddress]].Id;
        uint256 tempBalance = _idsToGameMap[_currentPlayersToGameIdMap[playerAddress]].SafeBalance;

        _currentPlayersToGameIdMap[playerAddress] = 0;
        delete _idsToGameMap[gameId];

        emit BeforeValueTransferEvent(gameId, playerAddress, tempBalance);
    }

    function AfterValueTransfer(address playerAddress) private {
        // Ensure transfer happened as expected. If not, update again.

        if(_currentPlayersToGameIdMap[playerAddress] != 0 || _idsToGameMap[_currentPlayersToGameIdMap[playerAddress]].SafeBalance != 0) {
            _currentPlayersToGameIdMap[playerAddress] = 0;
            delete _idsToGameMap[_currentPlayersToGameIdMap[playerAddress]];
        }

        emit AfterValueTransferEvent(playerAddress);
    }

    function getGame() public view gameExist returns(Game memory game) {
        game = _idsToGameMap[_currentPlayersToGameIdMap[msg.sender]];
    }

    function getInvestment() public view investExist returns(Investement memory investment) {
        investment = _investements[_OwnerToIds[msg.sender] - 1];
    }

}