/**
 *Submitted for verification at Arbiscan on 2023-05-21
*/

pragma solidity ^0.8.7;


// SPDX-License-Identifier: MIT
// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address _token, address _to, uint256 _value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0x095ea7b3, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint _x, uint _y) internal pure returns (uint z) {
        require((z = _x + _y) >= _x, "ds-math-add-overflow");
    }

    function sub(uint _x, uint _y) internal pure returns (uint z) {
        require((z = _x - _y) <= _x, "ds-math-sub-underflow");
    }

    function mul(uint _x, uint _y) internal pure returns (uint z) {
        require(_y == 0 || (z = _x * _y) / _y == _x, "ds-math-mul-overflow");
    }

    function div(uint _x, uint _y) internal pure returns (uint z) {
        require(_y > 0, "ds-math-div-by-zero");
        z = _x / _y;
    }
}

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(
        address _owner,
        address _spender
    ) external view returns (uint256);

    function approve(address _spender, uint256 _value) external returns (bool);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool);

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

interface IWETH {
    function deposit() external payable;

    function transfer(address _to, uint256 _value) external returns (bool);

    function withdraw(uint256) external;
}

interface IDEX {
    function getMaxAmountIn(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view returns (uint256);

    function getAmountOut(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _to
    ) external returns (uint256);
}

interface IDEXAggregator {
    function dexes(uint256) external view returns (address);

    function dexIndex(address) external view returns (uint256);

    function dexLength() external view returns (uint256);

    function getMaxAmountIn(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view returns (uint256 maxAmountIn, address dex);

    function getAmountOut(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256 amountOut, address dex);

    function swap(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _to
    ) external returns (uint256 amountOut, address dex);
}

contract Lockable {
    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "Lockable: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

contract DEXAggregator is Lockable, IDEXAggregator {
    using SafeMath for uint256;

    address public immutable WETH;
    address public manager;
    address[] public override dexes;
    mapping(address => uint256) public override dexIndex;

    event SetManager(address manager);
    event AddDEX(address indexed user, address indexed dex);
    event RemoveDEX(address indexed user, address indexed dex);
    event Swap(
        address indexed user,
        address indexed to,
        address indexed dex,
        address _tokenIn,
        address _tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(address _WETH, address _manager) public {
        WETH = _WETH;
        manager = _manager;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    modifier onlyManager() {
        require(msg.sender == manager, "DEXAggregator: FORBIDDEN");
        _;
    }

    function _validateDEX(address _dex) internal view returns (uint256 idx) {
        idx = dexIndex[_dex];
        require(idx > 0, "DEXAggregator: NOT_EXISTS_DEX");
    }

    function dexLength() external view override returns (uint256) {
        return dexes.length;
    }

    function setManager(address _newManager) external onlyManager {
        require(msg.sender != address(0), "DEXAggregator: ZERO_ADDRESS");
        manager = _newManager;

        emit SetManager(_newManager);
    }

    function addDEX(address _dex) external onlyManager {
        require(dexIndex[_dex] == 0, "DEXAggregator: EXISTS_DEX");
        dexes.push(_dex);
        dexIndex[_dex] = dexes.length;

        emit AddDEX(msg.sender, _dex);
    }

    function removeDEX(address _dex) external onlyManager {
        uint256 idx = _validateDEX(_dex);
        uint256 length = dexes.length;
        if (idx < length) {
            dexIndex[dexes[length - 1]] = idx;
            dexes[idx - 1] = dexes[length - 1];
        }
        dexes.pop();
        dexIndex[_dex] = 0;

        emit RemoveDEX(msg.sender, _dex);
    }

    function _getAmountOut(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal view returns (uint256 amountOut, address dex) {
        require(_tokenIn != _tokenOut, "DEXAggregator: BAD_PATH");
        if (_dex == address(0)) {
            uint256 length = dexes.length;
            for (uint256 i = 0; i < length; i++) {
                {
                    uint256 _amountOut = IDEX(dexes[i]).getAmountOut(
                        _tokenIn,
                        _tokenOut,
                        _amountIn
                    );
                    if (_amountOut > amountOut) {
                        amountOut = _amountOut; // choose the better
                        dex = dexes[i];
                    }
                }
            }
        } else {
            amountOut = IDEX(_dex).getAmountOut(_tokenIn, _tokenOut, _amountIn);
            dex = _dex;
        }
    }

    function getAmountOut(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view override returns (uint256 amountOut, address dex) {
        return _getAmountOut(_dex, _tokenIn, _tokenOut, _amountIn);
    }

    function getMaxAmountIn(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountOut
    ) external view override returns (uint256 maxAmountIn, address dex) {
        require(_tokenIn != _tokenOut, "DEXAggregator: BAD_PATH");
        if (_dex == address(0)) {
            uint256 length = dexes.length;
            for (uint256 i = 0; i < length; i++) {
                {
                    uint256 _maxAmountIn = IDEX(dexes[i]).getMaxAmountIn(
                        _tokenIn,
                        _tokenOut,
                        _amountOut
                    );
                    if (_maxAmountIn < maxAmountIn) {
                        maxAmountIn = _maxAmountIn; // choose the better
                        dex = dexes[i];
                    }
                }
            }
        } else {
            maxAmountIn = IDEX(_dex).getMaxAmountIn(
                _tokenIn,
                _tokenOut,
                _amountOut
            );
            dex = _dex;
        }
    }

    function _swap(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        address _to
    ) internal returns (uint256 amountOut) {
        TransferHelper.safeTransfer(_tokenIn, _dex, _amountIn);
        amountOut = IDEX(_dex).swap(_tokenIn, _tokenOut, _to);
    }

    function swap(
        address _dex,
        address _tokenIn,
        address _tokenOut,
        uint256 _minAmountOut,
        address _to
    ) external override lock returns (uint256 amountOut, address dex) {
        require(_tokenIn != _tokenOut, "DEXAggregator: BAD_PATH");

        // receive input token
        uint256 amountIn = IERC20(_tokenIn).balanceOf(address(this));

        // swap
        if (_dex == address(0)) {
            (, _dex) = _getAmountOut(_dex, _tokenIn, _tokenOut, amountIn);
        }
        dex = _dex;
        amountOut = _swap(_dex, _tokenIn, _tokenOut, amountIn, address(this));
        require(
            amountOut >= _minAmountOut,
            "DEXAggregator: INSUFFICIENT_OUTPUT_TOKEN"
        );

        // send output token
        TransferHelper.safeTransfer(_tokenOut, _to, amountOut);

        emit Swap(
            msg.sender,
            _to,
            _dex,
            _tokenIn,
            _tokenOut,
            amountIn,
            amountOut
        );
    }

    function rescueFunds(
        address _token,
        address _to
    ) external lock onlyManager {
        TransferHelper.safeTransfer(
            _token,
            _to,
            IERC20(_token).balanceOf(address(this))
        );
    }
}