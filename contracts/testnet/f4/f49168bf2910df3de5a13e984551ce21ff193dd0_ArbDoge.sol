// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import './IERC20.sol';
import './Ownable.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Router02.sol';
import './IUniswapV2Pair.sol';

contract ArbDoge is IERC20, Ownable {
    string public name;
    string public symbol;
    uint public decimals;

    uint public maxTotalSupply;
    uint public maxAirdrop;
    uint public maxRewards;

    uint public totalSupply;
    uint public tokenForAirdrop;
    uint public tokenForRewards;

    IUniswapV2Router02 public router;
    IUniswapV2Pair public pair;

    address public marketingAddress;
    uint public staking;
    uint public burn;
    uint public balanceLimit;
    uint public txValueLimit;

    bool public isEnableStaking;

    mapping (address => uint) public balanceOf;
    mapping (address => mapping(address => uint)) public allowance;

    mapping (address => bool) public isUnStakingTxOf;
    mapping (address => bool) public isUnlimitedBalanceOf;
    mapping (address => bool) public isUnlimitedValueTxOf;

    mapping (address => uint) private airdropWhitelist;

    mapping (address => bool) private supporter;

    modifier onlySupporter() {
        require(
            supporter[msg.sender] || msg.sender == owner,
            "ERC20: your are not supporter"
        );
        _;
    }

    constructor(
        uint _maxTotalSupply_,
        uint _maxAirdrop_,
        uint _maxRewards_,
        address _router_,
        address _basePair_
    ){
        require(
            (_maxAirdrop_ + _maxRewards_) < _maxTotalSupply_,
            "ERC20: _maxAirdrop_ + _maxRewards_ >= _maxTotalSupply_"
        );
        name = "ArbDoge";
        symbol = "ArbDoge";
        decimals = 9;

        staking = 2;
        burn = 2;
        maxAirdrop = _maxAirdrop_;
        maxRewards = _maxRewards_;
        tokenForAirdrop = _maxAirdrop_;
        tokenForRewards = _maxRewards_;
        maxTotalSupply = _maxTotalSupply_;

        uint _totalSupply = _maxTotalSupply_ - (_maxAirdrop_ + _maxRewards_);

        balanceLimit = _maxTotalSupply_ * 20 / 1000;
        txValueLimit = _maxTotalSupply_ * 20 / 1000;

        IUniswapV2Router02 _router = IUniswapV2Router02(_router_);
        pair = IUniswapV2Pair(
            IUniswapV2Factory(_router.factory()).createPair(
                address(this),
                _basePair_
            )
        );
        router = _router;

        isEnableStaking = true;

        isUnStakingTxOf[msg.sender] = true;
        isUnStakingTxOf[address(this)] = true;

        isUnlimitedBalanceOf[msg.sender] = true;
        isUnlimitedBalanceOf[address(this)] = true;
        isUnlimitedBalanceOf[address(router)] = true;
        isUnlimitedBalanceOf[address(pair)] = true;

        isUnlimitedValueTxOf[msg.sender] = true;
        isUnlimitedValueTxOf[address(this)] = true;

        marketingAddress = msg.sender;
        supporter[msg.sender] = true;

        _mint(msg.sender, _totalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint value
    ) private {
        require(value <= balanceOf[from], "ERC20: transfer amount exceeds balance");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(value > 0, "ERC20: Transfer amount must be greater than zero");

        if(!isUnlimitedValueTxOf[to] && !isUnlimitedValueTxOf[from]){
            require(
                value <= txValueLimit,
                "ERC20: Transfer amount must be less than txValueLimit"
            );
        }

        bool takeStaking = true;

        if (isUnStakingTxOf[from] || isUnStakingTxOf[to]) {
            takeStaking = false;
        }

        if (!isUnlimitedBalanceOf[to]) {
            require(
                balanceOf[to] + value <= balanceLimit,
                "ERC20: Recipient already owns maximum amount of tokens."
            );
        }

        _tokenTransfer(from, to, value, takeStaking);
    }

    function _approve(
        address owner,
        address spender,
        uint value
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = value;

        emit Approval(owner, spender, value);
    }

    function _mint(
        address to,
        uint amount
    ) private {
        require(to != address(0), "ERC20: mint to the zero address");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeStaking
    ) private {
        uint _staking = staking;
        uint _burn = burn;
        if(!takeStaking || !isEnableStaking) {
            _staking = 0;
            _burn = 0;
        }

        uint amountMarketing = amount * 10 * _staking / 1000;
        uint amountBurn = amount * 10 * _burn / 1000;
        uint transferAmount = amount - (amountMarketing + amountBurn);

        balanceOf[sender] -= amount;
        balanceOf[recipient] += transferAmount;

        _toMarketing(amountMarketing);
        _toBurn(amountBurn);

        emit Transfer(sender, recipient, transferAmount);
    }

    function _toMarketing(uint value) private {
        balanceOf[address(this)] += value;
    }

    function _toBurn( uint value) private {
        balanceOf[address(0)] += value;
    }

    function _swapTokensForEth(uint tokenAmount) private {
        require(marketingAddress != address(0), "Invalid marketing address");

        _approve(address(this), address(router), tokenAmount);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint deadline = block.timestamp + 1800;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            marketingAddress,
            deadline
        );
    }

    function transfer(
        address recipient,
        uint amount
    ) external override returns (bool) {
        _transfer(msg.sender,recipient, amount);

        return(true);
    }

    function approve(
        address spender,
        uint amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);

        return(true);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external override returns (bool) {
        uint256 currentAllowance = allowance[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);

        return(true);
    }

    function multiTransfer(
        address[] memory users,
        uint[] memory amounts
    ) public  {
        require(users.length == amounts.length, "Wrong parameters");
        for(uint i = 0; i < users.length; i++){
            _transfer(msg.sender,users[i], amounts[i]);
        }
    }

    function setStaking(uint _staking)
    public onlyOwner  {
        require(_staking > 0 && _staking < 100, "ERC20: _staking out of range");

        staking = _staking;
    }

    function setBurn(uint _burn)
    public onlyOwner  {
        require(_burn > 0 && _burn < 100, "ERC20: _fee out of range");

        burn = _burn;
    }

    function setBalanceLimitPercent(uint _percent)
    public onlyOwner  {
        require(_percent > 0 && _percent < 100, "ERC20: _percent out of range");
        balanceLimit = maxTotalSupply * 10 * _percent / 1000;
    }

    function setTxValueLimitPercent(uint _percent)
    public onlyOwner  {
        require(_percent > 0 && _percent < 100, "ERC20: _percent out of range");
        txValueLimit = maxTotalSupply * 10 * _percent / 1000;
    }

    function excludeFromStaking(
        address account,
        bool _exclude
    ) public onlyOwner  {
        require(
            isUnStakingTxOf[account] != _exclude,
            "ERC20: isFreeTxOf[account] != _exclude"
        );
        isUnStakingTxOf[account] = _exclude;
    }

    function excludeFromMaxAmount(
        address account,
        bool _exclude
    ) public onlyOwner  {
        require(
            isUnlimitedBalanceOf[account] != _exclude,
            "ERC20: isUnlimitedBalanceOf[account] != _exclude"
        );
        isUnlimitedBalanceOf[account] = _exclude;
    }

    function excludeFromMaxTxAmount(
        address account, bool _exclude
    ) public onlyOwner  {
        require(
            isUnlimitedValueTxOf[account] != _exclude,
            "ERC20: isUnlimitedValueTxOf[account] == _exclude"
        );
        isUnlimitedValueTxOf[account] = _exclude;
    }

    function setMarketingAddress(address _addr)
    public onlySupporter  {
        require(marketingAddress != _addr, "ERC20: Wallet address already set");

        if(!isUnStakingTxOf[_addr]) {
            excludeFromStaking(_addr, true);
        }

        if(!isUnlimitedBalanceOf[_addr]) {
            excludeFromMaxAmount(_addr, true);
        }
                        
        if(!isUnlimitedValueTxOf[_addr]) {
            excludeFromMaxTxAmount(_addr, true);
        }

        supporter[marketingAddress] = false;
        marketingAddress = _addr;
        supporter[_addr] = true;
    }

    function addAirdropWhitelist(
        address[] memory to, uint256[] memory amount
    ) public onlySupporter  {
        require(to.length == amount.length, "Invalid arguments");

        for (uint256 index = 0; index < to.length; index++) {
            airdropWhitelist[address(to[index])] += amount[index];
        }
    }

    function getAirdropWhitelist(address[] memory to)
    public view returns(uint[] memory) {
        uint length = to.length;
        uint[] memory amount = new uint[](length);
        for (uint256 index = 0; index < to.length; index++) {
            amount[index] = airdropWhitelist[address(to[index])];
        }
        return(amount);
    }

    function setTokensForAirdrop(uint256 _tokensForAirdrop)
    public onlySupporter {
        require(_tokensForAirdrop <= maxAirdrop, "_tokensForAirdrop > maxAirdrop");
        tokenForAirdrop = _tokensForAirdrop;
    }

    function claimAirdrop () public {
        require(
            airdropWhitelist[msg.sender] > 0 &&
            airdropWhitelist[msg.sender] <= tokenForAirdrop,
            "It's not possible to claim an airdrop at this address."
        );
        require(tokenForAirdrop > 0, "The amount of tokens available for the airdrop has been exhausted.");
        
        _mint(msg.sender, airdropWhitelist[msg.sender]);
        tokenForAirdrop -= airdropWhitelist[msg.sender];
        maxAirdrop -= airdropWhitelist[msg.sender];
        airdropWhitelist[msg.sender] = 0;
    }

    function setTokensForRewards(uint256 _tokensForRewards)
    public onlySupporter {
        require(_tokensForRewards < maxRewards);
        tokenForRewards = _tokensForRewards;
    }

    function rewards(
        address recipient,
        uint256 amount
    ) public onlySupporter {
        require(recipient != address(0), "0x is not accepted here");
        require(tokenForRewards > 0, "Rewards not available");
        require(amount > 0, "not accept 0 value");
        require(amount <= tokenForRewards, "amount > tokenForRewards");

        _mint(recipient, amount);
        tokenForRewards -= amount;
        maxRewards -= amount;
    }

    function sweepTokenForMarketing(uint256 amount)
    public onlySupporter  {
        uint marketingBalance = balanceOf[address(this)];
        require(marketingBalance >= amount, "ERC20: marketingBalance <= amount");
        _swapTokensForEth(amount);
    }

    function enableStaking(bool _staking)
    public onlyOwner  {
        require(isEnableStaking != _staking, "ERC20: isEnableStaking == _staking");
        isEnableStaking = _staking;
    }
}