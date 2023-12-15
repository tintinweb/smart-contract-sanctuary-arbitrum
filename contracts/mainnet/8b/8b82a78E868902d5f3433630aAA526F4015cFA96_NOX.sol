// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
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

pragma solidity >=0.5.0;

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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract NOX is IERC20, Ownable {
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "NOX";
    string constant _symbol = "$NOX";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 100_000_000 * (10 ** _decimals);
    uint256 _maxBuyTxAmount = (_totalSupply * 1) / 200;
    uint256 _maxSellTxAmount = (_totalSupply * 1) / 200;
    uint256 _maxWalletSize = (_totalSupply * 1) / 100;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public lastSell;
    mapping(address => uint256) public lastBuy;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public liquidityCreator;
    mapping(address => bool) public isAuthorized;

    uint256 public marketingSellFee = 400;
    uint256 public devSellFee = 100;

    uint256 public totalSellFee = marketingSellFee + devSellFee;

    uint256 public transferTax = 500;

    uint256 public feeDenominator = 10000;
    bool public isTransferTax = true;

    address payable public devFeeReceiver =
        payable(0x30A50D29D0579C4B14EA38B9AB5F7Ef4fB004a39);
    address payable public marketingFeeReceiver =
        payable(0xBd2F13cd5cacB2E1CB95FBd41fF9eb205cE24ea3);

    IUniswapV2Router02 public router;
    mapping(address => bool) liquidityPools;
    mapping(address => uint256) public protected;
    bool private protectionEnabled = true;
    bool private protectionDisabled = false;
    uint256 protectionLimit;
    uint256 public protectionCount;
    uint256 public protectionTimer;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
    uint256 public deadBlocks;
    bool public startBullRun = false;
    bool public pauseDisabled = false;
    uint256 public rateLimit = 2;

    bool public swapEnabled = false;
    uint256 public swapThreshold = _totalSupply / 1000;
    uint256 public swapMinimum = _totalSupply / 10000;
    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    mapping(address => bool) teamMember;

    modifier onlyTeam() {
        require(
            teamMember[_msgSender()] || msg.sender == owner(),
            "Caller is not a team member"
        );
        _;
    }

    event ProtectedWallet(address, address, uint256, uint8);

    constructor() {
        isFeeExempt[owner()] = true;
        liquidityCreator[owner()] = true;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[owner()] = true;

        isTxLimitExempt[DEAD] = true;

        _balances[owner()] = _totalSupply;

        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function maxBuyTxTokens() external view returns (uint256) {
        return _maxBuyTxAmount / (10 ** _decimals);
    }

    function maxSellTxTokens() external view returns (uint256) {
        return _maxSellTxAmount / (10 ** _decimals);
    }

    function maxWalletTokens() external view returns (uint256) {
        return _maxWalletSize / (10 ** _decimals);
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

    function setTeamMember(address _team, bool _enabled) external onlyOwner {
        teamMember[_team] = _enabled;
    }

    function airdrop(
        address[] calldata addresses,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(addresses.length > 0 && amounts.length == addresses.length);
        address from = msg.sender;

        for (uint i = 0; i < addresses.length; i++) {
            if (
                !liquidityPools[addresses[i]] && !liquidityCreator[addresses[i]]
            ) {
                _basicTransfer(
                    from,
                    addresses[i],
                    amounts[i] * (10 ** _decimals)
                );
            }
        }
    }

    function clearStuckBalance(
        uint256 amountPercentage,
        address adr
    ) external onlyTeam {
        uint256 amountETH = address(this).balance;

        if (amountETH > 0) {
            (bool sent, ) = adr.call{
                value: (amountETH * amountPercentage) / 100
            }("");
            require(sent, "Failed to transfer funds");
        }
    }

    function openTrading(
        uint256 _deadBlocks,
        uint256 _protection,
        uint256 _limit
    ) external onlyTeam {
        require(!startBullRun && _deadBlocks < 10);
        deadBlocks = _deadBlocks;
        startBullRun = true;
        launchedAt = block.number;
        protectionTimer = block.timestamp + _protection;
        protectionLimit = _limit * (10 ** _decimals);
    }

    function setProtection(bool _protect, uint256 _addTime) external onlyTeam {
        require(!protectionDisabled);
        protectionEnabled = _protect;
        require(_addTime < 1 days);
        protectionTimer += _addTime;
    }

    function disableProtection() external onlyTeam {
        protectionDisabled = true;
        protectionEnabled = false;
    }

    function protectWallet(
        address[] calldata _wallets,
        bool _protect
    ) external onlyTeam {
        if (_protect) {
            require(protectionEnabled);
        }

        for (uint i = 0; i < _wallets.length; i++) {
            if (_protect) {
                protectionCount++;
                emit ProtectedWallet(tx.origin, _wallets[i], block.number, 2);
            } else {
                if (protected[_wallets[i]] != 0) protectionCount--;
            }
            protected[_wallets[i]] = _protect ? block.number : 0;
        }
    }

    function transfer(
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        require(sender != address(0), "BEP20: transfer from 0x0");
        require(recipient != address(0), "BEP20: transfer to 0x0");
        require(amount > 0, "Amount must be > zero");
        require(_balances[sender] >= amount, "Insufficient balance");
        if (inSwap || isAuthorized[sender] || isAuthorized[recipient]) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (!startBullRun) {
            require(
                liquidityCreator[sender] || liquidityCreator[recipient],
                "Trading not open yet."
            );
        }

        checkTxLimit(sender, recipient, amount);

        if (!liquidityPools[recipient] && recipient != DEAD) {
            if (!isTxLimitExempt[recipient]) {
                checkWalletLimit(recipient, amount);
            }
        }

        if (protectionEnabled && protectionTimer > block.timestamp) {
            if (
                liquidityPools[sender] &&
                tx.origin != recipient &&
                protected[recipient] == 0
            ) {
                protected[recipient] = block.number;
                protectionCount++;
                emit ProtectedWallet(tx.origin, recipient, block.number, 0);
            }
        }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = amount;

        if (shouldTakeFee(sender, recipient)) {
            amountReceived = takeFee(recipient, sender, amount);
            if (shouldSwapBack(recipient) && amount > 0) swapBack(amount);
        }

        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.number;
        launchedTime = block.timestamp;
        swapEnabled = true;
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

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        uint256 walletLimit = _maxWalletSize;
        require(
            _balances[recipient] + amount <= walletLimit,
            "Transfer amount exceeds the bag size."
        );
    }

    function checkTxLimit(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        if (isTxLimitExempt[sender] || isTxLimitExempt[recipient]) return;
        require(
            amount <=
                (liquidityPools[sender] ? _maxBuyTxAmount : _maxSellTxAmount),
            "TX Limit Exceeded"
        );
        require(
            lastBuy[recipient] + rateLimit <= block.number,
            "Transfer rate limit exceeded."
        );

        if (protected[sender] != 0) {
            require(
                amount <= protectionLimit * (10 ** _decimals) &&
                    lastSell[sender] == 0 &&
                    protectionTimer > block.timestamp,
                "Wallet protected, please contact support."
            );
            lastSell[sender] = block.number;
        }

        if (liquidityPools[recipient]) {
            lastSell[sender] = block.number;
        } else if (shouldTakeFee(sender, recipient)) {
            if (
                protectionEnabled &&
                protectionTimer > block.timestamp &&
                lastBuy[tx.origin] == block.number &&
                protected[recipient] == 0
            ) {
                protected[recipient] = block.number;
                emit ProtectedWallet(tx.origin, recipient, block.number, 1);
            }
            lastBuy[recipient] = block.number;
            if (tx.origin != recipient) lastBuy[tx.origin] = block.number;
        }
    }

    function shouldTakeFee(
        address sender,
        address recipient
    ) public view returns (bool) {
        if (
            !isTransferTax &&
            !liquidityPools[recipient] &&
            !liquidityPools[sender]
        ) return false;
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (launchedAt + deadBlocks >= block.number) {
            return feeDenominator - 1;
        }
        if (selling) return totalSellFee;

        return transferTax;
    }

    function takeFee(
        address recipient,
        address sender,
        uint256 amount
    ) internal returns (uint256) {
        bool selling = liquidityPools[recipient];
        bool buying = liquidityPools[sender];
        uint256 feeAmount = 0;
        if (!buying) {
            feeAmount = (amount * getTotalFee(selling)) / feeDenominator;
        }
        if (selling) {
            _balances[address(this)] += feeAmount;
            emit Transfer(sender, address(this), feeAmount);
        } else {
            _balances[marketingFeeReceiver] += feeAmount;
            emit Transfer(sender, marketingFeeReceiver, feeAmount);
        }

        return amount - feeAmount;
    }

    function shouldSwapBack(address recipient) internal view returns (bool) {
        return
            !liquidityPools[msg.sender] &&
            !inSwap &&
            swapEnabled &&
            liquidityPools[recipient] &&
            _balances[address(this)] >= swapMinimum &&
            totalSellFee > 0;
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap)
            amountToSwap = _balances[address(this)];

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

        uint256 amountETH = address(this).balance - balanceBefore;

        uint256 amountETHMarketing = (amountETH * marketingSellFee) /
            totalSellFee;
        uint256 amountETHDev = amountETH - amountETHMarketing;

        if (amountETHMarketing > 0) {
            (bool sentMarketing, ) = marketingFeeReceiver.call{
                value: amountETHMarketing
            }("");
            if (!sentMarketing) {
                //Failed to transfer to marketing wallet
            }
        }

        if (amountETHDev > 0) {
            (bool sentDev, ) = devFeeReceiver.call{value: amountETHDev}("");
            if (!sentDev) {
                //Failed to transfer to dev wallet
            }
        }

        emit FundsDistributed(amountETHMarketing, amountETHDev);
    }

    function addLiquidityPool(address lp, bool isPool) external onlyOwner {
        require(lp != pair, "Can't alter current liquidity pair");
        liquidityPools[lp] = isPool;
    }

    function setRateLimit(uint256 rate) external onlyOwner {
        require(rate <= 60 seconds);
        rateLimit = rate;
    }

    function setTxLimit(
        uint256 buyNumerator,
        uint256 sellNumerator,
        uint256 divisor
    ) external onlyOwner {
        require(
            buyNumerator > 0 &&
                sellNumerator > 0 &&
                divisor > 0 &&
                divisor <= 10000
        );
        _maxBuyTxAmount = (_totalSupply * buyNumerator) / divisor;
        _maxSellTxAmount = (_totalSupply * sellNumerator) / divisor;
    }

    function setMaxWallet(
        uint256 numerator,
        uint256 divisor
    ) external onlyOwner {
        require(numerator > 0 && divisor > 0 && divisor <= 10000);
        _maxWalletSize = (_totalSupply * numerator) / divisor;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(
        uint256 _devSellFee,
        uint256 _marketingSellFee,
        uint256 _transferTax,
        uint256 _feeDenominator
    ) external onlyOwner {
        marketingSellFee = _marketingSellFee;
        transferTax = _transferTax;
        devSellFee = _devSellFee;

        totalSellFee = _devSellFee + _marketingSellFee;
        feeDenominator = _feeDenominator;
        require(
            _transferTax + totalSellFee <= feeDenominator / 4,
            "Fees too high"
        );
        emit FeesSet(_transferTax, totalSellFee, feeDenominator);
    }

    function toggleTransferTax() external onlyOwner {
        isTransferTax = !isTransferTax;
    }

    function setFeeReceivers(
        address _devFeeReceiver,
        address _marketingFeeReceiver
    ) external onlyOwner {
        devFeeReceiver = payable(_devFeeReceiver);
        marketingFeeReceiver = payable(_marketingFeeReceiver);
    }

    function addAuthorizedWallets(
        address _wallet,
        bool _status
    ) external onlyOwner {
        isAuthorized[_wallet] = _status;
    }

    function setSwapBackSettings(
        bool _enabled,
        uint256 _denominator,
        uint256 _swapMinimum
    ) external onlyOwner {
        require(_denominator > 0);
        swapEnabled = _enabled;
        swapThreshold = _totalSupply / _denominator;
        swapMinimum = _swapMinimum * (10 ** _decimals);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(ZERO));
    }

    function setTheRouter(address _router, address _pair) external onlyOwner {
        router = IUniswapV2Router02(_router);
        pair = _pair;
        liquidityPools[pair] = true;
        _allowances[owner()][_router] = type(uint256).max;
        _allowances[address(this)][_router] = type(uint256).max;
        isTxLimitExempt[_router] = true;
    }

    event FundsDistributed(uint256 marketingETH, uint256 devETH);
    event FeesSet(
        uint256 totalBuyFees,
        uint256 totalSellFees,
        uint256 denominator
    );
}