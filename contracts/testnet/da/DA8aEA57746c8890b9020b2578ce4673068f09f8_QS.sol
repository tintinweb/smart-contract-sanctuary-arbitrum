//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IDividendDistributor.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import './IDexRouter.sol';

// 0x4648a43B2C14Da09FdF82B161150d3F634f40491
contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
 
    address _token;
 
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
 
    // TODO change me USDC
    IERC20 ARB = IERC20(0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892);
    address WETH;
    IDexRouter router;
 
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
 
    mapping (address => Share) public shares;
 
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);
 
    uint256 currentIndex;
 
    modifier onlyToken() {
        require(msg.sender == _token); _;
    }
 
    constructor () {
        router = IDexRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        _token = msg.sender;
        WETH = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3;
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
        uint256 balanceBefore = ARB.balanceOf(address(this));
 
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(ARB);
 
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );
 
        uint256 amount = ARB.balanceOf(address(this)).sub(balanceBefore);
 
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
            ARB.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
 
    function claimDividend() external {
        distributeDividend(msg.sender);
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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDexRouter {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";
import "./IDexRouter.sol";
import "./Auth.sol";
import "./DividendDistributor.sol";
import "./DividendDistributor.sol";
import "./IFactory.sol";
import "./SafeMath.sol";

contract QS is IERC20, Auth {
    using SafeMath for uint256;

    // Events
    event SetMaxWallet(uint256 maxWalletToken);
    event SetFees(uint256 DevFee);
    event SetSwapBackSettings(bool enabled, uint256 swapThreshold);
    event SetIsFeeExempt(address holder, bool enabled);
    event SetIsTxLimitExempt(address holder, bool enabled);
    event SetFeeReceiver(address DevWallet);
    event StuckBalanceSent(uint256 amountETH, address recipient);
    event AutoLiquify(uint256 amountETH, uint256 amountToken);

    // Mappings
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isDividendExempt;

    string constant _name = "QS";
    string constant _symbol = "QS";
    uint8 constant _decimals = 18;
    uint256 _totalSupply = 1_000_000_000 * (10 ** _decimals);

    // Max Wallet
    uint256 public _maxWalletSize = (_totalSupply * 15) / 1000;
    uint256 public _maxTxSize = (_totalSupply * 15) / 1000;

    // Fees
    uint256 liquidityFee = 300; // 3%
    uint256 reflectionFee = 500; // 5%
    uint256 marketingFee = 200; // 2%
    uint256 totalFee = 1000;
    uint256 feeDenominator = 10000;

    // Fee receiver & Dead Wallet
    address public _devWallet;
    address public marketingFeeReceiver;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    // Router
    IDexRouter public router;
    address public pair;

    // TODO Change to USDC goerli testnet
    address Liq = 0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892;
    address WETH = 0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3;
    address public dist;

    // Launch
    uint256 public launchedAt;
    uint256 public launchedAtTimestamp;

    uint256 buybackMultiplierNumerator = 200;
    uint256 buybackMultiplierDenominator = 100;
    uint256 buybackMultiplierTriggeredAt;
    uint256 buybackMultiplierLength = 30 minutes;

    // Liquidity
    uint256 targetLiquidity = 25;
    uint256 targetLiquidityDenominator = 100;
    address autoLiquidityReceiver;

    // Swap
    bool public swapEnabled = true;
    uint256 public swapThreshold = (_totalSupply / 10000) * 3; // 0.3%
    bool inSwap;

    // Trading -> false on mainnet
    bool public isTradingEnabled = true;

    // Dividend Distributor
    DividendDistributor distributor;
    address public distributorAddress;
    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);
    uint256 distributorGas = 500000;

    // modifiers
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() Auth(msg.sender) {
        router = IDexRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        _allowances[address(this)][address(router)] = type(uint256).max;

        _devWallet = msg.sender;
        marketingFeeReceiver = msg.sender;
        autoLiquidityReceiver = msg.sender;

        isFeeExempt[owner] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[dist] = true;

        isTxLimitExempt[owner] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[dist] = true;

        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _balances[owner] = (_totalSupply * 100) / 100;
        approve(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, _totalSupply);

        emit Transfer(address(0), owner, (_totalSupply * 100) / 100);
    }

    // Basic Functions
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _marketingFeeReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - (amount);
        }

        return _transferFrom(sender, recipient, amount);

    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        require(
            isFeeExempt[sender] || isFeeExempt[recipient] || isTradingEnabled,
            "Not authorized to trade yet"
        );

        if (
            sender != owner &&
            sender != marketingFeeReceiver &&
            recipient != owner &&
            recipient != DEAD &&
            recipient != pair
        ) {
            require(
                isTxLimitExempt[recipient] ||
                    (amount <= _maxTxSize &&
                        _balances[recipient] + amount <= _maxWalletSize),
                "Transfer amount exceeds the MaxWallet size."
            );
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = (!shouldTakeFee(sender) ||
            !shouldTakeFee(recipient))
            ? takeFee(sender, recipient, amount)
            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try
                distributor.setShare(recipient, _balances[recipient])
            {} catch {}
        }

        try distributor.process(distributorGas) {} catch {}

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function setIsTradingEnabled(bool _isTradingEnabled) public authorized {
        isTradingEnabled = _isTradingEnabled;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            msg.sender != pair &&
            !inSwap &&
            swapEnabled &&
            _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(
            targetLiquidity,
            targetLiquidityDenominator
        )
            ? 0
            : liquidityFee;
        uint256 amountToLiquify = swapThreshold
            .mul(dynamicLiquidityFee)
            .div(totalFee)
            .div(2);
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

        uint256 amountETH = address(this).balance.sub(balanceBefore);
 
        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));
 
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHReflection = amountETH.mul(reflectionFee).div(totalETHFee);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
 
        try distributor.deposit{value: amountETHReflection}() {} catch {}
        payable(marketingFeeReceiver).transfer(amountETHMarketing);

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                Liq,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, to, block.timestamp);
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() public authorized {
        require(launchedAt == 0, "Already launched boi");
        launchedAt = block.number;
        launchedAtTimestamp = block.timestamp;
    }

    function getPair() public authorized {
        pair = IFactory(router.factory()).getPair(address(this), Liq);
        if (pair == address(0)) {
            pair = IFactory(router.factory()).createPair(address(this), Liq);
        }
    }

    function setIsDividendExempt(
        address holder,
        bool exempt
    ) external authorized {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
        emit SetIsFeeExempt(holder, exempt);
    }

    function setIsTxLimitExempt(
        address holder,
        bool exempt
    ) external authorized {
        isTxLimitExempt[holder] = exempt;
        emit SetIsTxLimitExempt(holder, exempt);
    }

    function takeFee(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (uint256) {
    uint256 feeAmount = amount.mul(getTotalFee(recipient == pair)).div(
            feeDenominator
        );

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + 1 >= block.number) {
            return feeDenominator.sub(1);
        }
        if (selling) {
            return getMultipliedFee();
        }
        return totalFee;
    }
        
    function getMultipliedFee() public view returns (uint256) {
        if (launchedAtTimestamp + 1 days > block.timestamp) {
            return totalFee.mul(18000).div(feeDenominator);
        } else if (
            buybackMultiplierTriggeredAt.add(buybackMultiplierLength) >
            block.timestamp
        ) {
            uint256 remainingTime = buybackMultiplierTriggeredAt
                .add(buybackMultiplierLength)
                .sub(block.timestamp);
            uint256 feeIncrease = totalFee
                .mul(buybackMultiplierNumerator)
                .div(buybackMultiplierDenominator)
                .sub(totalFee);
            return
                totalFee.add(
                    feeIncrease.mul(remainingTime).div(buybackMultiplierLength)
                );
        }
        return totalFee;
    }

    function setTargetLiquidity(
        uint256 _target,
        uint256 _denominator
    ) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external authorized {
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        distributorGas = gas;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function setMaxWalletAndTx(
        uint256 _maxWalletSize_,
        uint256 _maxTxSize_
    ) external authorized {
        require(
            _maxWalletSize_ >= _totalSupply / 1000 &&
                _maxTxSize_ >= _totalSupply / 1000,
            "Can't set MaxWallet or Tx below 0.1%"
        );
        _maxWalletSize = _maxWalletSize_;
        _maxTxSize = _maxTxSize_;
        emit SetMaxWallet(_maxWalletSize);
    }

    function isOverLiquified(
        uint256 target,
        uint256 accuracy
    ) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function getLiquidityBacking(
        uint256 accuracy
    ) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

     function setFees(
        uint256 _liquidityFee,
        uint256 _reflectionFee,
        uint256 _marketingFee,
        uint256 _feeDenominator
    ) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee);
        feeDenominator = _feeDenominator;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
 
/**
 * SAFEMATH LIBRARY
 */
library SafeMath {
 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
 
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
 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
 
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}