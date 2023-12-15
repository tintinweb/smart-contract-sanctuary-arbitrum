/**
 *Submitted for verification at Arbiscan.io on 2023-12-15
*/

/*
   ________          _       ______           __                  
  / ____/ /_  ____ _(_)___  / ____/___ ______/ /_____  _______  __
 / /   / __ \/ __ `/ / __ \/ /_  / __ `/ ___/ __/ __ \/ ___/ / / /
/ /___/ / / / /_/ / / / / / __/ / /_/ / /__/ /_/ /_/ / /  / /_/ / 
\____/_/ /_/\__,_/_/_/ /_/_/    \__,_/\___/\__/\____/_/   \__, /  
                                                         /____/   

  ChainFactory Smart-Contract

  Web:      https://chainfactory.app/
  X:        https://x.com/@ChainFactory
  Telegram: https://t.me/ChainFactory
  Discord:  https://discord.gg/fpjxD39v3k
  YouTube:  https://youtu.be/ChainFactory

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.23;

library Address {
  function isContract(address _contract) internal view returns (bool) {
    return _contract.code.length > 0;
  }
}

library Create2 {
  function predictAddress(bytes memory bytecode, bytes32 salt) internal view returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));

    return address(uint160(uint256(hash)));
  }

  function deploy(bytes memory bytecode, bytes32 salt) internal returns (address result) {
    assembly {
      result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
    }

    require(result != address(0), "Deploy failed");
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IMultiSignatureWallet {
  function listManagers(bool) external view returns (address[] memory);
}

interface IStake {
  function stakedAmount(address account) external view returns (uint256);
}

interface IInitialize {
  function initialize(bytes calldata data) external;
}

abstract contract CF_Ownable {
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() virtual {
    require(_owner == msg.sender, "Unauthorized");

    _;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  function renounceOwnership() external onlyOwner {
    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));

    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

abstract contract CF_Common {
  string internal constant _version = "1.0.0";
  IERC20 internal FACTORY_TOKEN;
  IStake internal FACTORY_STAKE;
  address internal MULTISIGN_ADDRESS;
  address internal TREASURY_ADDRESS;
  address[] internal _userList;
  address[] internal _deployerList;
  uint256[] internal _templateList;
  uint24 internal constant denominator = 1000;
  bool internal _locked;
  bool internal _initialized;

  mapping(address => userData) internal _userData;
  mapping(uint8 => discountLevel) internal _discountLevel;
  mapping(uint256 => templateData) internal _templateData;

  struct templateData {
    bool exists;
    bool active;
    bool discountable;
    mapping(uint256 => uint256) price;
    uint256 features;
  }

  struct templateDataView {
    uint256 id;
    bool discountable;
    uint256 price;
    uint256[] features;
  }

  struct userData {
    bool exists;
    uint256 balance;
    mapping(bytes32 => deployData) deploy;
    bytes32[] deployList;
    addedCreditData[] addedCredit;
  }

  struct userDataView {
    uint256 balance;
    deployView[] deploy;
    addedCreditData[] addedCredit;
  }

  struct addedCreditData {
    uint32 timestamp;
    uint256 amount;
    address origin;
  }

  struct deployData {
    bool exists;
    uint256 templateId;
    uint32 paidTimestamp;
    uint32 deployTimestamp;
    uint32 refundTimestamp;
    uint256 price;
    uint256 amount;
    uint256 credit;
    uint256 discount;
    uint256 gas;
    uint256 features;
    address contractAddress;
    address deployer;
  }

  struct deployView {
    bytes32 receipt;
    uint256 templateId;
    uint32 paidTimestamp;
    uint32 deployTimestamp;
    uint32 refundTimestamp;
    uint256 price;
    uint256 amount;
    uint256 credit;
    uint256 discount;
    uint256 gas;
    uint256 features;
    address contractAddress;
    address deployer;
  }

  struct pendingDeployView {
    address user;
    address deployer;
    bytes32 receipt;
    uint256 templateId;
    uint256 gas;
    uint256 features;
  }

  struct discountLevel {
    bool exists;
    uint24 percent;
    uint24 discount;
  }

  struct discountLevelView {
    uint8 level;
    uint24 percent;
    uint24 discount;
  }

  function _percentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    unchecked {
      return (amount * bps) / (100 * uint256(denominator));
    }
  }

  function _timestamp() internal view returns (uint32) {
    unchecked {
      return uint32(block.timestamp % 2**32);
    }
  }

  function _countBits(uint256 bitmask) internal pure returns (uint256 count) {
    unchecked {
      while (bitmask > 0) {
        if (bitmask % 2 == 1) { count++; }

        bitmask >>= 1;
      }
    }
  }

  function version() external pure returns (string memory) {
    return _version;
  }
}

contract ChainFactory is CF_Ownable, CF_Common {
  event Deposit(address indexed from, uint256 amount);
  event TemplatePaid(address indexed user, uint256 amount, bytes32 receipt);
  event TemplateDeployed(address indexed user, bytes32 receipt, uint256 templateId, address contractAddress);
  event TemplateRefund(address indexed user, uint256 amount, bytes32 receipt);
  event AddedCredit(address indexed user, uint256 amount);
  event AddedGas(address indexed user, uint256 amount, bytes32 receipt);
  event RefundedGas(address indexed user, uint256 amount, bytes32 receipt);
  event SetDiscountLevel(uint8 level, uint24 percent, uint24 discount);

  modifier nonReentrant() {
    require(!_locked, "No re-entrancy");

    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyOwner() virtual override {
    require(msg.sender == _owner || (MULTISIGN_ADDRESS != address(0) && msg.sender == MULTISIGN_ADDRESS), "Unauthorized");

    _;
  }

  modifier onlyManager() {
    require(MULTISIGN_ADDRESS != address(0));

    address[] memory managers = IMultiSignatureWallet(MULTISIGN_ADDRESS).listManagers(true);

    uint256 cnt = managers.length;
    bool proceed;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (managers[i] != msg.sender) { continue; }

        proceed = true;
      }
    }

    require(proceed, "Not manager");

    _;
  }

  modifier onlyDeployer() {
    uint256 cnt = _deployerList.length;
    bool proceed;

    unchecked {
      for (uint256 i; i < cnt; i++) {
        if (_deployerList[i] != msg.sender) { continue; }

        proceed = true;
      }
    }

    require(proceed, "Not deployer");

    _;
  }

  modifier isTemplate(uint256 templateId) {
    require(_templateData[templateId].exists && _templateData[templateId].active, "Unknown template");

    _;
  }

  function initialize() external {
    require(!_initialized);

    _transferOwnership(msg.sender);
    _initialized = true;
  }

  function setTemplate(uint256 templateId, bool active, bool discountable, uint256[] calldata price) external onlyOwner {
    uint256 cnt = price.length;

    require(cnt > 0 && cnt < 64);

    if (!_templateData[templateId].exists) {
      _templateData[templateId].exists = true;
      _templateList.push(templateId);
    }

    _templateData[templateId].active = active;
    _templateData[templateId].discountable = discountable;

    unchecked {
      _templateData[templateId].features = cnt - 1;

      for (uint256 f; f < cnt; f++) { _templateData[templateId].price[f] = price[f]; }
    }
  }

  function _addUser(address _addr) private {
    _userList.push(_addr);
    _userData[_addr].exists = true;
  }

  function addCredit() public payable nonReentrant() {
    require(msg.value > 0);
    require(TREASURY_ADDRESS != address(0), "No treasury");

    _addCredit(msg.sender, msg.value);
  }

  function _addCredit(address user, uint256 amount) private {
    if (!_userData[user].exists) { _addUser(user); }

    unchecked {
      _userData[user].balance += amount;
      _userData[user].addedCredit.push(addedCreditData(_timestamp(), amount, user));

      emit AddedCredit(user, amount);
    }

    if (amount > 0) {
      (bool success, ) = TREASURY_ADDRESS.call{ value: amount }("");

      require(success, "Transfer error");
    }
  }

  function refundGas(address user, bytes32 receipt) external payable onlyDeployer {
    require(_userData[user].exists, "Unknown user");
    require(_userData[user].deploy[receipt].exists, "Unknown receipt");

    (bool success, ) = payable(user).call{ value: msg.value }("");

    require(success, "Transfer error");

    emit RefundedGas(user, msg.value, receipt);
  }

  function getTemplatePrice(uint256 templateId, uint256 features) public view isTemplate(templateId) returns (uint256 price) {
    unchecked {
       uint256 cnt = _countBits(features);

       require(cnt <= _templateData[templateId].features, "Invalid number of features");

      for (uint256 f; f < cnt; f++) {
        if ((features & (1 << f)) == 0) { continue; }

        price += _templateData[templateId].price[f];
      }
    }
  }

  function payTemplate(uint256 templateId, uint256 gas, bytes32 nonce, uint256 features) external payable isTemplate(templateId) nonReentrant returns (bytes32 receipt) {
    require(TREASURY_ADDRESS != address(0), "No treasury");

    uint256 amount = msg.value;

    if (gas > 0) {
      require(_deployerList.length > 0, "No deployer");
      require(amount >= gas, "Gas fee error");
    }

    uint256 price = getTemplatePrice(templateId, features);
    uint256 discount = _percentage(uint256(price), uint256(_getDiscountPercent(msg.sender)));
    uint256 credit;
    uint256 refund;
    address deployer = gas > 0 ? _randomDeployer(nonce) : msg.sender;

    if (!_userData[msg.sender].exists) { _addUser(msg.sender); }

    unchecked {
      if (gas > 0) { amount -= gas; }
      if (discount > 0) { price -= discount; }

      if (_userData[msg.sender].balance > 0) {
        credit = _userData[msg.sender].balance >= price ? price : _userData[msg.sender].balance;

        _userData[msg.sender].balance -= credit;
      }

      require(amount + credit >= price, "Underpayment");

      if (amount >= price) {
        refund = (amount + credit) - price;
        amount -= refund;
      }
    }

    if (refund > 0) {
      if (gas > 0) {
        gas += refund;
      } else {
        _addCredit(msg.sender, refund);
      }
    }

    if (amount > 0) {
      (bool success, ) = TREASURY_ADDRESS.call{ value: amount }("");

      require(success, "Transfer error");
    }

    if (gas > 0) {
      (bool success, ) = payable(deployer).call{ value: gas }("");

      require(success, "Transfer error");
    }

    receipt = keccak256(abi.encodePacked(templateId, _timestamp(), nonce, msg.sender));

    _userData[msg.sender].deployList.push(receipt);
    _userData[msg.sender].deploy[receipt] = deployData(true, templateId, _timestamp(), 0, 0, price, amount, credit, discount, gas, features, address(0), deployer);

    emit TemplatePaid(msg.sender, amount, receipt);
  }

  function addGas(bytes32 receipt) external payable nonReentrant {
    require(msg.value > 0);
    require(_userData[msg.sender].exists, "Unknown user");
    require(_userData[msg.sender].deploy[receipt].exists, "Unknown receipt");
    require(_userData[msg.sender].deploy[receipt].gas > 0, "Non deployable");

    if (_userData[msg.sender].deploy[receipt].contractAddress != address(0)) {
      if (_userData[msg.sender].deploy[receipt].contractAddress == address(0xdEaD)) { revert("Deployment canceled"); }

      revert("Already deployed");
    }

    (bool success, ) = payable(_userData[msg.sender].deploy[receipt].deployer).call{ value: msg.value }("");

    require(success, "Transfer error");

    unchecked {
      _userData[msg.sender].deploy[receipt].gas += msg.value;
    }

    emit AddedGas(msg.sender, msg.value, receipt);
  }

  function adminCancelDeployTemplate(address user, bytes32 receipt, bool refund) external onlyManager {
    require(_userData[user].exists, "Unknown user");
    require(_userData[user].deploy[receipt].exists, "Unknown receipt");

    if (_userData[msg.sender].deploy[receipt].contractAddress != address(0)) {
      if (_userData[msg.sender].deploy[receipt].contractAddress == address(0xdEaD)) { revert("Deployment canceled"); }

      revert("Already deployed");
    }

    if (refund) {
      unchecked {
        uint256 amount = _userData[user].deploy[receipt].amount + _userData[user].deploy[receipt].credit + _userData[user].deploy[receipt].gas;

        _userData[user].balance += amount;
        _userData[user].deploy[receipt].refundTimestamp = _timestamp();

        emit TemplateRefund(user, amount, receipt);
      }
    }

    _userData[user].deploy[receipt].contractAddress = address(0xdEaD);
  }

  function adminDeployTemplate(address user, bytes32 receipt, bytes memory bytecode, bytes calldata data) external onlyManager nonReentrant returns (address) {
    return _deployTemplate(user, receipt, bytecode, data);
  }

  function publicDeployTemplate(bytes32 receipt, bytes memory bytecode, bytes calldata data) external nonReentrant returns (address) {
    return _deployTemplate(msg.sender, receipt, bytecode, data);
  }

  function execDeployTemplate(address user, bytes32 receipt, bytes memory bytecode, bytes calldata data) external onlyDeployer nonReentrant returns (address) {
    return _deployTemplate(user, receipt, bytecode, data);
  }

  function _deployTemplate(address user, bytes32 receipt, bytes memory bytecode, bytes calldata data) private returns (address contractAddress) {
    require(_userData[user].exists, "Unknown user");
    require(_userData[user].deploy[receipt].exists, "Unknown receipt");

    if (_userData[msg.sender].deploy[receipt].contractAddress != address(0)) {
      if (_userData[msg.sender].deploy[receipt].contractAddress == address(0xdEaD)) { revert("Deployment canceled"); }

      revert("Already deployed");
    }

    require(_userData[user].deploy[receipt].deployer == msg.sender, "Invalid deployer");

    address predictAddress = Create2.predictAddress(bytecode, receipt);

    require(!Address.isContract(predictAddress), "Already exists");

    contractAddress = Create2.deploy(bytecode, receipt);

    require(predictAddress == contractAddress, "Not the predicted one");

    _userData[user].deploy[receipt].deployTimestamp = _timestamp();
    _userData[user].deploy[receipt].contractAddress = contractAddress;

    emit TemplateDeployed(user, receipt, _userData[user].deploy[receipt].templateId, contractAddress);

    if (data.length > 0) {
      try IInitialize(contractAddress).initialize(data) { } catch { }
    }
  }

  function listTemplates() public view returns (templateDataView[] memory data) {
    uint256 cnt = _templateList.length;
    uint256 len = _countActiveTemplates();
    uint256 i;

    data = new templateDataView[](len);

    unchecked {
      for (uint256 t; t < cnt; t++) {
        uint256 templateId = _templateList[t];

        if (!_templateData[templateId].active) { continue; }

        uint256 fcnt = _templateData[templateId].features;
        uint256[] memory features = new uint256[](fcnt);

        for (uint256 f = 1; f - 1 < fcnt; f++) { features[uint256(f - 1)] = uint256(_templateData[templateId].price[f]); }

        data[i++] = templateDataView(templateId, _templateData[templateId].discountable, _templateData[templateId].price[0], features);
      }
    }
  }

  function listPendingDeploys() external view returns (pendingDeployView[] memory data) {
    uint256 cnt = _userList.length;
    uint256 pcnt = _countPendingDeploys();
    uint256 i;

    data = new pendingDeployView[](pcnt);

    unchecked {
      for (uint256 u; u < cnt; u++) {
        uint256 dcnt = _userData[_userList[u]].deployList.length;

        if (dcnt == 0) { continue; }

        for (uint256 d; d < dcnt; d++) {
          bytes32 receipt = _userData[_userList[u]].deployList[d];
          deployData memory deploy = _userData[_userList[u]].deploy[receipt];

          if (deploy.contractAddress != address(0) || deploy.gas == 0) { continue; }

          data[i++] = pendingDeployView(_userList[u], deploy.deployer, receipt, deploy.templateId, deploy.gas, deploy.features);
        }
      }
    }
  }

  function listUsers() external view returns (address[] memory data) {
    uint256 cnt = _userList.length;
    uint256 i;

    data = new address[](cnt);

    unchecked {
      for (uint256 u; u < cnt; u++) { data[i++] = _userList[u]; }
    }
  }

  function getUserInfo(address account) external view returns (userDataView memory user) {
    require(_userData[account].exists, "Unknown user");

    uint256 cnt = _userData[account].deployList.length;

    user.balance = _userData[account].balance;
    user.deploy = new deployView[](cnt);
    user.addedCredit = _userData[account].addedCredit;

    unchecked {
      for (uint256 d; d < cnt; d++) {
        bytes32 receipt = _userData[account].deployList[d];
        deployData memory deploy = _userData[account].deploy[receipt];

        user.deploy[d] = deployView(receipt, deploy.templateId, deploy.paidTimestamp, deploy.deployTimestamp, deploy.refundTimestamp, deploy.price, deploy.amount, deploy.credit, deploy.discount, deploy.gas, deploy.features, deploy.contractAddress, deploy.deployer);
      }
    }
  }

  function listDiscountLevels() external view returns (discountLevelView[] memory list) {
    list = new discountLevelView[](5);

    unchecked {
      for (uint8 i; i < 5; i++) { list[i] = discountLevelView(i, _discountLevel[i].percent, _discountLevel[i].discount); }
    }
  }

  function setDiscountLevel(uint8 level, uint24 percent, uint24 discount) external onlyOwner {
    require(level < 3);

    unchecked {
      require(percent <= denominator * 100);

      if (level + 1 < 3 && _discountLevel[level + 1].exists) { require(_discountLevel[level + 1].percent > percent); }
      if (level - 1 >= 0 && _discountLevel[level - 1].exists) { require(_discountLevel[level - 1].percent < percent); }
    }

    if (!_discountLevel[level].exists) { _discountLevel[level].exists = true; }

    _discountLevel[level].percent = percent;
    _discountLevel[level].discount = discount;

    emit SetDiscountLevel(level, percent, discount);
  }

  function _getDiscountPercent(address user) private view returns (uint24 discount) {
    if (address(FACTORY_TOKEN) == address(0)) { return 0; }

    uint256 balance = FACTORY_TOKEN.balanceOf(user);
    uint256 staked = address(FACTORY_STAKE) != address(0) ? FACTORY_STAKE.stakedAmount(user) : 0;

    if (balance == 0 && staked == 0) { return 0; }

    uint256 amount = balance > staked ? balance : staked;

    unchecked {
      uint24 pct = uint24((uint256(denominator) * amount * 100) / FACTORY_TOKEN.totalSupply());

      for (uint8 i; i < 3; i++) {
        if (!_discountLevel[i].exists || pct < _discountLevel[i].percent) { continue; }
        if (pct > _discountLevel[i].percent) { break; }

        discount = _discountLevel[i].discount;
      }
    }
  }

  function _countPendingDeploys() private view returns (uint256 pending) {
    uint256 cnt = _userList.length;

    unchecked {
      for (uint256 u; u < cnt; u++) {
        uint256 dcnt = _userData[_userList[u]].deployList.length;

        if (dcnt == 0) { continue; }

        for (uint256 d; d < dcnt; d++) {
          bytes32 receipt =  _userData[_userList[u]].deployList[d];

          if (_userData[_userList[u]].deploy[receipt].contractAddress != address(0) || _userData[_userList[u]].deploy[receipt].gas == 0) { continue; }

          pending++;
        }
      }
    }
  }

  function _countActiveTemplates() private view returns (uint256 active) {
    uint256 cnt = _templateList.length;

    unchecked {
      for (uint256 t; t < cnt; t++) {
        if (!_templateData[_templateList[t]].active) { continue; }

        active++;
      }
    }
  }

  function setMultiSignatureWallet(address account) external onlyOwner {
    MULTISIGN_ADDRESS = account;
  }

  function setDeployers(address[] calldata deployer) external onlyOwner {
    if (_deployerList.length > 0) { delete _deployerList; }

    _deployerList = deployer;
  }

  function _randomDeployer(bytes32 nonce) private view returns (address deployer) {
    uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, nonce)));
    uint256 deployerId = random % _deployerList.length;

    deployer = payable(_deployerList[deployerId]);
  }

  function setTreasury(address payable account) external onlyOwner {
    TREASURY_ADDRESS = account;
  }

  function setFactoryInterfaces(address token, address stake) external onlyOwner {
    FACTORY_TOKEN = IERC20(token);
    FACTORY_STAKE = IStake(stake);
  }

  function recoverERC20(address token, address to, uint256 amount) external onlyOwner {
    IERC20(token).transfer(to, amount);
  }

  function recoverETH(address payable to, uint256 amount) external onlyOwner {
    (bool success, ) = to.call{ value: amount }("");

    require(success);
  }

  receive() external payable { addCredit(); }
  fallback() external payable { }
}