/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

/**
 * KushAlienz v1.0
 * designed and engineered by Jscrui && Tiboo.
 * author: 0xJscrui & Tiboo.
 * website: https://kushalienz.com
 * telegram: @kushalienz
 *
 *   /$$                           /$$                 /$$ /$$                              
 *  | $$                          | $$                | $$|__/                              
 *  | $$   /$$ /$$   /$$  /$$$$$$$| $$$$$$$   /$$$$$$ | $$ /$$  /$$$$$$  /$$$$$$$  /$$$$$$$$
 *  | $$  /$$/| $$  | $$ /$$_____/| $$__  $$ |____  $$| $$| $$ /$$__  $$| $$__  $$|____ /$$/
 *  | $$$$$$/ | $$  | $$|  $$$$$$ | $$  \ $$  /$$$$$$$| $$| $$| $$$$$$$$| $$  \ $$   /$$$$/ 
 *  | $$_  $$ | $$  | $$ \____  $$| $$  | $$ /$$__  $$| $$| $$| $$_____/| $$  | $$  /$$__/  
 *  | $$ \  $$|  $$$$$$/ /$$$$$$$/| $$  | $$|  $$$$$$$| $$| $$|  $$$$$$$| $$  | $$ /$$$$$$$$
 *  |__/  \__/ \______/ |_______/ |__/  |__/ \_______/|__/|__/ \_______/|__/  |__/|________/
 *
 * SPDX-License-Identifier: MIT
 *
 * Tokenomics:
 *
 * UFOPool          2%
 * Marketing        2%
 * Liquidity        1%
 * Developer        1%
 *
 * Total Supply: 1.000.000 KALIEN
 * Max Buy: 1 % of Total Supply
 * Max Sell: 0.5 % of Total Supply
 * Max Hold: 3% Total Supply
 */


pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

