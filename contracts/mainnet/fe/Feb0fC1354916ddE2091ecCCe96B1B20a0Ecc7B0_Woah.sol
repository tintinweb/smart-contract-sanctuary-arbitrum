//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract ERC20Detailed {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory tname, string memory tsymbol, uint8 tdecimals) {
        _name = tname;
        _symbol = tsymbol;
        _decimals = tdecimals;

    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapV2Router01.sol";

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20Detailed.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract Woah is Context, Ownable, IERC20, ERC20Detailed {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniSwapV2Router;
    address public immutable uniSwapV2Pair;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcludedFromMax;

    uint256 internal _totalSupply;

    uint256 public sellFee = 3;
    uint256 public buyFee = 3;
    uint256 private contractFee;

    uint256 public constant ONE_HUNDRED_PERCENT = 100;

    address payable public feeWallet =
        payable(0x37B12F099a45A923F4481f752C0c368C12805b04);

    bool inSwapAndLiquify;
    bool private swapAndLiquifyEnabled = true;
    bool public tradingEnabled = false;

    uint256 public numTokensSellToFee = 1 * 10 ** 18;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    address private _owner;

    uint256 public maxWallet;

    constructor() ERC20Detailed("Woah Crash", "WOAH", 18) {
        _owner = msg.sender;
        _totalSupply = 1_000_000_000_000 * (10 ** 18);

        _balances[_owner] = _totalSupply;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );
        uniSwapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniSwapV2Router = _uniswapV2Router;

        maxWallet = (_totalSupply * 10) / 100;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        //exclude owner and liquidity contract from max supply
        _isExcludedFromMax[uniSwapV2Pair] = true;
        _isExcludedFromMax[owner()] = true;
        _isExcludedFromMax[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address towner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[towner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        tradingEnabled = true;
    }

    function checkWalletLimit(address recipient, uint256 amount) internal view {
        if (!_isExcludedFromMax[recipient]) {
            uint256 heldTokens = balanceOf(recipient);
            require(
                (heldTokens + amount) <= maxWallet,
                "Total Holding is currently limited, you can not buy that much."
            );
        }
    }

    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= totalSupply() / 100);
        maxWallet = (_totalSupply * amount) / 100;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function changeNumTokensSellToFee(
        uint256 _numTokensSellToFee
    ) external onlyOwner {
        require(
            _numTokensSellToFee >= 1 * 10 ** 18 &&
                _numTokensSellToFee <= totalSupply(),
            "Threshold must be set within 1 to 1,000,000,000,000 tokens"
        );
        numTokensSellToFee = _numTokensSellToFee;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        checkWalletLimit(recipient, amount);

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToFee;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            sender != uniSwapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        } else {
            require(tradingEnabled, "Trading not yet enabled");
        }

        if (sender != uniSwapV2Pair && recipient != uniSwapV2Pair) {
            takeFee = false;
        }

        if (takeFee) {
            if (sender == uniSwapV2Pair) {
                contractFee = buyFee;
            } else {
                contractFee = sellFee;
            }
            uint256 taxAmount = amount.mul(contractFee).div(100);
            uint256 TotalSent = amount.sub(taxAmount);
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(TotalSent);
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(sender, recipient, TotalSent);
            emit Transfer(sender, address(this), taxAmount);
        } else {
            _balances[sender] = _balances[sender].sub(
                amount,
                "ERC20: transfer amount exceeds balance"
            );
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance);

        payable(feeWallet).transfer(address(this).balance);

        emit SwapAndLiquify(contractTokenBalance, address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniSwapV2Router.WETH();

        _approve(address(this), address(uniSwapV2Router), tokenAmount);

        // make the swap
        uniSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _approve(
        address towner,
        address spender,
        uint256 amount
    ) internal {
        require(towner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[towner][spender] = amount;
        emit Approval(towner, spender, amount);
    }
}