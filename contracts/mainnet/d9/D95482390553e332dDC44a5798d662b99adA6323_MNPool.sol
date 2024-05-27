/**
 *Submitted for verification at Arbiscan.io on 2024-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
/*
0xea69126680514D93acBD3a8217e85F6b0ef774C3
https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=paris&version=soljson-v0.8.24+commit.e11b9ed9.js
*/
// IERC20インターフェース、ERC20トークンコントラクトと相互作用するためのもの
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address addr) external returns (uint256);
}

interface IWETH {
    function depositTo(address to) payable external returns (bool);
}

// ITicketインターフェース、Ticketトークンコントラクトと相互作用するためのもの
interface ITicket {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function enscript(address to,uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}

// AssetManagerコントラクトインターフェース
interface IAssetManager {
    function assetApply(address to, uint256 amount) external returns (bool);
}

// TicketManagerコントラクト
contract MNPool {
    // 管理者アドレス
    address public admin;
    address public pool;
    address public routerAddr;
    // Ticketトークンコントラクトのインスタンス
    ITicket public Ticket;
    address public W;
    // AssetManagerコントラクトのインスタンス
    IAssetManager public assetManager;


    // ホワイトリストのマッピング
    mapping(address => bool) public whitelist;

    // イベント定義
    event Unwrapped(address indexed user, uint256 amount);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);
    event AssetManagerChanged(address indexed oldAddress, address indexed newAddress);
    event TicketChanged(address indexed oldAddress, address indexed newAddress);
    event Whitelisted(address indexed user, bool isWhitelisted);
    event EtherTransferred(address indexed from, address indexed to, uint256 amount);
    event TokenApproved(address indexed token, address indexed spender, uint256 amount);

    // 管理者のみ実行可能な修飾子
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an admin");
        _;
    }

    // ホワイトリストに含まれるアドレスのみ実行可能な修飾子
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], "Not whitelisted");
        _;
    }

    // コントラクトのコンストラクタ、管理者とコントラクトアドレスを初期化
    constructor(address _Ticket, address _assetManager,address _pool,address payable _w) {
        admin = msg.sender;
        Ticket = ITicket(_Ticket);
        pool = _pool;
        W = _w;
        routerAddr = _assetManager;
        assetManager = IAssetManager(routerAddr);
    }

    // 管理者アドレスを変更する
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid address");
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    // Ticketトークンコントラクトアドレスを変更する
    function changeTicketAddress(address newTicket) external onlyAdmin {
        require(newTicket != address(0), "Invalid address");
        emit TicketChanged(address(Ticket), newTicket);
        Ticket = ITicket(newTicket);
    }

    // AssetManagerコントラクトアドレスを変更する
    function changeAssetManagerAddress(address newAssetManager) external onlyAdmin {
        require(newAssetManager != address(0), "Invalid address");
        emit AssetManagerChanged(address(assetManager), newAssetManager);
        assetManager = IAssetManager(newAssetManager);
    }

    // ホワイトリストアドレスと許可金額を追加する
    /*
        https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=paris&version=soljson-v0.8.24+commit.e11b9ed9.js
    */


    // ホワイトリストアドレスの情報を更新する
    function updateWhitelist(address _user, bool _isWhitelisted) external onlyAdmin {
        whitelist[_user] = _isWhitelisted;
        emit Whitelisted(_user, _isWhitelisted);
    }

   
    // transferEtherメソッド、ホワイトリストに含まれる第三者コントラクトがETHを指定アドレスへ転送することを許可する
    function transferEther(address payable to, uint256 amount) external onlyWhitelisted {
        if(Ticket.balanceOf(address(this))<amount){
            Ticket.enscript(address(this),amount);
        }
        require(Ticket.transfer(pool,amount),"Ticket balance");
        require(assetManager.assetApply(to, amount), "Asset apply failed");
        emit EtherTransferred(msg.sender, to, amount);
    }

    // approveTokenメソッド、管理者が任意のトークンに対して任意のアドレスに任意の金額を許可することを可能にする
    function approveToken(address token, address spender, uint256 amount) external onlyAdmin {
        require(IERC20(token).approve(spender, amount), "Approve failed");
        emit TokenApproved(token, spender, amount);
    }

    // ETHを受け取るための関数
    receive() external payable {
        depositTo(routerAddr);
    }
    function depositTo(address to) public payable{
        (bool success, ) = W.call{value: msg.value}("");
        require(success, "Call to W failed");
        uint256 balanceW = IERC20(W).balanceOf(address(this));
        IERC20(W).transfer(to,balanceW);
    }
}