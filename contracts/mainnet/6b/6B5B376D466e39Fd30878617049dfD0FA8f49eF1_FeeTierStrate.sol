// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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
    _transferOwnership(_msgSender());
  }

  modifier onlyOwner() {
    _checkOwner();
    _;
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  function _checkOwner() internal view virtual {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
  }

  function renounceOwnership() public virtual onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal virtual {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

contract FeeTierStrate is Ownable {
  struct FeeRecObj {
    uint256 index;
    string title;
    address account;
    uint256 feePercent;
    bool exist;
  }

  struct ManagerObj {
    uint256 index;
    bool exist;
  }

  uint256 public MAX_FEE = 1000000;
  uint256 public MAX_INDEX = 1;
  mapping (uint256 => uint256) private depositFee;
  mapping (uint256 => uint256) private totalFee;
  mapping (uint256 => uint256) private withdrawlFee;
  uint256 private baseFee = 1000000;

  mapping (uint256 => FeeRecObj) private _feeTier;
  uint256[] private _tierIndex;

  mapping (address => ManagerObj) private _manageAccess;
  address[] private _feeManager;

  modifier onlyManager() {
    require(msg.sender == owner() || _manageAccess[msg.sender].exist, "!manager");
    _;
  }

  constructor () {
    totalFee[0] = 100000;
    totalFee[1] = 100000;
    totalFee[2] = 100000;
    totalFee[3] = 100000;
    totalFee[4] = 100000;
    totalFee[5] = 100000;
    totalFee[6] = 100000;
    totalFee[7] = 100000;
    totalFee[8] = 100000;
  }

  function getAllManager() public view returns(address[] memory) {
    return _feeManager;
  }

  function setManager(address usraddress, bool access) public onlyOwner {
    if (access == true) {
      if ( ! _manageAccess[usraddress].exist) {
        uint256 newId = _feeManager.length;
        _manageAccess[usraddress] = ManagerObj(newId, true);
        _feeManager.push(usraddress);
      }
    }
    else {
      if (_manageAccess[usraddress].exist) {
        address lastObj = _feeManager[_feeManager.length - 1];
        _feeManager[_manageAccess[usraddress].index] = _feeManager[_manageAccess[lastObj].index];
        _feeManager.pop();
        delete _manageAccess[usraddress];
      }
    }
  }

  function getMaxFee() public view returns(uint256) {
    return MAX_FEE;
  }

  function setMaxFee(uint256 newFee) public onlyManager {
    MAX_FEE = newFee;
  }

  function setDepositFee(uint256 id, uint256 newFee) public onlyManager {
    depositFee[id] = newFee;
  }

  function setTotalFee(uint256 id, uint256 newFee) public onlyManager {
    totalFee[id] = newFee;
  }

  function setWithdrawFee(uint256 id, uint256 newFee) public onlyManager {
    withdrawlFee[id] = newFee;
  }

  function setBaseFee(uint256 newFee) public onlyManager {
    baseFee = newFee;
  }

  function getDepositFee(uint256 id) public view returns(uint256, uint256) {
    return (depositFee[id], baseFee);
  }

  function getTotalFee(uint256 id) public view returns(uint256, uint256) {
    return (totalFee[id], baseFee);
  }

  function getWithdrawFee(uint256 id) public view returns(uint256, uint256) {
    return (withdrawlFee[id], baseFee);
  }

  function getAllTier() public view returns(uint256[] memory) {
    return _tierIndex;
  }

  function insertTier(string memory title, address account, uint256 fee) public onlyManager {
    require(fee <= MAX_FEE, "Fee tier value is overflowed");
    _tierIndex.push(MAX_INDEX);
    _feeTier[MAX_INDEX] = FeeRecObj(_tierIndex.length - 1, title, account, fee, true);
    MAX_INDEX = MAX_INDEX + 1;
  }

  function getTier(uint256 index) public view returns(address, string memory, uint256) {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    FeeRecObj memory tierItem = _feeTier[index];
    return (tierItem.account, tierItem.title, tierItem.feePercent);
  }

  function updateTier(uint256 index, string memory title, address account, uint256 fee) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be loaded");
    require(fee <= MAX_FEE, "Fee tier value is overflowed");
    _feeTier[index].title = title;
    _feeTier[index].account = account;
    _feeTier[index].feePercent = fee;
  }

  function removeTier(uint256 index) public onlyManager {
    require(_feeTier[index].exist, "Only existing tier can be removed");
    uint256 arr_index = _feeTier[index].index;
    uint256 last_index = _tierIndex[_tierIndex.length-1];
    
    FeeRecObj memory changedObj = _feeTier[last_index];
    _feeTier[last_index] = FeeRecObj(arr_index, changedObj.title, changedObj.account, changedObj.feePercent, true);
    _tierIndex[arr_index] = last_index;
    _tierIndex.pop();
    delete _feeTier[index];
  }
}