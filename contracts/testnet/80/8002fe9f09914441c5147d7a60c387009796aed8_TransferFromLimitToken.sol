/**
 *Submitted for verification at Arbiscan on 2022-06-03
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// File: contracts/erc20TokenYT.sol


pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev less codes, less gas and clearer meaning for erc20 implementation.
 * Learn from openzeppline ERC20.sol
 * To use:
 * 1. Override function: name, symbol and decimals
 * 2. constructor: _mint or owner
 * @author Yang Tuo
 */
abstract contract erc20TokenYT {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    mapping(address => uint256) internal _BALANCES;
    mapping(address => mapping(address => uint256)) internal _ALLOWANCES;
    uint256 internal _TOTAL_SUPPLY;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    // constructor(string memory token_name, string memory token_symbol, uint8 token_decimals) {
    //     _NAME = token_name;
    //     _SYMBOL = token_symbol;
    //     _DECIMALS = token_decimals;
    // }

    function name() public view virtual returns (string memory) {
        return "Token Name";
    }

    function symbol() public view virtual returns (string memory) {
        return "TN";
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _BALANCES[account];
    }

    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _ALLOWANCES[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _ALLOWANCES[sender][msg.sender];
        if (currentAllowance != MAX_UINT256) {
            require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
            unchecked {
                _approve(sender, msg.sender, currentAllowance - amount);
            }
        }

        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        //require(owner != address(0), "ERC20: approve from the zero address");
        //require(spender != address(0), "ERC20: approve to the zero address");
        _ALLOWANCES[owner][spender] = amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        //require(sender != address(0), "ERC20: transfer from the zero address");
        //require(recipient != address(0), "ERC20: transfer to the zero address");
        //_beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _BALANCES[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _BALANCES[sender] = senderBalance - amount;
        }
        _BALANCES[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        //_afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        //require(account != address(0), "ERC20: mint to the zero address");
        //_beforeTokenTransfer(address(0), account, amount);

        _TOTAL_SUPPLY += amount;
        _BALANCES[account] += amount;
        emit Transfer(address(0), account, amount);

        //_afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        //require(account != address(0), "ERC20: burn from the zero address");
        //_beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _BALANCES[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _BALANCES[account] = accountBalance - amount;
        }
        _TOTAL_SUPPLY -= amount;

        emit Transfer(account, address(0), amount);

        //_afterTokenTransfer(account, address(0), amount);
    }
}

// File: contracts/TransferFromLimitToken.sol


pragma solidity 0.8.9;
pragma abicoder v2;



contract TransferFromLimitToken is
    erc20TokenYT,
    Ownable
{
    string constant NAME = "Aboard Paper Trading Competition USD Coin";
    string constant SYMBOL = "USDC";
    uint8 constant DECIMALS = 6;
    uint256 constant INIT_MINT = 1e9 * (10 ** DECIMALS);

    address public _LIMIT_SPENDER;
    uint256 public _LIMIT_NUM;
    mapping(address => uint256) _TRANSFER_ACC;

    event TransferFromLimit(address indexed spender, uint256 limit);

    constructor() {
        _mint(msg.sender, INIT_MINT);
    }

    function transferFromLimit(address spender, uint256 limit) external onlyOwner {
        _LIMIT_SPENDER = spender;
        _LIMIT_NUM = limit;
        emit TransferFromLimit(spender, limit);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if (msg.sender == _LIMIT_SPENDER) {
            uint256 transfer_acc = _TRANSFER_ACC[sender] + amount;
            require(transfer_acc <= _LIMIT_NUM, "Aboard Match: deposit limit");
            _TRANSFER_ACC[sender] = transfer_acc;
        }
        return super.transferFrom(sender, recipient, amount);
    }

    function getTransferLimitAcc(address account) external view returns (uint256) {
        return _TRANSFER_ACC[account];
    }
    

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function name() public view override returns (string memory) {
        return NAME;
    }

    function symbol() public view override returns (string memory) {
        return SYMBOL;
    }

    function decimals() public view override returns (uint8) {
        return DECIMALS;
    }
}