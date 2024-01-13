// SPDX-License-Identifier: MIT

/*

    Website: https://8192.site/
    Telegram: https://t.me/arb8192
    Twitter: https://twitter.com/arb8192


          .----------------.  .----------------.  .----------------.  .----------------. 
         | .--------------. || .--------------. || .--------------. || .--------------. |
         | |     ____     | || |     __       | || |    ______    | || |    _____     | |
         | |   .' __ '.   | || |    /  |      | || |  .' ____ '.  | || |   / ___ `.   | |
         | |   | (__) |   | || |    `| |      | || |  | (____) |  | || |  |_/___) |   | |
         | |   .`____'.   | || |     | |      | || |  '_.____. |  | || |   .'____.'   | |
         | |  | (____) |  | || |    _| |_     | || |  | \____| |  | || |  / /____     | |
         | |  `.______.'  | || |   |_____|    | || |   \______,'  | || |  |_______|   | |
         | |              | || |              | || |              | || |              | |
         | '--------------' || '--------------' || '--------------' || '--------------' |
          '----------------'  '----------------'  '----------------'  '----------------' 


    8192 supply and no decimals. Deflationary mechanics.
    A single token cannot be split into parts. On 8192, you can only transact integers.

    A unique trading experience with extremely limited supply and 3 different burn mechanisms:
    - 5% Sell tax, including 4% burn
    - LP burn on every 4/8/16/32 sells, if LP balance is > 4096/2048/1024/512, take 1 token as burn tax no matter the amount being sold

*/

