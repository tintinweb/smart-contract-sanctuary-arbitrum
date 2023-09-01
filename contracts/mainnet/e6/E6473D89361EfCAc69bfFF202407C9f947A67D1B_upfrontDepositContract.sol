/**
 *Submitted for verification at Arbiscan.io on 2023-08-31
*/

// SPDX-License-Identifier: MIT

/*
   __  __      ____                 __ 
  / / / /___  / __/________  ____  / /_
 / / / / __ \/ /_/ ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ /  / /_/ / / / / /_  
\____/ .___/_/ /_/   \____/_/ /_/\__/  
    /_/                                

  Deposit Smart-Contract

  Authors: <MagicFormula | function Y()> and <dotfx>
  Date: 2023/08/31
  Version: 1.0.12-arbitrum
  Web: https://upfrontdefi.com/
*/

pragma solidity >=0.8.18 <0.9.0;

library DateTime {
  uint256 constant OFFSET_1970_01_01 = 2440588;
  uint256 constant SECONDS_IN_MINUTE = 60;
  uint256 constant SECONDS_IN_HOUR = 3600;
  uint256 constant SECONDS_IN_DAY = 86400;
  uint256 constant SECONDS_IN_YEAR = 31536000;
  uint256 constant SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR = 126230400;
  uint256 constant SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999 = 883612800;
  uint256 constant SECONDS_IN_100_YEARS = 3155673600;
  uint256 constant SECONDS_IN_400_YEARS = 12622780800;

  function convertYMDHMStoTimestamp(uint16 _year, uint8 _month, uint8 _day, uint8 _hour, uint8 _minute, uint8 _second) internal pure returns (uint256 ts) {
    ts = addYearSeconds(ts, _year);

    unchecked {
      ts += addMonthSeconds(_year, _month);
      ts += (_day - 1) * SECONDS_IN_DAY;
      ts += _hour * SECONDS_IN_HOUR;
      ts += _minute * SECONDS_IN_MINUTE;
      ts += uint256(_second);
    }
  }

  function addYearSeconds(uint256 _ts, uint16 _year) internal pure returns (uint256 ts) {
    uint16 yearCounter;
    ts = _ts;

    unchecked {
      if (_year < 1972) {
        ts += (_year - 1970) * SECONDS_IN_YEAR;
      } else {
        ts += 2 * SECONDS_IN_YEAR;
        yearCounter = 1972;

        if (_year >= 2000) {
          ts += SECONDS_BETWEEN_JAN_1_1972_AND_DEC_31_1999;
          yearCounter = 2000;

          (yearCounter, ts) = incrementYearAndTimestamp(_year, yearCounter, ts, 400, SECONDS_IN_400_YEARS);
          (yearCounter, ts) = incrementLeapYear(_year, yearCounter, ts);
          (yearCounter, ts) = incrementYearAndTimestamp(_year, yearCounter, ts, 100, SECONDS_IN_100_YEARS);
        }

        (yearCounter, ts) = incrementYearAndTimestamp(_year, yearCounter, ts, 4, SECONDS_IN_FOUR_YEARS_WITH_LEAP_YEAR);
        (yearCounter, ts) = incrementLeapYear(_year, yearCounter, ts);
        (yearCounter, ts) = incrementYearAndTimestamp(_year, yearCounter, ts, 1, SECONDS_IN_YEAR);
      }
    }
  }

  function incrementLeapYear(uint16 _year, uint16 _yearCounter, uint256 _ts) internal pure returns (uint16 yearCounter, uint256 ts) {
    yearCounter = _yearCounter;
    ts = _ts;

    unchecked {
      if ((yearCounter < _year) && isLeapYear(yearCounter)) {
        yearCounter += 1;
        ts += SECONDS_IN_YEAR + SECONDS_IN_DAY;
      }
    }
  }

  function incrementYearAndTimestamp(uint16 _year, uint16 _yearCounter, uint256 _ts, uint16 _divisor, uint256 _seconds) internal pure returns (uint16 year, uint256 ts) {
    unchecked {
      uint256 res = uint256((_year - _yearCounter) / _divisor);
      year = uint16(_yearCounter + (res * _divisor));
      ts = _ts + (res * _seconds);
    }
  }

  function isLeapYear(uint16 _year) internal pure returns (bool) {
    if ((_year % 4) != 0) { return false; }
    if (((_year % 400) == 0) || ((_year % 100) != 0)) { return true; }

    return false;
  }

  function addMonthSeconds(uint16 _year, uint8 _month) internal pure returns (uint256) {
    uint32[13] memory monthSecondsMap = isLeapYear(_year) ? [ 0, 2678400, 5184000, 7862400, 10454400, 13132800, 15724800, 18403200, 21081600, 23673600, 26352000, 28944000, 31622400 ] : [ 0, 2678400, 5097600, 7776000, 10368000, 13046400, 15638400, 18316800, 20995200, 23587200, 26265600, 28857600, 31536000 ];

    return uint256(monthSecondsMap[_month - 1]);
  }

  function daysToDate(uint256 d) internal pure returns (uint256 year, uint256 month, uint256 day) {
    unchecked {
      uint256 L = d + 68569 + OFFSET_1970_01_01;
      uint256 N = 4 * L / 146097;

      L = L - (146097 * N + 3) / 4;
      year = 4000 * (L + 1) / 1461001;
      L = L - 1461 * year / 4 + 31;
      month = 80 * L / 2447;
      day = L - 2447 * month / 80;
      L = month / 11;
      month = month + 2 - 12 * L;
      year = 100 * (N - 49) + year + L;
    }
  }

  function getYearMonthDay(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
    unchecked {
      (year, month, day) = daysToDate(timestamp / SECONDS_IN_DAY);
    }
  }
}

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

