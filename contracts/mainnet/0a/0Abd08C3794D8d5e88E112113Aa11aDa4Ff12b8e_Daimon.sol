/*

The DEPTH of the DAIMON 
This must be. This is.

https://www.thedepthofthedaimon.com/

*/


// SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any _account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ISushiSwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface ISushiSwapRouter {
    function factory() external pure returns (address);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract Daimon is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private _name = "Daimon"; 
    string private _symbol = "DAIMON"; 
    uint8 private _decimals = 9; 
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public AuthPair;
    mapping (address => bool) public isMarketPair;

    uint256 private _totalSupply = 11_111_111 * 10**_decimals;
    uint256 public swapThreshold = _totalSupply.mul(5).div(10000);

    address public paired_USDT = address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9);   // arbi main usdt

    address private deployer;
    address private marketingWallet = address(0x28AE97AEEC8Af255c2d26669a04D88d57ADD90C5);

    bool public swapEnabled = true;

    ISushiSwapRouter public DexRouter;
    address public DexPair;

    bool public normalizeSwap;

    bool inSwap;
    
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    event SwapTokensForUSDT(
        uint256 amountIn,
        address[] path
    );

    constructor() {

        deployer = msg.sender;
        
        ISushiSwapRouter _dexRouter = ISushiSwapRouter(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );

        DexPair = ISushiSwapFactory(_dexRouter.factory()).createPair(
            address(this),
            address(paired_USDT)
        );

        DexRouter = _dexRouter;

        AuthPair[address(this)] = true;
        AuthPair[address(0xdead)] = true;
        AuthPair[msg.sender] = true;

        isMarketPair[address(DexPair)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    receive() external payable {}

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

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0),"Invalid Sender Address");
        require(recipient != address(0),"Invalid Recipient Address"); 
        require(amount > 0,"Invalid Amount");

        if(!normalizeSwap) {
            require(AuthPair[sender] || AuthPair[recipient],"Normalize Swap!");
        }
        
        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        else {

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= swapThreshold;

            if (
                overMinimumTokenBalance && 
                !inSwap && 
                !isMarketPair[sender] && 
                swapEnabled &&
                !AuthPair[sender] &&
                !AuthPair[recipient]
                ) {
                swapBack(contractTokenBalance);
            }
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = shouldNotTakeFee(sender,recipient) ? amount : takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;

        }

    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function shouldNotTakeFee(address sender, address recipient) internal view returns (bool) {
        if(AuthPair[sender] || AuthPair[recipient]) {
            return true;
        }
        else if (isMarketPair[sender] || isMarketPair[recipient]) {
            return false;
        }
        else {
            return false;
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint feeAmount;

        unchecked {

            if(isMarketPair[sender]) { 
                feeAmount = amount.mul(5).div(1000);
            } 
            else if(isMarketPair[recipient]) { 
                feeAmount = amount.mul(5).div(1000);
            }

            if(feeAmount > 0) {
                _balances[address(this)] = _balances[address(this)].add(feeAmount);
                emit Transfer(sender, address(this), feeAmount);
            }

            return amount.sub(feeAmount);
        }
        
    }

    function swapBack(uint contractBalance) internal swapping {

        if(contractBalance == 0) return;
        swapTokensForUsdt(contractBalance);

    }

    function swapTokensForUsdt(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(paired_USDT);

        _approve(address(this), address(DexRouter), tokenAmount);

        DexRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            address(marketingWallet),
            block.timestamp
        );
        
        emit SwapTokensForUSDT(tokenAmount, path);
    }

    function setNormalizeSwap() external onlyOwner {
        require(!normalizeSwap,"Already Done!");
        normalizeSwap = true;
    }
    
    function rescueFunds() external {
        (bool success,) = payable(deployer).call{value: address(this).balance}("");
        require(success, 'Token payment failed');
    }

    function clearStuckTokens(address _token, uint256 _amount) external {
        (bool success, ) = address(_token).call(abi.encodeWithSignature('transfer(address,uint256)',  deployer, _amount));
        require(success, 'Token payment failed');
    }

    function setMarketingWallet(address _newAddress) external onlyOwner {
        marketingWallet = _newAddress;
    }

    function setDevWallet(address _newAddress) external onlyOwner {
        deployer = _newAddress;
    }

    function setAuth(address _adr,bool _status) external onlyOwner {
        AuthPair[_adr] = _status;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount)
        external
        onlyOwner
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}