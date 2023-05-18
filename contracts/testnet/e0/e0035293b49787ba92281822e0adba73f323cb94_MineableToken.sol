/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

// Mineable Token (0xMT) - Mineable Token Contract
//	
// Symbol: 0xMT
// Decimals: 18 
//
// Total supply: 21,000,000
//
// Mined over 50+ years using Bitcoins Distrubtion reward halvings every ~4 years. Uses Proof-oF-Work to distribute the tokens.
//
// Website: https://0xmt.com/
// Public Miner: https://0xmt.com/download.html
// Discord: https://discord.gg/EBHPmMUE45
//
// No premine, dev cut, or advantage taken at launch. Public miner available at launch.  100% of the token is given away fairly over 100+ years using Bitcoins model!
//
// Credits: 0xBitcoin


pragma solidity ^0.8.11;


/**
* @title Precompiled contract that exists in every Arbitrum chain at address(100), 0x0000000000000000000000000000000000000064. Exposes a variety of system-level functionality.
 */
interface ArbSys {
    /**
    * @notice Get internal version number identifying an ArbOS build
    * @return version number as int
     */
	function arbBlockHash(uint blockNumber) external view returns(bytes32);
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */ 
    function arbBlockNumber() external view returns (uint);

    /** 
    * @notice Send given amount of Eth to dest from sender.
    * This is a convenience function, which is equivalent to calling sendTxToL1 with empty calldataForL1.
    * @param destination recipient address on L1
    * @return unique identifier for this L2-to-L1 transaction.
    */
   
}


// File: contracts/utils/SafeMath.sol

library SafeMath2 {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        return x - y;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z / x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}

// File: contracts/utils/Math.sol

library ExtendedMath2 {


    //return the smaller of the two inputs (a or b)
    function limitLessThan(uint a, uint b) internal pure returns (uint c) {

        if(a > b) return b;

        return a;

    }
}

// File: contracts/interfaces/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    
}



