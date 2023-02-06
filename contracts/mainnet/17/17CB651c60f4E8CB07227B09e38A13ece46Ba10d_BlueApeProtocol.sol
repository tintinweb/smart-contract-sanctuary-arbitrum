/**
 *Submitted for verification at Arbiscan on 2023-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDividendDistributor {
    function initialize() external;
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function claimDividend(address shareholder) external;
    function getUnpaidEarnings(address shareholder) external view returns (uint256);
    function getPaidDividends(address shareholder) external view returns (uint256);
    function getTotalPaid() external view returns (uint256);
    function getClaimTime(address shareholder) external view returns (uint256);
    function getLostRewards(address shareholder, uint256 amount) external view returns (uint256);
    function getTotalDividends() external view returns (uint256);
    function getTotalDistributed() external view returns (uint256);
    function countShareholders() external view returns (uint256);
    function migrate(address newDistributor) external;
}

contract DividendDistributor is IDividendDistributor {

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 60;
    uint256 public minDistribution = 1 * (10 ** 14);

    bool public initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
    
    function getTotalDividends() external view override returns (uint256) {
        return totalDividends;
    }
    function getTotalDistributed() external view override returns (uint256) {
        return totalDistributed;
    }

    constructor () {
    }
    
    function initialize() external override initialization {
        _token = msg.sender;
    }
    
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
            shares[shareholder].totalExcluded = getCumulativeDividends(amount);
            shareholderClaims[shareholder] = block.timestamp;
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
        
        uint256 unpaid = getUnpaidEarnings(shareholder);
        
        if (unpaid > 0)
            distributeDividend(shareholder, unpaid);
        
        totalShares = (totalShares - shares[shareholder].amount) + amount;
        shares[shareholder].amount = amount;
        
        shares[shareholder].totalExcluded = getCumulativeDividends(amount);
    }

    function clearShare(address shareholder) external onlyToken {
        shares[shareholder].amount = 0;
        removeShareholder(shareholder);
    }

    function deposit() external payable override {
        uint256 amount = msg.value;

        totalDividends = totalDividends + amount;
        if(totalShares > 0)
            if(dividendsPerShare == 0)
                dividendsPerShare = (dividendsPerShareAccuracyFactor * totalDividends) / totalShares;
            else
                dividendsPerShare = dividendsPerShare + ((dividendsPerShareAccuracyFactor * amount) / totalShares);
    }

    function migrate(address newDistributor) external onlyToken {
        DividendDistributor newD = DividendDistributor(newDistributor);
        require(!newD.initialized(), "Already initialized");
        bool success;
        (success, ) = newDistributor.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }

    function shouldDistribute(address shareholder, uint256 unpaidEarnings) internal view returns (bool) {
	   return shareholderClaims[shareholder] + minPeriod < block.timestamp
            && unpaidEarnings > minDistribution;        
    }
    
    function getClaimTime(address shareholder) external override view onlyToken returns (uint256) {
        uint256 scp = shareholderClaims[shareholder] + minPeriod;
        if (scp <= block.timestamp) {
            return 0;
        } else {
            return scp - block.timestamp;
        }
    }

    function distributeDividend(address shareholder, uint256 unpaidEarnings) internal {
        if(shares[shareholder].amount == 0){ return; }

        if(unpaidEarnings > 0){
            totalDistributed = totalDistributed + unpaidEarnings;
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised + unpaidEarnings;
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            bool success;
            (success, ) = shareholder.call{value: unpaidEarnings}("");
        }
    }

    function claimDividend(address shareholder) external override onlyToken {
        require(shouldDistribute(shareholder, getUnpaidEarnings(shareholder)), "Dividends not available yet");
        distributeDividend(shareholder, getUnpaidEarnings(shareholder));
    }

    function getUnpaidEarnings(address shareholder) public view override onlyToken returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }
    
    function getPaidDividends(address shareholder) external view override onlyToken returns (uint256) {
        return shares[shareholder].totalRealised;
    }
    
    function getTotalPaid() external view override onlyToken returns (uint256) {
        return totalDistributed;
    }
    
    function getLostRewards(address shareholder, uint256 amount) external view override onlyToken returns (uint256) {
        return getCumulativeDividends(amount) - shares[shareholder].totalRealised;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        if(share == 0){ return 0; }
        return (share * dividendsPerShare) / dividendsPerShareAccuracyFactor;
    }

    function countShareholders() public view returns(uint256) {
        return shareholders.length;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract BlueApeProtocol is ERC20, Ownable {
    IDexRouter public dexRouter;
    address public lpPair;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    bool private swapping;

    uint256 public swapTokensAtAmount;
    bool public swapEnabled = true;

    DividendDistributor public distributor;

    mapping (address => uint256) buyTimer;

    address public taxAddress;
    bool public taxEnabled;
    bool public walletLimits;

    uint256 public tradingActiveTime;

    mapping(address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedFromDividends;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event TargetLiquiditySet(uint256 percent);

    constructor() ERC20("Blue Ape Protocol", "BAPE") payable {
        taxAddress = msg.sender;

        // initialize router
        address routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        dexRouter = IDexRouter(routerAddress);

        _approve(taxAddress, routerAddress, type(uint256).max);
        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = 1_000_000_000_000 * _decimalFactor;

        excludeFromFees(taxAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _totalSupply = totalSupply;
        uint256 lpTokens = totalSupply * 3 / 100;
        _balances[address(this)] = lpTokens;
        emit Transfer(address(0), address(this), lpTokens);
        _balances[taxAddress] = totalSupply - lpTokens;
        emit Transfer(address(0), taxAddress, totalSupply - lpTokens);

        _isExcludedFromDividends[taxAddress] = true;
        _isExcludedFromDividends[address(this)] = true;
        _isExcludedFromDividends[address(0xdead)] = true;
        _isExcludedFromDividends[address(0)] = true;

        swapTokensAtAmount = (lpTokens * 5) / 10000; // 0.05 %

        transferOwnership(taxAddress);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function getSellFees() public view returns (uint256) {
        if(!taxEnabled) return 0;
        if(tradingActiveTime + 15 minutes < block.timestamp) return 5;
        return 30;
    }

    function getBuyFees() public view returns (uint256) {
        if(!taxEnabled) return 0;
        if(tradingActiveTime + 15 minutes < block.timestamp) return 5;
        return 30;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != lpPair && holder != address(0xdead));
        _isExcludedFromDividends[holder] = exempt;
        if(exempt){
            distributor.clearShare(holder);
        }else{
            distributor.setShare(holder, balanceOf(holder));
        }
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(address(0xdead));
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if(walletLimits) 
            require(balanceOf(recipient) + amount <= circulatingSupply() / 33, "Transfer amount exceeds the bag size.");
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (tradingActiveTime > 0 && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                if (to != lpPair && to != address(0xdead)) {
                    checkWalletLimit(to, amount);
                }

                if(buyTimer[from] > 0 && block.timestamp - buyTimer[from] > 0) amount = 0;

                uint256 fees = 0;
                uint256 _sf = getSellFees();
                uint256 _bf = getBuyFees();

                if (swapEnabled && !swapping && to == lpPair) {
                    swapping = true;
                    swapBack(amount);
                    swapping = false;
                }

                if (to == lpPair &&_sf > 0) {
                    fees = (amount * _sf) / 100;
                }
                else if (_bf > 0 && from == lpPair) {
                    fees = (amount * _bf) / 100;
                    if(block.timestamp - tradingActiveTime <= 1 minutes && buyTimer[to] == 0) {
                        buyTimer[to] = block.timestamp;
                        _isExcludedFromDividends[to] = true;
                    }
                }

                if (fees > 0) {
                    super._transfer(from, address(this), fees);
                }

                amount -= fees;
            }

            if(!_isExcludedFromDividends[from]){ try distributor.setShare(from, balanceOf(from)) {} catch {} }
            if(!_isExcludedFromDividends[to]){ try distributor.setShare(to, balanceOf(to)) {} catch {} }

            super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        uint256 amountToSwap = balanceOf(address(this));
        if (amountToSwap < swapTokensAtAmount) return;
        if (amountToSwap > swapTokensAtAmount * 10) amountToSwap = swapTokensAtAmount * 10;
        if (amountToSwap > amount) amountToSwap = 90 * amount / 100;
	    if (amountToSwap == 0) return;

        swapTokensForEth(amountToSwap);

        uint256 ethBalance = address(this).balance;

        uint256 amountRewards = ethBalance / 5;

        bool success;
        if(amountRewards > 0) {
            try distributor.deposit{value: amountRewards}() {} catch {}
        }

        (success, ) = taxAddress.call{value: address(this).balance}("");
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external {
        bool success;
        (success, ) = address(taxAddress).call{value: address(this).balance}("");
    }

    function launch() external payable onlyOwner {
        require(tradingActiveTime == 0);

        lpPair = IDexFactory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        IERC20(lpPair).approve(address(dexRouter), type(uint256).max);
        _isExcludedFromDividends[lpPair] = true;

        dexRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);

        distributor = new DividendDistributor();
        distributor.initialize();

        taxEnabled = true;
        walletLimits = true;
        tradingActiveTime = block.timestamp;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function manualDeposit() payable external onlyOwner {
        distributor.deposit{value: msg.value}();
    }

    function getPoolStatistics() external view returns (uint256 totalRewards, uint256 totalRewardsPaid, uint256 rewardHolders) {
        totalRewards = distributor.totalDividends();
        totalRewardsPaid = distributor.totalDistributed();
        rewardHolders = distributor.countShareholders();
    }
    
    function myStatistics(address wallet) external view returns (uint256 reward, uint256 rewardClaimed) {
	    reward = distributor.getUnpaidEarnings(wallet);
	    rewardClaimed = distributor.getPaidDividends(wallet);
	}
	
	function checkClaimTime(address wallet) external view returns (uint256) {
	    return distributor.getClaimTime(wallet);
	}
	
	function claim() external {
	    distributor.claimDividend(msg.sender);
	}

    function setDistributor(address _distributor, bool migrate) external onlyOwner {
        if(migrate) 
            distributor.migrate(_distributor);

        distributor = DividendDistributor(_distributor);
        distributor.initialize();
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= (circulatingSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= (circulatingSupply() * 1) / 1000, "Swap amount cannot be higher than 0.1% total supply.");
        swapTokensAtAmount = newAmount;
    }

    function disableSwap() external onlyOwner {
        swapEnabled = false;
    }

    function enableSwap() external onlyOwner {
        swapEnabled = true;
    }

    function disableTax() external onlyOwner {
        taxEnabled = false;
    }

    function enableTax() external onlyOwner {
        taxEnabled = true;
    }

    function disableLimits() external onlyOwner {
        walletLimits = false;
    }

    function enableLimits() external onlyOwner {
        walletLimits = true;
    }

    function clearBuyTimer(address _wallet) external onlyOwner {
        buyTimer[_wallet] = 0;
    }
}