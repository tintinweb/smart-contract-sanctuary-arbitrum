// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IPanaAuthority.sol";

abstract contract PanaAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPanaAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IPanaAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IPanaAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IPanaAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPanaAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event DistributionVaultPushed(address indexed from, address indexed to, bool _effectiveImmediately); 

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event DistributionVaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
    function distributionVault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ISupplyContoller {
        
    /* ========== EVENTS ========== */
    event SupplyControlParamsSet(uint256 lossRatio, uint256 cf, uint256 cc, uint256 samplingTime,
        uint256 oldLossRatio, uint256 oldCf, uint256 oldCc, uint256 oldSamplingTime);
    event Burnt(uint256 totalSupply, uint256 panaInPool, uint256 slp, uint256 panaResidue, uint256 tokenResidue);
    event Supplied(uint256 totalSupply, uint256 panaInPool, uint256 slp, uint256 panaSupplied, uint256 panaResidue, uint256 tokenResidue);
    
    function supplyControlEnabled() external view returns (bool);

    function paramsSet() external view returns (bool);

    function setSupplyControlParams(uint256 _lossRatio, uint256 _cf, uint256 _cc, uint256 _samplingTime) external;

    function enableSupplyControl() external;

    function disableSupplyControl() external;

    function compute() external view returns (uint256 _pana, uint256 _slp, bool _burn);

    function burn(uint256 _slp) external;

    function add(uint256 _pana) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

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
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint liquidity);
    function sync() external;
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: contracts/uniswapv2/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
/**
 * @notice 
 * Supply controller is intended to return amount of Pana needed to be added/removed 
 * to/from the liquidity pool to move the pana supply in pool closer to the target setting.
 * The treasury then calls the burn and add operations from this 
 * contract to perform the Burn/Supply as determined to maintain the target supply in pool
 *
 * CAUTION: Since the control mechanism is based on a percentage and Pana is an 18 decimal token,
 * any supply of Pana less or equal to 10^^-17 will lead to underflow
 */
pragma solidity ^0.8.10;

import "../libraries/SafeERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IUniswapV2ERC20.sol";
import "../interfaces/IUniswapV2Pair.sol";
import "../interfaces/IUniswapV2Router02.sol";

import "../access/PanaAccessControlled.sol";
import "../interfaces/ISupplyContoller.sol";

