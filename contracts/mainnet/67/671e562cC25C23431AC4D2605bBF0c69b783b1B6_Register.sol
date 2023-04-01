// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract EIP712 {
  bytes32 private immutable DOMAIN_SEPARATOR;
  uint256 private immutable CHAIN_ID;
  address private immutable THIS;

  bytes32 private immutable NAME_HASH;
  bytes32 private immutable VERSION_HASH;
  bytes32 private immutable TYPE_HASH;

  constructor(string memory _name, string memory _version) {
    bytes32 nameHash = keccak256(bytes(_name));
    bytes32 versionHash = keccak256(bytes(_version));
    bytes32 typeHash = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );
    NAME_HASH = nameHash;
    VERSION_HASH = versionHash;
    CHAIN_ID = block.chainid;
    DOMAIN_SEPARATOR = buildDomainSeparator(typeHash, nameHash, versionHash);
    THIS = address(this);
    TYPE_HASH = typeHash;
  }

  function buildDomainSeparator(bytes32 _typeHash, bytes32 _nameHash, bytes32 _versionHash) private view returns (bytes32) {
     return keccak256(abi.encode(_typeHash, _nameHash, _versionHash, block.chainid, address(this)));
  }

  function _domainSeparator() internal view returns (bytes32) {
    if(address(this) == THIS && block.chainid == CHAIN_ID) {
      return DOMAIN_SEPARATOR;
    } else {
      return buildDomainSeparator(TYPE_HASH, NAME_HASH, VERSION_HASH);
    }
  }

  function _createMessageHash(bytes32 _structHash) internal view returns (bytes32) {
    return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), _structHash));
  }

  function domainSeparator() external view returns (bytes32) {
    return _domainSeparator();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./Token.sol";
import "./EIP712.sol";

interface IWhitelist {
    function registerWhitelist(address) external view returns (bool);
    function whitelists(address) external view returns (bool);
    function whitelistAddress(address) external;
    function removeAddressFromWhitelist(address) external;
} 

contract Register is Token, EIP712 {
  address payable public issuer;
  address public registrar;
  address public rescue;
  event IssuerTransferred(address indexed to);
  event RegistrarTransferred(address indexed to);
  event RescueTransferred(address indexed to);

  address public whitelistContract;
  event WhitelistContractChanged(address indexed to);

  mapping(address => uint256) public nonces;
  bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  bool public paused;
  event RegisterPaused(address pauser);
  event RegisterUnpaused(address pauser);

  string public version;
  bytes12 public isin;
  bytes32 public terms;
  uint public lockdown;
  event IsinChanged(bytes12 newIsin);
  event TermsChanged(bytes32 newHash);
  event LockdownChanged(uint newLockDown);

  event Minted(address indexed to, uint256 amount);
  event Burned(address indexed from, uint256 amount);
  
  event TransferForced(address indexed from, address indexed to, uint256 value);
  event IssuerTokenTransferred(address indexed to, uint256 value);

  modifier onlyRescue {
    require(msg.sender == rescue, "only rescue can call this");
    _;
  }
  modifier onlyRegistrar {
    require(msg.sender == registrar, "only registrar can call this");
    _;
  }
  
  constructor(
    string memory _name, 
    string memory _symbol, 
    string memory _version,
    address payable _issuer, 
    address payable _registrar, 
    address payable _rescue,
    bool _paused,
    uint _lockdown,
    uint256 _totalSupply
    ) 
    Token(_name, _symbol) EIP712(_name, _version) {
    issuer = _issuer;
    registrar = _registrar;
    rescue = _rescue;

    paused = _paused;
    version = _version;

    lockdown = _lockdown;

    if(_totalSupply > 0) {
      _mint(issuer, _totalSupply);
    }
  }

  function changeWhitelistContract(address to) external returns (bool) {
    require(to != address(0), "whitelist cannot be zero address");
    uint len;
    assembly {
      len := extcodesize(to)
    }
    require(len >= 0, "whitelist must be contract");
    whitelistContract = to;
    emit WhitelistContractChanged(to);
    return true;
  }

  // Whitelist-Contract Funktionen

  function isRegisterWhitelisted() external view returns (bool) {
    return IWhitelist(whitelistContract).registerWhitelist(address(this));
  }

  function isAddressWhitelisted(address holder) public view returns (bool) {
    return IWhitelist(whitelistContract).whitelists(holder);
  }

  function whitelistAddress(address holder) external onlyRegistrar {
    IWhitelist(whitelistContract).whitelistAddress(holder);
  }

  function removeAddressFromWhitelist(address holder) external onlyRegistrar {
    IWhitelist(whitelistContract).removeAddressFromWhitelist(holder);
  }

  //Tokensale Funktionen

  function transfer(address to, uint256 value) public {
    require(!isLockedDown(), "Contract is locked");
    require(!paused, "Contract is paused");
    require(isAddressWhitelisted(msg.sender), "caller must be whitelisted");
    require(isAddressWhitelisted(to), "receiver must be whitelisted");

    _transfer(msg.sender, to, value, true);
  }

  function transferFrom(address from, address to, uint256 value) public {
    require(!isLockedDown(), "Contract is locked");
    require(!paused, "Contract is paused");
    require(isAddressWhitelisted(msg.sender), "caller must be whitelisted");
    require(isAddressWhitelisted(from), "sender must be whitelisted");
    require(isAddressWhitelisted(to), "receiver must be whitelisted");

    _transfer(from, to, value, true);
  } 

  function approve(address spender, uint256 value) public returns (bool) {
    require(!isLockedDown(), "Contract is locked");
    require(!paused, "Contract is paused");
    require(isAddressWhitelisted(msg.sender), "sender must be whitelisted");

    _approve(msg.sender, spender, value);
    return true;
  }

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external {
    require(!isLockedDown(), "Contract is locked");
    require(!paused, "Contract is paused");
    require(isAddressWhitelisted(owner), "owner must be whitelisted");
    require(isAddressWhitelisted(spender), "spender must be whitelisted");
    require(isAddressWhitelisted(msg.sender), "caller must be whitelisted");
    require(block.timestamp <= deadline, "expired deadline");

    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner], deadline));
    bytes32 hash = _createMessageHash(structHash);
    address signer = ecrecover(hash, v, r, s);
    require(signer == owner, "invalid signature");

    nonces[owner]++;
    _approve(owner, spender, value);
  }

  //eWpG Rollen ändern

  function transferIssuer(address payable to) external onlyRegistrar {
    require(to != address(0), "new issuer cannot be zero address");
    transferIssuerToken(to, balanceOf(issuer));
    IWhitelist(whitelistContract).removeAddressFromWhitelist(issuer);
    IWhitelist(whitelistContract).whitelistAddress(to);
    issuer = to;
    emit IssuerTransferred(to);
  }

  function transferRegistrar(address payable to) external onlyRescue {
    require(to != address(0), "new registrar cannot be zero address");
    IWhitelist(whitelistContract).removeAddressFromWhitelist(registrar);
    IWhitelist(whitelistContract).whitelistAddress(to);
    registrar = to;
    emit RegistrarTransferred(to);
  }

  function transferRescue(address payable to) external onlyRescue {
    require(to != address(0), "new rescue cannot be zero address");
    rescue = to;
    emit RescueTransferred(to);
  }

  // eWpG Angaben ändern

  function changeIsin(bytes12 value) external onlyRegistrar {
    isin = value;
    emit IsinChanged(value);
  }

  function changeTerms(bytes32 value) external onlyRegistrar {
    terms = value;
    emit TermsChanged(value);
  }

  function changeLockDown(uint value) external onlyRegistrar {
    lockdown = value;
    emit LockdownChanged(value);
  }

  function isLockedDown() public view returns (bool) {
    return block.timestamp <= lockdown;
  }

  //eWpG Tokenbesitz ändern
  
  function transferIssuerToken(address to, uint256 value) public onlyRegistrar {   
    if(isAddressWhitelisted(to) == false) {
      IWhitelist(whitelistContract).whitelistAddress(to);
    }
    _transfer(issuer, to, value, false);
  }

  function transferIssuerTokenBulk(address[] memory _to, uint256[] memory _value) public onlyRegistrar returns (bool) {
    require(_to.length == _value.length, "number of receivers must be equal to bulk size");
              
    for (uint i = 0; i < _to.length; i++) {
        transferIssuerToken(_to[i], _value[i]);
    }
    return true;
  }

  function forceTransfer(address from, address to, uint256 value) public onlyRegistrar returns (bool) {
    require(isAddressWhitelisted(to), "TokenSale forceTransfer: recipient must be whitelisted");

    _transfer(from, to, value, false);
    emit TransferForced(from, to, value);
    return true;
  }

  function forceTransferBulk(address[] memory from, address[] memory to, uint256[] memory  values) external onlyRegistrar {
    require(from.length == values.length, "number of senders must be equal to bulk size");
    require(to.length == values.length, "number of receivers must be equal to bulk size");
              
    for (uint i = 0; i < to.length; i++) {
      forceTransfer(from[i], to[i], values[i]);
    }
  }

  function pause() public onlyRegistrar {
    paused = true;
    emit RegisterPaused(msg.sender);
  }
  function unpause() public onlyRegistrar {
    paused = false;
    emit RegisterUnpaused(msg.sender);
  }

  function mint(uint256 value) public onlyRegistrar {
    _mint(issuer, value);
    emit Minted(issuer, value);
  }

  function burn(address from, uint256 value) public onlyRegistrar {
    _burn(from, value);
    emit Burned(from, value);
  }

  function burnFromBulk(address[] memory from, uint256[] memory values) external onlyRegistrar {
    require(from.length == values.length, "number of addresses must be equal to bulk size");
              
    for (uint i = 0; i<from.length; i++) {
      _burn(from[i], values[i]);
    }
  }

  // end of life: burn all issuer tokens
  function kill() external onlyRegistrar{
    require(balanceOf(issuer) == totalSupply, "all tokens must be owned by the issuer");

    _burn(issuer, totalSupply);
    selfdestruct(issuer);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

abstract contract Token {
  string public name;
  string public symbol;
  uint256 public totalSupply;
  uint8 public decimals = 0;

  mapping (address => uint256) private balances;
  mapping (address => mapping(address => uint256)) private allowances;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  function balanceOf(address holder) public view returns (uint256) {
    return balances[holder];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return allowances[owner][spender];
  }

  function _transfer(address from, address to, uint256 value, bool withAllowance) internal {
    require(from != address(0), "sender cannot be zero address");
    require(to != address(0), "recipient cannot be zero address");
    require(value <= balances[from], "balance to low");

    if(from != msg.sender && withAllowance) {
      require(allowances[from][msg.sender] >= value, "allowance to low");
      
      unchecked{
        _approve(from, msg.sender, allowances[from][msg.sender] - value);
      }
    }

    unchecked{
      balances[from] -= value;
      balances[to] += value;
    }
    emit Transfer(from, to, value);
  }

  function _approve (address owner, address spender, uint256 value) internal {
    require(owner != address(0), "owner cannot be zero address");
    require(spender != address(0), "spender cannot be zero address");
    
    allowances[owner][spender] = value;
    emit Approval(owner, spender, value);
  }

  function _mint(address to, uint256 value) internal {
    require(to != address(0), "recipient cannot be zero address");

    totalSupply += value;
    unchecked {
      balances[to] += value;
    }
    emit Transfer(address(0), to, value);
  }

  function _burn(address from, uint256 value) internal {
    require(from != address(0), "cannot burn from zero address");
    require(balances[from] >= value, "burn amount exceeds account balance");
    
    unchecked {
      balances[from] -= value;
      totalSupply -= value;
    }
    emit Transfer(from, address(0), value);
  }

}