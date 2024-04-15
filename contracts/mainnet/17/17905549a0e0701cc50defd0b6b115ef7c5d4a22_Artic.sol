/**
 *Submitted for verification at Arbiscan.io on 2024-04-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
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

    function _createInitialSupply(address account, uint256 amount)
        internal
        virtual
    {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
    }
}








contract Artic is ERC20, Ownable {
    uint256 private constant PERCENT_DENOMINATOR = 100;

    struct TaxRates {
        uint256 buy;
        uint256 sell;
        uint256 transfer;
    }

    TaxRates public taxRates;

    mapping (address => bool) public isTaxExempt;
    mapping (address => bool) public automatedMarketMakerPairs;

    address public taxWallet;

    event TaxPaid(address indexed from, address indexed to, uint256 value, uint256 fee, string txnType);
    event TaxRateUpdated(string taxType, uint256 newRate);

    constructor() ERC20("Artic", "ART") {
        _mint(msg.sender, 100 * 10**6 * 10**18);  // 100 million tokens
        taxWallet = 0xD3Bc610f71A28a6872E74da6F58f07fE94499f0c; 

        setTaxRates(10, 10, 0);  // Initial tax rates for buy, sell, and transfer
        setTaxExemptStatus(msg.sender, true);  // Owner is tax exempt
    }

    function setTaxRates(uint256 _buyTax, uint256 _sellTax, uint256 _transferTax) public onlyOwner {
        taxRates.buy = _buyTax;
        taxRates.sell = _sellTax;
        taxRates.transfer = _transferTax;
        emit TaxRateUpdated("buy", _buyTax);
        emit TaxRateUpdated("sell", _sellTax);
        emit TaxRateUpdated("transfer", _transferTax);
    }

    function setTaxWallet(address _taxWallet) public onlyOwner {
        require(_taxWallet != address(0), "Tax wallet cannot be the zero address");
        taxWallet = _taxWallet;
    }

    function setTaxExemptStatus(address _account, bool _status) public onlyOwner {
        isTaxExempt[_account] = _status;
    }

    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(_pair != address(0), "AMM pair cannot be the zero address");
        automatedMarketMakerPairs[_pair] = _value;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (amount == 0) {
            super._transfer(sender, recipient, 0);
            return;
        }

        bool takeFee = !(isTaxExempt[sender] || isTaxExempt[recipient]);
        uint256 feeAmount = 0;

        if (takeFee) {
            uint256 taxRate = getEffectiveTaxRate(sender, recipient);
            feeAmount = amount * taxRate / PERCENT_DENOMINATOR;

            if (feeAmount > 0) {
                super._transfer(sender, taxWallet, feeAmount);
                emit TaxPaid(sender, recipient, amount, feeAmount, getTransactionType(sender, recipient));
            }
        }

        super._transfer(sender, recipient, amount - feeAmount);
    }

    function getEffectiveTaxRate(address sender, address recipient) public view returns (uint256) {
        if (automatedMarketMakerPairs[recipient]) {
            return taxRates.sell;
        } else if (automatedMarketMakerPairs[sender]) {
            return taxRates.buy;
        } else {
            return taxRates.transfer;
        }
    }

    function getTransactionType(address sender, address recipient) public view returns (string memory) {
        if (automatedMarketMakerPairs[recipient]) {
            return "Sell";
        } else if (automatedMarketMakerPairs[sender]) {
            return "Buy";
        } else {
            return "Transfer";
        }
    }
}