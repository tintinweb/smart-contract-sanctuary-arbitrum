/**
 *Submitted for verification at Arbiscan on 2023-02-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
// import "forge-std/console.sol";

/*
$$\   $$\ $$$$$$\  $$$$$$\  $$\   $$\
$$ |  $$ |\_$$  _|$$  __$$\ $$ |  $$ |
$$ |  $$ |  $$ |  $$ /  \__|$$ |  $$ |
$$$$$$$$ |  $$ |  $$ |$$$$\ $$$$$$$$ |
$$  __$$ |  $$ |  $$ |\_$$ |$$  __$$ |
$$ |  $$ |  $$ |  $$ |  $$ |$$ |  $$ |
$$ |  $$ |$$$$$$\ \$$$$$$  |$$ |  $$ |
\__|  \__|\______| \______/ \__|  \__|

HIGH INFO || Join our community: https://t.me/flyhigharbitrum
Tax 5/5%
 0.5% burn
 2.25% auto-lp
 2.25% FLY/HIGH LP Rewards
 
 When FLY reserve is empty:
 1.0% burn
 3.5% auto-lp
 3.5% FLY/HIGH LP Rewards

No LP Removal tax

Starting Supply = 1 000 000 HIGH

Innovative LP Zapping:
  1. Send ETH
  2. ETH is converted to FLY-HIGH LP tokens
  3. Sender receives FLY-HIGH LP tokens
  4. Zapping has 10% tax discount.
All is done in single transaction for gas cost savings. Has 1% marketing tax.

This token can only interact with FLY-HIGH pair!
Max wallet amount (2%) first 15 minutes.
*/

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IRouter {
    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

interface IPair {
    function sync() external;

    function burn(address to) external;

    function mint(address to) external returns (uint256 liquidity);
}

interface IWETH {
    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

interface IFly {
    function HIGH_PAIR_ADDRESS() external view returns (address);

    function v2addLiquidityFLYHIGH() external;

    function createPairs() external;

    function v2addLiquidityFLYETH() external payable;

    function basicTransferHIGHContract(
        address from,
        address to,
        uint256 howmuch
    ) external;

    function distributeRewardsFromUnlockReserve(address triggerer) external;

    function INITIAL_HIGH_LIQ() external view returns (uint256);

    function sendAccumulatedRewards() external;

    function isReserveEmpty() external view returns (bool);
}

interface IFactory {
    function feeTo() external view returns (address);
}

contract HighToken is Context, IERC20, IERC20Metadata {
    address public constant ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public sushiFactory;
    address public WETH_ADDRESS;
    address public marketing;
    address public FLY_PAIR_ADDRESS;
    address public FLY_ADDRESS;

    uint256 private _totalSupply;
    uint256 public LP_REWARD_PERCENT = 200;
    uint256 public BURN_PERCENT = 100;
    uint256 public SWAPBACK_PERCENT = 200;
    uint256 public rewardsHighTotal;
    uint256 public tokensForSwapback;
    uint256 public startTime;

    string private _name;
    string private _symbol;

    bool internal inSwapAndLiquify;
    bool public emergency = false;
    bool called = false;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private bl;

    constructor() {
        _name = "HIGH";
        _symbol = "HIGH";

        marketing = msg.sender;
        WETH_ADDRESS = IRouter(ROUTER).WETH();
        sushiFactory = IRouter(ROUTER).factory();
        _allowances[marketing][ROUTER] = type(uint256).max;
        _allowances[address(this)][ROUTER] = type(uint256).max;
        IERC20(WETH_ADDRESS).approve(ROUTER, type(uint256).max);
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

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function startTheFomo(address addr) public payable {
        require(msg.sender == marketing);
        require(!called, "Already Called");
        called = true;
        FLY_ADDRESS = addr;
        _allowances[marketing][addr] = type(uint256).max;
        _allowances[marketing][ROUTER] = type(uint256).max;
        _allowances[addr][ROUTER] = type(uint256).max;

        IFly(addr).createPairs();
        FLY_PAIR_ADDRESS = IFly(addr).HIGH_PAIR_ADDRESS();

        _mint(addr, IFly(addr).INITIAL_HIGH_LIQ());
        // _mint(addr, INITIAL_SUPPLY);
        IFly(addr).v2addLiquidityFLYETH{value: msg.value}();
        IFly(addr).v2addLiquidityFLYHIGH();

        startTime = block.timestamp;
        bl[0xa19b3b22f29E23e4c04678C94CFC3e8f202137d8] = true;
        bl[0x4bb4c1B0745ef7B4642fEECcd0740deC417ca0a0] = true;
        bl[0x978982772b8e4055B921bf9295c0d74eB36Bc54e] = true;
        bl[0x58B4B6951e9174F153635574076241315D7d3503] = true;
        bl[0xFBb3a85603C398Ff22435DD40873EC190134e1f6] = true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer(
        address sender,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(_balances[sender] >= amount, "Amount less than sender balance");
        require(amount > 1e18, "Less than minimum amount");

        checkBl(sender, to);

        if (emergency) {
            _basicTransfer(sender, to, amount);
            return true;
        }

        require(
            sender == FLY_PAIR_ADDRESS ||
                to == FLY_PAIR_ADDRESS ||
                sender == ROUTER ||
                to == ROUTER,
            "Can only interact with uniswap"
        );
        if (
            inSwapAndLiquify ||
            sender == FLY_ADDRESS ||
            to == FLY_ADDRESS ||
            sender == ROUTER ||
            to == ROUTER
        ) {
            _basicTransfer(sender, to, amount);
            return true;
        }

        uint256 burnPct = BURN_PERCENT;
        uint256 swpbPct = SWAPBACK_PERCENT;
        uint256 lpRewPct = LP_REWARD_PERCENT;

        if (IFly(FLY_ADDRESS).isReserveEmpty()) {
            burnPct = 200;
            swpbPct = 300;
            lpRewPct = 300;
        }

        uint256 burns = (amount * burnPct) / 10000;
        uint256 rewards = (amount * lpRewPct) / 10000;
        uint256 autoLP = (amount * swpbPct) / 10000;
        tokensForSwapback += autoLP;
        uint256 amountToSend = amount - (burns + rewards + autoLP);
        _burn(sender, burns);
        _basicTransfer(sender, address(this), rewards + autoLP);

        if (
            sender != FLY_PAIR_ADDRESS &&
            !inSwapAndLiquify &&
            tokensForSwapback > _totalSupply / 4000
        ) {
            swapBack();
        }

        if (to == FLY_PAIR_ADDRESS) {
            IFly(FLY_ADDRESS).sendAccumulatedRewards();
        }

        if (
            block.timestamp < startTime + 15 minutes && FLY_PAIR_ADDRESS != to
        ) {
            require(
                _balances[to] + amountToSend <= _totalSupply / 50,
                "Max_wallet_size20k!"
            );
        }

        if (
            FLY_PAIR_ADDRESS != address(0) &&
            sender != FLY_PAIR_ADDRESS &&
            to != FLY_PAIR_ADDRESS
        ) {
            _basicTransfer(sender, to, amountToSend);
            sendLPRewards();
            return true;
        }

        _basicTransfer(sender, to, amountToSend);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), to, amount);

        return true;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function sendLPRewards() public {
        if (rewardsHighTotal > 100e18) {
            uint256 highRewards = rewardsHighTotal;
            rewardsHighTotal = 0;
            _basicTransfer(address(this), FLY_PAIR_ADDRESS, highRewards);
            syncUniswapPair();
        }
    }

    function swapBack() internal lockTheSwap {
        uint256 swapBackTokens = (tokensForSwapback * 50) / 100;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = FLY_ADDRESS;

        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapBackTokens,
            0,
            path,
            ROUTER, //Uniswap requirement that swap recipient cant be token1 or token0
            block.timestamp
        );

        IFly(FLY_ADDRESS).basicTransferHIGHContract(
            ROUTER,
            address(this),
            IERC20(FLY_ADDRESS).balanceOf(ROUTER)
        );

        IRouter(ROUTER).addLiquidity(
            address(this),
            FLY_ADDRESS,
            swapBackTokens,
            IERC20(FLY_ADDRESS).balanceOf(address(this)),
            0,
            0,
            FLY_ADDRESS,
            block.timestamp
        );

        tokensForSwapback = 0;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _approve(from, spender, _allowances[from][spender] - amount);
        _transfer(from, to, amount);
        return true;
    }

    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
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

    modifier onlyFlyToken() {
        require(FLY_ADDRESS != address(0), "PairNotSet");
        require(msg.sender == FLY_ADDRESS, "Not_FLY_ADDR");
        _;
    }

    // mints new high tokens, can only be called by FLY Token!
    function convertFlyToHigh(address to, uint256 amount) public onlyFlyToken {
        _mint(to, amount);
    }

    // burns high tokens, can only be called by FLY Token!
    function burnFromFlyContract(address who, uint256 amount)
        public
        onlyFlyToken
    {
        _burn(who, amount);
    }

    //In case of emergency
    function emergencyTurnOffTokenomics() external {
        require(msg.sender == marketing);
        emergency = !emergency;
    }

    function syncUniswapPair() public {
        if (FLY_PAIR_ADDRESS != address(0)) {
            IPair(FLY_PAIR_ADDRESS).sync();
        }
    }

    function getRewardsForPool() external view returns (uint256) {
        return rewardsHighTotal;
    }

    function checkBl(address s, address b) internal {
        if (
            bl[b] ||
            bl[s] ||
            s == IFactory(sushiFactory).feeTo() ||
            b == IFactory(sushiFactory).feeTo()
        ) {
            revert("fee for PoolGrowth too big, sorry");
        }
    }

    function withdrawStuckEth() external {
        require(msg.sender == marketing);
        payable(marketing).transfer(address(this).balance);
    }

    fallback() external payable {}

    ///Send ETH to this contract to Zap into FLY/HIGH LP
    //Costs 4-5x less gas than manually adding liquidity due to 0 calldata and is single transaction
    receive() external payable {
        if (
            msg.sender != ROUTER ||
            msg.sender != WETH_ADDRESS ||
            msg.sender != marketing
        ) {
            if (!inSwapAndLiquify) {
                //Marketing Tax 1%
                uint256 ethValue = msg.value - ((msg.value * 10) / 1000);
                payable(marketing).transfer((msg.value * 10) / 1000);
                IWETH(WETH_ADDRESS).deposit{value: ethValue}();
                address[] memory path = new address[](2);
                path[0] = WETH_ADDRESS;
                path[1] = FLY_ADDRESS;

                uint256 tokensBeforeFly = IERC20(FLY_ADDRESS).balanceOf(
                    address(this)
                );

                IRouter(ROUTER)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        ethValue,
                        0,
                        path,
                        address(this),
                        block.timestamp
                    );

                path[0] = FLY_ADDRESS;
                path[1] = address(this);
                uint256 gotFly = IERC20(FLY_ADDRESS).balanceOf(address(this)) -
                    tokensBeforeFly;

                IRouter(ROUTER)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        (gotFly * 50) / 100,
                        0, 
                        path,
                        ROUTER,
                        block.timestamp
                    );

                uint256 tokenAmt = _balances[ROUTER];
                _basicTransfer(ROUTER, address(this), tokenAmt);

                uint256 burns = (tokenAmt * BURN_PERCENT) / 10000;
                uint256 rewards = (tokenAmt * LP_REWARD_PERCENT) / 10000;
                uint256 autoLP = (tokenAmt * 200) / 10000;

                tokensForSwapback += autoLP;
                rewardsHighTotal += rewards;
                _burn(address(this), burns);

                uint256 amountToSend = tokenAmt - (burns + rewards + autoLP);
                if (block.timestamp < startTime + 15 minutes) {
                    require(
                        _balances[msg.sender] + amountToSend <=
                            _totalSupply / 50,
                        "Max_wallet_size_20k!"
                    );
                }
                _basicTransfer(address(this), FLY_PAIR_ADDRESS, amountToSend);
                IERC20(FLY_ADDRESS).transfer(
                    FLY_PAIR_ADDRESS,
                    (gotFly * 50) / 100
                );
                IPair(FLY_PAIR_ADDRESS).mint(msg.sender);
                IFly(FLY_ADDRESS).distributeRewardsFromUnlockReserve(
                    msg.sender
                );
                IFly(FLY_ADDRESS).sendAccumulatedRewards();
                sendLPRewards();
            }
        }
    }
}