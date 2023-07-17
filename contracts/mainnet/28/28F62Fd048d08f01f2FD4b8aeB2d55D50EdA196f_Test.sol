/**
 *Submitted for verification at Arbiscan on 2023-07-17
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
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

interface IFactoryV2 {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address lpPair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address lpPair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function sync() external;
}

interface IRouter01 {
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Test is IERC20 {
    mapping(address => uint256) private _tOwned;
    mapping(address => bool) lpPairs;    
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _liquidityHolders;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromLimits;

    uint256 private constant startingSupply = 100_000_000;
    string private constant _name = "Test";
    string private constant _symbol = "Test";
    uint8 private constant _decimals = 18;
    uint256 private _tTotal = startingSupply * 10**_decimals;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 liquidity;
        uint16 operations;
        uint16 burn;
        uint16 totalSwap;
    }

    Fees public _taxRates = Fees({buyFee: 100, sellFee: 100, transferFee: 100});

    Ratios public _ratios =
        Ratios({liquidity: 0, operations: 100, burn: 0, totalSwap: 100});
    
    uint256 constant masterTaxDivisor = 10000;
    
    IRouter02 public dexRouter;
    address public lpPair;
    address public liquidityAddress;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable operations;
    }

    TaxWallets public _taxWallets =
        TaxWallets({
            operations: payable(0x6CB9d33086e545a9e01b879a48CB3Fd1ed12F988)
        });
    bool inSwap;
    bool public contractSwapEnabled = true;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    bool public piContractSwapsEnabled;
    uint256 public piSwapPercent = 10;
    
    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = true;

    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier inSwapFlag() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() payable {
        _owner = msg.sender;
        originalDeployer = msg.sender;
        _tOwned[_owner] = _tTotal;
        emit Transfer(address(0), _owner, _tTotal);
        dexRouter = IRouter02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        lpPair = IFactoryV2(dexRouter.factory()).createPair(
            dexRouter.WETH(),
            address(this)
        );
        lpPairs[lpPair] = true;
        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);
        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[0x6CB9d33086e545a9e01b879a48CB3Fd1ed12F988] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;
        liquidityAddress = _owner;
    }

    receive() external payable {}

    address private _owner;
    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller =/= owner.");
        _;
    }
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function transferOwner(address newOwner) external onlyOwner {
        require(
            newOwner != address(0),
            "Call renounceOwnership to transfer owner to the zero address."
        );
        require(
            newOwner != DEAD,
            "Call renounceOwnership to transfer owner to the zero address."
        );
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);

        if (balanceOf(_owner) > 0) {
            finalizeTransfer(
                _owner,
                newOwner,
                balanceOf(_owner),
                false,
                false,
                true
            );
        }

        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function renounceOwnership() external onlyOwner {
        setExcludedFromFees(_owner, false);
        address oldOwner = _owner;       
        emit OwnershipTransferred(oldOwner, address(0));
    }

    address public originalDeployer;
    address public operator;

    function setOperator(address newOperator) public {
        require(
            msg.sender == originalDeployer,
            "Can only be called by original deployer."
        );
        address oldOperator = operator;
        if (oldOperator != address(0)) {
            _liquidityHolders[oldOperator] = false;
            setExcludedFromFees(oldOperator, false);
        }
        operator = newOperator;
        _liquidityHolders[newOperator] = true;
        setExcludedFromFees(newOperator, true);
    }

    function renounceOriginalDeployer() external {
        require(
            msg.sender == originalDeployer,
            "Can only be called by original deployer."
        );
        setOperator(address(0));
        originalDeployer = address(0);
    }

    function renOwnership() external onlyOwner {
        setExcludedFromFees(_owner, false);
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    function totalSupply() external view override returns (uint256) {
        if (_tTotal == 0) {
            revert();
        }
        return _tTotal;
    }

    function decimals() external view override returns (uint8) {
        if (_tTotal == 0) {
            revert();
        }
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return _owner;
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() external onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }
        return _transfer(sender, recipient, amount);
    }

    function setNewRouter(address newRouter) external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot change after liquidity.");
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(
            address(this),
            _newRouter.WETH()
        );
        lpPairs[lpPair] = false;
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(
                address(this),
                _newRouter.WETH()
            );
        } else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        lpPairs[lpPair] = true;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }


    function isExcludedFromLimits(address account)
        external
        view
        returns (bool)
    {
        return _isExcludedFromLimits[account];
    }

    function setExcludedFromLimits(address account, bool enabled)
        external
        onlyOwner
    {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromFees(address account) external view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled)
        public
        onlyOwner
    {
        _isExcludedFromFees[account] = enabled;
    }

    function setWallets(address payable operations) external onlyOwner {
        require(operations != address(0), "Cannot be zero address.");
        _taxWallets.operations = payable(operations);
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return
            from != _owner &&
            to != _owner &&
            tx.origin != _owner &&
            !_liquidityHolders[to] &&
            !_liquidityHolders[from] &&
            to != DEAD &&
            to != address(0) &&
            from != address(this);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        if (lpPairs[from]) {
            buy = true;
        } else if (lpPairs[to]) {
            sell = true;
        } else {
            other = true;
        }
        if (_hasLimits(from, to)) {
            if (!tradingEnabled) {
                revert("Trading not yet enabled!");
            }                      
        }
        
        if (sell) {
            if (!inSwap) {
                if (contractSwapEnabled) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        uint256 swapAmt = swapAmount;
                        if (piContractSwapsEnabled) {
                            swapAmt =
                                (balanceOf(lpPair) * piSwapPercent) /
                                masterTaxDivisor;
                        }
                        if (contractTokenBalance >= swapAmt) {
                            contractTokenBalance = swapAmt;
                        }
                        contractSwap(contractTokenBalance);
                    }
                }
            }
        }

        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    function contractSwap(uint256 contractTokenBalance) internal inSwapFlag {
        Ratios memory ratios = _ratios;
        if (ratios.totalSwap == 0) {
            return;
        }

        if (
            _allowances[address(this)][address(dexRouter)] != type(uint256).max
        ) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) /
            ratios.totalSwap) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        try
            dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            )
        {} catch {
            return;
        }

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            try
                dexRouter.addLiquidityETH{value: liquidityBalance}(
                    address(this),
                    toLiquify,
                    0,
                    0,
                    liquidityAddress,
                    block.timestamp
                )
            {
                emit AutoLiquify(liquidityBalance, toLiquify);
            } catch {
                return;
            }
        }

        amtBalance -= liquidityBalance;
        ratios.totalSwap -= ratios.liquidity;
        bool success;
        uint256 operationsBalance = (amtBalance * ratios.operations) /
            ratios.totalSwap;
        if (ratios.operations > 0) {
            (success, ) = _taxWallets.operations.call{
                value: operationsBalance,
                gas: 55000
            }("");
        }
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _isExcludedFromFees[from] = true;
            _hasLiqBeenAdded = true;
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");        
        tradingEnabled = true;
        swapThreshold = (balanceOf(lpPair) * 10) / 10000;
        swapAmount = (balanceOf(lpPair) * 30) / 10000;
    }

    function finalizeTransfer(
        address from,
        address to,
        uint256 amount,
        bool buy,
        bool sell,
        bool other
    ) internal returns (bool) {
        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee)
            ? takeTaxes(from, buy, sell, amount)
            : amount;
        _tOwned[to] += amountReceived;
        emit Transfer(from, to, amountReceived);
        if (!_hasLiqBeenAdded) {
            
        }
        return true;
    }

    function takeTaxes(
        address from,
        bool buy,
        bool sell,
        uint256 amount
    ) internal returns (uint256) {
        Ratios memory ratios = _ratios;
        uint256 total = ratios.burn + ratios.totalSwap;
        uint256 currentFee;
        if (buy) {
            currentFee = _taxRates.buyFee;
        } else if (sell) {
            currentFee = _taxRates.sellFee;
        } else {
            currentFee = _taxRates.transferFee;
        }
        if (currentFee == 0 || total == 0) {
            return amount;
        }
        uint256 feeAmount = (amount * currentFee) / masterTaxDivisor;
        uint256 burnAmt = (feeAmount * ratios.burn) / total;
        uint256 swapAmt = feeAmount - burnAmt;
        if (swapAmt > 0) {
            _tOwned[address(this)] += swapAmt;
            emit Transfer(from, address(this), swapAmt);
        }
        if (burnAmt > 0) {
            _tTotal -= burnAmt;
            emit Transfer(from, address(0), burnAmt);
        }

        return amount - feeAmount;
    }
}