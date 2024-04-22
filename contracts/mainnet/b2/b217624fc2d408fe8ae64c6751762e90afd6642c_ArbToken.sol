/**
 *Submitted for verification at Arbiscan.io on 2024-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address _spender, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external ;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface ISwapRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}
interface ISwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "!owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "new is 0");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
contract TokenDistributor {
    constructor(address token) {
        IERC20(token).approve(msg.sender, uint256(2**256-1));
    }
}
interface IWBNB {
    function withdraw(uint wad) external;
}
interface ISwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}
contract ArbToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;																												 
    mapping(address => mapping(address => uint256)) private _allowances;
    address payable public fundAddress;
    string private _name;
    string private _symbol;
    uint256 private _decimals;
    uint256 public kb;
    uint256 public maxWalletAmount;
    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _rewardList;
    mapping(address => bool) public isMaxEatExempt;
    uint256 private _tTotal;
    ISwapRouter public _swapRouter;
    address public currency;
    mapping(address => bool) public _swapPairList;
    bool public antiSYNC = true;
    bool private inSwap;
    uint256 private constant MAX = 2**256-1;
    TokenDistributor public _tokenDistributor;
    uint256 public _buyFundFee;
    uint256 public _buyLPFee;
    uint256 public _buyRewardFee;
    uint256 public buy_burnFee;
    uint256 public _sellFundFee;
    uint256 public _sellLPFee;
    uint256 public _sellRewardFee;
    uint256 public sell_burnFee;
    uint256 public addLiquidityFee;
    uint256 public removeLiquidityFee;
    uint256 public airdropNumbs;
    bool public currencyIsEth;
    address public rewardToken;
    uint256 public startTradeBlock;
    uint256 public startLPBlock;
    address public _mainPair;
    bool public enableOffTrade;
    bool public enableKillBlock;
    bool public enableRewardList;
    bool public enableWalletLimit;
    bool public enableChangeTax;
    bool public airdropEnable;
    address[] public rewardPath;
    constructor(
        string[] memory stringParams,
        address[] memory addressParams,
        uint256[] memory numberParams,
        bool[] memory boolParams
    ) {
        _name = stringParams[0];
        _symbol = stringParams[1];
        _decimals = numberParams[0];
        _tTotal = numberParams[1] * (10**18);
        fundAddress = payable(addressParams[0]);
        require(!isContract(fundAddress), "no contract ");
        currency = addressParams[1];
        _swapRouter = ISwapRouter(addressParams[2]);
        address ReceiveAddress = addressParams[3];
        rewardToken = addressParams[4];
        maxWalletAmount = numberParams[2];
        enableOffTrade = boolParams[0];
        enableKillBlock = boolParams[1];
        enableRewardList = boolParams[2];
        enableWalletLimit = boolParams[3];
        enableChangeTax = boolParams[4];
        currencyIsEth = boolParams[5];
        airdropEnable = boolParams[6];
        rewardPath = [currency];
        if (currency != rewardToken) {
            if (currencyIsEth == false) {
                rewardPath.push(_swapRouter.WETH());
            }
            if (rewardToken != _swapRouter.WETH()) rewardPath.push(rewardToken);
        }
        IERC20(currency).approve(address(_swapRouter), MAX);
        _allowances[address(this)][address(_swapRouter)] = MAX;
        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        _mainPair = swapFactory.createPair(address(this), currency);
        _swapPairList[_mainPair] = true;
        _buyFundFee = numberParams[3];
        _buyLPFee = numberParams[4];
        _buyRewardFee = numberParams[5];
        buy_burnFee = numberParams[6];
        _sellFundFee = numberParams[7];
        _sellLPFee = numberParams[8];
        _sellRewardFee = numberParams[9];
        sell_burnFee = numberParams[10];
        require(
            _buyFundFee + _buyLPFee + _buyRewardFee + buy_burnFee <= 2500 && 
            _sellFundFee + _sellLPFee + _sellRewardFee + sell_burnFee <= 2500
            
        );
        kb = numberParams[11];
        airdropNumbs = numberParams[12];
        require(airdropNumbs <= 5, "!<= 5");
        _balances[fundAddress] = uint256(_tTotal * 30 / 100);
        _balances[ReceiveAddress] = uint256(_tTotal * 70 / 100);
        emit Transfer(address(0), fundAddress, uint256(_tTotal * 30 / 100));
        emit Transfer(address(0), ReceiveAddress, uint256(_tTotal * 70 / 100));
        _feeWhiteList[fundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        isMaxEatExempt[fundAddress] = true;
        isMaxEatExempt[ReceiveAddress] = true;
        isMaxEatExempt[address(_swapRouter)] = true;
        isMaxEatExempt[address(_mainPair)] = true;
        isMaxEatExempt[address(this)] = true;
        isMaxEatExempt[address(0xdead)] = true;
        _tokenDistributor = new TokenDistributor(currency);
    }
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    function name() external view override returns (string memory) {
        return _name;
    }
    function decimals() external view override returns (uint256) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
    function setAntiSYNCEnable(bool s) public onlyOwner {
        antiSYNC = s;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (account == _mainPair && msg.sender == _mainPair && antiSYNC) {
            require(_balances[_mainPair] > 0, "!sync");
        }
        return _balances[account];
    }
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(
        address spender,
        uint256 amount
    ) public override  {
        _approve(msg.sender, spender, amount);
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override  {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
    }
    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function setisMaxEatExempt(address holder, bool exempt) external onlyOwner {
        isMaxEatExempt[holder] = exempt;
    }
    function setkb(uint256 a) external onlyOwner {
        kb = a;
    }
    function isReward(address account) public view returns (uint256) {
        if (_rewardList[account]) {
            return 1;
        } else {
            return 0;
        }
    }
    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    function _isAddLiquidity() internal view returns (bool isAdd) {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();
        address tokenOther = currency;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isAdd = bal > r;
    }
    function _isRemoveLiquidity() internal view returns (bool isRemove) {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1, ) = mainPair.getReserves();
        address tokenOther = currency;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }
        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(balanceOf(from) >= amount, "balanceNotEnough");
        require(isReward(from) == 0, "isReward != 0 !");
        bool takeFee;
        bool isSell;
        bool isRemove;
        bool isAdd;
        if (_swapPairList[to]) {
            isAdd = _isAddLiquidity();
        } else if (_swapPairList[from]) {
            isRemove = _isRemoveLiquidity();
        }
        if (startTradeBlock == 0 && enableOffTrade) {
            if (
                !_feeWhiteList[from] &&
                !_feeWhiteList[to] &&
                !_swapPairList[from] &&
                !_swapPairList[to]
            ) {
                require(!isContract(to), "cant add other lp");
            }
        }
        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (enableOffTrade) {
                    bool star = startTradeBlock > 0;
                    require(
                        star || (0 < startLPBlock && isAdd)
                    );
                }
                if (
                    enableOffTrade &&
                    enableKillBlock &&
                    block.number < startTradeBlock + kb &&
                    !_swapPairList[to]
                ) {
                    _rewardList[to] = true;
                }
                if (!isAdd && !isRemove) takeFee = true;
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }
        _tokenTransfer(from, to, amount, takeFee, isSell, isAdd, isRemove);
    }       
    function setAddLiquidityFee(uint256 newValue) external onlyOwner {
        require(newValue <= 2500, ">25!");
        addLiquidityFee = newValue;
    }
    function setRemoveLiquidityFee(uint256 newValue) external onlyOwner {
        require(newValue <= 10000, ">10000!");
        removeLiquidityFee = newValue;
    }
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell,
        bool isAdd,
        bool isRemove
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;
        if (takeFee) {
            uint256 swapFee;
            if (isSell) {
                swapFee = _sellFundFee + _sellRewardFee + _sellLPFee;
            } else {
                swapFee = _buyFundFee + _buyLPFee + _buyRewardFee;
            }
            uint256 swapAmount = (tAmount * swapFee) / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(sender, address(this), swapAmount);
            }
            uint256 burnAmount;
            if (!isSell) {
                //buy
                burnAmount = (tAmount * buy_burnFee) / 10000;
            } else {
                //sell
                burnAmount = (tAmount * sell_burnFee) / 10000;
            }
            if (burnAmount > 0) {
                feeAmount += burnAmount;
                _takeTransfer(sender, address(0xdead), burnAmount);
            }
        }
        if (isAdd && !_feeWhiteList[sender] && !_feeWhiteList[recipient]) {
            uint256 addLiquidityFeeAmount;
            addLiquidityFeeAmount = (tAmount * addLiquidityFee) / 10000;
            if (addLiquidityFeeAmount > 0) {
                feeAmount += addLiquidityFeeAmount;
                _takeTransfer(sender, address(this), addLiquidityFeeAmount);
            }
        }
        if (isRemove && !_feeWhiteList[sender] && !_feeWhiteList[recipient]) {
            uint256 removeLiquidityFeeAmount;
            removeLiquidityFeeAmount = (tAmount * removeLiquidityFee) / 10000;
            if (removeLiquidityFeeAmount > 0) {
                feeAmount += removeLiquidityFeeAmount;
                _takeTransfer(
                    sender,
                    address(0xdead),
                    removeLiquidityFeeAmount
                );
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }
    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }
    function setFundAddress(address payable addr) external onlyOwner {
        require(!isContract(addr), "no contract ");
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }
    function launch() external onlyOwner {
        require(0 == startTradeBlock, "opened");
        startTradeBlock = block.number;
    }
    function setFeeWhiteList(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }
    function multi_bclist(
        address[] calldata addresses,
        bool value
    ) public onlyOwner {
        require(enableRewardList, "disabled");
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _rewardList[addresses[i]] = value;
        }
    }
    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }
    receive() external payable {}
}