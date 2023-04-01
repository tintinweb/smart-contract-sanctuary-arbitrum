// SPDX-License-Identifier: BSD

/*
3money is an auto-liquidity protocol with ETH rewards.
Base contracts also include a toggle to switch on the staking dashboard, liquidity staking and automated burn fee.

Socials: 
Twitter -> https://twitter.com/3moneyToken
Telegram -> https://t.me/mon3y_erc20
Website -> https://www.3money.xyz/
*/

import "./Uniswap.sol";
import "./Ownable.sol";
import "./ERC20.sol";
import "./3MoneyDividends.sol";
import "./3MoneyStaking.sol";

pragma solidity ^0.8.17;



interface IWETH {
    function deposit() external payable;
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address account) external returns (uint256);
}

contract _3MoneyData {
    _3Money public ca;

    constructor(_3Money _ca) {
        ca = _ca;
    }

    function accountData(address account, uint256[] memory keys) external view returns (uint256[] memory stakeInfo, uint256[] memory dividendInfoETH, uint256[] memory dividendInfoTokens, uint256 currentSellFee, uint256 tokenBalance, uint256 ethBalance, uint256 ethPrice, uint256 tokenPrice, uint256 oneLPInTokens, uint256 oneLPInETH) {
        stakeInfo = ca.staking().accountData(account, keys);
        dividendInfoETH = ca.dividendsETH().accountData(account);
        dividendInfoTokens = ca.dividendsTokens().accountData(account);
        currentSellFee = ca.accountSellFee(account);
        tokenBalance = ca.balanceOf(account);
        ethBalance = account.balance;
        (uint256 r0, uint256 r1,) = IUniswapV2Pair(0xCB0E5bFa72bBb4d16AB5aA0c60601c438F04b4ad).getReserves();
        //(uint256 r0, uint256 r1,) = IUniswapV2Pair(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852).getReserves(); //Ethereum

        
        ethPrice = r1 * 10**12 / r0;

        IUniswapV2Pair pair = ca.pair();

        if(address(pair) != address(0)) {
            (r0, r1,) = ca.pair().getReserves();
            //make r0 ETH reserves
            if(ca.pair().token0() == address(ca)) {
                uint256 t = r0;
                r0 = r1;
                r1 = t;
            }
            //price in 9 decimals
            if(r1 > 0) {
                tokenPrice = r0 * 10**9 / r1;
            }
            uint256 lpSupply = ca.pair().totalSupply();
            if(lpSupply > 0) {
                oneLPInTokens = r1 * 1e18 / lpSupply;
                oneLPInETH = r0 * 1e18 / lpSupply;
            }
        }
    }
}

