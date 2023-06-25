// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ███████╗░█████╗░██████╗░████████╗██████╗░███████╗░██████╗░██████╗
// ██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██╔════╝
// █████╗░░██║░░██║██████╔╝░░░██║░░░██████╔╝█████╗░░╚█████╗░╚█████╗░
// ██╔══╝░░██║░░██║██╔══██╗░░░██║░░░██╔══██╗██╔══╝░░░╚═══██╗░╚═══██╗
// ██║░░░░░╚█████╔╝██║░░██║░░░██║░░░██║░░██║███████╗██████╔╝██████╔╝
// ╚═╝░░░░░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚═════╝░╚═════╝░
// ███████╗██╗███╗░░██╗░█████╗░███╗░░██╗░█████╗░███████╗
// ██╔════╝██║████╗░██║██╔══██╗████╗░██║██╔══██╗██╔════╝
// █████╗░░██║██╔██╗██║███████║██╔██╗██║██║░░╚═╝█████╗░░
// ██╔══╝░░██║██║╚████║██╔══██║██║╚████║██║░░██╗██╔══╝░░
// ██║░░░░░██║██║░╚███║██║░░██║██║░╚███║╚█████╔╝███████╗
// ╚═╝░░░░░╚═╝╚═╝░░╚══╝╚═╝░░╚═╝╚═╝░░╚══╝░╚════╝░╚══════╝
     
//  _____         _                   _____     _   _ _____               
// |   __|___ ___| |_ ___ ___ ___ ___|  _  |___| |_|_|   __|_ _ _ ___ ___ 
// |   __| . |  _|  _|  _| -_|_ -|_ -|     |  _| . | |__   | | | | .'| . |
// |__|  |___|_| |_| |_| |___|___|___|__|__|_| |___|_|_____|_____|__,|  _|
//                                                                   |_|  

// Github - https://github.com/FortressFinance

import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {SafeCast} from "lib/openzeppelin-contracts/contracts/utils/math/SafeCast.sol";
import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";

import {IFortressSwap} from "src/shared/fortress-interfaces/IFortressSwap.sol";

import {IUniswapV3RouterArbi} from "src/arbitrum/interfaces/IUniswapV3RouterArbi.sol";
import {IGMXRouter} from "src/arbitrum/interfaces/IGMXRouter.sol";
import {IWETH} from "src/shared/interfaces/IWETH.sol";
import {ICurvePool} from "src/shared/interfaces/ICurvePool.sol";
import {ICurveCryptoETHV2Pool} from "src/shared/interfaces/ICurveCryptoETHV2Pool.sol";
import {ICurveSBTCPool} from "src/shared/interfaces/ICurveSBTCPool.sol";
import {ICurveCryptoV2Pool} from "src/shared/interfaces/ICurveCryptoV2Pool.sol";
import {ICurve3Pool} from "src/shared/interfaces/ICurve3Pool.sol";
import {ICurvesUSD4Pool} from "src/shared/interfaces/ICurvesUSD4Pool.sol";
import {ICurveBase3Pool} from "src/shared/interfaces/ICurveBase3Pool.sol";
import {ICurvePlainPool} from "src/shared/interfaces/ICurvePlainPool.sol";
import {ICurveCRVMeta} from "src/shared/interfaces/ICurveCRVMeta.sol";
import {ICurveFraxMeta} from "src/shared/interfaces/ICurveFraxMeta.sol";
import {ICurveFraxCryptoMeta} from "src/shared/interfaces/ICurveFraxCryptoMeta.sol";
import {IUniswapV3Pool} from "src/shared/interfaces/IUniswapV3Pool.sol";
import {IUniswapV2Router} from "src/shared/interfaces/IUniswapV2Router.sol";
import {IBalancerVault} from "src/shared/interfaces/IBalancerVault.sol";
import {IBalancerPool} from "src/shared/interfaces/IBalancerPool.sol";

