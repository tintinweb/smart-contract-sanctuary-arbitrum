/**
 *Submitted for verification at Arbiscan on 2023-02-06
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// import "forge-std/console.sol";

/*
 /$$$$$$$$ /$$   /$$     /$$
| $$_____/| $$  |  $$   /$$/
| $$      | $$   \  $$ /$$/
| $$$$$   | $$    \  $$$$/
| $$__/   | $$     \  $$/
| $$      | $$      | $$
| $$      | $$$$$$$$| $$
|__/      |________/|__/

FLY INFO || Join our community: https://t.me/flyhigharbitrum
Tax 5/5%
 0.5% burn
 1.5% auto-lp
 1.0% FLY/ETH LP Rewards
 2.0% FLY/HIGH LP Rewards

No LP Removal tax
No tax on FLY when interacting with FLY/HIGH pair

On Swap - 5% of the FLY amount is minted as HIGH 
 2.5% minted for you, 
 2.5% minted for FLY/HIGH LP Rewards

Starting Supply = 10 000 000 FLY
 70% of initial supply unlocked
 6 750 000 FLY / 1.5 ETH Starting Liquidity FLY/ETH
   250 000 FLY / 1 000 000 HIGH Starting Liquidity FLY/HIGH 

 30% of initial supply in "Locked Reserve"
   -0.5 FLY tokens unlock every second from the Locked Reserve
   -Unlocked FLY tokens are distributed as follows:
   -Burn (20%), FLY/ETH (24%), FLY/HIGH (56%) LP rewards

LP Rewards:
 1.Removes 2% of FLY/ETH and 4% FLY/HIGH LP tokens held by FLY contract every 3 hours
 2.Airdrops FLY+ETH as rewards to other FLY/ETH LPs
 3.Airdrops FLY+HIGH as rewards to other FLY/HIGH LPs

When FLY reserve is empty taxes are:
 0.5% burn
 1.0% auto-lp
 1.0% FLY/HIGH LP Rewards
 2.5% FLY/ETH LP Rewards
 3.0% Locked Reserve
 -- 8% Total
 2.0% FLY->HIGH mint ratio

Reserve is not empty again when it reaches at laest 2% of total supply.

Innovative LP Zapping:
  1. Send ETH
  2. ETH is converted to FLY-ETH LP tokens
  3. Sender receives FLY-ETH LP tokens
  4. Zapping has 5% tax discount
All is done in single transaction for gas cost savings. Has 1% marketing tax.

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

interface HighToken {
    function setFlyAddress(address n) external;

    function convertFlyToHigh(address to, uint256 howmuch) external;

    function burnFromFlyContract(address who, uint256 howmuch) external;

    function sendLPRewards() external;
}

interface IFactory {
    function feeTo() external view returns (address);
}

contract FlyToken is Context, IERC20, IERC20Metadata {
    // CONSTANTS
    address public FACTORY;
    address public constant ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public WETH_ADDRESS;
    address public marketing;
    address public HIGH_ADDRESS;
    address public ETH_PAIR_ADDRESS;
    address public HIGH_PAIR_ADDRESS;
    address public owner;

    uint256 internal constant FULL_SUPPLY = 10_000_000e18;
    uint256 internal INITIAL_UNLOCKED_RESERVE = (FULL_SUPPLY * 7000) / 10000;
    uint256 internal INITIAL_LOCKED_RESERVE = (FULL_SUPPLY * 3000) / 10000;
    uint256 internal INITIAL_LIQ_HIGH_PAIR = 250_000e18;
    uint256 public INITIAL_HIGH_LIQ = 1_000_000e18;

    //6.75M
    uint256 internal INITIAL_LIQ_ETH_PAIR =
        INITIAL_UNLOCKED_RESERVE - INITIAL_LIQ_HIGH_PAIR;

    /* Per Transaction */
    uint256 public BURN_PERCENT = 50; // 100=1%
    uint256 public SWAPBACK_PERCENT = 150;
    uint256 public ETH_LP_REWARD_PERCENT = 100;
    uint256 public HIGH_LP_REWARD_PERCENT = 200;
    uint256 public HIGH_MINT_PERCENT = 500;

    /* Unlock */
    uint256 public UNLOCK_TOKEN_AMOUNT = 1e18; // 1 FLY TOKEN
    uint256 public UNLOCK_REWARD_PERCENT = 8000;
    uint256 public UNLOCK_ETH_POOL_REWARD_PERCENT = 3000;
    uint256 public UNLOCK_HIGH_POOL_REWARD_PERCENT = 7000;

    /* VAR */
    uint256 private _totalSupply;

    uint256 public lockedReserveLeft = INITIAL_LOCKED_RESERVE;
    uint256 public lastRewardedStamp;
    uint256 public constant cooldown = 10 minutes;
    uint256 public startTime;
    uint256 public ethPairRewardTotal;
    uint256 public highPairRewardTotal;
    uint256 public totalHighToMintForPool;
    uint256 public tokensForSwapback;
    uint256 public lastRemoveLPStamp;
    bool internal inSwapAndLiquify;
    bool public emergency = false;
    bool public isReserveEmpty = false;

    string private _name;
    string private _symbol;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private bl;

    /* Events */
    event Burned(address indexed burnedFrom, uint256 amount);
    event RewardsDistributed(uint256 indexed blockStamp, uint256 amount);
    event AllUnlocked();
    event RewardToETHPair(
        uint256 indexed timestamp,
        uint256 wethAmt,
        uint256 flyAmt
    );
    event RewardToHighPair(
        uint256 indexed timestamp,
        uint256 highAmt,
        uint256 flyAmt
    );

    constructor(address highAddress) {
        _name = "FLY";
        _symbol = "FLY";

        HIGH_ADDRESS = highAddress;
        WETH_ADDRESS = IRouter(ROUTER).WETH();
        FACTORY = IRouter(ROUTER).factory();
        _mint(address(this), FULL_SUPPLY);
        _allowances[marketing][ROUTER] = type(uint256).max;
        _allowances[address(this)][ROUTER] = type(uint256).max;
        _allowances[highAddress][ROUTER] = type(uint256).max;
        IERC20(WETH_ADDRESS).approve(ROUTER, type(uint256).max);
        lastRewardedStamp = block.timestamp;
        marketing = msg.sender;
        owner = msg.sender;
        startTime = block.timestamp;
        bl[0xa19b3b22f29E23e4c04678C94CFC3e8f202137d8] = true;
        bl[0x4bb4c1B0745ef7B4642fEECcd0740deC417ca0a0] = true;
        bl[0x978982772b8e4055B921bf9295c0d74eB36Bc54e] = true;
        bl[0x58B4B6951e9174F153635574076241315D7d3503] = true;
        bl[0xFBb3a85603C398Ff22435DD40873EC190134e1f6] = true;
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

    function allowance(address _owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[_owner][spender];
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
        address _owner = _msgSender();
        _approve(owner, spender, _allowances[_owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address _owner = _msgSender();
        uint256 currentAllowance = _allowances[_owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function renounceOwnership() external {
        require(msg.sender == owner, "Not owner");
        owner = address(0);
    }

    function _transfer(
        address sender,
        address to,
        uint256 amount
    ) internal returns (bool) {
        require(amount > 1e18, "Less than minimum amount");
        require(_balances[sender] >= amount, "Amount less than sender balance");

        checkBl(sender, to);

        if (emergency) {
            _basicTransfer(sender, to, amount);
            return true;
        }

        if (
            inSwapAndLiquify ||
            sender == address(this) ||
            sender == HIGH_ADDRESS ||
            sender == HIGH_PAIR_ADDRESS ||
            sender == ROUTER ||
            to == address(this) ||
            to == HIGH_ADDRESS ||
            to == HIGH_PAIR_ADDRESS ||
            to == ROUTER
        ) {
            _basicTransfer(sender, to, amount);
            return true;
        }

        if (
            sender != ETH_PAIR_ADDRESS &&
            sender != HIGH_PAIR_ADDRESS &&
            to != HIGH_PAIR_ADDRESS &&
            !inSwapAndLiquify &&
            tokensForSwapback > _totalSupply / 4000
        ) {
            swapBack();
        }

        uint256 ethPairReward = (amount * ETH_LP_REWARD_PERCENT) / 10000;
        uint256 highPairReward = (amount * HIGH_LP_REWARD_PERCENT) / 10000;
        uint256 burns = (amount * BURN_PERCENT) / 10000;
        uint256 autoLP = (amount * SWAPBACK_PERCENT) / 10000;

        tokensForSwapback += autoLP;
        uint256 amountToSend;
        uint256 highMintAmount = (amount * HIGH_MINT_PERCENT) / 10000;

        totalHighToMintForPool += (highMintAmount * 50) / 100;
        ethPairRewardTotal += ethPairReward;
        highPairRewardTotal += highPairReward;
        _burn(sender, burns);
        _basicTransfer(
            sender,
            address(this),
            ethPairReward + highPairReward + autoLP
        );

        if (to == ETH_PAIR_ADDRESS || to == HIGH_PAIR_ADDRESS) {
            distributeRewardsFromUnlockReserve(sender);
            sendAccumulatedRewards();
        } else if (sender != HIGH_PAIR_ADDRESS) {
            HighToken(HIGH_ADDRESS).convertFlyToHigh(
                to,
                (highMintAmount * 50) / 100
            );
        }

        //When reserve gets eptied
        if (isReserveEmpty) {
            //Additional 3% tax
            uint256 forReserve = (amount * 300) / 10000;
            lockedReserveLeft += forReserve;
            amountToSend =
                amount -
                (autoLP + highPairReward + ethPairReward + burns + forReserve);
            _basicTransfer(sender, address(this), forReserve);
            //If reserve gets more than 2% of supply it gets unlocked again
            lastRewardedStamp = block.timestamp;
            isReserveEmpty = lockedReserveLeft < _totalSupply / 50;
        } else {
            //When reserve is not empty
            amountToSend =
                amount -
                (autoLP + highPairReward + ethPairReward + burns);
        }

        if (
            block.timestamp < startTime + 15 minutes &&
            ETH_PAIR_ADDRESS != to &&
            HIGH_PAIR_ADDRESS != to
        ) {
            require(
                _balances[to] + amountToSend <= _totalSupply / 50,
                "Max_wallet_size200k!"
            );
        }

        if (
            to != HIGH_PAIR_ADDRESS &&
            to != ETH_PAIR_ADDRESS &&
            ETH_PAIR_ADDRESS != address(0) &&
            HIGH_PAIR_ADDRESS != address(0) &&
            sender != address(this) &&
            sender != ETH_PAIR_ADDRESS &&
            sender != HIGH_PAIR_ADDRESS
        ) {
            if (ethPairRewardTotal > 5e18 && highPairRewardTotal > 10e18) {
                sendAccumulatedRewards();
            }

            if (
                sender != ROUTER
            ) {
                distributeRewardsFromUnlockReserve(sender);
            }

            _basicTransfer(sender, to, amountToSend);
            syncUniswapPairs();

            return true;
        }
        _basicTransfer(sender, to, amountToSend);

        return true;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function sendAccumulatedRewards() public {
        if (
            ethPairRewardTotal > 100e18 &&
            highPairRewardTotal > 100e18 &&
            totalHighToMintForPool > 100e18
        ) {
            uint256 rewardsForEth = ethPairRewardTotal;
            uint256 rewardsForHigh = highPairRewardTotal;
            uint256 mintForHigh = totalHighToMintForPool;
            ethPairRewardTotal = 0;
            highPairRewardTotal = 0;
            totalHighToMintForPool = 0;
            _basicTransfer(address(this), ETH_PAIR_ADDRESS, rewardsForEth);
            _basicTransfer(address(this), HIGH_PAIR_ADDRESS, rewardsForHigh);
            HighToken(HIGH_ADDRESS).convertFlyToHigh(
                HIGH_PAIR_ADDRESS,
                mintForHigh
            );
            syncUniswapPairs();
            emit RewardToETHPair(block.timestamp, 0, rewardsForEth);
            emit RewardToHighPair(block.timestamp, 0, rewardsForHigh);
        }
    }

    function swapBack() internal lockTheSwap {
        uint256 swapBackTokens = tokensForSwapback / 4;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH_ADDRESS;

        IRouter(ROUTER).swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapBackTokens,
            0,
            path,
            address(this),
            block.timestamp
        );

        IRouter(ROUTER).addLiquidityETH{value: address(this).balance}(
            address(this),
            swapBackTokens,
            0,
            0,
            address(this),
            block.timestamp
        );

        path[1] = HIGH_ADDRESS;

        IRouter(ROUTER).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapBackTokens,
            0,
            path,
            ROUTER,
            block.timestamp
        );

        uint256 burnAmt = IERC20(HIGH_ADDRESS).balanceOf(ROUTER);

        HighToken(HIGH_ADDRESS).burnFromFlyContract(ROUTER, burnAmt);

        HighToken(HIGH_ADDRESS).convertFlyToHigh(address(this), burnAmt);

        IRouter(ROUTER).addLiquidity(
            address(this),
            HIGH_ADDRESS,
            swapBackTokens,
            IERC20(HIGH_ADDRESS).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );

        tokensForSwapback = 0;

        if (block.timestamp > lastRemoveLPStamp + 3 hours) {
            removeLiqForAirdrop();
            removeLiqForAirdropHigh();
            lastRemoveLPStamp = block.timestamp;
        }
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
        address _owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    function distributeRewardsFromUnlockReserve(address triggerer) public {
        if (!isReserveEmpty && block.timestamp > lastRewardedStamp + cooldown) {
            uint256 blockStamp = block.timestamp;
            uint256 secondsSinceLastReward = blockStamp - lastRewardedStamp;

            //0.5 FLY every 1 sec
            uint256 totalTokensToUnlock = (secondsSinceLastReward *
                UNLOCK_TOKEN_AMOUNT) / 2;

            if (totalTokensToUnlock > lockedReserveLeft) {
                handleAllUnlocked();
            } else if (totalTokensToUnlock > 10e8) {
                //30% for FLY/ETH 70% for FLY/HIGH
                uint256 ethPoolRewards = (totalTokensToUnlock *
                    UNLOCK_ETH_POOL_REWARD_PERCENT) / 10000;

                uint256 highPoolRewards = (totalTokensToUnlock *
                    UNLOCK_HIGH_POOL_REWARD_PERCENT) / 10000;

                uint256 triggererRewards = ethPoolRewards / 20;

                _basicTransfer(
                    address(this),
                    ETH_PAIR_ADDRESS,
                    ethPoolRewards - triggererRewards
                );
                _basicTransfer(
                    address(this),
                    HIGH_PAIR_ADDRESS,
                    highPoolRewards
                );
                _basicTransfer(address(this), triggerer, triggererRewards);
                updateRewardState(blockStamp, totalTokensToUnlock);

                emit RewardToETHPair(
                    block.timestamp,
                    0,
                    ethPoolRewards - triggererRewards
                );
                emit RewardToHighPair(block.timestamp, 0, highPoolRewards);
            }
        }
    }

    function updateRewardState(uint256 blockStamp, uint256 totalTokensToUnlock)
        internal
    {
        lastRewardedStamp = blockStamp;
        lockedReserveLeft = lockedReserveLeft - totalTokensToUnlock;
        syncUniswapPairs();
    }

    //Sync Both Pairs
    function syncUniswapPairs() public {
        if (ETH_PAIR_ADDRESS != address(0)) {
            IPair(address(ETH_PAIR_ADDRESS)).sync();
        }
        if (HIGH_PAIR_ADDRESS != address(0)) {
            IPair(address(HIGH_PAIR_ADDRESS)).sync();
        }
    }

    function handleAllUnlocked() internal {
        emit AllUnlocked();
        isReserveEmpty = true;
        ETH_LP_REWARD_PERCENT = 250;
        HIGH_LP_REWARD_PERCENT = 100;
        SWAPBACK_PERCENT = 100;
        BURN_PERCENT = 50;
        HIGH_MINT_PERCENT = 200;
        lockedReserveLeft = 0;
    }

    function getFlyEthPairAddress() public view returns (address) {
        return ETH_PAIR_ADDRESS;
    }

    function getFlyHighPairAddress() public view returns (address) {
        return HIGH_PAIR_ADDRESS;
    }

    function getLPTokenBalance() public view returns (uint256) {
        return IERC20(ETH_PAIR_ADDRESS).balanceOf(address(this));
    }

    function createPairs() public {
        require(
            ETH_PAIR_ADDRESS == address(0) && HIGH_PAIR_ADDRESS == address(0),
            "already set"
        );

        ETH_PAIR_ADDRESS = IUniswapV2Factory(FACTORY).createPair(
            address(this),
            WETH_ADDRESS
        );

        HIGH_PAIR_ADDRESS = IUniswapV2Factory(FACTORY).createPair(
            address(this),
            HIGH_ADDRESS
        );
    }

    function v2addLiquidityFLYETH() public payable {
        require(msg.sender == HIGH_ADDRESS);
        lastRewardedStamp = block.timestamp;

        (, , uint256 gotLp) = IRouter(ROUTER).addLiquidityETH{value: msg.value}(
            address(this),
            INITIAL_LIQ_ETH_PAIR,
            0,
            0,
            address(this),
            block.timestamp
        );
        //Deployer keeps half of starting FLY/ETH lp for locking; other half goes for fomonomics
        IERC20(ETH_PAIR_ADDRESS).transfer(marketing, (gotLp * 50) / 100);
        startTime = block.timestamp;
    }

    function v2addLiquidityFLYHIGH() public {
        require(msg.sender == HIGH_ADDRESS);
        //Deployer keeps 10% of starting FLY/HIGH lp; other goes for fomonomics
        lastRewardedStamp = block.timestamp;

        (, , uint256 gotLp) = IRouter(ROUTER).addLiquidity(
            address(this),
            HIGH_ADDRESS,
            INITIAL_LIQ_HIGH_PAIR,
            INITIAL_HIGH_LIQ,
            0,
            0,
            address(this),
            block.timestamp
        );
        IERC20(HIGH_PAIR_ADDRESS).transfer(marketing, (gotLp * 10) / 100);
        startTime = block.timestamp;
    }

    //Starting protocol lp accures also rewards.
    //This mechanism redistributes the part of protocol lp to other lp's every 3 hours.
    function removeLiqForAirdrop() internal {
        uint256 currentLPTokens = (IERC20(ETH_PAIR_ADDRESS).balanceOf(
            address(this)
        ) * 20) / 1000;
        IERC20(ETH_PAIR_ADDRESS).approve(ROUTER, currentLPTokens);

        uint256 balanceBefore = balanceOf(address(this));
        uint256 wethBefore = IERC20(WETH_ADDRESS).balanceOf(address(this));

        IERC20(ETH_PAIR_ADDRESS).transfer(ETH_PAIR_ADDRESS, currentLPTokens);
        IPair(ETH_PAIR_ADDRESS).burn(address(this));

        uint256 balanceAfter = balanceOf(address(this));
        uint256 gotFly = balanceAfter - balanceBefore;
        uint256 gotWeth = IERC20(WETH_ADDRESS).balanceOf(address(this)) -
            wethBefore;

        //Start Marketing
        uint256 forMarketing = (gotWeth * 20) / 100;
        IERC20(WETH_ADDRESS).transfer(marketing, forMarketing);
        _basicTransfer(address(this), marketing, (gotFly * 20) / 100);
        //End Marketing

        //Rewards
        IERC20(WETH_ADDRESS).transfer(ETH_PAIR_ADDRESS, gotWeth - forMarketing);
        _basicTransfer(address(this), ETH_PAIR_ADDRESS, (gotFly * 80) / 100);
        emit RewardToETHPair(
            block.timestamp,
            gotWeth - forMarketing,
            (gotFly * 80) / 100
        );
        syncUniswapPairs();
    }

    //Starting protocol lp also accures rewards.
    //This mechanism redistributes part of protocol lp to other lp's every 3 hours. Also pays for marketing
    function removeLiqForAirdropHigh() internal {
        uint256 currentLPTokensHigh = (IERC20(HIGH_PAIR_ADDRESS).balanceOf(
            address(this)
        ) * 40) / 1000;
        uint256 flyBefore = balanceOf(address(this));
        uint256 highBefore = IERC20(HIGH_ADDRESS).balanceOf(address(this));

        IERC20(HIGH_PAIR_ADDRESS).transfer(
            HIGH_PAIR_ADDRESS,
            currentLPTokensHigh
        );
        IPair(HIGH_PAIR_ADDRESS).burn(address(this));

        uint256 flyGot = balanceOf(address(this)) - flyBefore;
        uint256 highGot = IERC20(HIGH_ADDRESS).balanceOf(address(this)) -
            highBefore;

        //Rewards
        IERC20(HIGH_ADDRESS).transfer(HIGH_PAIR_ADDRESS, highGot);
        _basicTransfer(address(this), HIGH_PAIR_ADDRESS, flyGot);
        emit RewardToETHPair(block.timestamp, highGot, flyGot);
        syncUniswapPairs();
    }

    //In case of emergency
    function emergencyTurnOffTokenomics() external {
        require(msg.sender == marketing);
        emergency = !emergency;
    }

    function withdrawStuckEth() external {
        require(msg.sender == marketing);
        payable(marketing).transfer(address(this).balance);
    }

    //Can only be called from HIGH contract
    function basicTransferHIGHContract(
        address from,
        address to,
        uint256 howmuch
    ) external {
        require(msg.sender == HIGH_ADDRESS, "Not_HIGH_ADDRESS");
        _basicTransfer(from, to, howmuch);
    }

    //Util getters
    function getLockedReserveLeft() external view returns (uint256) {
        return lockedReserveLeft / 1e18;
    }

    function getPendingRewardsFromUnlock() external view returns (uint256) {
        return
            ((block.timestamp - lastRewardedStamp) * UNLOCK_TOKEN_AMOUNT) / 2 /
            1e18;
    }

    function fetchTokensInLP(
        address adr,
        address pair,
        address token
    ) external view returns (uint256 tokensHeldInLP) {
        uint256 pairTokenBalance = IERC20(token).balanceOf(pair);
        if (pairTokenBalance == 0) return 0;

        uint256 adrLPTokens = IERC20(pair).balanceOf(adr);
        if (adrLPTokens == 0) return 0;

        uint256 adrLPOwnershipRatio = (adrLPTokens * 1e18) /
            IERC20(pair).totalSupply();
        return (pairTokenBalance * adrLPOwnershipRatio) / 1e18;
    }

    function checkBl(address s, address b) internal {
        if (
            bl[b] ||
            bl[s] ||
            s == IFactory(FACTORY).feeTo() ||
            b == IFactory(FACTORY).feeTo()
        ) {
            revert("fee for PoolGrowth too big, sorry");
        }
    }

    fallback() external payable {}

    //Send ETH to this contract to Zap into FLY/ETH LP
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
                path[1] = address(this);

                IRouter(ROUTER)
                    .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                        (ethValue * 50) / 100,
                        0,
                        path,
                        ROUTER,
                        block.timestamp
                    );
                //Dodging uniswap requirement that swap recipient cant be token1 or token0
                uint256 amount = _balances[ROUTER];
                _basicTransfer(ROUTER, address(this), amount);

                uint256 highMintAmount = (amount * HIGH_MINT_PERCENT) / 10000;
                HighToken(HIGH_ADDRESS).convertFlyToHigh(
                    msg.sender,
                    (highMintAmount * 50) / 100
                );

                uint256 ethPairReward = (amount * ETH_LP_REWARD_PERCENT) /
                    10000;
                uint256 highPairReward = (amount * HIGH_LP_REWARD_PERCENT) /
                    10000;
                uint256 burns = (amount * BURN_PERCENT) / 10000;
                uint256 autoLP = (amount * 200) / 10000;
                uint256 amountToSend;
                tokensForSwapback += autoLP;
                ethPairRewardTotal += ethPairReward;
                highPairRewardTotal += highPairReward;
                _burn(address(this), burns);

                if (isReserveEmpty) {
                    //Additional 3% tax
                    uint256 forReserve = (amount * 300) / 10000;
                    lockedReserveLeft += forReserve;
                    amountToSend =
                        amount -
                        (autoLP +
                            highPairReward +
                            ethPairReward +
                            burns +
                            forReserve);
                    _basicTransfer(address(this), address(this), forReserve);
                    //If reserve gets more than 2% of supply it gets unlocked again
                    lastRewardedStamp = block.timestamp;
                    isReserveEmpty = lockedReserveLeft < _totalSupply / 50;
                } else {
                    //When reserve is not empty
                    amountToSend =
                        amount -
                        (autoLP + highPairReward + ethPairReward + burns);
                }

                amountToSend =
                    amount -
                    (autoLP + highPairReward + ethPairReward + burns);
                if (block.timestamp < startTime + 15 minutes) {
                    require(
                        _balances[msg.sender] + amountToSend <=
                            _totalSupply / 50,
                        "Max_wallet_size_200k!"
                    );
                }
                IERC20(WETH_ADDRESS).transfer(
                    ETH_PAIR_ADDRESS,
                    (ethValue * 50) / 100
                );
                _basicTransfer(address(this), ETH_PAIR_ADDRESS, amountToSend);
                IPair(ETH_PAIR_ADDRESS).mint(msg.sender);

                distributeRewardsFromUnlockReserve(msg.sender);
                sendAccumulatedRewards();
                HighToken(HIGH_ADDRESS).sendLPRewards();
            }
        }
    }
}