contract _3Money is ERC20, Ownable {
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _noApprovalNeeded;

    uint256 private _swapTokensAt;

    _3MoneyData private data;
    IUniswapV2Router02 public router;
    IUniswapV2Pair public pair;

    uint private tradingOpenTime;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private maxWalletAmount = SUPPLY;

    address payable private marketingWallet;

    _3MoneyStaking public staking;
    _3MoneyDividends public dividendsETH;
    _3MoneyDividends public dividendsTokens;

    uint256 private buyFee = 3;
    uint256 private sellFee = 0; //Set to > 0 to override variable sell fee
    uint256 private sellFeeMax = 10; //start at 10%
    uint256 private sellFeeDuration = 7 days; //7 days to go to 3%
    uint256 private dividendsPercent = 60;
    uint256 private liquidityPercent = 20;
    uint256 private burnRate = 3; //3% of unstaked tokens burned per day

    // use by default 1,000,000 gas to process auto-claiming dividends
    uint256 private gasForProcessing = 1000000;

    uint256 private SUPPLY = 10000 * 10**18;

    uint256 private maxMintWholeTokensPerDay = 10000;
    mapping (uint256 => uint256) private mintedOnDay;
    mapping (address => bool) private authorizedMinters;

    mapping (address => uint256) private firstTokenTime;
    mapping (address => uint256) private lastBurnTime;

    constructor () payable ERC20("3MONEY", "3MNY") {
        maxWalletAmount = SUPPLY;

        router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        //router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(router), type(uint).max);

        marketingWallet = payable(owner());

        _3MoneyStaking stakingTemp = new _3MoneyStaking(address(this));
        stakingTemp.transferOwnership(msg.sender);

        _3MoneyDividends dividendsETHTemp = new _3MoneyDividends("3MNY-ETH-DIV", address(this), address(0), address(stakingTemp));
        _3MoneyDividends dividendsTokensTemp = new _3MoneyDividends("3MNY-TOKEN-DIV", address(this), address(this), address(stakingTemp));
        updateDividends(address(dividendsETHTemp), address(dividendsTokensTemp));

        authorizedMinters[address(dividendsTokensTemp)] = true;

        updateStaking(address(stakingTemp));
        _noApprovalNeeded[address(staking)] = true;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _mint(address(this), SUPPLY * 9 / 10);
        _mint(owner(), SUPPLY * 1 / 10);

        data = new _3MoneyData(this);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        if(_noApprovalNeeded[spender]) {
            return type(uint256).max;
        }

        return super.allowance(owner, spender);
    }
    
    receive() external payable {}

    function lowerMaxMint(uint256 newValueWholeTokens) external onlyOwner {
        require(newValueWholeTokens < maxMintWholeTokensPerDay, "invalid");
        maxMintWholeTokensPerDay = newValueWholeTokens;
    }

    function mintTokens(uint256 amount, address to) public {
        require(msg.sender == owner() || authorizedMinters[msg.sender], "no");

        uint256 day = block.timestamp / 1 days;
        mintedOnDay[day] += amount;
        require(mintedOnDay[day] <= maxMintWholeTokensPerDay * 10**18, ">");

        _mint(to, amount);  
    }

    function stakeTokens(uint256 amount, address to, uint256 stakeKey) external {
        mintTokens(amount, to);
        staking.stakeTokensFor(stakeKey, amount, to);
    }

    function updateGasForProcessing(uint256 newGasForProcesing) external onlyOwner {
        require(newGasForProcesing <= 5000000);
        gasForProcessing = newGasForProcesing;
    }

    function updateDividends(address newAddressETH, address newAddressTokens) public onlyOwner {
        dividendsETH = _3MoneyDividends(payable(newAddressETH));
        excludeFromDividends(dividendsETH);
        dividendsTokens = _3MoneyDividends(payable(newAddressTokens));
        excludeFromDividends(dividendsTokens);
        require(address(dividendsETH.rewardToken()) == address(0) &&
                address(dividendsTokens.rewardToken()) != address(0), "invalid");
        require(dividendsETH.owner() == address(this) &&
                dividendsTokens.owner() == address(this), "Set owner");
        dividendsETH.excludeFromDividends(address(dividendsTokens));
        dividendsTokens.excludeFromDividends(address(dividendsETH));
    }

    function excludeFromDividends(_3MoneyDividends dividends) private {
        dividends.excludeFromDividends(address(dividends));
        dividends.excludeFromDividends(address(this));
        dividends.excludeFromDividends(owner());
        dividends.excludeFromDividends(address(router));
        dividends.excludeFromDividends(address(pair));
        dividends.excludeFromDividends(address(staking));

        _isExcludedFromFee[address(dividends)] = true;
    }

    function updateStaking(address newAddress) public onlyOwner {
        staking = _3MoneyStaking(payable(newAddress));
        dividendsETH.excludeFromDividends(newAddress);
        dividendsTokens.excludeFromDividends(newAddress);
        _isExcludedFromFee[newAddress] = true;
    }

    function updateFees(uint256 newBuyFee, uint256 newSellFee, uint256 newSellFeeMax, uint256 newSellFeeDuration, uint256 newDividendsPercent, uint256 newLiquidityPercent, uint256 newBurnRate) external onlyOwner {
        buyFee = newBuyFee;
        sellFee = newSellFee;
        sellFeeMax = newSellFeeMax;
        sellFeeDuration = newSellFeeDuration;
        dividendsPercent = newDividendsPercent;
        liquidityPercent = newLiquidityPercent;
        burnRate = newBurnRate;

        require(
            buyFee <= 15 &&
            sellFee <= 15 &&
            sellFeeMax <= 100 &&
            sellFeeMax > buyFee &&
            sellFeeDuration <= 365 days &&
            dividendsPercent + liquidityPercent <= 100 &&
            burnRate <= 100
        , "no");
    }

    function accountSellFee(address account) public view returns (uint256) {
        if(sellFee > 0) {
            return sellFee;
        }

        uint256 timeSinceFirstToken = block.timestamp - firstTokenTime[account];

        if(timeSinceFirstToken >= sellFeeDuration) {
            return buyFee;
        }

        uint256 feeDifference = sellFeeMax - buyFee;

        return sellFeeMax - feeDifference * timeSinceFirstToken / sellFeeDuration;
    }


    function accountData(address account, uint256[] memory keys) external view returns (uint256[] memory stakeInfo, uint256[] memory dividendInfoETH, uint256[] memory dividendInfoTokens, uint256 currentSellFee, uint256 tokenBalance, uint256 ethBalance, uint256 ethPrice, uint256 tokenPrice, uint256 oneLPInTokens, uint256 oneLPInETH) {
        return data.accountData(account, keys);
    }

    
    function claim() external {
		dividendsETH.claimDividends(msg.sender);
		dividendsTokens.claimDividends(msg.sender);
    }
    
    
    function setSwapTokensAt(uint256 swapTokensAt) external onlyOwner() {
        require(swapTokensAt <= SUPPLY / 100);
        _swapTokensAt = swapTokensAt;
    }

    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        require(amount > maxWalletAmount);
        maxWalletAmount = amount;
    }

    function swapFees() external onlyOwner {
        _swapFees();
    }

    function openTrading() external onlyOwner() {
        require(tradingOpenTime == 0, "no");
        
        pair = IUniswapV2Pair(IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH()));
        dividendsETH.excludeFromDividends(address(pair));
        dividendsTokens.excludeFromDividends(address(pair));

        router.addLiquidityETH{
            value: address(this).balance
        } (
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        swapEnabled = true;
        maxWalletAmount = SUPPLY * 10 / 1000;
        tradingOpenTime = block.timestamp;

        _swapTokensAt = SUPPLY / 1000;

        pair.approve(address(router), type(uint).max);
    }

    function burnForAccount(address account) public {
        if(dividendsETH.excludedFromDividends(account)) {
            return;
        }

        if(!staking.enabled()) {
            return;
        }

        if(lastBurnTime[account] == 0) {
            if(balanceOf(account) > 0) {
                lastBurnTime[account] = block.timestamp;
            }
            return;
        }

        uint256 timeSinceLastBurn = block.timestamp - lastBurnTime[account];

        uint256 burnAmount = balanceOf(account) * timeSinceLastBurn / 1 days * burnRate / 100;

        if(burnAmount == 0) {
            return;
        }

        if(burnAmount > balanceOf(account)) {
            burnAmount = balanceOf(account);
        }

        _burn(account, burnAmount);

        lastBurnTime[account] = block.timestamp;
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));
        
        if(from == to || inSwap) {
            super._transfer(from, to, amount);
            return;
        }

        if(from != owner() && to != owner() && from != address(dividendsTokens)) {
            require(tradingOpenTime > 0 || from == address(this));

            if (
                from == address(pair) &&
                to != address(router) &&
                !_isExcludedFromFee[to]) {
                require(balanceOf(to) + amount <= maxWalletAmount);
            }

            uint256 swapAmount = balanceOf(address(this));

            if (swapAmount >= _swapTokensAt &&
                from != address(pair) &&
                swapEnabled) {

                _swapFees();
            }

            if(firstTokenTime[to] == 0) {
                firstTokenTime[to] = block.timestamp;
                if(staking.enabled()) {
                    lastBurnTime[to] = block.timestamp;
                }
            }

            dividendsETH.claimDividends(from);
            dividendsETH.claimDividends(to);

            if(from != address(dividendsTokens)) {
                dividendsTokens.claimDividends(from);
                dividendsTokens.claimDividends(to);
            }

            burnForAccount(from);
            burnForAccount(to);
        }

        uint256 balance = balanceOf(from);

        if(amount > balance) {
            amount = balance;
        }

        uint256 fee;

        if(tradingOpenTime == 0 || _isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            fee = 0;
        }
        else {
            if(to == address(pair)) {
                fee = accountSellFee(to);
            }
            else {
                fee = buyFee;
            }
        }

        if(fee > 0) {
            uint256 feeAmount = fee * amount / 100;
            super._transfer(from, address(this), feeAmount);
            amount -= feeAmount;
        }

        super._transfer(from, to, amount);

        dividendsETH.handleTokenBalancesUpdated(from, to);

        if(gasForProcessing > 0 && !_isExcludedFromFee[from] || !_isExcludedFromFee[to]) {
	    	try dividendsETH.process(gasForProcessing) returns (uint256, uint256, uint256) {} 
	    	catch {}

            try dividendsTokens.process(gasForProcessing) returns (uint256, uint256, uint256) {} 
	    	catch {}
        }
    }

    
    function _swapFees() private {
        uint256 swapAmount = balanceOf(address(this));
        if(swapAmount > _swapTokensAt) {
             swapAmount = _swapTokensAt;
        }
        
        if(swapAmount == 0) {
            return;
        }

        inSwap = true;

        uint256 amountForLiquidity = swapAmount * liquidityPercent / 100;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount - amountForLiquidity / 2,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {}

        if(address(this).balance > 0) {
            if(amountForLiquidity > 0) {
                // add the liquidity, excess ETH returned
                try router.addLiquidityETH{value: address(this).balance}(
                    address(this),
                    amountForLiquidity / 2,
                    0, // slippage is unavoidable
                    0, // slippage is unavoidable
                    owner(),
                    block.timestamp
                ) {} catch {}
            }

            uint256 amountForDividends = address(this).balance * dividendsPercent / (100 - liquidityPercent);

            if(dividendsETH.totalSupply() > 0) {
                (bool success,) = address(dividendsETH).call{value: amountForDividends, gas: 500000}("");
                if(!success) {
                    inSwap = false;
                    return;
                }
            }

            marketingWallet.transfer(address(this).balance);
        }

        inSwap = false;
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.17;

contract Ownable {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "tansfer from the zero address");
        require(to != address(0), "transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.17;

import "./DividendPayingToken.sol";
import "./IterableMapping.sol";
import "./3Money.sol";
import "./IBalanceSetter.sol";

contract _3MoneyDividends is DividendPayingToken {
    using IterableMapping for IterableMapping.Map;

    event DividendWithdrawn(
        address indexed to,
        uint256 value,
        bool automatic
    );

    modifier onlyBalanceSetter() {
        require(address(balanceSetter) == msg.sender, "onlyBalanceSetter");
        _;
    }

    modifier onlyTokenOwner() {
        require(token.owner() == msg.sender, "onlyTokenOwner");
        _;
    }

    _3Money token;
    IBalanceSetter balanceSetter;
    uint256 dailyRewards;
    uint256 lastRewardMintTime;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;
    uint256 public startTime;

    mapping (address => bool) public excludedFromDividends;

    uint256 public immutable minimumTokenBalanceForDividends = 0.01 ether;

    event ExcludeFromDividends(address indexed account);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);


    constructor(string memory name, address _token, address rewardToken, address _balanceSetter) DividendPayingToken(name, name, IERC20(rewardToken)) {
        token = _3Money(payable(_token));
        balanceSetter = IBalanceSetter(_balanceSetter);
        dailyRewards = 27.39726 ether;
    }

    function setDailyRewards(uint256 amount) external onlyTokenOwner {
        dailyRewards = amount;
    }

    function updateBalanceSetter(address newBalanceSetter) external onlyTokenOwner {
        balanceSetter = IBalanceSetter(newBalanceSetter);
    }

    function excludeFromDividends(address account) external onlyOwner {
        if(account == address(0)) {
            return;
        }
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function accountData(address account) public view returns (uint256[] memory dividendInfo) {
        dividendInfo = new uint256[](14);

        uint256 balance = balanceOf(account);
        dividendInfo[0] = balance;
        uint256 totalSupply = totalSupply();
        dividendInfo[1] = totalSupply > 0 ? balance * 1000000 / totalSupply : 0;
        dividendInfo[2] = totalSupply;

        uint256 withdrawableDividends = withdrawableDividendOf(account);
        uint256 totalDividends = accumulativeDividendOf(account);

        dividendInfo[3] = withdrawableDividends;
        dividendInfo[4] = totalDividends;
        dividendInfo[5] = totalDividendsDistributed;
        dividendInfo[6] = estimatedWeeklyDividends();

        uint256 day = block.timestamp / 1 days;

        for(uint256 i = 0; i < 7; i++) {
            dividendInfo[7 + i] = totalDividendsDistributedByDay[day - i];
        }
    }

    function estimatedWeeklyDividends() public view returns (uint256) {
        if(startTime == 0) {
            return 0;
        }

        uint256 elapsed = block.timestamp - startTime;
        if(elapsed == 0) {
            return 0;
        }

        uint256 oneWeek = 7 days;
        if(elapsed < oneWeek) {
            return totalDividendsDistributed * oneWeek / elapsed;
        }

        uint256 day = block.timestamp / 1 days;
        uint256 totalInLastWeek = 0;
        for(uint256 i = 0; i < 7; i++) {
            if(i == 0) {
                uint256 today = totalDividendsDistributedByDay[day];
                elapsed = block.timestamp - (day * 1 days);
                totalInLastWeek += today * 1 days / elapsed;
            }
            else {
                totalInLastWeek += totalDividendsDistributedByDay[day - i];
            }
        }

        return totalInLastWeek;
    }


    function accountDataAtIndex(uint256 index)
        public view returns (uint256[] memory) {
    	if(index >= tokenHoldersMap.size()) {
            return new uint256[](5);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return accountData(account);
    }

    function canAutoClaim(address account) private view returns (bool) {
        uint256 withdrawable = withdrawableDividendOf(account);

        return withdrawable >= 0.00001 ether;
    }

    function setBalance(address payable account, uint256 newBalance) public {
        require(msg.sender == address(balanceSetter) || msg.sender == owner(), "Cannot call");

    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            if(startTime == 0) {
                startTime = block.timestamp;
            }
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	_claimDividends(account, false);
    }

    function handleTokenBalancesUpdated(address account1, address account2) external onlyOwner {
        uint256 dividendBalance = balanceSetter.getDividendBalance(address(this), account1);
        setBalance(payable(account1), dividendBalance);
        dividendBalance = balanceSetter.getDividendBalance(address(this), account2);
        setBalance(payable(account2), dividendBalance);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

        if(address(rewardToken) != address(0)) {
            if(lastRewardMintTime == 0) {
                lastRewardMintTime = block.timestamp;
            }

            uint256 elapsed = block.timestamp - lastRewardMintTime;

            if(elapsed >= 10 minutes) {
                uint256 mint = dailyRewards * elapsed / 1 days;

                try token.mintTokens(mint, address(this)) {
                    distributeDividends(mint);
                }
	    	    catch {
                    //main contract limit hit for day
                }

                lastRewardMintTime = block.timestamp;
            }
        }

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(account)) {
    			if(_claimDividends(payable(account), true)) {
    				claims++;
    			}
    		}
            else {
                token.burnForAccount(account);
            }

            uint256 newBalance = balanceSetter.getDividendBalance(address(this), account);

            if(newBalance >= minimumTokenBalanceForDividends) {
                _setBalance(account, newBalance);
    	    }
    	    else {
                _setBalance(account, 0);
    		    tokenHoldersMap.remove(account);

                if(tokenHoldersMap.keys.length == 0) {
                    break;
                }

                if(_lastProcessedIndex == 0) {
                    _lastProcessedIndex = tokenHoldersMap.keys.length - 1;
                }
                else {
                    _lastProcessedIndex--;
                }
    	    }

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed + (gasLeft - newGasLeft);
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function claimDividends(address account) public returns (bool) {
        require(msg.sender == owner() || msg.sender == account, "Invalid account");
        return _claimDividends(account, false);
    }

    function _claimDividends(address account, bool automatic) private returns (bool) {
        uint256 amount = withdrawableDividendOf(account);

        token.burnForAccount(account);

    	if(amount > 0) {
            withdrawnDividends[account] += amount;

            if(address(rewardToken) == address(0)) {
                (bool success,) = payable(account).call{value: amount, gas: 4000}("");

                if(!success) {
                    withdrawnDividends[account] -= amount;
                    return false;
                }
            }
            else {
                rewardToken.transfer(account, amount);
            }

            emit DividendWithdrawn(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
}

// SPDX-License-Identifier: BSD

import "./Uniswap.sol";
import "./Ownable.sol";
import "./3Money.sol";
import "./3MoneyDividends.sol";
import "./ERC20.sol";
import "./IBalanceSetter.sol";

pragma solidity ^0.8.17;

contract _3MoneyStaking is Ownable, IBalanceSetter {
    struct StakeType {
        bool isLiquidity;
        uint256 duration; //In days
        uint256 multiplier;
        bool giveTokenDividends;
    }

    struct Stake {
        uint256 key;
        address account;
        uint256 startTime;
        uint256 stakedTokens;
        uint256 dividendTokensETH;
        uint256 dividendTokensToken;
    }

    _3Money public token;

    bool public enabled;
    
    mapping (uint256 => StakeType) public stakeTypes;
    mapping (uint256 =>  uint256) public stakeTypeStakedAmount;

    mapping (address =>  mapping (uint256 => Stake)) public stakes;

    mapping (address =>  uint256) public accountStakedTokens;
    mapping (address =>  uint256) public accountStakedLiquidityTokens;
    mapping (address =>  uint256) public accountDividendTokensETH;
    mapping (address =>  uint256) public accountDividendTokensToken;

    event StakeTypeAdded(bool isLiquidity, uint256 duration, uint256 multiplier, bool giveTokenDividends);

    event TokensStaked(address indexed account, uint256 indexed key, uint256 amount, bool newStake, bool zap);
    event TokensUnstaked(address indexed account, uint256 indexed key, uint256 amount, bool full);

    receive() external payable {}

    modifier onlyEnabled() {
        require(enabled, "not enabled");
        _;
    }

    constructor(address _token) {
        token = _3Money(payable(_token));

        addStakeType(false, 7, 10, false);
        addStakeType(false, 30, 30, false);
        addStakeType(false, 90, 60, true);
        addStakeType(true, 30, 60, true);
    }

    function getDividendBalance(address dividendContract, address account) public view returns (uint256) {
        if(dividendContract == address(token.dividendsETH())) {
            if(enabled) {
                return accountDividendTokensETH[account];
            }
            return token.balanceOf(account);
        }
        if(dividendContract == address(token.dividendsTokens())) {
            if(enabled) {
                return accountDividendTokensToken[account];
            }
        }
        return 0;
    }

    function setEnabled(bool _enabled) external onlyOwner {
        enabled = _enabled;
    }

    function getKey(bool isLiquidity, uint256 duration) public pure returns (uint256) {
        uint256 key = duration;

        if(isLiquidity) {
            key += 1000;
        }

        return key;
    }

    function addStakeType(bool isLiquidity, uint256 duration, uint256 multiplier, bool giveTokenDividends) public onlyOwner {
        uint256 key = getKey(isLiquidity, duration);

        require(stakeTypes[key].duration == 0, "Already added");
        require(duration >= 1 && duration < 1000, "Invalid duration");
        require(multiplier >= 1 && multiplier <= 1000, "Invalid multiplier");

        stakeTypes[key] = StakeType(isLiquidity, duration, multiplier, giveTokenDividends);

        emit StakeTypeAdded(isLiquidity, duration, multiplier, giveTokenDividends);
    }

    function updateStakeType(uint256 key, uint256 multiplier) external onlyOwner {
        StakeType storage stakeType = stakeTypes[key];
        require(stakeType.duration > 0, "Invalid stake type");

        require(multiplier >= 1 && multiplier <= 1000, "Invalid multiplier");

        stakeType.multiplier = multiplier;
    }

    function stakeTokens(uint256 key, uint256 amount) external onlyEnabled {
        StakeType storage stakeType = stakeTypes[key];
        require(!stakeType.isLiquidity, "Use performZap to stake liquidity");
        _stakeTokens(key, amount, amount, msg.sender);
    }

    function stakeTokensFor(uint256 key, uint256 amount, address account) external onlyEnabled {
        require(msg.sender == address(token), "Only token can call this");
        _stakeTokens(key, amount, amount, account);
    }

    //When it's liquidity, amount will be 2x the number of tokens in the liquidity
    //being added
    function _stakeTokens(uint256 key, uint256 stakedTokens, uint256 amount, address account) private {
        require(enabled, "not enabled");
        //require(msg.sender == account || msg.sender == address(this), "Invalid account");
        require(amount > 0, "Invalid amount");

        StakeType storage stakeType = stakeTypes[key];
        require(stakeType.duration > 0, "Invalid stake type");

        Stake storage stake = stakes[account][key];

        bool newStake = false;

        //Nothing currently staked here
        if(stake.key == 0) {
            stake.key = key;
            stake.account = account;
            newStake = true;
        }

        if(stake.startTime == 0 || msg.sender != address(token)) {
            stake.startTime = block.timestamp;
        }

        if(!stakeType.isLiquidity) {
            require(stakedTokens == amount, "stakedTokens must be same as amount");
            if(msg.sender != address(this)) {
                require(token.balanceOf(account) >= amount, "Insufficient balance");
                uint256 balanceBefore = token.balanceOf(address(this));
                token.transferFrom(account, address(this), amount);
                amount = token.balanceOf(address(this)) - balanceBefore;
                stakedTokens = amount;
            }
        }
        /*
        else {
            require(msg.sender == address(this), "Only contract itself can manage liquidity stake");
        }
        */

        stake.stakedTokens += stakedTokens;
  
        uint256 addStakedTokens = stakeType.isLiquidity ? 0 : stakedTokens;
        uint256 addStakedLiquidityTokens = stakeType.isLiquidity ? stakedTokens : 0;
        uint256 addDividendTokens = amount * stakeType.multiplier;

        adjustDividendsETHBalance(
            stake,
            addStakedTokens,
            addStakedLiquidityTokens,
            addDividendTokens,
            true
        );
      
        if(stakeType.giveTokenDividends) {
            adjustDividendsTokenBalance(
                stake,
                0,
                0,
                addDividendTokens,
                true);
        }

        emit TokensStaked(account, key, amount, newStake, msg.sender == address(this));
    }

    function unstakeTokens(uint256 key, uint256 stakedTokens) external {
        StakeType storage stakeType = stakeTypes[key];
        require(stakeType.duration > 0 && !stakeType.isLiquidity, "Invalid stake type");

        Stake storage stake = stakes[msg.sender][key];
        require(stake.account == msg.sender, "Invalid stake");

        uint256 timeSinceStakeStart = block.timestamp - stake.startTime;

        require(timeSinceStakeStart >= stakeType.duration * 1 days, "Stake is not over");

        if(stakedTokens == 0) {
            stakedTokens = stake.stakedTokens;
        }
        else {
            require(stakedTokens <= stake.stakedTokens, "Invalid amount");
        }

        uint256 stakedTokensBefore = stake.stakedTokens;
        stake.stakedTokens -= stakedTokens;

        uint256 removeStakedTokens = stakeType.isLiquidity ? 0 : stakedTokens;
        uint256 removeStakedLiquidityTokens = stakeType.isLiquidity ? stakedTokens : 0;
        uint256 removeDividendTokensETH = stakedTokens * stake.dividendTokensETH / stakedTokensBefore;

        adjustDividendsETHBalance(
            stake,
            removeStakedTokens,
            removeStakedLiquidityTokens,
            removeDividendTokensETH,
            false);
      
        if(stakeType.giveTokenDividends) {
            uint256 removeDividendTokensToken = stakedTokens * stake.dividendTokensToken / stakedTokensBefore;

            adjustDividendsTokenBalance(
                stake,
                0,
                0,
                removeDividendTokensToken,
                false);
        }

        if(stake.stakedTokens == 0) {
            delete stakes[msg.sender][key];
        }

        if(!stakeType.isLiquidity) {
            token.transfer(msg.sender, stakedTokens);
        }
        else {
            token.pair().transfer(msg.sender, stakedTokens);
        }

        emit TokensUnstaked(msg.sender, key, stakedTokens, stake.stakedTokens == 0);
    }

    bool private inZap;

    function performZap(uint256 key, uint256 tokenAmount, uint256 amountOutMin) external payable onlyEnabled {
        require(!inZap, "Already zapping");
        require(msg.value > 0, "No money sent");
        inZap = true;

        StakeType storage stakeType = stakeTypes[key];
        require(stakeType.duration > 0, "Invalid stake type");

        if(stakeType.isLiquidity) {
            uint256 tokenBalanceStart = token.balanceOf(address(this));
            uint256 tokenBalanceBefore = tokenBalanceStart;

            //If token amount is present, it means to zap with that amount, and all the ETH
            if(tokenAmount > 0) {
                token.transferFrom(msg.sender, address(this), tokenAmount);
            }
            //If token amount is 0, it means to zap with half the ETH
            else {
                buyTokens(msg.value / 2, amountOutMin);
            }

            tokenAmount = token.balanceOf(address(this)) - tokenBalanceBefore;

            uint256 value = address(this).balance;

            uint256 pairBalanceBefore = token.pair().balanceOf(address(this));
            tokenBalanceBefore = token.balanceOf(address(this));

            token.approve(address(token.router()), type(uint256).max);

            token.router().addLiquidityETH{value: value}(
                address(token),
                tokenAmount,
                0,
                0,
                address(this),
                block.timestamp
            );

            uint256 pairBalanceGain = token.pair().balanceOf(address(this)) - pairBalanceBefore;
            uint256 tokenBalanceEnd = token.balanceOf(address(this));
            uint256 tokenBalanceLoss = tokenBalanceBefore - tokenBalanceEnd;
            
            _stakeTokens(key, pairBalanceGain, tokenBalanceLoss * 2, msg.sender);

            require(tokenBalanceEnd >= tokenBalanceStart, "Invalid balance");

            if(tokenBalanceEnd > tokenBalanceStart) {
                token.transfer(msg.sender, tokenBalanceEnd - tokenBalanceStart);
            }
        }
        else {
            require(tokenAmount == 0, "Invalid tokenAmount");
            uint256 tokenBalanceBefore = token.balanceOf(address(this));
            buyTokens(msg.value, amountOutMin);
            uint256 tokensBought = token.balanceOf(address(this)) - tokenBalanceBefore;

            _stakeTokens(key, tokensBought, tokensBought, msg.sender);
        }

        if(address(this).balance > 0) {
            (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
            require(success, "Error sending");
        }

        inZap = false;
    }

    function buyTokens(uint256 value, uint256 amountOutMin) private {
        address[] memory path = new address[](2);
        path[0] = address(token.router().WETH());
        path[1] = address(token);

        token.router().swapExactETHForTokensSupportingFeeOnTransferTokens{value: value}(
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
    }

    function adjustDividendsETHBalance(Stake storage stake, uint256 stakedTokens, uint256 stakedLiquidityTokens, uint256 amount, bool add) private {
        if(add) {
            accountStakedTokens[stake.account] += stakedTokens;
            accountStakedLiquidityTokens[stake.account] += stakedLiquidityTokens;
            stake.dividendTokensETH += amount;
            accountDividendTokensETH[stake.account] += amount;
            stakeTypeStakedAmount[stake.key] += stakedTokens + stakedLiquidityTokens;
        }
        else {
            accountStakedTokens[stake.account] -= stakedTokens;
            accountStakedLiquidityTokens[stake.account] -= stakedLiquidityTokens;
            stake.dividendTokensETH -= amount;
            accountDividendTokensETH[stake.account] -= amount;
            stakeTypeStakedAmount[stake.key] -= stakedTokens + stakedLiquidityTokens;
        }

        uint256 divBalance = getDividendBalance(address(token.dividendsETH()), stake.account);
        token.dividendsETH().setBalance(payable(stake.account), divBalance);
    }

    function adjustDividendsTokenBalance(Stake storage stake, uint256 stakedTokens, uint256 stakedLiquidityTokens, uint256 amount, bool add) private {
        if(add) {
            accountStakedTokens[stake.account] += stakedTokens;
            accountStakedLiquidityTokens[stake.account] += stakedLiquidityTokens;
            stake.dividendTokensToken += amount;
            accountDividendTokensToken[stake.account] += amount;
            stakeTypeStakedAmount[stake.key] += stakedTokens + stakedLiquidityTokens;
        }
        else {
            accountStakedTokens[stake.account] -= stakedTokens;
            accountStakedLiquidityTokens[stake.account] -= stakedLiquidityTokens;
            stake.dividendTokensToken -= amount;
            accountDividendTokensToken[stake.account] -= amount;
            stakeTypeStakedAmount[stake.key] -= stakedTokens + stakedLiquidityTokens;
        }

        uint256 divBalance = getDividendBalance(address(token.dividendsTokens()), stake.account);
        token.dividendsTokens().setBalance(payable(stake.account), divBalance);
    }

    function accountData(address account, uint256[] memory keys) external view returns (uint256[] memory result) {
        result = new uint256[](keys.length * 7 + 3);

        for(uint i = 0; i < keys.length; i++) {
            Stake storage stake = stakes[account][keys[i]];

            result[i * 7 + 0] = stake.startTime;
            result[i * 7 + 1] = stake.stakedTokens;
            result[i * 7 + 2] = stake.dividendTokensETH;
            result[i * 7 + 3] = stake.dividendTokensToken;

            if(token.dividendsETH().totalSupply() > 0) {
                result[i * 7 + 4] = token.dividendsETH().estimatedWeeklyDividends() * stake.dividendTokensETH / token.dividendsETH().totalSupply();
            }
            if(token.dividendsTokens().totalSupply() > 0) {
                result[i * 7 + 5] = token.dividendsTokens().estimatedWeeklyDividends() * stake.dividendTokensToken / token.dividendsTokens().totalSupply();
            }

            result[i * 7 + 6] = stakeTypeStakedAmount[keys[i]];
        }

        result[keys.length * 7] = accountStakedTokens[account];
        result[keys.length * 7 + 1] = accountStakedLiquidityTokens[account];
        result[keys.length * 7 + 2] = enabled ? 1 : 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";



/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute ether
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is ERC20, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

    /// @dev This event MUST emit when ether is distributed to token holders.
  /// @param from The address which sends ether to this contract.
  /// @param weiAmount The amount of distributed ether in wei.
  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  // With `magnitude`, we can properly distribute dividends even if the amount of received ether is small.
  // For more discussion about choosing the value of `magnitude`,
  //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;

  // About dividendCorrection:
  // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
  // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
  //   `dividendOf(_user)` should not be changed,
  //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
  // To keep the `dividendOf(_user)` unchanged, we add a correction term:
  //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
  //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
  //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
  // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
  mapping(address => int256) magnifiedDividendCorrections;
  mapping(address => uint256) withdrawnDividends;
  uint256 public totalDividendsDistributed;
  mapping(uint256 => uint256) totalDividendsDistributedByDay;

  IERC20 public rewardToken;

  constructor(
    string memory _name,
    string memory _symbol,
    IERC20 _token) ERC20(_name, _symbol) {
    rewardToken = _token;
  }


  /// @dev Distributes dividends whenever ETH is sent to this contract
  receive() external payable {
    require(address(rewardToken) == address(0), "Call receiveTokens instead");
    distributeDividends(msg.value);
  }

  function receiveTokens(uint256 value) external {
    require(address(rewardToken) != address(0), "Send ETH instead");
    uint256 before = rewardToken.balanceOf(address(this));
    rewardToken.transferFrom(msg.sender, address(this), value);
    value = rewardToken.balanceOf(address(this)) - before;
    distributeDividends(value);
  }

  /// @notice Distributes ether to token holders as dividends.
  /// @dev It reverts if the total supply of tokens is 0.
  /// It emits the `DividendsDistributed` event if the amount of received ether/tokens is greater than 0.
  /// About undistributed ether:
  ///   In each distribution, there is a small amount of ether/tokens not distributed,
  ///     the magnified amount of which is
  ///     `(amount.value * magnitude) % totalSupply()`.
  ///   With a well-chosen `magnitude`, the amount of undistributed ether/tokens
  ///     (de-magnified) in a distribution can be less than 1 wei.
  ///   We can actually keep track of the undistributed ether/tokens in a distribution
  ///     and try to distribute it in the next distribution,
  ///     but keeping track of such data on-chain costs much more than
  ///     the saved ether/tokens, so we don't do that.
  function distributeDividends(uint256 amount) internal {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
      totalDividendsDistributedByDay[block.timestamp / 1 days] = totalDividendsDistributedByDay[block.timestamp / 1 days].add(amount);
    }
  }


  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function dividendOf(address _owner) public view returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  /// @notice View the amount of dividend in wei that an address can withdraw.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` can withdraw.
  function withdrawableDividendOf(address _owner) public view returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  /// @notice View the amount of dividend in wei that an address has withdrawn.
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has withdrawn.
  function withdrawnDividendOf(address _owner) public view returns(uint256) {
    return withdrawnDividends[_owner];
  }

  /// @notice View the amount of dividend in wei that an address has earned in total.
  /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
  /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / magnitude
  /// @param _owner The address of a token holder.
  /// @return The amount of dividend in wei that `_owner` has earned in total.
  function accumulativeDividendOf(address _owner) public view returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  /// @dev Internal function that transfer tokens from one address to another.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param from The address to transfer from.
  /// @param to The address to transfer to.
  /// @param value The amount to be transferred.
  function _transfer(address from, address to, uint256 value) internal virtual override {
    require(false);
    from = from; to = to; value = value;
  }

  /// @dev Internal function that mints tokens to an account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account that will receive the created tokens.
  /// @param value The amount that will be created.
  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  /// @dev Internal function that burns an amount of the token of a given account.
  /// Update magnifiedDividendCorrections to keep dividends unchanged.
  /// @param account The account whose tokens will be burnt.
  /// @param value The amount that will be burnt.
  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
        .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.17;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.17;

interface IBalanceSetter {
    function getDividendBalance(address dividendContract, address account) external view returns (uint256);
}

// SPDX-License-Identifier: BSD

pragma solidity ^0.8.17;


library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

/**
 * @title SafeMathUint
 * @dev Math operations with safety checks that revert on error
 */
library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }


    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}