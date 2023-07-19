// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function balanceOf(address owner) external view returns (uint);
    function getReserves() external view returns ( uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast );
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ERC20 {

    uint internal _totalSupply;
    mapping(address => uint) internal _balanceOf;
    mapping(address => mapping(address => uint)) internal _allowance;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function _mint(address to, uint value) internal {
        _beforeTokenTransfer(address(0), to, value);
        _totalSupply += value;
        _balanceOf[to] += value;
        emit Transfer(address(0), to, value);
        _afterTokenTransfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _beforeTokenTransfer(from, address(0), value);
        _balanceOf[from] -= value;
        _totalSupply -= value;
        emit Transfer(from, address(0), value);
        _afterTokenTransfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint value
    ) internal virtual {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint value
    ) internal virtual {
        _beforeTokenTransfer(from, to, value);
        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
        _afterTokenTransfer(from, to, value);
    }

    function allowance(address owner, address spender) external view virtual returns (uint) {
        return _allowance[owner][spender];
    }

    function _spendAllowance(address owner, address spender, uint value) internal virtual {
        if (_allowance[owner][spender] != type(uint256).max) {
            require(_allowance[owner][spender] >= value, "ERC20: insufficient allowance");
            _allowance[owner][spender] -= value;
        }
    }

    function totalSupply() external view virtual returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address owner) external view virtual returns (uint) {
        return _balanceOf[owner];
    }

    function approve(address spender, uint value) external virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external virtual returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint value
    ) external virtual returns (bool) {
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint value
    ) internal virtual {}

    function _beforeTokenTransfer(
        address from,
        address to,
        uint value
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "./ERC20.sol";

contract SlippageERC20 is ERC20 {

    /// @notice permission tpye
    /// main permission
    uint8 public constant OWNER = 0;
    /// mint permission
    uint8 public constant MINTER = 1;

    /// @notice param tpye
    /// from slip, general for sell
    uint8 public constant FROM_SLIP = 2;
    /// to slip, general for buy
    uint8 public constant TO_SLIP = 3;
    /// set slip white list
    uint8 public constant SLIP_WHITE_LIST = 4;
    /// set black list
    uint8 public constant BLACK_LIST = 5;
    /// withdraw token
    uint8 public constant WITHDRAW = 6;
    /// set default tax rate
    uint8 public constant DEFAULT_TAX_RATE = 7;

    /// default tax rate, transfer tax rate except fromSlip, toSlip, slipWhiteList
    uint32 public defaultTaxRateE5 = 0;

    /// @notice throw all Permission
    bool public throwAllPermission = false;

    /// @notice permission => caller => isPermission
    mapping (uint8 => mapping(address => bool)) public permissions;
    /// @notice set permission event
    event PermissionSet(uint8 indexed permission, address indexed account, bool indexed value);

    /// @notice check permission
    modifier onlyCaller(uint8 _permission) {
        require(!throwAllPermission && permissions[_permission][msg.sender], "Calls have not allowed");
        _;
    }

    /// @notice from
    mapping(address => uint32) public fromSlipE5;
    /// @notice to
    mapping(address => uint32) public toSlipE5;

    mapping(address => bool) public slipWhiteList;
    event SlipWhiteListSet(address indexed account, bool indexed value);

    mapping(address => bool) public blackList;

    function _initERC20_() internal {
        // set permission for own
        address _owner = msg.sender;
        
        _setPermission(OWNER, _owner, true);
        _setPermission(MINTER, _owner, true);
        _setSlipWhite(address(this), true);
    }

    /// @notice set permission
    function _setPermission(uint8 _permission, address _account, bool _value) internal {
        permissions[_permission][_account] = _value;
        emit PermissionSet(_permission, _account, _value);
    }

    /// @notice set permissions
    function setPermissions(uint8[] calldata _permissions, address[] calldata _accounts, bool[] calldata _values) external onlyCaller(OWNER) {
        require(_permissions.length == _accounts.length && _accounts.length == _values.length, "Lengths are not equal");
        for (uint i = 0; i < _permissions.length; i++) {
            _setPermission(_permissions[i], _accounts[i], _values[i]);
        }
    }

    function _setSlipWhite(address _addr, bool _isWhite) internal {
        slipWhiteList[_addr] = _isWhite;
        emit SlipWhiteListSet(_addr, _isWhite);
    }
    
    /// @notice set throw all permission
    function setThrowAllPermission() external onlyCaller(OWNER) {
        throwAllPermission = true;
    }

    /// @notice set
    function setConfig(uint8[] calldata _configTypes, bytes[] calldata _datas) external onlyCaller(OWNER) {
        uint len = _configTypes.length;
        for(uint i = 0; i < len; i++) {
            if (_configTypes[i] == FROM_SLIP) {
                (address _from, uint32 _feeE5) = abi.decode(_datas[i], (address, uint32));
                fromSlipE5[_from] = _feeE5;
            } else if (_configTypes[i] == TO_SLIP) {
                (address _to, uint32 _feeE5) = abi.decode(_datas[i], (address, uint32));
                toSlipE5[_to] = _feeE5;
            } else if (_configTypes[i] == SLIP_WHITE_LIST) {
                (address _account, bool _value) = abi.decode(_datas[i], (address, bool));
                _setSlipWhite(_account, _value);
            } else if (_configTypes[i] == BLACK_LIST) {
                (address _account, bool _value) = abi.decode(_datas[i], (address, bool));
                blackList[_account] = _value;
            } else if (_configTypes[i] == WITHDRAW) {
                (address _to, uint _amount) = abi.decode(_datas[i], (address, uint));
                _balanceOf[address(this)] -= _amount;
                _balanceOf[_to] += _amount;
                emit Transfer(address(this), _to, _amount);
            } else if (_configTypes[i] == DEFAULT_TAX_RATE) {
                (uint32 _feeE5) = abi.decode(_datas[i], (uint32));
                defaultTaxRateE5 = _feeE5;
            }
        }
    }

    /// @notice slipperage transfer
    function _transfer(address _from, address _to, uint256 _amount) internal override {
        /// @notice this function just for filter transfer allwoed
        require(!blackList[_from] && !blackList[_to], "blacklisted");

        uint _fee = 0;
        if (!slipWhiteList[_from] && !slipWhiteList[_to]) {
            _fee = _amount * (fromSlipE5[_from] + toSlipE5[_to]) / 1e5;
            /// @dev default tax rate without slip
            if ( defaultTaxRateE5 > 0 && _fee == 0) {
                _fee = _amount * defaultTaxRateE5 / 1e5;
            }
            
            if (_fee > 0) {
                _transferSlippage(_from, _to, _amount, _fee);
            }
        }
        _beforeTokenTransfer(_from, _to, _amount);
        _balanceOf[_from] -= _amount;
        _amount -= _fee;
        _balanceOf[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        _afterTokenTransfer(_from, _to, _amount);
    }

    /// @notice default transfer fee
    function _transferSlippage(address _from, address, uint256, uint _fee) internal virtual {
        _balanceOf[address(this)] += _fee;
        emit Transfer(_from, address(this), _fee);
    }

    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SlippageERC20} from "../utils/SlippageERC20.sol";
import {IPair} from "../interface/IPair.sol";

interface ERC20Interface {
    function balanceOf(address user) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to,uint256 amount) external returns(bool);
}

library SafeToken {

    function balance(address token, address user) internal view returns (uint256) {
        return ERC20Interface(token).balanceOf(user);
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }

}


contract Wallet {
    function safeTransfer(address token, address to, uint256 value) external {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "!safeTransfer");
    }
}

