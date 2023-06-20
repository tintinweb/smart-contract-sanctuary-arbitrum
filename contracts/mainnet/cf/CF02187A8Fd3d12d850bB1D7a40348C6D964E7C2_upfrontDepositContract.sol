/**
 *Submitted for verification at Arbiscan on 2023-06-20
*/

// SPDX-License-Identifier: MIT

/*
   __  __      ____                 __ 
  / / / /___  / __/________  ____  / /_
 / / / / __ \/ /_/ ___/ __ \/ __ \/ __/
/ /_/ / /_/ / __/ /  / /_/ / / / / /_  
\____/ .___/_/ /_/   \____/_/ /_/\__/  
    /_/                                

  Deposit Contract

  Authors: <MagicFormulaY> & <dotfx>
  Date: 2023/06/20
  Version: 1.0.4
*/

pragma solidity >=0.8.18 <0.9.0;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() {
    _setOwner(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier isOwner() virtual {
    require(_msgSender() == _owner, "Caller must be the owner");

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
  function decimals() external view returns (uint8);
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
  string public constant VERSION = "1.0.4";
  address private DEPOSIT_TOKEN;
  uint256 private DEPOSIT_WINDOW_START;
  uint256 private DEPOSIT_WINDOW_LENGTH;
  uint256 private DEPOSIT_WINDOW_CLOSED;
  uint256 private DEPOSIT_MIN_AMOUNT;
  uint256 private DEPOSIT_MAX_AMOUNT;
  uint256 private DEPOSIT_CAP;
  uint256 private REWARD_RATE;
  uint256 private CYCLE_LENGTH;
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

  struct investorListStruct {
    address investor;
    uint256 deposits;
  }

  modifier isTokenInterface(address _token) {
    require(tokenInterfaceData[_token].exists, "Unknown interface");

    _;
  }

  modifier isOwner() override {
    require(_msgSender() == owner() || (MULTISIGN_ADDRESS != address(0) && _msgSender() == MULTISIGN_ADDRESS), "Caller must be the owner or the Multi-Signature Wallet");

    _;
  }

  modifier isManager() {
    require(MULTISIGN_ADDRESS != address(0));

    address[] memory managers = upfrontMultiSignatureWallet(MULTISIGN_ADDRESS).listManagers(true);

    uint256 cnt = managers.length;
    bool proceed;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (managers[i] != _msgSender()) { continue; }

        proceed = true;
      }
    }

    require(proceed, "Caller must be manager");

    _;
  }

  modifier isExecutor() {
    require(_msgSender() == EXECUTOR_ADDRESS, "Caller must be executor");

    _;
  }

  modifier isInitialized() {
    require(initialized, "Contract not initialized");

    _;
  }

  modifier isInvitation(address _invitation) {
    if (INVITATION_ONLY && !investorData[_msgSender()].exists) {
      require(_invitation != address(0), "Invalid code");
      require(investorData[_invitation].exists, "Unknown origin");
      require(investorData[_invitation].invitedList.length < INVITATION_MAX, "Code usage exceeded");

      _;
    } else {
      _;
    }
  }

  modifier isInvestor() {
    require(investorData[_msgSender()].exists, "Unknown investor");

    _;
  }

  constructor() {
    initialize();
  }

  receive() external payable isInitialized {
    emit Deposit(msg.sender, msg.value);
  }

  fallback() external payable isInitialized {
    require(msg.data.length == 0);

    emit Deposit(msg.sender, msg.value);
  }

  function initialize() public {
    require(!initialized, "Contract already initialized");

    _setOwner(_msgSender());

    initialized = true;
  }

  function withdrawNativeFunds(address payable _to, uint256 _amount) external payable isOwner nonReEntrant {
    require(_amount > 0);
    require(getBalance() >= _amount, "Insufficient balance");

    (bool success, bytes memory result) = _to.call{ value: _amount }("");

    if (!success) {
      if (result.length > 0) {
        assembly {
          let size := mload(result)

          revert(add(32, result), size)
        }
      }

      revert("Function call reverted");
    }

    emit WithdrawnNativeFunds(_to, _amount, msg.sender);
  }

  function withdrawTokenFunds(address _token, address _to, uint256 _amount) external isOwner isTokenInterface(_token) nonReEntrant {
    require(_amount > 0);
    require(getTokenBalance(_token) >= _amount, "Insufficient balance");

    bool success = tokenInterfaceData[_token].iface.transfer(_to, _amount);
    require(success, "Transfer error");

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

  function adminAddTokenInterface(address _token) external isManager isInitialized {
    _addTokenInterface(_token);
  }

  function _addTokenInterface(address _token) internal {
    require(!tokenInterfaceData[_token].exists, "Interface exists");

    tokenInterfaceData[_token].exists = true;
    tokenInterfaceData[_token].iface = IERC20(_token);
  }

  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function getContractInfo() external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool) {
    return (REWARD_RATE, DEPOSIT_WINDOW_START, DEPOSIT_WINDOW_LENGTH, DEPOSIT_WINDOW_CLOSED, DEPOSIT_MIN_AMOUNT, DEPOSIT_MAX_AMOUNT, DEPOSIT_CAP, WITHDRAWAL_LOCK_TIME, WITHDRAWAL_WAIT_TIME, INVITATION_ONLY ? INVITATION_MAX : 0, CYCLE_LENGTH, PROOF_OF_LIFE, MAX_INVESTORS, REWARDS_PROCESSED);
  }

  function getContractStats() external view returns (uint256 totalInvestors, uint256 totalDeposits, uint256 totalRewards) {
    totalInvestors = investorList.length;

    unchecked {
      for (uint256 i; i < totalInvestors; i++) {
        uint256 dcnt = investorData[investorList[i]].deposit.length;

        for (uint256 d; d < dcnt; d++) {
          depositDataStruct memory deposit = investorData[investorList[i]].deposit[d];

          if (deposit.withdrawn == 0) { totalDeposits += deposit.amount; }

          totalRewards += deposit.claimedRewards + deposit.unclaimedRewards;
        }
      }
    }
  }

  function getContractFees() external view returns (uint256, uint256, uint256, uint256) {
    return (FEE_DEPOSIT, FEE_WITHDRAWAL, FEE_CLAIM, FEE_COMPOUND);
  }

  function getInvestorInfo(address _investor) external view returns (investorReturnStruct memory) {
    require(investorData[_investor].exists, "Unknown investor");

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

  function migrateInvestor(address _oldInvestor, address _newInvestor) external isOwner {
    require(_newInvestor != address(0));
    require(!investorData[_newInvestor].exists, "Investor exists");

    investorDataStruct storage investor = investorData[_oldInvestor];

    investorData[_newInvestor].exists = true;
    investorData[_newInvestor].autoClaim = investor.autoClaim;
    investorData[_newInvestor].autoCompound = investor.autoCompound;
    investorData[_newInvestor].created = getCurrentTime();
    investorData[_newInvestor].lastProofOfLife = getCurrentTime();
    investorData[_newInvestor].deposit = investor.deposit;

    uint256 cnt = investorList.length;
    uint256 dcnt = investor.deposit.length;

    unchecked {
      for (uint256 d; d < dcnt; d++) {
        investor.deposit[d].amount = 0;
        investor.deposit[d].claimedRewards = 0;
        investor.deposit[d].unclaimedRewards = 0;
        investor.deposit[d].withdrawalRequest = 0;
        investor.deposit[d].withdrawn = 0;
        investor.deposit[d].paused = true;
      }

      for (uint256 i; i < cnt; i++) {
        if (investorList[i] != _oldInvestor) { continue; }

        investorList[i] = _newInvestor;
        break;
      }
    }

    investor.blocked = true;
    investor.exists = false;

    emit InvestorMigrated(_oldInvestor, _newInvestor);
  }

  function newDeposit(uint256 _amount, address _invitation) external isInitialized isInvitation(_invitation) nonReEntrant {
    require(msg.sender != owner(), "Owner cannot participate");
    require(DEPOSIT_WINDOW_CLOSED == 0, "Deposit window closed");
    require(_amount >= DEPOSIT_MIN_AMOUNT, "Insufficient deposit");
    require(DEPOSIT_MAX_AMOUNT == 0 || (DEPOSIT_MAX_AMOUNT > 0 && _amount <= DEPOSIT_MAX_AMOUNT), "Deposit exceeded");
    require(tokenInterfaceData[DEPOSIT_TOKEN].iface.balanceOf(msg.sender) >= _amount, "Insufficient balance");
    require(tokenInterfaceData[DEPOSIT_TOKEN].iface.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");

    if (investorData[msg.sender].exists) {
      _signProofOfLife(msg.sender);

      require(DEPOSIT_CAP == 0 || (DEPOSIT_CAP > 0 && investorData[msg.sender].deposit.length < DEPOSIT_CAP), "Deposit cap reached");
    } else {
      require(investorList.length < MAX_INVESTORS, "Max. investors reached");
    }

    bool txDeposit = tokenInterfaceData[DEPOSIT_TOKEN].iface.transferFrom(msg.sender, address(this), _amount);
    require(txDeposit, "Transfer error");

    uint256 fee = _amount * FEE_DEPOSIT / (100*100);
    uint256 total = _amount - fee;

    if (fee > 0 && TREASURY_ADDRESS != address(0)) {
      bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, fee);
      require(txFee, "Fee transfer error");
    }

    if (!investorData[msg.sender].exists) {
      investorData[msg.sender].exists = true;
      investorData[msg.sender].created = getCurrentTime();
      investorData[msg.sender].lastProofOfLife = getCurrentTime();

      if (INVITATION_ONLY) {
        investorData[msg.sender].invitedBy = _invitation;
        investorData[_invitation].invited[msg.sender] = invitedDataStruct(true, getCurrentTime());
        investorData[_invitation].invitedList.push(msg.sender);
      }

      investorList.push(msg.sender);
    }

    investorData[msg.sender].deposit.push(depositDataStruct(true, getCurrentTime(), getCurrentTime(), total, 0, 0, 0, 0, true));

    emit Deposit(msg.sender, total);
  }

  function requestWithdrawal(uint256 _id) external isInvestor {
    require(_id >= 1, "Invalid deposit");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists, "Unknown deposit");

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.amount > 0);
      require(deposit.withdrawalRequest == 0, "Request submitted");
      require(deposit.created + WITHDRAWAL_LOCK_TIME <= getCurrentTime(), "Withdrawal request not ready");

      deposit.withdrawalRequest = getCurrentTime();
      deposit.lastAction = getCurrentTime();
      deposit.paused = true;

      emit WithdrawalRequested(msg.sender, _id);
    }
  }

  function cancelWithdrawalRequest(uint256 _id) external isInvestor {
    require(_id >= 1, "Invalid deposit");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists, "Unknown deposit");

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.withdrawn == 0, "Withdrawal processed");
      require(deposit.withdrawalRequest > 0, "Request not found");
      require(deposit.withdrawalRequest + (WITHDRAWAL_WAIT_TIME / 2) >= getCurrentTime(), "Request cannot be cancelled");

      deposit.withdrawalRequest = 0;
      deposit.lastAction = getCurrentTime();

      emit WithdrawalRequestCancelled(msg.sender, _id);
    }
  }

  function withdrawDeposit(uint256 _id) external isInvestor isInitialized nonReEntrant returns (uint256 total) {
    require(_id >= 1, "Invalid deposit");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists, "Unknown deposit");

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.amount > 0);
      require(deposit.withdrawn == 0, "Already processed");
      require(deposit.withdrawalRequest > 0, "Request not found");
      require(deposit.withdrawalRequest + WITHDRAWAL_WAIT_TIME <= getCurrentTime(), "Withdrawal not ready");

      uint256 rewards = deposit.unclaimedRewards;
      uint256 amount = deposit.amount + rewards;
      uint256 fee = amount * FEE_WITHDRAWAL / (100*100);

      total = amount - fee;

      require(getTokenBalance(DEPOSIT_TOKEN) >= amount, "Insufficient balance");

      if (fee > 0 && TREASURY_ADDRESS != address(0)) {
        bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, fee);
        require(txFee, "Fee transfer error");
      }

      bool txTotal = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(msg.sender, total);
      require(txTotal, "Transfer error");

      deposit.claimedRewards += rewards;
      deposit.unclaimedRewards = 0;
      deposit.lastAction = getCurrentTime();
      deposit.withdrawn = getCurrentTime();
      deposit.paused = true;

      emit WithdrawnDeposit(msg.sender, _id, total);
    }
  }

  function approveWithdrawal(address _investor, uint256 _id) external isOwner {
    require(investorData[_investor].exists, "Unknown investor");

    investorDataStruct storage investor = investorData[_investor];

    unchecked {
      uint256 d = _id - 1;

      require(investor.deposit[d].exists, "Unknown deposit");

      depositDataStruct storage deposit = investor.deposit[d];

      require(deposit.amount > 0);
      require(deposit.withdrawalRequest > 0, "Request not found");
      require(deposit.withdrawn == 0, "Already processed");

      deposit.withdrawalRequest = getCurrentTime() - WITHDRAWAL_WAIT_TIME;

      emit WithdrawalApproved(_investor, _id);
    }
  }

  function toggleAutoClaimAndCompound(bool autoClaim, bool autoCompound) external isInvestor {
    require(!(autoClaim && autoCompound), "One action can be set at a time");

    investorDataStruct storage investor = investorData[msg.sender];

    _signProofOfLife(msg.sender);

    if (autoCompound) { require(DEPOSIT_CAP == 0 || (DEPOSIT_CAP > 0 && investor.deposit.length < DEPOSIT_CAP), "Deposit cap reached"); }

    investor.autoClaim = autoClaim;
    investor.autoCompound = autoCompound;
  }

  function setDepositToken(address _token) external isOwner {
    require(Address.isContract(_token));

    DEPOSIT_TOKEN = _token;

    _addTokenInterface(DEPOSIT_TOKEN);
  }

  function adminOpenDepositWindow() external isManager isInitialized {
    _openDepositWindow();
  }

  function execOpenDepositWindow() external isExecutor isInitialized {
    _openDepositWindow();
  }

  function _openDepositWindow() internal {
    require(DEPOSIT_WINDOW_START == 0, "Window already open");
    require(DEPOSIT_WINDOW_CLOSED + CYCLE_LENGTH <= getCurrentTime(), "Cycle not finished");

    DEPOSIT_WINDOW_START = getCurrentTime();
    DEPOSIT_WINDOW_CLOSED = 0;

    emit DepositWindowOpen();
  }

  function adminProcessRewards() external isManager isInitialized nonReEntrant {
    _processRewards();
  }

  function execProcessRewards() external isExecutor isInitialized nonReEntrant {
    _processRewards();
  }

  function _processRewards() internal {
    require(DEPOSIT_WINDOW_CLOSED == 0, "Cycle not finished");
    require(!REWARDS_PROCESSED, "Already processed");

    uint256 cnt = investorList.length;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        investorDataStruct storage investor = investorData[investorList[i]];

        if (investor.blocked) { continue; }

        if (PROOF_OF_LIFE > 0 && investor.lastProofOfLife + PROOF_OF_LIFE <= getCurrentTime()) {
          _blockInvestor(investorList[i]);

          continue;
        }

        uint256 dcnt = investor.deposit.length;
        uint256 rewards_length;
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
          if (investor.autoCompound && DEPOSIT_CAP > 0 && dcnt >= DEPOSIT_CAP) { continue; }

          rewards_array[rewards_length++] = d + 1;
        }

        if (rewards_length == 0) { continue; }

        uint256[] memory rewards_list = new uint256[](rewards_length);

        for (uint256 r; r < rewards_length; r++) { rewards_list[r] = rewards_array[r]; }

        if (investor.autoClaim) {
          _claimRewards(investorList[i], rewards_list);
        } else if (investor.autoCompound) {
          _compoundRewards(investorList[i], rewards_list);
        }
      }
    }

    REWARDS_PROCESSED = true;
  }

  function adminCloseDepositWindow() external isManager isInitialized {
    _closeDepositWindow();
  }

  function execCloseDepositWindow() external isExecutor isInitialized {
    _closeDepositWindow();
  }

  function _closeDepositWindow() internal {
    require(DEPOSIT_WINDOW_CLOSED == 0, "Deposit window closed");
    require(DEPOSIT_WINDOW_START + DEPOSIT_WINDOW_LENGTH <= getCurrentTime(), "Window length not finished");

    uint256 cnt = investorList.length;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        investorDataStruct storage investor = investorData[investorList[i]];

        if (investor.blocked) { continue; }

        if (PROOF_OF_LIFE > 0 && investor.lastProofOfLife + PROOF_OF_LIFE <= getCurrentTime()) {
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
    DEPOSIT_WINDOW_CLOSED = getCurrentTime();
    REWARDS_PROCESSED = false;

    emit DepositWindowClosed();
  }

  function signProofOfLife() external isInvestor isInitialized {
    _signProofOfLife(msg.sender);
  }

  function _signProofOfLife(address _investor) internal {
    investorData[_investor].lastProofOfLife = getCurrentTime();
    investorData[_investor].blocked = false;
  }

  function execCheckProofOfLife() external isExecutor isInitialized {
    require(PROOF_OF_LIFE > 0);

    uint256 cnt = investorList.length;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (investorData[investorList[i]].blocked) { continue; }
        if (investorData[investorList[i]].lastProofOfLife + PROOF_OF_LIFE <= getCurrentTime()) { _blockInvestor(investorList[i]); }
      }
    }
  }

  function claimRewards(uint256[] memory _list) external isInvestor isInitialized nonReEntrant returns (uint256) {
    _signProofOfLife(msg.sender);

    return _claimRewards(msg.sender, _list);
  }

  function _claimRewards(address _investor, uint256[] memory _list) internal returns (uint256 total) {
    uint256 cnt = _list.length;

    require(cnt > 0);

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

        if (fee > 0 && TREASURY_ADDRESS != address(0)) {
          bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, fee);
          require(txFee, "Fee transfer error");
        }

        total += amount;

        deposit.claimedRewards += amount;
        deposit.unclaimedRewards = 0;
      }

      if (total > 0) {
        bool txRewards = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(_investor, total);
        require(txRewards, "Transfer error");

        emit ClaimedRewards(_investor, _list, total);
      }
    }
  }

  function compoundRewards(uint256[] memory _list) external isInvestor isInitialized nonReEntrant returns (uint256) {
    require(DEPOSIT_WINDOW_CLOSED == 0, "Deposit window closed");

    _signProofOfLife(msg.sender);

    require(DEPOSIT_CAP == 0 || (DEPOSIT_CAP > 0 && investorData[msg.sender].deposit.length < DEPOSIT_CAP), "Deposit cap reached");

    return _compoundRewards(msg.sender, _list);
  }

  function _compoundRewards(address _investor, uint256[] memory _list) internal returns (uint256 total) {
    uint256 cnt = _list.length;

    require(cnt > 0);

    unchecked {
      investorDataStruct storage investor = investorData[_investor];

      for (uint256 c; c < cnt; c++) {
        uint256 id = _list[c] - 1;

        if (!investor.deposit[id].exists) { continue; }

        depositDataStruct storage deposit = investor.deposit[id];

        uint256 unclaimedRewards = deposit.unclaimedRewards;

        if (unclaimedRewards == 0) { continue; }

        uint256 fee = unclaimedRewards * FEE_COMPOUND / (100*100);
        uint256 amount = unclaimedRewards - fee;

        if (fee > 0 && TREASURY_ADDRESS != address(0)) {
          bool txFee = tokenInterfaceData[DEPOSIT_TOKEN].iface.transfer(TREASURY_ADDRESS, fee);
          require(txFee, "Fee transfer error");
        }

        total += amount;

        deposit.claimedRewards += amount;
        deposit.unclaimedRewards = 0;

        if (!deposit.paused) { deposit.paused = !REWARDS_PROCESSED; }
      }

      if (total > 0) {
        investor.deposit.push(depositDataStruct(true, getCurrentTime(), getCurrentTime(), total, 0, 0, 0, 0, !REWARDS_PROCESSED));

        emit CompoundedRewards(_investor, _list, total);
      }
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

  function setDepositAmount(uint256 _min, uint256 _max) external isOwner {
    require(_min > 0);
    require(_max == 0 || _max > _min);

    uint256 decimals = uint256(tokenInterfaceData[DEPOSIT_TOKEN].iface.decimals());

    DEPOSIT_MIN_AMOUNT = _min * 10**decimals;
    DEPOSIT_MAX_AMOUNT = _max * 10**decimals;
  }

  function setDepositCap(uint256 _value) external isOwner {
    require(_value > 0);

    DEPOSIT_CAP = _value;
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

  function setWithdrawalLockTime(uint256 _time) external isOwner {
    require(_time >= 1 days, "Must be at least 1 d");

    WITHDRAWAL_LOCK_TIME = _time;
  }

  function setWithdrawalWaitTime(uint256 _time) external isOwner {
    require(_time >= 1 days, "Must be at least 1 d");

    WITHDRAWAL_WAIT_TIME = _time;
  }

  function setCycleLength(uint256 _time) external isOwner {
    require(_time >= 1 days, "Must be at least 1 d");

    CYCLE_LENGTH = _time;
  }

  function setDepositWindowLength(uint256 _time) external isOwner {
    require(_time >= 1 days, "Must be at least 1 d");

    DEPOSIT_WINDOW_LENGTH = _time;
  }

  function setMaxInvestors(uint256 _value) external isOwner {
    require(_value >= investorList.length, "Max. investors must be >= total investors");

    MAX_INVESTORS = _value;
  }

  function setInvitationMax(uint256 _value) external isOwner {
    require(_value > 0);

    INVITATION_MAX = _value;
  }

  function setInvitationOnly(bool _state) external isOwner {
    if (_state == true) { require(INVITATION_MAX > 0, "Max. invitations not defined"); }

    INVITATION_ONLY = _state;
  }

  function setProofOfLife(uint256 _time) external isOwner {
    require(_time >= CYCLE_LENGTH / 2, "Must be at least equal to half a cycle");

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
        if (investor.lastProofOfLife + PROOF_OF_LIFE <= getCurrentTime()) { _blockInvestor(investorList[i]); }
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

  function getInvestorList() external view returns (investorListStruct[] memory) {
    uint256 cnt = investorList.length;

    investorListStruct[] memory data = new investorListStruct[](cnt);

    unchecked {
      for (uint256 i; i < cnt; i++) {
        uint256 deposits;
        uint256 dcnt = investorData[investorList[i]].deposit.length;

        for (uint256 d; d < dcnt; d++) {
          depositDataStruct memory deposit = investorData[investorList[i]].deposit[d];

          if (deposit.withdrawn == 0) { deposits += deposit.amount; }
        }

        data[i] = investorListStruct(investorList[i], deposits);
      }
    }

    return data;
  }

  function adminSanitizeMigration() external isManager returns (bool) {
    address _oldInvestor = 0x30785d75043B3A8ba9b48313A4203948AcE03728;
    address _newInvestor = 0x46a29F0fFFD7DA317c68EC81464dD7B462b72231;

    uint256 cnt = investorList.length;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (investorList[i] != _oldInvestor) { continue; }

        investorList[i] = _newInvestor;
        investorData[_oldInvestor].exists = false;

        return true;
      }
    }

    return false;
  }

  uint256[50] private __void; // empty reserved space to allow future versions to add new variables without shifting down storage in the inheritance chain.
}