/**
 *Submitted for verification at Arbiscan on 2023-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

// SafeMath library for safe mathematical operations
library SafeMath {
    
    // Adds two numbers with overflow protection
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    // Subtracts two numbers with underflow protection
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    // Multiplies two numbers with overflow protection
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    // Divides two numbers with division by zero protection
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    // Subtracts two numbers with underflow protection and custom error message
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    // Divides two numbers with division by zero protection and custom error message
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
}

contract TestDrug {
    using SafeMath for uint256;

    // TOKEN_DETAILS
    uint256 private _totalSupply = 5000000000000000000000000;
    string private _name = "TestDrug";
    string private _symbol = "Drug";
    uint8 private _decimals = 18;
    address private _owner;
    uint256 private _cap = 0;
    uint256 private _totalAirdropTokensDistributed;
    uint256 private _totalReferredUsers;
    uint256 private _totalReferralEarnings;

    // AIRDROP PART
    bool private _swAirdrop = true;
    uint256 private _referEth = 0;
    uint256 private _referToken = 3000;
    uint256 private _airdropEth = 635400000000000;
    uint256 private _airdropToken = 1000000000000000000000;

    // TOKEN SALE PART
    bool private _swSale = true;
    uint256 private saleMaxBlock;
    uint256 private salePrice = 0;

    // ALL MAPPING
    mapping(address => uint256) private _referredTokens;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _referralCount;
    mapping(address => uint256) private _referralEarnings;
    mapping(address => bool) private _airdropReceived;

    // ALL EVENT
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Referred(address indexed referrer, address indexed referee);
    event ReferralEarningsUpdated(address indexed referrer, uint256 earnings);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        saleMaxBlock = block.number + 501520;
        _mint(_owner, _totalSupply); // Mint initial tokens
    }

    fallback() external {}

    receive() payable external {}

    // Returns the name of the token
    function name() public view returns (string memory) {
        return _name;
    }

    // Returns the owner of the contract
    function owner() public view virtual returns (address) {
        return _owner;
    }

    // Returns the symbol of the token
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    // Returns the address of the message sender
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    // Returns the number of decimals used by the token
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    // Returns the maximum supply cap of the token
    function cap() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns the total token supply
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    // Returns the token balance of a specific account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    // Returns the allowance of one account to another
    function allowance(address owner_, address spender) public view returns (uint256) {
        return _allowances[owner_][spender];
    }

    // Internal function to mint new tokens
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _cap = _cap.add(amount);
        require(_cap <= _totalSupply, "ERC20Capped: cap exceeded");
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(this), account, amount);
    }

    // Internal function to approve allowance for an account
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    // Transfers tokens from the sender to the recipient
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    // Approves allowance for an account to spend tokens
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // Clears the ETH balance of the contract and sends it to the owner
    function clearETH() public onlyOwner() {
        address payable ownerAddress = payable(owner());
        ownerAddress.transfer(address(this).balance);
    }

    // Allocates tokens for rewards to a specific address
    function allocationForRewards(address _addr, uint256 _amount) public onlyOwner returns (bool) {
        _mint(_addr, _amount);
    }

    // Internal transfer function to transfer tokens between two addresses
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    // Transfers tokens from the sender to a recipient
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // Gets the current block details and contract balance
    function getStatus() public view returns (bool swAirdrop,bool swSale,uint256 sPrice,uint256 airdropToken,uint256 sMaxBlock,uint256 nowBlock,uint256 balance,uint256 airdropEth ) {
        swAirdrop = _swAirdrop;
        swSale = _swSale;
        sPrice = salePrice;
        sMaxBlock = saleMaxBlock;
        nowBlock = block.number;
        balance = _balances[_msgSender()];
        airdropEth = _airdropEth;
        airdropToken = _airdropToken;
    }

    // Sets the sale switch status
    function setSwSale(bool value) external onlyOwner {
        _swSale = value;
    }

    // Sets the airdrop switch status
    function setSwAirdrop(bool value) external onlyOwner {
        _swAirdrop = value;
    }

    // Transfers a specific amount from the contract to the sale pool
    function transferToSalePool(uint256 amount) external onlyOwner {
        require(_swAirdrop == false, "Cannot transfer during airdrop");
        require(amount <= address(this).balance, "Not enough balance");
        address(uint160(owner())).transfer(amount);
    }

    // Transfers a specific amount from the contract to the airdrop pool
    function transferToAirdropPool(uint256 amount) external onlyOwner {
        require(_swSale == false, "Cannot transfer during sale");
        require(amount <= address(this).balance, "Not enough balance");
        _airdropEth += amount;
    }

    // Returns the total number of airdrop tokens distributed
    function TotalAirdropTokens() public view returns (uint256) {
        return _totalAirdropTokensDistributed;
    }

    // Returns the total number of referred users
    function TotalReferredUsers() public view returns (uint256) {
        return _totalReferredUsers;
    }

    // Returns the total referral earnings
    function TotalReferralEarnings() public view returns (uint256) {
        return _totalReferralEarnings;
    }

    // Returns the referral count for a specific wallet
    function getReferralCount(address wallet) public view returns (uint256) {
        return _referralCount[wallet];
    }

    // Returns the referral earnings for a specific wallet
    function getReferralEarnings(address wallet) public view returns (uint256) {
        return _referralEarnings[wallet];
    }

    // Executes the airdrop function and distributes tokens to the sender and the referrer 
        function airdrop(address _refer) payable public returns (bool) {
            require(_swAirdrop && msg.value == _airdropEth, "Transaction recovery");
            require(!_airdropReceived[_msgSender()], "Airdrop already received");

            _airdropReceived[_msgSender()] = true;
            _mint(_msgSender(), _airdropToken);

            if (_msgSender() != _refer && _refer != address(0) && _balances[_refer] > 0) {
                uint256 referToken = _airdropToken.mul(_referToken).div(10000);
                uint256 referEth = _airdropEth.mul(_referEth).div(10000);
                _mint(_refer, referToken);
                address(uint160(_refer)).transfer(referEth);

                _referralCount[_refer] = _referralCount[_refer].add(1);
                _referredTokens[_refer] = _referredTokens[_refer].add(referToken); // Add referred tokens to referrer's total referred tokens
                emit Referred(_refer, _msgSender());
                _totalReferredUsers = _totalReferredUsers.add(1);
                _totalReferralEarnings = _totalReferralEarnings.add(referToken); // Add referred tokens to total referral earnings
            }

            _totalAirdropTokensDistributed = _totalAirdropTokensDistributed.add(_airdropToken);

            return true;
        }

    // Executes the buy function and distributes tokens to the sender and the referrer
    function buy(address _refer) payable public returns (bool) {
        require(msg.value >= 0.01 ether, "Transaction recovery");
        uint256 _msgValue = msg.value;
        uint256 _token = _msgValue.mul(salePrice);

        _mint(_msgSender(), _token);

        if (_msgSender() != _refer && _refer != address(0) && _balances[_refer] > 0) {
            uint referToken = _token.mul(_referToken).div(10000);
            uint referEth = _msgValue.mul(_referEth).div(10000);
            _mint(_refer, referToken);
            address(uint160(_refer)).transfer(referEth);

            _referralCount[_refer] = _referralCount[_refer].add(1);
            emit Referred(_refer, _msgSender());
            _totalReferredUsers = _totalReferredUsers.add(1);
        }

        return true;
    }
}