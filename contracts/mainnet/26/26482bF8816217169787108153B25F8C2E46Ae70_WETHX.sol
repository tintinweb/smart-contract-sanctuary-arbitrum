/**
 *Submitted for verification at Arbiscan.io on 2024-05-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
// https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=paris&version=soljson-v0.8.22+commit.4fc1097e.js
pragma solidity ^0.8.0;

// Interface for interacting with the MultiNetPool contract.
interface IMultiNetPool {
    function transferEther(address to, uint256 amount) external returns (bool);
}

// ERC-20 Token Standard Interface.
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// Wrapped Ether Contract.
contract WETHX {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;
    address public multiNetPool;
    address public DAO;//The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.
    address public ticket;
    uint256 public cooldownPeriod = 7 days;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    mapping(address => uint) public balanceOf;
    mapping(address => uint) public balanceAfterLastTransfer;
    mapping(address => uint) public lastTransferTime;
    mapping(address => mapping(address => uint)) public allowance;

    uint256 private _totalSupply;
    bool private _inCall;
    bool public nativeTokenIsEther;

    modifier onlyDAO() {
        require(msg.sender == DAO, "Caller is not the DAO");
        _;
    }

    modifier nonReentrant() {
        require(!_inCall, "Reentrant call");
        _inCall = true;
        _;
        _inCall = false;
    }

    // 为逻辑合约添加初始化函数以代替构造函数
    function initialize(address _multiNetPool, address initialDAO,bool _nativeTokenIsEther) public {
        multiNetPool = _multiNetPool;
        nativeTokenIsEther = _nativeTokenIsEther;
        DAO = initialDAO;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable nonReentrant {
        require(nativeTokenIsEther,"Native token must be Ether");
        if (multiNetPool != address(0)) {
            (bool success, ) = multiNetPool.call{value: msg.value}("");
            require(success, "Transfer to MultiNetPool failed");
        }
        balanceOf[msg.sender] += msg.value;
        _totalSupply += msg.value;
        balanceAfterLastTransfer[msg.sender] += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function withdraw(uint wad) public nonReentrant {
        require(balanceOf[msg.sender] >= wad, "Insufficient balance");
        require(block.timestamp - lastTransferTime[msg.sender] >= cooldownPeriod, "Cooldown period has not elapsed");
        require(wad <= balanceAfterLastTransfer[msg.sender], "Withdraw amount exceeds balance after last transfer");

        balanceOf[msg.sender] -= wad;
        _totalSupply -= wad;

        if (multiNetPool != address(0)) {
            bool success = IMultiNetPool(multiNetPool).transferEther(address(this), wad);
            require(success, "MultiNetPool transfer failed");
        }

        (bool sent, ) = payable(msg.sender).call{value: wad}("");
        require(sent, "Failed to send Ether");
        updateLastTransfer(msg.sender);
        emit Transfer(msg.sender, address(0), wad);
    }

    function setMultiNetPool(address _multiNetPool) public onlyDAO returns (bool) {
        multiNetPool = _multiNetPool;
        return true;
    }
    
    function setDAO(address _DAO) public onlyDAO returns (bool) {
        DAO = _DAO;//The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.
        return true;
    }
    
    function updateLastTransfer(address src) private {
        lastTransferTime[src] = block.timestamp;
        balanceAfterLastTransfer[src] = balanceOf[src];
    }
}