/**
 *Submitted for verification at Arbiscan on 2023-06-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ArbSys {
    function arbBlockNumber() external view returns (uint);
}

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
    constructor() {
        _owner = msg.sender;
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

    address public fundAddress = address(0x259E9786BB40eb5F656dbc16e15538a2340c2554) ;

    string private _name = "XMY";
    string private _symbol = "XMY";
    uint256 private _decimals = 18;


    mapping(address => bool) public _feeWhiteList;

    uint256 private _tTotal = 10_000_000_000 *10**_decimals;
    uint256 public mineRate = 60;
    uint256 public preSaleRate = 20;
    address public routerAddress = address(0x8b707e7578059aD857f228FA63E82AA80E132b97);
    ISwapRouter public _swapRouter;
    address public weth = address(0xD8bbeA7e504851b0aa1c37475E7601c590cFa0B4);
    address public deadAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => bool) public _swapPairList;


    uint256 private constant MAX = ~uint256(0);

    TokenDistributor public mineRewardDistributor;
    
    uint256 public _buyLPFee = 200;

    uint256 public sell_burnFee = 800;

    uint256 public addLiquidityFee = 250;
    uint256 public removeLiquidityFee = 250;

    mapping(address => address) public _inviter;
    mapping(address => address[]) public _binders;
    mapping(address => mapping(address => bool)) public _maybeInvitor;

    uint256 public endPresaleTime;
    uint256 public gapTime = 180 days;
    uint256 public presaleSold;
    uint256 public totalPieces = 80000;
    address[] public preList;
    mapping(address => bool) public allowedPreList;
    mapping(address => bool) public presaleList;
    mapping(address => uint256) public presaleAmount;
    mapping(address => uint256) public presalePieces;
    mapping(address => uint256) public presaleReward;
    mapping(address => uint256) public leftPresale;

    uint256 public startPreTradeTime;
    uint256 public startTradeTime;

    mapping(address => uint256) public _userLPAmount;
    address public _lastMaybeAddLPAddress;
    uint256 public _lastMaybeAddLPAmount;

    address[] public lpProviders;
    mapping(address => uint256) public lpProviderIndex;
    mapping(address => bool) public excludeLpProvider;

    mapping(address => uint256) public mineReward;
    mapping(address => uint256) public invitorReward;

    uint256 oneLPNum = 1;
    uint256 twoLPNum = 1;
    uint256 threeLPNum = 1;
    uint256 fourLPNum = 1;
    uint256 fiveLPNum = 1;

    // uint256 oneLPNum = 25*10**_decimals;
    // uint256 twoLPNum = 80*10**_decimals;
    // uint256 threeLPNum = 240*10**_decimals;
    // uint256 fourLPNum = 400*10**_decimals;
    // uint256 fiveLPNum = 640*10**_decimals;


    uint256 oneInvitorReward = 6000 *10**_decimals;
    uint256 twoInvitorReward = 20000 *10**_decimals;
    uint256 threeInvitorReward = 60000 *10**_decimals;
    uint256 fourInvitorReward = 120000 *10**_decimals;


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

        mineRewardDistributor = new TokenDistributor();


        uint256 _mineTotal = _tTotal * mineRate / 100;
        _balances[address(mineRewardDistributor)] = _mineTotal;
        emit Transfer(address(0), address(mineRewardDistributor), _mineTotal);

        uint256 _preSaleTotal = _tTotal * preSaleRate / 100;
        _balances[address(this)] = _preSaleTotal;
        emit Transfer(address(0), address(this), _preSaleTotal);       

        uint256 liquidityTotal = _tTotal - _mineTotal - _preSaleTotal;
        _balances[ReceiveAddress] = liquidityTotal;
        emit Transfer(address(0), ReceiveAddress, liquidityTotal);

        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        // _feeWhiteList[address(_swapRouter)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0x000000000000000000000000000000000000dEaD)] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[address(mineRewardDistributor)] = true;        


        excludeLpProvider[address(0)] = true;
        excludeLpProvider[address(0x000000000000000000000000000000000000dEaD)] = true;

        _addLpProvider(fundAddress);

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
        address lastMaybeAddLPAddress = _lastMaybeAddLPAddress;
        if (lastMaybeAddLPAddress != address(0)) {
            _lastMaybeAddLPAddress = address(0);
            uint256 lpBalance = IERC20(_mainPair).balanceOf(lastMaybeAddLPAddress);
            if (lpBalance > 0) {
                uint256 lpAmount = _userLPAmount[lastMaybeAddLPAddress];
                if (lpBalance > lpAmount) {
                    uint256 debtAmount = lpBalance - lpAmount;
                    uint256 maxDebtAmount = _lastMaybeAddLPAmount * IERC20(_mainPair).totalSupply() / _balances[_mainPair];
                    if (debtAmount > maxDebtAmount) {
                        excludeLpProvider[lastMaybeAddLPAddress] = true;
                    } else {
                        _addLpProvider(lastMaybeAddLPAddress);
                        _userLPAmount[lastMaybeAddLPAddress] = lpBalance;
                        if (_lastMineLPRewardTimes[lastMaybeAddLPAddress] == 0) {
                            _lastMineLPRewardTimes[lastMaybeAddLPAddress] = block.timestamp;
                        }
                    }
                }
            }
        }

        bool takeFee;
        bool isSell;
        bool isRemove;
        bool isAdd;


        if (_swapPairList[from] || _swapPairList[to]) {
            if (_swapPairList[to]) {
            isAdd = _isAddLiquidity();
            isSell = true;

            }
            if (_swapPairList[from]) {
                isRemove = _isRemoveLiquidity();

            }
            if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
                if(allowedPreList[from] || allowedPreList[to]){
                    require(block.timestamp > startPreTradeTime); 
                }else{
                    require(block.timestamp > startTradeTime);
                }



                if (!isAdd && !isRemove) takeFee = true; // just swap fee
            }
        }else {
            if (_inviter[to] == address(0) && amount > 0 && from != to) {
                _maybeInvitor[to][from] = true;
            }
            if (_inviter[from] == address(0) && amount > 0 && from != to) {
                if (_maybeInvitor[from][to] && _binders[from].length == 0) {
                    _bindInvitor(from, to);
                }
            }
        }

        if (isRemove) {
            if (!_feeWhiteList[to]) {
                // takeFee = true;
                uint256 liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - 1);
                // if (from != address(_swapRouter)) {
                //     liquidity = (amount * ISwapPair(_mainPair).totalSupply() + 1) / (balanceOf(_mainPair) - amount - 1);
                // } 
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

        if (from != address(this)) {
            if (isSell) {
                _lastMaybeAddLPAddress = from;
                _lastMaybeAddLPAmount = amount;
            }
            if (!_feeWhiteList[from] && !isAdd) {
                processMineLP(500000);
            }
            
        }
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
                _takeTransfer(sender, deadAddress, sellBurnAmount);

            } else {
                uint256 buyLPAmount = tAmount * _buyLPFee/10000; 
                feeAmount += buyLPAmount;
                _takeTransfer(sender, address(_mainPair), buyLPAmount);

            }

        }


        if (isRemove && !_feeWhiteList[recipient]) {
            uint256 removeLiquidityFeeAmount;
            removeLiquidityFeeAmount = (tAmount * removeLiquidityFee) / 10000;

            
            feeAmount += removeLiquidityFeeAmount;
            _takeTransfer(sender, address(fundAddress), removeLiquidityFeeAmount);
            
        }
        if (isAdd && !_feeWhiteList[sender]) {
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
            }else{
                _inviter[account] = invitor;
                _binders[invitor].push(account);
                
                return true;
            }
        }
        else{
            return false;
        }
    }

    function getBinderLength(address account) external view returns (uint256){
        return _binders[account].length;
    }

    function presale(address invitor,uint256 piece) payable external  {
        require(endPresaleTime == 0,"presaleEnd!");
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
            
            sortPreList();

        }
        else{
            payable(msg.sender).transfer(ethAmount);
        }
        
    }
    function sortPreList() private  {
        // note that uint can not take negative value
        for (uint i = 1;i < preList.length;i++){
            address temp = preList[i];
            uint256 tempPiece = presalePieces[temp];
            uint j=i;
            while( (j >= 1) && (tempPiece > presalePieces[preList[j-1]])){
                preList[j] = preList[j-1];
                j--;
            }
            preList[j] = temp;
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
    function getSortList() public view returns(address[] memory){
        return preList;
    }

    function endPresale() external onlyOwner {
        require(0 == endPresaleTime);
        endPresaleTime = block.timestamp;
        for (uint256 i = 0; i <preList.length;i++) {
            uint256 totalPresaleAmount = presaleAmount[preList[i]] + presaleReward[preList[i]];
            leftPresale[preList[i]] = totalPresaleAmount;
            presaleSold += totalPresaleAmount;
            if(i<5){
                allowedPreList[preList[i]] = true;
            }
        }
        uint256 preBurn = _balances[address(this)] - presaleSold;
        _basicTransfer(address(this),address(0),preBurn);
        
    }


    function setLaunchTime(uint256 launchTime) external onlyOwner {
        require(0 == startTradeTime && endPresaleTime !=0);
        startTradeTime = launchTime;
        startPreTradeTime = launchTime - 3600;
    }


    function getPresaleToken()external{
        uint256 totalPresaleAmount = presaleAmount[msg.sender] + presaleReward[msg.sender];
        uint256 leftAmount = leftPresale[msg.sender];
        require(leftAmount > 0 && block.timestamp > endPresaleTime );

        if(block.timestamp < endPresaleTime + gapTime){
            if(leftAmount == totalPresaleAmount){
                uint256 halfAmount = leftAmount / 2;
                leftPresale[msg.sender] -= halfAmount;
                _basicTransfer(address(this),msg.sender,halfAmount);
            }

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



    function setFundAddress(address addr) external onlyOwner {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
        _addLpProvider(addr);
    }


    function setFeeWhiteList(
        address[] calldata addr,
        bool enable
    ) public onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }





    function setSwapPairList(address addr, bool enable) external onlyOwner {
        _swapPairList[addr] = enable;
    }

    function claimBalance() external onlyOwner {
        payable(fundAddress).transfer(address(this).balance);
    }

    function claimToken(
        address token,
        uint256 amount,
        address to
    ) external  {
        require(fundAddress == msg.sender);
        IERC20(token).transfer(to, amount);
    }

    function claimContractToken(address contractAddress, address token, uint256 amount) external {
        require(fundAddress == msg.sender);
        TokenDistributor(contractAddress).claimToken(token, fundAddress, amount);
    }


    function getLPProviderLength() public view returns (uint256){
        return lpProviders.length;
    }

    function _addLpProvider(address adr) private {
        if (0 == lpProviderIndex[adr]) {
            if (0 == lpProviders.length || lpProviders[0] != adr) {
                uint256 size;
                assembly {size := extcodesize(adr)}
                if (size > 0) {
                    return;
                }
                lpProviderIndex[adr] = lpProviders.length;
                lpProviders.push(adr);
            }
        }
    }
    function checkLowerCount(address account) view private returns(uint256 lowerHoldCount,uint256 lowerLPCount ){
        uint256 lowerCount =  _binders[account].length;
        for (uint256 i; i < lowerCount; ++i) {
            address lowAddress = _binders[account][i];
            uint256 pairBalance = IERC20(_mainPair).balanceOf(lowAddress);
            if(_balances[lowAddress] >= 1000*10**_decimals){
                lowerHoldCount +=1;
                if(pairBalance >= 10**15){
                    lowerLPCount +=1;
                }

            }
        }
        
    }

    // function checkMineLv(address account) public view returns(uint8){
    //     uint256 accLPBalance = IERC20(_mainPair).balanceOf(account);
    //     (uint256 lowerHoldCount,uint256 lowerLPCount) = checkLowerCount(account);
    //     if(accLPBalance > fiveLPNum && lowerHoldCount>=60 && lowerLPCount>= 50){
    //         return 5;

    //     }
    //     else if(accLPBalance > fourLPNum && lowerHoldCount>=50 && lowerLPCount>= 40){
    //         return 4;

    //     }
    //     else if(accLPBalance > threeLPNum && lowerHoldCount>=40 && lowerLPCount>= 30){
    //         return 3;

    //     }
    //     else if(accLPBalance > twoLPNum && lowerHoldCount>=30 && lowerLPCount>= 20){
    //         return 2;

    //     }
    //     else if(accLPBalance > oneLPNum && lowerHoldCount>=20 && lowerLPCount>= 10){
    //         return 1;

    //     }else{
    //         return 0;
    //     }

    // }

    function checkMineLv(address account) public view returns(uint8){
        uint256 accLPBalance = IERC20(_mainPair).balanceOf(account);
        (uint256 lowerHoldCount,uint256 lowerLPCount) = checkLowerCount(account);
        if(accLPBalance > fiveLPNum && lowerHoldCount>=5 && lowerLPCount>= 4){
            return 5;

        }
        else if(accLPBalance > fourLPNum && lowerHoldCount>=4 && lowerLPCount>= 3){
            return 4;

        }
        else if(accLPBalance > threeLPNum && lowerHoldCount>=3 && lowerLPCount>= 2){
            return 3;

        }
        else if(accLPBalance > twoLPNum && lowerHoldCount>=2 && lowerLPCount>= 1){
            return 2;

        }
        else if(accLPBalance > oneLPNum && lowerHoldCount>=1 && lowerLPCount>= 0){
            return 1;

        }else{
            return 0;
        }

    }


    uint256 public _currentMineLPIndex;
    uint256 public _progressMineLPBlock;
    uint256 public _progressMineLPBlockDebt = 100;
    mapping(address => uint256) public _lastMineLPRewardTimes;
    // uint256 public _mineTimeDebt = 7 days;
    uint256 public _mineTimeDebt = 600;

    uint256 public lastCycleTimestamp;
    uint256 public cycleTimeDebt = 182 days;
    uint256 public cycleAmount;
    uint256 public cycleMineAmount;
    uint256 public cycleInvitorAmount;
    uint256 public lastEachTimestamp;
    uint256 public eachMineAmount;
    uint256 public eachInvitorAmount;
    uint256 public eachInvitorMin = 10**_decimals;
    uint256 public MinerMin = 1000**_decimals;





    function processMineLP(uint256 gas) private {

        if (_progressMineLPBlock + _progressMineLPBlockDebt > ArbSys(address(100)).arbBlockNumber()) {
            return;
        }


        uint totalPair = IERC20(_mainPair).totalSupply();
        if (0 == totalPair) {
            return;
        }
        address sender = address(mineRewardDistributor);

        if (_balances[sender] < MinerMin) { 
            return;
        }

        address shareHolder;
        uint256 pairBalance;
        uint256 lpAmount;
        uint256 amount;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();


        while (gasUsed < gas && iterations < lpProviders.length) {
            if (_currentMineLPIndex >= lpProviders.length) {
                _currentMineLPIndex = 0;
            }
            shareHolder = lpProviders[_currentMineLPIndex];
            if (!excludeLpProvider[shareHolder]) {
                pairBalance = IERC20(_mainPair).balanceOf(shareHolder);
                lpAmount = _userLPAmount[shareHolder];
                if (lpAmount < pairBalance) {
                    pairBalance = lpAmount;
                }

                if (block.timestamp > _lastMineLPRewardTimes[shareHolder] + _mineTimeDebt) {
                    amount = eachMineAmount * pairBalance / totalPair;
                    
                    if (amount > 0) {
                        mineReward[shareHolder] += amount;
                        procesInvitorReward(shareHolder,amount);
                        _lastMineLPRewardTimes[shareHolder] = block.timestamp;
                    }

                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _currentMineLPIndex++;
            iterations++;
        }
        updateMineCycle();
        _progressMineLPBlock = ArbSys(address(100)).arbBlockNumber();
        
    }

    function updateMineCycle() private {
        if(block.timestamp > lastCycleTimestamp + cycleTimeDebt ){
            cycleAmount = _balances[address(mineRewardDistributor)] * 3 / 10;
            cycleMineAmount = cycleAmount * 6 /10;
            cycleInvitorAmount = cycleAmount - cycleMineAmount;
            lastCycleTimestamp = block.timestamp;
        }
        if(block.timestamp > lastEachTimestamp + _mineTimeDebt ){
            eachMineAmount = cycleMineAmount /26;
            eachInvitorAmount = cycleInvitorAmount/26;
            lastEachTimestamp = block.timestamp;
        }


    }


    function procesInvitorReward(address current, uint256 reward) private {

        for (uint256 i; i < 5;i++) {
            address invitor = _inviter[current];
            uint256 invitorAmount;
            uint8 invitorLv = checkMineLv(invitor);
            if (address(0) == invitor || deadAddress == invitor || eachInvitorAmount < eachInvitorMin) {
                break;
            }

            if (i ==0){
                if (invitorLv > 0){
                    invitorAmount = reward * 20 / 100;
                    
                }else{
                    invitorAmount = 0;
                }
            }else if(i ==1){
                if (invitorLv > 1){
                    invitorAmount = reward * 10 / 100;
                }else{
                    invitorAmount = 0;
                }        
            }else if(i ==2){
                if (invitorLv > 2){
                    invitorAmount = reward * 5 / 100;
                }else{
                    invitorAmount = 0;
                }

            
            }else if(i ==3){
                if (invitorLv > 3){
                    invitorAmount = reward * 2 / 100;
                }else{
                    invitorAmount = 0;
                }

            }else {
                if (invitorLv > 4){
                    invitorAmount = reward * 1 / 100;
                }else{
                    invitorAmount = 0;
                }
            }


            if(invitorAmount >0){

                if(eachInvitorAmount - invitorAmount>0){
                    invitorReward[invitor] += invitorAmount;
                    eachInvitorAmount -= invitorAmount;
                    procesUpInvitorReward(invitor,invitorAmount);

                    
                }else{
                    break;
                }


            }

            current = invitor;

        }

    }
    function procesUpInvitorReward(address current, uint256 reward) private {
        address invitor;
        uint256 invitorAmount;

        for (uint256 i; i < 5;i++) {
            invitor = _inviter[current];
            uint8 invitorLv = checkMineLv(invitor);
            
            if (address(0) == invitor || deadAddress == invitor || eachInvitorAmount < eachInvitorMin ||invitorLv ==0) {
                break;
            }
            
            if(invitorLv == 1){
                invitorAmount = reward * 5 / 100;

            }
            else if(invitorLv == 2){
                invitorAmount = reward * 10 / 100;

            }
            else if(invitorLv == 3){
                invitorAmount = reward * 15 / 100;

            }
            else if(invitorLv == 4){
                invitorAmount = reward * 20 / 100;

            }else{
                invitorAmount = reward * 30 / 100;
            }
            
            if(eachInvitorAmount - invitorAmount > 0){
                invitorReward[invitor] += invitorAmount;
                eachInvitorAmount -= invitorAmount;
                reward = invitorAmount;
                current = invitor;

            }else{
                break;
            }

        }

    }

    function getMineReward()external{
        uint256 totalMineReward = mineReward[msg.sender];
        require(totalMineReward > 0);
        address sender = address(mineRewardDistributor);
        uint256 techAmount = totalMineReward * 3/100;
        mineReward[msg.sender] = 0;
        TokenDistributor(sender).claimToken(address(this), fundAddress, techAmount);
        TokenDistributor(sender).claimToken(address(this), msg.sender, totalMineReward - techAmount);
        


    }
    function getInvitorReward()external{
        uint256 totalInvitorReward = invitorReward[msg.sender];
        uint256 availableInvitorReward;
        require(totalInvitorReward > 0);
        address sender = address(mineRewardDistributor);
        uint8 accountrLv = checkMineLv(msg.sender);
        if(accountrLv == 0){
            availableInvitorReward = 0;

        }
        else if(accountrLv == 1){
            if(totalInvitorReward > oneInvitorReward){
                availableInvitorReward = oneInvitorReward;
            }

        }
        else if(accountrLv == 2){
            if(totalInvitorReward > twoInvitorReward){
                availableInvitorReward = twoInvitorReward;
            }

        }
        else if(accountrLv == 3){
            if(totalInvitorReward > threeInvitorReward){
                availableInvitorReward = threeInvitorReward;
            }
        }else if(accountrLv == 4){
            if(totalInvitorReward > fourInvitorReward){
                availableInvitorReward = fourInvitorReward;
            }

        }else{
            availableInvitorReward = totalInvitorReward;
            
        }

        if(availableInvitorReward >0){
            uint256 techAmount = availableInvitorReward * 10 / 100;
            invitorReward[msg.sender] = 0;
            TokenDistributor(sender).claimToken(address(this), deadAddress, techAmount);
            TokenDistributor(sender).claimToken(address(this), msg.sender, availableInvitorReward - techAmount);
        }



    }

    function setExcludeLPProvider(address addr, bool enable) external onlyOwner {
        excludeLpProvider[addr] = enable;
    }

}