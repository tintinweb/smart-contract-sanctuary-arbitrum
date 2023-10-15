/**
 *Submitted for verification at Arbiscan.io on 2023-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title PartyBet 
 * Guess to Earn
 */
 contract PartyBet {

    /// @notice bet record
    struct BetRecord {
        address betAddress;
        string issueNo;
        uint256 timestamp; 
        uint256 guessPrice;  
        uint256 betPrice;
    }

    /// @notice 每期统计
    struct IssueRecordStatic {
        uint256 orderNum; // 下单数量
        uint256 pricePool;
        uint256 resultPrice; // 开奖价格，default:0 未开奖  
    }

    /// @notice 个人在哪期下过单. address => issueNo
    mapping(address => string[]) public personBetIssueRows;

    /// @notice 每期的下单数据统计. keccak256(issueNo) => IssueRecordStatic
    mapping(uint256 => IssueRecordStatic) public issueRecordStaticRow;

    /// @notice Winners : 每期的中奖记录. keccak256(issueNo) => BetRecord
    mapping(uint256 => BetRecord[]) public issueResultRows;

    /// @notice 每期的记录 keccak256(issueNo) => BetRecord
    mapping(uint256 => BetRecord[]) public issueBetRecordRows;

    /// @notice 每期的领奖 keccak256(issueNo) => {address => amount}
    mapping(uint256 => mapping(address => uint256)) public claimedRewards;

    /// @notice Will put in the prize pool
    uint256 public betPrice = 0.008 ether;

    /// @notice bet status , 整点前后5分钟不能下注
    bool public available = true;

    /// @notice 提取费率 betFee / 100
    uint256 public betFee = 10;

    /// @notice Addresses of super operators
    mapping(address => bool) private  superOperators;

     /// @notice Requires sender to be contract super operator
    modifier onlyAdmin() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }

    /// @notice Emitted after claim rewards
    event ClaimSuccess(address operator, uint256 amount);

    /// @notice Emitted after guess
    event GuessSuccess(address operator, uint256 guessPrice, uint256 betPrice, string issueNo, uint256 pricePool);

     /// @notice Emitted after open 
    event OpenSuccess(address operator, uint256 resultPrice, string issueNo);

    /// @notice Emitted after super operator is updated
    event AuthorizedOperator(address indexed operator, address indexed holder);

    /// @notice Emitted after super operator is updated
    event RevokedOperator(address indexed operator, address indexed holder);

    /// Initial 
    constructor() {
        superOperators[msg.sender] = true;
    }

    // 
    //  @notice guess BTC price
    //  @param guessPrice 2500002 = 25000.02
    //  
    function guess(
        uint256 guessPrice
    ) public payable  {
        require(available, "Have Been Closed.");
        require(isItTimeToDo(),"Closed. Wait for the next round!");
        require(guessPrice > 0, "Guess price must be greater than 0!");
        require(msg.value >= betPrice, "Not enough ETH sent for this request");

        string memory issueNo = getIssueNo();
        uint256 issueNoKey = makeUintKey(issueNo);
        require(issueResultRows[issueNoKey].length < 1, "This round have been closed! Wait for the next round! ");


        // 登记本次下注， XXX期，地址，下注金额
        BetRecord memory betRecord;
        betRecord.issueNo = issueNo;
        betRecord.betAddress = msg.sender;
        betRecord.timestamp = block.timestamp;
        betRecord.betPrice = msg.value;
        betRecord.guessPrice = guessPrice;

        /// 登记我的下注记录 
        issueBetRecordRows[issueNoKey].push(betRecord);
        /// 登记我参与的期号
        personBetIssueRows[msg.sender].push(betRecord.issueNo);

        /// 统计数据
        IssueRecordStatic memory issueRecordStatic = issueRecordStaticRow[issueNoKey];
        issueRecordStatic.orderNum = issueRecordStatic.orderNum + 1;
        issueRecordStatic.pricePool = issueRecordStatic.pricePool + betRecord.betPrice;
        issueRecordStatic.resultPrice = 0; // 初始数据
        /// save to issueRecordStatic
        issueRecordStaticRow[issueNoKey] = issueRecordStatic;

        /// 
        emit GuessSuccess(msg.sender, guessPrice, betPrice, betRecord.issueNo, issueRecordStatic.pricePool);
        
    }

    /// @notice Chainlink Keepers Job Scheduler 
    /// @param resultPrice 2500001 = 25000.01
    function open(uint256 resultPrice, string memory issueNo) public onlyAdmin {
        uint256 issueNoKey = makeUintKey(issueNo);
        require(resultPrice > 0, "Price must be greater than 0!");
        require(issueResultRows[issueNoKey].length < 1, "This round have been opened!");

        require(issueRecordStaticRow[issueNoKey].orderNum > 0, "There is incorrect issue number.");
        issueRecordStaticRow[issueNoKey].resultPrice = resultPrice;

        // 计算中奖用户
        uint winnerPirce = 0;
        uint winnerMarginPrice;
        uint betRecordMarginPrice;

        // 比较价格, 并找出中奖价格
        for (uint i = 0; i < issueBetRecordRows[issueNoKey].length; i++) {
            if (i == 0) {
                winnerPirce = issueBetRecordRows[issueNoKey][i].guessPrice;
                continue;
            }

            winnerMarginPrice = absSub(winnerPirce ,resultPrice);
            betRecordMarginPrice = absSub(issueBetRecordRows[issueNoKey][i].guessPrice ,resultPrice);
            if(winnerMarginPrice > betRecordMarginPrice){
                winnerPirce = issueBetRecordRows[issueNoKey][i].guessPrice;
            }
        }

        // 登记相同价格的记录
        for (uint i = 0; i < issueBetRecordRows[issueNoKey].length; i++) {
            if (issueBetRecordRows[issueNoKey][i].guessPrice == winnerPirce){
                issueResultRows[issueNoKey].push(issueBetRecordRows[issueNoKey][i]);
            }
        }

        emit OpenSuccess(msg.sender, resultPrice, issueNo);
    }  

    /// @notice 计算各地址的中奖占比, 并返回查询结果
    function getWinnnerPercent(string memory issueNo, address winnerAddress) internal view returns (uint){
        uint256 issueNoKey = makeUintKey(issueNo);
        uint total = issueResultRows[issueNoKey].length;
        require(total > 0 , "This issue number is incorrect !");
        
        // BetRecord memory betRecord;
        uint winnerCounter = 0;
        for (uint i = 0; i < issueResultRows[issueNoKey].length; i++) {
            if( issueResultRows[issueNoKey][i].betAddress == winnerAddress ){
                winnerCounter ++;
            }
        }
        
        return (winnerCounter/total);
    }

    /// @notice claim rewards
    function claim(string memory issueNo) public {
        uint256 issueNoKey = makeUintKey(issueNo);
        require(issueRecordStaticRow[issueNoKey].orderNum > 0, "This issue number is incorrect!");
        address winnerAddress = msg.sender;
        /// 检查我是否claim过了
        require(claimedRewards[issueNoKey][winnerAddress] < 1, "You have claimed.");

        uint winnerPercent = getWinnnerPercent(issueNo,winnerAddress);
        require(winnerPercent > 0, "There is no rewards for you!");

        
        /// 我的收益 Wei 计算
        uint256 totalRewards = issueRecordStaticRow[issueNoKey].pricePool * (100-betFee) / 100;
        uint256 myRewards = totalRewards * winnerPercent;
        require(myRewards > 0, "Your rewards is incorrect!");


        uint256 balance = address(this).balance;
        require(balance > myRewards, "Balance is not enough!");

        // transfer to winner
        payable(winnerAddress).transfer(myRewards);
        // set status
        claimedRewards[issueNoKey][winnerAddress] = myRewards;

        /// 
        emit ClaimSuccess(winnerAddress, myRewards);

    }

    // abssub
    function absSub(uint256 _a,uint256 _b) public pure returns (uint256) {
        if(_a > _b){
            return _a - _b;
        }else{
            return _b - _a;
        }
    }

    // make stringKey
    function makeUintKey(string memory issueNo) public pure returns (uint256) {
        bytes32 issueNoKey = keccak256(bytes(issueNo));
        return uint256(issueNoKey);
    } 

    /// @notice 获取本期期号
    function getIssueNo() public view returns(string memory){
        uint256 timestamp = block.timestamp;
        uint256 year = (timestamp / 31536000) + 1970;
        uint256 month = (timestamp % 31536000) / 2628000;
        uint256 day = (timestamp % 2628000) / 86400;
        uint256 hour = (timestamp % 86400 + 3600) / 3600;
        
        string memory issueNo = string(abi.encodePacked(
            uintToString(year), "-",
            uintToString(month), "-",
            uintToString(day), "-",
            uintToString(hour)
        ));
        return issueNo;
    }

    /// @notice Is time available
    function isItTimeToDo()internal pure returns (bool){
        return true;
    }

    /// @notice unit convert to string
    function uintToString(uint256 num) internal pure returns (string memory) {
        if (num == 0) {
            return "0";
        }
        uint256 len;
        uint256 temp = num;
        while (temp != 0) {
            len++;
            temp /= 10;
        }
        bytes memory str = new bytes(len);
        temp = num;
        while (temp != 0) {
            len--;
            str[len] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(str);
    }

    /// @notice set bet fee for PartyBet
    function setBetFee(uint256 _betFee) public onlyAdmin {
        betFee = _betFee;
    }

    /// @notice set bet price for PartyBet
    function setBetPrice(uint256 _price) public onlyAdmin {
        betPrice = _price;
    }

    /// @notice set bet available for PartyBet
    function setBetAvailable(bool _available) public onlyAdmin {
        available = _available;
    }

    /// @notice Allows receiving ETH
    receive() external payable {}

    /**
     * Allow withdraw of ETH tokens from the contract
     */
    function withdrawETH(address recipient) public onlyAdmin {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");
        payable(recipient).transfer(balance);
    }

    /// @notice Allows super operator to update super operator
    function authorizeOperator(address _operator) external onlyAdmin {
        superOperators[_operator] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Allows super operator to update super operator
    function revokeOperator(address _operator) external onlyAdmin {
        superOperators[_operator] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

    function getBalance() public view returns(uint256) {
        return  address(this).balance;
    }

 }