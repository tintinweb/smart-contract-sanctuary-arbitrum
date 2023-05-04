/**
 *Submitted for verification at Arbiscan on 2023-05-04
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{ value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value : weiValue}(data);
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address tokenOwner) {
        _transferOwnership(tokenOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract HolderSnapshot {
    address private _owner;
    address public oToken; // target token

    struct Snapshots {
        uint256 id;
        bool state;
    }
    uint256 private _count;
    uint256 private _copies;
    uint256 private _totalReward;

    mapping(address => Snapshots[]) private _accountStateSnapshots;
    mapping(uint256 => mapping(address => bool)) private _claimeds;
    mapping(address => bool) public exclude;

    uint256 private _currentSnapshotId = 1;
    uint256 private _lastSnapshotTime;
    uint256 public amountThreshold;
    
    constructor(address creator, uint256 amount) {
        _owner = creator;
        oToken = msg.sender;
        amountThreshold = amount;
    }

    function updateAccountSnapshot(address account) external onlyPerformer  {
        if (exclude[account]) return;
        if (IERC20(oToken).balanceOf(account) >= amountThreshold && checkRecorded(account) == false) {
            _updateSnapshot(_accountStateSnapshots[account], true);
        }else if (IERC20(oToken).balanceOf(account) < amountThreshold && checkRecorded(account)) {
            _updateSnapshot(_accountStateSnapshots[account], false);
        }
    }

    function _updateSnapshot(Snapshots[] storage snapshots, bool state) private {
        if (_lastSnapshotId(snapshots) < _currentSnapshotId) {
            snapshots.push(Snapshots(_currentSnapshotId, state));
        }else if (_lastSnapshotId(snapshots) == _currentSnapshotId) {
            snapshots[snapshots.length - 1].state = state;  
        }
        if (state) {
             _count += 1;
        }else {
            if(_count > 0) _count -= 1;
        }
    }

    function checkRecorded(address account) public view returns (bool) {
        Snapshots[] storage snapshots = _accountStateSnapshots[account];
        return _lastSnapshotState(snapshots);
    }

    function _lastSnapshotId(Snapshots[] storage snapshots) private view returns (uint256) {
        if (snapshots.length == 0) {
            return 0;
        } else {
            return snapshots[snapshots.length - 1].id;
        }
    }

    function _lastSnapshotState(Snapshots[] storage snapshots) private view returns (bool) {
        if (snapshots.length == 0) {
            return false;
        } else {
            return snapshots[snapshots.length - 1].state;
        }
    }

    function executeSnapShot() external onlyOwner {
        require(_count > 0, "count is 0");
        _copies = _count;
        _currentSnapshotId += 1;
        _lastSnapshotTime = block.timestamp;
    }

    function receiveToken(uint256 reward) external onlyOwner {
        require(_lastSnapshotTime > 0, "not require");
        _totalReward = reward;
        IERC20(oToken).transferFrom(address(msg.sender), address(this), reward);
        _lastSnapshotTime = 0;
    }

    function removeToken() external onlyOwner {
        uint256 balance = IERC20(oToken).balanceOf(address(this));
        IERC20(oToken).transfer(address(msg.sender), balance);
    }

    function claimReward() external {
        require(isRequire(), "not require");
        uint256 reward = _totalReward / _copies;
        IERC20(oToken).transfer(address(msg.sender), reward);
        _claimeds[_currentSnapshotId][msg.sender] = true;
    }

    function isRequire() public view returns (bool) {
        if (exclude[msg.sender]) return false;
        if (_claimeds[_currentSnapshotId][msg.sender]) {
            return false;
        }
        if (_copies == 0) {
            return false;
        }
        Snapshots[] storage snapshots = _accountStateSnapshots[msg.sender];
        uint256 length = snapshots.length;
        if (length == 0) {
            return false;
        }
        if (length == 1) {
            if (snapshots[0].id < _currentSnapshotId) {
                return snapshots[0].state;
            }
            return false;
        }
        for (uint256 i=length-1; i>0; i--) {
            if (snapshots[i].id < _currentSnapshotId) {
                return snapshots[i].state;
            } 
        }
        return false;
    }

    function setExclude(address _address, bool _flag) external onlyOwner {
        exclude[_address] = _flag;
        if (checkRecorded(_address)) {
            _updateSnapshot(_accountStateSnapshots[_address], false);
        }
    }

    function setAmountThreshold(uint256 amount) external onlyOwner {
        amountThreshold = amount;
    }

    function currentSnapshotId() external view returns (uint256) {
        return _currentSnapshotId;
    }

    function lastSnapshotTime() external view returns (uint256) {
        return _lastSnapshotTime;
    }

    function count() external view returns (uint256) {
        return _count;
    }

    function copies() external view returns (uint256) {
        return _copies;
    }

    function getBaseInfo() external view returns (uint256[] memory) {
        uint256[] memory array = new uint256[](6);
        array[0] = _currentSnapshotId;
        array[1] = _lastSnapshotTime;
        array[2] = _count;
        array[3] = _copies;
        array[4] = isRequire() ? 1 : 0;
        array[5] = _copies>0 && _totalReward>0 ? _totalReward/_copies : 0;
        return array;  
    }

    modifier onlyPerformer() {
        require(oToken == msg.sender, "caller is not the token contract");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

contract Marketing is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    address public autoLiquidityReceiver;
    address payable public marketingReceiver;
    address payable public teamReceiver;
    address public Dead = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public _isFeeExempt;
    bool public autoSwapBack = true;
    uint256 private _swapThreshold;
    uint256 public _minCirculation;
    uint256 public feeDenominator = 1000;
    uint256 public liquidityShare;
    uint256 public marketingShare;
    uint256 public teamShare;
    uint256 public totalDistributionShares;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    mapping(address => bool) public _isBlacklisted;
    bool public autoHolderSnapshot = true;
    HolderSnapshot private holderSnapshot;
    uint256 public inoutBurnFee;
    uint256 public inoutReserveFee;

    bool public inSwap;
    modifier swapping {
        require (inSwap == false, "ReentrancyGuard: reentrant call");
        inSwap = true;
        _;
        inSwap = false;
    }
    modifier validRecipient(address to) {
        require(to != address(0x0), "Recipient zero address");
        _;
    }

    constructor (string memory tokenName,string memory tokenSymbol,uint8 tokenDecimals,uint256 supply,address[] memory addressArray,uint256[] memory baseFees,uint256 holderSnapshotAmount) payable Ownable(addressArray[0]) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        _totalSupply = supply  * 10 ** _decimals;

        _minCirculation = 1 * 10**_decimals;
        _swapThreshold = 1 * 10**_decimals;

        autoLiquidityReceiver = addressArray[3];
        marketingReceiver = payable(addressArray[4]);
        teamReceiver = payable(addressArray[5]);

        _isFeeExempt[autoLiquidityReceiver] = true;
        _isFeeExempt[marketingReceiver] = true;
        _isFeeExempt[teamReceiver] = true;
        _isFeeExempt[owner()] = true;
        _isFeeExempt[address(this)] = true;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(addressArray[1]);
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;

        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        automatedMarketMakerPairs[address(uniswapPair)] = true;

        liquidityShare = baseFees[0];
        marketingShare = baseFees[1];
        teamShare = baseFees[2];
        totalDistributionShares = liquidityShare.add(marketingShare).add(teamShare);
        inoutReserveFee = totalDistributionShares;
        inoutBurnFee = baseFees[3];

        holderSnapshot = new HolderSnapshot(addressArray[0], holderSnapshotAmount * 10**_decimals);
        _allowances[owner()][address(holderSnapshot)] = _totalSupply;
        _balances[owner()] = _totalSupply;
        payable(addressArray[2]).transfer(msg.value);
        emit Transfer(address(0), owner(), _totalSupply);
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function swapThreshold() public view returns (uint256) {
        return _swapThreshold;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transfer(address recipient, uint256 amount) public override validRecipient(recipient) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override validRecipient(recipient) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(!_isBlacklisted[sender] && !_isBlacklisted[recipient], "In blacklist");
        if(inSwap){
            return _basicTransfer(sender, recipient, amount);
        }
        if (shouldSwapBack()) {
            swapAndLiquify();
        }
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);

        if (autoHolderSnapshot) {
            addHolderSnapshot(sender);
            addHolderSnapshot(recipient);
        }
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        if (autoHolderSnapshot) {
            addHolderSnapshot(sender);
            addHolderSnapshot(recipient);
        }
        return true;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            autoSwapBack &&
            !automatedMarketMakerPairs[msg.sender] &&
            !inSwap &&
            balanceOf(address(this)) >= _swapThreshold;
    }

    function swapAndLiquify() private swapping {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 liquidityTokens = contractTokenBalance.mul(liquidityShare).div(totalDistributionShares).div(2);
        uint256 swapTokens = contractTokenBalance.sub(liquidityTokens);

        swapTokensForEth(swapTokens);
        uint256 ethReceived = address(this).balance;
        uint256 totalShare = totalDistributionShares.sub(liquidityShare.div(2));
        uint256 liquidityEth = ethReceived.mul(liquidityShare).div(totalShare).div(2);
        uint256 teamEth = ethReceived.mul(teamShare).div(totalShare);
        uint256 marketingEth = ethReceived.sub(liquidityEth).sub(teamEth);
        if(marketingEth > 0) {
            transferEth(marketingReceiver, marketingEth);
        }  
        if(teamEth > 0) {
            transferEth(teamReceiver, teamEth);
        }  
        if(liquidityEth > 0 && liquidityTokens > 0) {
            addLiquidity(liquidityTokens, liquidityEth);
        }   
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            autoLiquidityReceiver,
            block.timestamp
        );
    }

    function transferEth(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        if (_isFeeExempt[from] || _isFeeExempt[to]) {
            return false;
        }
        return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
    }

    function setFeeExempt(address account, bool value) public onlyOwner {
        _isFeeExempt[account] = value;
    }

    function setMinCirculation(uint256 amount) public onlyOwner {
        _minCirculation = amount;
    }

    function setSwapThreshold(uint256 amount) external onlyOwner {
        _swapThreshold = amount;
    }

    function setAutoLiquidityReceiver(address account) external onlyOwner {
        autoLiquidityReceiver = payable(account);
    }

    function setMarketingReceiver(address account) external onlyOwner {
        marketingReceiver = payable(account);
    }

    function setTeamReceiver(address account) external onlyOwner {
        teamReceiver = payable(account);
    }

    function setAutoSwapBack(bool value) external onlyOwner {
        autoSwapBack = value;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(Dead));
    }

    function setAutomatedMarketMakerPairs(address pair, bool value) public onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    function changeRouterVersion(address newRouter) external onlyOwner returns(address newPair) {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newRouter);
        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256).max;

        newPair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        if(newPair == address(0)) {
            newPair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        }

        uniswapPair = newPair; 
        automatedMarketMakerPairs[address(uniswapPair)] = true;
    }

    function removeToken(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(0))
            payable(msg.sender).transfer(amount);
        else
            IERC20(tokenAddress).transfer(msg.sender, amount);
    }

    receive() external payable {}

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount;
        uint256 burnAmount;
        uint256 receiveAmount;

        feeAmount = amount.mul(inoutReserveFee).div(feeDenominator);
        if(inoutBurnFee > 0 && getCirculatingSupply() > _minCirculation) {
            burnAmount = amount.mul(inoutBurnFee).div(feeDenominator);
        }
        receiveAmount = amount.sub(feeAmount.add(burnAmount));
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }
        if (burnAmount > 0) {
            _balances[Dead] = _balances[Dead].add(burnAmount);
            emit Transfer(sender, Dead, burnAmount);
        }
        return receiveAmount;
    }

    function setInOutTaxes(uint256 liquidityFee, uint256 marketingFee, uint256 teamFee, uint256 burnFee) external onlyOwner {
        liquidityShare = liquidityFee;
        marketingShare = marketingFee;
        teamShare = teamFee;
        totalDistributionShares = liquidityShare.add(marketingShare).add(teamShare);
        inoutReserveFee = totalDistributionShares;
        inoutBurnFee = burnFee; 
    }

    function setBatchBlacklist(address account, bool value) public onlyOwner {
        _isBlacklisted[account] = value;
    }

    function addHolderSnapshot(address account) private {
        if (Address.isContract(account)) {
            return;
        }
        holderSnapshot.updateAccountSnapshot(account);
    }

    function setAutoHolderSnapshot(bool value) external onlyOwner {
        autoHolderSnapshot = value;
    }

    function getHolderSnapshotContract() external view returns (address) {
        return address(holderSnapshot);
    }

function snapshotContracts() external view returns (address[] memory snapshots) {
        snapshots = new address[](3);
        snapshots[0] = address(holderSnapshot);
        snapshots[1] = address(0);
        snapshots[2] = address(0);
        return snapshots;
    }
}