contract FortressArbiSwap is ReentrancyGuard, IFortressSwap {

    using SafeERC20 for IERC20;
    using SafeCast for int256;
    using Address for address payable;

    /// @notice The address of WETH token (Arbitrum)
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    /// @notice The address representing native ETH.
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    /// @notice The address of Uniswap V3 Router (Arbitrum).
    address private constant UNIV3_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
    /// @notice The address of Balancer vault (Arbitrum).
    address constant BALANCER_VAULT = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    // The address of Sushi Swap Router (Arbitrum).
    address constant SUSHI_ARB_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    /// @notice The address of Fraxswap Uniswap V2 Router Arbitrum (https://docs.frax.finance/smart-contracts/fraxswap#arbitrum-1).
    address private constant FRAXSWAP_UNIV2_ROUTER = 0xc2544A32872A91F4A553b404C6950e89De901fdb;
    /// @notice The address of GMX Swap Router.
    address constant GMX_ROUTER = 0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064;

    struct Route {
        // pool type -->
        // 0: UniswapV3
        // 1: Fraxswap
        // 2: Curve2AssetPool
        // 3: _swapCurveCryptoV2
        // 4: Curve3AssetPool
        // 5: CurveETHV2Pool
        // 6: CurveCRVMeta - N/A
        // 7: CurveFraxMeta - N/A
        // 8: CurveBase3Pool
        // 9: CurveSBTCPool
        // 10: Curve4Pool
        // 11: FraxCryptoMeta - N/A
        // 12: BalancerSingleSwap
        // 13: SushiSwap
        // 14: GMXSwap
        
        /// @notice The internal pool type.
        uint256[] poolType;
        /// @notice The pool addresses.
        address[] poolAddress;
        /// @notice The addresses of the token to swap from.
        address[] tokenIn;
        /// @notice The addresses of the token to swap to.
        address[] tokenOut;
    }

    /// @notice The swap routes.
    mapping(address => mapping(address => Route)) private routes;
    
    /// @notice The address of the owner.
    address public owner;

    /********************************** View Functions **********************************/

    /// @dev Check if a certain swap route is available.
    /// @param _fromToken - The address of the input token.
    /// @param _toToken - The address of the output token.
    /// @return - Whether the route exist.
    function routeExists(address _fromToken, address _toToken) external view returns (bool) {
        return routes[_fromToken][_toToken].poolAddress.length > 0;
    }

    /********************************** Constructor **********************************/

    constructor(address _owner) {
        if (_owner == address(0)) revert ZeroInput();
         
        owner = _owner;
    }

    /********************************** Mutated Functions **********************************/

    /// @dev Swap from one token to another.
    /// @param _fromToken - The address of the input token.
    /// @param _toToken - The address of the output token.
    /// @param _amount - The amount of input token.
    /// @return - The amount of output token.
    function swap(address _fromToken, address _toToken, uint256 _amount) external payable nonReentrant returns (uint256) {
        Route storage _route = routes[_fromToken][_toToken];
        if (_route.poolAddress.length == 0) revert RouteUnavailable();
        
        if (msg.value > 0) {
            if (msg.value != _amount) revert AmountMismatch();
            if (_fromToken != ETH) revert TokenMismatch();
        } else {
            if (_fromToken == ETH) revert TokenMismatch();
            IERC20(_fromToken).safeTransferFrom(msg.sender, address(this), _amount);
        }
        
        uint256 _poolType;
        address _poolAddress;
        address _tokenIn;
        address _tokenOut;
        for(uint256 i = 0; i < _route.poolAddress.length; i++) {
            _poolType = _route.poolType[i];
            _poolAddress = _route.poolAddress[i];
            _tokenIn = _route.tokenIn[i];
            _tokenOut = _route.tokenOut[i];
            
            if (_poolType == 0) {
                _amount = _swapUniV3(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 1) {
                _amount = _swapFraxswapUniV2(_tokenIn, _tokenOut, _amount);
            } else if (_poolType == 2) {
                _amount = _swapCurve2Asset(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 3) {
                _amount = _swapCurveCryptoV2(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 4) {
                _amount = _swapCurve3Asset(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 5) {
                _amount = _swapCurveETHV2(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 8) {
                _amount = _swapCurveBase3Pool(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 9) {
                _amount = _swapCurveSBTCPool(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 10) {
                _amount = _swapCurve4Pool(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 12) {
                _amount = _swapBalancerPoolSingle(_tokenIn, _tokenOut, _amount, _poolAddress);
            } else if (_poolType == 13) {
                _amount = _swapSushiPool(_tokenIn, _tokenOut, _amount);
            } else if (_poolType == 14) {
                _amount = _swapGMX(_tokenIn, _tokenOut, _amount);
            } else {
                revert UnsupportedPoolType();
            }
        }
        
        if (_toToken == ETH) {
            payable(msg.sender).sendValue(_amount);
        } else {
            IERC20(_toToken).safeTransfer(msg.sender, _amount);
        }
        
        emit Swap(_fromToken, _toToken, _amount);
        
        return _amount;
    }

    /********************************** Restricted Functions **********************************/

    /// @dev Add/Update a swap route.
    /// @param _fromToken - The address of the input token.
    /// @param _toToken - The address of the output token.
    /// @param _poolType - The internal pool type.
    /// @param _poolAddress - The pool addresses.
    /// @param _fromList - The addresses of the input tokens.
    /// @param _toList - The addresses of the output tokens.
    function updateRoute(address _fromToken, address _toToken, uint256[] memory _poolType, address[] memory _poolAddress, address[] memory _fromList, address[] memory _toList) external {
        if (msg.sender != owner) revert Unauthorized();
        if (routes[_fromToken][_toToken].poolAddress.length != 0) revert RouteAlreadyExists();

        routes[_fromToken][_toToken] = Route(
            _poolType,
            _poolAddress,
            _fromList,
            _toList
        );

        emit UpdateRoute(_fromToken, _toToken, _poolAddress);
    }

    /// @dev Delete a swap route.
    /// @param _fromToken - The address of the input token.
    /// @param _toToken - The address of the output token.
    function deleteRoute(address _fromToken, address _toToken) external {
        if (msg.sender != owner) revert Unauthorized();

        delete routes[_fromToken][_toToken];

        emit DeleteRoute(_fromToken, _toToken);
    }

    /// @dev Update the contract owner.
    /// @param _newOwner - The address of the new owner.
    function updateOwner(address _newOwner) external {
        if (msg.sender != owner) revert Unauthorized();
        if (_newOwner == address(0)) revert ZeroInput();

        owner = _newOwner;
        
        emit UpdateOwner(_newOwner);
    }

    /// @dev Rescue stuck ERC20 tokens.
    /// @param _tokens - The address of the tokens to rescue.
    /// @param _recipient - The address of the recipient of rescued tokens.
    function rescue(address[] memory _tokens, address _recipient) external {
        if (msg.sender != owner) revert Unauthorized();
        if (_recipient == address(0)) revert ZeroInput();

        for (uint256 i = 0; i < _tokens.length; i++) {
            IERC20(_tokens[i]).safeTransfer(_recipient, IERC20(_tokens[i]).balanceOf(address(this)));
        }

        emit Rescue(_tokens, _recipient);
    }

    /// @dev Rescue stuck ETH.
    /// @param _recipient - The address of the recipient of rescued ETH.
    function rescueETH(address _recipient) external {
        if (msg.sender != owner) revert Unauthorized();
        if (_recipient == address(0)) revert ZeroInput();
        
        payable(_recipient).sendValue(address(this).balance);

        emit RescueETH(_recipient);
    }

    /********************************** Internal Functions **********************************/

    function _swapGMX(address _fromToken, address _toToken, uint256 _amount) internal returns (uint256) {

        bool _toETH = false;
        if (_fromToken == ETH) {
            _wrapETH(_amount);
            _fromToken = WETH;
        } else if (_toToken == ETH) {
            _toToken = WETH;
            _toETH = true;
        }

        address _router = GMX_ROUTER;
        _approve(_fromToken, _router, _amount);

        address[] memory _path = new address[](2);
        _path[0] = _fromToken;
        _path[1] = _toToken; 

        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        IGMXRouter(_router).swap(_path, _amount, 0, address(this));
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;

        if (_toETH) {
            _unwrapETH(_amount);
        }
        
        return _amount;
    }

    function _swapUniV3(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        
        bool _toETH = false;
        if (_fromToken == ETH) {
            _wrapETH(_amount);
            _fromToken = WETH;
        } else if (_toToken == ETH) {
            _toToken = WETH;
            _toETH = true;
        }
        
        address _router = UNIV3_ROUTER;
        _approve(_fromToken, _router, _amount);

        uint24 _fee = IUniswapV3Pool(_poolAddress).fee();
        
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        IUniswapV3RouterArbi.ExactInputSingleParams memory _params = IUniswapV3RouterArbi.ExactInputSingleParams(
            _fromToken,
            _toToken,
            _fee, 
            address(this), 
            _amount,
            0,
            0
        );

        IUniswapV3RouterArbi(_router).exactInputSingle(_params);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;

        if (_toETH) {
            _unwrapETH(_amount);
        }
        
        return _amount;
    }

    function _swapFraxswapUniV2(address _fromToken, address _toToken, uint256 _amount) internal returns (uint256) {
        
        bool _toETH = false;
        if (_fromToken == ETH) {
            _wrapETH(_amount);
            _fromToken = WETH;
        } else if (_toToken == ETH) {
            _toToken = WETH;
            _toETH = true;
        }

        _approve(_fromToken, FRAXSWAP_UNIV2_ROUTER, _amount);

        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        // uint256[] memory _amounts;
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        IUniswapV2Router(FRAXSWAP_UNIV2_ROUTER).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;

        if (_toETH) {
            _unwrapETH(_amount);
        } 

        // return _amounts[1];
        return _amount;
    }

    function _swapBalancerPoolSingle(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        bytes32 _poolId = IBalancerPool(_poolAddress).getPoolId();
        
        bool _toETH = false;
        if (_fromToken == ETH) {
            _wrapETH(_amount);
            _fromToken = WETH;
        } else if (_toToken == ETH) {
            _toToken = WETH;
            _toETH = true;
        }
        
        _approve(_fromToken, BALANCER_VAULT, _amount);
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        IBalancerVault(BALANCER_VAULT).swap(
            IBalancerVault.SingleSwap({
            poolId: _poolId,
            kind: IBalancerVault.SwapKind.GIVEN_IN,
            assetIn: _fromToken,
            assetOut: _toToken,
            amount: _amount,
            userData: new bytes(0)
            }),
            IBalancerVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
            }),
            0,
            block.timestamp
        );

        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;

        if (_toETH) {
            _unwrapETH(_amount);
        }

        return _amount;
    }

    // ICurvePlainPool
    // ICurveETHPool
    function _swapCurve2Asset(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        ICurvePool _pool = ICurvePool(_poolAddress);
        
        int128 _to = 0;
        int128 _from = 0;
        if (_fromToken == _pool.coins(0) && _toToken == _pool.coins(1)) {
            _from = 0;
            _to = 1;
        } else if (_fromToken == _pool.coins(1) && _toToken == _pool.coins(0)) {
            _from = 1;
            _to = 0;
        } else {
            revert InvalidTokens();
        }
        
        uint256 _before = _toToken == ETH ? address(this).balance : IERC20(_toToken).balanceOf(address(this));

        if (_fromToken == ETH) {
            payable(address(_pool)).functionCallWithValue(abi.encodeWithSignature("exchange(address,address,uint256,uint256)", _from, _to, _amount, 0), _amount);
        } else {
            _approve(_fromToken, _poolAddress, _amount);
            _pool.exchange(_from, _to, _amount, 0);
        }
        return _toToken == ETH ? address(this).balance - _before : IERC20(_toToken).balanceOf(address(this)) - _before;
    }

    // ICurveCryptoV2Pool
    function _swapCurveCryptoV2(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        ICurveCryptoV2Pool _pool = ICurveCryptoV2Pool(_poolAddress);
        
        uint256 _to = 0;
        uint256 _from = 0;
        if (_fromToken == _pool.coins(0) && _toToken == _pool.coins(1)) {
            _from = 0;
            _to = 1;
        } else if (_fromToken == _pool.coins(1) && _toToken == _pool.coins(0)) {
            _from = 1;
            _to = 0;
        } else {
            revert InvalidTokens();
        }
        
        uint256 _before = _toToken == ETH ? address(this).balance : IERC20(_toToken).balanceOf(address(this));

        if (_pool.coins(_from) == ETH) {
            payable(address(_pool)).functionCallWithValue(abi.encodeWithSignature("exchange(address,address,uint256,uint256)", _from, _to, _amount, 0), _amount);
        } else {
            _approve(_fromToken, _poolAddress, _amount);
            _pool.exchange(_from, _to, _amount, 0);
        }
        return _toToken == ETH ? address(this).balance - _before : IERC20(_toToken).balanceOf(address(this)) - _before;
    }

    // ICurveBase3Pool
    function _swapCurveBase3Pool(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        ICurveBase3Pool _pool = ICurveBase3Pool(_poolAddress);
        
        int256 _to = 0;
        int256 _from = 0;
        for(int256 i = 0; i < 3; i++) {
            if (_fromToken == _pool.coins(i.toUint256())) {
                _from = i;
            } else if (_toToken == _pool.coins(i.toUint256())) {
                _to = i;
            }
        }

        _approve(_fromToken, _poolAddress, _amount);
        
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        _pool.exchange(_from.toInt128(), _to.toInt128(), _amount, 0);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;
        
        return _amount;
    }

    // ICurve3Pool
    function _swapCurve3Asset(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        ICurve3Pool _pool = ICurve3Pool(_poolAddress);

        bool _toETH = false;
        if (_fromToken == ETH) {
            _wrapETH(_amount);
            _fromToken = WETH;
        } else if (_toToken == ETH) {
            _toToken = WETH;
            _toETH = true;
        }

        uint256 _to = 0;
        uint256 _from = 0;
        for(uint256 i = 0; i < 3; i++) {
            if (_fromToken == _pool.coins(i)) {
                _from = i;
            } else if (_toToken == _pool.coins(i)) {
                _to = i;
            }
        }

        _approve(_fromToken, _poolAddress, _amount);
        
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        _pool.exchange(_from, _to, _amount, 0);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;
        
        if (_toETH) {
            _unwrapETH(_amount);
        }
        return _amount;
    }

    function _swapCurve4Pool(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        ICurvesUSD4Pool _pool = ICurvesUSD4Pool(_poolAddress);

        int128 _to = 0;
        int128 _from = 0;
        for(int128 i = 0; i < 4; i++) {
            if (_fromToken == _pool.coins(i)) {
                _from = i;
            } else if (_toToken == _pool.coins(i)) {
                _to = i;
            }
        }

        _approve(_fromToken, _poolAddress, _amount);
        
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        _pool.exchange(_from, _to, _amount, 0);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;
        
        return _amount;
    }
    
    // ICurveSBTCPool
    function _swapCurveSBTCPool(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        ICurveSBTCPool _pool = ICurveSBTCPool(_poolAddress);

        int128 _to = 0;
        int128 _from = 0;
        for(int128 i = 0; i < 3; i++) {
            if (_fromToken == _pool.coins(i)) {
                _from = i;
            } else if (_toToken == _pool.coins(i)) {
                _to = i;
            }
        }

        _approve(_fromToken, _poolAddress, _amount);
        
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        _pool.exchange(_from, _to, _amount, 0);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;
        
        return _amount;
    }

    // ICurveCryptoETHV2Pool
    function _swapCurveETHV2(address _fromToken, address _toToken, uint256 _amount, address _poolAddress) internal returns (uint256) {
        ICurveCryptoETHV2Pool _pool = ICurveCryptoETHV2Pool(_poolAddress);
        
        bool _toETH = false;
        if (_fromToken == ETH) {
            _wrapETH(_amount);
            _fromToken = WETH;
        } else if (_toToken == ETH) {
            _toToken = WETH;
            _toETH = true;
        }

        _approve(_fromToken, _poolAddress, _amount);

        uint256 _to = 0;
        uint256 _from = 0;
        if (_fromToken == _pool.coins(0) && _toToken == _pool.coins(1)) {
            _from = 0;
            _to = 1;
        } else if (_fromToken == _pool.coins(1) && _toToken == _pool.coins(0)) {
            _from = 1;
            _to = 0;
        } else {
            revert InvalidTokens();
        }
        
        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        _pool.exchange(_from, _to, _amount, 0, false);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;

        if (_toETH) {
            _unwrapETH(_amount);
        }
        return _amount;
    }

    // SushiPool
    function _swapSushiPool(address _fromToken, address _toToken, uint256 _amount) internal returns (uint256) {
        
        bool _toETH = false;
        if (_fromToken == ETH) {
            _wrapETH(_amount);
            _fromToken = WETH;
        } else if (_toToken == ETH) {
            _toToken = WETH;
            _toETH = true;
        }
        
        address _router = SUSHI_ARB_ROUTER;
        _approve(_fromToken, _router, _amount);

        address[] memory path = new address[](2);
        path[0] = _fromToken;
        path[1] = _toToken;

        uint256 _before = IERC20(_toToken).balanceOf(address(this));
        IUniswapV2Router(_router).swapExactTokensForTokens(_amount, 0, path, address(this), block.timestamp);
        _amount = IERC20(_toToken).balanceOf(address(this)) - _before;

        if (_toETH) {
            _unwrapETH(_amount);
        }

        return _amount;
    }

    function _wrapETH(uint256 _amount) internal {
        payable(WETH).functionCallWithValue(abi.encodeWithSignature("deposit()"), _amount);
    }

    function _unwrapETH(uint256 _amount) internal {
        IWETH(WETH).withdraw(_amount);
    }

    function _approve(address _token, address _spender, uint256 _amount) internal {
        IERC20(_token).safeApprove(_spender, 0);
        IERC20(_token).safeApprove(_spender, _amount);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.17;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity 0.8.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IFortressSwap {

    /// @notice swap _amount of _fromToken to _toToken.
    /// @param _fromToken The address of the token to swap from.
    /// @param _toToken The address of the token to swap to.
    /// @param _amount The amount of _fromToken to swap.
    /// @return _amount The amount of _toToken after swap.  
    function swap(address _fromToken, address _toToken, uint256 _amount) external payable returns (uint256);

    /********************************** Events & Errors **********************************/

    event Swap(address indexed _fromToken, address indexed _toToken, uint256 _amount);
    event UpdateRoute(address indexed fromToken, address indexed toToken, address[] indexed poolAddress);
    event DeleteRoute(address indexed fromToken, address indexed toToken);
    event UpdateOwner(address indexed _newOwner);
    event Rescue(address[] indexed _tokens, address indexed _recipient);
    event RescueETH(address indexed _recipient);

    error Unauthorized();
    error UnsupportedPoolType();
    error FailedToSendETH();
    error InvalidTokens();
    error RouteUnavailable();
    error AmountMismatch();
    error TokenMismatch();
    error RouteAlreadyExists();
    error ZeroInput();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Functions for swapping tokens via Uniswap V3
interface IUniswapV3RouterArbi {
 
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGMXRouter {

    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICurvePool {

  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external payable returns (uint256);

  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
  
  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);
  
  function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/cvxeth
// https://curve.fi/crveth
// https://curve.fi/spelleth
// https://curve.fi/factory-crypto/3 - FXS/ETH
// https://curve.fi/factory-crypto/8 - YFI/ETH
// https://curve.fi/factory-crypto/85 - BTRFLY/ETH
// https://curve.fi/factory-crypto/39 - KP3R/ETH
// https://curve.fi/factory-crypto/43 - JPEG/ETH
// https://curve.fi/factory-crypto/55 - TOKE/ETH
// https://curve.fi/factory-crypto/21 - OHM/ETH

interface ICurveCryptoETHV2Pool {

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount, bool use_eth) external payable returns (uint256);

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external payable returns (uint256);

    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 _min_amount, bool use_eth) external returns (uint256);

    function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/sbtc

interface ICurveSBTCPool {
  
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable returns (uint256);
    
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external payable;
    
    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);

    function coins(int128 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/factory-crypto/37 - USDC/STG
// https://curve.fi/factory-crypto/23 - USDC/FIDU
// https://curve.fi/factory-crypto/4 - wBTC/BADGER
// https://curve.fi/factory-crypto/18 - cvxFXS/FXS
// https://curve.fi/factory-crypto/62 - pxCVX/CVX
// https://curve.fi/factory-crypto/22 - SILO/FRAX
// https://curve.fi/factory-crypto/48 - FRAX/FPI
// https://curve.fi/factory-crypto/90 - FXS/FPIS

interface ICurveCryptoV2Pool {

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
    
    function remove_liquidity_one_coin(uint256 _token_amount, uint256 i, uint256 _min_amount) external returns (uint256);

    function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/tricrypto2 - ETH is wETH

interface ICurve3Pool {
  
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external payable;
    
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable;
    
    function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external payable;

    function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/susdv2

interface ICurvesUSD4Pool {
  
    function add_liquidity(uint256[4] memory amounts, uint256 min_mint_amount) external;
    
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
    
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount) external;

    function coins(int128 arg0) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/3pool
// https://curve.fi/ib

interface ICurveBase3Pool {
  
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;
    
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external;

    function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/fraxusdc
// https://curve.fi/eursusd
// https://curve.fi/link
// https://curve.fi/eurs
// https://curve.fi/eursusd
// https://curve.fi/link
// CRV/cvxCRV - https://curve.fi/factory/22
// FXS/sdFXS - https://curve.fi/#/ethereum/pools/factory-v2-100

interface ICurvePlainPool {
  
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);

  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

  function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/frax
// https://curve.fi/tusd
// https://curve.fi/lusd
// https://curve.fi/gusd
// https://curve.fi/mim
// https://curve.fi/factory/113 - pUSD
// https://curve.fi/alusd

interface ICurveCRVMeta {
  
  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);

  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

  // function remove_liquidity(uint256 _burn_amount, uint256[2] memory _min_amounts) external returns (uint256[2]);

  function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/factory/144 - tUSD/FRAXBP
// https://curve.fi/factory/147 - alUSD/FRAXBP
// https://curve.fi/factory/137 - LUSD/FRAXBP

interface ICurveFraxMeta {

  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function remove_liquidity_one_coin(uint256 token_amount, int128 i, uint256 min_amount) external returns (uint256);

  function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);

  function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// https://curve.fi/factory-crypto/95 - CVX/crvFRAX
// https://curve.fi/factory-crypto/94 - cvxFXS/crvFRAX
// https://curve.fi/factory-crypto/96 - ALCX/crvFRAX
// https://curve.fi/factory-crypto/97 - cvxCRV/crvFRAX

interface ICurveFraxCryptoMeta {

  function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256);

  function remove_liquidity_one_coin(uint256 token_amount, uint256 i, uint256 min_amount) external returns (uint256);

  function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);

  function coins(uint256 index) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV3Pool {
    
  function token0() external returns (address);

  function token1() external returns (address);

  function fee() external returns (uint24);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IUniswapV2Router {

    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma abicoder v2;

import "src/mainnet/interfaces/IAsset.sol";

interface IBalancerVault {
    
    enum JoinKind {
        INIT,
        EXACT_TOKENS_IN_FOR_BPT_OUT,
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT
    }

    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint256 amount;
        bytes userData;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    struct ExitPoolRequest{
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance; 
    }

    function getPoolTokens(bytes32 poolId) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external payable returns (uint256 amountCalculated);

    function batchSwap(SwapKind kind, BatchSwapStep[] memory swaps, IAsset[] memory assets, FundManagement memory funds, int256[] memory limits, uint256 deadline) external payable returns (int256[] memory);

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancerPool {

  function getPoolId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}