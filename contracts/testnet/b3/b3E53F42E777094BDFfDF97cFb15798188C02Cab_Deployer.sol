/**
 *Submitted for verification at Arbiscan on 2023-04-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IERC20 {
    function symbol() external view returns (string memory);
    
    function name() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external;


    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is Context, IERC20 {
    mapping (address => uint256) internal _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _symbol;
    string private _name;
    uint256 private _totalSupply = 0;
    address private _owner;
    uint256 public _decimal;

    constructor(string memory name_, string memory symbol_, uint256 decimal_, address owner_, uint256 totalSupply_){
        _name = name_;
        _symbol = symbol_;
        _owner = owner_;
        _decimal = decimal_;
        _mint(owner_, totalSupply_);
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

    function decimals() public view virtual override returns (uint256) {
        return _decimal;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override{
        _transfer(_msgSender(), recipient, amount);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override{
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function mint(address mintAddress, uint256 mintAmount) public virtual {
        require(msg.sender == _owner, "ERC20: Must be owner");
        _mint(mintAddress, mintAmount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);

        
        _balances[account] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
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
    
    function _burn(address account, uint256 amount) internal virtual{
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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


contract Deployer{
    mapping(address => ContractItem[]) private contracts;
    mapping(address => bool) public isAdmin;
    address public feeAddress;
    uint256 public feeCreated;
    uint256 public feeListing;
    event ByteCode(address add, bytes32 bytecode);

    struct ContractItem {
        address _address;
        uint8 _type;
        uint256 _time;
    }

    constructor(address feeAddress_, uint256 feeCreated_, uint256 feeListing_){
        isAdmin[msg.sender] = true;
        feeAddress = feeAddress_;
        feeCreated = feeCreated_;
        feeListing = feeListing_;
    }

    modifier adminOnly() {
        require(isAdmin[msg.sender] == true);
        _;
    }

    function addAdmin(address[] memory _addresses) public adminOnly() {
        for (uint256 i = 0; i < _addresses.length; i++) {
            isAdmin[_addresses[i]] = true;
        }
    }

    function removeAdmin(address _address) public adminOnly() {
        isAdmin[_address] = false;
    }

    function editFee(address address_, uint256 feeCreated_, uint256 feeListing_) public adminOnly() {
        feeAddress = address_;
        feeCreated = feeCreated_;
        feeListing = feeListing_;
    }

    function getContract(address _address) public view returns (ContractItem[] memory) {
        return contracts[_address];
    }

    function getLastContract(address _address) public view returns (address) {
        ContractItem[] memory itemList  = contracts[_address];
        if(itemList.length > 0){
            ContractItem memory item = itemList[itemList.length - 1];
            return item._address;
        }
        return address(0);
    }

    function deployToken(string memory _name, string memory _symbol, uint256 _totalSupply, uint16 _decimal) public payable{
        require(msg.value >= feeCreated, "Sender amount doesn't match the fee created");
        require(feeAddress != address(0), "");
        payable(feeAddress).transfer(feeCreated);

        address contractAddress = address(new ERC20(_name, _symbol, _decimal, msg.sender, _totalSupply));
        contracts[msg.sender].push(ContractItem(contractAddress, 0, block.timestamp));
    }

    function listingToken(address _address) public payable{
        require(msg.value >= feeListing, "Sender amount doesn't match the fee listing");
        require(feeAddress != address(0), "");
        payable(feeAddress).transfer(feeListing);

        contracts[msg.sender].push(ContractItem(_address, 1, block.timestamp));
    }
}