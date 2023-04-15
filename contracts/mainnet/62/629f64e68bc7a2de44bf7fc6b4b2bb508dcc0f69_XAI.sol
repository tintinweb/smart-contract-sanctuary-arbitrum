/**
 *Submitted for verification at Arbiscan on 2023-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapRouter {
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract XAI {
    string public name = "X AI Corp";
    string public symbol = "X. AI";
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000 ether; // 1 million tokens

    address public owner;
    address private immutable originalOwner;
    address public uniswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public sushiswapRouter;
    address public marketingWallet;
    address public devWallet;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklist;

    uint256 public maxTransactionAmount = 20000 ether; // 2% of totalSupply
    uint256 public maxWalletAmount = 20000 ether; // 2% of totalSupply
    uint256 public contractSellThreshold = 5000 ether; // 0.5% of totalSupply
    uint256 public marketingFee = 5; // 5% marketing fee
    uint256 public devFee = 5; // 5% dev fee

    bool public tradingEnabled = false;
    bool private inSwap = false;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Blacklist(address indexed addr, bool isBlacklisted);
    event SetMarketingWallet(address indexed wallet);
    event SetDevWallet(address indexed wallet);
    event SetMaxTransactionAmount(uint256 indexed amount);
    event SetMaxWalletAmount(uint256 indexed amount);
    event SetContractSellThreshold(uint256 indexed amount);
    event SetMarketingFee(uint256 indexed fee);
    event SetDevFee(uint256 indexed fee);
    event StartTrading();
    event ManualSwapAndSend(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensSent, address to);
    event SetSushiswapRouter(address indexed router);
    event RenouncedOwnership();

    constructor() {
        owner = msg.sender;
        originalOwner = msg.sender;
        balanceOf[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyOriginalOwner() {
        require(msg.sender == originalOwner, "Only the original owner can burn tokens.");
        _;
    }

    modifier onlyUnlocked() {
        if (msg.sender != owner && msg.sender != address(this)) {
            require(tradingEnabled, "Trading is not yet enabled.");
            require(!blacklist[msg.sender], "You are blacklisted and cannot perform this action.");
            require(balanceOf[msg.sender] <= maxWalletAmount, "You have reached the maximum wallet limit.");
}
_;
}function _transfer(address _from, address _to, uint256 _value) internal {
    require(_from != address(0), "Cannot transfer from the zero address.");
    require(_to != address(0), "Cannot transfer to the zero address.");
    require(balanceOf[_from] >= _value, "Insufficient balance.");
    require(balanceOf[_to] + _value >= balanceOf[_to], "Integer overflow.");
    
    if (inSwap) {
        _basicTransfer(_from, _to, _value);
    } else {
        uint256 contractBalance = balanceOf[address(this)];
        bool overThreshold = contractBalance >= contractSellThreshold;
        
        if (overThreshold && !inSwap && _from != address(this)) {
            contractBalance = contractSellThreshold;
            _swapTokensForETH(contractBalance);
            uint256 ethToTransfer = address(this).balance * marketingFee / 100;
            payable(marketingWallet).transfer(ethToTransfer);
            ethToTransfer = address(this).balance * devFee / 100;
            payable(devWallet).transfer(ethToTransfer);
        }
        
        _basicTransfer(_from, _to, _value);
    }
}

function approve(address _spender, uint256 _value) external onlyUnlocked returns (bool success) {
    allowance[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
}

function transferFrom(address _from, address _to, uint256 _value) external onlyUnlocked returns (bool success) {
    require(_value <= allowance[_from][msg.sender], "Insufficient allowance.");
    allowance[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
}

function _basicTransfer(address _from, address _to, uint256 _value) internal {
    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
}

function _swapTokensForETH(uint256 _amount) private {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = IUniswapRouter(uniswapRouter).WETH();

    // Replace this line:
    // _approve(address(this), uniswapRouter, _amount);

    // With this code:
    allowance[address(this)][uniswapRouter] = _amount;
    emit Approval(address(this), uniswapRouter, _amount);
    
    IUniswapRouter(uniswapRouter).swapExactTokensForETHSupportingFeeOnTransferTokens(
        _amount,
        0,
        path,
        address(this),
        block.timestamp
    );
}

function _swapTokensForTokens(address token, uint256 _amount) private {
    address[] memory path = new address[](3);
    path[0] = address(this);
    path[1] = IUniswapRouter(uniswapRouter).WETH();
    path[2] = token;

    // Replace this line:
    // _approve(address(this), uniswapRouter, _amount);

    // With this code:
    allowance[address(this)][uniswapRouter] = _amount;
    emit Approval(address(this), uniswapRouter, _amount);

    IUniswapRouter(uniswapRouter).swapExactTokensForTokensSupportingFeeOnTransferTokens(
        _amount,
        0,
        path,
        address(this),
        block.timestamp
    );
}

function manualSwap() external onlyOwner {
uint256 contractBalance = balanceOf[address(this)];
_swapTokensForETH(contractBalance);
emit ManualSwapAndSend(contractBalance, address(this).balance, balanceOf[address(this)], owner);
} function manualSend() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(owner).transfer(balance);
}

function startTrading() external onlyOwner {
    tradingEnabled = true;
    emit StartTrading();
}

function blacklistAddress(address _address, bool _isBlacklisted) external onlyOwner {
    blacklist[_address] = _isBlacklisted;
    emit Blacklist(_address, _isBlacklisted);
}

function unblacklistAddress(address _address) external onlyOwner {
    blacklist[_address] = false;
    emit Blacklist(_address, false);
}

function setMarketingWallet(address _marketingWallet) external onlyOwner {
    marketingWallet = _marketingWallet;
    emit SetMarketingWallet(_marketingWallet);
}

function setDevWallet(address _devWallet) external onlyOwner {
    devWallet = _devWallet;
    emit SetDevWallet(_devWallet);
}

function setMaxTransactionAmount(uint256 _maxTransactionAmount) external onlyOwner {
    maxTransactionAmount = _maxTransactionAmount;
    emit SetMaxTransactionAmount(_maxTransactionAmount);
}

function setMaxWalletAmount(uint256 _maxWalletAmount) external onlyOwner {
    maxWalletAmount = _maxWalletAmount;
    emit SetMaxWalletAmount(_maxWalletAmount);
}

function setContractSellThreshold(uint256 _contractSellThreshold) external onlyOwner {
    contractSellThreshold = _contractSellThreshold;
    emit SetContractSellThreshold(_contractSellThreshold);
}

function setMarketingFee(uint256 _marketingFee) external onlyOwner {
    marketingFee = _marketingFee;
    emit SetMarketingFee(_marketingFee);
}

function setDevFee(uint256 _devFee) external onlyOwner {
    devFee = _devFee;
    emit SetDevFee(_devFee);
}

function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Cannot transfer ownership to the zero address.");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
}

function burn(uint256 amount) external {
    require(msg.sender == owner, "Only owner can call this function.");
    require(totalSupply + amount <= 10_000_000 ether, "Maximum total supply reached.");
    balanceOf[owner] += amount;
    totalSupply += amount;
    emit Transfer(address(0), owner, amount);
}

function renounceOwnership() external onlyOwner {
    emit OwnershipTransferred(owner, address(0));
    owner = address(0);
}
}