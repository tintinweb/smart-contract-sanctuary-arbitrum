/**
 *Submitted for verification at Arbiscan on 2023-05-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function balanceOfUnderlying(address account) external view returns (uint256);
  function currentFlagment() external view returns (uint256);
  function rebasegenesis() external view returns (bool);
  function toFlagment(uint256 value) external view returns (uint256);
  function toUnderlying(uint256 value) external view returns (uint256);
  function requestSupply(address to, uint256 amount) external returns (bool);
}

contract permission {
    mapping(address => mapping(string => bytes32)) private permit;

    function newpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode(adr,str))); }

    function clearpermit(address adr,string memory str) internal { permit[adr][str] = bytes32(keccak256(abi.encode("null"))); }

    function checkpermit(address adr,string memory str) public view returns (bool) {
        if(permit[adr][str]==bytes32(keccak256(abi.encode(adr,str)))){ return true; }else{ return false; }
    }
}

contract SoulsKeeper is permission {

    event Deposit(address indexed from,address indexed to,uint256 amount,uint256 blockstamp,uint256 currentFlagment);
    event Withdraw(address indexed to,uint256 amount,uint256 blockstamp,uint256 currentFlagment,uint256 mintingAmount);

    address _owner;
    address public tokenAddress;
    bool public poolActived;

    uint256 public totalSupply;
    uint256 public distributed;
    uint256 public deleyedcooldown;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public unlockedBlock;

    uint256 public depositFee = 0;
    uint256 public denominator = 100;

    IERC20 token;
    
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        token = IERC20(tokenAddress);
        _owner = msg.sender;
        newpermit(_owner,"owner");
    }

    function deposit(uint256 amount) public returns (bool) {
        require(token.rebasegenesis(),"Token Was Not Start Rebase");
        require(poolActived,"Pool Was Not Actived");
        address to = msg.sender;
        token.transferFrom(msg.sender,address(this),amount);
        uint256 feeAmount = amount * depositFee / denominator;
        uint256 depositAmount = amount - feeAmount;
        balances[to] += depositAmount;
        unlockedBlock[to] = block.timestamp + deleyedcooldown;
        totalSupply += depositAmount;
        emit Deposit(msg.sender,to,amount,block.timestamp,token.currentFlagment());
        return true;
    }

    function withdraw(uint256 amount) public returns (bool) {
        require(amount<=balances[msg.sender],"Insignificant Balance To Withdraw");
        require(unlockedBlock[msg.sender]<block.timestamp,"Withdraw Is In Coutdown");
        balances[msg.sender] -= amount;
        uint256 mintingAmount;
        uint256 requestingAmount = token.toUnderlying(amount);
        uint256 holdingAmount = token.balanceOfUnderlying(address(this));
        if(requestingAmount>holdingAmount){
            mintingAmount = requestingAmount - holdingAmount;
            token.requestSupply(address(this),mintingAmount);
        }
        token.transfer(msg.sender,amount);
        distributed += amount;
        emit Withdraw(msg.sender,amount,block.timestamp,token.currentFlagment(),mintingAmount);
        return true;
    }

    function poolActiveToggle() public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        poolActived = !poolActived;
        return true;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function updateCooldownWithPermit(address _account,uint256 _blockstamp) public returns (bool) {
        require(checkpermit(msg.sender,"operator"));
        unlockedBlock[_account] = _blockstamp;
        return true;
    }

    function setFeeAmount(uint256 _depositFee,uint256 _denominator) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        depositFee = _depositFee;
        denominator = _denominator;
        return true;
    }

    function settingDeleyedcooldown(uint256 _cooldown) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        deleyedcooldown = _cooldown;
        return true;
    }

    function grantRole(address adr,string memory role) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        newpermit(adr,role);
        return true;
    }

    function revokeRole(address adr,string memory role) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        clearpermit(adr,role);
        return true;
    }

    function transferOwnership(address adr) public returns (bool) {
        require(checkpermit(msg.sender,"owner"));
        newpermit(adr,"owner");
        clearpermit(msg.sender,"owner");
        _owner = adr;
        return true;
    }

}