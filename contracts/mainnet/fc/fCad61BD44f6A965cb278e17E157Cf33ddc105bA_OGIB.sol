/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

interface IOreoSwapRouter {
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

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);

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

interface IOreoSwapFactory {
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

interface IPlayerManager {
    function checkPlayerExists(address) external returns (bool);
    function playerRewardsActive(address) external returns (bool);
    function updatePlayerStatus(address, bool) external;
}

interface ERC20 {
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

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
}

contract OGIB is ERC20, Auth {
    event SetAutomatedMarketMakerPair(address indexed _pair, bool indexed _value);
    event SetAutomatedMarketMakerRouter(address _router);
    event SetFeeExempt(address _addr, bool _value);
    event SetFeePercentage(uint256 _fee);
    event SetFeeReceiver(address _feeReceiver);
    event SetPlayerManagerContract(address _playerManager);
    event SetSwapBackThreshold(uint256 _amount);
    event SetUsdcOgibThreshold(uint256 _amount);

    address private WETH;
    address private USDC;
    address private DEAD = 0x000000000000000000000000000000000000dEaD;
    address private ZERO = 0x0000000000000000000000000000000000000000;

    IPlayerManager private playerManager;

    string constant private _name = "OGI War Bonds";
    string constant private _symbol = "OGIB";
    uint8 constant private _decimals = 18;

    uint256 private _totalSupply = 1000000000 * 10 ** _decimals;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    address[] public marketPairs;
    mapping (address => bool) public automatedMarketMakerPairs;

    mapping (address => bool) public isFeeExempt;

    uint256 private feePercentage = 2;
    uint256 public maxFeePercentage = 5;

    uint256 private constant feeDenominator  = 100;

    address private feeReceiver;

    IOreoSwapRouter public router;
    address public pair;

    uint256 public swapThreshold = _totalSupply * 1 / 5000;
    uint256 public usdcThreshold = 20 * 10 ** _decimals;

    bool private inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor() Auth(msg.sender) {
        router = IOreoSwapRouter(0x38eEd6a71A4ddA9d7f776946e3cfa4ec43781AE6);
        WETH = router.WETH();
        USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        pair = IOreoSwapFactory(router.factory()).createPair(WETH, address(this));

        setAutomatedMarketMakerPair(pair, true);

        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;

        feeReceiver = msg.sender;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply - _balances[DEAD] - _balances[ZERO]; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
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

    function transfer(address _recipient, uint256 _amount) public virtual override returns (bool) {
        return _transferFrom(msg.sender, _recipient, _amount);
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool) {
        require(_allowances[_sender][msg.sender] >= _amount, "Insufficient Allowance");

        if(_allowances[_sender][msg.sender] != type(uint256).max){
            _allowances[_sender][msg.sender] -= _amount;
        }

        return _transferFrom(_sender, _recipient, _amount);
    }

    function _transferFrom(address _sender, address _recipient, uint256 _amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(_sender, _recipient, _amount); }

        if(shouldSwapBack()) { swapBack(); }

        uint256 amountReceived = _amount;

        bool isTransfer = !automatedMarketMakerPairs[_sender] && !automatedMarketMakerPairs[_recipient];
        bool feeExempt = isFeeExempt[_sender] || isFeeExempt[_recipient];

        if(!isTransfer && !feeExempt) {
            amountReceived = takeFee(_sender, _amount);
        }

        _balances[_sender] -= _amount;
        _balances[_recipient] += amountReceived;

        if(address(playerManager) != address(0)) {
            try playerManager.updatePlayerStatus(_sender, _balances[_sender] < getUsdcThreshold()) {} catch {}
            try playerManager.updatePlayerStatus(_recipient, _balances[_recipient] >= getUsdcThreshold()) {} catch {}
        }

        emit Transfer(_sender, _recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address _sender, address _recipient, uint256 _amount) internal returns (bool) {
        _balances[_sender] -= _amount;
        _balances[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
        return true;
    }

    function takeFee(address sender, uint256 _amount) internal returns (uint256){
        uint256 feeAmount = (_amount * feePercentage) / feeDenominator;

        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        return _amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
        !automatedMarketMakerPairs[msg.sender]
        && !inSwap
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _balances[address(this)],
            0,
            path,
            feeReceiver,
            block.timestamp
        );
    }

    function rescueERC20(address _tokenAddress) external onlyOwner returns (bool) {
        ERC20 recoverableToken = ERC20(_tokenAddress);
        return recoverableToken.transfer(msg.sender, recoverableToken.balanceOf(address(this)));
    }

    function clearStuckBalance() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setIsFeeExempt(address _holder, bool _exempt) external onlyOwner {
        require(isFeeExempt[_holder] != _exempt, "Fee exempt status can't be set to same as current status");

        isFeeExempt[_holder] = _exempt;

        emit SetFeeExempt(_holder, _exempt);
    }

    function setFeePercentage(uint256 _feePercentage) external onlyOwner {
        require(_feePercentage <= maxFeePercentage, "Buy fee cannot be more than 5%");

        feePercentage = _feePercentage;

        emit SetFeePercentage(_feePercentage);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Zero Address validation" );

        feeReceiver = _feeReceiver;

        emit SetFeeReceiver(_feeReceiver);
    }

    function setSwapThreshold(uint256 _threshold) external onlyOwner {
        require (_threshold > 0, "Can't set swap threshold to 0");

        swapThreshold = _threshold;

        emit SetSwapBackThreshold(_threshold);
    }

    function setUsdcOgibThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 1, "USDC to OGIB threshold can't be less than $1");

        usdcThreshold = _threshold * 10 ** _decimals;

        emit SetUsdcOgibThreshold(_threshold);
    }

    function setPlayerManagerContract(address _playerManager) external onlyOwner {
        require (address(playerManager) != _playerManager, "Can't set OGIC contract to same address");

        playerManager = IPlayerManager(_playerManager);

        emit SetPlayerManagerContract(_playerManager);
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(automatedMarketMakerPairs[_pair] != _value, "Value already set");

        automatedMarketMakerPairs[_pair] = _value;

        if(_value){
            marketPairs.push(_pair);
        }else{
            require(marketPairs.length > 1, "Required 1 pair");
            for (uint256 i = 0; i < marketPairs.length; i++) {
                if (marketPairs[i] == _pair) {
                    marketPairs[i] = marketPairs[marketPairs.length - 1];
                    marketPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function getOgibToUsdcPrice() public view returns (uint256) {
        uint256 ogibAmount = 1 * 10 ** _decimals;

        // Get the price of ETH in OGIB
        address[] memory path = new address[](3);
        path[0] = USDC;
        path[1] = WETH;
        path[2] = address(this);
        uint256[] memory amounts = router.getAmountsOut(ogibAmount, path);
        uint256 ogibForOneUSDC = amounts[2];

        // Compute the OGIB/USDC price
        return ogibForOneUSDC;
    }

    function getUsdcThreshold() public view returns (uint256) {
        uint256 ogibUsdcPrice = getOgibToUsdcPrice();
        uint256 ogibAmount = usdcThreshold;
        return ogibAmount * ogibUsdcPrice;
    }
}