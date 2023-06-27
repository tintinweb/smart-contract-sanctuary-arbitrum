/*
    Roulette contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "SafeMath.sol";
import "INFT.sol";
import "ICasinoTreasury.sol";

contract BetsManager {
    using SafeMath for uint256;

    address public rouletteCA;

    modifier onlyRoulette() {
        require(msg.sender == rouletteCA, "Only roulette"); _;
    }

    constructor(address _rouletteCA, address _casinoTreasury) { 
        rouletteCA = _rouletteCA; 
        casinoTreasury = ICasinoTreasury(_casinoTreasury);
    }

    //region VARIABLES

    // Casino treasury iface
    ICasinoTreasury casinoTreasury;

    // Next bet index
    uint256 public nextBet = 1;

    // Bets
    mapping (uint256 => bet) public bets;

    // User pending bets
    mapping (address => uint256 []) public userPendingBets;

    // User pending bets claim
    mapping (address => uint256 []) public userPendingBetsClaim;

    // Bet amounts enabled, in dollars
    mapping (uint256 => bool) public betsEnabled;
    
    // Custom dollars prizes
    mapping (uint8 => uint256) public customDollarPrizes;
    mapping (uint8 => address) public customNFTPrizes;

    // Roulette prizes chances
    prizeChance [] public prizeChancesOption;

    //endregion

    //region ENUMS

    //region Prizes types

    enum prizeType {
        none,
        x2reward,
        x5reward,
        x10reward,
        freeSpin,               // the tokens you used to bet will be returned to you
        customPrizeDollarAmount,
        NFT
    }

    //endregion

    //region Bets

    enum betType {
        none,
        paid
    }

    enum betState {
        none,
        pending,
        solved,
        claimed,
        cancelled                             // tokens will be returned to user
    }

    struct bet {
        uint256 index;
        address user;
        uint256 betAmount;                    // amount in dollars
        uint8 _type;                          // betType
        uint8 state;                          // betState
        uint8 prizeWon;                       // prizeType
        uint8 customPrizeDollarAmountWonType; // only if customPrizeDollarAmount
        uint8 NFTwonType;                     // only if NFT
    }

    //endregion

    //region Prizes chances

    struct prizeChance {
        uint8 _prizeType;                     // prizeType enum
        uint8 prizeSubtype;                   // customDollarPrizes or customNFTPrizes
        uint256 chanceBase10000;
    }

    //endregion

    //endregion

    //region VIEWS

    function _getBetUser(uint256 betIndex) public view returns(address) { return bets[betIndex].user; }

    function isBetEnabled(uint256 _bet) public view returns (bool) { return betsEnabled[_bet]; }

    function getUserPendingBets(address adr) public view returns(uint256 [] memory) { return userPendingBets[adr]; }

    function getUserPendingBetsClaim(address adr) public view returns(uint256 [] memory) { return userPendingBetsClaim[adr]; }

    function getBetsPendingSolve(uint8 nBets) public view returns(uint256 [] memory) {
        uint256 [] memory result = new uint256 [](nBets);
        uint256 _count = 0;
        for(uint256 _i = nextBet - 1; _i > 0; _i--) {
            if(bets[_i].state == 1) {
                result[_count] = bets[_i].index;
                _count++;
            }
            if(_count >= nBets) {
                break;
            }
        }
        return result;
    }

    //endregion

    //region USER

    // Perform bet (transferences and taxes managed on main contract)
    function _performBet(uint256 betAmount, address adr) public onlyRoulette {
        require(isBetEnabled(betAmount), "That amount is not enabled");

        bets[nextBet] = bet(
            nextBet,
            adr,
            betAmount,
            uint8(betType.paid),
            uint8(betState.pending),
            0,
            0,
            0
        );

        userPendingBets[bets[nextBet].user].push(nextBet);
        nextBet++;
    }

    // Claim bet prize, returns prize in dollars (transferences managed on main contract)
    function _claimBet(uint256 betIndex) public onlyRoulette returns(uint256) {
        require(bets[betIndex].state == uint8(betState.solved), "Bet is still not solved, can not be claimed");
        require(bets[betIndex].state != uint8(betState.claimed), "Bet was already claimed");
        require(bets[betIndex].state != uint8(betState.cancelled), "Bet was cancelled");

        _removeUserPendingBetClaim(betIndex);
        bets[betIndex].state = uint8(betState.claimed);

        // Send the prize
        if(bets[betIndex].prizeWon == uint8(prizeType.none)) {
            // You lost, nothing to do here
            return 0;
        } 
        if(bets[betIndex].prizeWon == uint8(prizeType.x2reward)) {
            // You get your bet amount x2
            return bets[betIndex].betAmount.mul(2);
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.x5reward)) {
            // You get your bet amount x5
            return bets[betIndex].betAmount.mul(5);
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.x10reward)) {
            // You get your bet amount x10
            return bets[betIndex].betAmount.mul(10);
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.freeSpin)) {
            // Just your bet amount returns to you
            return bets[betIndex].betAmount;
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.customPrizeDollarAmount)) {
            // You get a custom dollar amount            
            return customDollarPrizes[bets[betIndex].customPrizeDollarAmountWonType];
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.NFT)) {
            // You get an NFT            
            address adrNFT = customNFTPrizes[bets[betIndex].NFTwonType];
            // Perform NFT mint and transfer
            INFT nftMintIFACE = INFT(adrNFT);
            nftMintIFACE.casinoMint(bets[betIndex].user);
            return 0;
        }

        // Should never reach here
        return 0;
    }    

    // Cancels the bet and returns the money to be returned to the address, only can be called for owner or user (transferences managed on main contract)
    function _cancelBet(uint256 betIndex) public onlyRoulette returns(uint256) {      
        require(bets[betIndex].state == uint8(betState.pending), "Bet is not pending");
        bets[betIndex].state = uint8(betState.cancelled);
        _removeUserPendingBet(betIndex);
        return bets[betIndex].betAmount;
    }

    //endregion

    //region BET SOLVER
    
    // Simulates an spin and returns the prize type won and subtype
    function _simulateSpin(uint256 randomBase10000) public view returns(uint8, uint8) {
        uint256 acum = 0;

        for(uint256 _i = 0; _i < prizeChancesOption.length; _i++) {
            uint256 previousAcum = acum;
            acum += prizeChancesOption[_i].chanceBase10000;
            if(randomBase10000 <= acum && randomBase10000 > previousAcum) {
                return (prizeChancesOption[_i]._prizeType, prizeChancesOption[_i].prizeSubtype);
            }
        }

        return (uint8(prizeType.none), 0);
    }

    // Solves the bet and sets the prize won
    function _solveBet(uint256 betIndex, uint8 _prizeType, uint8 prizeSubtype) public onlyRoulette {
        require(bets[betIndex].state == uint8(betState.pending), "Bet is not pending");

        // Solved
        bets[betIndex].state = uint8(betState.solved);

        // Prize type
        bets[betIndex].prizeWon = _prizeType;

        // Subtype
        if(bets[betIndex].prizeWon == uint8(prizeType.customPrizeDollarAmount)) {
            bets[betIndex].customPrizeDollarAmountWonType = prizeSubtype;
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.NFT)) {
            bets[betIndex].NFTwonType = prizeSubtype;
        }

        // Set bet as pending to claim for user
        _removeUserPendingBet(betIndex);
        userPendingBetsClaim[bets[betIndex].user].push(betIndex);
    }

    //endregion

    //region ADMIN

    function _setCustomDollarPrize(uint8 _n, uint256 _amount) public onlyRoulette { customDollarPrizes[_n] = _amount; }

    function _setCustomNFTPrize(uint8 _n, address _address) public onlyRoulette { customNFTPrizes[_n] = _address; }

    function _enableDisableBetAmount(uint256 _dollarsAmount, bool _enabled) public onlyRoulette {
        require(_dollarsAmount <= 1000, "Too big ");
        betsEnabled[_dollarsAmount] = _enabled;
    }

    function _setPrizeChanceOptions(uint8 [] memory _prizeType, uint8 [] memory _prizeSubtype, uint256 [] memory _chanceBase10000) public onlyRoulette {
        require(_prizeType.length == _prizeSubtype.length, "Same size arrays are required here _prizeType != _prizeSubtype");
        require(_prizeSubtype.length == _chanceBase10000.length, "Same size arrays are required here _prizeSubtype != _chanceBase10000");
        require(_prizeType[_prizeType.length - 1] == uint8(prizeType.none), "Last element has to be the chance to lose");      

        delete prizeChancesOption;
        for(uint256 _i; _i < _prizeType.length; _i++) {
            prizeChancesOption.push(prizeChance(
                _prizeType[_i],
                _prizeSubtype[_i],
                _chanceBase10000[_i]));
        }
    }

    //endregion

    //region UTILS

    // Remove the bet from user pending bets list, only internal use
    function _removeUserPendingBet(uint256 betIndex) private {
        uint256 _indexDelete = 0;
        bool _found = false;
        for(uint256 _i = 0; _i < userPendingBets[bets[betIndex].user].length; _i++){
            if(userPendingBets[bets[betIndex].user][_i] == betIndex){
                _indexDelete = _i;
                _found = true;
                break;
            }
        }    

        if(_found){
            userPendingBets[bets[betIndex].user][_indexDelete] = userPendingBets[bets[betIndex].user][userPendingBets[bets[betIndex].user].length - 1];
            userPendingBets[bets[betIndex].user].pop();
        }
    }

    // Remove the bet from user pending claim bets list, only internal use
    function _removeUserPendingBetClaim(uint256 betIndex) private {
        uint256 _indexDelete = 0;
        bool _found = false;
        for(uint256 _i = 0; _i < userPendingBetsClaim[bets[betIndex].user].length; _i++){
            if(userPendingBetsClaim[bets[betIndex].user][_i] == betIndex){
                _indexDelete = _i;
                _found = true;
                break;
            }
        }

        if(_found){
            userPendingBetsClaim[bets[betIndex].user][_indexDelete] = userPendingBetsClaim[bets[betIndex].user][userPendingBetsClaim[bets[betIndex].user].length - 1];
            userPendingBetsClaim[bets[betIndex].user].pop();
        }
    }

    //endregion
}