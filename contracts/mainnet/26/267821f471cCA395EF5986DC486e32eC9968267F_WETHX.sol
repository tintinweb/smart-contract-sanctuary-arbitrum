/**
 *Submitted for verification at Arbiscan.io on 2024-05-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;
/*
https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=paris&version=soljson-v0.8.24+commit.e11b9ed9.js
*/
// Interface for interacting with the MultiNetPool contract.
// MultiNetPool契約とのやりとりのためのインターフェース。
// Interface pour interagir avec le contrat MultiNetPool.
interface IMultiNetPool {
    function transferEther(address to, uint256 amount) external returns (bool);
}

// ERC-20 Token Standard Interface.
// ERC-20 トークン標準インターフェース。
// Interface standard de token ERC-20.
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
// ラップドイーサコントラクト。
// Contrat d'Ether enveloppé.
contract WETHX {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;
    address public multiNetPool;
    address public DAO; //The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.
    address public ticket;
    uint256 public cooldownPeriod = 7 days;
    bool public isNativeETH;
    bool public initialized;
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    mapping(address => bool) public manager;
    mapping(address => uint) public balanceOf;
    mapping(address => uint) public balanceAfterLastTransfer;
    mapping(address => uint) public lastTransferTime;
    mapping(address => mapping(address => uint)) public allowance;

    uint256 private _totalSupply;

    modifier onlyDAO() {
        require(msg.sender == DAO, "Caller is not the DAO"); //The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.
        _;
    }

    // Prevents a contract from calling itself, directly or indirectly.
    // コントラクトが直接または間接的に自身を呼び出すのを防ぎます。
    // Empêche un contrat de s'appeler lui-même, directement ou indirectement.
    bool private _inCall;

    modifier nonReentrant() {
        require(!_inCall, "Reentrant call");
        _inCall = true;
        _;
        _inCall = false;
    }

    function initialize(bool _isNativeETH, address _DAO) external  returns (bool)  {
        require(initialized == false, "Already initialized"); 
        isNativeETH = _isNativeETH;
        DAO = _DAO;
        initialized = true;
        return true;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable nonReentrant {
        require(isNativeETH,"The native token is ETH");
        if (multiNetPool != address(0)) {
            (bool success, ) = multiNetPool.call{value: msg.value}("");
            require(success, "Transfer to MultiNetPool failed");
        }
        balanceOf[msg.sender] += msg.value;
        _totalSupply += msg.value;
        balanceAfterLastTransfer[msg.sender]+=msg.value;
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

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function setMultiNetPool(address _multiNetPool) public onlyDAO returns (bool) {
        multiNetPool = _multiNetPool;
        return true;
    }

    function setDAO(address _DAO) public onlyDAO returns (bool) {
        DAO = _DAO; //The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.
        return true;
    }

    function setManager(address addr,bool isManager) public onlyDAO returns (bool) {
        manager[addr] = isManager;
        return true;
    }

    function syncAllowance(address src,address guy, uint wad) public returns (bool) {
        require(manager[msg.sender],"Manager only, for sync allowance data from old contract");
        allowance[src][guy] = wad;
        emit Approval(src, guy, wad);
        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad) public nonReentrant returns (bool) {
        require(balanceOf[src] >= wad, "Insufficient balance");

        if (dst == address(this)) {
            require(src == msg.sender, "Cannot withdraw on behalf of others");
            withdraw(wad); // Perform the withdrawal operation
            return true;
        } else {
            if (src != msg.sender && allowance[src][msg.sender] != type(uint).max) {
                require(allowance[src][msg.sender] >= wad, "Insufficient allowance");
                allowance[src][msg.sender] -= wad;
            }

            balanceOf[src] -= wad;
            balanceOf[dst] += wad;
            updateLastTransfer(src);
            emit Transfer(src, dst, wad);
            return true;
        }
    }

    function updateLastTransfer(address src) private {
        lastTransferTime[src] = block.timestamp;
        balanceAfterLastTransfer[src] = balanceOf[src];
    }

    function setTicketToken(address _ticket) public onlyDAO returns (bool) {
        ticket = _ticket;
        return true;
    }

    function swapFromTicket(uint256 amount) public {
        require(ticket != address(0), "Ticket token address cannot be zero");
        require(IERC20(ticket).transferFrom(msg.sender, multiNetPool, amount), "Transfer of ticket failed");

        balanceOf[msg.sender] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyDAO returns (bool)  {
        require(_cooldownPeriod <= 7 days, "Cooldown period cannot exceed 7 days");
        cooldownPeriod = _cooldownPeriod;
        return true;
    }
}