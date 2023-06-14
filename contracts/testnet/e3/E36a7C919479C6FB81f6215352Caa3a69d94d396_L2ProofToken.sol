/**
 *Submitted for verification at Arbiscan on 2023-06-14
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

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
    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

contract L2ProofToken is ERC20, ERC20Burnable, Pausable, Ownable {
    bool public supplement;
    // add investment and supply everyday
    address public factory;
    // burn user proof
    address public pool;

    mapping(address => bool) public operators;
    mapping(address => bool) public investments;
    mapping(address => bool) public whitelist;
    // user => token => bal
    mapping(address => mapping(address => uint256)) usertokenbal;

    modifier onlyOperator() {
        require(operators[_msgSender()], "Proof: OnlyOperator");
        _;
    }

    modifier onlySupplementing() {
        require(!supplement, "Proof: NotInSupply");
        _;
    }

    constructor(address _factory, address _pool) ERC20("L2ProofToken", "L2P") {
        supplement = false;
        factory = _factory;
        pool = _pool;
        whitelist[address(0)] = true;
        operators[_msgSender()] = true;
    }

    function batchSet(
        address[] memory targets,
        address[] memory tokens,
        uint256[] memory amounts
    ) public onlyOperator onlySupplementing {
        require(
            targets.length == amounts.length && targets.length == tokens.length,
            "Proof: InvalidParameter"
        );
        for (uint256 i = 0; i < targets.length; i++) {
            if (balanceOf(targets[i]) > amounts[i]) {
                burnFrom(targets[i], balanceOf(targets[i]) - amounts[i]);
            } else if (balanceOf(targets[i]) < amounts[i]) {
                _mint(targets[i], amounts[i] - balanceOf(targets[i]));
            }

            usertokenbal[targets[i]][tokens[i]] = amounts[i];
        }
    }

    function depositMint(
        address token,
        uint256 amount
    ) external whenNotPaused returns (bool) {
        require(investments[_msgSender()], "Proof: NotAllowed");
        usertokenbal[tx.origin][token] += amount;
        _mint(tx.origin, amount);
        return true;
    }

    function redemptionBurn(
        address token,
        uint256 amount
    ) external whenNotPaused returns (bool) {
        require(_msgSender() == pool, "Proof: NotAllowed");
        require(
            usertokenbal[tx.origin][token] >= amount,
            "Proof: transfer amount exceeds balance"
        );
        usertokenbal[tx.origin][token] -= amount;
        burnFrom(tx.origin, amount);
        return true;
    }

    function addInvestment(address _invest) external {
        require(_msgSender() == factory, "Proof: OnlyFactory");
        investments[_invest] = true;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
        require(whitelist[from] || whitelist[to], "Proof: Only Whitelist");
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // only open when need change supply
    function setSupplement(bool flag) external onlyOwner {
        supplement = flag;
    }

    function setFactory(address _factory) external onlyOwner {
        factory = _factory;
    }

    function setPool(address _pool) external onlyOwner {
        pool = _pool;
    }

    function setInvestment(address target, bool flag) external onlyOwner {
        investments[target] = flag;
    }

    function setOperator(address target, bool flag) external onlyOwner {
        operators[target] = flag;
    }

    function setWhitelist(address[] memory targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            whitelist[targets[i]] = true;
        }
    }

    function burn(uint256 amount) public override {
        require(whitelist[_msgSender()], "Proof: Only Whitelist");
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        require(
            _msgSender() == owner() || _msgSender() == pool,
            "Proof: Only pool"
        );
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal override {
        uint256 currentAllowance = allowance(owner, spender);
        if (spender != pool && currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}