abstract contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _setOwner(msg.sender);
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier isOwner() virtual {
    require(msg.sender == _owner, "Not owner");

    _;
  }

  function renounceOwnership() external virtual isOwner {
    _setOwner(address(0));
  }

  function transferOwnership(address newOwner) external virtual isOwner {
    require(newOwner != address(0));

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract ReentrancyGuard is Ownable {
  bool internal locked;

  modifier nonReEntrant() {
    require(!locked, "No re-entrancy");

    locked = true;
    _;
    locked = false;
  }
}

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface upfrontMultiSignatureWallet {
  function listManagers(bool) external view returns (address[] memory);
}

contract upfrontDepositContract is ReentrancyGuard {
  string public constant VERSION = "1.0.12-arbitrum";
  address private DEPOSIT_TOKEN;
  uint256 private DEPOSIT_WINDOW_START;
  uint256 private DEPOSIT_WINDOW_LENGTH;
  uint256 private DEPOSIT_WINDOW_CLOSED;
  uint256 private DEPOSIT_MIN_AMOUNT;
  uint256 private DEPOSIT_MAX_AMOUNT;
  uint256 private DEPOSIT_CAP;
  uint256 private REWARD_RATE;
  uint256 private CYCLE_LENGTH; //unused
  uint256 private WITHDRAWAL_LOCK_TIME;
  uint256 private WITHDRAWAL_WAIT_TIME;
  uint256 private FEE_WITHDRAWAL;
  uint256 private FEE_DEPOSIT;
  uint256 private FEE_CLAIM;
  uint256 private FEE_COMPOUND;
  uint256 private PROOF_OF_LIFE;
  address private MULTISIGN_ADDRESS;
  address private EXECUTOR_ADDRESS;
  address private TREASURY_ADDRESS;
  uint256 private MAX_INVESTORS;
  uint256 private INVITATION_MAX;
  bool private INVITATION_ONLY;
  bool private REWARDS_PROCESSED;
  bool private initialized;

  struct tokenInterfaceDataStruct {
    bool exists;
    IERC20 iface;
  }

  struct investorDataStruct {
    bool exists;
    bool autoClaim;
    bool autoCompound;
    uint256 created;
    uint256 lastProofOfLife;
    address invitedBy;
    depositDataStruct[] deposit;
    mapping(address => invitedDataStruct) invited;
    address[] invitedList;
    bool blocked;
  }

  struct depositDataStruct {
    bool exists;
    uint256 created;
    uint256 lastAction;
    uint256 amount;
    uint256 claimedRewards;
    uint256 unclaimedRewards;
    uint256 withdrawalRequest;
    uint256 withdrawn;
    bool paused;
  }

  struct invitedDataStruct {
    bool exists;
    uint256 timestamp;
  }

  struct investorReturnStruct {
    bool autoClaim;
    bool autoCompound;
    uint256 created;
    uint256 lastProofOfLife;
    address invitedBy;
    depositDataStruct[] deposit;
    invitedReturnStruct[] invited;
    bool blocked;
  }

  struct invitedReturnStruct {
    uint256 timestamp;
    address invited;
  }

  address[] private investorList;

  mapping(address => tokenInterfaceDataStruct) private tokenInterfaceData;
  mapping(address => investorDataStruct) private investorData;

  event Deposit(address indexed from, uint256 amount);
  event WithdrawnNativeFunds(address indexed to, uint256 amount, address executor);
  event WithdrawnTokenFunds(address indexed to, uint256 amount, address token, address executor);
  event WithdrawalRequested(address indexed investor, uint256 indexed id);
  event WithdrawalRequestCancelled(address indexed investor, uint256 indexed id);
  event WithdrawnDeposit(address indexed investor, uint256 indexed id, uint256 amount);
  event DepositWindowOpen();
  event DepositWindowClosed();
  event ClaimedRewards(address indexed investor, uint256[] indexed list, uint256 amount);
  event CompoundedRewards(address indexed investor, uint256[] indexed list, uint256 amount);
  event ProofOfLifeExpired(address indexed investor);
  event InvestorMigrated(address oldInvestor, address newInvestor);
  event WithdrawalApproved(address indexed investor, uint256 indexed id);

  struct investorListStruct { //unused
    address investor;
    uint256 deposits;
  }

  event MergedDeposits(address indexed investor, uint256[] indexed list, uint256 amount);

  uint256 private DEPOSIT_MAX_TOTAL;
  uint256 private DEPOSIT_MAX_PER_INVESTOR;

  struct contractInfoStruct {
    uint256 totalInvestors;
    uint256 totalInvested;
    uint256 totalRewards;
    uint256 rewardRate;
    uint256 depositWindowDay;
    uint256 depositWindowStart;
    uint256 depositWindowLength;
    uint256 depositWindowClosed;
    uint256 depositMin;
    uint256 depositMax;
    uint256 depositCap;
    uint256 depositMaxTotal;
    uint256 depositMaxPerInvestor;
    uint256 withdrawalLockTime;
    uint256 withdrawalWaitTime;
    uint256 invitationMax;
    uint256 maxInvestors;
    uint256 feeDeposit;
    uint256 feeWithdrawal;
    uint256 feeClaim;
    uint256 feeCompound;
    uint256 proofOfLife;
    bool rewardsProcessed;
    address token;
    uint256 totalWithdrawn;
  }

  uint256 private DEPOSIT_WINDOW_DAY;
  uint256 private REWARDS_PROCESSING;

  mapping(address => bool) private rewardsProcessed;

  event RewardsProcessed();

  modifier isTokenInterface(address _token) {
    require(tokenInterfaceData[_token].exists, "Unknown interface");

    _;
  }

  modifier isOwner() override {
    require(msg.sender == owner() || (MULTISIGN_ADDRESS != address(0) && msg.sender == MULTISIGN_ADDRESS), "Not owner or Multi-Signature Wallet");

    _;
  }

  modifier isManager() {
    require(MULTISIGN_ADDRESS != address(0));

    address[] memory managers = upfrontMultiSignatureWallet(MULTISIGN_ADDRESS).listManagers(true);

    uint256 cnt = managers.length;
    bool proceed;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (managers[i] != msg.sender) { continue; }

        proceed = true;
        break;
      }
    }

    require(proceed, "Not manager");

    _;
  }

  modifier isExecutor() {
    require(msg.sender == EXECUTOR_ADDRESS, "Not executor");

    _;
  }

  modifier isInitialized() {
    require(initialized, "Not initialized");

    _;
  }

  modifier isInvestor(address _investor) {
    require(investorData[_investor].exists, "Unknown investor");

    _;
  }

  constructor() {
    initialize();
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  fallback() external payable {
    require(msg.data.length == 0);

    emit Deposit(msg.sender, msg.value);
  }

  function initialize() public {
    require(!initialized);

    _setOwner(msg.sender);

    initialized = true;
  }

  function withdrawNativeFunds(address payable _to, uint256 _amount) external payable isOwner nonReEntrant {
    require(_amount > 0);
    require(getBalance() >= _amount, "Insufficient balance");

    (bool success, ) = _to.call{ value: _amount }("");
    require(success);

    emit WithdrawnNativeFunds(_to, _amount, msg.sender);
  }

  function withdrawTokenFunds(address _token, address _to, uint256 _amount) external isOwner isTokenInterface(_token) nonReEntrant {
    require(_amount > 0);
    require(getTokenBalance(_token) >= _amount, "Insufficient balance");

    bool success = tokenInterfaceData[_token].iface.transfer(_to, _amount);
    require(success);

    emit WithdrawnTokenFunds(_to, _amount, _token, msg.sender);
  }

  function getBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getTokenBalance(address _token) public view isTokenInterface(_token) returns (uint256) {
    return tokenInterfaceData[_token].iface.balanceOf(address(this));
  }

  function addTokenInterface(address _token) external isOwner {
    _addTokenInterface(_token);
  }

  function adminAddTokenInterface(address _token) external isManager {
    _addTokenInterface(_token);
  }

  function _addTokenInterface(address _token) internal {
    require(!tokenInterfaceData[_token].exists, "Interface exists");

    tokenInterfaceData[_token].exists = true;
    tokenInterfaceData[_token].iface = IERC20(_token);
  }

  function _contractStats() internal view returns (uint256 totalInvestors, uint256 totalInvested, uint256 totalRewards, uint256 totalWithdrawn) {
    totalInvestors = investorList.length;

    unchecked {
      for (uint256 i; i < totalInvestors; i++) {
        (, uint256 investorDeposits, uint256 investorRewards, uint256 investorWithdrawn) = _investorTotalDeposits(investorList[i]);

        totalInvested += investorDeposits;
        totalRewards += investorRewards;
        totalWithdrawn += investorWithdrawn;
      }
    }
  }

  function getContractInfo() external view returns (contractInfoStruct memory info) {
    (uint256 totalInvestors, uint256 totalInvested, uint256 totalRewards, uint256 totalWithdrawn) = _contractStats();

    info.totalInvestors = totalInvestors;
    info.totalInvested = totalInvested;
    info.totalRewards = totalRewards;
    info.totalWithdrawn = totalWithdrawn;
    info.rewardRate = REWARD_RATE;
    info.depositWindowDay = DEPOSIT_WINDOW_DAY;
    info.depositWindowStart = DEPOSIT_WINDOW_START;
    info.depositWindowLength = DEPOSIT_WINDOW_LENGTH;
    info.depositWindowClosed = DEPOSIT_WINDOW_CLOSED;
    info.depositMin = DEPOSIT_MIN_AMOUNT;
    info.depositMax = DEPOSIT_MAX_AMOUNT;
    info.depositCap = DEPOSIT_CAP;
    info.depositMaxTotal = DEPOSIT_MAX_TOTAL;
    info.depositMaxPerInvestor = DEPOSIT_MAX_PER_INVESTOR;
    info.withdrawalLockTime = WITHDRAWAL_LOCK_TIME;
    info.withdrawalWaitTime = WITHDRAWAL_WAIT_TIME;
    info.invitationMax = INVITATION_ONLY ? INVITATION_MAX : 0;
    info.maxInvestors = MAX_INVESTORS;
    info.feeDeposit = FEE_DEPOSIT;
    info.feeWithdrawal = FEE_WITHDRAWAL;
    info.feeClaim = FEE_CLAIM;
    info.feeCompound = FEE_COMPOUND;
    info.proofOfLife = PROOF_OF_LIFE;
    info.rewardsProcessed = REWARDS_PROCESSED;
    info.token = DEPOSIT_TOKEN;
  }

  function _investorTotalDeposits(address _investor) internal view returns (uint256 deposits, uint256 investorDeposits, uint256 investorRewards, uint256 investorWithdrawn) {
    uint256 cnt = investorData[_investor].deposit.length;

    unchecked {
      for (uint256 d; d < cnt; d++) {
        depositDataStruct memory deposit = investorData[_investor].deposit[d];

        investorRewards += deposit.claimedRewards + deposit.unclaimedRewards;

        if (deposit.withdrawn > 0) { investorWithdrawn += deposit.amount; }
        if (deposit.amount == 0 || deposit.withdrawn > 0) { continue; }

        investorDeposits += deposit.amount;
        deposits++;
      }
    }
  }

  function getInvestorInfo(address _investor) public view isInvestor(_investor) returns (investorReturnStruct memory) {
    investorReturnStruct memory investor;
    uint256 icnt = investorData[_investor].invitedList.length;

    investor.autoClaim = investorData[_investor].autoClaim;
    investor.autoCompound = investorData[_investor].autoCompound;
    investor.created = investorData[_investor].created;
    investor.lastProofOfLife = investorData[_investor].lastProofOfLife;
    investor.invitedBy = investorData[_investor].invitedBy;
    investor.deposit = investorData[_investor].deposit;
    investor.invited = new invitedReturnStruct[](icnt);
    investor.blocked = investorData[_investor].blocked;

    unchecked {
      for (uint256 i; i < icnt; i++) {
        invitedDataStruct memory invited = investorData[_investor].invited[investorData[_investor].invitedList[i]];

        investor.invited[i] = invitedReturnStruct(invited.timestamp, investorData[_investor].invitedList[i]);
      }
    }

    return investor;
  }

  function getInvestorList() external view returns (address[] memory, investorReturnStruct[] memory) {
    uint256 cnt = investorList.length;

    investorReturnStruct[] memory data = new investorReturnStruct[](cnt);

    unchecked {
      for (uint256 i; i < cnt; i++) {
        data[i] = getInvestorInfo(investorList[i]);
      }
    }

    return (investorList, data);
  }

  function migrateInvestor(address _oldInvestor, address _newInvestor) external isOwner isInvestor(_oldInvestor) {
    require(_newInvestor != address(0));
    require(!investorData[_newInvestor].exists, "Investor exists");

    investorDataStruct storage oldInvestor = investorData[_oldInvestor];
    investorDataStruct storage newInvestor = investorData[_newInvestor];

    newInvestor.exists = true;
    newInvestor.autoClaim = oldInvestor.autoClaim;
    newInvestor.autoCompound = oldInvestor.autoCompound;
    newInvestor.created = block.timestamp;
    newInvestor.lastProofOfLife = block.timestamp;
    newInvestor.deposit = oldInvestor.deposit;

    uint256 cnt = investorList.length;
    uint256 dcnt = oldInvestor.deposit.length;

    unchecked {
      for (uint256 d; d < dcnt; d++) {
        depositDataStruct storage deposit = oldInvestor.deposit[d];

        deposit.amount = 0;
        deposit.claimedRewards = 0;
        deposit.unclaimedRewards = 0;
        deposit.withdrawalRequest = 0;
        deposit.withdrawn = 0;
        deposit.paused = true;
      }

      for (uint256 i; i < cnt; i++) {
        if (investorList[i] != _oldInvestor) { continue; }

        investorList[i] = _newInvestor;
        break;
      }
    }

    oldInvestor.blocked = true;
    oldInvestor.exists = false;

    emit InvestorMigrated(_oldInvestor, _newInvestor);
  }

  function newDeposit(uint256 _amount, address _invitation) external nonReEntrant {
    require(msg.sender != owner());
    require(DEPOSIT_WINDOW_CLOSED == 0, "Deposit window closed");
    require(_amount >= DEPOSIT_MIN_AMOUNT, "Insufficient deposit");
    require(DEPOSIT_MAX_AMOUNT == 0 || (DEPOSIT_MAX_AMOUNT > 0 && _amount <= DEPOSIT_MAX_AMOUNT), "Deposit exceeded");
    require(tokenInterfaceData[DEPOSIT_TOKEN].iface.balanceOf(msg.sender) >= _amount, "Insufficient balance");
    require(tokenInterfaceData[DEPOSIT_TOKEN].iface.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");

    (uint256 totalInvestors, uint256 totalInvested, , ) = _contractStats();

    unchecked {
      uint256 fee = _amount * FEE_DEPOSIT / (100*100);
      uint256 total = _amount - fee;

      if (DEPOSIT_MAX_TOTAL > 0) { require(totalInvested + total <= DEPOSIT_MAX_TOTAL, "Max. reached"); }

      if (investorData[msg.sender].exists) {
        _signProofOfLife(msg.sender);

        if (DEPOSIT_CAP > 0 || DEPOSIT_MAX_PER_INVESTOR > 0) {
          (uint256 deposits, uint256 investorDeposits, , ) = _investorTotalDeposits(msg.sender);

          if (DEPOSIT_CAP > 0) { require(deposits < DEPOSIT_CAP, "Deposit cap reached"); }
          if (DEPOSIT_MAX_PER_INVESTOR > 0) { require(investorDeposits + total <= DEPOSIT_MAX_PER_INVESTOR, "Max. reached"); }
        }
      } else {
        if (MAX_INVESTORS > 0) { require(totalInvestors < MAX_INVESTORS, "Max. investors reached"); }

        if (INVITATION_ONLY) {
          require(_invitation != address(0), "Invalid code");
          require(investorData[_invitation].exists, "Unknown investor");
          require(investorData[_invitation].invitedList.length < INVITATION_MAX, "Invitations exceeded");
        }
      }

      bool txDeposit = tokenInterfaceData[DEPOSIT_TOKEN].iface.transferFrom(msg.sender, address(this), _amount);
      require(txDeposit);

      if (fee > 0 && TREASURY_ADDRESS != address(0)) {
        bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, fee);
        require(txFee);
      }

      if (!investorData[msg.sender].exists) {
        investorData[msg.sender].exists = true;
        investorData[msg.sender].created = block.timestamp;
        investorData[msg.sender].lastProofOfLife = block.timestamp;

        if (INVITATION_ONLY) {
          investorData[msg.sender].invitedBy = _invitation;
          investorData[_invitation].invited[msg.sender] = invitedDataStruct(true, block.timestamp);
          investorData[_invitation].invitedList.push(msg.sender);
        }

        investorList.push(msg.sender);
      }

      investorData[msg.sender].deposit.push(depositDataStruct(true, block.timestamp, block.timestamp, total, 0, 0, 0, 0, true));

      emit Deposit(msg.sender, total);
    }
  }

  function mergeDeposits(uint256[] memory _list) external isInvestor(msg.sender) {
    require(DEPOSIT_WINDOW_CLOSED == 0, "Deposit window closed");

    uint256 cnt = _list.length;

    require(cnt > 1);

    investorDataStruct storage investor = investorData[msg.sender];

    uint256 amount;
    uint256 claimedRewards;
    uint256 unclaimedRewards;

    unchecked {
      for (uint256 c; c < cnt; c++) {
        uint256 id = _list[c] - 1;

        require(investor.deposit[id].exists);

        depositDataStruct storage deposit = investor.deposit[id];

        require(deposit.amount > 0 && deposit.withdrawn == 0 && deposit.withdrawalRequest == 0 && deposit.created + WITHDRAWAL_LOCK_TIME <= block.timestamp, "Cannot be merged");

        amount += deposit.amount;
        claimedRewards += deposit.claimedRewards;
        unclaimedRewards += deposit.unclaimedRewards;

        deposit.amount = 0;
        deposit.claimedRewards = 0;
        deposit.unclaimedRewards = 0;
        deposit.paused = true;
      }
    }

    investor.deposit.push(depositDataStruct(true, block.timestamp, block.timestamp, amount, claimedRewards, unclaimedRewards, 0, 0, !REWARDS_PROCESSED));

    emit MergedDeposits(msg.sender, _list, amount);
  }

  function requestWithdrawal(uint256 _id) external isInvestor(msg.sender) {
    require(_id >= 1, "Invalid deposit");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists);

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.amount > 0);
      require(deposit.withdrawalRequest == 0, "Request submitted");
      require(deposit.created + WITHDRAWAL_LOCK_TIME <= block.timestamp, "Not ready");

      deposit.withdrawalRequest = block.timestamp;
      deposit.lastAction = block.timestamp;
      deposit.paused = true;

      emit WithdrawalRequested(msg.sender, _id);
    }
  }

  function cancelWithdrawalRequest(uint256 _id) external isInvestor(msg.sender) {
    require(_id >= 1, "Invalid deposit");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists);

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.withdrawn == 0, "Processed");
      require(deposit.withdrawalRequest > 0, "No request");
      require(deposit.withdrawalRequest + (WITHDRAWAL_WAIT_TIME / 2) >= block.timestamp, "Not cancellable");

      deposit.withdrawalRequest = 0;
      deposit.lastAction = block.timestamp;

      emit WithdrawalRequestCancelled(msg.sender, _id);
    }
  }

  function withdrawDeposit(uint256 _id) external isInvestor(msg.sender) nonReEntrant returns (uint256 total) {
    require(_id >= 1, "Invalid deposit");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists);

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.amount > 0);
      require(deposit.withdrawn == 0, "Processed");
      require(deposit.withdrawalRequest > 0, "No request");
      require(deposit.withdrawalRequest + WITHDRAWAL_WAIT_TIME <= block.timestamp, "Not ready");

      uint256 rewards = deposit.unclaimedRewards;
      uint256 amount = deposit.amount + rewards;
      uint256 fee = amount * FEE_WITHDRAWAL / (100*100);

      total = amount - fee;

      require(getTokenBalance(DEPOSIT_TOKEN) >= amount, "Insufficient balance");

      if (fee > 0 && TREASURY_ADDRESS != address(0)) {
        bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, fee);
        require(txFee);
      }

      bool txTotal = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(msg.sender, total);
      require(txTotal);

      deposit.claimedRewards += rewards;
      deposit.unclaimedRewards = 0;
      deposit.lastAction = block.timestamp;
      deposit.withdrawn = block.timestamp;
      deposit.paused = true;

      emit WithdrawnDeposit(msg.sender, _id, total);
    }
  }

  function approveWithdrawal(address _investor, uint256 _id) external isOwner isInvestor(_investor) {
    investorDataStruct storage investor = investorData[_investor];

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists);

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.amount > 0);
      require(deposit.withdrawalRequest > 0, "No request");
      require(deposit.withdrawn == 0, "Processed");

      deposit.withdrawalRequest = block.timestamp - WITHDRAWAL_WAIT_TIME;

      emit WithdrawalApproved(_investor, _id);
    }
  }

  function toggleAutoClaimAndCompound(bool autoClaim, bool autoCompound) external isInvestor(msg.sender) {
    require(!(autoClaim && autoCompound), "One action only");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    if (autoCompound) {
      if (DEPOSIT_CAP > 0) {
        (uint256 deposits, , , ) = _investorTotalDeposits(msg.sender);

        require(deposits < DEPOSIT_CAP, "Deposit cap reached");
      }

      if (DEPOSIT_MAX_TOTAL > 0) {
        (, uint256 totalInvested, , ) = _contractStats();

        require(totalInvested <= DEPOSIT_MAX_TOTAL, "Max. reached");
      }
    }

    investor.autoClaim = autoClaim;
    investor.autoCompound = autoCompound;
  }

  function setDepositToken(address _token) external isOwner {
    require(Address.isContract(_token));

    DEPOSIT_TOKEN = _token;

    if (!tokenInterfaceData[_token].exists) { _addTokenInterface(DEPOSIT_TOKEN); }
  }

  function adminOpenDepositWindow() external isManager {
    _openDepositWindow();
  }

  function execOpenDepositWindow() external isExecutor {
    _openDepositWindow();
  }

  function _openDepositWindow() internal {
    require(DEPOSIT_WINDOW_START == 0, "Deposit window open");

    uint256 open;

    unchecked {
      if (DEPOSIT_WINDOW_CLOSED > 0) {
        (uint256 closedYear, uint256 closedMonth, ) = DateTime.getYearMonthDay(DEPOSIT_WINDOW_CLOSED);

        open = DateTime.convertYMDHMStoTimestamp(uint16(closedYear), uint8(closedMonth + 1), uint8(DEPOSIT_WINDOW_DAY), 12, 0, 0);
      } else {
        (uint256 currentYear, uint256 currentMonth, ) = DateTime.getYearMonthDay(block.timestamp);

        open = DateTime.convertYMDHMStoTimestamp(uint16(currentYear), uint8(currentMonth), uint8(DEPOSIT_WINDOW_DAY), 12, 0, 0);
      }

      require(block.timestamp >= open, "Cycle not finished");
    }

    DEPOSIT_WINDOW_START = block.timestamp;
    DEPOSIT_WINDOW_CLOSED = 0;

    emit DepositWindowOpen();
  }

  function adminProcessRewards() external isManager nonReEntrant {
    _processRewards();
  }

  function execProcessRewards() external isExecutor nonReEntrant {
    _processRewards();
  }

  function _processRewards() internal {
    require(DEPOSIT_WINDOW_CLOSED == 0, "Cycle not finished");
    require(!REWARDS_PROCESSED, "Processed");

    (uint256 totalInvestors, uint256 totalInvested, , ) = _contractStats();

    unchecked {
      for (uint256 i; i < totalInvestors; i++) {
        investorDataStruct storage investor = investorData[investorList[i]];

        if (investor.blocked) { continue; }

        if (PROOF_OF_LIFE > 0 && investor.lastProofOfLife + PROOF_OF_LIFE <= block.timestamp) {
          _blockInvestor(investorList[i]);

          continue;
        }

        (uint256 deposits, uint256 investorDeposits, , ) = _investorTotalDeposits(investorList[i]);

        uint256 dcnt = investor.deposit.length;
        uint256 rewards_length;
        uint256 rewards_total;
        uint256[] memory rewards_array = new uint256[](dcnt);

        for (uint256 d; d < dcnt; d++) {
          depositDataStruct storage deposit = investor.deposit[d];

          if (deposit.amount == 0) { continue; }
          if (deposit.withdrawalRequest > 0 || deposit.withdrawn > 0) { continue; }

          if (deposit.paused) {
            deposit.paused = false;

            continue;
          }

          deposit.unclaimedRewards += deposit.amount * REWARD_RATE / (100*100);

          if (!investor.autoClaim && !investor.autoCompound) { continue; }

          rewards_total += deposit.unclaimedRewards;
          rewards_array[rewards_length++] = d + 1;
        }

        if (rewards_length == 0) { continue; }

        uint256[] memory rewards_list = new uint256[](rewards_length);

        for (uint256 r; r < rewards_length; r++) { rewards_list[r] = rewards_array[r]; }

        if ((DEPOSIT_CAP > 0 && deposits >= DEPOSIT_CAP) || (DEPOSIT_MAX_TOTAL > 0 && totalInvested + rewards_total > DEPOSIT_MAX_TOTAL) || (DEPOSIT_MAX_PER_INVESTOR > 0 && investorDeposits + rewards_total > DEPOSIT_MAX_PER_INVESTOR)) {
          investor.autoClaim = true;
          investor.autoCompound = false;
        } else {
          _compoundRewards(investorList[i], rewards_list);

          continue;
        }

        _claimRewards(investorList[i], rewards_list);
      }
    }

    REWARDS_PROCESSED = true;

    if (REWARDS_PROCESSED) { emit RewardsProcessed(); }
  }

  function adminCloseDepositWindow() external isManager {
    _closeDepositWindow();
  }

  function execCloseDepositWindow() external isExecutor {
    _closeDepositWindow();
  }

  function _closeDepositWindow() internal {
    require(DEPOSIT_WINDOW_CLOSED == 0, "Deposit window closed");
    require(DEPOSIT_WINDOW_START + DEPOSIT_WINDOW_LENGTH <= block.timestamp, "Cycle not finished");

    uint256 cnt = investorList.length;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        investorDataStruct storage investor = investorData[investorList[i]];

        if (investor.blocked) { continue; }

        if (PROOF_OF_LIFE > 0 && investor.lastProofOfLife + PROOF_OF_LIFE <= block.timestamp) {
          _blockInvestor(investorList[i]);

          continue;
        }

        uint256 dcnt = investor.deposit.length;

        for (uint256 d; d < dcnt; d++) {
          depositDataStruct storage deposit = investor.deposit[d];

          if (deposit.withdrawalRequest > 0 || deposit.withdrawn > 0) { continue; }

          deposit.paused = false;
        }
      }
    }

    DEPOSIT_WINDOW_START = 0;
    DEPOSIT_WINDOW_CLOSED = block.timestamp;
    REWARDS_PROCESSED = false;

    emit DepositWindowClosed();
  }

  function signProofOfLife() external isInvestor(msg.sender) {
    _signProofOfLife(msg.sender);
  }

  function _signProofOfLife(address _investor) internal {
    investorData[_investor].lastProofOfLife = block.timestamp;
    investorData[_investor].blocked = false;
  }

  function execCheckProofOfLife() external isExecutor {
    require(PROOF_OF_LIFE > 0);

    uint256 cnt = investorList.length;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        investorDataStruct storage investor = investorData[investorList[i]];

        if (investor.blocked) { continue; }
        if (investor.lastProofOfLife + PROOF_OF_LIFE <= block.timestamp) { _blockInvestor(investorList[i]); }
      }
    }
  }

  function claimRewards(uint256[] memory _list) external isInvestor(msg.sender) nonReEntrant returns (uint256) {
    _signProofOfLife(msg.sender);

    return _claimRewards(msg.sender, _list);
  }

  function _claimRewards(address _investor, uint256[] memory _list) internal returns (uint256 total) {
    uint256 cnt = _list.length;

    require(cnt > 0);

    uint256 totalFee;
    investorDataStruct storage investor = investorData[_investor];

    unchecked {
      for (uint256 c; c < cnt; c++) {
        uint256 id = _list[c] - 1;

        if (!investor.deposit[id].exists) { continue; }

        depositDataStruct storage deposit = investor.deposit[id];

        uint256 unclaimedRewards = deposit.unclaimedRewards;

        if (unclaimedRewards == 0) { continue; }

        uint256 fee = unclaimedRewards * FEE_CLAIM / (100*100);
        uint256 amount = unclaimedRewards - fee;

        totalFee += fee;
        total += amount;

        deposit.claimedRewards += amount;
        deposit.unclaimedRewards = 0;
      }
    }

    if (total > 0) {
      if (totalFee > 0 && TREASURY_ADDRESS != address(0)) {
        bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, totalFee);
        require(txFee);
      }

      bool txRewards = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(_investor, total);
      require(txRewards);

      emit ClaimedRewards(_investor, _list, total);
    }
  }

  function compoundRewards(uint256[] memory _list) external isInvestor(msg.sender) nonReEntrant returns (uint256) {
    require(DEPOSIT_WINDOW_CLOSED == 0, "Deposit window closed");

    _signProofOfLife(msg.sender);

    if (DEPOSIT_CAP > 0) {
      (uint256 deposits, , , ) = _investorTotalDeposits(msg.sender);

      require(deposits < DEPOSIT_CAP, "Deposit cap reached");
    }

    return _compoundRewards(msg.sender, _list);
  }

  function _compoundRewards(address _investor, uint256[] memory _list) internal returns (uint256 total) {
    uint256 cnt = _list.length;

    require(cnt > 0);

    uint256 totalFee;
    investorDataStruct storage investor = investorData[_investor];

    unchecked {
      for (uint256 c; c < cnt; c++) {
        uint256 id = _list[c] - 1;

        if (!investor.deposit[id].exists) { continue; }

        depositDataStruct storage deposit = investor.deposit[id];

        if (deposit.unclaimedRewards == 0) { continue; }

        uint256 fee = deposit.unclaimedRewards * FEE_COMPOUND / (100*100);
        uint256 amount = deposit.unclaimedRewards - fee;

        totalFee += fee;
        total += amount;

        deposit.claimedRewards += amount;
        deposit.unclaimedRewards = 0;

        if (!deposit.paused) { deposit.paused = !REWARDS_PROCESSED; }
      }
    }

    if (total > 0) {
      if (DEPOSIT_MAX_TOTAL > 0) {
        (, uint256 totalInvested, , ) = _contractStats();

        require(totalInvested + total <= DEPOSIT_MAX_TOTAL, "Max. reached");
      }

      if (DEPOSIT_CAP > 0 || DEPOSIT_MAX_PER_INVESTOR > 0) {
        (uint256 deposits, uint256 investorDeposits, , ) = _investorTotalDeposits(_investor);

        if (DEPOSIT_CAP > 0) { require(deposits < DEPOSIT_CAP, "Deposit cap reached"); }
        if (DEPOSIT_MAX_PER_INVESTOR > 0) { require(investorDeposits + total <= DEPOSIT_MAX_PER_INVESTOR, "Max. reached"); }
      }

      if (totalFee > 0 && TREASURY_ADDRESS != address(0)) {
        bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, totalFee);
        require(txFee);
      }

      investor.deposit.push(depositDataStruct(true, block.timestamp, block.timestamp, total, 0, 0, 0, 0, !REWARDS_PROCESSED));

      emit CompoundedRewards(_investor, _list, total);
    }
  }

  function _blockInvestor(address _investor) internal {
    investorDataStruct storage investor = investorData[_investor];
    uint256 dcnt = investor.deposit.length;

    investor.blocked = true;
    investor.autoClaim = false;
    investor.autoCompound = false;

    unchecked {
      for (uint256 d; d < dcnt; d++) { investor.deposit[d].paused = true; }
    }

    emit ProofOfLifeExpired(_investor);
  }

  function setRewardRate(uint256 _rate) external isOwner {
    require(_rate > 0 && _rate < 100*100);

    REWARD_RATE = _rate;
  }

  function setDepositTime(uint256 _day, uint256 _window) external isOwner {
    require(_day >= 1 && _day <= 28);

    DEPOSIT_WINDOW_DAY = _day;
    DEPOSIT_WINDOW_LENGTH = _window;
  }

  function setDepositLimits(uint256 _min, uint256 _max, uint256 _cap, uint256 _maxTotal, uint256 _maxPerInvestor, uint256 _investors) external isOwner {
    require(_min > 0);
    require(_max == 0 || _max >= _min);
    require(_cap > 0);
    require(_investors == 0 || _investors >= investorList.length, "Invalid max. investors");

    DEPOSIT_MIN_AMOUNT = _min;
    DEPOSIT_MAX_AMOUNT = _max;
    DEPOSIT_CAP = _cap;
    DEPOSIT_MAX_TOTAL = _maxTotal;
    DEPOSIT_MAX_PER_INVESTOR = _maxPerInvestor;
    MAX_INVESTORS = _investors;
  }

  function setFees(uint256 _deposit, uint256 _withdrawal, uint256 _claim, uint256 _compound) external isOwner {
    require(_deposit < 100*100);
    require(_withdrawal < 100*100);
    require(_claim < 100*100);
    require(_compound < 100*100);

    FEE_DEPOSIT = _deposit;
    FEE_WITHDRAWAL = _withdrawal;
    FEE_CLAIM = _claim;
    FEE_COMPOUND = _compound;
  }

  function setWithdrawalLimits(uint256 _lock, uint256 _wait) external isOwner {
    require(_lock >= 1 days);
    require(_wait >= 1 days);

    WITHDRAWAL_LOCK_TIME = _lock;
    WITHDRAWAL_WAIT_TIME = _wait;
  }

  function setInvitationLimits(bool _state, uint256 _max) external isOwner {
    INVITATION_ONLY = _state;
    INVITATION_MAX = _max;
  }

  function setProofOfLife(uint256 _time) external isOwner {
    PROOF_OF_LIFE = _time;

    uint256 cnt = investorList.length;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        investorDataStruct storage investor = investorData[investorList[i]];

        if (PROOF_OF_LIFE == 0) {
          investor.blocked = false;

          continue;
        }

        if (investor.blocked) { continue; }
        if (investor.lastProofOfLife + PROOF_OF_LIFE <= block.timestamp) { _blockInvestor(investorList[i]); }
      }
    }
  }

  function setExecutor(address _address) external isOwner {
    require(_address != address(0));

    EXECUTOR_ADDRESS = _address;
  }

  function setTreasury(address _address) external isOwner {
    require(_address != address(0));

    TREASURY_ADDRESS = _address;
  }

  function setMultiSignatureWallet(address _address) external isOwner {
    require(_address != address(0));

    MULTISIGN_ADDRESS = _address;
  }
}