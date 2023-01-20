/**
 *Submitted for verification at Arbiscan on 2023-01-20
*/

pragma solidity ^0.8.0;

/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

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

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address _owner, address spender)
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

/**
 * Allows for contract ownership along with multi-address authorization
 */
abstract contract Auth {
    address owner;
    mapping(address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Any authorized address
     */
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
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
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

/**
 * Pause and unpause certain functions using modifiers
 */
abstract contract Pausable is Auth {
    bool public paused;

    constructor(bool _paused) {
        paused = _paused;
    }

    modifier whenPaused() {
        require(paused || isAuthorized(msg.sender), "!PAUSED");
        _;
    }

    modifier notPaused() {
        require(!paused || isAuthorized(msg.sender), "PAUSED");
        _;
    }

    function pause() external notPaused authorized {
        paused = true;
        emit Paused();
    }

    function unpause() public whenPaused authorized {
        _unpause();
    }

    function _unpause() internal {
        paused = false;
        emit Unpaused();
    }

    event Paused();
    event Unpaused();
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract CasinoChip is IBEP20, Auth, Pausable {
    using SafeMath for uint256;

    string constant _name = "ArbiRoul Casino Chip";
    string constant _symbol = "ROUL";
    uint8 constant _decimals = 18;

    uint256 private _totalSupply = 300000000 * (10**_decimals);
    uint256 public _maxTxAmount = 6000000 * (10**_decimals);

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public hasFee;
    mapping(address => bool) public isExempt;

    uint256 public autoLiquidityFee = 4;
    uint256 public devFee = 1;
    uint256 public feeDenominator = 100;

    address public autoLiquidityReceiver;
    address public devFeeReceiver;

    address public casino;

    IDEXRouter public router;
    address private WBNB;
    address public liquifyPair;

    uint256 launchedAt;

    bool public liquifyEnabled = true;
    uint256 public liquifyAmount = 300000 * (10**_decimals);
    bool private inLiquify;
    modifier liquifying() {
        inLiquify = true;
        _;
        inLiquify = false;
    }

    constructor(address _owner, address _router) Auth(_owner) Pausable(true) {
        router = IDEXRouter(_router);
        WBNB = router.WETH();
        liquifyPair = IDEXFactory(router.factory()).createPair(
            WBNB,
            address(this)
        );

        _allowances[address(this)][_router] = type(uint256).max;
        hasFee[liquifyPair] = true;
        isExempt[_owner] = true;
        isExempt[address(this)] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);

        payable(_owner).transfer(address(this).balance);
    }

    receive() external payable {
        assert(msg.sender == WBNB || msg.sender == address(router));
    }

    modifier migrationProtection(address sender) {
        require(
            !paused || isAuthorized(sender) || isAuthorized(msg.sender),
            "PROTECTED"
        );
        _;
    }

    modifier onlyCasino() {
        require(
            msg.sender == casino,
            "Only casino contract can call these functions"
        );
        _;
    }

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

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function casinoPay(address account, uint256 amount) external onlyCasino {
        _mint(account, amount);
    }

    function casinoTake(address account, uint256 amount) external onlyCasino {
        _burn(account, amount);
    }

    // ONLY FOR INTERNAL CALLS FROM CASINO CONTRACT
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    // ONLY FOR INTERNAL CALLS FROM CASINO CONTRACT
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance.sub(amount);
        _totalSupply = _totalSupply.sub(amount);

        emit Transfer(account, address(0), amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal migrationProtection(sender) returns (bool) {
        checkTxLimit(sender, recipient, amount);

        if (
            sender != msg.sender &&
            _allowances[sender][msg.sender] != type(uint256).max
        ) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
                .sub(amount, "Insufficient Allowance");
        }

        if (launchedAt == 0 && recipient == liquifyPair) {
            launch();
        }

        bool shouldLiquify = shouldAutoLiquify() &&
            !(isExempt[sender] || isExempt[recipient]);
        if (shouldLiquify) {
            autoLiquify();
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, amount)
            : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal view {
        require(
            amount <= _maxTxAmount || isExempt[sender] || isExempt[recipient],
            "TX Limit Exceeded"
        );
    }

    function takeFee(address sender, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 liquidityFeeAmount = amount.mul(getLiquidityFee()).div(
            feeDenominator
        );
        uint256 devFeeAmount = amount.mul(devFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(
            liquidityFeeAmount
        );
        _balances[devFeeReceiver] = _balances[devFeeReceiver].add(devFeeAmount);

        emit Transfer(sender, address(this), liquidityFeeAmount);
        emit Transfer(sender, devFeeReceiver, devFeeAmount);

        return amount.sub(liquidityFeeAmount).sub(devFeeAmount);
    }

    function getLiquidityFee() internal view returns (uint256) {
        if (launchedAt + 1 >= block.number) {
            return feeDenominator.sub(devFee).sub(1);
        }
        return autoLiquidityFee;
    }

    function shouldAutoLiquify() internal view returns (bool) {
        return
            msg.sender != liquifyPair &&
            !inLiquify &&
            liquifyEnabled &&
            _balances[address(this)] >= liquifyAmount;
    }

    function autoLiquify() internal liquifying {
        uint256 amountToSwap = liquifyAmount.div(2);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        try
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {}

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        try
            router.addLiquidityETH{value: amountBNB}(
                address(this),
                amountToSwap,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            )
        {
            emit AutoLiquify(amountBNB, amountToSwap);
        } catch {}
    }

    function launch() internal {
        launchedAt = block.number;
        _unpause();
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000, "Limit too low");
        _maxTxAmount = amount;
    }

    function setLiquify(bool enabled, uint256 amount) external authorized {
        require(amount <= 1000 * (10**_decimals));
        liquifyEnabled = enabled;
        liquifyAmount = amount;
    }

    function migrateAutoLiquidityDEX(address _router, address _liquifyPair)
        external
        authorized
    {
        _allowances[address(this)][address(router)] = 0;
        router = IDEXRouter(_router);
        liquifyPair = _liquifyPair;
        hasFee[liquifyPair] = true;
        _allowances[address(this)][_router] = type(uint256).max;
    }

    function shouldTakeFee(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (isExempt[sender] || isExempt[recipient] || inLiquify) {
            return false;
        }
        return hasFee[sender] || hasFee[recipient];
    }

    function setHasFee(address adr, bool state) external authorized {
        require(!isExempt[adr], "Is Exempt");
        hasFee[adr] = state;
    }

    function setIsExempt(address adr, bool state) external authorized {
        require(!hasFee[adr], "Has Fee");
        isExempt[adr] = state;
    }

    function setFees(
        uint256 _liquidityFee,
        uint256 _devFee,
        uint256 _feeDenominator
    ) external authorized {
        autoLiquidityFee = _liquidityFee;
        devFee = _devFee;

        feeDenominator = _feeDenominator;

        require(
            autoLiquidityFee.add(devFee).mul(100).div(feeDenominator) <= 10,
            "Fee Limit Exceeded"
        );
    }

    function setFeeReceivers(
        address _autoLiquidityReceiver,
        address _devFeeReceiver
    ) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        devFeeReceiver = _devFeeReceiver;
    }

    function setCasino(address casinoContract) external authorized {
        casino = casinoContract;
    }

    function rescue() external authorized {
        payable(msg.sender).transfer(address(this).balance);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}