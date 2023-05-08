/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ISwapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

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
        require(_owner == msg.sender, "!o");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "n0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract AbsToken is IERC20, Ownable {
    struct LimitInfo {
        uint256 holderNum;
        uint256 amount;
    }

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private constant _deadAddress = address(0x000000000000000000000000000000000000dEaD);

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;

    ISwapRouter private immutable _swapRouter;
    uint256 private constant MAX = ~uint256(0);
    uint256 public startTradeBlock;
    address public _mainPair;
    address private  immutable _weth;
    address private immutable _receiver;

    LimitInfo[] private _limitInfo;

    constructor (
        address RouterAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply
    ){
        _receiver = msg.sender;
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        _swapRouter = ISwapRouter(RouterAddress);
        _weth = _swapRouter.WETH();
        _allowances[address(this)][address(_swapRouter)] = MAX;

        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;
        _tTotal = total;

        _takeTransfer(address(0), _receiver, tokenUnit);
        _takeTransfer(address(0), address(this), total - tokenUnit);

        uint256 yi = 100000000 * tokenUnit;
        _perPresaleToken = yi;

        //少于5000人，单地址限制持币1亿
        _limitInfo.push(LimitInfo(5000, yi));
        _limitInfo.push(LimitInfo(10000, 10 * yi));
        _limitInfo.push(LimitInfo(15000, 20 * yi));
        _limitInfo.push(LimitInfo(20000, 30 * yi));
        _limitInfo.push(LimitInfo(25000, 40 * yi));
    }

    function initMainPair() public {
        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        address ethPair = swapFactory.createPair(address(this), _weth);
        _mainPair = ethPair;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(address(0) != _mainPair, "!init");
        uint256 fromBalance = balanceOf(from);
        require(fromBalance >= amount, "BNE");

        //不能卖完，留0.000001个币
        if (from != _owner && from != address(this) && from != address(_swapRouter)) {
            uint256 maxSellAmount;
            uint256 remainAmount = 10 ** (_decimals - 6);
            if (fromBalance > remainAmount) {
                maxSellAmount = fromBalance - remainAmount;
            }
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        if (from == _mainPair) {
            //开盘才能买
            require(0 < startTradeBlock);
            //杀50个区块，arb 1秒5个块，杀10秒
            if (block.number < startTradeBlock + 50) {
                _killTransfer(from, to, amount);
                return;
            }
        } else if (to == _mainPair) {
            if (address(this) != from && _owner != from) {
                //开盘才能卖
                require(0 < startTradeBlock);
                //杀50个区块，arb 1秒5个块，杀10秒
                if (block.number < startTradeBlock + 50) {
                    _killTransfer(from, to, amount);
                    return;
                }
            }
        }

        _tokenTransfer(from, to, amount);
        //销毁地址，池子地址不限制数量
        if (_deadAddress != to && _mainPair != to && address(this) != to) {
            uint256 limitAmount = getLimitAmount();
            //限制数量大于0时，不能超过限制数量
            if (limitAmount > 0) {
                require(limitAmount >= balanceOf(to), "Hold Limit");
            }
        }
    }

    function getLimitAmount() public view returns (uint256 limitAmount){
        uint256 len = _limitInfo.length;
        uint256 holderLen = getHolderLength();
        LimitInfo storage limitInfo;
        for (uint256 i; i < len;) {
            limitInfo = _limitInfo[i];
            if (holderLen < limitInfo.holderNum) {
                limitAmount = limitInfo.amount;
                break;
            }
        unchecked{
            ++i;
        }
        }
    }

    function _killTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 99 / 100;
        _takeTransfer(
            sender,
            _deadAddress,
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        _takeTransfer(sender, recipient, tAmount);
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
        _addHolder(to);
    }

    address[] public holders;
    mapping(address => uint256) public holderIndex;

    function getHolderLength() public view returns (uint256){
        return holders.length;
    }

    function _addHolder(address adr) private {
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    //打开交易
    function startTrade() external onlyOwner {
        //开关只能打开一次
        require(0 == startTradeBlock, "Trading");
        //预售完了，才能打开开关
        require(_presaleNum >= _presaleQty, "Presale");
        startTradeBlock = block.number;
    }

    bool private _startPresale = false;
    uint256 private  constant _perPresaleEth = 1 ether / 100;
    uint256 private immutable _perPresaleToken;
    uint256 private _presaleQty = 1000;
    uint256 private _presaleNum;
    mapping(address => bool) public joinPresale;

    function presale() public payable {
        //未开始
        require(_startPresale, "not start");
        //预售完了
        require(_presaleNum < _presaleQty, "sold out");
        //ETH 不足
        require(msg.value >= _perPresaleEth, "ETH NE");
        address account = msg.sender;
        //拒绝机器人
        require(tx.origin == account, "robot");
        //参与过了
        require(!joinPresale[account], "join");
        joinPresale[account] = true;
        _presaleNum++;

        (,,uint256 liquidity) = _swapRouter.addLiquidityETH{value : _perPresaleEth}(address(this), _perPresaleToken, 0, 0, address(this), block.timestamp);
        address ethLP = _mainPair;
        safeTransfer(ethLP, _deadAddress, liquidity / 2);
        safeTransfer(ethLP, account, liquidity / 2);
    }

    function getPresaleInfo() public view returns (
        bool startPresale,
        uint256 perPresaleEth,
        uint256 perPresaleToken,
        uint256 presaleQty,
        uint256 presaleNum
    ){
        startPresale = _startPresale;
        perPresaleEth = _perPresaleEth;
        perPresaleToken = _perPresaleToken;
        presaleQty = _presaleQty;
        presaleNum = _presaleNum;
    }

    function StartPresale() external onlyOwner {
        _startPresale = true;
    }

    receive() external payable {

    }

    function claimETH(uint256 amount) external {
        //开盘后才能提取合约里的ETH，避免有人转ETH到合约里，造成资产损失
        require(startTradeBlock > 0, "not allow");
        safeTransferETH(_receiver, amount);
    }

    function claimToken(address token, uint256 amount) external {
        //开盘后才能提取合约里的代币，避免有人转代币到合约里，造成资产损失
        require(startTradeBlock > 0, "not allow");
        safeTransfer(token, _receiver, amount);
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (success && data.length > 0) {

        }
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success, bytes memory data) = to.call{value : value}(new bytes(0));
        if (success && data.length > 0) {

        }
    }
}

contract TATAN is AbsToken {
    constructor() AbsToken(
    //SwapRouter
        address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d),
        "TATAN TOKEN",
        "TATAN",
        18,
        100000000001
    ){

    }
}