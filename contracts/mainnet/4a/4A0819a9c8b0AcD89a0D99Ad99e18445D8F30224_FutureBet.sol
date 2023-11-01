/**
 *Submitted for verification at Arbiscan.io on 2023-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface Uniswap {
    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract FutureBet is Ownable {
    IERC20 token;

    bool public isPaused = false;

    uint256 public totalGameRound = 0;
    uint256 public projectFee = 10; // this value is in % of the pool size
    uint256 public freezeTime = 5 * 60; // this value is the time in seconds. This value means number of seconds the function is freezed
    uint256 public claimFreeze = 0;
    uint256 public optionCount = 3;
    uint256 public subQuestionResultOrderLength = 0;

    address public projectFeeAddress;
    address public tokenStoreWallet;

    struct Transaction {
        address user;
        uint256 round;
        uint256 quest_no;
        uint256 amount;
        uint256 betOption;
    }

    struct RoundTransactionType{
        address user;
        uint256 round;
        uint256 quest_no;
        uint256 amount;
        uint256 betOption;
        string[] optionNames;
    }

    struct questionType {
        uint256 round;
        string roundTitle;
        bool roundCanceled;
        string roundCategory;
        uint256 roundPoolSize;
        string roundBannerURL;
        string roundTeam1Name;
        string roundTeam2Name;
        uint256 roundStartTime;
        string roundTeam1LogoURL;
        string roundTeam2LogoURL;
    }

    struct questionTypeWithSubQuestions {
        uint256 round;
        string roundTitle;
        bool roundCanceled;
        string roundCategory;
        uint256 roundPoolSize;
        string roundBannerURL;
        string roundTeam1Name;
        string roundTeam2Name;
        uint256 roundStartTime;
        string roundTeam1LogoURL;
        string roundTeam2LogoURL;
        subQuestionType[] questions;
    }
    

    struct subQuestionType{
        bool isLocked;
        uint256 result;
        string question;
        uint256 quest_no;
        uint256 lockTime;
        uint256 betAmount;
        uint256 option1Bet;
        uint256 option2Bet;
        uint256 option3Bet;
        uint256 claimedAmount;
        uint256 claimableAmount;
        string [] optionNames;
        uint256 refundedAmount;
        uint256 subQuestionPoolSize;
    }

    struct BetDetails {
        uint256 round;
        bool isLocked;
        uint256 result;
        string question;
        uint256 quest_no;
        uint256 betOption;
        uint256 betAmount;
        bool roundCanceled;
        string[] optionNames;
        uint256 refundedAmount;
        uint256 claimableAmount;
        uint256 lockTime;
    }

    struct resultType {
        uint256 result;
        uint256 round;
        string question;
        string roundBannerURL;
        string roundCategory;
        uint256 roundPoolSize;
        uint256 roundEndTime;
        uint256 roundResultTime;
    }

    struct poolSizeType {
        uint256 round;
        uint256 poolSize;
        string roundTitle;
    }

    struct subQuestionResultOrderType {
        uint256 round;
        uint256 quest_no;
    }

  

    address[] users;
    Transaction[] public recentTransactions;
    subQuestionResultOrderType[] subQuestionResultOrder;

    mapping(address => bool) public isAdmin;
    mapping(uint256 => string) public roundCategory;

    // new added
    mapping(uint256 => string) public roundTitle; //[round] = title
    mapping(uint256 => string) public roundBannerURL; //[round] = url
    mapping(uint256 => string) public roundTeam1LogoURL;
    mapping(uint256 => string) public roundTeam2LogoURL;
    mapping(uint256 => string) public roundTeam1Name;
    mapping(uint256 => string) public roundTeam2Name;
    mapping(uint256 => uint256) public roundStartTime;
    mapping(uint256 => bool) public roundCanceled;


    mapping(uint256 => uint256) public roundPoolSize;
    mapping(uint256 => uint256) public roundTotalBets;
    mapping(address => bool) public userAddresses;
    mapping(address => uint256) public userBetCount;

    // New add
    mapping(uint256 => uint256) public subQuestionCount;
    mapping(uint256 =>mapping(uint256 => string)) public subQuestion; // [round][quest_no] = question
    mapping(uint256 =>mapping(uint256 => bool)) public subQuestionLocked;
    mapping(uint256 =>mapping(uint256 => uint256)) public subQuestionResult;
    mapping(uint256 =>mapping(uint256 => uint256)) public subQuestionLockTime;
    mapping(uint256 => mapping(uint256 => uint256)) public subQuestionPoolSize; // [round][quest_no] = pool size (total bet amount on question)
    mapping(uint256 => mapping(uint256 => mapping (uint256 => uint256))) public subQuestionOptionBet; // [round][quest_no][option] = bet amount
    mapping(uint256 => mapping (uint256 => mapping (uint256 => string))) public subQuestionOptionName; // [roundNumber][quest_no][optionNumber] = optionName;

     
    // mapping (address => mapping (uint256 => mapping (uint256 => uint256))) public userBetAmount; // [user][round][quest_no] = amount
    // mapping (address => mapping (uint256 => mapping (uint256 => uint256))) public userBetOption; // [user][round][quest_no] = 1 or 2 or 3
    mapping (address => mapping (uint256 => mapping (uint256 => uint256))) public userSubQuestionClaimedAmount; // [user][round][quest_no]= amount


    // to store user amount refunded on round cancelation
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public userRoundRefundAmount; // [user][round] = amount
    

    // to store multiple option bet amount
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256)))) public userBetAmount; // [user][round][quest_no][option] = amount

    // to store user mulitple option bet
    mapping(address => mapping(uint256 => mapping(uint256 => mapping(uint256 => bool)))) public userBetOption; // [user][round][quest_no][option] = boolean



    // All modifiers here
    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    modifier isPausable() {
        require(!isPaused, "Contract is paused");
        _;
    }

    constructor() {
        token = IERC20(0x0c97AfB21a37dd50226c8C9d505B17520CB80ABb);
        projectFeeAddress = 0x5Ff4c7A335ecBF4566beb4fa8de2e050A3f65c2E;
        isAdmin[msg.sender] = true;
        tokenStoreWallet = address(this);
    }

    function placeBet(uint256 _round,uint256 _quest_no,uint256 _amount,uint256 _betOption) public isPausable {

        require(_round <= totalGameRound,"Round does not exist");
        require(!roundCanceled[_round],"Round is canceled");
        require(_betOption <= optionCount && _betOption > 0, "Invalid Option");
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");

        bool check = true;
        if(subQuestionLockTime[_round][_quest_no] < block.timestamp){
            check = false;
        }

        if(subQuestionLocked[_round][_quest_no] == true){
            check = false;
        }

        require(check ,"Question is locked");


        token.transferFrom(msg.sender, tokenStoreWallet, _amount);

        roundTotalBets[_round] += 1;
        roundPoolSize[_round] += _amount;
        userBetCount[msg.sender] += 1;
        subQuestionPoolSize[_round][_quest_no] += _amount;

        if (!userAddresses[msg.sender]) {
            users.push(msg.sender);
            userAddresses[msg.sender] = true;
        }

        userBetOption[msg.sender][_round][_quest_no][_betOption] = true;
        userBetAmount[msg.sender][_round][_quest_no][_betOption] += _amount;
        subQuestionOptionBet[_round][_quest_no][_betOption] += _amount;

        recentTransactions.push(
            Transaction({
                user:msg.sender,
                round:_round,
                quest_no:_quest_no,
                amount:_amount,
                betOption:_betOption
            })
        );
    }

    function claimReward(uint256 _round,uint256 _quest_no) public isPausable {
        require(claimFreeze < block.timestamp,"Claiming is not allowed. Wait for some time");
        require(_round <= totalGameRound,"Round does not exist");

        uint256 _claimableRewards = claimableReward(msg.sender, _round,_quest_no);
        require(_claimableRewards > 0, "No rewards to claim");
        
        userSubQuestionClaimedAmount[msg.sender][_round][_quest_no] += _claimableRewards;

        if (tokenStoreWallet == address(this)) {
            token.transfer(msg.sender, _claimableRewards);
        } else {
            token.transferFrom(tokenStoreWallet, msg.sender, _claimableRewards);
        }
    }

    function claimRefundAmount(uint256 _round,uint256 _quest_no) public isPausable {

        require(claimFreeze < block.timestamp,"Claiming is not allowed. Wait for some time");
        require(roundCanceled[_round] == true,"Round is not canceled");

        uint256 _refundableAmount;

        _refundableAmount += userBetAmount[msg.sender][_round][_quest_no][1];
        _refundableAmount += userBetAmount[msg.sender][_round][_quest_no][2];
        _refundableAmount += userBetAmount[msg.sender][_round][_quest_no][3];

        require(_refundableAmount > 0,"No refund to claim");

        if (tokenStoreWallet == address(this)) {
            token.transfer(msg.sender, _refundableAmount);
        } else {
            token.transferFrom(tokenStoreWallet, msg.sender, _refundableAmount);
        }
        
        roundPoolSize[_round] -= _refundableAmount;
        userRoundRefundAmount[msg.sender][_round][_quest_no] = _refundableAmount;
    }

    // ALL VIEW FUNCTIONS HERE ----------------------------------------------------------------

    function claimableReward(address _user,uint256 _round,uint256 _quest_no) public view returns (uint256 _amount) {

        if (subQuestionResult[_round][_quest_no] == 0) return 0;

        uint256 _selectedOption;

        // check if the user betted on the winning option
        for(uint256 _option = 1;_option <= optionCount;_option++){
            if(userBetOption[_user][_round][_quest_no][_option] == true){
                if(_option == subQuestionResult[_round][_quest_no]){
                    _selectedOption = _option;
                    break;
                }else{
                    return 0;
                }
            }
        }

        if(_selectedOption == 0) return 0; // user did not bet on the any option

        uint256 _roundResult = subQuestionResult[_round][_quest_no];

        uint256 _totalBet = subQuestionPoolSize[_round][_quest_no];
        uint256 _projectFee = (subQuestionPoolSize[_round][_quest_no] * projectFee) / 100;
        uint256 _claimableAmount = ((_totalBet - _projectFee) * userBetAmount[_user][_round][_quest_no][_selectedOption]) /
         subQuestionOptionBet[_round][_quest_no][_roundResult];

        return _claimableAmount;
    }

    // get round transaction 
    function getRoundTransactions(uint256 _round) public view returns (RoundTransactionType[] memory) {
        uint256 _length = recentTransactions.length;
        uint256 count = 0;

        RoundTransactionType[] memory _roundTransactions = new RoundTransactionType[](_length);

        for (int256 i = int256(_length) - 1; i >= 0 && count < _length; i--) {
            if (recentTransactions[uint256(i)].round == _round) {
                _roundTransactions[count] = RoundTransactionType({
                    user: recentTransactions[uint256(i)].user,
                    round: recentTransactions[uint256(i)].round,
                    quest_no: recentTransactions[uint256(i)].quest_no,
                    amount: recentTransactions[uint256(i)].amount,
                    betOption: recentTransactions[uint256(i)].betOption,
                    optionNames: getOptionNamesOfSubQuestion(_round,recentTransactions[uint256(i)].quest_no)
                });
                count++;
            }
        }

        // Resize the array to match the number of transactions
        assembly {
            mstore(_roundTransactions, count)
        }

        return _roundTransactions;
    }


    // get recent transactions of a user
    function getUserTransactions(address _user,uint256 n) public view returns (Transaction[] memory) {
        uint256 _length = recentTransactions.length;
        uint256 count = 0;

        Transaction[] memory _userTransactions = new Transaction[](n);

        for (int256 i = int256(_length) - 1; i >= 0 && count < n; i--) {
            if (recentTransactions[uint256(i)].user == _user) {
                _userTransactions[count] = recentTransactions[uint256(i)];
                count++;
            }
        }
        return _userTransactions;
    }

   
    // Get all user bet details
    function getUserBetDetails(address _user) public view returns (BetDetails[] memory) {
        uint256 _length = userBetCount[_user];
        uint256 count = 0;

        // Create an array to store user bet details
        BetDetails[] memory _userBetDetails = new BetDetails[](_length);

        for (uint256 txIndex = 0; txIndex < recentTransactions.length; txIndex++) {
            uint256 _round = recentTransactions[txIndex].round;
            uint256 _quest_no = recentTransactions[txIndex].quest_no;
            uint256 _option = recentTransactions[txIndex].betOption;
            uint256 _amount = recentTransactions[txIndex].amount;
            address _userAddress = recentTransactions[txIndex].user;

            // Check if the transaction is associated with the specified user
            if (_userAddress == _user) {
                _userBetDetails[count] = BetDetails({
                    round: _round,
                    betAmount: _amount,
                    betOption: _option,
                    quest_no: _quest_no,
                    roundCanceled: roundCanceled[_round],
                    question: subQuestion[_round][_quest_no],
                    result: subQuestionResult[_round][_quest_no],
                    isLocked: subQuestionLocked[_round][_quest_no],
                    lockTime: subQuestionLockTime[_round][_quest_no],
                    optionNames: getOptionNamesOfSubQuestion(_round,_quest_no),
                    claimableAmount: claimableReward(_user, _round, _quest_no),
                    refundedAmount: userRoundRefundAmount[_user][_round][_quest_no]
                });
                count++;
            }
        }

        // Ensure that the returned array has the correct length
        // This step may be needed if userBetCount[_user] is not always accurate
        if (count < _length) {
            assembly {
                mstore(_userBetDetails, count)
            }
        }

        return _userBetDetails;
    }


    // get total games done
    function getTotalGames() public view returns (uint256) {
        return totalGameRound;
    }

    // Get all user claimed amounts and user addresses
    function getTopWinners() public view returns (uint256[] memory, address[] memory) {
        uint256[] memory _claimedAmounts = new uint256[](users.length);
        address[] memory _userAddresses = new address[](users.length);
        uint256 _count = 0;

        for (uint256 i = 0; i < users.length; i++) {
            address currentUser = users[i];
            uint256 totalClaimedAmount = 0;

            for (uint256 _round = 1; _round <= totalGameRound; _round++) {
                for (uint256 _quest_no = 1; _quest_no <= subQuestionCount[_round]; _quest_no++) {
                    uint256 _reward = userSubQuestionClaimedAmount[currentUser][_round][_quest_no];
                    if (_reward > 0) {
                        totalClaimedAmount += _reward;
                    }
                }
            }

            // Only include users with claimed amounts
            if (totalClaimedAmount > 0) {
                _userAddresses[_count] = currentUser;
                _claimedAmounts[_count] = totalClaimedAmount;
                _count++;
            }
        }

        // Resize arrays to match the number of users with claimed amounts
        assembly {
            mstore(_claimedAmounts, _count)
            mstore(_userAddresses, _count)
        }

        return (_claimedAmounts, _userAddresses);
    }


    // Get top pool size for active rounds
    function getTopPoolSize() public view returns (poolSizeType[] memory) {
        poolSizeType[] memory _poolSizeDetails = new poolSizeType[](totalGameRound);
        uint256 _count = 0;
        for (uint256 _round = 1; _round <= totalGameRound; _round++) {
            if (roundCanceled[_round]) continue; // Skip canceled rounds

            // Populate pool size details for active rounds
            _poolSizeDetails[_count] = poolSizeType({
                round: _round,
                poolSize: roundPoolSize[_round],
                roundTitle: roundTitle[_round]
            });
            _count++;
        }

        // Resize the array to match the number of active rounds
        assembly {
            mstore(_poolSizeDetails, _count)
        }

        return _poolSizeDetails;
    }


    function getAllQuestions(string memory _category) public view returns (questionType[] memory) {
        questionType[] memory _allQuestions = new questionType[](totalGameRound);

        for (uint256 _roundNumber = 1;_roundNumber <= totalGameRound;_roundNumber++) {
            
            // making sure all the questions are of same category
            if(keccak256(bytes(_category)) != keccak256(bytes(roundCategory[_roundNumber]))) continue;

             _allQuestions[_roundNumber - 1] = questionType({
                round: uint256(_roundNumber),
                roundTitle: roundTitle[_roundNumber],
                roundCanceled: roundCanceled[_roundNumber],
                roundCategory: roundCategory[_roundNumber],
                roundPoolSize: roundPoolSize[_roundNumber],
                roundStartTime: roundStartTime[_roundNumber],
                roundBannerURL: roundBannerURL[_roundNumber],
                roundTeam1Name: roundTeam1Name[_roundNumber],
                roundTeam2Name: roundTeam2Name[_roundNumber],
                roundTeam1LogoURL: roundTeam1LogoURL[_roundNumber],
                roundTeam2LogoURL: roundTeam2LogoURL[_roundNumber]
            });
        }
        return _allQuestions;
    }

    function getQuestion(uint256 _roundNumber) public view returns (questionTypeWithSubQuestions memory) {

        require(_roundNumber <= totalGameRound,"Round does not exist");

        subQuestionType [] memory questions = new subQuestionType[](subQuestionCount[_roundNumber]);

        // getting sub questions
        for(uint256 _quest_no = 1;_quest_no <= subQuestionCount[_roundNumber];_quest_no++){
            uint256 _option1Bet = subQuestionOptionBet[_roundNumber][_quest_no][1];
            uint256 _option2Bet = subQuestionOptionBet[_roundNumber][_quest_no][2];
            uint256 _option3Bet = subQuestionOptionBet[_roundNumber][_quest_no][3];

            uint256 _betAmount = userBetAmount[msg.sender][_roundNumber][_quest_no][1] + userBetAmount[msg.sender][_roundNumber][_quest_no][2] + userBetAmount[msg.sender][_roundNumber][_quest_no][3];

            questions[_quest_no -1]=(subQuestionType({
                quest_no: _quest_no,
                betAmount: _betAmount,
                option1Bet: _option1Bet,
                option2Bet: _option2Bet,
                option3Bet: _option3Bet,
                question: subQuestion[_roundNumber][_quest_no],
                result:subQuestionResult[_roundNumber][_quest_no],
                isLocked: subQuestionLocked[_roundNumber][_quest_no],
                lockTime: subQuestionLockTime[_roundNumber][_quest_no],
                optionNames: getOptionNamesOfSubQuestion(_roundNumber,_quest_no),
                subQuestionPoolSize: subQuestionPoolSize[_roundNumber][_quest_no],
                claimableAmount: claimableReward(msg.sender, _roundNumber,_quest_no),
                refundedAmount: userRoundRefundAmount[msg.sender][_roundNumber][_quest_no],
                claimedAmount: userSubQuestionClaimedAmount[msg.sender][_roundNumber][_quest_no]
            }));
        }

        return questionTypeWithSubQuestions({
            round: uint256(_roundNumber),
            roundTitle: roundTitle[_roundNumber],
            roundPoolSize: roundPoolSize[_roundNumber],
            roundCanceled: roundCanceled[_roundNumber],
            roundCategory: roundCategory[_roundNumber],
            roundStartTime: roundStartTime[_roundNumber],
            roundBannerURL: roundBannerURL[_roundNumber],
            roundTeam1Name: roundTeam1Name[_roundNumber],
            roundTeam2Name: roundTeam2Name[_roundNumber],
            roundTeam1LogoURL: roundTeam1LogoURL[_roundNumber],
            roundTeam2LogoURL: roundTeam2LogoURL[_roundNumber],
            questions: questions   
        });
    }

    function isUserSubQuestionClaimedAmount(address _user,uint256 _round,uint256 _quest_no) public view returns (uint256) {
        return userSubQuestionClaimedAmount[_user][_round][_quest_no];
    }

    function getOptionNamesOfSubQuestion(uint256 _round, uint256 _quest_no) public view returns (string[] memory) {

        string [] memory _optionNames= new string[](3);
        for(uint256 _option = 0; _option<optionCount;_option++ ){
            _optionNames[_option] = subQuestionOptionName[_round][_quest_no][_option+1];
        }
        return _optionNames;
    }

    // ADMIN FUNCTIONS HERE ----------------------------------------------------------------

    // announce results
    function announceResult(uint256 _round,uint256 _quest_no,uint256 _result) external onlyAdmin {
        require(_round <= totalGameRound,"Round does not exist");
        require(roundCanceled[_round] == false,"Round is canceled");
        require(_quest_no <= subQuestionCount[_round],"Question does not exist");
        require(subQuestionResult[_round][_quest_no] == 0,"Result already announced");
        require(_result <= optionCount && _result > 0, "Invalid Option, It should be 1 or 2 or 3");
        require(bytes(subQuestionOptionName[_round][_quest_no][_result]).length > 0,"Invalid Option, It should be 1 or 2");
        
        bool check = true;
        if(subQuestionLockTime[_round][_quest_no] > block.timestamp){
            check = false;
        }

        if(subQuestionLocked[_round][_quest_no] == false){
            check = false;
        }

        require(check ,"Question is not locked");



        subQuestionResult[_round][_quest_no] = _result;

        // send game owner fees
        uint256 _fees = (subQuestionPoolSize[_round][_quest_no] * projectFee) / 100;

        if (tokenStoreWallet == address(this)) {
            token.transfer(projectFeeAddress, _fees);
        } else {
            token.transferFrom(tokenStoreWallet,projectFeeAddress,_fees);
        }

        subQuestionResultOrder.push(subQuestionResultOrderType({
            round: _round,
            quest_no: _quest_no
        }));
    }

    // this function is to override result
    function overrideResult(uint256 _round,uint256 _quest_no,uint256 _result) external onlyAdmin {
        require(_round <= totalGameRound,"Round does not exist");
        require(_quest_no <= subQuestionCount[_round],"Question does not exist");
        require(roundCanceled[_round] == false,"Round is canceled");

        bool check = true;
        if(subQuestionLockTime[_round][_quest_no] > block.timestamp){
            check = false;
        }

        if(subQuestionLocked[_round][_quest_no] == false){
            check = false;
        }

        require(check ,"Question is not locked");

        subQuestionResult[_round][_quest_no] = _result;
    }

    // cancel round
    function cancelRound(uint256 _round) external onlyAdmin {
        require(_round <= totalGameRound,"Round does not exist");

        // check if the any of subquestion result has been declared 
        for(uint256 _quest_no = 1;_quest_no <= subQuestionCount[_round];_quest_no++){
            require(subQuestionResult[_round][_quest_no] == 0,"You can not cancel this round, as the result has been declared for one of the sub questions");
        }

        roundCanceled[_round] = true;
    }

    // lock sub question
    function lockSubQuestion(uint256 _round,uint256 _quest_no) external onlyAdmin {
        require(_round <= totalGameRound,"Round does not exist");
        require(_quest_no <= subQuestionCount[_round],"Question does not exist");
        subQuestionLocked[_round][_quest_no] = true;
    }

    function addQuestion(
            string memory _roundTitle,string memory _roundBannerURL,string memory _roundCategory,string memory _roundTeam1LogoURL,
            string memory _roundTeam2LogoURL,string memory _roundTeam1Name,string memory _roundTeam2Name,uint256 _roundStartTime
        ) public onlyAdmin {

        require(keccak256(bytes(_roundCategory)) == keccak256(bytes("cricket")) ||keccak256(bytes(_roundCategory)) == keccak256(bytes("football")) ,
            "Invalid category. Category should be one of cricket, football"
        );

        totalGameRound += 1;

        roundTitle[totalGameRound] =  _roundTitle;
        roundCategory[totalGameRound] =  _roundCategory;
        roundBannerURL[totalGameRound] = _roundBannerURL;
        roundTeam1Name[totalGameRound] = _roundTeam1Name;
        roundTeam2Name[totalGameRound] = _roundTeam2Name;
        roundTeam1LogoURL[totalGameRound] = _roundTeam1LogoURL;
        roundTeam2LogoURL[totalGameRound] = _roundTeam2LogoURL;
        roundStartTime[totalGameRound] = _roundStartTime;
        roundPoolSize[totalGameRound] = 0;

        
    }

    function addSubQuestion(uint256 _round,string memory _question, string [] memory _subQuestionOptionNames,uint256 _subQuestionLockTime) public onlyAdmin {
        require(_subQuestionLockTime>0,"Lock time should be greater than 0");
        require(_round <= totalGameRound,"Round does not exist");
        require(roundCanceled[_round] == false,"Round is canceled");
        require(_subQuestionOptionNames.length >= 2 && _subQuestionOptionNames.length <=3,"Invalid option names");

        subQuestionCount[_round] += 1;

        subQuestion[_round][subQuestionCount[_round]] = _question;
        subQuestionLockTime[_round][subQuestionCount[_round]] = _subQuestionLockTime;
        // adding option names
        for(uint256 i = 0;i < _subQuestionOptionNames.length;i++){
            subQuestionOptionName[_round][subQuestionCount[_round]][i+1] = _subQuestionOptionNames[i];
        }
    }

    // update round
   function updateQuestion(
        uint256 _round,
        string memory _roundTitle,
        string memory _roundBannerURL,
        string memory _roundCategory,
        string memory _roundTeam1LogoURL,
        string memory _roundTeam2LogoURL,
        string memory _roundTeam1Name,
        string memory _roundTeam2Name,
        uint256 _roundStartTime
    ) public onlyAdmin {

        require(_round <= totalGameRound, "Round does not exist");

        if (bytes(_roundTitle).length > 0) {
            roundTitle[_round] = _roundTitle;
        }

        if (bytes(_roundCategory).length > 0) {
            require(
                keccak256(bytes(_roundCategory)) == keccak256(bytes("cricket")) ||
                keccak256(bytes(_roundCategory)) == keccak256(bytes("football")),
                "Invalid category. Category should be one of cricket, football"
            );
            roundCategory[_round] = _roundCategory;
        }

        if (bytes(_roundBannerURL).length > 0) {
            roundBannerURL[_round] = _roundBannerURL;
        }

        if (bytes(_roundTeam1Name).length > 0) {
            roundTeam1Name[_round] = _roundTeam1Name;
        }

        if (bytes(_roundTeam2Name).length > 0) {
            roundTeam2Name[_round] = _roundTeam2Name;
        }

        if (bytes(_roundTeam1LogoURL).length > 0) {
            roundTeam1LogoURL[_round] = _roundTeam1LogoURL;
        }

        if (bytes(_roundTeam2LogoURL).length > 0) {
            roundTeam2LogoURL[_round] = _roundTeam2LogoURL;
        }
        
        if (_roundStartTime >0) {
            roundStartTime[_round] = _roundStartTime;
        }
        
    }

    // update question
    function updateSubQuestion(uint256 _round,uint256 _quest_no, string memory _question,string[] memory _subQuestionOptionNames,uint256 _subQuestionLockTime ) public onlyAdmin {
        require(_round <= totalGameRound,"Round does not exist");
        require(_quest_no <= subQuestionCount[_round],"Question does not exist");
        require(roundCanceled[_round] == false,"Round is canceled");
        require(_subQuestionOptionNames.length >= 2 && _subQuestionOptionNames.length <=3,"Invalid option names");

        if(bytes(_question).length > 0){
            subQuestion[_round][_quest_no] = _question;
        }

        if(_subQuestionOptionNames.length > 0){
            for(uint256 i = 0;i < _subQuestionOptionNames.length;i++){
                subQuestionOptionName[_round][_quest_no][i+1] = _subQuestionOptionNames[i];
            }
        }

        if(_subQuestionLockTime > 0){
            subQuestionLockTime[_round][_quest_no] = _subQuestionLockTime;
        }
    }


    // ONLY OWNER FUNCTIONS HERE ----------------------------------------------------------------

    // this function is to set the project fee address
    function setProjectFeeAddress(address _projectFeeAddress) external onlyOwner returns (bool) {
        projectFeeAddress = _projectFeeAddress;
        return true;
    }

    // this function is to set the project fee
    function setProjectFee(uint256 _projectFee) external onlyOwner returns (bool) {
        projectFee = _projectFee;
        return true;
    }

    // this function is to set the freeze time
    function setFreezeTime(
        uint256 _freezeTime
    ) external onlyOwner returns (bool) {
        freezeTime = _freezeTime;
        return true;
    }

    // this function is to pause the contract
    function pauseContract(bool _flag) external onlyOwner {
        isPaused = _flag;
    }

    // this function is to setAdmin
    function setAdmin(
        address _admin,
        bool _flag
    ) external onlyOwner returns (bool) {
        isAdmin[_admin] = _flag;
        return true;
    }

    // this function is to set the option count
    function setOptionCount(
        uint256 _optionCount
    ) external onlyOwner returns (bool) {
        optionCount = _optionCount;
        return true;
    }

    // this function is to set the claim freeze time
    function setClaimFreeze(
        uint256 _claimFreeze
    ) external onlyOwner returns (bool) {
        claimFreeze = _claimFreeze;
        return true;
    }

    // set token
    function setToken(address _tokenAddress) external onlyOwner returns (bool) {
        token = IERC20(_tokenAddress);
        return true;
    }

    // set token store wallet
    function setTokenStoreWallet(
        address _tokenStoreWallet
    ) external onlyOwner returns (bool) {
        tokenStoreWallet = _tokenStoreWallet;
        return true;
    }

    // THESE ARE EMERGENCY FUNCTIONS -----------------------------------------------------------
    // this function is to withdraw BNB
    function withdrawEth(uint256 _amount) external onlyOwner returns (bool) {
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        return success;
    }

    // this function is to withdraw tokens
    function withdrawBEP20(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        IERC20 _token = IERC20(_tokenAddress);
        bool success = _token.transfer(msg.sender, _amount);
        return success;
    }
}