abstract contract BaseSupplyController is ISupplyContoller, PanaAccessControlled {
    using SafeERC20 for IERC20;            

    IERC20 internal immutable PANA;
    IERC20 internal immutable TOKEN;

    address public pair; // The LP pair for which this controller will be used
    address public router; // The address of the UniswapV2Router02 router contract for the given pair
    address public supplyControlCaller; // The address of the contract that is responsible for invoking control

    bool public override supplyControlEnabled; // Switch to start/stop supply control at anytime
    bool public override paramsSet; // Flag that indicates whether the params were set for current control regime

    // Loss Ratio, calculated as lossRatio = deltaPS/deltaTS.
    // Where deltaPS = Target Pana Supply in Pool - Current Pana Supply in Pool
    // deltaTS = Increase in total Pana supply
    // Percentage specified to 4 precision digits. 2250 = 22.50% = 0.2250
    uint256 public lossRatio;

    // cf = Channel floor
    // tlr = Target loss ratio
    // Control should take action only when Pana supply in pool at a point falls such that lossRatio < tlr - cf
    // Percentage specified to 4 precision digits. 100 = 1% = 0.01
    uint256 public cf;

    // cc = Channel Ceiling
    // tlr = Target loss ratio
    // Control should take action only when Pana supply in pool at a point grows such that lossRatio > tlr + cc
    // Percentage specified to 4 precision digits. 100 = 1% = 0.01
    uint256 public cc;

    // Minimal time between calculations, seconds
    uint256 public samplingTime;

    // Previous compute time
    uint256 public prev_timestamp;

    modifier supplyControlCallerOnly() {
        require(msg.sender == supplyControlCaller ||
                msg.sender == authority.policy(), 
                "CONTROL: Only invokable by policy or a contract authorized as caller");
        _;
    }

    constructor(
        address _PANA,
        address _pair, 
        address _router, 
        address _supplyControlCaller,
        address _authority
    ) PanaAccessControlled(IPanaAuthority(_authority)) {
        require(_PANA != address(0), "Zero address: PANA");
        require(_pair != address(0), "Zero address: PAIR");
        require(_router != address(0), "Zero address: ROUTER");
        require(_supplyControlCaller != address(0), "Zero address: CALLER");
        require(_authority != address(0), "Zero address: AUTHORITY");

        PANA = IERC20(_PANA);
        TOKEN = (IUniswapV2Pair(_pair).token0() == address(PANA)) ?  
                    IERC20(IUniswapV2Pair(_pair).token1()) : 
                        IERC20(IUniswapV2Pair(_pair).token0());
        pair = _pair;
        router = _router;
        supplyControlCaller = _supplyControlCaller;
        paramsSet = false;
    }

    function enableSupplyControl() external override onlyGovernor {
        require(supplyControlEnabled == false, "CONTROL: Control already in progress");
        require(paramsSet == true, "CONTROL: Control parameters are not set");
        supplyControlEnabled = true;
    }

    function disableSupplyControl() external override onlyGovernor {
        require(supplyControlEnabled == true, "CONTROL: No control in progress");
        supplyControlEnabled = false;
        paramsSet = false; // Control params should be set for new control regime whenever it is started
    }

    function setSupplyControlParams(uint256 _lossRatio, uint256 _cf, uint256 _cc, uint256 _samplingTime) external onlyGovernor {
        uint256 old_lossRatio = paramsSet ? lossRatio : 0;
        uint256 old_cf = paramsSet ? cf : 0;
        uint256 old_cc = paramsSet ? cc : 0;
        uint256 old_samplingTime = paramsSet ? samplingTime : 0; 

        lossRatio = _lossRatio;
        cf = _cf;
        cc = _cc;
        samplingTime = _samplingTime;

        paramsSet = true;

        emit SupplyControlParamsSet(lossRatio, cf, cc, samplingTime, old_lossRatio, old_cf, old_cc, old_samplingTime);
    }

    function compute() external view override returns (uint256 _pana, uint256 _slp, bool _burn) {
        require(paramsSet == true, "CONTROL: Control parameters are not set");

        (_pana, _slp, _burn) = (0, 0, false);

        if (supplyControlEnabled) {
            uint256 _dt = block.timestamp - prev_timestamp;
            if (_dt < samplingTime) {
                // too early for the next control action hence returning zero
                return (_pana, _slp, _burn);
            }

            uint256 _totalSupply = PANA.totalSupply();
            uint256 _panaInPool = getPanaReserves();

            uint256 _targetSupply = lossRatio * _totalSupply / (10**4);
            uint256 _channelFloor = (lossRatio - cf) * _totalSupply / 10**4;
            uint256 _channelCeiling = (lossRatio + cc) * _totalSupply / 10**4;

            if ((_panaInPool < _channelFloor || _panaInPool > _channelCeiling)) {
                int256 panaAmount = computePana(_targetSupply, _panaInPool, _dt);

                _burn = panaAmount < 0;
                if (_burn) {
                    _pana = uint256(-panaAmount);

                    // Burn SLPs containing 1/2 the Pana needed to be burnt. 
                    // Other half will be be burnt through swap                    
                    _slp = (_pana * IUniswapV2Pair(pair).totalSupply()) / (2 * _panaInPool);
                } else {
                    _pana = uint256(panaAmount);
                    _slp = 0;
                }
            }
        }
    }

    function computePana(uint256 _targetSupply, uint256 _panaInPool, uint256 _dt) internal view virtual returns (int256);

    /**
     * @notice burns Pana from the pool using SLP
     * @param _slp uint256 - amount of slp to burn
     */
    function burn(uint256 _slp) external override supplyControlCallerOnly {
        prev_timestamp = block.timestamp;

        IUniswapV2Pair(pair).approve(router, _slp);

        // Half the amount of Pana to burn comes out alongwith the other half in the form of token
        (uint _panaOut, uint _tokenOut) = 
            IUniswapV2Router02(router).removeLiquidity(
                address(PANA),
                address(TOKEN),
                _slp,
                0,
                0,
                address(this),
                type(uint256).max
            );

        TOKEN.approve(router, _tokenOut);

        address[] memory _path = new address[](2);
        _path[0] = address(TOKEN);
        _path[1] = address(PANA);

        // Swap the token to remove the other half
        (uint[] memory _amounts) = IUniswapV2Router02(router).swapExactTokensForTokens(
            _tokenOut, 
            0, 
            _path,
            address(this), 
            type(uint256).max
        );

        // Residual amounts need to be transferred to treasury
        uint256 _panaResidue = _panaOut + _amounts[1];
        uint256 _tokenResidue = _tokenOut - _amounts[0];

        PANA.safeTransfer(msg.sender, _panaResidue);

        if (_tokenResidue > 0) {
            TOKEN.safeTransfer(msg.sender, _tokenResidue);
        }

        emit Burnt(PANA.totalSupply(), getPanaReserves(), _slp, _panaResidue, _tokenResidue);
    }

    /**
     * @notice adds Pana to the pool
     * @param _pana uint256 - amount of pana to add
     */
    function add(uint256 _pana) external override supplyControlCallerOnly {
        prev_timestamp = block.timestamp;

        PANA.approve(router, _pana);

        address[] memory _path = new address[](2);
        _path[0] = address(PANA);
        _path[1] = address(TOKEN);

        // Pana gets added but token gets withdrawn
        (uint[] memory _amounts_1) = IUniswapV2Router02(router).swapExactTokensForTokens(
            _pana / 2, 
            0, 
            _path,
            address(this), 
            type(uint256).max
        );

        TOKEN.approve(router, _amounts_1[1]);

        uint256 _tokForAdd = _amounts_1[1];
        uint256 _panaForAdd = _pana - _amounts_1[0];

        PANA.approve(router, _panaForAdd);

        // Add the other half token amount back to the pool alongwith Pana
        (uint _panaAdded, uint _tokenAdded, uint _slp) = IUniswapV2Router02(router).addLiquidity(
            address(PANA),
            address(TOKEN),
            _panaForAdd,
            _tokForAdd,
            0,
            0,
            address(this),
            type(uint256).max
        );

        uint256 _netPanaAddedToPool = _amounts_1[0] + _panaAdded;

        // Residual amounts need to be transferred to treasury
        uint256 _panaResidue = _panaForAdd - _panaAdded;
        uint256 _tokenResidue = _tokForAdd - _tokenAdded;

        // Transfer SLP to treasury
        IUniswapV2Pair(pair).transfer(msg.sender, _slp);

        PANA.safeTransfer(msg.sender, _panaResidue);
        TOKEN.safeTransfer(msg.sender, _tokenResidue);

        emit Supplied(PANA.totalSupply(), getPanaReserves(), _slp, _netPanaAddedToPool, _panaResidue, _tokenResidue);
    }

    function getPanaReserves() internal view virtual returns(uint256 _reserve) {
        (uint256 _reserve0, uint256 _reserve1, ) = IUniswapV2Pair(pair).getReserves();
        _reserve = (IUniswapV2Pair(pair).token0() == address(PANA)) ? _reserve0 : _reserve1;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.10;

import "./BaseSupplyController.sol";

contract ProportionalSupplyController is BaseSupplyController {   
    event PCoefficientSet(int256 kp, int256 oldKp);

    // Proportional gain, 4 decimals
    int256 public kp;

    constructor(
        int256 _kp,
        address _PANA,
        address _pair, 
        address _router, 
        address _supplyControlCaller,
        address _authority
    ) BaseSupplyController(_PANA, _pair, _router, _supplyControlCaller, _authority) {
        kp = _kp;
    }

    function setPCoefficient(int256 _kp) external onlyPolicy {
        require(_kp <= 10000, "Proportional coefficient cannot be more than 1");
       
        int256 oldKp = kp;
        kp = _kp;

        emit PCoefficientSet(kp, oldKp);
    }

    function computePana(uint256 _targetSupply, uint256 _panaInPool, uint256 _dt) internal override view returns (int256) {
        return (int256(_targetSupply) - int256(_panaInPool)) * kp / 10**4;
    }
}