contract MineableToken is IERC20 {

// Average BlockTime
    uint public targetTime = 60 * 12;

//Events
    using SafeMath2 for uint256;
    using ExtendedMath2 for uint;
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

// Managment events
    uint256 override public totalSupply = 21000000000000000000000000;
    bytes32 private constant BALANCE_KEY = keccak256("balance");
    
//MineableToken INITALIZE Start
    uint _totalSupply = 21000000000000000000000000;
    uint public epochOld = 0;  //Epoch count at each readjustment 
    uint public latestDifficultyPeriodStarted2 = block.timestamp; //BlockTime of last readjustment
    uint public latestDifficultyPeriodStarted = ArbSys(0x0000000000000000000000000000000000000064).arbBlockNumber();
    uint public epochCount = 0;//number of 'blocks' mined
    uint public _BLOCKS_PER_READJUSTMENT = 1024; // should be 1024
    uint public  _MAXIMUM_TARGET = 2**234;
    uint public  _MINIMUM_TARGET = 2**16; 
    uint public miningTarget = _MAXIMUM_TARGET;  //1000 million difficulty to start until i enable mining
    
    bytes32 public challengeNumber = ArbSys(0x0000000000000000000000000000000000000064).arbBlockHash( ArbSys(0x0000000000000000000000000000000000000064).arbBlockNumber() - 2);   //generate a new one when a new reward is minted

    uint public rewardEra = 0;
    uint public maxSupplyForEra = (_totalSupply - _totalSupply.div( 2**(rewardEra + 1)));
    uint public reward_amount;
    
    uint public tokensMinted = 0;	//Tokens Minted
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    uint public startTime;
    bool init = false;
// metadata
    string public name = "Mineable Token";
    string public constant symbol = "0xMT";
    uint8 public constant decimals = 18;
	
    
	constructor() {
		startTime = block.timestamp + 60 * 60 * 24 * 1; //Mining opens 1 days after contract launch.
	        reward_amount = 0;  //Zero reward for first day to setup miners
	        rewardEra = 0;
	        tokensMinted = 0;
	        epochCount = 0;
	        epochOld = 0;
	        miningTarget = _MAXIMUM_TARGET.div(10000);
	        latestDifficultyPeriodStarted2 = block.timestamp;
	        _startNewMiningEpoch();
	}

////////////////////////////////
// Contract Initial Functions //
///////////////////////////////


	function openMining() public returns (bool success) {
		//Starts mining after 1 day period for miners to setup is done
		require(!init, "Only allowed to run once");
		init = true;
		require(block.timestamp >= startTime && block.timestamp <= startTime + 60* 60 * 24* 7, "Must be after startTime");
	        reward_amount = 50 * 10**uint(decimals);
	        rewardEra = 0;
	        tokensMinted = 0;
	        epochCount = 0;
	        epochOld = 0;
		
		return true;
	}


/////////////////////////////
// Main Contract Functions //
/////////////////////////////

	function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success) {
		mintTo(nonce, challenge_digest, msg.sender);
		return true;
	}
	

	function mintTo(uint256 nonce, bytes32 challenge_digest, address mintToAddress) public returns (uint256 totalOwed) {
	
		bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

		//the challenge digest must match the expected
		require(digest == challenge_digest, "Old challenge_digest or wrong challenge_digest");

		//the digest must be smaller than the target
		require(uint256(digest) < miningTarget, "Digest must be smaller than miningTarget");

		_startNewMiningEpoch();

		balances[mintToAddress] = balances[mintToAddress].add(reward_amount);
		emit Transfer(address(0), mintToAddress, reward_amount);
		tokensMinted = tokensMinted.add(reward_amount);

		emit Mint(mintToAddress, reward_amount, epochCount, challengeNumber );

		return totalOwed;

	}
	

	function _startNewMiningEpoch() internal {
	
		//if max supply for the era will be exceeded next reward round then enter the new era before that happens
		//15 is the final reward era.
		if( tokensMinted.add(reward_amount) > maxSupplyForEra && rewardEra < 15)
		{
			rewardEra = rewardEra + 1;
			maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));
			if(rewardEra < 4){
				targetTime = ((12 * 60) * 2**rewardEra);
				if(_BLOCKS_PER_READJUSTMENT <= 16){
					_BLOCKS_PER_READJUSTMENT = 8;
				}else{
					_BLOCKS_PER_READJUSTMENT = _BLOCKS_PER_READJUSTMENT / 2;
				}
			}else{
				reward_amount = ( 50 * 10**uint(decimals)).div( 2**(rewardEra - 3  ) );
			}
		}

		// total supply of MINED tokens is ~21000000000000000000000000  because of 18 decimal places

		epochCount = epochCount.add(1);

		//every so often, readjust difficulty
		if((epochCount) % (_BLOCKS_PER_READJUSTMENT) == 0)
		{
			maxSupplyForEra = _totalSupply - _totalSupply.div( 2**(rewardEra + 1));
			_reAdjustDifficulty();
		}
		bytes32 challengeNumber2 = ArbSys(0x0000000000000000000000000000000000000064).arbBlockHash( ArbSys(0x0000000000000000000000000000000000000064).arbBlockNumber() - 1);
		require(challengeNumber2 != challengeNumber, "No same challenge Solves");
		challengeNumber = challengeNumber2;
	}


	function _reAdjustDifficulty() internal {
	
		uint256 blktimestamp = block.timestamp;
		uint TimeSinceLastDifficultyPeriod2 = blktimestamp - latestDifficultyPeriodStarted2;
		uint epochTotal = epochCount - epochOld;
		uint adjusDiffTargetTime = targetTime *  epochTotal; 
		epochOld = epochCount;

		//if there were less eth blocks passed in time than expected
		if( TimeSinceLastDifficultyPeriod2 < adjusDiffTargetTime )
		{
			uint excess_block_pct = (adjusDiffTargetTime.mult(100)).div( TimeSinceLastDifficultyPeriod2 );
			uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
			//make it harder 
			miningTarget = miningTarget.sub(miningTarget.div(2000).mult(excess_block_pct_extra));   //by up to 50 %
		}else{
			uint shortage_block_pct = (TimeSinceLastDifficultyPeriod2.mult(100)).div( adjusDiffTargetTime );
			uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000
			//make it easier
			miningTarget = miningTarget.add(miningTarget.div(500).mult(shortage_block_pct_extra));   //by up to 200 %
		}

		latestDifficultyPeriodStarted2 = blktimestamp;
		latestDifficultyPeriodStarted = ArbSys(0x0000000000000000000000000000000000000064).arbBlockNumber();
		if(miningTarget < _MINIMUM_TARGET) //very difficult
		{
			miningTarget = _MINIMUM_TARGET;
		}
		if(miningTarget > _MAXIMUM_TARGET) //very easy
		{
			miningTarget = _MAXIMUM_TARGET;
		}
		
	}



