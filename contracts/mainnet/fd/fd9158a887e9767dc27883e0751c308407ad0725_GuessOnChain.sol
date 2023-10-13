/**
 *Submitted for verification at Arbiscan.io on 2023-10-12
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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

contract GuessOnChain is Ownable {
    IERC20 token;

    bool public isPaused = false;

    uint256 public totalGameRound = 0;
    uint256 public projectFee = 10; // this value is in % of the pool size
    uint256 public freezeTime = 5 * 60; // this value is the time in seconds. This value means number of seconds the function is freezed
    uint256 public claimFreeze = 0;
    uint256 public optionCount = 2;

    address public projectFeeAddress;
    address public revenueFeeAddress;
    address public burnFeeAddress;
    address public tokenStoreWallet;

    struct Transaction {
        uint256 gameId;
        address user;
        uint256 betted;
        uint256 amount;
    }   

    struct questionType {
        uint256 round;
        string roundDescription;
        uint256 option1Bet;
        uint256 option2Bet;
        string question;
        string roundCategory;
        string roundQuestionImageUrl;
        uint256 roundPoolSize;
        uint256 roundEndTime;
        uint256 roundResultTime;
    }

    struct BetDetails {
        uint256 betAmount;
        uint256 betOption;
        uint256 round;
        uint256 result;
    }

    struct resultType {
        uint256 result;
        uint256 round;
        string question;
        string roundQuestionImageUrl;
        string roundCategory;
        uint256 roundPoolSize;
        uint256 roundEndTime;
        uint256 roundResultTime;
    }

    Transaction[] public recentTransactions;
    address[] users;
    uint256[] roundResultOrder;

    mapping(address => bool) public isAdmin;
    mapping(uint256 => string) public roundQuestion;
    mapping(uint256 => string) public roundDescription;
    mapping(uint256 => string) public roundCategory;
    mapping(uint256 => string) public roundQuestionImageUrl;
    mapping(uint256 => uint256) public roundPoolSize;
    mapping(uint256 => uint256) public roundTotalBets;
    mapping(uint256 => uint256) public roundResult;
    mapping(uint256 => uint256) public roundEndTime;
    mapping(uint256 => uint256) public roundResultTime;
    mapping(address => bool) public userAddresses;
    mapping(uint256 => mapping(uint256 => uint256)) public roundOptionBet;
    mapping(uint256 => mapping(uint256 => uint256)) public roundOptionBetCount;
    mapping(address => mapping(uint256 => uint256)) public userRoundBet;
    mapping(address => mapping(uint256 => uint256)) public userRoundAmount;
    mapping(address => mapping(uint256 => uint256))
        public userRoundClaimedAmount;

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
        token = IERC20(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);
        projectFeeAddress = 0x5Ff4c7A335ecBF4566beb4fa8de2e050A3f65c2E;
        revenueFeeAddress = 0x83538c6A03DCd882F0269a7EC875D1d52fE0ad94;
        burnFeeAddress = 0xED0E6CE35ca165cb061450ea4A5061804D358Def;
        isAdmin[msg.sender] = true;
        tokenStoreWallet = address(this);

    }

    function placeBet(uint256 _round,uint256 _amount,uint256 _betOption) public isPausable {
        require(_round <= totalGameRound && _round > 0, "Invalid round");
        require(_betOption <= optionCount && _betOption > 0, "Invalid Option");
        require(_amount > 0, "Amount must be greater than 0");
        require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(roundEndTime[_round] > block.timestamp, "Betting time is over");

        if (userRoundBet[msg.sender][_round] > 0) {
            require(userRoundBet[msg.sender][_round] == _betOption,"You can not change your choice");
        }

        token.transferFrom(msg.sender, tokenStoreWallet, _amount);

        roundPoolSize[_round] += _amount;
        roundTotalBets[_round] += 1;

        if (userRoundAmount[msg.sender][_round] == 0) {
            roundOptionBetCount[_round][_betOption] += 1;
        }

        if (!userAddresses[msg.sender]) {
            users.push(msg.sender);
        }

        userAddresses[msg.sender] = true;
        userRoundBet[msg.sender][_round] = _betOption;
        userRoundAmount[msg.sender][_round] += _amount;
        roundOptionBet[_round][_betOption] += _amount;

        recentTransactions.push(
            Transaction(_round, msg.sender, _betOption, _amount)
        );
    }

    function claimReward(uint256 _round) public isPausable {
        require(claimFreeze < block.timestamp,"Claiming is not allowed. Wait for some time");
        require(_round <= totalGameRound && _round > 0, "Invalid round");

        uint256 _claimableRewards = claimableReward(msg.sender, _round);
        require(_claimableRewards > 0, "No rewards to claim");

        userRoundClaimedAmount[msg.sender][_round] += _claimableRewards;

        if (tokenStoreWallet == address(this)) {
            token.transfer(msg.sender, _claimableRewards);
        } else {
            token.transferFrom(tokenStoreWallet, msg.sender, _claimableRewards);
        }
    }



    // ALL VIEW FUNCTIONS HERE ----------------------------------------------------------------

    function claimableReward(address _user, uint256 _round) public view returns (uint256 _amount){
        require(_round <= totalGameRound && _round > 0, "Invalid round");
        // if the result is 0, then the user will get refund
        uint256 _reward = 0;
        if (roundResult[_round] == 0) return 0;
        if (roundResult[_round] != userRoundBet[_user][_round]) return 0; // if the user betted on non winning option, then he will not get any refund

        uint256 _roundResult = roundResult[_round];

        uint256 _totalBet = roundPoolSize[_round];
        uint256 _projectFee = (roundPoolSize[_round] * projectFee) / 100;
        uint256 _claimableAmount = ((_totalBet - _projectFee) *
            userRoundAmount[_user][_round]) /
            roundOptionBet[_round][_roundResult];


        if(_claimableAmount > userRoundClaimedAmount[_user][_round]){
            _reward = _claimableAmount - userRoundClaimedAmount[_user][_round];
        }else{
            return 0;
        }

        return _reward;
    }

    // get recent n transactions
    function getRecentTransactions(uint256 n) public view returns (Transaction[] memory){

        uint256 _length = recentTransactions.length;
        uint256 _start = _length > n ? _length - n : 0;
        Transaction[] memory _recentTransactions = new Transaction[](
            _length - _start
        );
        for (uint256 i = _start; i < _length; i++) {
            _recentTransactions[i - _start] = recentTransactions[i];
        }
        return _recentTransactions;
    }

    // get particaular round transactions
    function getRoundTransactions(uint256 _round) public view returns (Transaction[] memory){
        require(_round <= totalGameRound && _round > 0, "Invalid round");

        uint256 _length = recentTransactions.length;
        Transaction[] memory _roundTransactions = new Transaction[](_length);
        for (uint256 i = 0; i < _length; i++) {
            if (recentTransactions[i].gameId == _round) {
                _roundTransactions[i + 1] = recentTransactions[i + 1];
            }
        }
        return _roundTransactions;
    }

    // get recent transactions of a user
    function getUserTransactions(address _user, uint256 n) public view returns (Transaction[] memory){
        require(_user != address(0), "Invalid user address");

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

    // get recent n transactions for round
    function getRecentRoundTransactions(uint256 _round, uint256 n) public view returns (Transaction[] memory){
        require(_round <= totalGameRound && _round > 0, "Invalid round");

        uint256 _length = recentTransactions.length;
        uint256 count = 0;

        // Create a dynamic array to store the transactions
        Transaction[] memory _roundTransactions = new Transaction[](n);

        // Iterate through the transactions in reverse order
        for (int256 i = int256(_length) - 1; i >= 0 && count < n; i--) {
            if (recentTransactions[uint256(i)].gameId == _round) {
                _roundTransactions[count] = recentTransactions[uint256(i)];
                count++;
            }
        }

        return _roundTransactions;
    }

    // get recent n

    // get recent n game results
    function getRecentGameResults(uint256 n) public view returns (uint256[][] memory){
        uint256 _length = totalGameRound;
        uint256 _start = _length > n ? _length - n : 0;
        uint256[][] memory _recentGameResults = new uint256[][](
            _length - _start
        );
        for (uint256 i = _start; i < _length; i++) {
            uint256[] memory _result = new uint256[](2);
            _result[0] = i;
            _result[1] = roundResult[i];
            _recentGameResults[i - _start] = _result;
        }
        return _recentGameResults;
    }

    // get total games done
    function getTotalGames() public view returns (uint256) {
        return totalGameRound;
    }

    // get total rewards distributed
    function getTotalRewardsDistributed() public view returns (uint256) {
        uint256 _totalRewards = 0;
        for (uint256 i = 0; i < totalGameRound; i++) {
            // check if result declared
            if (roundResult[i] == 0) continue;
            _totalRewards += roundPoolSize[i];
        }
        return _totalRewards;
    }

    // get all rounds pool size and pool ids
    function getAllRoundsPoolSize() public view returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory _poolSize = new uint256[](totalGameRound);
        uint256[] memory _poolIds = new uint256[](totalGameRound);
        for (uint256 i = 0; i < totalGameRound; i++) {
            _poolSize[i] = roundPoolSize[i];
            _poolIds[i] = i;
        }
        return (_poolSize, _poolIds);
    }

    // get all user claimed amounts and user addresses
    function getAllUserClaimedAmounts() public view returns (uint256[] memory, address[] memory){
        uint256[] memory _claimedAmounts = new uint256[](users.length);
        address[] memory _userAddresses = new address[](users.length);
        uint256 _count = 0;

        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 _round = 1; _round <= totalGameRound; _round++) {
                if (roundResultTime[_round] > block.timestamp) continue;
                uint256 _reward = userRoundClaimedAmount[users[i]][_round];
                if (_reward > 0) {
                    _userAddresses[_count] = users[i];
                    _claimedAmounts[_count] += _reward;
                }
            }
            _count++;
        }
        return (_claimedAmounts, _userAddresses);
    }

    function getAllUserRoundClaimedAmounts(uint256 _round) public view returns (address[] memory, uint256[] memory)
    {
        uint256[] memory _claimedAmounts = new uint256[](users.length);
        address[] memory _userAddresses = new address[](users.length);
        uint256 _count = 0;

        for (uint256 i = 0; i < users.length; i++) {
            uint256 _reward = userRoundClaimedAmount[users[i]][_round];
            if (_reward > 0) {
                _userAddresses[_count] = users[i];
                _claimedAmounts[_count] += _reward;
                _count++;
            }
        }

        assembly {
            mstore(_userAddresses, _count)
            mstore(_claimedAmounts, _count)
        }

        return (_userAddresses, _claimedAmounts);
    }

    // get all user user addresses, betted amount, and betted option for a particular round
    function getAllUserBettedAmounts(uint256 _round) public view returns (address[] memory,uint256[] memory,uint256[] memory){
        uint256[] memory _bettedAmounts = new uint256[](users.length);
        uint256[] memory _bettedOptions = new uint256[](users.length);
        address[] memory _userAddresses = new address[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            _bettedAmounts[i] = userRoundAmount[users[i]][_round];
            _bettedOptions[i] = userRoundBet[users[i]][_round];
            _userAddresses[i] = users[i];
        }
        return (_userAddresses, _bettedAmounts, _bettedOptions);
    }

    // get all result rounds in order of declaration and declared results
    function getAllResultRounds() public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory _resultRounds = new uint256[](roundResultOrder.length);
        uint256[] memory _resultValues = new uint256[](roundResultOrder.length);
        for (uint256 i = 0; i < roundResultOrder.length; i++) {
            _resultRounds[i] = roundResultOrder[i];
            _resultValues[i] = roundResult[roundResultOrder[i]];
        }
        return (_resultRounds, _resultValues);
    }

    function getRecentResult() public view returns (resultType[] memory) {
        uint256 count = 0;
        uint256 _start = roundResultOrder.length > 10 ? roundResultOrder.length - 10 : 0;
        uint256 _end = roundResultOrder.length > 0 ? roundResultOrder.length - 1 : 0;

        resultType[] memory results = new resultType[](_end - _start + 1);

        for (uint256 i = _start; i <= _end; i++) {
            results[count] = resultType({
                round: roundResultOrder[i],
                result: roundResult[roundResultOrder[i]],
                question: roundQuestion[roundResultOrder[i]],
                roundEndTime: roundEndTime[roundResultOrder[i]],
                roundPoolSize: roundPoolSize[roundResultOrder[i]],
                roundCategory: roundCategory[roundResultOrder[i]],
                roundResultTime: roundResultTime[roundResultOrder[i]],
                roundQuestionImageUrl: roundQuestionImageUrl[
                    roundResultOrder[i]
                ]
            });
            count++;
        }

        assembly {
            mstore(results, count)
        }

        return results;
    }

    // get all user betted amount list and betted option list for a particular round
    function getAllUserBettedAmountsList(uint256 _round) public view returns (uint256[] memory, uint256[] memory){
        uint256[] memory _bettedAmounts = new uint256[](users.length);
        uint256[] memory _bettedOptions = new uint256[](users.length);
        for (uint256 i = 0; i < users.length; i++) {
            _bettedAmounts[i] = userRoundAmount[users[i]][_round];
            _bettedOptions[i] = userRoundBet[users[i]][_round];
        }
        return (_bettedAmounts, _bettedOptions);
    }

    function getRoundResult(uint256 _round) public view returns (uint256) {
        return roundResult[_round];
    }

    function getUserBetDetails(address _user, uint256 _round) public view returns (BetDetails memory){
        return BetDetails({
                betAmount: userRoundAmount[_user][_round],
                betOption: userRoundBet[_user][_round],
                round: _round,
                result: roundResult[_round]
            });
    }

    function getAllQuestions() public view returns (questionType[] memory) {
        questionType[] memory _allQuestions = new questionType[](totalGameRound);

        for (uint256 _roundNumber = 1;_roundNumber <= totalGameRound;_roundNumber++) {
            uint256 _option1Bet = roundOptionBet[_roundNumber][1];
            uint256 _option2Bet = roundOptionBet[_roundNumber][2];

            _allQuestions[_roundNumber - 1] = questionType({
                round: uint256(_roundNumber),
                option1Bet: _option1Bet,
                option2Bet: _option2Bet,
                question: roundQuestion[_roundNumber],
                roundDescription:roundDescription[_roundNumber],
                roundCategory: roundCategory[_roundNumber],
                roundEndTime: roundEndTime[_roundNumber],
                roundPoolSize: roundPoolSize[_roundNumber],
                roundResultTime: roundResultTime[_roundNumber],
                roundQuestionImageUrl: roundQuestionImageUrl[_roundNumber]
            });
        }

        return _allQuestions;
    }

    function getQuestion(uint256 _roundNumber) public view returns (questionType memory) {
        require(_roundNumber <= totalGameRound && _roundNumber > 0, "Invalid round");

        uint256 _option1Bet = roundOptionBet[_roundNumber][1];
        uint256 _option2Bet = roundOptionBet[_roundNumber][2];

        return
            questionType({
                round: uint256(_roundNumber),
                option1Bet: _option1Bet,
                option2Bet: _option2Bet,
                question: roundQuestion[_roundNumber],
                roundDescription: roundDescription[_roundNumber],
                roundCategory: roundCategory[_roundNumber],
                roundEndTime: roundEndTime[_roundNumber],
                roundPoolSize: roundPoolSize[_roundNumber],
                roundResultTime: roundResultTime[_roundNumber],
                roundQuestionImageUrl: roundQuestionImageUrl[_roundNumber]
            });
    }

    function isUserClaimedAmount(address _user, uint256 _round) public
        view
        returns (uint256)
    {
        return userRoundClaimedAmount[_user][_round];
    }


    

    // ADMIN FUNCTIONS HERE ----------------------------------------------------------------

    // announce results
    function announceResult(uint256 _round, uint256 _result) external onlyAdmin{
        require(roundResult[_round] == 0, "Result already declared");
        require(_round <= totalGameRound && _round > 0, "Invalid round");
        require(_result <= optionCount && _result > 0, "Invalid result");
        require(roundResultTime[_round] < block.timestamp, "Result time not reached");

        roundResult[_round] = _result;

        // send game owner fees
        uint256 _fees = (roundPoolSize[_round] * projectFee) / 100;

        uint256 _revenue_fees = (_fees * 80) /100;
        uint256 _burn_fees = (_fees * 20) /100;


        if (tokenStoreWallet == address(this)) {
            token.transfer(revenueFeeAddress, _revenue_fees);
            token.transfer(burnFeeAddress, _burn_fees);
        } else {
            token.transferFrom(tokenStoreWallet, revenueFeeAddress,_revenue_fees);
            token.transferFrom(tokenStoreWallet, burnFeeAddress,_burn_fees);
        }

        roundResultOrder.push(_round);
    }

    // this function is to override result
    function overrideResult(uint256 _round, uint256 _result)external onlyAdmin {
        require(_round <= totalGameRound && _round > 0, "Invalid round");
        require(roundResult[_round] != 0, "Result not declared");
        require(_result <= optionCount && _result > 0, "Invalid result");

        roundResult[_round] = _result;
    }

    function addQuestion(string memory _question,string memory _roundDescription, string memory _imageURL,string memory _category,uint256 _roundEndTime,uint256 _roundResultTime) public onlyAdmin {

        require(validateCategory(_category), "Invalid category. category should be one of price-action, sports, news&politics, events, market-cap");

        totalGameRound += 1;

        roundPoolSize[totalGameRound] = 0;
        roundCategory[totalGameRound] = _category;
        roundQuestion[totalGameRound] = _question;
        roundDescription[totalGameRound]=_roundDescription;
        roundQuestionImageUrl[totalGameRound] = _imageURL;
        roundEndTime[totalGameRound] = _roundEndTime * 1 hours + block.timestamp;
        roundResultTime[totalGameRound] = _roundResultTime * 1 hours + block.timestamp;
    }

    // this function is to update question
    function updateQuestion(uint256 _round,string memory _question,string memory _roundDescription,string memory _imageURL,string memory _category,uint256 _roundEndTime,uint256 _roundResultTime) public onlyAdmin {
        require(_round <= totalGameRound && _round > 0, "Invalid round");
        // Ensure the category is valid


        if(bytes(_category).length > 0){
            require(validateCategory(_category), "Invalid category. category should be one of price-action, sports, news&politics, events, market-cap");
            roundCategory[_round] = _category;
        }

        if(bytes(_question).length > 0){
            roundQuestion[_round] = _question;
        }

        if(bytes(_roundDescription).length > 0){
            roundDescription[_round] = _roundDescription;
        }

        if(bytes(_imageURL).length > 0){
            roundQuestionImageUrl[_round] = _imageURL;
        }

        if(_roundEndTime > 0){
            roundEndTime[_round] = _roundEndTime * 1 hours + block.timestamp;
        }

        if(_roundResultTime > 0){
            roundResultTime[_round] = _roundResultTime * 1 hours + block.timestamp;
        }   

    }

    // this function validate the category
    function validateCategory(string memory _category) internal pure returns (bool) {
        // Ensure the category is valid
        if (
            keccak256(bytes(_category)) == keccak256(bytes("price-action")) ||
            keccak256(bytes(_category)) == keccak256(bytes("sports")) ||
            keccak256(bytes(_category)) == keccak256(bytes("news&politics")) ||
            keccak256(bytes(_category)) == keccak256(bytes("events")) ||
            keccak256(bytes(_category)) == keccak256(bytes("market-cap"))
        ) {
            return true;
        } else {
            return false;
        }
    }


    // ONLY OWNER FUNCTIONS HERE ----------------------------------------------------------------

    // this function is to set the project fee address
    function setProjectFeeAddress(address _projectFeeAddress) external onlyOwner returns (bool)
    {
        projectFeeAddress = _projectFeeAddress;
        return true;
    }

    // this function is to set the revenue fee address
    function setRevenueFeeAddress(address _revenueFeeAddress)
        external
        onlyOwner
        returns (bool)
    {
        revenueFeeAddress = _revenueFeeAddress;
        return true;
    }

    // this function is to set the burn fee address
    function setBurnFeeAddress(address _burnFeeAddress)
        external
        onlyOwner
        returns (bool)
    {
        burnFeeAddress = _burnFeeAddress;
        return true;
    }

    // this function is to set the project fee
    function setProjectFee(uint256 _projectFee)
        external
        onlyOwner
        returns (bool)
    {
        projectFee = _projectFee;
        return true;
    }

    // this function is to set the freeze time
    function setFreezeTime(uint256 _freezeTime)
        external
        onlyOwner
        returns (bool)
    {
        freezeTime = _freezeTime;
        return true;
    }

    // this function is to pause the contract
    function pauseContract(bool _flag) external onlyOwner {
        isPaused = _flag;
    }

    // this function is to setAdmin
    function setAdmin(address _admin, bool _flag)
        external
        onlyOwner
        returns (bool)
    {
        isAdmin[_admin] = _flag;
        return true;
    }

    // this function is to set the option count
    function setOptionCount(uint256 _optionCount)
        external
        onlyOwner
        returns (bool)
    {
        optionCount = _optionCount;
        return true;
    }

    // this function is to set the claim freeze time
    function setClaimFreeze(uint256 _claimFreeze)
        external
        onlyOwner
        returns (bool)
    {
        claimFreeze = _claimFreeze;
        return true;
    }

    // set token
    function setToken(address _tokenAddress) external onlyOwner returns (bool) {
        token = IERC20(_tokenAddress);
        return true;
    }

    // set token store wallet
    function setTokenStoreWallet(address _tokenStoreWallet)
        external
        onlyOwner
        returns (bool)
    {
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
    function withdrawBEP20(address _tokenAddress, uint256 _amount)
        external
        onlyOwner
        returns (bool)
    {
        IERC20 _token = IERC20(_tokenAddress);
        bool success = _token.transfer(msg.sender, _amount);
        return success;
    }
}