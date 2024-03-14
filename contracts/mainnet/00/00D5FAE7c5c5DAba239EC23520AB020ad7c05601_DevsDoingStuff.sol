/**
 *Submitted for verification at Arbiscan.io on 2024-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
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

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IDistributor {
   function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external;
   function setShare(address shareholder, uint256 amount) external;
   function deposit(uint256 amount) external;
   function process(uint256 gas) external;
}

contract Distributor is IDistributor {
    address owner;
	
    struct Share {
	  uint256 amount;
	  uint256 totalExcluded;
	  uint256 totalRealised;
    }
	
    address reflectionToken = address(0x13A7DeDb7169a17bE92B0E3C7C2315B46f4772B3);

    address[] shareholders;
    mapping (address => uint256) public shareholderIndexes;
    mapping (address => uint256) public shareholderClaims;
    mapping (address => Share) public shares;
	
	event DistributionCriteriaUpdate(uint256 minPeriod, uint256 minDistribution);
	event NewFundDeposit(uint256 amount);

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public constant dividendsPerShareAccuracyFactor = 10 ** 36;
	
    uint256 public minPeriod = 3600;
    uint256 public minDistribution = 1 * (10 ** 18);
	
    uint256 currentIndex;
	
    modifier onlyOwner() {
        require(msg.sender == owner, "!Token"); _;
    }
	
    constructor () {
        owner = msg.sender;
    }
	
	receive() external payable {}
	
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyOwner {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
		emit DistributionCriteriaUpdate(minPeriod, minDistribution);
    }
	
    function setShare(address shareholder, uint256 amount) external override onlyOwner {
        if(shares[shareholder].amount > 0)
		{
            distributeDividend(shareholder);
        }
		if(amount > 0 && shares[shareholder].amount == 0)
		{
           addShareholder(shareholder);
        }
		else if(amount == 0 && shares[shareholder].amount > 0)
		{
           removeShareholder(shareholder);
        }
        totalShares = totalShares - shares[shareholder].amount + amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit(uint256 amount) external override onlyOwner {
        totalDividends = totalDividends + amount;
        dividendsPerShare = dividendsPerShare + dividendsPerShareAccuracyFactor * amount / totalShares;
		emit NewFundDeposit(amount);
    }
	
    function process(uint256 gas) external override onlyOwner {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount)
			{
                currentIndex = 0;
            }
            if(shouldDistribute(shareholders[currentIndex]))
			{
                distributeDividend(shareholders[currentIndex]);
            }
            gasUsed = gasUsed + gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return (shareholderClaims[shareholder] + minPeriod) < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }
	
    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
		
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0) 
		{
            IERC20(reflectionToken).transfer(shareholder, amount);
			totalDistributed = totalDistributed + amount;
			shareholderClaims[shareholder] = block.timestamp;
			shares[shareholder].totalRealised = shares[shareholder].totalRealised + amount;
			shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
	
    function claimReflection() external {
		if(shouldDistribute(msg.sender)) 
		{
		   distributeDividend(msg.sender);
		}
    }
	
    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShare / dividendsPerShareAccuracyFactor;
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

interface IJoeFactory {
   function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IJoeRouter {
   function factory() external pure returns (address);
   function WAVAX() external pure returns (address);
   function addLiquidityAVAX(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
   function swapExactTokensForAVAXSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
   function swapExactAVAXForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
   function swapExactAVAXForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external payable;
   function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, address referrer, uint256 deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, address referrer, uint256 deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, address referrer, uint256 deadline) external;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin,address to,uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function WETH() external pure returns (address);
    function factory() external pure returns (address);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

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
	
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
	
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }
	
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
	
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }
	
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
	
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
	
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }
	
    function _transfer(address from, address to, uint256 amount ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
	
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
	
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
	
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
	
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}          

contract DevsDoingStuff is ERC20, Ownable {
	uint256 public maxTx;
	uint256 public maxWallet;

	uint256[] public reflectionFee;
	
	uint256 public swapTokensAtAmount;
	uint256 public distributorGas;
	
	uint256 private reflectionFeeTotal;
	
	IUniswapV2Router02 public camelotRouter;
    address public camelotPair;
    address public reflectionToken;
	address public distributorAddress;
	Distributor distributor;
	
	bool private swapping;
	bool public distributionEnabled;
    bool public reflectionsEnabled;
	
	mapping (address => bool) isDividendExempt;
	mapping (address => bool) public isExcludedFromFee;
	mapping (address => bool) public isAutomatedMarketMakerPairs;
	
	event AccountExcludeFromFee(address account, bool status);
	event SwapTokensAmountUpdated(uint256 amount);
	event AutomatedMarketMakerPairUpdated(address pair, bool value);
	
	constructor() Ownable(msg.sender) ERC20("DevsDoingStuff", "DEVS") 
	{
        reflectionToken = address(0x13A7DeDb7169a17bE92B0E3C7C2315B46f4772B3);
	   
	    reflectionFee.push(500);
	    reflectionFee.push(500);
	    reflectionFee.push(500);
	   
	    isExcludedFromFee[address(msg.sender)] = true;
        isExcludedFromFee[address(this)] = true;
	   
        isDividendExempt[address(this)] = true;
	   
	    swapTokensAtAmount = 1000_000 * (10 ** 18);
	    distributorGas = 300000;

		maxTx = 1_000_000_000 * (10 ** 18);
		maxWallet = 1_000_000_000 * (10 ** 18);
	   
	    distributionEnabled = true;
        reflectionsEnabled = true;
	    _mint(address(msg.sender), 100_000_000_000 * (10 ** 18));
    }
	
    function createPairs() public onlyOwner {
	    distributor = new Distributor();
	    distributorAddress = address(distributor);

	    camelotRouter = IUniswapV2Router02(0xc873fEcbd354f5A56E00E710B90EF4201db2448d); 
        camelotPair = IUniswapV2Factory(camelotRouter.factory()).createPair(address(this), camelotRouter.WETH());

	    isDividendExempt[address(camelotPair)] = true;
	    isAutomatedMarketMakerPairs[address(camelotPair)] = true;   
    }

	receive() external payable {}
	
	function excludeFromFee(address account, bool status) external onlyOwner {
	   require(isExcludedFromFee[account] != status, "Account is already the value of 'status'");
	   
	   isExcludedFromFee[account] = status;
	   emit AccountExcludeFromFee(account, status);
	}
	
	function setSwapTokensAtAmount(uint256 amount) external onlyOwner {
  	    require(amount <= totalSupply(), "Amount cannot be over the total supply.");
		require(amount >= 1 * (10 ** 18), "Minimum `500` token per swap required");
		
		swapTokensAtAmount = amount;
		emit SwapTokensAmountUpdated(amount);
  	}
	
	function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != address(0), "Zero address");
		
		isAutomatedMarketMakerPairs[address(pair)] = value;
		emit AutomatedMarketMakerPairUpdated(pair, value);
    }
	
	function _transfer(address sender, address recipient, uint256 amount) internal override(ERC20){      
		if(!isDividendExempt[recipient]) {
			require(amount <= maxTx, "Amount over max transaction allowed");
			require(balanceOf(recipient) + amount <= maxWallet, "Max wallet reached");
		}
	
		uint256 contractTokenBalance = balanceOf(address(this));
		bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if (canSwap == true && !swapping && isAutomatedMarketMakerPairs[recipient] == true && reflectionsEnabled == true) 
		{
			uint256 tokenToReflection = reflectionFeeTotal;
			uint256 tokenToSwap = tokenToReflection;

			if(tokenToSwap >= swapTokensAtAmount) 
			{
			    swapping = true;
				swapTokensForAvax(swapTokensAtAmount);
				uint256 AvaxBalance = address(this).balance;
                
				uint256 reflectionPart = AvaxBalance;
				
				if(reflectionPart > 0)
				{
                    swapAvaxForReflection(reflectionPart);
					uint256 reflectionBalance = IERC20(reflectionToken).balanceOf(address(this));
					IERC20(reflectionToken).transfer(distributorAddress, reflectionBalance);
				    distributor.deposit(reflectionBalance);
				    reflectionFeeTotal = reflectionFeeTotal - ((swapTokensAtAmount * tokenToReflection) / (tokenToSwap));
				}
				swapping = false;
			}
        }
		
		if(isExcludedFromFee[sender] || isExcludedFromFee[recipient]) 
		{
            super._transfer(sender, recipient, amount);
        }
		else 
		{
		    uint256 allFee = collectFee(amount, isAutomatedMarketMakerPairs[recipient], !isAutomatedMarketMakerPairs[sender] && !isAutomatedMarketMakerPairs[recipient]);
			if(allFee > 0) 
			{
			   super._transfer(sender, address(this), allFee);
			}
			super._transfer(sender, recipient, amount - allFee);
        }
		
		if(!isDividendExempt[sender]){ try distributor.setShare(sender, balanceOf(sender)) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, balanceOf(recipient)) {} catch {} }
		if(distributionEnabled) 
		{
		   try distributor.process(distributorGas) {} catch {}
		}
    }
	
	function collectFee(uint256 amount, bool sell, bool p2p) private returns (uint256) {
        uint256 newReflectionFee = amount * (p2p ? reflectionFee[2] : sell ? reflectionFee[1] : reflectionFee[0]) / 10000;

		reflectionFeeTotal += newReflectionFee;
        return (newReflectionFee);
    }
	
	function swapTokensForAvax(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = camelotRouter.WETH();
		
        _approve(address(this), address(camelotRouter), tokenAmount);
        camelotRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            address(this),
            block.timestamp
        );
    }
	
	function swapAvaxForReflection(uint256 AvaxAmount) private {
        address[] memory path = new address[](2);
        path[0] = camelotRouter.WETH();
        path[1] = address(reflectionToken);
		
        camelotRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: AvaxAmount}(
            0,
            path,
            address(this),
            address(this),
            block.timestamp
        );
    }
	
	function setIsDividendExempt(address holder, bool status) external onlyOwner {
       isDividendExempt[holder] = status;
       if(status)
	   {
            distributor.setShare(holder, 0);
       }
	   else
	   {
            distributor.setShare(holder, balanceOf(holder));
       }
    }
	
	function setDistributionStatus(bool status) external onlyOwner {
        distributionEnabled = status;
    }
	
	function setDistributionCriteria(uint256 minPeriod, uint256 minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(minPeriod, minDistribution);
    }
	
	function setDistributorGas(uint256 gas) external onlyOwner {
       require(gas < 750000, "Gas is greater than limit");
       distributorGas = gas;
    }

	function removeMaxTx() external onlyOwner {
		maxTx = 100_000_000_000 * (10 ** 18);
	}

	function removeMaxWallet() external onlyOwner {
		maxWallet = 100_000_000_000 * (10 ** 18);
	}

    function disableReflections() external onlyOwner {
        if(reflectionsEnabled == true){
        reflectionsEnabled = false;
        }
        else { reflectionsEnabled = true; }
    }
}