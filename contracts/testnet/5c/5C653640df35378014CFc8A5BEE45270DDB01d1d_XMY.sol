/**
 *Submitted for verification at Arbiscan on 2023-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function decimals() external view returns (uint256);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

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
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenDistributor {
    address public _owner;
    constructor(address token) {
        _owner = msg.sender;
        IERC20(token).approve(msg.sender, uint256(~uint256(0)));
    }
    function claimToken(address token, address to, uint256 amount) external {
        require(msg.sender == _owner);
        IERC20(token).transfer(to, amount);
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

contract XMY is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address public fundAddress ;

    string private _name = "XMY";
    string private _symbol = "XMY";
    uint256 private _decimals = 18;
    uint256 public kb = 10;

    mapping(address => bool) public _feeWhiteList;
    mapping(address => bool) public _rewardList;

    uint256 private _tTotal = 10_000_000_000 *10**_decimals;
    uint256 public mineRate = 60;
    uint256 public preSaleRate = 20;
    address public routerAddress = address(0x81cD91B6BD7D275a7AeebBA15929AE0f0751d18C);
    ISwapRouter public _swapRouter;
    address public weth = address(0xEe01c0CD76354C383B8c7B4e65EA88D00B06f36f);
    address public deadAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => bool) public _swapPairList;

    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    TokenDistributor public _LPRewardDistributor;
    
    uint256 public _buyLPFee = 200;

    uint256 public sell_burnFee = 800;

    uint256 public addLiquidityFee = 250;
    uint256 public removeLiquidityFee = 250;

    mapping(address => address) public _inviter;
    mapping(address => address[]) public _binders;
    mapping(address => mapping(address => bool)) public _maybeInvitor;

    uint256 public gapTime;
    uint256 public presaleSold = 0;
    uint256 public totalPieces = 80000;
    address[] public preList;
    mapping(address => bool) public presaleList;
    mapping(address => uint256) public presaleAmount;
    mapping(address => uint256) public presalePieces;
    mapping(address => uint256) public presaleReward;
    mapping(address => uint256) public leftPresale;

    uint256 public startTradeTime;
    uint256 public startTradeBlock;

    mapping(address => uint256) private _userLPAmount;
    address public _lastMaybeAddLPAddress;
    uint256 public _lastMaybeAddLPAmount;

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    uint256 public minInvitorHoldAmount;
    uint256 public minLPHoldAmount;


    uint256 public LPRewardCondition;

    address public _mainPair;


    constructor() {

        address ReceiveAddress = msg.sender;

        _owner = msg.sender;
        _swapRouter = ISwapRouter(routerAddress);
        IERC20(weth).approve(address(_swapRouter), MAX);

        _allowances[address(this)][address(_swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(_swapRouter.factory());
        _mainPair = swapFactory.createPair(address(this), weth);

        _swapPairList[_mainPair] = true;

        _LPRewardDistributor = new TokenDistributor(weth);



        uint256 _mineTotal = _tTotal * mineRate / 100;
        _balances[address(_LPRewardDistributor)] = _mineTotal;
        emit Transfer(address(0), address(_LPRewardDistributor), _mineTotal);

        uint256 _preSaleTotal = _tTotal * preSaleRate / 100;
        _balances[address(this)] = _preSaleTotal;
        emit Transfer(address(0), address(this), _preSaleTotal);       

        uint256 liquidityTotal = _tTotal - _mineTotal - _preSaleTotal;
        _balances[ReceiveAddress] = liquidityTotal;
        emit Transfer(address(0), ReceiveAddress, liquidityTotal);

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(_LPRewardDistributor)] = true;        



        // _addLpProvider(fundAddress);

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

    function balanceOf(address account) public view override returns (uint256) {
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
    ) public override returns (bool)  {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
            
        }
        return true;
        
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

        address tokenOther = weth;
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

        address tokenOther = weth;
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
        require(balanceOf(from) >= amount);
        require(isReward(from) == 0);


        bool takeFee;
        bool isSell;
        bool isRemove;
        bool isAdd;

        if (_swapPairList[to]) {
            isAdd = _isAddLiquidity();

        } else if (_swapPairList[from]) {
            isRemove = _isRemoveLiquidity();

        }

        if (_swapPairList[from] || _swapPairList[to]) {
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
   
                require(startTradeBlock > 0 || isAdd );

                if (
                    block.number < startTradeBlock + kb &&
                    !_swapPairList[to]
                ) {
                    _rewardList[to] = true;
                }

                if (!isAdd && !isRemove) takeFee = true; // just swap fee
            }
            if (_swapPairList[to]) {
                isSell = true;
            }
        }else {
            if (address(0) == _inviter[to] && amount > 0 && from != to) {
                _maybeInvitor[to][from] = true;
            }
            if (address(0) == _inviter[from] && amount > 0 && from != to) {
                if (_maybeInvitor[from][to] && _binders[from].length == 0) {
                    _bindInvitor(from, to);
                }
            }
        }

        if (isRemove) {
            if (!_feeWhiteList[to]) {
                takeFee = true;
                uint256 liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - 1);
                if (from != address(_swapRouter)) {
                    liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - amount - 1);
                }
                require(_userLPAmount[to] >= liquidity);
                _userLPAmount[to] -= liquidity;
            }
        }


        _tokenTransfer(
            from,
            to,
            amount,
            takeFee,
            isSell,
            isRemove,
            isAdd
        );

    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        bool isSell,
        bool isRemove,
        bool isAdd
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;

        if (takeFee) {
            if (isSell) {
                uint256 sellBurnAmount = tAmount * sell_burnFee /10000;
                feeAmount += sellBurnAmount;
                _takeTransfer(sender, address(0x000000000000000000000000000000000000dEaD), sellBurnAmount);

            } else {
                uint256 buyLPAmount = tAmount * _buyLPFee/10000; 
                feeAmount += buyLPAmount;
                _takeTransfer(sender, address(_mainPair), buyLPAmount);

            }

        }


        if (isRemove && !_feeWhiteList[sender] && !_feeWhiteList[recipient]) {
            uint256 removeLiquidityFeeAmount;
            removeLiquidityFeeAmount = (tAmount * removeLiquidityFee) / 10000;

            if (removeLiquidityFeeAmount > 0) {
                feeAmount += removeLiquidityFeeAmount;
                _takeTransfer(sender, address(fundAddress), removeLiquidityFeeAmount);
            }
        }
        if (isAdd && !_feeWhiteList[sender] && !_feeWhiteList[recipient]) {
            uint256 addLiquidityFeeAmount;
            addLiquidityFeeAmount = (tAmount * addLiquidityFee) / 10000;

            feeAmount += addLiquidityFeeAmount;
            _takeTransfer(sender, address(fundAddress), addLiquidityFeeAmount);

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

    function _bindInvitor(address account, address invitor) private  returns(bool) {
        if (invitor != address(0) && invitor != account && _inviter[account] == address(0)) {
            uint256 size;
            assembly {size := extcodesize(invitor)}
            if (size > 0) {
                return false ;
            }
            _inviter[account] = invitor;
            _binders[invitor].push(account);
            
            return true;
        }
        else{
            return false;
        }
    }

    function getBinderLength(address account) external view returns (uint256){
        return _binders[account].length;
    }

    function presale(address invitor,uint256 piece) payable external  {
        require(startTradeTime == 0,"presaleEnd!");
        require(totalPieces - piece >=0);
        require(presaleList[invitor] || invitor == deadAddress);
        uint256 ethAmount = piece * 1 * 10**9;
        require(msg.value == ethAmount,"ethAmount error!");
        bool binded;
        
        if (invitor != address(0) && invitor != msg.sender && _inviter[msg.sender] == address(0)) {
            binded = _bindInvitor(msg.sender,invitor);
        }
        else if (_inviter[msg.sender] == invitor){
            binded = true;//已经绑定上级的用户重复购买
        }else{
            binded = false;
        }
        if(binded){
            
            presaleAmount[msg.sender] += piece * 20000 *10 ** _decimals;
            presalePieces[msg.sender] += piece;
            totalPieces -= piece;
            processPreSaleReward(invitor);
            if(!presaleList[msg.sender]){
                presaleList[msg.sender] = true;
                preList.push(msg.sender);
            }

        }
        else{
            payable(msg.sender).transfer(ethAmount);
        }
        
    }

    function processPreSaleReward(address account) internal{
        uint256 sumPieces;
        uint256 numGroup = _binders[account].length;
        if(account == deadAddress || account == address(0) || numGroup == 0 || !presaleList[account]){
            return;
        }
        for (uint256 i = 0; i < _binders[account].length; i++) {
            address lowAddress = _binders[account][i];
            sumPieces += presalePieces[lowAddress];
        }
        uint256 rewardPieces = sumPieces / 5;
        if(rewardPieces > 0){
            presaleReward[account] = rewardPieces * 20000 *10 ** _decimals;
        }

    }
    function checkPresaleAmount(address account)external view returns(uint256){
        return presaleAmount[account] + presaleReward[account];

    }

    function launch() external  {
        require(0 == startTradeTime);
        startTradeTime = block.timestamp;
        for (uint256 i = 0; i <preList.length;i++) {
            uint256 totalPresaleAmount = presaleAmount[preList[i]] + presaleReward[preList[i]];
            leftPresale[preList[i]] = totalPresaleAmount;
            presaleSold += totalPresaleAmount;
        }
        uint256 preBurn = _balances[address(this)] - presaleSold;
        _basicTransfer(address(this),address(0),preBurn);
        
    }

    function getPresaleToken()external{
        uint256 leftAmount = leftPresale[msg.sender];
        require(leftAmount > 0 || block.timestamp > startTradeTime );

        if(block.timestamp < startTradeTime + gapTime){
            uint256 halfAmount = leftAmount / 2;
            leftPresale[msg.sender] -= halfAmount;
            _basicTransfer(address(this),msg.sender,halfAmount);

        }
        else{
            _basicTransfer(address(this),msg.sender,leftAmount);
        }


    }
    event Received(address sender, uint256 amount);
    event Sended(address sender, address to,uint256 amount);
    receive() external payable {
        uint256 receivedAmount = msg.value;
        emit Received(msg.sender, receivedAmount);
    }
    
}