/////////////////////////
//// Helper Functions ///
/////////////////////////

	function blocksFromReadjust() public view returns (uint256 blocks){
		blocks = (epochCount % _BLOCKS_PER_READJUSTMENT);
		return blocks;
	}
	

	function blocksToReadjust() public view returns (uint blocks){
		blocks = _BLOCKS_PER_READJUSTMENT - ((epochCount) % _BLOCKS_PER_READJUSTMENT);
		 return (blocks);
	}


	function reAdjustsToWhatDifficulty() public view returns (uint difficulty) {
		if(epochCount - epochOld == 0){
			return _MAXIMUM_TARGET.div(miningTarget);
		}
		uint256 blktimestamp = block.timestamp;
		uint TimeSinceLastDifficultyPeriod2 = blktimestamp - latestDifficultyPeriodStarted2;
		uint epochTotal = epochCount - epochOld;
		uint adjusDiffTargetTime = targetTime *  epochTotal; 
        	uint miningTarget2 = 0;
		//if there were less eth blocks passed in time than expected
		if( TimeSinceLastDifficultyPeriod2 < adjusDiffTargetTime )
		{
			uint excess_block_pct = (adjusDiffTargetTime.mult(100)).div( TimeSinceLastDifficultyPeriod2 );
			uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(1000);
			//make it harder 
			miningTarget2 = miningTarget.sub(miningTarget.div(2000).mult(excess_block_pct_extra));   //by up to 50 %
		}else{
			uint shortage_block_pct = (TimeSinceLastDifficultyPeriod2.mult(100)).div( adjusDiffTargetTime );

			uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(1000); //always between 0 and 1000
			//make it easier
			miningTarget2 = miningTarget.add(miningTarget.div(500).mult(shortage_block_pct_extra));   //by up to 200 %
		}

		if(miningTarget2 < _MINIMUM_TARGET) //very difficult
		{
			miningTarget2 = _MINIMUM_TARGET;
		}
		if(miningTarget2 > _MAXIMUM_TARGET) //very easy
		{
			miningTarget2 = _MAXIMUM_TARGET;
		}
		difficulty = _MAXIMUM_TARGET.div(miningTarget2);
			return difficulty;
	}



/////////////////////////
// Statistics Functions /
/////////////////////////

	function inflationMined () public view returns (uint YearlyInflation, uint EpochsPerYear, uint RewardsAtTime, uint TimePerEpoch){
		if(epochCount - epochOld == 0){
			return (0, 0, 0, 0);
		}
		uint256 blktimestamp = block.timestamp;
		uint TimeSinceLastDifficultyPeriod2 = blktimestamp - latestDifficultyPeriodStarted2;

        
		TimePerEpoch = TimeSinceLastDifficultyPeriod2 / blocksFromReadjust(); 
		RewardsAtTime = reward_amount;
		uint year = 365 * 24 * 60 * 60;
		EpochsPerYear = year / TimePerEpoch;
		YearlyInflation = RewardsAtTime * EpochsPerYear;
		return (YearlyInflation, EpochsPerYear, RewardsAtTime, TimePerEpoch);
	}

	
	function toNextEraDays () public view returns (uint daysToNextEra, uint _maxSupplyForEra, uint _tokensMinted, uint amtDaily){

        (uint totalamt,,,) = inflationMined();
		(amtDaily) = totalamt / 365;
		if(amtDaily == 0){
			return(0,0,0,0);
		}
		daysToNextEra = (maxSupplyForEra - tokensMinted) / amtDaily;
		return (daysToNextEra, maxSupplyForEra, tokensMinted, amtDaily);
	}
	

	function toNextEraEpochs () public view returns ( uint epochs, uint epochTime, uint daysToNextEra){
		if(blocksFromReadjust() == 0){
			return (0,0,0);
        }
		uint256 blktimestamp = block.timestamp;
        uint TimeSinceLastDifficultyPeriod2 = blktimestamp - latestDifficultyPeriodStarted2;
		uint timePerEpoch = TimeSinceLastDifficultyPeriod2 / blocksFromReadjust();
		(uint daysz,,,) = toNextEraDays();
		uint amt = daysz * (60*60*24) / timePerEpoch;
		return (amt, timePerEpoch, daysz);
	}



