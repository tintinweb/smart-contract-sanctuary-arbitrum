/**
 *Submitted for verification at Arbiscan.io on 2023-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// ----------------------------------------------------------------------------
//   @title PartyBet 
//   Guess to Earn
//
// ----------------------------------------------------------------------------
contract PartyBet {

    /// @notice bet record
    struct BetRecord {
        address betAddress;
        string issueNo;
        uint256 timestamp; 
        uint256 guessPrice;  
        uint256 betPrice;
    }

    /// @notice static / round
    struct IssueRecordStatic {
        uint256 orderNum; // count order
        uint256 pricePool;
        uint256 resultPrice; // open
    }

    /// @notice Join which round?  address => issueNo
    mapping(address => string[]) public personBetIssueRows;

    /// @notice static : keccak256(issueNo) => IssueRecordStatic
    mapping(uint256 => IssueRecordStatic) public issueRecordStaticRow;

    /// @notice Winners records. keccak256(issueNo) => BetRecord
    mapping(uint256 => BetRecord[]) public issueResultRows;

    /// @notice order records. keccak256(issueNo) => BetRecord
    mapping(uint256 => BetRecord[]) public issueBetRecordRows;

    /// @notice claim records. keccak256(issueNo) => {address => amount}
    mapping(uint256 => mapping(address => uint256)) public claimedRewards;

    /// @notice Will put in the prize pool
    uint256 public betPrice = 0.008 ether;

    /// @notice bet status ,
    bool public available = true;

    /// @notice fee: betFee / 100
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
        require(isTimeToDo(),"Closed. Wait for the next round!");
        require(guessPrice > 0, "Guess price must be greater than 0!");
        require(msg.value >= betPrice, "Not enough ETH sent for this request");

        string memory issueNo = getIssueNo();
        uint256 issueNoKey = makeUintKey(issueNo);
        require(issueResultRows[issueNoKey].length < 1, "This round have been closed! Wait for the next round! ");


        // make order
        BetRecord memory betRecord;
        betRecord.issueNo = issueNo;
        betRecord.betAddress = msg.sender;
        betRecord.timestamp = block.timestamp;
        betRecord.betPrice = msg.value;
        betRecord.guessPrice = guessPrice;

        ///
        issueBetRecordRows[issueNoKey].push(betRecord);
        personBetIssueRows[msg.sender].push(betRecord.issueNo);

        /// static
        IssueRecordStatic memory issueRecordStatic = issueRecordStaticRow[issueNoKey];
        issueRecordStatic.orderNum = issueRecordStatic.orderNum + 1;
        issueRecordStatic.pricePool = issueRecordStatic.pricePool + betRecord.betPrice;
        issueRecordStatic.resultPrice = 0;
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

        // find winner guess price
        uint winnerPirce = 0;
        uint winnerMarginPrice;
        uint betRecordMarginPrice;

        // compare price
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

        // save winner 
        for (uint i = 0; i < issueBetRecordRows[issueNoKey].length; i++) {
            if (issueBetRecordRows[issueNoKey][i].guessPrice == winnerPirce){
                issueResultRows[issueNoKey].push(issueBetRecordRows[issueNoKey][i]);
            }
        }

        emit OpenSuccess(msg.sender, resultPrice, issueNo);
    }  

    /// @notice compute rewards
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
        require(claimedRewards[issueNoKey][winnerAddress] < 1, "You have claimed.");

        uint winnerPercent = getWinnnerPercent(issueNo,winnerAddress);
        require(winnerPercent > 0, "There is no rewards for you!");

        /// My income . unit:Wei
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

    /// @notice get ruound number
    function getIssueNo() public view returns(string memory){
        uint256 timestamp = block.timestamp;
        uint year = BokkyPooBahsDateTimeLibrary.getYear(timestamp);
        uint month = BokkyPooBahsDateTimeLibrary.getMonth(timestamp);
        uint day = BokkyPooBahsDateTimeLibrary.getDay(timestamp);
        uint hour = BokkyPooBahsDateTimeLibrary.getHour(timestamp+3600);
        
        string memory issueNo = string(abi.encodePacked(
            uintToString(year), "-",
            uintToString(month), "-",
            uintToString(day), "-",
            uintToString(hour)
        ));
        return issueNo;
    }

    /// @notice Is time available
    function isTimeToDo()internal view returns (bool){
        uint256 timestamp = block.timestamp;
        uint minute = BokkyPooBahsDateTimeLibrary.getMinute(timestamp);
        if (minute > 55 || minute < 5){
            return false;
        }
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


library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}