contract AiETH is SlippageERC20 {

    using SafeToken for address;
    
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    /// @notice the rebase lp address
    address public lp;
    address public usdt;

    /// @notice lp pool
    address public lpPool;
    /// @notice node pool
    address public nodePool;
    /// @notice fund pool
    address public fundPool;

    Wallet public immutable wallet;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _totalSupply
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        _mint(msg.sender, _totalSupply);
        _setSlipWhite(msg.sender, true);
        _initERC20_();
        wallet = new Wallet();
    }

    function setLp(address _lp) external onlyCaller(OWNER) {
        lp = _lp;
        IPair iLp = IPair(_lp);
        address token = iLp.token0();
        usdt = token == address(this) ? iLp.token1() : token;
    }

    function setAddress(
        address _lpPool,
        address _nodePool,
        address _fundPool
    ) external onlyCaller(OWNER) {
        lpPool = _lpPool;
        nodePool = _nodePool;
        fundPool = _fundPool;
        _setSlipWhite(_lpPool, true);
        _setSlipWhite(_nodePool, true);
        _setSlipWhite(_fundPool, true);
    }

    function _transferSlippage(address _from, address _to, uint256, uint _fee) internal override {
        // buy or burn lp
        if ( lp != address(0) ) {
            if ( _from == lp ) {
                _totalSupply -= _fee;
                emit Transfer(_from, address(0), _fee);
            }
            // sell or mint lp
            else if ( _to == lp ) {
                emit Transfer(_from, address(this), _fee);
                _sell(_fee);
                uint _perFee = ERC20Interface(usdt).balanceOf(address(wallet));
                uint _perFee3 = _perFee / 3;
                wallet.safeTransfer(usdt, lpPool, _perFee3);
                wallet.safeTransfer(usdt, nodePool, _perFee3);
                wallet.safeTransfer(usdt, fundPool, _perFee - _perFee3 * 2);
            }
        }
    }

    /// @notice sell AiETH
    function _sell(uint _aiAmount) internal {

        IPair iLp = IPair(lp);
        (uint reserveAi, uint reserveUsdt, ) = iLp.getReserves();
        if (address(this) > usdt) {
            (reserveAi, reserveUsdt) = (reserveUsdt, reserveAi);
        }

        _balanceOf[lp] += _aiAmount;
        emit Transfer(address(this), lp, _aiAmount);
        uint amount0Out = uint(0);
        uint amount1Out = getAmountOut(_aiAmount, reserveAi, reserveUsdt, 9970);
        if (address(this) > usdt) {
            (amount0Out, amount1Out) = (amount1Out, amount0Out);
        }
        iLp.swap(amount0Out, amount1Out, address(wallet), new bytes(0));
    }

    /// given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut,
        uint feeE4
    ) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * feeE4;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}