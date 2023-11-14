// SPDX-License-Identifier: MIT
//website: https://memeordi.org
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract MemeOrdi is Ownable, ReentrancyGuard {
    struct Inscription {
        address deployer;
        string tickName;
        uint256 totalSupply;
        uint256 limitPerMint;
        uint256 mintedAmount;
        uint256 mintedCnt;
        mapping (address => uint256) balanceOf;
    }

    address public protocolFeeTo;
    uint256 public protocolFeePercent;
    uint256 public subjectFeePercent;
    uint256 public deployFee;
    uint256 public mintFee;
    uint256 public mintIndex;

    mapping(bytes32 => Inscription) public inscriptions;

    event MintEvent(uint256 eventIndex, uint256 ts, address trader, string tickName, uint256 amount,
        uint256 ethAmount, uint256 protocolEthAmount, uint256 subjectEthAmount, uint256 traderBalance, uint256 mintedAmount);

    event Transfer(address indexed from, address indexed to, string tickName, uint256 value);

    constructor() {
        protocolFeeTo = msg.sender;
        protocolFeePercent = 0.5 ether; // 50%
        subjectFeePercent = 0.5 ether; // 50%
        deployFee = 0.0005 ether;
        mintFee = 0.0005 ether;
    }

    function setDeployFee(uint256 amount) external onlyOwner {
        deployFee = amount;
    }

    function setMintFee(uint256 amount) external onlyOwner {
        mintFee = amount;
    }

    function deploy(string memory _name, uint256 _totalSupply, uint256 _limitPerMint) external payable nonReentrant {
      require(_limitPerMint < _totalSupply, "_limitPerMint should less than _totalSupply");
      require(msg.value >= deployFee, "Insufficient payment");
      bytes32 key = getInscriptionKey(_name);
      Inscription storage isp = inscriptions[key];
      require(isp.deployer == address(0), "tick already deployed!");

      bool success;
      (success, ) = protocolFeeTo.call{value: msg.value}(new bytes(0));
      require(success, "Unable to send funds");

      isp.deployer = msg.sender;
      isp.tickName = _name;
      isp.totalSupply = _totalSupply;
      isp.limitPerMint = _limitPerMint;
    }

    function mintInscription(string memory _name, uint256 _amount) external payable nonReentrant {
      bytes32 key = getInscriptionKey(_name);
      Inscription storage isp = inscriptions[key];
      require(isp.deployer != address(0), "tick not deploy yet!");
      require(_amount <= isp.limitPerMint, "_amount large than _amount!");
      require(msg.value >= mintFee, "Insufficient payment");
      require((_amount + isp.mintedAmount) <= isp.totalSupply, "added new mint amount large than totalSupply");

      uint256 protocolFee = msg.value * protocolFeePercent / 1 ether;
      uint256 subjectFee = msg.value * subjectFeePercent / 1 ether;
      require((protocolFee + subjectFee) <= msg.value, "can not transfer more eth fee out than input!");
      
      bool success;
      (success, ) = protocolFeeTo.call{value: protocolFee}(new bytes(0));
      require(success, "Unable to send funds");
      (success, ) = isp.deployer.call{value: subjectFee}(new bytes(0));
      require(success, "Unable to send funds");

      isp.mintedAmount += _amount;
      isp.mintedCnt += 1;
      isp.balanceOf[msg.sender] += _amount;
      uint256 ethAmount = protocolFee + subjectFee;
      emit MintEvent(mintIndex++, block.timestamp, msg.sender, _name, _amount, ethAmount, protocolFee, subjectFee, isp.balanceOf[msg.sender], isp.mintedAmount);
    }

    function transferInscription(string memory _name, uint256 _amount, address _recipient) external nonReentrant {
      bytes32 key = getInscriptionKey(_name);
      Inscription storage isp = inscriptions[key];
      require(isp.deployer != address(0), "tick not deploy yet!");
      require(_amount <= isp.balanceOf[msg.sender], "amount large than balance");

      isp.balanceOf[msg.sender] -= _amount;
      isp.balanceOf[_recipient] += _amount;
      emit Transfer(msg.sender, _recipient, _name, _amount);
    }

    function balanceOf(string memory _name) public view returns (uint256) {
      return balanceOfAddr(_name, msg.sender);
    }

    function balanceOfAddr(string memory _name, address addr) public view returns (uint256) {
      bytes32 key = getInscriptionKey(_name);
      Inscription storage isp = inscriptions[key];
      require(isp.deployer != address(0), "tick not deploy yet!");
      return isp.balanceOf[addr];
    }

    function getInscription(string memory _name) public view returns (uint256, uint256, uint256, uint256, string memory, address) {
      bytes32 key = getInscriptionKey(_name);
      Inscription storage isp = inscriptions[key];
      require(isp.deployer != address(0), "tick not deploy yet!");

      return (
        isp.totalSupply,
        isp.limitPerMint,
        isp.mintedAmount,
        isp.mintedCnt,
        isp.tickName,
        isp.deployer
      );
    }

    function getInscriptionKey(string memory _name) public pure returns (bytes32) {
      return keccak256(abi.encodePacked(_name));
    }
}