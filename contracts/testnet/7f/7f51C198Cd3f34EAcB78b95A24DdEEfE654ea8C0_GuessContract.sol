/**
 *Submitted for verification at Arbiscan on 2023-05-01
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at BscScan.com on 2021-04-30
*/

pragma solidity >=0.6.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


interface BEP20Interface{
    function totalSupply() external returns (uint);
    function balanceOf(address tokenOwner) external returns (uint balance);
    function allowance(address tokenOwner, address spender) external returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function transferGuess(address recipient, uint256 _amount) external returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */
 
// contract RandomNumberConsumer is VRFConsumerBase {
    
//     bytes32 internal keyHash;
//     uint256 internal fee;
//     bytes32 internal ReqId;
    
//     uint256 public randomResult;

//     constructor() 
//         VRFConsumerBase(
//             0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
//             0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06  // LINK Token
//         )
//     {
//         keyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
//         fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
//     }

//     /** 
//      * Requests randomness 
//      */
//     function getRandomNumber() public returns (bytes32 requestId) {
//         require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
//         ReqId = requestRandomness(keyHash, fee); 
//         return ReqId;
//     }

//     /**
//      * Callback function used by VRF Coordinator
//      */
//     function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
//         randomResult = (randomness%1000) + 1;
//     }

//     // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
// }


/*
Randomizer contract address :
Arbitrum One: 0x5b8bB80f2d72D0C85caB8fB169e8170A05C94bAF
Arbitrum Goerli: 0x923096Da90a3b60eb7E12723fA2E1547BA9236Bc
*/


// Randomizer protocol interface
interface IRandomizer {
	function request(uint256 callbackGasLimit) external returns (uint256);
	function request(uint256 callbackGasLimit, uint256 confirmations) external returns (uint256);
	function clientWithdrawTo(address _to, uint256 _amount) external;
}


contract GuessContract {
    
    using SafeMath for uint;
    
    address public owner ;
    uint public randomNum = 0;
    uint tokenPerWeek = 11200;
    uint timeBtwLastWinner;
    
    /* stoch contract address */    
    BEP20Interface public randContractAddress;
    // RandomNumberConsumer public vrfContracAddress;
    IRandomizer public randomizer;
    
    uint public totalTokenStakedInContract; 
    uint public winnerTokens;
      
    struct StakerInfo {
        bool isStaking;
        uint stakingBalance;
        uint[] choosedNumbers;
        uint maxNumberUserCanChoose;
        uint currentNumbers;
    }
    
    struct numberMapStruct {
        bool isChoosen;
        address userAddress;
    }
    
    mapping(address=>StakerInfo) StakerInfos;
    mapping(uint => numberMapStruct) numberMap;

    // uint[] temp;

    uint counter;

 //////////////////////////////////////////////////////////////////////////////Constructor Function///////////////////////////////////////////////////////////////////////////////////////////////////
     

    constructor(address _randContractAddress, address _vrfContractAddress) {
        timeBtwLastWinner = block.timestamp;
        owner = msg.sender;
        randContractAddress = BEP20Interface(_randContractAddress);
        // vrfContracAddress = RandomNumberConsumer(_vrfContractAddress);
        randomizer = IRandomizer(_vrfContractAddress);
    }


//////////////////////////////////////////////////////////////////////////////////////Modifier Definitations////////////////////////////////////////////////////////////////////////////////////////////

    /* onlyAdmin modifier to verify caller to be owner */
    modifier onlyAdmin {
        require (msg.sender ==  owner  , 'Only Admin has right to execute this function');
        _;
        
    }
    
    /* modifier to verify caller has already staked tokens */
    modifier onlyStaked() {
        require(StakerInfos[msg.sender].isStaking == true,"User Is Not Staking");
        _;
    }
    
    
//////////////////////////////////////////////////////////////////////////////////////Staking Function//////////////////////////////////////////////////////////////////////////////////////////////////



    /* function to stake tokens in contract. This will make staker to be eligible for guessing numbers 
    * 100 token => 1 guess
    */

    event staking(address staker,uint256 amount);

    /* This function is used for staking amount in contract for choosing numbers */
    function stakeTokens(uint _amount) external  { 
       require(_amount >= 100*1e18,"Minimum Amount 100"); 
       require(BEP20Interface(randContractAddress).allowance(msg.sender, address(this)) >= _amount, "token approval required");
    //   require ( StakerInfos[msg.sender].isStaking == false, "You have already staked once in this pool.You cannot staked again.Wait for next batch") ;
       require (BEP20Interface(randContractAddress).transferFrom(msg.sender, address(this), _amount),"From Transfer From");
       
       StakerInfos[msg.sender].stakingBalance =  StakerInfos[msg.sender].stakingBalance.add(_amount);
       totalTokenStakedInContract = totalTokenStakedInContract.add(_amount);
       StakerInfos[msg.sender].isStaking = true;
       StakerInfos[msg.sender].maxNumberUserCanChoose = (StakerInfos[msg.sender].stakingBalance).div(100*1e18); 
    
       emit staking(msg.sender,_amount);
    }


    /* This function is used for withdraw extra amount */
    /* Extra amount means remaining stacking amount after choosing numbers*/
    function withdrawExtraAmount() external onlyStaked{
        uint tokenStackAmount;
        uint remainAmount;
        for(uint i = 0;i<1000;i++){
            if(numberMap[i+1].isChoosen == true && numberMap[i+1].userAddress == msg.sender){
                // StakerInfos[msg.sender].stakingBalance -= 100*1e18;
                // totalTokenStakedInContract = totalTokenStakedInContract.sub(100*1e18);
                // StakerInfos[msg.sender].maxNumberUserCanChoose -= 1;
                tokenStackAmount+=100*1e18;
            }         
        }

        remainAmount=StakerInfos[msg.sender].stakingBalance-tokenStackAmount;
        randContractAddress.transferGuess(msg.sender,remainAmount);
        StakerInfos[msg.sender].stakingBalance -=remainAmount;
        StakerInfos[msg.sender].maxNumberUserCanChoose=StakerInfos[msg.sender].maxNumberUserCanChoose-(remainAmount/(100*1e18));
        if(StakerInfos[msg.sender].stakingBalance == 0){
            StakerInfos[msg.sender].isStaking = false;
        }
    }

    
    
    /* funtion to guess numbers as per tokens staked by the user. User can choose any numbers at a time but not more than max allocated count 
     * All choosen numbers must be in the range of 1 - 1000 
     * One number can be choosed by only one person
    */
    function chooseNumbers(uint[] memory _number) external onlyStaked() {
        require(StakerInfos[msg.sender].maxNumberUserCanChoose > 0,"you can't choose more then maximum numbers you can choose");
        require(StakerInfos[msg.sender].currentNumbers < StakerInfos[msg.sender].maxNumberUserCanChoose,"Maximum numbers limit reached.");
        require(StakerInfos[msg.sender].maxNumberUserCanChoose.sub(StakerInfos[msg.sender].currentNumbers) > 0,"You are already choosed maximum numbers.");
        require(_number.length <= StakerInfos[msg.sender].maxNumberUserCanChoose.sub(StakerInfos[msg.sender].currentNumbers),"You can't choose more than maximum numbers limit.");
        for(uint i = 0; i <_number.length; i++ ){
            require(_number[i] >= 1 && _number[i] <= 1000,"Ticket Number Is Valid");
            if(numberMap[_number[i]].isChoosen == false && numberMap[_number[i]].userAddress == address(0)){
                StakerInfos[msg.sender].currentNumbers += 1;
                numberMap[_number[i]].isChoosen = true;
                numberMap[_number[i]].userAddress = msg.sender;
            }
        }
        // for(uint i=0;i<_number.length;i++){
        //     require(_number[i] >= 1 && _number[i] <= 1000,"Hello5");
        // uint[] memory rejectedNumbers = new uint[](_number.length);
        // uint t=0;
        // for(uint i=0;i<_number.length;i++) {
        //     if (numberMap[_number[i]].isChoosen == true) {
        //         rejectedNumbers[t] = _number[i];
        //         t = t.add(1);
        //     }
        //     else {
        //         StakerInfos[msg.sender].currentNumbers = StakerInfos[msg.sender].currentNumbers.add(1);
        //         StakerInfos[msg.sender].choosedNumbers.push(_number[i]);
        //         numberMap[_number[i]].isChoosen = true;
        //         numberMap[_number[i]].userAddress = msg.sender;
        //         counter++;
        //     }
        // }

        // return rejectedNumbers;
        // }
        
    }
    
    
    /*  Using this function user can unstake his/her tokens at any point of time.
    *   After unstaking history of user related to choosed numbers is updated (choosed numbers, staking balance, isStaking)
    */
    function totalUnstake() external onlyStaked() returns(uint) {
        require(StakerInfos[msg.sender].stakingBalance > 0, "staking balance cannot be zero");
        uint _temp = 0;

        // for(uint i = 0; i < StakerInfos[msg.sender].choosedNumbers.length; i++){
        //    randContractAddress.transferGuess(msg.sender,100);
        //    totalTokenStakedInContract = totalTokenStakedInContract.sub(100);
        //    numberMap[StakerInfos[msg.sender].choosedNumbers[i]].isChoosen = false;
        //    numberMap[StakerInfos[msg.sender].choosedNumbers[i]].userAddress = address(0);
        //    counter--;
        // }

        // for(uint i = 0;i<1000;i++){
        //     if(numberMap[i+1].isChoosen == true && numberMap[i+1].userAddress == msg.sender){
        //         randContractAddress.transferGuess(msg.sender,100*1e18);
        //         totalTokenStakedInContract = totalTokenStakedInContract.sub(100*1e18);
        //         numberMap[i+1].isChoosen = false;
        //         numberMap[i+1].userAddress = address(0);
        //         temp += 100*1e18; 
        //     }
        // }

        // StakerInfos[msg.sender].stakingBalance = 0;
        // StakerInfos[msg.sender].isStaking = false;
        // StakerInfos[msg.sender].maxNumberUserCanChoose = 0;
        // delete StakerInfos[msg.sender].choosedNumbers;
        // StakerInfos[msg.sender].currentNumbers = 0;


        for(uint i = 0;i<1000;i++){
            if(numberMap[i+1].isChoosen == true && numberMap[i+1].userAddress == msg.sender){
                randContractAddress.transferGuess(msg.sender,100*1e18);
                StakerInfos[msg.sender].stakingBalance -= 100*1e18;
                StakerInfos[msg.sender].currentNumbers -= 1;
                totalTokenStakedInContract = totalTokenStakedInContract.sub(100*1e18);
                StakerInfos[msg.sender].maxNumberUserCanChoose -= 1;
                numberMap[i+1].isChoosen = false;
                numberMap[i+1].userAddress = address(0);
                _temp += 100*1e18;
            }
        }

        if(StakerInfos[msg.sender].stakingBalance == 0){
            StakerInfos[msg.sender].isStaking = false;
        }

        return _temp;
    }


    /* Used for unstack stacking amount for perticular choosed numbers */ 
    /* Used in choosewinner function */   
    function unstakeTokens(uint[] memory _number,address user) public onlyStaked() returns(uint) {
        require(StakerInfos[msg.sender].stakingBalance > 0, "staking balance cannot be zero");

        uint temp = 0;

        // for(uint i = 0; i < _number.length;i++){
        //     if(_number[i] == numberMap[i])
        // }

        for(uint i = 0; i < 1000;i++){
            for(uint j = 0; j < _number.length; j++){
                if(numberMap[i+1].isChoosen == true && numberMap[i+1].userAddress == user){
                    if(i+1 == _number[j]){
                       randContractAddress.transferGuess(user,100*1e18);
                       StakerInfos[user].stakingBalance -= 100*1e18;
                       StakerInfos[user].currentNumbers -= 1;
                       totalTokenStakedInContract = totalTokenStakedInContract.sub(100*1e18);
                       StakerInfos[user].maxNumberUserCanChoose -= 1;
                       numberMap[i+1].isChoosen = false;
                       numberMap[i+1].userAddress = address(0);
                       temp += 100*1e18;
                    }
                }
            }
        }
        
        // for(uint i=0;i<StakerInfos[msg.sender].choosedNumbers.length;i++) {
        //     for(uint256 j=0;j<_number.length;j++){
        //         if(_number[j] == StakerInfos[msg.sender].choosedNumbers[i] ){
        //             randContractAddress.transferGuess(msg.sender,100);
        //             StakerInfos[msg.sender].stakingBalance -= 100;
        //             StakerInfos[msg.sender].maxNumberUserCanChoose -= 1;
        //             StakerInfos[msg.sender].currentNumbers -= 1;
        //             counter--;
        //             totalTokenStakedInContract = totalTokenStakedInContract.sub(100);
        //             numberMap[StakerInfos[msg.sender].choosedNumbers[i]].isChoosen = false;
        //             numberMap[StakerInfos[msg.sender].choosedNumbers[i]].userAddress = address(0);
        //             StakerInfos[msg.sender].choosedNumbers[i] = 0;
        //         }
        //     }
        // } 

        // for(uint k = 0;k<StakerInfos[msg.sender].choosedNumbers.length;k++){
        //     if(StakerInfos[msg.sender].choosedNumbers[k] != 0 && numberMap[StakerInfos[msg.sender].choosedNumbers[k]].isChoosen == true ){
        //         temp.push(StakerInfos[msg.sender].choosedNumbers[k]);
        //     }
        // }
        
        // delete StakerInfos[msg.sender].choosedNumbers;

        // for(uint i=0;i<temp.length;i++) {
        //     StakerInfos[msg.sender].choosedNumbers.push(temp[i]);
        // }

        // delete temp;

        if(StakerInfos[msg.sender].stakingBalance == 0){
            StakerInfos[msg.sender].isStaking = false;
        }

        return temp;
    } 
    
    event winnerAddress(uint256 rewards,uint time);
    

    /* For transfer winner reward and stacking amount for perticular winning random number to winner */
    function chooseWinner() external onlyAdmin returns(address) {
        require(randomNum != 0,"Random number can't be zero");
        require(numberMap[randomNum].userAddress != address(0),"This number is not choosed by any user.");
        address user;
        user = numberMap[randomNum].userAddress;
        uint winnerRewards;
        uint _time = block.timestamp.sub(timeBtwLastWinner);
        winnerRewards = calculateReedemToken(_time);
        emit winnerAddress(winnerRewards,_time);
        require(BEP20Interface(randContractAddress).transferGuess(user, winnerRewards),"Require to set guess contract address.");
        uint[] memory t = new uint[](1);
        t[0] = randomNum;
        unstakeTokens(t,user);
        winnerTokens = winnerRewards;
        timeBtwLastWinner = block.timestamp;
        randomNum = 0;

        return user;
    }

    function setRandomizer(address _vrfContractAddress) public onlyAdmin{
        randomizer = IRandomizer(_vrfContractAddress);
    }
    
    /* check random number owner */
    function checkRandomOwner() view public returns(address) {
        require(numberMap[randomNum].userAddress != address(0), "No matched");
        return numberMap[randomNum].userAddress;
    }
    
    /* check random number */
    function checkRandomNumber() view public returns(uint) {
        return randomNum;
    } 
    
    /* To get numbers selected by user */
    function viewNumbersSelected(address _user) view public returns(uint[] memory) {
        uint[] memory tempo = new uint[](1000);
        for(uint i = 0;i<1000;i++){
            if(numberMap[i+1].isChoosen == true && numberMap[i+1].userAddress == _user){               
                tempo[i] = i+1;
            }
        }
        return tempo;
    }
    
    /* To get maximum nunbers user can select */
    function maxNumberUserCanSelect(address _user) view public returns(uint) {
        return StakerInfos[_user].maxNumberUserCanChoose;
    }
    
    /* To get remaining numbers user can select */
    function remainingNumbersToSet(address _user) view public returns(uint) {
        return (StakerInfos[_user].maxNumberUserCanChoose - StakerInfos[msg.sender].currentNumbers);
    }

    /* onlyAdmin modifier to verify caller to be owner */    
    function countNumberSelected(address _user) view public returns(uint) {
        return StakerInfos[_user].currentNumbers;
    }
    
    /* To get user staking balance */
    function checkStakingBalance(address _user) view public returns(uint) {
       return StakerInfos[_user].stakingBalance; 
    }
    
    /* To check is user is stacking or not */
    function isUserStaking(address _user) view public returns(bool) {
        return StakerInfos[_user].isStaking;
    }
    
    /* To get token amount which user can get in rewards at perticular */
    function calculateReedemToken(uint _time) view internal returns(uint) {
        // uint amount = tokenPerWeek;
        return tokenPerWeek.mul(_time).div(1 weeks);
        //amount = amount.mul(10**18);
        //amount = amount.div(7);
        //amount = amount.div(24);
        //amount = amount.div(60);
        //amount = amount.div(60);
        // return amount;
    } 
    
    /* To get current token reward amount */
    function calculateCurrentTokenAmount() view public returns(uint) {
        uint amount = calculateReedemToken(block.timestamp.sub(timeBtwLastWinner));
        return amount;
    }
    
    /* To get last winner choosed time */
    function lastWinsTime() view public returns(uint) {
        return timeBtwLastWinner;
    }
    
    /* To get token amount which winner get in reward*/
    function winnerTokensReceived() public view returns(uint) {
        return winnerTokens;
    }

    //This function is used 
    // function generateReqId() onlyAdmin external returns (bool) {
    //     vrfContracAddress.getRandomNumber();
    //     return true;
    // }

    // event randomN(uint256 num);

    
    // function generateRandomNumber() external onlyAdmin returns (uint) {
    //     randomNum = vrfContracAddress.randomResult();

    //     emit randomN(randomNum);

    //     return randomNum;
    // }


    /* To generate random number request*/
    function generateReqId() onlyAdmin external returns (bool) {
        randomizer.request(50000);
        return true;
    }

    /* This callback function is called by randomizer vrf contract */
    function randomizerCallback(uint256 _id, bytes32 _value) external{
    //Callback can only be called by randomizer
	    require(msg.sender == address(randomizer), "Caller not Randomizer");
        uint256 value=(uint(_value)%1000)+1;
        randomNum=value;
    }

    /* Allows the owner to withdraw their deposited randomizer funds */
	function randomizerWithdraw(uint256 amount) external onlyAdmin{ 
		randomizer.clientWithdrawTo(msg.sender, amount);
	}

    event randomN(uint256 num);

    /* To check the availability of number*/
    function availability(uint256 _ticketNumber) external view returns (bool) {
        require(_ticketNumber > 0,"Invalid Input");
        require(_ticketNumber <= 1000,"Invalid Input");
        if(numberMap[_ticketNumber].isChoosen == false){
            return true;
        } else {
            return false;
        }
    }

    /* To get all selected numbers */
    function occupied() external view returns(uint[] memory){
        uint[] memory tempo = new uint[](1000);
        for(uint i = 0;i<1000;i++){
            if(numberMap[i+1].isChoosen == true){
                
                tempo[i] = i+1;
            }
        }
        return tempo;
    }
    
    
}