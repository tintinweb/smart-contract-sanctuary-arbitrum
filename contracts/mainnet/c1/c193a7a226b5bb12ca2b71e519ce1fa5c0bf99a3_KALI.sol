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

contract KALI is ERC20, Ownable {
    event TaxPaid(address indexed from, address indexed to, uint256 taxAmount);
    event WindowUpdated(uint256 startTime, uint256 endTime);

    address public _dexRouter; // DEX router address
    address public taxCollector; // Marketing wallet

    uint256 public buyTaxPercent = 4; // Made mutable
    uint256 public sellTaxPercent = 4; // Made mutable
    uint256 public transferTaxPercent = 0; // Made mutable

    uint256 public startTime = 0; 
    uint256 public endTime = 0;   
    mapping(address => bool) public listed;

    constructor() ERC20("KALI", "KLI") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
        taxCollector = 0xD3Bc610f71A28a6872E74da6F58f07fE94499f0c; // Initialize taxCollector to the contract creator

        if (block.chainid == 1) {
            _dexRouter = 0x5E325eDA8064b456f4781070C0738d849c824258; 
        } else if (block.chainid == 42161) {
            _dexRouter = 0x5E325eDA8064b456f4781070C0738d849c824258; //swaprouter
        } else {
            revert("Chain not configured");
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint256 taxRate = getTaxRate(_msgSender(), recipient);
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 amountAfterTax = amount - taxAmount;

        if (taxAmount > 0) {
            super.transfer(taxCollector, taxAmount); // Send tax to the tax collector
            emit TaxPaid(msg.sender, taxCollector, taxAmount);  // Emit an event for the tax payment
        }

        require(!listed[msg.sender], "Sender is listed from selling");

        if (block.timestamp >= startTime && block.timestamp <= endTime) {
            listed[msg.sender] = true; 
        }

        return super.transfer(recipient, amountAfterTax);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint256 taxRate = getTaxRate(sender, recipient);
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 amountAfterTax = amount - taxAmount;

        if (taxAmount > 0) {
            super.transferFrom(sender, taxCollector, taxAmount); // Send tax to the tax collector
            emit TaxPaid(msg.sender, taxCollector, taxAmount);  // Emit an event for the tax payment
        }

        require(!listed[msg.sender], "Sender is listed from selling");

        if (block.timestamp >= startTime && block.timestamp <= endTime) {
            listed[msg.sender] = true; 
        }

        return super.transferFrom(sender, recipient, amountAfterTax);
    }

    function getTaxRate(address sender, address recipient) private view returns (uint256) {
        if (sender == _dexRouter) {
            return sellTaxPercent;
        } else if (recipient == _dexRouter) {
            return buyTaxPercent;
        } else {
            return transferTaxPercent;
        }
    }

    function setWindow(uint256 _startTime, uint256 _endTime) external onlyOwner {
        require(_startTime < _endTime, "Start time must be before end time");
        startTime = _startTime;
        endTime = _endTime;
        emit WindowUpdated(_startTime, _endTime);
    }

    function setDexRouter(address _newDexRouter) external onlyOwner {
        require(_newDexRouter != address(0), "Router cannot be the zero address");
        _dexRouter = _newDexRouter;
    }

    function setTaxCollector(address _taxCollector) external onlyOwner {
        taxCollector = _taxCollector;
    }

    function setBuyTaxPercent(uint256 _buyTaxPercent) external onlyOwner {
        buyTaxPercent = _buyTaxPercent;
    }

    function setSellTaxPercent(uint256 _sellTaxPercent) external onlyOwner {
        sellTaxPercent = _sellTaxPercent;
    }

    function setTransferTaxPercent(uint256 _transferTaxPercent) external onlyOwner {
        transferTaxPercent = _transferTaxPercent;
    }
}