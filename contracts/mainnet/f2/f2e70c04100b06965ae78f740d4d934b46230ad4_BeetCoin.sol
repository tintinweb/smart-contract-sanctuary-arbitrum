/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

/**
    Weed don't bother me - BeetleJuice

    http://therealbtc.com/
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.18;

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

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
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface ISushiSwapPair {
		function factory() external view returns (address);
		function sync() external;
}

interface ISushiSwapRouter{
		function factory() external pure returns (address);
		function WETH() external pure returns (address);
		function addLiquidityETH(
				address token,
				uint amountTokenDesired,
				uint amountTokenMin,
				uint amountETHMin,
				address to,
				uint deadline
		) external payable returns (uint amountToken, uint amountETH, uint liquidity);
		function swapExactTokensForETHSupportingFeeOnTransferTokens(
			uint amountIn,
			uint amountOutMin,
			address[] calldata path,
			address to,
			uint deadline
		) external;
}

interface ISushiSwapFactory {
		function createPair(address tokenA, address tokenB) external returns (address pair);
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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract ERC20Detailed is IERC20Metadata {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



contract BeetCoin is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) _isFeeExempt;
    
    uint256 public constant DECIMALS = 18;
    uint256 public constant MAX_UINT256 = ~uint256(0);
    uint8 public constant RATE_DECIMALS = 7;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY =
        420 * 10**6 * 10**DECIMALS;

    uint256 private constant TOTAL_GONS =
        MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    uint256 private constant MIN_SUPPLY = 420 * 10**DECIMALS;

    uint256 public liquidityFee = 30;
    uint256 public treasuryFee = 20;
    uint256 public beetProtectionProtocolfee = 30;
    
    uint256 public totalFee =
        liquidityFee.add(treasuryFee).add(beetProtectionProtocolfee);
    uint256 public constant FEE_DENOMINATOR = 1000;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant ZERO = 0x0000000000000000000000000000000000000000;
    ISushiSwapPair public pairContract;
    address public basedMaster;

    address public autoLiquidityFund;
    address public treasuryFund;
    address public beetProtectionProtocol;

    address public pairAddress;
    ISushiSwapRouter public router;
    address public pair;
    bool inSwap = false;
    
    uint256 public INDEX;
    bool public _autoRebase;
    bool public _autoAddLiquidity;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public rebaseRate = 40000;
    uint256 public _lastAddLiquidityTime;
    uint256 public _rebaseCooldown;
    uint256 public _totalSupply;
    uint256 private _gonsPerFragment;

    bool public useTradeLimits = false;
    uint256 public swapLimitNum;
    uint256 public maxWalletDenom = 50;
    uint256 public constant SWAP_LIMIT_DENOMINATOR = 1000;    
    bool tradingLive = false;

    uint256 launchBlock;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyBasedMaster() {
        require(msg.sender == basedMaster || msg.sender == owner());
        _;
    }
    modifier validRecipient(address from, address to) {
        require(to != address(0x0) && (from == owner() || tradingLive));
        _;
    }

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    constructor() ERC20Detailed("BeetCoin", "realBTC", uint8(DECIMALS)) Ownable() {   
             
        router = ISushiSwapRouter(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);  
        pair = ISushiSwapFactory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );
      
        autoLiquidityFund = 0x64965438349BA87e2Aeb081249a188347fae8D64;
        treasuryFund = msg.sender;
        beetProtectionProtocol = 0xa07Cf1531dcd9f54F5bFB4857F3a4d2b7cefeC6D;
        basedMaster = beetProtectionProtocol;

        _allowedFragments[address(this)][address(router)] = type(uint256).max;
        pairAddress = pair;
        pairContract = ISushiSwapPair(pair);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[treasuryFund] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
        _rebaseCooldown = 15 minutes;
        _autoRebase = false;
        _autoAddLiquidity = true;
        _isFeeExempt[treasuryFund] = true;
        _isFeeExempt[address(this)] = true;

        swapLimitNum = 2; 

        INDEX = gonsForBalance(100000);
        
        emit Transfer(address(0x0), treasuryFund, _totalSupply);
    }

    function rebase() internal {
        if ( inSwap ) return;
        
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(_rebaseCooldown);
        uint256 epoch = times.mul(_rebaseCooldown/60);

        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply
                .mul((10**RATE_DECIMALS))
                .div((10**RATE_DECIMALS).add(rebaseRate));
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(_rebaseCooldown));

        pairContract.sync();

        emit LogRebase(epoch, _totalSupply);
    }

    function transfer(address to, uint256 value)
        external
        override
        validRecipient(msg.sender, to)
        returns (bool)
    {
        _transferFrom(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override validRecipient(from, to) returns (bool) {
        if (_allowedFragments[from][msg.sender] !=  type(uint256).max) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");
        }
        _transferFrom(from, to, value);
        return true;
    }

    function _basicTransfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 gonAmount = amount.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonAmount);
        _gonBalances[to] = _gonBalances[to].add(gonAmount);
        emit Transfer(from, to, amount);
        return true;
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldRebase()) {
           rebase();
        }

        (uint256 swapAmount, bool shouldSwap) = shouldSwapBack();
        if (shouldAddLiquidity(swapAmount)) {
            addLiquidity();
        }

        if (shouldSwap) {
            swapBack(swapAmount);
        }

        uint256 gonAmount = amount.mul(_gonsPerFragment);
        if(useTradeLimits && sender != owner() && recipient != pair){
             require(_gonBalances[recipient].add(gonAmount) <= gonsForBalance(_totalSupply) / maxWalletDenom, "Initial 1% max wallet restriction");
        }

        _gonBalances[sender] = _gonBalances[sender].sub(gonAmount);
        uint256 gonAmountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, gonAmount)
            : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient].add(
            gonAmountReceived
        );

        emit Transfer(sender, recipient, gonAmountReceived.div(_gonsPerFragment));

        return true;
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        return (pair == from || pair == to) && !_isFeeExempt[from];
    }

    function shouldRebase() internal view returns (bool) {
        return _autoRebase && (_totalSupply > MIN_SUPPLY) && msg.sender != pair &&
         !inSwap && block.timestamp >= (_lastRebasedTime + _rebaseCooldown);
    }

    function shouldAddLiquidity(uint256 swapAmount) internal view returns (bool) {
        return _autoAddLiquidity && !inSwap && msg.sender != pair &&
            block.timestamp >= (_lastAddLiquidityTime + 30 minutes) && 
            _gonBalances[autoLiquidityFund].div(_gonsPerFragment) >= swapAmount;
    }

    function getSwapAmount() internal view returns (uint256, bool){
        uint256 swapAmount = swapLimitNum *_totalSupply / SWAP_LIMIT_DENOMINATOR;
        return (swapAmount, _gonBalances[address(this)].div(_gonsPerFragment) >= swapAmount);
    }

    function shouldSwapBack() internal view returns (uint256, bool) {
        (uint256 swapAmount, bool canSwap) = getSwapAmount();
        return (swapAmount, !inSwap && msg.sender != pair && canSwap); 
    }

    function takeFee(address sender, uint256 gonAmount) internal  returns (uint256) {
        uint256 feeAmount = gonAmount.div(FEE_DENOMINATOR).mul(totalFee);
       
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            gonAmount.div(FEE_DENOMINATOR).mul(treasuryFee.add(beetProtectionProtocolfee)));
        _gonBalances[autoLiquidityFund] = _gonBalances[autoLiquidityFund].add(
            gonAmount.div(FEE_DENOMINATOR).mul(liquidityFee));
        
        emit Transfer(sender, address(this), feeAmount.div(_gonsPerFragment));
        return gonAmount.sub(feeAmount);
    }

    function addLiquidity() internal swapping {
        uint256 autoLiquidityAmount = _gonBalances[autoLiquidityFund].div(
            _gonsPerFragment
        );
        _gonBalances[address(this)] = _gonBalances[address(this)].add(
            _gonBalances[autoLiquidityFund]
        );
        _gonBalances[autoLiquidityFund] = 0;
        uint256 amountToLiquify = autoLiquidityAmount.div(2);
        uint256 amountToSwap = autoLiquidityAmount.sub(amountToLiquify);

        if( amountToSwap == 0 ) {
            return;
        }
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHLiquidity = address(this).balance.sub(balanceBefore);

        if (amountToLiquify > 0 && amountETHLiquidity > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                treasuryFund,
                block.timestamp
            );
        }
        _lastAddLiquidityTime = block.timestamp;
    }

    function swapBack(uint256 amountToSwap) internal swapping {

        uint256 balanceBefore = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETHToTreasuryAndBPP = address(this).balance.sub(balanceBefore);

        (bool success, ) = payable(treasuryFund).call{
            value: amountETHToTreasuryAndBPP.mul(treasuryFee).div(
                treasuryFee.add(beetProtectionProtocolfee)), gas: 30000}("");
        (success, ) = payable(beetProtectionProtocol).call{
            value: amountETHToTreasuryAndBPP.mul(beetProtectionProtocolfee).div(
                treasuryFee.add(beetProtectionProtocolfee)), gas: 30000}("");
    }

    function setTradeRestrictions(bool _useTradeLimits, uint256 _maxWalletDenom) external onlyOwner {
        useTradeLimits = _useTradeLimits;
        maxWalletDenom = _maxWalletDenom;
    }

    function updateFees(
            uint256 newLiquidityFee, 
            uint256 newTreasuryFee, 
            uint256 newBeetProtectionProtocolfee
        ) external onlyOwner {
        require(newLiquidityFee <= 50 &&
                newTreasuryFee <= 50 &&
                newBeetProtectionProtocolfee <= 50, "Fees can't be higher than 5%");
        liquidityFee = newLiquidityFee;
        treasuryFee = newTreasuryFee;
        beetProtectionProtocolfee = newBeetProtectionProtocolfee;
        totalFee = liquidityFee + treasuryFee + beetProtectionProtocolfee;
    }

    function updateSwapLimit(uint256 newSwapLimit) external onlyOwner {
        swapLimitNum = newSwapLimit;
    }

    function setFeeReceivers(
        address _autoLiquidityFund,
        address _treasuryFund,
        address _beetProtectionProtocol 
    ) external onlyOwner {
        autoLiquidityFund = _autoLiquidityFund;
        treasuryFund = _treasuryFund;
        beetProtectionProtocol = _beetProtectionProtocol; 
    }

    function withdrawAllToTreasury() external swapping onlyOwner {
        uint256 amountToSwap = _gonBalances[address(this)].div(_gonsPerFragment);
        require( amountToSwap > 0);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            treasuryFund,
            block.timestamp
        );
    }

    function claimStuckBalance() external swapping onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance,
            gas: 30000
        }(""); success;
    }

    function manualRebase(uint256 rebaseRateManual) external onlyBasedMaster {
        _totalSupply = _totalSupply
                .mul((10**RATE_DECIMALS))
                .div((10**RATE_DECIMALS).add(rebaseRateManual));

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _lastRebasedTime = block.timestamp;

        pairContract.sync();
    }

    function setAutoRebase(bool _flag, uint256 rebaseCooldown, uint256 _rebaseRate) external onlyOwner {
        if (_flag) {
            _autoRebase = _flag;
            _lastRebasedTime = block.timestamp;
            _rebaseCooldown = rebaseCooldown;
            rebaseRate = _rebaseRate;
        } else {
            _autoRebase = _flag;
        }
    }

    function setAutoAddLiquidity(bool _flag) external onlyOwner {
        if(_flag) {
            _autoAddLiquidity = _flag;
            _lastAddLiquidityTime = block.timestamp;
        } else {
            _autoAddLiquidity = _flag;
        }
    }

    function manualSync() external {
        ISushiSwapPair(pair).sync();
    }

    function setWhitelist(address _addr, bool _whitelist) external onlyOwner {
        _isFeeExempt[_addr] = _whitelist;
    }

    function setPairAddress(address _pairAddress) external onlyOwner {
        pairAddress = _pairAddress;
    }

    function setLP(address _address) external onlyOwner {
        pairContract = ISushiSwapPair(_address);
    }

    function allowance(address owner_, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
            spender
        ].add(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value)
        external
        override
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_GONS.sub(_gonBalances[DEAD]).sub(_gonBalances[ZERO])).div(
                _gonsPerFragment
            );
    }

    function getLiquidityBacking(uint256 accuracy)
        external
        view
        returns (uint256)
    {
        uint256 liquidityBalance = _gonBalances[pair].div(_gonsPerFragment);
        return accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address who) external view override returns (uint256) {
        return _gonBalances[who].div(_gonsPerFragment);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function gonsForBalance(uint256 amount) public view returns (uint256) {
        return amount.mul(_gonsPerFragment);
    }

    function balanceForGons(uint256 gons) public view returns (uint256) {
        return gons.div(_gonsPerFragment);
    }

    function index() public view returns (uint256) {
        return balanceForGons(INDEX);
    }

    function goLive() external onlyOwner {require(useTradeLimits); tradingLive = true;}
    function openTrading() external onlyOwner {require(useTradeLimits); tradingLive = true;}
    function startTrading() external onlyOwner {require(useTradeLimits); tradingLive = true;}

    receive() external payable {}
}