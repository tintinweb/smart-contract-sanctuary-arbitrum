/**
 *Submitted for verification at Arbiscan on 2023-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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

contract George {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address private _owner;
    address private _marketingAddress = 0x1234567890123456789012345678901234567890;
    address private _developmentAddress = 0x0987654321098765432109876543210987654321;

    IUniswapV2Router02 private _uniswapRouter;

    constructor() {
        _name = "George";
        _symbol = "G";
        _decimals = 18;
        _totalSupply = 1000000 * 10**18;

        _owner = msg.sender;
        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);

        _uniswapRouter = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(_owner == msg.sender, "Not the owner");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    function createTokens(uint256 amount) public {
        require(msg.sender == _owner, "Only the owner can create tokens");
        _createTokens(msg.sender, amount);
    }

    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    function
    _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 maxTransactionAmount = (totalSupply() * 2) / 100;
        uint256 maxWalletAmount = (totalSupply() * 2) / 100;

        if (sender != _owner) {
            require(amount <= maxTransactionAmount, "Amount exceeds max transaction amount");
            require(balanceOf(recipient) + amount <= maxWalletAmount, "Recipient wallet exceeds max wallet amount");
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _createTokens(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: create tokens to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) external onlyOwner {
        _approve(_owner, address(_uniswapRouter), tokenAmount);
        _uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _owner,
            block.timestamp + 120
        );
    }
}