pragma solidity 0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
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

        _beforeTokenTransfer(sender, recipient, amount);

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

        _afterTokenTransfer(sender, recipient, amount);
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract arb8192 is ERC20, Ownable {
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public constant deadAddress = address(0xdead);

    bool private isSwapping;

    address private treasuryWallet;

    uint256 public maxTransactionAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxSwapTokens;

    uint256 public lpBurnFrequency = 8 hours;
    uint256 public lastLpBurnTime;

    bool public limitsInEffect = true;
    bool public tradingActive = false;

    uint256 private launchedAt;

    uint256 public buyTotalFees;
    uint256 public buyTreasuryFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellTreasuryFee;
    uint256 public sellBurnFee;

    uint256 public sellCounter;
    uint256 public sellAmountCounter;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(uint256 => uint256) private swapInBlock;
    mapping(address => bool) public _isExcludedMaxTransactionAmount;

    mapping(address => bool) public automatedMarketMakerPairs;

    event AutoNukeLP();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event MarketingWalletUpdated(
        address indexed newWallet,
        address indexed oldWallet
    );

    constructor() ERC20("8192", "8192", 0) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );

        excludeFromMaxTransaction(address(_uniswapV2Router), true);
        uniswapV2Router = _uniswapV2Router;

        uint256 _buyTreasuryFee = 0;
        uint256 _buyBurnFee = 0;

        uint256 _sellTreasuryFee = 1;
        uint256 _sellBurnFee = 4;

        buyTreasuryFee = _buyTreasuryFee;
        buyBurnFee = _buyBurnFee;
        buyTotalFees = buyTreasuryFee + buyBurnFee;

        sellTreasuryFee = _sellTreasuryFee;
        sellBurnFee = _sellBurnFee;
        sellTotalFees = sellTreasuryFee + sellBurnFee;

        uint256 totalSupply = 8192;

        maxTransactionAmount = 164; // 2%
        swapTokensAtAmount = 2;
        maxSwapTokens = 32;

        treasuryWallet = msg.sender;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(address(0xdead), true);

        _mint(msg.sender, totalSupply);
    }

    receive() external payable {}

    function setPair(address pairAddress) external onlyOwner {
        uniswapV2Pair = pairAddress;
        excludeFromMaxTransaction(address(uniswapV2Pair), true);
        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
    }

    function enableTrading() external onlyOwner {
        tradingActive = true;
        launchedAt = block.number;
    }

    function removeLimits() external onlyOwner returns (bool) {
        limitsInEffect = false;
        return true;
    }

    function wlContract(address _whitelist, bool isWL) public onlyOwner {
        _isExcludedMaxTransactionAmount[_whitelist] = isWL;
        _isExcludedFromFees[_whitelist] = isWL;
    }

    function excludeFromMaxTransaction(
        address excludedAddress,
        bool isExcluded
    ) public onlyOwner {
        _isExcludedMaxTransactionAmount[excludedAddress] = isExcluded;
    }

    function updateSwapTokensAtAmount(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(newAmount >= 1 && newAmount <= 128);
        swapTokensAtAmount = newAmount;
        return true;
    }

    function updateMaxSwapTokens(
        uint256 newAmount
    ) external onlyOwner returns (bool) {
        require(newAmount >= 1 && newAmount <= 128);
        maxSwapTokens = newAmount;
        return true;
    }

    function updateBuyFees(
        uint256 _treasuryFee,
        uint256 _burnFee
    ) external onlyOwner {
        buyTreasuryFee = _treasuryFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyTreasuryFee + buyBurnFee;
        require(buyTotalFees <= 20);
    }

    function updateSellFees(
        uint256 _treasuryFee,
        uint256 _burnFee
    ) external onlyOwner {
        sellTreasuryFee = _treasuryFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellTreasuryFee + sellBurnFee;
        require(sellTotalFees <= 32);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) public onlyOwner {
        require(
            pair != uniswapV2Pair,
            "The pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateMarketingWallet(
        address newMarketingWallet
    ) external onlyOwner {
        emit MarketingWalletUpdated(newMarketingWallet, treasuryWallet);
        treasuryWallet = newMarketingWallet;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 blockNumber = block.number;

        if (limitsInEffect) {
            if (
                from != owner() &&
                to != owner() &&
                to != address(0) &&
                to != address(0xdead) &&
                !isSwapping
            ) {
                if (!tradingActive) {
                    require(
                        _isExcludedFromFees[from] || _isExcludedFromFees[to],
                        "Trading is not active."
                    );
                }

                if (
                    automatedMarketMakerPairs[from] &&
                    !_isExcludedMaxTransactionAmount[to]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Buy transfer amount exceeds the maxTransactionAmount."
                    );
                    require(
                        amount + balanceOf(to) <= maxTransactionAmount,
                        "Max wallet exceeded"
                    );
                }
                else if (
                    automatedMarketMakerPairs[to] &&
                    !_isExcludedMaxTransactionAmount[from]
                ) {
                    require(
                        amount <= maxTransactionAmount,
                        "Sell transfer amount exceeds the maxTransactionAmount."
                    );
                } else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(
                        amount + balanceOf(to) <= maxTransactionAmount,
                        "Max wallet exceeded"
                    );
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            !isSwapping &&
            (swapInBlock[blockNumber] <= 2) &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            isSwapping = true;

            swapBack();

            ++swapInBlock[blockNumber];

            isSwapping = false;
        }

        if (
            !isSwapping &&
            automatedMarketMakerPairs[to] &&
            !_isExcludedFromFees[from]
        ) {
            autoBurnLiquidityPairTokens();
        }

        bool takeFee = !isSwapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        uint256 toTreasury = 0;
        uint256 toBurn = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        // cause there are no decimals, fees will be taken only on txs of 50 tokens and more
        if (takeFee) {
            // on sell
            if (automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = (amount * sellTotalFees) / 100;
                toBurn = (fees * sellBurnFee) / sellTotalFees;
                toTreasury = fees - toBurn;

                // on every 4/8/16/32 sells, if LP balance is > 4096/2048/1024/512, take 1 token as burn tax no matter the amount being sold
                // will be triggered only if burn amount from fees is 0 for the current trade and the trade is taxable
                sellCounter++;
                uint256 lpBalance = balanceOf(uniswapV2Pair);
                if (toBurn == 0) {
                    if (
                        (lpBalance > 4096 && sellCounter >= 4) ||
                        (lpBalance > 2048 && sellCounter >= 8) ||
                        (lpBalance > 1024 && sellCounter >= 16) ||
                        (lpBalance > 512 && sellCounter >= 32)
                    ) {
                        sellCounter = 0;
                        toBurn = 1;
                        fees += 1;
                    }
                }

                sellAmountCounter += amount;
            }
            // on buy
            else if (buyTotalFees > 0 && automatedMarketMakerPairs[from]) {
                fees = (amount * buyTotalFees) / 100;
                toBurn = (fees * buyBurnFee) / buyTotalFees;
                toTreasury = fees - toBurn;
            }

            if (toTreasury > 0) {
                super._transfer(from, address(this), toTreasury);
            }

            if (toBurn > 0) {
                super._transfer(from, address(0xdead), toBurn);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        bool success;

        if (contractBalance == 0) {
            return;
        }

        if (contractBalance > maxSwapTokens) {
            contractBalance = maxSwapTokens;
        }

        uint256 amountToSwapForETH = contractBalance;

        swapTokensForEth(amountToSwapForETH);

        (success, ) = address(treasuryWallet).call{
            value: address(this).balance
        }("");
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function autoBurnLiquidityPairTokens() internal {
        uint256 liquidityPairBalance = balanceOf(uniswapV2Pair);

        if (liquidityPairBalance > 256) {
            if (sellAmountCounter < 1024) {
                if (block.timestamp < lastLpBurnTime + lpBurnFrequency) {
                    return;
                } else {
                    lastLpBurnTime = block.timestamp;
                }
            } else {
                sellAmountCounter = 0;
            }

            super._transfer(uniswapV2Pair, address(0xdead), 1);

            IUniswapV2Pair pair = IUniswapV2Pair(uniswapV2Pair);
            pair.sync();
            emit AutoNukeLP();
        }
    }
}