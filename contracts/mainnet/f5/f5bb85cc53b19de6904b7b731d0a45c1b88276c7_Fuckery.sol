/**
 *Submitted for verification at Arbiscan on 2023-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Fuckery {
    string public constant name = "Fuckery";
    string public constant symbol = "FUK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 888_888_888_888_8888 * 10**decimals;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address public owner = 0x8Ed3E3A7580596a39EA6F161E4594F6926a673d0;
    address public liquidityPool;
    address public taxAddress = 0x6a2D4a23124292c065b450289cC15C868049B76A; // Set the tax address here
    uint256 public buyTaxPercentage = 3; // 3% tax for buy transactions
    uint256 public sellTaxPercentage = 3; // 3% tax for sell transactions

    IUniswapV2Router02 private sushiSwapRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[msg.sender], "Insufficient balance");

        uint256 taxAmount = (amount * buyTaxPercentage) / 100;
        uint256 afterTaxAmount = amount - taxAmount;

        balances[msg.sender] -= amount;
        balances[taxAddress] += taxAmount; // Transfer the buy tax to the tax address
        balances[recipient] += afterTaxAmount;

        emit Transfer(msg.sender, recipient, afterTaxAmount);
        emit Transfer(msg.sender, taxAddress, taxAmount); // Emit a separate transfer event for the buy tax amount

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Invalid spender address");

        allowances[msg.sender][spender] = amount;
        
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(sender != address(0), "Invalid sender address");
        require(recipient != address(0), "Invalid recipient address");
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        uint256 taxAmount;
        if (msg.sender == liquidityPool) {
            taxAmount = (amount * buyTaxPercentage) / 100; // Apply buy tax for liquidity pool transfers
        } else {
            taxAmount = (amount * sellTaxPercentage) / 100; // Apply sell tax for other transfers
        }
        uint256 afterTaxAmount = amount - taxAmount;

        balances[sender] -= amount;
        balances[taxAddress] += taxAmount; // Transfer the tax to the tax address
        balances[recipient] += afterTaxAmount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, afterTaxAmount);
        emit Transfer(sender, taxAddress, taxAmount); // Emit a separate transfer event for the tax amount

        return true;
    }

    function allowance(address ownerAddress, address spender) public view returns (uint256) {
        return allowances[ownerAddress][spender];
    }

    function setLiquidityPool(address _liquidityPool) public onlyOwner {
        require(_liquidityPool != address(0), "Invalid liquidity pool address");
        liquidityPool = _liquidityPool;
    }

    function setBuyTaxPercentage(uint256 _buyTaxPercentage) public onlyOwner {
        require(_buyTaxPercentage <= 10, "Buy tax percentage must be less than or equal to 10%"); // Limit tax to 10%
        buyTaxPercentage = _buyTaxPercentage;
    }

    function setSellTaxPercentage(uint256 _sellTaxPercentage) public onlyOwner {
        require(_sellTaxPercentage <= 10, "Sell tax percentage must be less than or equal to 10%"); // Limit tax to 10%
        sellTaxPercentage = _sellTaxPercentage;
    }

    function setTaxAddress(address _taxAddress) public onlyOwner {
        require(_taxAddress != address(0), "Invalid tax address");
        taxAddress = _taxAddress;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}