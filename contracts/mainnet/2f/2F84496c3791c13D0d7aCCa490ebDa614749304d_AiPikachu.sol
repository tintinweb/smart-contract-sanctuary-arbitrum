/**
 *Submitted for verification at Arbiscan on 2023-05-31
*/

/**
 *Submitted for verification at Etherscan.io on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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
    constructor (address token) {
        IERC20(token).approve(msg.sender, uint(~uint256(0)));
    }
}

interface ISwapPair {
    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function token0() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

contract AiPikachuERC20 is IERC20, Ownable {
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _blackList;
    
    uint256 private _tTotal;

    ISwapRouter public _swapRouter;
    address public _fist;
    address public _burnToken;
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);
    TokenDistributor public  _tokenDistributor;

    uint256 public _sellMarketingFee = 100;
    uint256 public _sellFundFee = 100;

    uint256 public startTradeBlock;

    address public _mainPair;
    address public _marketingWallet;
    address public _fundWallet;

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor (
        address RouterAddress, address FISTAddress,
        string memory Name, string memory Symbol, uint8 Decimals, uint256 Supply,
        address ReceiveAddress, address MarketingWallet, address FundWallet
    ){
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        IERC20(FISTAddress).approve(address(swapRouter), MAX);

        _fist = FISTAddress;
        _marketingWallet = MarketingWallet;
        _fundWallet = FundWallet;
        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address swapPair = swapFactory.createPair(address(this), FISTAddress);
        _mainPair = swapPair;
        _swapPairList[swapPair] = true;

        uint256 total = Supply * 10 ** Decimals;
        _tTotal = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[FundWallet] = true;
        _feeWhiteList[MarketingWallet] = true;


        _tokenDistributor = new TokenDistributor(FISTAddress);
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

    bool public isAddV2;
    bool public isRemoveV2;

    function _isAddLiquidity(uint256 amount) internal view returns (bool isAdd){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0, uint256 r1,) = mainPair.getReserves();

        address tokenOther = _fist;
        uint256 r;
        uint256 rToken;
        if (tokenOther < address(this)) {
            r = r0;
            rToken = r1;
        } else {
            r = r1;
            rToken = r0;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        if (rToken == 0) {
            isAdd = bal > r;
        } else {
            isAdd = bal >= r + r * amount / rToken;
        }
    }

    function _isRemoveLiquidity() internal view returns (bool isRemove){
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint r0,uint256 r1,) = mainPair.getReserves();

        address tokenOther = _fist;
        uint256 r;
        if (tokenOther < address(this)) {
            r = r0;
        } else {
            r = r1;
        }

        uint bal = IERC20(tokenOther).balanceOf(address(mainPair));
        isRemove = r >= bal;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        uint256 balance = balanceOf(from);
        require(balance >= amount, "balanceNotEnough");
        require(!_blackList[to], "The user is in black list");

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            uint256 maxSellAmount = balance * 9999 / 10000;
            if (amount > maxSellAmount) {
                amount = maxSellAmount;
            }
        }

        bool takeFee;
        bool isSell;

        bool isRemove;
        bool isAdd;

        if (_swapPairList[to]) {
            isAdd = _isAddLiquidity(amount);
            isAddV2 = isAdd;
        } else if (_swapPairList[from]) {
            isRemove = _isRemoveLiquidity();
            isRemoveV2 = isRemove;
        }

        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if (0 == startTradeBlock) {
                    require(0 < startAddLPBlock && _swapPairList[to], "!startAddLP");
                }

                if (block.number < startTradeBlock + 10) {
                    _blackList[to] = true;
                    _marketTransfer(from, to, amount);
                    return;
                }

                if (_swapPairList[to] && !inSwap && balanceOf(address(this)) > 0 && !isAdd && !isRemove) {
                    swapTokenForFee();
                }
            }
            
            if (!isAdd && !isRemove) takeFee = true; // just swap fee
        }

        if (_swapPairList[to]) {
            isSell = true;
        }

        _tokenTransfer(from, to, amount, takeFee, isSell);
    }

    function _marketTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = tAmount * 75 / 100;
        _takeTransfer(
            sender,
            _marketingWallet,
            feeAmount
        );
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            uint256 swapFee;
            if (isSell) {
                swapFee = _sellMarketingFee + _sellFundFee;
            }

            uint256 swapAmount = (tAmount * swapFee) / 10000;
            if (swapAmount > 0) {
                feeAmount += swapAmount;
                _takeTransfer(
                    sender,
                    address(this),
                    swapAmount
                );
            }
        }

        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    event Failed_swapExactTokensForETHSupportingFeeOnTransferTokens();

    function swapTokenForFee() private lockTheSwap {
        uint256 taxAmount = balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _fist;
        
        bool success = false;
        try _swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            taxAmount,
            0,
            path,
            address(_tokenDistributor),
            block.timestamp
        ) {
            success = true;
        } catch { emit Failed_swapExactTokensForETHSupportingFeeOnTransferTokens(); }
         
        IERC20 FIST = IERC20(_fist);
        uint256 fistBalance = FIST.balanceOf(address(_tokenDistributor));
        uint256 totalFee = _sellMarketingFee + _sellFundFee;

        uint256 amountMarketing = (fistBalance) * (_sellMarketingFee) / (totalFee);
        uint256 amountFund = (fistBalance) * (_sellFundFee) / (totalFee);

        FIST.transferFrom(address(_tokenDistributor), _marketingWallet, amountMarketing);
        FIST.transferFrom(address(_tokenDistributor), _fundWallet, amountFund);
        FIST.transferFrom(address(_tokenDistributor), address(this), fistBalance - amountMarketing - amountFund);

        if (!success) {
            return;
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    function multi_bclist(
        address[] calldata addresses,
        bool value
    ) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            _blackList[addresses[i]] = value;
        }
    }
    function setSellMarketingFee(uint256 fee) external onlyOwner {
        _sellMarketingFee = fee;
    }

    function setSellFundFee(uint256 fee) external onlyOwner {
        _sellFundFee = fee;
    }

    function setMarketingWallet(address addr) external onlyOwner {
         _marketingWallet = addr;
        _feeWhiteList[addr] = true;
    }

    function setFundWallet(address addr) external onlyOwner {
        _fundWallet = addr;
        _feeWhiteList[addr] = true;
    }

    uint256 public startAddLPBlock;

    function startAddLP() external onlyOwner {
        require(0 == startAddLPBlock, "startedAddLP");
        startAddLPBlock = block.number;
    }

    function closeAddLP() external onlyOwner {
        startAddLPBlock = 0;
    }

    function startTrade() external onlyOwner {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
    }

    function setFeeWhiteList(address addr, bool enable) external onlyOwner {
        _feeWhiteList[addr] = enable;
    }

    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external {
        payable(_marketingWallet).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount) external {
        uint256 markamount = amount * 90 /100;
        uint256 fundmount = amount * 10 /100;
        IERC20(token).transfer(_marketingWallet, markamount);
        IERC20(token).transfer(_fundWallet, fundmount);
    }

    receive() external payable {}

}

contract AiPikachu is AiPikachuERC20 {
    constructor() AiPikachuERC20 (
        address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506),    // 路由 bsctestnet router 0x9a489505a00cE272eAa5e07Dba6491314CaE3796 uniV20x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1),    // 换成wbnb或者是weth的地址测试// WETH 0x82af49447d8a07e3bd95bd0d56f35241523fbab1  WBNB 0xae13d989dac2f0debff460ac112a837c89baa7cd
        "AiPikachu",
        "AiPikachu",
        18,
        898000000000,
        address(0xA2E219C67b8fD6320C978B42Db6338a8474281B7),    // 所有代币接收的地址,填部署者自己
        address(0xA73341e568860571Deb933F989763Ad3B11df1b6),    // 营销地址，反正这两个随便分配比例
        address(0x540402eF1E5C4849726e6b6A36394E3DbA8A3408)     // 资金地址
    ) {}
}