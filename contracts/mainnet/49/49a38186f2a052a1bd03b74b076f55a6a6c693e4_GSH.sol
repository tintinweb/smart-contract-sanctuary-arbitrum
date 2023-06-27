/**
 *Submitted for verification at Arbiscan on 2023-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event EtherReceived(address indexed from, uint256 value); // 添加了一个自定义事件 EtherReceived，用于通知以太币的接收
}

contract GSH is IERC20 {
    string public constant name = "GSH";
    string public constant symbol = "GSH";
    uint8 public constant decimals = 18;
    uint256 private constant _totalSupply = 10000000000 * (10 ** uint256(decimals)); // 1000亿代币，总供应量
    uint256 private _remainingSupply = _totalSupply; // 剩余供应量
    mapping(address => uint256) private _balances; // 地址对应的余额
    mapping(address => mapping(address => uint256)) private _allowances; // 地址对应的授权额度
    mapping(address => bool) private _blacklist; // 地址是否在黑名单中
    mapping(address => bool) private _whitelist; // 地址是否在白名单中
    mapping(address => bool) private _participated; // 地址是否已参与过铸币
    address public creator; // 合约创建者的地址
    bool public mintingEnabled; // 是否启用铸币功能
    uint256 public mintStartTime; // 铸币开始时间
    uint256 public mintEndTime; // 铸币结束时间
    uint256 public constant mintTokenAmount = 500000 * (10 ** uint256(decimals)); // 铸币数量为 50万代币
    uint256 public constant mintEthAmount = 0.001 ether; // 铸币需要的以太币数量为 0.001 ETH

    constructor() {
        creator = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply); // 初始化时，将总供应量转移给合约创建者
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only the creator can call this function."); // 限制只有合约创建者可以调用的修饰符
        _;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(recipient != address(0), "ERC20: transfer to the zero address"); // 确保不向零地址转账
        require(!_blacklist[msg.sender], "You are in the blacklist and cannot transfer."); // 确保发送者不在黑名单中
        require(amount <= _balances[msg.sender], "ERC20: transfer amount exceeds balance"); // 确保发送者余额足够
        require(!_blacklist[recipient], "Recipient is in the blacklist and cannot receive."); // 确保接收者不在黑名单中
        require(_whitelist[msg.sender] || _whitelist[recipient], "Transfer not allowed."); // 确保发送者或接收者在白名单中

        uint256 taxAmount = amount * 2 / 100; // 计算2%的税收金额
        uint256 transferAmount = amount - taxAmount; // 实际转账金额

        _balances[msg.sender] -= amount; // 扣除发送者的代币
        _balances[recipient] += transferAmount; // 增加接收者的代币
        _balances[address(this)] += taxAmount; // 将税收金额转到合约地址

        emit Transfer(msg.sender, recipient, transferAmount); // 触发转账事件
        emit Transfer(msg.sender, address(this), taxAmount); // 触发税收事件

        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(!_blacklist[sender], "Sender is in the blacklist and cannot transfer.");
        require(amount <= _balances[sender], "ERC20: transfer amount exceeds balance");
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance");
        require(!_blacklist[recipient], "Recipient is in the blacklist and cannot receive.");
        require(_whitelist[sender] || _whitelist[recipient], "Transfer not allowed.");

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function addBlacklist(address account) public onlyCreator {
        _blacklist[account] = true; // 将地址添加到黑名单中
    }

    function removeBlacklist(address account) public onlyCreator {
        _blacklist[account] = false; // 将地址从黑名单中移除
    }

    function addWhitelist(address account) public onlyCreator {
        _whitelist[account] = true; // 将地址添加到白名单中
    }

    function removeWhitelist(address account) public onlyCreator {
        _whitelist[account] = false; // 将地址从白名单中移除
    }

    function enableMint(uint256 duration) public onlyCreator {
        require(!mintingEnabled, "Minting is already enabled.");
        mintingEnabled = true; // 启用铸币功能
        mintStartTime = block.timestamp; // 设置铸币开始时间
        mintEndTime = block.timestamp + duration; // 设置铸币结束时间
    }

    function disableMint() public onlyCreator {
        require(mintingEnabled, "Minting is not enabled.");
        mintingEnabled = false; // 禁用铸币功能
    }

    function mint() public payable {
        require(mintingEnabled, "Minting is not enabled.");
        require(msg.value == mintEthAmount, "Please send exactly 0.001 ETH to mint.");
        require(!_participated[msg.sender], "You have already participated in minting.");
        require(!_blacklist[msg.sender], "You are in the blacklist and cannot mint.");
        require(_remainingSupply >= mintTokenAmount, "Minting amount exceeds remaining supply");
        require(address(this).balance >= mintEthAmount, "Contract balance is insufficient for minting");

        _participated[msg.sender] = true; // 标记地址已参与铸币

        _balances[address(this)] -= mintTokenAmount; // 扣除合约地址的代币
        _balances[msg.sender] += mintTokenAmount; // 增加发送者的代币
        _remainingSupply -= mintTokenAmount; // 更新剩余供应量

        emit Transfer(address(this), msg.sender, mintTokenAmount); // 触发转账事件
    }

    function extractBalance() public onlyCreator {
        require(address(this).balance > 0, "Contract balance is zero.");
        payable(creator).transfer(address(this).balance); // 将合约余额提取到创建者地址
    }

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value); // 触发自定义事件 EtherReceived
    }
}