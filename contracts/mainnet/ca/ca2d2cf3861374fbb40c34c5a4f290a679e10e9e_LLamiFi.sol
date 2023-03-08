/**
 *Submitted for verification at Arbiscan on 2023-03-07
*/

// File: LLamiFi3/Libraries/IDEXRouter2.sol


pragma solidity ^0.8.9;

//camelot
interface IDEXRouter2 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

      function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    )
    external;
}
// File: LLamiFi3/Libraries/IDividendDistributor.sol


pragma solidity ^0.8.9;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function changeTokenReward(address newTokenDividends) external;
    function changeRouter(address _router) external;
    function unstuckToken(address _receiver) external;
}
// File: LLamiFi3/Libraries/IDEXRouter.sol


pragma solidity ^0.8.9;

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: LLamiFi3/Libraries/IDEXFactory.sol


pragma solidity ^0.8.9;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
// File: LLamiFi3/BasicLibraries/IBEP20.sol


pragma solidity ^0.8.9;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: LLamiFi3/BasicLibraries/Auth.sol


pragma solidity ^0.8.9;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}
// File: LLamiFi3/BasicLibraries/SafeMath.sol


pragma solidity ^0.8.9;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: LLamiFi3/Libraries/DividendDistributor.sol


pragma solidity ^0.8.9;





contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    // EARN
    IBEP20 public RWRD = IBEP20(0x0000000000000000000000000000000000000000);
    address WBNB = 0x0000000000000000000000000000000000000000;
    IDEXRouter2 router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 30 * 60;
    uint256 public minDistribution = 1 * (10 ** 12);

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router, address _WBNB) {
        WBNB = _WBNB;
        router = _router != address(0)
            ? IDEXRouter2(_router)
            : IDEXRouter2(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = RWRD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WBNB;
        path[1] = address(RWRD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            address(0),
            block.timestamp
        );

        uint256 amount = RWRD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            RWRD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function claimDividend(address shareholder) external onlyToken{
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
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

    function changeTokenReward(address newTokenDividends) external override onlyToken {
        RWRD = IBEP20(newTokenDividends);
    }

    function changeRouter(address _router) external override onlyToken {
        router = IDEXRouter2(_router);
    }

    function unstuckToken(address _receiver) external override onlyToken {
        uint256 amount = RWRD.balanceOf(address(this));
        RWRD.transfer(_receiver, amount);
    }
}
// File: LLamiFi3/LLamiFi.sol

/*
    Token contract - Arbitrum Token
    Developed by Kraitor <TG: kraitordev>
*/

pragma solidity ^0.8.9;







contract LLamiFi is Auth, IBEP20 {
    using SafeMath for uint256;

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;
    address routerAdr = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    string constant _name = "LLamiFi";
    string constant _symbol = "$LLAMI";
    uint8 constant _decimals = 9;
    uint256 _totalSupply = 1 * 10**8 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply.mul(2).div(100);
    uint256 public _maxWalletToken = _totalSupply.mul(2).div(100);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
        
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isTxLimitExempt;

    // 60/1000 6%
    uint256 private devFee          = 6;
    uint256 private teamFee         = 6;
    uint256 private treasuryFee     = 18;
    uint256 private liquidityFee    = 0;  
    uint256 private burnFee         = 12;       
    uint256 private rewardsFee      = 0;
    uint256 private stakingFee      = 0;
    uint256 private buybackFee      = 18;
    uint256 private proj1Fee        = 0;
    uint256 private proj2Fee        = 0;
 
    uint256 public totalFeeBase1000 = devFee + teamFee + treasuryFee + liquidityFee + rewardsFee + buybackFee + stakingFee + burnFee + proj1Fee + proj2Fee;
    uint256 public feeDenominator   = 1000;
 
    uint256 sellMultiplier = 100;
    uint256 buyMultiplier = 100;
    uint256 transferMultiplier = 100;

    address public autoLiquidityReceiver;
    address public treasuryFeeReceiver;
    address public buybackFeeReceiver;
    address public devFeeReceiver;
    address public teamFeeReceiver;
    address public stakingFeeReceiver;
    address public project1FeeReceiver;
    address public project2FeeReceiver;

    uint256 targetLiquidity = 80; //40% of supply
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
   
    address public distributorAdr = address(0);
    DividendDistributor distributor;
    uint256 distributorGas = 500000;

    bool public tradingOpen = false;    
    
    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 25 / 10000;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(routerAdr);     
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        distributor = new DividendDistributor(address(router), WETH);
        distributorAdr = address(distributor);
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[ZERO] = true;

        autoLiquidityReceiver = msg.sender;
        treasuryFeeReceiver = msg.sender;
        buybackFeeReceiver = msg.sender;
        devFeeReceiver = msg.sender;
        teamFeeReceiver = msg.sender;
        stakingFeeReceiver = msg.sender; 
        project1FeeReceiver = msg.sender;
        project2FeeReceiver = msg.sender;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[DEAD] = true;
        isFeeExempt[ZERO] = true;

        isTxLimitExempt[msg.sender] = true;        
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[pair] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) {return owner;}
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }    

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function transferBulk(address [] calldata addresses, uint256 [] calldata amounts) external {
        require(addresses.length == amounts.length, 'Arrays of different size');
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i; i < addresses.length; ++i) {
            this.transferFrom(msg.sender, addresses[i], amounts[i]);
        }
    }

    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    function _burn(address _sender, uint256 amount) internal {
        _transferFrom(_sender, DEAD, amount);
    }

    function setMaxWalletPercent_base1000(uint256 maxWallPercent_base1000) external onlyOwner {
        require(maxWallPercent_base1000 >= 10,"Cannot set max wallet less than 1%");
        _maxWalletToken = (_totalSupply * maxWallPercent_base1000 ) / 1000;
    }

    function setMaxTxPercent_base1000(uint256 maxTXPercentage_base1000) external onlyOwner {
        require(maxTXPercentage_base1000 >= 10,"Cannot set max transaction less than 1%");
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000 ) / 1000;
    }

    function manageAuthorizations(address account, bool status) public virtual onlyOwner {
        authorizations[account] = status;
    }
    
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpen,"Trading not open yet");
        }        
        
        if (!authorizations[sender] && recipient != address(this) && recipient != address(DEAD) && recipient != pair && recipient != stakingFeeReceiver && recipient != treasuryFeeReceiver && !isTxLimitExempt[recipient]){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}

        checkTxLimit(sender, amount);

        if(shouldSwapBack()){ swapBack(); }
       
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

         uint256 amountReceived = (isFeeExempt[sender] || isFeeExempt[recipient]) ? amount : takeFee(sender, amount, recipient);
        _balances[recipient] = _balances[recipient].add(amountReceived);

        // Dividend tracker //
        if(!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }

        if(!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]) {} catch {} 
        }

        if(rewardsFee > 0){
            try distributor.process(distributorGas) {} catch {}
        }
        ///////////////////////

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount, address recipient) internal returns (uint256) {

        uint256 multiplier = transferMultiplier;
        if(recipient == pair) {
            multiplier = sellMultiplier;
        } else if(sender == pair) {
            multiplier = buyMultiplier;
        }

        uint256 feeAmount = amount.mul(totalFeeBase1000).mul(multiplier).div(feeDenominator * 100);

        uint256 stakingTokens = feeAmount.mul(stakingFee).div(totalFeeBase1000);
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFeeBase1000);
        uint256 contractTokens = feeAmount.sub(stakingTokens).sub(burnTokens);

        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(stakingTokens);
        _balances[DEAD] = _balances[DEAD].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
        
        if(stakingTokens > 0){
            emit Transfer(sender, stakingFeeReceiver, stakingTokens);    
        }
        if(burnTokens > 0){
            emit Transfer(sender, DEAD, burnTokens);    
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;    
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool) {
        require(tokenAddress != address(this), 'You can not withdraw the native token');
        if(tokens == 0){
            tokens = IBEP20 (tokenAddress).balanceOf(address(this));
        }
        return IBEP20 (tokenAddress).transfer(msg.sender, tokens);
    }

    function setMultipliers(uint256 _buy, uint256 _sell, uint256 _trans) public onlyOwner {        
        sellMultiplier = _sell;
        buyMultiplier = _buy;
        transferMultiplier = _trans;    

        uint256 buyFee = totalFeeBase1000.mul(buyMultiplier).div(100);
        uint256 sellFee = totalFeeBase1000.mul(sellMultiplier).div(100);
        uint256 transferFee = totalFeeBase1000.mul(transferMultiplier).div(100);

        require(buyFee.add(sellFee) <= feeDenominator.mul(2).div(10), "Buy + Sell tax cannot be more than 20%");        
        require(buyFee.add(transferFee) <= feeDenominator.mul(2).div(10), "Buy + Transfer tax cannot be more than 20%");                
    }

    function OpenTrading() public onlyOwner {
        tradingOpen = true;        
    }

    function ClearStuckBalance() external onlyOwner { 
        payable(msg.sender).transfer(address(this).balance);        
    }

    function swapBack() internal swapping {
        uint256 totalFeeSwapback = totalFeeBase1000.sub(stakingFee).sub(burnFee); //already applied on transfers
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFeeSwapback).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);
        uint256 totalBNBFee = totalFeeSwapback.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        uint256 amountBNBTreasury = amountBNB.mul(treasuryFee).div(totalBNBFee);
        uint256 amountBNBdev = amountBNB.mul(devFee).div(totalBNBFee);
        uint256 amountBNBteam = amountBNB.mul(teamFee).div(totalBNBFee);
        uint256 amountBNBbuyback = amountBNB.mul(buybackFee).div(totalBNBFee);
        uint256 amountBNBRewards = amountBNB.mul(rewardsFee).div(totalBNBFee);
        uint256 amountBNBProj1 = amountBNB.mul(proj1Fee).div(totalBNBFee);
        uint256 amountBNBProj2 = amountBNB.mul(proj2Fee).div(totalBNBFee);

        bool tmpSuccess = payable(treasuryFeeReceiver).send(amountBNBTreasury);
        tmpSuccess = payable(buybackFeeReceiver).send(amountBNBbuyback);
        tmpSuccess = payable(devFeeReceiver).send(amountBNBdev);
        tmpSuccess = payable(teamFeeReceiver).send(amountBNBteam);   
        if(amountBNBRewards > 0){
            try distributor.deposit{value: amountBNBRewards}() {} catch {}
        }
        tmpSuccess = payable(project1FeeReceiver).send(amountBNBProj1);
        tmpSuccess = payable(project2FeeReceiver).send(amountBNBProj2);                
        tmpSuccess = false;

        addLiq(amountToLiquify, amountBNBLiquidity);
    }

    function addLiq(uint256 tokens, uint256 _value) internal {
        if(tokens > 0){
            router.addLiquidityETH{value: _value}(
                address(this),
                tokens,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(_value, tokens);
        }
    }

    function SetIsFeeExempt(address[] calldata addresses, bool status) external onlyOwner {
        _SetIsFeeExempt(addresses, status);
    }

    function _SetIsFeeExempt(address[] memory addresses, bool status) internal {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i; i < addresses.length; ++i) {
            isFeeExempt[addresses[i]] = status;
        }
    }

    function SetIsTxLimitExempt(address[] calldata addresses, bool status) external onlyOwner { //TXLimit Exempt will also Wallet Limit Exempt
        _SetIsTxLimitExempt(addresses, status);
    }

    function _SetIsTxLimitExempt(address[] memory addresses, bool status) internal {
        require(addresses.length < 501,"GAS Error: max limit is 500 addresses");
        for (uint256 i; i < addresses.length; ++i) {
            isTxLimitExempt[addresses[i]] = status;
        }
    }

    function setFees(
        uint256 _liquidityFee, 
        uint256 _devFee, 
        uint256 _teamFee, 
        uint256 _treasuryFee, 
        uint256 _buybackFee, 
        uint256 _stakingFee, 
        uint256 _rewardsFee, 
        uint256 _burnFee, 
        uint256 _proj1Fee, 
        uint256 _proj2Fee
        ) external onlyOwner {
            liquidityFee = _liquidityFee;
            devFee = _devFee;
            teamFee = _teamFee;
            treasuryFee = _treasuryFee;
            buybackFee = _buybackFee;
            stakingFee = _stakingFee;
            rewardsFee = _rewardsFee;
            burnFee = _burnFee;
            proj1Fee = _proj1Fee;
            proj2Fee = _proj2Fee;

            totalFeeBase1000 = _liquidityFee;
            totalFeeBase1000 += _devFee;
            totalFeeBase1000 += _teamFee;
            totalFeeBase1000 += _treasuryFee;
            totalFeeBase1000 += _buybackFee;
            totalFeeBase1000 += _stakingFee;
            totalFeeBase1000 += _rewardsFee;
            totalFeeBase1000 += _burnFee;
            totalFeeBase1000 += _proj1Fee;
            totalFeeBase1000 += _proj2Fee;
            require(totalFeeBase1000 <= feeDenominator.div(10), "Fees cannot be more than 10%");
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver, 
        address _treasuryFeeReceiver, 
        address _buybackFeeReceiver, 
        address _stakingFeeReceiver, 
        address _devFeeReceiver, 
        address _teamFeeReceiver,
        address _project1FeeReceiver,
        address _project2FeeReceiver
        ) external onlyOwner {
            autoLiquidityReceiver = _autoLiquidityReceiver;
            treasuryFeeReceiver = _treasuryFeeReceiver;
            buybackFeeReceiver = _buybackFeeReceiver;
            stakingFeeReceiver = _stakingFeeReceiver;
            devFeeReceiver = _devFeeReceiver;
            teamFeeReceiver = _teamFeeReceiver;
            project1FeeReceiver = _project1FeeReceiver;
            project2FeeReceiver = _project2FeeReceiver;

            uint256 s = 8;
            address[] memory receivers = new address[](s);
            receivers[0] = autoLiquidityReceiver;
            receivers[1] = treasuryFeeReceiver;
            receivers[2] = buybackFeeReceiver;
            receivers[3] = stakingFeeReceiver;
            receivers[4] = devFeeReceiver;
            receivers[5] = teamFeeReceiver;
            receivers[6] = project1FeeReceiver;
            receivers[7] = project2FeeReceiver;

            _SetIsFeeExempt(receivers, true);
            _SetIsTxLimitExempt(receivers, true);
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        require(_amount <= _totalSupply * 50 / 10000, 'Invalid value, swap threshold can not be bigger than 0.5%');
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }   
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;  
    }  

    // Rewards //
    function changeDistributor(address newDistributor) external onlyOwner {
        require(isContract(newDistributor), "Address has to be a contract");
        distributorAdr = newDistributor;
        distributor = DividendDistributor(distributorAdr);
    }

    function changeTokenReward(address tokenReward) external onlyOwner {
        require(isContract(tokenReward), "Address has to be a contract");
        distributor.changeTokenReward(tokenReward);
    }  

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external onlyOwner {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }    

    function setRouterDividends(address _router) external onlyOwner {
        require(isContract(_router), "Address has to be a contract");
        distributor.changeRouter(_router);
    }

    function unstuckRewards() external onlyOwner {
        distributor.unstuckToken(msg.sender);
    }  

    function isContract(address account) internal view returns (bool) { return account.code.length > 0; }
    /////////////
}