/**
 *Submitted for verification at Arbiscan on 2023-04-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SteinInu {
    string public constant name = "Stein Inu";
    string public constant symbol = "STINU";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public owner;
    address public marketingWallet;
    address public devWallet;
    address public uniswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    uint256 public maxTxnAmount;
    uint256 public maxWalletAmount;
    uint256 public contractSellSwapThreshold;

    uint256 public marketingFee;
    uint256 public developmentFee;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public nonces;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => bool) public isBlacklisted;

    bool public tradingEnabled;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    constructor(address _marketingWallet, address _devWallet, uint256 _contractSellSwapThreshold) {
        owner = msg.sender;
        uint256 initialSupply = 1000000 * 10**decimals;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;

        maxTxnAmount = totalSupply * 2 / 100;
        maxWalletAmount = totalSupply * 2 / 100;
        contractSellSwapThreshold = _contractSellSwapThreshold;

        marketingWallet = _marketingWallet;
        devWallet = _devWallet;
    }

    function startTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function renounceOwnership() external onlyOwner {
        require(balanceOf[owner] == 0, "Cannot renounce ownership if balance is greater than 0");
        owner = address(0);
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_value <= allowance[_from][msg.sender], "Value exceeds allowance");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0), "Cannot transfer to the zero address");
        require(!isBlacklisted[_from] && !isBlacklisted[_to], "Addresses are blacklisted");

        if (!tradingEnabled && _from != owner) {
            revert("Trading is not enabled");
        }

        if (msg.sender != owner) {
            require(_value <= maxTxnAmount, "Value exceeds max transaction amount");
            require(balanceOf[_to] + _value <= maxWalletAmount, "Recipient wallet limit exceeded");
        }

        if (_from == address(this) && _to == uniswapRouter) {
            require(balanceOf[address(this)] >= contractSellSwapThreshold, "Cannot sell/swap below threshold");
uint256 sellAmount = balanceOf[address(this)] - contractSellSwapThreshold;
uint256 totalFee = sellAmount * (marketingFee + developmentFee) / 100;
uint256 marketingShare = totalFee * marketingFee / (marketingFee + developmentFee);
uint256 developmentShare = totalFee - marketingShare;
balanceOf[address(this)] -= sellAmount;
balanceOf[marketingWallet] += marketingShare;
balanceOf[devWallet] += developmentShare;
emit Transfer(address(this), marketingWallet, marketingShare);
emit Transfer(address(this), devWallet, developmentShare);
}    balanceOf[_from] -= _value;
    balanceOf[_to] += _value;
    emit Transfer(_from, _to, _value);
}

function manualBurn(uint256 _value) external onlyOwner {
    require(balanceOf[owner] >= _value, "Not enough tokens in owner's balance");
    balanceOf[owner] -= _value;
    totalSupply -= _value;
    emit Transfer(owner, address(0), _value);
}

function blacklistAddress(address _address) external onlyOwner {
    isBlacklisted[_address] = true;
}

function unblacklistAddress(address _address) external onlyOwner {
    isBlacklisted[_address] = false;
}

function manualSwap() external onlyOwner {
    // Implement your manual swap logic here
}

function manualSend() external onlyOwner {
    // Implement your manual send logic here
}

function setFee(uint256 _marketingFee, uint256 _developmentFee) external onlyOwner {
    require(_marketingFee + _developmentFee <= 100, "Total fee cannot exceed 100%");
    marketingFee = _marketingFee;
    developmentFee = _developmentFee;
}

function setFeeReceiver(address _marketingWallet, address _devWallet) external onlyOwner {
    require(_marketingWallet != address(0) && _devWallet != address(0), "Marketing and dev wallets cannot be zero address");
    marketingWallet = _marketingWallet;
    devWallet = _devWallet;
}

function setMaxTxn(uint256 _maxTxnAmount) external onlyOwner {
    require(_maxTxnAmount > contractSellSwapThreshold, "Max txn amount should be greater than contract sell/swap threshold");
    maxTxnAmount = _maxTxnAmount;
}

function setMaxWallet(uint256 _maxWalletAmount) external onlyOwner {
    require(_maxWalletAmount > contractSellSwapThreshold, "Max wallet amount should be greater than contract sell/swap threshold");
    maxWalletAmount = _maxWalletAmount;
}

function setContractSellSwapThreshold(uint256 _threshold) external onlyOwner {
    require(_threshold <= totalSupply, "Threshold should be less than or equal to total supply");
    require(_threshold <= maxTxnAmount && _threshold <= maxWalletAmount, "Threshold should be less than or equal to max txn and wallet amount");
    contractSellSwapThreshold = _threshold;
}
}