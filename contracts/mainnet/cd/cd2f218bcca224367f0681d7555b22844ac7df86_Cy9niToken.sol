/**
 *Submitted for verification at Arbiscan on 2023-07-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol


interface IUniswapV2Router02 is IUniswapV2Router01 {
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
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}




contract Cy9niToken is  IERC20, Ownable {

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => uint256) private _isBought;
   

    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1e12 * 1e9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private constant MAX_COOLDOWN = 120 seconds;

    string private constant _name = "cy9ni";
    string private constant _symbol = "C9";
    uint8 private constant _decimals = 8;

    struct Fee {
        uint16 teamFee;
        uint16 treasuryFee;
        uint16 taxFee;
        uint16 appPot;
    }

    Fee public buyFee;
    Fee public sellFee;
    Fee public transferFee;

    uint16 private _taxFee;
    uint16 private _teamFee;
    uint16 private _treasuryFee;
    uint16 private _potFee;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    address public teamWallet = 0x23395966Bcf6d99ebD9c13333Dded70CFec57926;
    address public treasuryWallet = 0x953913d214a62f72d189b8665881Ce2EBD9e6cC4;
    address public potWallet = 0x8F65B922264F754FBEf0dADc5274fe9052dC96bd;

    uint256 public coolDown;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;
   

            
            ///events
    event MaxWalletAmountUpdated (uint256 amount);
    event MaxBuyAmountPerTxUpdated (uint256 amount);
    event MaxSellAmountPerTxUpdated (uint256 amount);
    event CooldownUpdated(uint256 time);
           
           ///Custom Errors//
    error ERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);
    error ERC20InsufficientAllowance(address spender, uint256 currentAllowance, uint256 amount);
    error CoolDownLimitExceeded (uint256 limit);
    error ExcludedWalletNotAllowed();
    error AlreadyExcluded();
    error AlreadyIncluded();
    error MaxFeeLimitReached();
    error AmountMustBeLessThanTotalSupply();
    error AmountMustBeLessThanTotalReflections();
    error AlreadySameAddress();
    error MaxBuyValueTooLow();
    error MaxSellValueTooLow();
    error MaxWalletValueTooLow();
    error CoolDownEnabled();
    error BalanceExceedsMaxWalletLimit();
    error BuyPerTxLimitExceeds();
    error SellPerTxLimitExceeds();
    error TransferFromZeroAddress();
    error TransferToZeroAddress();

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        buyFee.treasuryFee = 5;
        buyFee.taxFee = 40;
        buyFee.appPot = 5;

        sellFee.treasuryFee = 5;
        sellFee.taxFee = 40;
        sellFee.appPot = 5;

        transferFee.treasuryFee = 5;
        transferFee.taxFee = 40;
        transferFee.appPot = 5;
        
        ///Sushiswap  Router on Arbitrum One
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
        );
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcluded[address(0xdead)] = true;
        coolDown = 120 seconds; // 120 seconds cooldown period

        maxSellAmount = (totalSupply() * 125) /  (100000); // 0.125% of the supply per transaction
        maxBuyAmount = (totalSupply() * 125) /  (100000); //  0.125% of the supply per transaction
        maxWalletAmount = (totalSupply() * 5) /  (1000);  // 0.5% of the supply per wallet limit

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
    
     /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
     /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }
    

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    

     /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
     /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

     /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

     /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `requestedDecrease`.
     */
    function decreaseAllowance(address spender, uint256 requestedDecrease) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < requestedDecrease) {
            revert ERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
        }
        unchecked {
            _approve(owner, spender, currentAllowance - requestedDecrease);
        }

        return true;
    }

   
   /**@notice function to change the cooldown period in seconds 
     *
     */
    function setCooldown(uint256 timeInSeconds) external onlyOwner {
        if (timeInSeconds > MAX_COOLDOWN) {
            revert CoolDownLimitExceeded(MAX_COOLDOWN);
        }
        coolDown = timeInSeconds;
        emit CooldownUpdated (timeInSeconds);
    }

    /**@notice function returns wthether a particular address is excluded from reflection or not. 
     *
     */

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        if(_isExcluded[sender]){
            revert ExcludedWalletNotAllowed();
        }
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rTotal = _rTotal - (rAmount);
        _tFeeTotal = _tFeeTotal + (tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        if(tAmount > _tTotal){
           revert AmountMustBeLessThanTotalSupply();
        }
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        if(rAmount > _rTotal){
           revert AmountMustBeLessThanTotalReflections();
            }
        uint256 currentRate = _getRate();
        return rAmount /  (currentRate);
    }

                    //Functions to Exclude /Include a particular address from reflection

    function excludeFromReward(address account) public onlyOwner {
        if(_isExcluded[account]){
            revert AlreadyExcluded();
        }
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
         if(!_isExcluded[account]){
            revert AlreadyIncluded();
        } 
          for (uint256 i = 0; i < _excluded.length; i++) {

           if (_excluded[i] == account){ 
            //updating _rOwned to make sure the balances stay the same
            if (_tOwned [account] > 0) {
                uint256 newrOwned = _tOwned [account] * (_getRate());
                _rTotal = _rTotal - (_rOwned [account]-newrOwned);
                _rOwned[account] = newrOwned;
                } 
                else{
               _rOwned [account] = 0;
                }
               _tOwned[account]= 0;
               _excluded [i] = _excluded [_excluded.length-1];
               _isExcluded [account] = false;
               _excluded.pop();
               break;
            }
        }
    }

                     // Whitelist the address from taxes
    function excludeFromFee(address account) external onlyOwner {
        if(_isExcludedFromFee[account]){
            revert AlreadyExcluded();
        }
        _isExcludedFromFee[account] = true;
    }
    
                    //removing address from Whiteslist to pay normal tax
    function includeInFee(address account) external onlyOwner {
       if(!_isExcludedFromFee[account]){
        revert AlreadyIncluded();
       }
        _isExcludedFromFee[account] = false;
    }
                     //FEE SETTER FUNCTIONS
    function setBuyFee(
        uint16 treasury,
        uint16 team,
        uint16 tax,
        uint16 apot
    ) external onlyOwner {
        buyFee.treasuryFee = treasury;
        buyFee.teamFee = team;
        buyFee.taxFee = tax;
        buyFee.appPot = apot;

        uint256 totalBuyFee = treasury + team + tax + apot;
        if(totalBuyFee > 100){
            revert MaxFeeLimitReached();
        }
    }

    function setSellFee(
        uint16 team,
        uint16 treasury,
        uint16 tax,
        uint16 apot
    ) external onlyOwner {
        sellFee.teamFee = team;
        sellFee.treasuryFee = treasury;
        sellFee.taxFee = tax;
        sellFee.appPot = apot;
        uint256 totalSellFee = treasury + team + tax + apot;
         if(totalSellFee > 100){
            revert MaxFeeLimitReached();
        }
    }

    function setTransferFee(
        uint16 team,
        uint16 teasury,
        uint16 tax,
        uint16 apot
    ) external onlyOwner {
        transferFee.teamFee = team;
        transferFee.treasuryFee = teasury;
        transferFee.taxFee = tax;
        transferFee.appPot = apot;
        uint256 totalTransferFee = team + teasury + tax + apot;
        if(totalTransferFee > 100){
            revert MaxFeeLimitReached();
        }
    }

                      //Function to update Router
    function updateRouter(address newAddress) external onlyOwner {
       if(newAddress == address(uniswapV2Router)) {
          revert AlreadySameAddress();
       }
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address get_pair = IUniswapV2Factory(uniswapV2Router.factory()).getPair(
            address(this),
            uniswapV2Router.WETH()
        );
        if (get_pair == address(0)) {
            uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
                .createPair(address(this), uniswapV2Router.WETH());
        } else {
            uniswapV2Pair = get_pair;
        }
    }

            //Max Wallet, Max Buy per transaction, Max Sell per transaction setter                  
    function setMaxWallet(uint256 value) external onlyOwner {
        if (value < totalSupply()/200){
            revert MaxWalletValueTooLow();
        }
        maxWalletAmount = value;
        emit MaxWalletAmountUpdated(maxWalletAmount);
    }

    function setMaxBuyAmount(uint256 value) external onlyOwner {
        if (value < totalSupply()/1000){
            revert MaxBuyValueTooLow();
        }
        maxBuyAmount = value;
        emit MaxBuyAmountPerTxUpdated(maxBuyAmount);
    }

    function setMaxSellAmount(uint256 value) external onlyOwner {
         if (value < totalSupply()/1000){
            revert MaxSellValueTooLow();
        }
        maxSellAmount = value;
        emit MaxSellAmountPerTxUpdated(maxSellAmount);
    }

    modifier notZeroAddress(address _address) {
      require(_address != address(0), "Address must not be zero");
      _;
    }                        
                            //Wallet Setters //
    function setTreasuryWallet(address payable wallet) external notZeroAddress(wallet) onlyOwner {
        treasuryWallet = wallet;
    }

    function setTeamWallet(address payable wallet) external notZeroAddress(wallet) onlyOwner {
        teamWallet = wallet;
    }

    function setPotWallet(address payable wallet) external notZeroAddress(wallet) onlyOwner {
        potWallet = wallet;
    }

                                 //Claim ETH OR ERC20 tokens                                  
    function claimStuckedTokens(address token) external  onlyOwner returns (bool) {
       
        if (token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
           
        } else if (token == address(this)){
            _transfer(address(this), owner(), balanceOf(address(this)));
        } else {

        IERC20 erc20token = IERC20(token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
        
        }
        return true;
    }

    
    receive() external payable {
        this;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam,
            uint256 tTreasury,
            uint256 tPot
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tTeam,
            tTreasury,
            tPot,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tTeam
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTeam = calculateTeamFee(tAmount);
        uint256 tTreasury = calculateTreasuryFee(tAmount);
        uint256 tPot = calculatePotFee(tAmount);
        uint256 tTransferAmount = tAmount - (tFee) - (tTeam);
        tTransferAmount = tTransferAmount - (tTreasury) - (tPot);
        return (tTransferAmount, tFee, tTeam, tTreasury, tPot);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 tTreasury,
        uint256 tPot,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee * (currentRate);
        uint256 rTeam = tTeam * (currentRate);
        uint256 rTreasury = tTreasury * (currentRate);
        uint256 rPot = tPot * (currentRate);
        uint256 rTransferAmount = rAmount
             - (rFee)
             - (rTeam)
             - (rTreasury)
             - (rPot);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply /  (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal /  (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeTeam(uint256 tTeam) private {
        if (tTeam > 0) {
            uint256 currentRate = _getRate();
            uint256 rTeam = tTeam * (currentRate);
            _rOwned[teamWallet] = _rOwned[teamWallet] + (rTeam);
            if (_isExcluded[teamWallet])
                _tOwned[teamWallet] = _tOwned[teamWallet] + (tTeam);
            
        }
    }

    function _takeTreasuryAndPot(uint256 tTreasury, uint256 tPot) private {
        if (tTreasury > 0 || tPot > 0) {
            uint256 currentRate = _getRate();
            uint256 rTreasury = tTreasury * (currentRate);
            uint256 rPot = tPot * (currentRate);

            _rOwned[treasuryWallet] = _rOwned[treasuryWallet] + (rTreasury);
            _rOwned[potWallet] = _rOwned[potWallet] + (rPot);
            if (_isExcluded[treasuryWallet]) {
                _tOwned[treasuryWallet] = _tOwned[treasuryWallet] + (tTreasury);
            }
            if (_isExcluded[potWallet]) {
                _tOwned[potWallet] = _tOwned[potWallet] + (tPot);
            }

            
        }
    }

    function calculateTaxFee(uint256 amount) private view returns (uint256) {
        return (amount * _taxFee) /  (10**3);
    }

    function calculateTeamFee(uint256 amount)
        private
        view
        returns (uint256)
    {
        return (amount * _teamFee) /  (10**3);
    }

    function calculateTreasuryFee(uint256 amount)
        private
        view
        returns (uint256)
    {
        return (amount * _treasuryFee) /  (10**3);
    }

    function calculatePotFee(uint256 amount) private view returns (uint256) {
        return (amount * _potFee) /  (10**3);
    }



    function removeAllFee() private {
        _taxFee = 0;
        _teamFee = 0;
        _treasuryFee = 0;
        _potFee = 0;
    }

    function setBuy() private {
        _taxFee = buyFee.taxFee;
        _teamFee = buyFee.teamFee;
        _treasuryFee = buyFee.treasuryFee;
        _potFee = buyFee.appPot;
    }

    function setSell() private {
        _taxFee = sellFee.taxFee;
        _teamFee = sellFee.teamFee;
        _treasuryFee = sellFee.treasuryFee;
        _potFee = sellFee.appPot;
    }

    function setTransfer() private {
        _taxFee = transferFee.taxFee;
        _teamFee = transferFee.teamFee;
        _treasuryFee = transferFee.treasuryFee;
        _potFee = transferFee.appPot;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    
     /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        if(from == address(0)) {revert TransferFromZeroAddress();}
        if(to == address(0)) {revert TransferToZeroAddress();}
      
        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        removeAllFee();

        if (takeFee) {
            if (recipient != uniswapV2Pair) {
                if(
                    balanceOf(recipient) + amount > maxWalletAmount){
                        revert BalanceExceedsMaxWalletLimit();
                    }
                    
            }
            if (sender == uniswapV2Pair) {
               if (amount > maxBuyAmount){
                  revert BuyPerTxLimitExceeds();
               }

                _isBought[recipient] = block.timestamp;
                setBuy();
            }
            if (recipient == uniswapV2Pair) {
                 if (amount > maxSellAmount){
                    revert SellPerTxLimitExceeds();
                }
                if(
                      coolDown > block.timestamp - _isBought[sender]){
                        revert CoolDownEnabled();
                      }
                    
                setSell();
            }
            if (sender != uniswapV2Pair && recipient != uniswapV2Pair) {
                setTransfer();
            }
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeTeam(tTeam);
        _takeTreasuryAndPot(
            calculateTreasuryFee(tAmount),
            calculatePotFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeTeam(tTeam);
        _takeTreasuryAndPot(
            calculateTreasuryFee(tAmount),
            calculatePotFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeTeam(tTeam);
        _takeTreasuryAndPot(
            calculateTreasuryFee(tAmount),
            calculatePotFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeTeam(tTeam);
        _takeTreasuryAndPot(
            calculateTreasuryFee(tAmount),
            calculatePotFee(tAmount)
        );
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}