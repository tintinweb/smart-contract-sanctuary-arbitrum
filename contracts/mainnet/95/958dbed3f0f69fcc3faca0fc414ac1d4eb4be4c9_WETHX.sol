/**
 *Submitted for verification at Arbiscan.io on 2024-05-22
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

/*
0x958dbed3f0f69fcc3faca0fc414ac1d4eb4be4c9
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
    string public symbol = "WETH.x";
    uint8 public decimals = 18;
    address public multiNetPool;
    address public DAO; //The team has committed to set up the variable as a smart contract address with voting capabilities by June 1, 2024, thus making the certificate absolutely decentralized. If you view this source code after June 1, 2024, please monitor the contract to which the value of the DAO variable corresponds.
    address public ticket;
    uint256 public cooldownPeriod = 7 days;
    bool public isNativeETH = true;
    bool public claimed;
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
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
        updateLastTransfer(msg.sender);
        if (multiNetPool != address(0)) {
            bool success = IMultiNetPool(multiNetPool).transferEther(address(this), wad);
            require(success, "MultiNetPool transfer failed");
        }

        (bool sent, ) = payable(msg.sender).call{value: wad}("");
        require(sent, "Failed to send Ether");
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
            _inCall = false;
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

    function claimOwnership() public returns (bool)  {
        require(!claimed,"Ownship has been claimed by somebody.");
        DAO = msg.sender;
        claimed = true;
        return true;
    }

    function updateLastTransfer(address src) private {
        lastTransferTime[src] = block.timestamp;
        balanceAfterLastTransfer[src] = balanceOf[src];
    }

    // Typically, we use tickets to grant and count the number of cross-chain castings allowed by a third-party facility.
    function setTicketToken(address _ticket) public onlyDAO returns (bool) {
        ticket = _ticket;
        return true;
    }
    
    // For cross-chain mint or upgrade old edition token. 
    function ticketToThis(address src,address dst,uint256 amount) public {
        require(ticket != address(0), "Ticket token address cannot be zero");
        if(multiNetPool!=address(0)){
            require(IERC20(ticket).transferFrom(src, multiNetPool, amount), "Transfer of ticket failed");
        }else{
            require(IERC20(ticket).transferFrom(src, address(this), amount), "Transfer of ticket failed");
        }
        balanceOf[dst] += amount;
        _totalSupply += amount;
        emit Transfer(address(0),dst,amount);
    }

    // Used for cross-chain burns while recovering the licensed mint limit for third-party configurations such as bridges.
    function thisToTicket(address src,address dst,uint256 amount) public {
        require(ticket != address(0), "Ticket token address cannot be zero");
        require(balanceOf[src] >= amount, "Insufficient balance");
        balanceOf[src] -= amount;
        if(multiNetPool!=address(0)){
            require(IERC20(ticket).transferFrom(multiNetPool,dst,amount), "Transfer of ticket failed");
        }else{
            require(IERC20(address(this)).transfer(dst, amount), "Transfer of ticket failed");
        }
        _totalSupply -= amount;
        emit Transfer(src,address(0),amount);
    }

    function setCooldownPeriod(uint256 _cooldownPeriod) public onlyDAO returns (bool)  {
        require(_cooldownPeriod <= 7 days, "Cooldown period cannot exceed 7 days");
        cooldownPeriod = _cooldownPeriod;
        return true;
    }

    function setNativeToken(bool _isNativeETH) public onlyDAO returns (bool)  {
        isNativeETH = _isNativeETH;
        return true;
    }

    function getCooldownPeriodInDays() public view returns (uint256) {
        return cooldownPeriod / 1 days;
    }

    function getSelfCooldownDays() public view returns (uint256) {
        return ((block.timestamp - lastTransferTime[msg.sender])/ 1 days);
    }

    function getUserCooldownDays(address addr) public view returns (uint256) {
        return ((block.timestamp - lastTransferTime[addr])/ 1 days);
    }

}