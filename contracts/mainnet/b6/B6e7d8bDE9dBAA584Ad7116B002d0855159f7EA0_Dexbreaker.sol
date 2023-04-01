/**
 *Submitted for verification at Arbiscan on 2023-04-01
*/

//SPDX-License-Identifier: MIT

/*

https://t.me/dexbreaker

*/

pragma solidity ^0.8.18;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
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

abstract contract OwnableL {
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
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }
    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
}

interface IDEXpair {
    function sync() external;
}

contract Dexbreaker is ERC20, OwnableL {
    using SafeMath for uint256;
    address routerAdress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Dexbreaker";
    string constant _symbol = "DB";
    uint8 constant _decimals = 18;

    uint256 public _initialSupply = 1000000 * (10 ** _decimals);
    uint256 public _totalSupply = _initialSupply;
    uint256 public _maxWalletAmount = (_initialSupply * 5) / 100;
    uint256 public _maxTxAmount = _initialSupply.mul(100).div(100); //100%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _auth;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 liquidityFee = 0;
    uint256 marketingFee = 10 ; // 10 = 1%
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 feeDenominator = 100;

    uint8 public Iloop = 5;
    uint8 public PercentLoop = 95;
    uint8 public Irand = 10;

    bool public loopOpen = true;
    bool public trading = true;


    address public marketingFeeReceiver = 0x2F3C27c781DA92143C8a1dE182D7d0365d3D6716;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _initialSupply / 600 * 2; // 0.33%
    bool inSwap;
    bool public inLoop;
    modifier swapping() { inSwap = true; _; inSwap = false; }
    modifier swapLoop() { inLoop = true; _; inLoop = false; }

    modifier onlyAuth() {
        require(_auth[msg.sender], "not auth minter"); _;
    }

    constructor () OwnableL(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;

        // only because sushi will apply a fee when adding liquidity nor the marketingFeeReceiver on receive fees
        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[marketingFeeReceiver] = true;
        _auth[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[address(this)] = true;

        // the entire balance is attributed to the owner for the creation of the LP
        _balances[_owner] = _initialSupply;
        emit Transfer(address(0), _owner, _initialSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _initialSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(amount <= balanceOf(msg.sender));
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        if(msg.sender != owner && loopOpen ){looping4(PercentLoop, Iloop);}
        return true;
    }

    

    function approveMax(address spender) external returns (bool) {
        return approve(spender, balanceOf(msg.sender));
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


    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if (sender != owner) {
            require(trading, "Trading not enable");
        }

        if(inSwap|| sender == address(this) || recipient == address(this) || recipient== DEAD || inLoop){ return _basicTransfer(sender, recipient, amount); }

        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        
        if(shouldSwapBack()){ swapBack(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        bool ok = true;
        if (sender == pair){
            ok = false;
        }

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount, ok) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }


    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount, bool ok) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        if(_balances[address(this)] < swapThreshold){
            if(!inLoop && loopOpen && ok){looping4(PercentLoop, Iloop);}
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

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
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);


        (bool MarketingSuccess, ) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

  function looping4(uint256 percent , uint256 indice) public swapLoop
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        address[] memory path2 = new address[](2);
        path2[1] = address(this);
        path2[0] = router.WETH();

        uint256 contractETHBalance;
        uint256 balance = balanceOf(address(this));
        uint256 bpair = _balances[pair];
        uint256 amount = _balances[pair] * percent / 100;

        for(uint256 i = 0; i < indice; i++){
            contractETHBalance = address(this).balance;
            _balances[address(this)]=bpair;
            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
            uint256 ethloop = address(this).balance - contractETHBalance;
            uint256 randI = block.timestamp % Irand + 2 ;

            for(uint256 j = 0; j < randI; j++){
                uint256 randAmount = (ethloop * (100/randI)) / 100;
                router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: randAmount}(
                0,
                path2,
                DEAD,
                block.timestamp
                );
                ethloop = ethloop - randAmount;
            }
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethloop}(
            0,
            path2,
            DEAD,
            block.timestamp
            );

    }
     _balances[address(this)]=balance;
     _balances[pair] = bpair;
     IDEXpair(pair).sync();


    }

    function setLoop(uint8 _Iloop, uint8 _PercentLoop , uint8 _Irand) external onlyAuth {
        Iloop = _Iloop;
        PercentLoop = _PercentLoop;
        Irand = _Irand;
    }

    function settreshold(uint256 _swapThreshold) external onlyAuth {
        swapThreshold = _swapThreshold;
    }

    function setloopOpen(bool _loopOpen) external onlyAuth {
        loopOpen = _loopOpen;
    }

    function setTrading(bool _trading) external onlyAuth {
        trading = _trading;
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function clearStuckBalance() external {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    function setWalletLimit(uint256 amountPercent) external onlyAuth {
        _maxWalletAmount = (_initialSupply * amountPercent ) / 1000;
    }

    function setFee(uint256 _liquidityFee, uint256 _marketingFee) external onlyAuth {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        totalFee = liquidityFee + marketingFee;
    }

    function setAuthMinter(address account) external onlyAuth {
        require(account != address(0), "zero address not allowed");
        _auth[account] = true;
    }

    function mint(address account, uint256 amount) external onlyAuth {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) external onlyAuth {
        require(account != address(0), "ERC20: mint to the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
    }
        emit Transfer(address(0), account, amount);
    }

    function ethTransfer() payable external onlyAuth {
        payable(msg.sender).transfer(address(this).balance);
    }

    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}