contract KushAlienz is ERC20, Ownable{
    using Address for address payable;
     
    IRouter public router;
    address public pair;
    
    bool private _liquidityMutex = false;
    bool public providingLiquidity = false;
    bool public tradingEnabled = false;
    
    uint256 public tokenLiquidityThreshold = 500 * 1e18; //500 tokens = 0.05% of Total Supply
    uint256 public maxBuyLimit = 10_000 * 1e18; //10000 tokens = 1% Total Supply
    uint256 public maxSellLimit = 5_000 * 1e18; //5000 tokens = 0.5% Total Supply
    uint256 public maxWalletLimit = 15_000 * 1e18; //30000 tokens = 3% MTotalax Supply

    uint256 public genesis_block;
    
    address public routerAddress = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; //Arbitrum Nitro Router

    address public marketingAddress = 0x66b0B142D99cAF9d676A1511f7629fD4Bf215BCA; //Marketing Address
    address public devAddress = 0x874c9d2C94662A679446236550294419891E4377; //Dev Address
    address public UFOPoolAddress; 
    
    struct Taxes {
        uint256 marketing; 
        uint256 liquidity;
        uint256 UFOPool;
        uint256 dev;
    }
    
    Taxes public taxes = Taxes(2, 1, 2, 1);
    Taxes public sellTaxes = Taxes(2, 1, 2, 1);
    
    mapping (address => bool) public exemptFee;
    mapping (address => bool) public isBlacklisted;
    mapping (address => bool) public allowedTransfer;
    
    // AntiDump 
    mapping(address => uint256) private _lastSell;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 120 seconds;
    
    // Antibot 
    modifier antiBot(address account){
        require(tradingEnabled || allowedTransfer[account], "KushAlienz: Trading disabled.");
        _;
    }
    
    // Antiloop 
    modifier mutexLock() {
        if (!_liquidityMutex) {
            _liquidityMutex = true;
            _;
            _liquidityMutex = false;
        }
    }
    
    constructor() ERC20("KUSH ALIENZ", "KALIEN") {
        //Mint tokens
        _mint(msg.sender, 1e6 * 1e18);
        
        //Define Router
        IRouter _router = IRouter(routerAddress);

        //Create a pair for this new token
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        
        //Define router and pair to variables
        router = _router;
        pair = _pair;
        
        //Add exceptions
        exemptFee[msg.sender] = true;
        exemptFee[address(this)] = true;
        exemptFee[marketingAddress] = true;
        exemptFee[devAddress] = true;
        exemptFee[UFOPoolAddress] = true;        
        
        //Add allows
        allowedTransfer[address(this)] = true;
        allowedTransfer[owner()] = true;
        allowedTransfer[pair] = true;
        allowedTransfer[marketingAddress] = true;
        allowedTransfer[devAddress] = true;
        allowedTransfer[UFOPoolAddress] = true;        
                
    }

    function startTrading() external onlyOwner{
        tradingEnabled = true;
        providingLiquidity = true;
    }
    
    function approve(address spender, uint256 amount) public override antiBot(msg.sender) returns(bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override antiBot(sender) returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override antiBot(msg.sender) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override antiBot(msg.sender) returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }
    
    function transfer(address recipient, uint256 amount) public override antiBot(msg.sender) returns (bool) { 
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "KushAlienz: Transfer amount must be greater than zero");
        require(!isBlacklisted[sender] && !isBlacklisted[recipient], "KushAlienz: Blacklisted");

        if(recipient == pair && genesis_block == 0) genesis_block = block.number;
        
        if(!exemptFee[sender] && !exemptFee[recipient]){
            require(tradingEnabled, "KushAlienz: Trading disabled");
        }
        
        if(sender == pair && !exemptFee[recipient] && !_liquidityMutex){
            require(amount <= maxBuyLimit, "KushAlienz: Exceeding max buy limit");
            require(balanceOf(recipient) + amount <= maxWalletLimit, "KushAlienz: Exceeding max hold limit");
        }
        
        if(sender != pair && !exemptFee[recipient] && !exemptFee[sender] && !_liquidityMutex){
            require(amount <= maxSellLimit, "KushAlienz: Exceeding max sell limit");
            
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWalletLimit, "KushAlienz: Exceeding max wallet limit");
            }
            
            if(coolDownEnabled){
                uint256 timePassed = block.timestamp - _lastSell[sender];
                require(timePassed >= coolDownTime, "KushAlienz: Cooldown enabled");
                _lastSell[sender] = block.timestamp;
            }
        }
        
        uint256 feeswap;         
        uint256 fee;

        Taxes memory currentTaxes;

        if(!exemptFee[sender] && !exemptFee[recipient] && block.number <= genesis_block + 9) {
            require(recipient != pair, "KushAlienz: Sells not allowed in first 9 blocks");
        }
        
        //Set fee to 0 if fees in contract are Handled or Exempted
        if (_liquidityMutex || exemptFee[sender] || exemptFee[recipient]){
            fee = 0;
        }else if(recipient == pair){
            feeswap = sellTaxes.liquidity + sellTaxes.marketing + sellTaxes.dev + sellTaxes.UFOPool;             
            currentTaxes = sellTaxes;
        }else{
            feeswap =  taxes.liquidity + taxes.marketing + taxes.dev + taxes.UFOPool;             
            currentTaxes = taxes;
        }
        
        // Fee -> total amount of tokens to be substracted
        fee = amount * feeswap / 100;

        // Send Fee if threshold has been reached && don't do this on buys, breaks swap.
        if (providingLiquidity && sender != pair && feeswap > 0){ 
            handle_fees(feeswap, currentTaxes);
        }

        //Rest to tx Recipient
        super._transfer(sender, recipient, amount - fee);
    
        if(fee > 0){
            //Send the fee to the contract
            if (feeswap > 0) {
                uint256 feeAmount = amount * feeswap / 100;
                super._transfer(sender, address(this), feeAmount);
            }
        }

    }

    function handle_fees(uint256 feeswap, Taxes memory swapTaxes) private mutexLock {
        
        uint256 tokenBalance = balanceOf(address(this));

        if (tokenBalance >= tokenLiquidityThreshold) {
        
            //Check if threshold is 0 and set it to balance
            if(tokenLiquidityThreshold != 0){
                    tokenBalance = tokenLiquidityThreshold;
            }
                                    
            // Token distribution
            uint256 liquidityTokens = swapTaxes.liquidity * tokenBalance / feeswap;
            uint256 marketingTokens = swapTaxes.marketing * tokenBalance / feeswap;
            uint256 devTokens = swapTaxes.dev * tokenBalance / feeswap;
            uint256 UFOPoolTokens = tokenBalance - liquidityTokens - marketingTokens - devTokens;

            //Split the liquidity tokens into halves
            uint256 half = liquidityTokens / 2;

            //Swap all and save half to add liquidity ETH / Tokens
            uint256 toSwap = tokenBalance - half;
            
            //Save inital ETH balance
            uint256 initialBalance = address(this).balance;
            
            //Swap
            swapTokensForETH(toSwap);

            //Swapped ETH 
            uint256 afterBalance = address(this).balance - initialBalance;
            
            //ETH to add liquidity
            uint256 liquidityETH = half * afterBalance / toSwap;

            //Add liquidity
            if(liquidityETH > 0){
                addLiquidity(half, liquidityETH);
            }
            
            //Send ETH to wallets
            uint256 marketingAmt = marketingTokens * afterBalance / toSwap;
                if(marketingAmt > 0){
                    payable(marketingAddress).sendValue(marketingAmt);
                }
                
            uint256 devAmt = devTokens * afterBalance / toSwap;
                if(devAmt > 0){
                    payable(devAddress).sendValue(devAmt);
                }
                    
            uint256 poolAmt = UFOPoolTokens * afterBalance / toSwap;
                if(poolAmt > 0){
                    payable(UFOPoolAddress).sendValue(poolAmt);
                }
                            
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private {        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);
        
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(router), tokenAmount);

        router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, owner(), block.timestamp);
    }

    function setLiquidityProvide(bool _state) external onlyOwner {        
        providingLiquidity = _state;
    }

    function setLiquidityThreshold(uint256 _newLiquidityThreshold) external onlyOwner {        
        require(_newLiquidityThreshold != 0, "KushAlienz: Liquidity threshold can't be 0");
        tokenLiquidityThreshold = _newLiquidityThreshold * 1e18;
    }

    function setTaxes(Taxes calldata _newTaxes) external onlyOwner{
        require(_newTaxes.liquidity + _newTaxes.marketing + _newTaxes.dev + _newTaxes.UFOPool <= 10, "KushAlienz: Total taxes above 10%");
        taxes = _newTaxes;
    }
    
    function setSellTaxes(Taxes calldata _newSellTaxes) external onlyOwner{
        require(_newSellTaxes.liquidity + _newSellTaxes.marketing + _newSellTaxes.dev + _newSellTaxes.UFOPool <= 10, "KushAlienz: Total sell taxes above 10%");
        sellTaxes = _newSellTaxes;
    }
    
    function setRouterAndPair(address _newRouter, address _newPair) external onlyOwner{
        require(_newRouter != address(0), "KushAlienz: Router is the zero address");
        require(_newPair != address(0), "KushAlienz: Pair is the zero address");
        router = IRouter(_newRouter);
        pair = _newPair;
    }
        
    function setUFOPoolAddress(address _newUFOPoolAddress) external onlyOwner{
        require(_newUFOPoolAddress != address(0), "KushAlienz: UFO Pool is the zero address");
        UFOPoolAddress = _newUFOPoolAddress;
    }    
    
    function setCooldown(bool _state, uint256 time) external onlyOwner{
        require(time <= 90, "KushAlienz: Cooldown is above 90 seconds.");
        coolDownTime = time * 1 seconds;
        coolDownEnabled = _state;
    }
    
    function setIsBlacklisted(address _account, bool _state) external onlyOwner{
        require(_account != address(0), "KushAlienz: Owner can't be blacklisted.");
        isBlacklisted[_account] = _state;
    }
    
    function setBulkIsBlacklisted(address[] calldata accounts, bool _state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length;){
            isBlacklisted[accounts[i]] = _state; 
            unchecked {
                i++;
            }           
        }
    }
    
    function setAllowedTransfer(address account, bool _state) external onlyOwner{
        allowedTransfer[account] = _state;
    }
    
    function setExemptFee(address _address, bool _state) external onlyOwner {
        exemptFee[_address] = _state;
    }
    
    function setBulkExemptFee(address[] calldata accounts, bool _state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length;){
            exemptFee[accounts[i]] = _state;
            unchecked {
                i++;
            }
        }
    }
    
    function setMaxTxLimit(uint256 _maxBuy, uint256 _maxSell) external onlyOwner{
        require(_maxBuy > 99 && _maxSell > 99, "KushAlienz: Max buy and sell must be above 99.");
        maxBuyLimit = _maxBuy * 1e18;
        maxSellLimit = _maxSell * 1e18;
    }
    
    function setMaxWalletlimit(uint256 _amount) external onlyOwner{
        require(_amount > 99, "KushAlienz: Max wallet limit must be above 99.");
        maxWalletLimit = _amount * 1e18;
    }

    function getPair() public view returns(address){
        return pair;
    }
    
    function rescueETH() external onlyOwner{
        payable(devAddress).transfer(address(this).balance);
    }

    function rescueBEP20(address _tokenAddress, uint256 _amount) external onlyOwner{
        IERC20(_tokenAddress).transfer(_tokenAddress, _amount);
    }

    receive() external payable {
        payable(devAddress).transfer(msg.value);
    }

}