/////////////////////////
/// Debug Functions  ////
/////////////////////////

	function checkMintSolution(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget) public view returns (bool success) {
		bytes32 digest = bytes32(keccak256(abi.encodePacked(challenge_number,msg.sender,nonce)));
		if(uint256(digest) > testTarget) revert();

		return (digest == challenge_digest);
	}

	function checkMintSolutionForAddress(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number, uint testTarget, address sender) public view returns (bool success) {
		bytes32 digest = bytes32(keccak256(abi.encodePacked(challenge_number,sender,nonce)));
		if(uint256(digest) > testTarget) revert();

		return (digest == challenge_digest);
	}


	//this is a recent ethereum block hash, used to prevent pre-mining future blocks
	function getChallengeNumber() public view returns (bytes32) {

		return challengeNumber;

	}

	
	//the number of zeroes the digest of the PoW solution requires.  Auto adjusts
	function getMiningDifficulty() public view returns (uint) {
			return _MAXIMUM_TARGET.div(miningTarget);
	}


	function getMiningTarget() public view returns (uint) {
			return (miningTarget);
	}


	function getMiningMinted() public view returns (uint) {
		return tokensMinted;
	}

	function getCirculatingSupply() public view returns (uint) {
		return tokensMinted;
	}

	//~21m coins total in minting
	//reward begins at 50 and stays same for the first 4 eras (0-3), targetTime doubles to compensate for first 4 eras
	//After rewardEra = 4 it halves the reward every Era because no more targetTime is added
	function getMiningReward() public view returns (uint) {

		if(rewardEra < 4){
			return ( 50 * 10**uint(decimals));
		}else{
			return ( 50 * 10**uint(decimals)).div( 2**(rewardEra - 3  ) );
		}
		}


	function getEpoch() public view returns (uint) {

		return epochCount ;

	}


	//help debug mining software
	function getMintDigest(uint256 nonce, bytes32 challenge_digest, bytes32 challenge_number) public view returns (bytes32 digesttest) {

		bytes32 digest =  keccak256(abi.encodePacked(challengeNumber, msg.sender, nonce));

		return digest;

	}


/////////////////////////
///  ERC20 Functions  ///
/////////////////////////

		// ------------------------------------------------------------------------

		// Get the token balance for account `tokenOwner`

		// ------------------------------------------------------------------------

	function balanceOf(address tokenOwner) public override view returns (uint balance) {

		return balances[tokenOwner];

	}


		// ------------------------------------------------------------------------

		// Transfer the balance from token owner's account to `to` account

		// - Owner's account must have sufficient balance to transfer

		// - 0 value transfers are allowed

		// ------------------------------------------------------------------------


	function transfer(address to, uint tokens) public override returns (bool success) {

		balances[msg.sender] = balances[msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);

		emit Transfer(msg.sender, to, tokens);

		return true;

	}


		// ------------------------------------------------------------------------

		// Token owner can approve for `spender` to transferFrom(...) `tokens`

		// from the token owner's account

		//

		// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md

		// recommends that there are no checks for the approval double-spend attack

		// as this should be implemented in user interfaces

		// ------------------------------------------------------------------------


	function approve(address spender, uint tokens) public override returns (bool success) {

		allowed[msg.sender][spender] = tokens;

		emit Approval(msg.sender, spender, tokens);

		return true;

	}


		// ------------------------------------------------------------------------

		// Transfer `tokens` from the `from` account to the `to` account

		//

		// The calling account must already have sufficient tokens approve(...)-d

		// for spending from the `from` account and

		// - From account must have sufficient balance to transfer

		// - Spender must have sufficient allowance to transfer

		// - 0 value transfers are allowed

		// ------------------------------------------------------------------------


	function transferFrom(address from, address to, uint tokens) public override returns (bool success) {

		balances[from] = balances[from].sub(tokens);
		allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
		balances[to] = balances[to].add(tokens);

		emit Transfer(from, to, tokens);

		return true;

	}


		// ------------------------------------------------------------------------

		// Returns the amount of tokens approved by the owner that can be

		// transferred to the spender's account

		// ------------------------------------------------------------------------


	function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {

		return allowed[tokenOwner][spender];

	}




	  //Allow ETH to enter
	receive() external payable {
        revert();
	}


	fallback() external payable {
            revert();

	}
}

/*
*
* MIT License
* ===========
*
* Copyright (c) 2023 Mineable Tokens (0xMT)
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.   
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/