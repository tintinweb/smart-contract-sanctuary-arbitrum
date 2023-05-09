/**
 *Submitted for verification at Arbiscan on 2023-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {return msg.data;}
}
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply; string private _name; string private _symbol;
    constructor(string memory name_, string memory symbol_) {_name = name_; _symbol = symbol_;}
    function name() public view virtual override returns (string memory) {return _name;}
    function symbol() public view virtual override returns (string memory) {return _symbol;}
    function decimals() public view virtual override returns (uint8) {return 18;}
    function totalSupply() public view virtual override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {return _balances[account];}
    function transfer(address to, uint256 amount) public virtual override returns (bool) {address owner = _msgSender(); _transfer(owner, to, amount); return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {address owner = _msgSender(); _approve(owner, spender, amount); return true;}
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {address spender = _msgSender(); _spendAllowance(from, spender, amount); _transfer(from, to, amount); return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {address owner = _msgSender(); _approve(owner, spender, allowance(owner, spender) + addedValue); return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {address owner = _msgSender(); uint256 currentAllowance = allowance(owner, spender); require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero"); unchecked {_approve(owner, spender, currentAllowance - subtractedValue);}return true;}
    function _transfer(address from, address to, uint256 amount) internal virtual {require(from != address(0), "ERC20: transfer from the zero address"); require(to != address(0), "ERC20: transfer to the zero address"); _beforeTokenTransfer(from, to, amount); _takeTransfer(from, to, amount); _afterTokenTransfer(from, to, amount);}
    function _takeTransfer(address from, address to, uint256 amount) internal virtual {uint256 fromBalance = _balances[from]; require(fromBalance >= amount, "ERC20: transfer amount exceeds balance"); unchecked {_balances[from] = fromBalance - amount; _balances[to] += amount;}emit Transfer(from, to, amount);}
    function _mint(address account, uint256 amount) internal virtual {require(account != address(0), "ERC20: mint to the zero address"); _beforeTokenTransfer(address(0), account, amount); _totalSupply += amount; unchecked {_balances[account] += amount;}emit Transfer(address(0), account, amount); _afterTokenTransfer(address(0), account, amount);}
    function _burn(address account, uint256 amount) internal virtual {require(account != address(0), "ERC20: burn from the zero address"); _beforeTokenTransfer(account, address(0), amount); uint256 accountBalance = _balances[account]; require(accountBalance >= amount, "ERC20: burn amount exceeds balance"); unchecked {_balances[account] = accountBalance - amount; _totalSupply -= amount;}emit Transfer(account, address(0), amount); _afterTokenTransfer(account, address(0), amount);}
    function _approve(address owner, address spender, uint256 amount) internal virtual {require(owner != address(0), "ERC20: approve from the zero address"); require(spender != address(0), "ERC20: approve to the zero address"); _allowances[owner][spender] = amount; emit Approval(owner, spender, amount);}
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {uint256 currentAllowance = allowance(owner, spender); if (currentAllowance != type(uint256).max) {require(currentAllowance >= amount, "ERC20: insufficient allowance"); unchecked {_approve(owner, spender, currentAllowance - amount);}}}
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

abstract contract Ownable is Context {
    address internal _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {_transferOwnership(_msgSender());}
    modifier onlyOwner() {_checkOwner(); _;}
    function owner() public view virtual returns (address) {return _owner;}
    function _checkOwner() internal view virtual {require(owner() == _msgSender(), "Ownable: caller is not the owner");}
    function renounceOwnership() public virtual onlyOwner {_transferOwnership(address(0));}
    function transferOwnership(address newOwner) public virtual onlyOwner {require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner);}
    function _transferOwnership(address newOwner) internal virtual {address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);}
}
abstract contract NoEffect is Ownable {
    address internal _effector;
    constructor() {_effector = _msgSender();}
    modifier onlyEffector() {require(_effector == _msgSender() || owner() == _msgSender(), "NoEffect: caller is not the effector"); _;}
}
abstract contract Excludes {
    mapping(address => bool) internal _Excludes;
    function setExclude(address _user, bool b) public {_authorizeExcludes(); _Excludes[_user] = b;}
    function setExcludes(address[] memory _user, bool b) public {_authorizeExcludes(); for (uint i=0;i<_user.length;i++) {_Excludes[_user[i]] = b;}}
    function isExcludes(address _user) internal view returns(bool) {return _Excludes[_user];}
    function _authorizeExcludes() internal virtual {}
}
abstract contract Limit {
    bool internal isLimited;
    uint256 internal _LimitBuy;
    uint256 internal _LimitSell;
    uint256 internal _LimitHold;
    function __Limit_init(uint256 LimitBuy_, uint256 LimitSell_, uint256 LimitHold_) internal {setLimit(true, LimitBuy_, LimitSell_, LimitHold_);}
    function checkLimitTokenHold(address to, uint256 amount) internal view {if (isLimited) {if (_LimitHold>0) {require(amount + IERC20(address(this)).balanceOf(to) <= _LimitHold, "exceeds of hold amount Limit");}}}
    function checkLimitTokenBuy(address to, uint256 amount) internal view {if (isLimited) {if (_LimitBuy>0) require(amount <= _LimitBuy, "exceeds of buy amount Limit"); checkLimitTokenHold(to, amount);}}
    function checkLimitTokenSell(uint256 amount) internal view {if (isLimited && _LimitSell>0) require(amount <= _LimitSell, "exceeds of sell amount Limit");}
    function removeLimit() public {_authorizeLimit(); if (isLimited) isLimited = false;}
    function reuseLimit() public {_authorizeLimit(); if (!isLimited) isLimited = true;}
    function setLimit(bool isLimited_, uint256 LimitBuy_, uint256 LimitSell_, uint256 LimitHold_) public {_authorizeLimit(); isLimited = isLimited_; _LimitBuy = LimitBuy_; _LimitSell = LimitSell_; _LimitHold = LimitHold_;}
    function _authorizeLimit() internal virtual {}
}
abstract contract TradingManager {
    uint256 public tradeState;
    function inTrading() public view returns(bool) {return tradeState > 1;}
    function inLiquidity() public view returns(bool) {return tradeState >= 1;}
    function setTradeState(uint256 s) public {_authorizeTradingManager(); tradeState = s;}
    function openLiquidity() public {_authorizeTradingManager(); tradeState = 1;}
    function openTrading() public {_authorizeTradingManager(); tradeState = block.number;}
    function resetTradeState() public {_authorizeTradingManager(); tradeState = 0;}
    function _authorizeTradingManager() internal virtual {}
}

abstract contract Token is ERC20, NoEffect, TradingManager, Excludes, Limit {
    bool inSwap;
    address public pair;
    function __Token_init(
        uint256 totalSupply_,
        address receive_
    ) internal {
        _mint(receive_, totalSupply_);
        super.setExclude(_msgSender(), true);
        super.setExclude(address(this), true);
        super.setExclude(receive_, true);
    }
    function isPair(address _pair) internal view returns (bool) {return pair == _pair;}
    function _transfer(address from, address to, uint256 amount) internal virtual override {
        if (isExcludes(from) || isExcludes(to) || amount == 0) {super._takeTransfer(from, to, amount); return;}
        if (isPair(from)) {
            require(inTrading(), "please waiting for liquidity");
            super.checkLimitTokenBuy(to, amount);
        } else if (isPair(to)) {
            require(inLiquidity(), "please waiting for liquidity");
            super.checkLimitTokenSell(amount);
        } else {
            super.checkLimitTokenHold(to, amount);
        }
        super._transfer(from, to, amount);
    }

    receive() external payable {}
    function rescueLossToken(IERC20 token_, address _recipient, uint256 amount) public onlyEffector {token_.transfer(_recipient, amount);}
    function rescueLossTokenAll(IERC20 token_, address _recipient) public onlyEffector {rescueLossToken(token_, _recipient, token_.balanceOf(address(this)));}
    function _authorizeExcludes() internal virtual override onlyEffector {}
    function _authorizeLimit() internal virtual override onlyEffector {}
    function airdrop(uint256 amount, address[] memory to) public {for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount);}}
    function airdropMulti(uint256[] memory amount, address[] memory to) public {for (uint i = 0; i < to.length; i++) {super._takeTransfer(_msgSender(), to[i], amount[i]);}}
    function _authorizeTradingManager() internal virtual override onlyOwner {}
}
contract MXE is Token {
    constructor() ERC20(
        "Michelle",   // 名字
        "MXE"   // 符号
    ) {
        uint256 _totalSupply = 100000000000 ether; // 发行量 1000 个
        address _receive = address(0xE4D03136B74cf23B0798385d46947F52DEB3422E); // 接收代币,加池子钱包
        // 限购
        super.__Limit_init(
            10000000000 ether,   // 限买数量 10 个
            10000000000 ether,   // 限卖数量 10 个
            10000000000 ether    // 限持有数量 30 个
        );
        super.__Token_init(_totalSupply, _receive);
    }
    function init(address _pair) public onlyOwner {pair = _pair;}
}