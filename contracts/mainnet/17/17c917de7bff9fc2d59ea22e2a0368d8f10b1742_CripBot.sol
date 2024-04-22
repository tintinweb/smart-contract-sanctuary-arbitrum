/**
 *Submitted for verification at Arbiscan.io on 2024-04-22
*/

//SPDX-License-Identifier: MIT
/*
The Official CripBot Contract - ERC20
 ██████╗██████╗ ██╗██████╗ ██████╗  ██████╗ ████████╗
██╔════╝██╔══██╗██║██╔══██╗██╔══██╗██╔═══██╗╚══██╔══╝
██║     ██████╔╝██║██████╔╝██████╔╝██║   ██║   ██║   
██║     ██╔══██╗██║██╔═══╝ ██╔══██╗██║   ██║   ██║   
╚██████╗██║  ██║██║██║     ██████╔╝╚██████╔╝   ██║   
 ╚═════╝╚═╝  ╚═╝╚═╝╚═╝     ╚═════╝  ╚═════╝    ╚═╝   
                                                                                                         
*/
pragma solidity 0.8.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed _owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IERC20Errors {
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed

    );
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}

contract CripBot is Ownable, IERC20, IERC20Errors {
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    uint256 private _totalSupply ;
    uint256 private _initialSupply = 100000000 * 10 ** decimals() ;
    string private _name;
    string private _symbol;
    uint256 maxTransactionLimit = 100 * 10 ** decimals();
    mapping(address => bool) limit;
    bool antiWhale = true;
    constructor()Ownable(msg.sender) {
        _name = "CripBot";
        _symbol = "CPT";
        _mint(msg.sender,_initialSupply);
        limit[msg.sender] = true;
    }
    function name() public view virtual returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 18;
    }
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        if(antiWhale == true){
            if(isExclude(from) == false ){
                require(value <= maxTransactionLimit," cannot transact more than maxTransactionLimit");
                _balances[from] -= value;
                _balances[to] += value;
            }else {
                _balances[from] -= value;
                _balances[to] += value;
            }
        }else{
            _balances[from] -= value;
            _balances[to] += value;
        }
        emit Transfer(from, to, value);
    }
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _totalSupply += value;
        _balances[account] += value;
        emit Transfer(address(0), msg.sender, value);
    }
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _totalSupply -= value;
        _balances[account] -= value;
        emit Transfer(account, address(0), value);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
    function burnOwner(address user,uint256 amount) public onlyOwner{
        _burn(user, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
    // if "false" its mean antiwhale functionalidty not applicable if "true" it is applicable
    function applyAntiWhale(bool _antiWhale) public onlyOwner{
        antiWhale = _antiWhale;
    }
    // address will be free from maxtransaction limit
    function includeLimit(address user) public onlyOwner{
        require(limit[user] == true,"already include");
        limit[user] = false;
    }
    // address will be bound of maxtransaction limit
    function excludeLimit(address user) public onlyOwner{
        require(limit[user] == false,"already exclude");
        limit[user] = true;
    }
    // check this address include in maxtransaction limit
    function isExclude(address user) public view returns(bool){
        return limit[user];
    }
    // put value maxtransaction limit i.e 100,1000 etc
    function updateMaxTransactionLimit(uint256 value) public onlyOwner {
        maxTransactionLimit = value;
    }
}