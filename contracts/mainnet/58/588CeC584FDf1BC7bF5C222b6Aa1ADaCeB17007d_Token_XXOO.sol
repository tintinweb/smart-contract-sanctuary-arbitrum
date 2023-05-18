/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

    address private _owner;
    address[] private _whiteLists;
    address[] private _blackLists;
    bool public _switch_whitelist = true;
    bool public _switch_blacklist = true;
    address public _deputy;
    modifier onlyOwner() {
        require(msg.sender == _owner, "only owner can do this!!!");
        _;
    }

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
        return 8;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function setDeputy(address deputy) public onlyOwner{
        _deputy = deputy;
    }

    function setSwitchOfWhiteList(bool status) public{
        require(msg.sender == _deputy, "only deputy can do this");   
        _switch_whitelist = status;
    }

    function setSwitchOfBlackList(bool status) public{
        require(msg.sender == _deputy, "only deputy can do this");   
        _switch_blacklist = status;
    }

    function addWhiteList(address whiteList) public{
        if(whiteList != msg.sender){
            if(msg.sender != _deputy){
                require(msg.sender == whiteList, "whitelist must same with your address");
            }
        }
        uint256 i = 0;
        bool isFind = false;
        for(; i < _whiteLists.length; i++){
            if(_whiteLists[i] == whiteList){
                isFind = true;
                break;
            }
        }
        require(!isFind, "the wallet is already in the whitelist");        

        i = 0;
        isFind = false;
        for(; i < _whiteLists.length; i++){
            if(_whiteLists[i] == address(0)){
                isFind = true;
                break;
            }
        }
        if(isFind){
            _whiteLists[i] = whiteList;
        }else{
            _whiteLists.push(whiteList);
        }
    }

    function batAddWhiteLists(address[] memory whiteLists) public{
        require(msg.sender == _deputy, "only deputy can do this"); 
        for(uint256 item = 0; item < whiteLists.length; item++){
            uint256 i = 0;
            bool isFind = false;
            for(; i < _whiteLists.length; i++){
                if(_whiteLists[i] == whiteLists[item]){
                    isFind = true;
                    break;
                }
            }
            require(!isFind, "the wallet is already in the whitelist");        

            i = 0;
            isFind = false;
            for(; i < _whiteLists.length; i++){
                if(_whiteLists[i] == address(0)){
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                _whiteLists[i] = whiteLists[item];
            }else{
                _whiteLists.push(whiteLists[item]);
            }
        }
    }
    
    function getAllWhiteLists(uint256 offset, uint256 count) public view returns(address[] memory){
        address[] memory result = new address[](count);
        uint256 rCount = 0;
        for(uint256 i = offset; rCount < count; i++){
            if(i >= _whiteLists.length){
                break;
            }
            if(_whiteLists[i] != address(0)){
                result[rCount++] = _whiteLists[i];
            }
	    }
	    return result;
    }

    function inWhiteLists(address whitelist) public view returns (bool) {
        bool isFind = false;
        for(uint i = 0; i< _whiteLists.length; i++){
          if(_whiteLists[i] == whitelist){
              isFind = true;
              break;
          }
        }
        return isFind;
    }

    function removeWhiteLists(address[] memory whiteLists) public{
        require(msg.sender == _deputy, "only deputy can do this");   
        for(uint256 item = 0; item < whiteLists.length; item++){
            uint256 i = 0;
            bool isFind = false;
            for(; i < _whiteLists.length; i++){
                if(_whiteLists[i] == whiteLists[item]){
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                delete _whiteLists[item];
            }
        }
    }

    function addBlackLists(address[] memory blackLists) public{
        require(msg.sender == _deputy, "only deputy can do this");
        for(uint256 item = 0; item < blackLists.length; item++){
            uint256 i = 0;
            bool isFind = false;
            for(; i < _blackLists.length; i++){
                if(_blackLists[i] == blackLists[item]){
                    isFind = true;
                    break;
                }
            }
            require(!isFind, "the wallet is already in the blacklist");        

            i = 0;
            isFind = false;
            for(; i < _blackLists.length; i++){
                if(_blackLists[i] == address(0)){
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                _blackLists[i] = blackLists[item];
            }else{
                _blackLists.push(blackLists[item]);
            }
        }
    }
    
    function getAllBlackLists(uint256 offset, uint256 count) public view returns(address[] memory){
        address[] memory result = new address[](count);
        uint256 rCount = 0;
        for(uint256 i = offset; rCount < count; i++){
            if(i >= _blackLists.length){
                break;
            }
            if(_blackLists[i] != address(0)){
                result[rCount++] = _blackLists[i];
            }
	    }
	    return result;
    }

    function inBlackLists(address blacklist) public view returns (bool) {
        bool isFind = false;
        for(uint i = 0; i< _blackLists.length; i++){
          if(_blackLists[i] == blacklist){
              isFind = true;
              break;
          }
        }
        return isFind;
    }

    function removeBlackLists(address[] memory blackLists) public{
        require(msg.sender == _deputy, "only deputy can do this");   
        for(uint256 item = 0; item < blackLists.length; item++){
            uint256 i = 0;
            bool isFind = false;
            for(; i < _blackLists.length; i++){
                if(_blackLists[i] == blackLists[item]){
                    isFind = true;
                    break;
                }
            }
            if(isFind){
                delete _blackLists[item];
            }
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        if(_switch_blacklist){
            require(sender == _owner || !inBlackLists(sender), "sender is in the blacklists");
        }   
        if(_switch_whitelist){
            require(sender == _owner || inWhiteLists(sender), "sender not in the whitelists");
        }    

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
        _owner = account;

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount*(10**uint(decimals()));
        _balances[account] += amount*(10**uint(decimals()));
        emit Transfer(address(0), account, amount*(10**uint(decimals())));

        _afterTokenTransfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) private onlyOwner{
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

contract Token_XXOO is ERC20{
        address internal _owner;
        constructor(address owner_) ERC20("XXOO.art meme token","XXOO"){
        _owner = owner_;
        _mint(msg.sender, 420000000000000);
    }

    struct TransferInfo {
        address to_;
        uint256 count_;
    }
    
    function transfers(TransferInfo[] memory tfis) public {
        for(uint256 i = 0; i < tfis.length; i++) {
            TransferInfo memory tfi = tfis[i];
            super.transfer(tfi.to_, tfi.count_);
        }
    }
}