// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "Ownable.sol";

contract BetGame is Ownable {

    ///// Global state variables below /////
    enum Winner { RED, BLUE, DRAW, NA }
    struct Game { // Careful with the struct packing, as Solidity variables store data by 256-bit memory slots
        mapping(address => uint256) betsOnRed;
        mapping(address => uint256) betsOnBlue;
        uint256 totalBetsOnRed;
        uint256 totalBetsOnBlue;
        uint256 startingBet; // Default is 0
        uint8 commissionPercent;
        Winner winner; // Up to 255 values enums take up 8 bits of storage
        bool isBetOpen;
    }
    mapping(bytes32 => Game) public games; // On mapping creation all possible keys exist, and values are initialized to 0/false.
    address public bookmaker; // The current bookmaker of the game
    uint256 public bookmakerGasUnitsLimit; // The bookmaker's transactions gas units limit
    uint256 public bookmakerGasTip; // The bookmaker's transactions gas tip
    uint8 public safetyMultiplier; // A safey net multiplier used in case gas fees go up to much between faraway blocks
    uint8 public commissionPercent; // The bookmaker commission percentage    
    ///// Global state variables above /////

    /**
     * Modifier that requires this user to be the bookmaker
     */
    modifier onlyBookmaker () {
        require(msg.sender == bookmaker, "Not authorized.");
        _;
    }

    /**
     * Called when contract is initially deployed
     */
    constructor() {        
        bookmakerGasUnitsLimit = 100000; // Cover the gas of the 2 bookmaker functions execution per game
        bookmakerGasTip = 10000000000; // 10 gwei
        safetyMultiplier = 2; // Reasonnable safety net
        commissionPercent = 7; // Initial commission is 7%
    }

    /**** Functions below. We order them by usage case (using their MethodID), as the top ordered ones cost less gas than the below ones  ****/
    /**** The Method ID generation rules are as follows: keccack256(Function signature - eg. func(uint256)) and take the first four bytes ****/

    /**
     * @dev Set a game bet open or not status, by the bookmaker
     * @param _gameRef The ref of the game to be updated
     * @param _isBetOpen The bet open status
     */
    function setBetOpenStatus(bytes32 _gameRef, bool _isBetOpen) external onlyBookmaker {
        if (games[_gameRef].isBetOpen != _isBetOpen) {
            games[_gameRef].isBetOpen = _isBetOpen;
        }
    }

    /**
     * @dev Set the winner of a game as well as the final winnings accounting commission (unless game is a Draw), by the bookmaker
     * @param _gameRef The ref of the game to be updated. Each bytes32 can store up to 32 letters (ASCII), where each character is a byte
     * @param _winner The winner, as 0=red, 1=blue or 2=draw. Note: Less costly with int than string and keccak256(abi.encodePacked(_winner))
     */
    function setWinner(bytes32 _gameRef, uint8 _winner) external onlyBookmaker {
        if (_winner == 0) {     
            games[_gameRef].winner = Winner.RED;
        }
        else if (_winner == 1) {
            games[_gameRef].winner = Winner.BLUE;
        }
        else if (_winner == 2) {
            games[_gameRef].winner = Winner.DRAW;
        }
        else {
            games[_gameRef].winner = Winner.NA;
        }
    }

    /**
     * @dev Gets the current gas cost of bookmaker functions. Note: 'view' reads from state but does not modify, therefore costs no gas
     * @return uint256 Current gas cost
     */
    function getGasCost() public view returns (uint256) {
        // Gas formula after London upgrade: gas units (limit) x (base fee + tip). Eg. 21,000 x (100 + 10) = 2,310,000 gwei, or 0.00231 ETH.
        return (bookmakerGasUnitsLimit * ((block.basefee * 2) + bookmakerGasTip)); // Ideally, tx should be valid even after 6 blocks 
    }

    /**
     * @dev Create a new game. Note: private can only be used from inside that contract (not even from children contracts)
     * @param _gameRef The ref of the game to be created
     * @param _startingBet The initial bet minimum amount
     */
    function _createGame(bytes32 _gameRef, uint256 _startingBet) private {
        Game storage newGame = games[_gameRef];
        newGame.totalBetsOnRed = 0;
        newGame.totalBetsOnBlue = 0;
        newGame.startingBet = _startingBet;
        newGame.commissionPercent = commissionPercent;
        newGame.winner = Winner.NA;
        newGame.isBetOpen = true;
    }

    /**
     * @dev Place a bet by calling that function and pay money (payable) to the contract at the same time
     * @param _gameRef The ref of the game being bet on 
     * @param _side Which side is bet on, as 0=red, 1=blue
     * @param _startingBet The initial, mininum bet amount
     */
    function placeNewBet(bytes32 _gameRef, uint8 _side, uint256 _startingBet) external payable {
        // msg.value contains the amount of wei (ether / 1e18) sent in the transaction.
        require(msg.value > getGasCost() * safetyMultiplier, "Not enough sent."); // Ensure that safe minimum ether was sent, else revert
        if (games[_gameRef].startingBet == 0) { // Create this game if it doesn't already exist
            require(_startingBet > getGasCost() * safetyMultiplier, "Starting bet too low.");
            _createGame(_gameRef, _startingBet);
        }
        else if (!games[_gameRef].isBetOpen) {  // Only when bets are still open, else revert transaction
            revert("Bets are closed.");
        }
        if (_side == 0) {     
            games[_gameRef].betsOnRed[msg.sender] += msg.value; // Update the red betters mapping
            games[_gameRef].totalBetsOnRed += msg.value; // Update the total bets amount on red
        }
        else if (_side == 1) {
            games[_gameRef].betsOnBlue[msg.sender] += msg.value;
            games[_gameRef].totalBetsOnBlue += msg.value;
        }
        else revert("Illegal operation."); // Revert transaction if not red or blue passed in params
    }

    /**
     * @dev Define a new bookmaker - only the contract owner can do this. Note: external function improves performance and saves on gas vs public
     * @param _bookMaker The public address of the new bookmaker
     */
    function setNewBookmaker(address _bookMaker) external onlyOwner {
        bookmaker = _bookMaker;
    }

    /**
     * @dev Returns how many digits in a number digits. Note: Pure function declares that no state variable will be changed or read
     * @param _number The number to be analysed
     * @return uint8 digits 
     */
    function _getDigitsIn(uint256 _number) private pure returns (uint8) {
        uint8 digits = 0;
        while (_number != 0) {
            _number /= 10;
            digits++;
        }
        return digits;
    }

    /**
     * @dev Gets the amount for bookmaker before a withdrawal, including commission and gas costs
     * @param _amount The amount to be recalculated
     * @param _commissionPercent The commission percent to use for calculation     
     * @return uint256 Final, minored amount  
     */
    function _getBookmakerSplit(uint256 _amount, uint8 _commissionPercent) private view returns (uint256) {
        // Note: division rounds down to the nearest integer
        return (((_amount * _commissionPercent) / 100) + getGasCost());
    }

    /**
     * @dev In case something goes wrong, allow betters to withdraw their stake from a game that is not won yet
     * @param _gameRef The ref of the game to allow panic withdraw from
     */
    function allowPanicCancelOut(bytes32 _gameRef) external onlyOwner {
        if (!games[_gameRef].isBetOpen) {
            games[_gameRef].isBetOpen = true; // Reopen bets if needs be
        }
        if ((games[_gameRef].totalBetsOnRed >= games[_gameRef].startingBet) || (games[_gameRef].totalBetsOnBlue >= games[_gameRef].startingBet)) {
            games[_gameRef].startingBet = games[_gameRef].totalBetsOnRed + games[_gameRef].totalBetsOnBlue; // Make startingBet large enough
        }
    }

    /**
     * @dev Set the gas costs for all the transactions done by the bookmaker in a given game
     * @param _gasUnitsLimit The new gas limit
     * @param _gasTip The new gas tip to cover the gas of the bookmaker functions execution per game
     * @param _safetyMultiplier The new gas cost safetyMultiplier for bets
     * @param _commissionPercent The new commission percentage, as in 0 to 100
     */
    function setBookmakerFeeElements(uint256 _gasUnitsLimit, uint256 _gasTip, uint8 _safetyMultiplier, uint8 _commissionPercent) external onlyOwner {
        bookmakerGasUnitsLimit = _gasUnitsLimit;
        bookmakerGasTip = _gasTip;
        safetyMultiplier = _safetyMultiplier;
        commissionPercent = _commissionPercent;
    }

    /**
     * @dev Allow a winner to withdraw their payout
     * @param _gameRef The ref of the game to withdraw from
     */
    function withdrawGamePayout(bytes32 _gameRef) external {
        require(!games[_gameRef].isBetOpen, "Cannot withdraw at that point."); // Bets must be closed
        if (games[_gameRef].winner == Winner.RED) {
            require(games[_gameRef].betsOnRed[msg.sender] > 0, "Denied."); // Caller must be a red winner that hasn't pulled out his winnings yet
            uint256 q = 10 ** _getDigitsIn(games[_gameRef].totalBetsOnRed); // So we can account for decimals
            // Get that winner's winnings depending on their participation ratio
            uint256 winnings = (games[_gameRef].totalBetsOnBlue * ((games[_gameRef].betsOnRed[msg.sender] * q) / games[_gameRef].totalBetsOnRed)) / q;
            uint256 amountForBookmaker = _getBookmakerSplit(winnings, games[_gameRef].commissionPercent); // Bookmaker gets % of winnings
            if (amountForBookmaker > games[_gameRef].betsOnRed[msg.sender] + winnings) {
                amountForBookmaker = 0; // Rare case if gas cost has upped too much between now and then blocks, and winner amount can't cover it
            }
            uint256 amountForBetter = games[_gameRef].betsOnRed[msg.sender] + winnings - amountForBookmaker;
            // Update contract game data to reflect that winner's withdrawal
            games[_gameRef].totalBetsOnRed -= games[_gameRef].betsOnRed[msg.sender];
            games[_gameRef].betsOnRed[msg.sender] = 0;
            games[_gameRef].totalBetsOnBlue -= winnings;
            payable(bookmaker).transfer(amountForBookmaker); // Send due to bookmaker (address needs to be of type payable here)
            payable(msg.sender).transfer(amountForBetter);
        }
        else if (games[_gameRef].winner == Winner.BLUE) {
            require(games[_gameRef].betsOnBlue[msg.sender] > 0, "Denied.");
            uint256 q = 10 ** _getDigitsIn(games[_gameRef].totalBetsOnBlue); 
            uint256 winnings = (games[_gameRef].totalBetsOnRed * ((games[_gameRef].betsOnBlue[msg.sender] * q) / games[_gameRef].totalBetsOnBlue)) / q;
            uint256 amountForBookmaker = _getBookmakerSplit(winnings, games[_gameRef].commissionPercent);
            if (amountForBookmaker > games[_gameRef].betsOnBlue[msg.sender] + winnings) {
                amountForBookmaker = 0;
            }
            uint256 amountForBetter = games[_gameRef].betsOnBlue[msg.sender] + winnings - amountForBookmaker;
            games[_gameRef].totalBetsOnBlue -= games[_gameRef].betsOnBlue[msg.sender];
            games[_gameRef].betsOnBlue[msg.sender] = 0;
            games[_gameRef].totalBetsOnRed -= winnings;
            payable(bookmaker).transfer(amountForBookmaker);
            payable(msg.sender).transfer(amountForBetter);
        }
        else if (games[_gameRef].winner == Winner.DRAW) {
            require ((games[_gameRef].betsOnBlue[msg.sender] > 0) || (games[_gameRef].betsOnRed[msg.sender] > 0), "Denied.");
            uint256 amount = 0;
            if (games[_gameRef].betsOnRed[msg.sender] > 0) { // Case bet on red
                amount = games[_gameRef].betsOnRed[msg.sender];
                games[_gameRef].totalBetsOnRed -= games[_gameRef].betsOnRed[msg.sender];
                games[_gameRef].betsOnRed[msg.sender] = 0; 
            }
            if (games[_gameRef].betsOnBlue[msg.sender] > 0) { // Case bet on blue
                amount += games[_gameRef].betsOnBlue[msg.sender];
                games[_gameRef].totalBetsOnBlue -= games[_gameRef].betsOnBlue[msg.sender];
                games[_gameRef].betsOnBlue[msg.sender] = 0;
            }
            if (amount > 0) {
                payable(msg.sender).transfer(amount);
            }
        }
        else revert("Impossible."); // No winner or draw
    }

    /**
     * @dev Allow a better to cancel and refund their bet, as long as opposite starting bet amount has not yet been filled
     * @param _gameRef The ref of the game to cancel bet from
     * @param _side Which side to cancel and withdraw bet from, as 0=red, 1=blue 
     */
    function cancelBet(bytes32 _gameRef, uint8 _side) external {
        require(games[_gameRef].isBetOpen, "Cannot cancel bet at that point."); // Bets must be still opened
        require(games[_gameRef].winner == Winner.NA, "Cannot cancel bet at that point."); // There must also be no winner yet
        if (_side == 0) {  
            require(games[_gameRef].totalBetsOnBlue < games[_gameRef].startingBet, "Cannot cancel bet at that point."); // Opposite bet be unreached
            require(games[_gameRef].betsOnRed[msg.sender] > 0, "No bet placed here."); // Sender must have a bet placed on that side
            uint256 amount = games[_gameRef].betsOnRed[msg.sender];
            games[_gameRef].totalBetsOnRed -= amount;
            games[_gameRef].betsOnRed[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
        else if (_side == 1) {
            require(games[_gameRef].totalBetsOnRed < games[_gameRef].startingBet, "Cannot cancel bet at that point.");
            require(games[_gameRef].betsOnBlue[msg.sender] > 0, "No bet placed here.");
            uint256 amount = games[_gameRef].betsOnBlue[msg.sender];
            games[_gameRef].totalBetsOnBlue -= amount;
            games[_gameRef].betsOnBlue[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
        else revert("Illegal operation."); // Revert transaction if not red or blue passed in params
    }

    /**
     * @dev Returns information on a given game for a given sender user
     * @param _gameRef The ref of the game enquired
     * @return uint256 totalBetsOnRed 
     * @return uint256 totalBetsOnBlue
     * @return uint256 betsOnRed of sender 
     * @return uint256 betsOnBlue of sender 
     * @return uint256 startingBet 
     * @return Winner winner 
     * @return bool isBetOpen 
     */
    function getSenderGameStat(bytes32 _gameRef) external view returns (uint256, uint256, uint256, uint256, uint256, Winner, bool) {
        return (games[_gameRef].totalBetsOnRed, games[_gameRef].totalBetsOnBlue, games[_gameRef].betsOnRed[msg.sender], 
            games[_gameRef].betsOnBlue[msg.sender], games[_gameRef].startingBet, games[_gameRef].winner, games[_gameRef].isBetOpen);
    }

}