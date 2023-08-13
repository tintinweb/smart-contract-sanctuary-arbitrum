// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SupportingSwap, SwapLibrary, TransferHelper, FeeStore, ISwapFactory, ISwapPair, IWETH, IERC20 } from "./SupportingSwapUpgraded.sol";

contract SwapRouter is SupportingSwap {

    constructor(
        address _factory, 
        uint8 _adminFee, 
        address _adminFeeAddress, 
        address _adminFeeSetter
    ) FeeStore(_factory, _adminFee, _adminFeeAddress, _adminFeeSetter) {
        factory = _factory;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function initialize(address _weth, address[] calldata _stables) external {
        require(msg.sender == adminFeeSetter && WETH == address(0), "Invalid Initialize call");
        require(_weth != address(0), "Swap: INVALID_ADDRESS");
        WETH = _weth;
        for (uint i = 0; i < _stables.length; i++) {
            require(_stables[i] != address(0), "Swap: INVALID_ADDRESS");
            stables[_stables[i]] = true;
        }
    }

    // **** ADD LIQUIDITY ****
    function addLiquidity(
        address tokenA,
        address tokenB,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (
        uint amountA, 
        uint amountB, 
        uint liquidity
    ) {
        address pair;
        (amountA, amountB, pair) = _addLiquidity(
            tokenA, 
            tokenB, 
            feeTaker, 
            amountADesired, 
            amountBDesired, 
            amountAMin, 
            amountBMin
        );
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
        liquidity = ISwapPair(pair).mint(to);
    }

    function addLiquidityETH(
        address token,
        address feeTaker,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (
        uint amountETH, 
        uint amountToken, 
        uint liquidity
    ) {
        address pair;
        (amountETH, amountToken, pair) = _addLiquidity(
            WETH,
            token,
            feeTaker,
            msg.value,
            amountTokenDesired,
            amountETHMin,
            amountTokenMin
        );

        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        assert(IWETH(WETH).transfer(pair, amountETH));
        liquidity = ISwapPair(pair).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        address pair = SwapLibrary.pairFor(tokenA, tokenB);
        uint value = approveMax ? type(uint).max - 1 : liquidity;
        ISwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        address pair = SwapLibrary.pairFor(token, WETH);
        uint value = approveMax ? type(uint).max - 1 : liquidity;
        ISwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        address pair = SwapLibrary.pairFor(token, WETH);
        uint value = approveMax ? type(uint).max - 1 : liquidity;
        ISwapPair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        address pair = SwapLibrary.pairFor(tokenA, tokenB);
        TransferHelper.safeTransferFrom(pair, msg.sender, pair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = ISwapPair(pair).burn(to);
        (address token0,) = SwapLibrary.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, "SwapRouter: INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "SwapRouter: INSUFFICIENT_B_AMOUNT");
    }

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        IWETH(WETH).withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

    function getPair(address tokenA, address tokenB) public view returns (address) {
        return ISwapFactory(factory).getPair(tokenA, tokenB);
    }

    function getAmountsOut(
        uint amountIn, 
        address[] memory path, 
        uint totalFee
    ) public view virtual override returns (
        uint[] memory amounts
    ) {
        return SwapLibrary.getAmountsOut(amountIn, path, totalFee, adminFee);
    }

    function getAmountsIn(
        uint amountOut, 
        address[] memory path, 
        uint totalFee
    ) public view virtual override returns (
        uint[] memory amounts
    ) {
        return SwapLibrary.getAmountsIn(amountOut, path, totalFee, adminFee);
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB, address pair) {
        // create the pair if it doesn't exist yet
        pair = getPair(tokenA, tokenB);
        if (pair == address(0)) {
            if(tokenA == WETH || stables[tokenA]) {
                pair = ISwapFactory(factory).createPair(tokenB, tokenA, feeTaker != address(0), feeTaker);
                pairFeeAddress[pair] = tokenA;
            } else {
                pair = ISwapFactory(factory).createPair(tokenA, tokenB, feeTaker != address(0), feeTaker);
                pairFeeAddress[pair] = tokenB;
            }
        }
        (uint reserveA, uint reserveB) = SwapLibrary.getReserves(tokenA, tokenB);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            if (tokenA == WETH || stables[tokenA]) {
                pairFeeAddress[pair] = tokenA;
            } else {
                pairFeeAddress[pair] = tokenB;
            }
        } else {
            uint amountBOptimal = SwapLibrary.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "SwapRouter: INSUFFICIENT_B_AMOUNT");
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint amountAOptimal = SwapLibrary.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, "SwapRouter: INSUFFICIENT_A_AMOUNT");
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ISwapRouter } from "./interfaces/ISwapRouter.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";
import { SwapLibrary, ISwapPair } from "./libraries/SwapLibraryForUpgraded.sol";
import { ISwapFactory } from "./interfaces/ISwapFactory.sol";
import { IERC20 } from "./interfaces/IERC20.sol";
import { IWETH } from "./interfaces/IWETH.sol";
import { IToken } from "./interfaces/IToken.sol";
import { FeeStore } from "./FeeStore.sol";

abstract contract SupportingSwap is FeeStore, ISwapRouter {

    address public override factory;
    address public override WETH;
    mapping(address => bool) public override stables;
    uint8 private maxHops = 4;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "SwapRouter: EXPIRED");
        _;
    }

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) {
        require(path.length <= maxHops, "SwapRouter: TOO_MANY_HOPS");
        (address tokenA, address tokenB) = SwapLibrary.sortTokens(path[0], path[path.length - 1]);
        address pair = ISwapFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "SwapRouter: PAIR_NOT_EXIST");
        uint adminFeeDeduct;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(path[0], msg.sender, adminFeeAddress, adminFeeDeduct);
        }
        uint amountOut = _swapWithPairFees(amountIn, msg.sender, path, to);
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (amountOut,adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountOut, adminFee);
            TransferHelper.safeTransferFrom(path[path.length - 1], address(this), adminFeeAddress, adminFeeDeduct);
        }
        require(amountOut >= amountOutMin, "SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[path.length - 1], address(this), to, amountOut);
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        require(path.length <= maxHops, "SwapRouter: TOO_MANY_HOPS");
        (address tokenA, address tokenB) = SwapLibrary.sortTokens(path[0], path[path.length - 1]);
        address pair = ISwapFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "SwapRouter: PAIR_NOT_EXIST");
        uint adminFeeDeduct;
        uint totalAmountOut;
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (,adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountOut, adminFee);
            totalAmountOut = amountOut + adminFeeDeduct;
        } else {
            totalAmountOut = amountOut;
        }
        (uint amountIn, uint _adminFeeDeduct) = SwapLibrary.getRequiredAmountIn(totalAmountOut, path, adminFee, msg.sender);
        adminFeeDeduct = _adminFeeDeduct;
        require((path[0] == pairFeeAddress[pair] ? (amountIn+adminFeeDeduct) : amountIn) <= amountInMax, "SwapRouter: EXCESSIVE_INPUT_AMOUNT");
        if (path[0] == pairFeeAddress[pair]) TransferHelper.safeTransferFrom(path[0], msg.sender, adminFeeAddress, adminFeeDeduct);
        uint amountReceived = _swapWithPairFees(amountIn, msg.sender, path, address(this));
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (, uint __adminFeeDedeuct) = SwapLibrary.adminFeeCalculation(amountReceived, adminFee);
            adminFeeDeduct = __adminFeeDedeuct;
            TransferHelper.safeTransferFrom(path[path.length - 1], address(this), adminFeeAddress, adminFeeDeduct);
        }
        require(amountReceived == (path[path.length - 1] == pairFeeAddress[pair] ? amountOut + adminFeeDeduct : amountOut), "SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[path.length - 1], address(this), to, amountOut);
    }



    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external virtual override ensure(deadline) {
        require(path.length <= maxHops, "SwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, "SwapRouter: INVALID_PATH");
        (address tokenA, address tokenB) = SwapLibrary.sortTokens(path[0], path[path.length - 1]);
        address pair = ISwapFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "SwapRouter: PAIR_NOT_EXIST");
        uint adminFeeDeduct;
        uint totalAmountOut;
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (,adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountOut, adminFee);
            totalAmountOut = amountOut + adminFeeDeduct;
        } else {
            totalAmountOut = amountOut;
        }
        (uint amountIn, uint _adminFeeDeduct) = SwapLibrary.getRequiredAmountIn(totalAmountOut, path, adminFee, msg.sender);
        adminFeeDeduct = _adminFeeDeduct;
        require((path[0] == pairFeeAddress[pair] ? (amountIn+adminFeeDeduct) : amountIn) <= amountInMax, "SwapRouter: EXCESSIVE_INPUT_AMOUNT");
        if (path[0] == pairFeeAddress[pair]) TransferHelper.safeTransferFrom(path[0], msg.sender, adminFeeAddress, adminFeeDeduct);
        uint amountReceived = _swapWithPairFees(amountIn, msg.sender, path, address(this));
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (, uint __adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountReceived, adminFee);
            adminFeeDeduct = __adminFeeDeduct;
            TransferHelper.safeTransferFrom(path[path.length - 1], address(this), adminFeeAddress, adminFeeDeduct);
        }
        require(amountReceived == (path[path.length - 1] == pairFeeAddress[pair] ? amountOut + adminFeeDeduct : amountOut), "SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) public virtual override ensure(deadline) {
        require(path.length <= maxHops, "SwapRouter: TOO_MANY_HOPS");
        require(path[path.length - 1] == WETH, "SwapRouter: INVALID_PATH");
        (address tokenA, address tokenB) = SwapLibrary.sortTokens(path[0], path[path.length - 1]);
        address pair = ISwapFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "SwapRouter: PAIR_NOT_EXIST");
        uint adminFeeDeduct;
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(path[0], msg.sender, adminFeeAddress, adminFeeDeduct);
        }
        uint amountOut = _swapWithPairFees(amountIn, msg.sender, path, to);
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (amountOut,adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountOut, adminFee);
            TransferHelper.safeTransferFrom(path[path.length - 1], address(this), adminFeeAddress, adminFeeDeduct);
        }
        require(amountOut >= amountOutMin, "SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)  public virtual override payable ensure(deadline) {
        require(path.length <= maxHops, "SwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, "SwapRouter: INVALID_PATH");
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();
        (address tokenA, address tokenB) = SwapLibrary.sortTokens(path[0], path[path.length - 1]);
        address pair = ISwapFactory(factory).getPair(tokenA, tokenB);
        uint adminFeeDeduct;
        require(pair != address(0), "SwapRouter: PAIR_NOT_EXIST");
        if (path[0] == pairFeeAddress[pair]) {
            (amountIn, adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountIn, adminFee);
            TransferHelper.safeTransferFrom(path[0], msg.sender, adminFeeAddress, adminFeeDeduct);
        }
        uint amountOut = _swapWithPairFees(amountIn, msg.sender, path, to);
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (amountOut,adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountOut, adminFee);
            TransferHelper.safeTransferFrom(path[path.length - 1], address(this), adminFeeAddress, adminFeeDeduct);
        }
        require(amountOut >= amountOutMin, "SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[path.length - 1], address(this), to, amountOut);
    }

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external virtual override payable ensure(deadline) {
        require(path.length <= maxHops, "SwapRouter: TOO_MANY_HOPS");
        require(path[0] == WETH, "SwapRouter: INVALID_PATH");
        uint amountProvided = msg.value;
        IWETH(WETH).deposit{value: amountProvided}();
        (address tokenA, address tokenB) = SwapLibrary.sortTokens(path[0], path[path.length - 1]);
        address pair = ISwapFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "SwapRouter: PAIR_NOT_EXIST");
        uint adminFeeDeduct;
        uint totalAmountOut;
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (,adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountOut, adminFee);
            totalAmountOut = amountOut + adminFeeDeduct;
        } else {
            totalAmountOut = amountOut;
        }
        (uint amountIn, uint _adminFeeDeduct) = SwapLibrary.getRequiredAmountIn(totalAmountOut, path, adminFee, msg.sender);
        adminFeeDeduct = _adminFeeDeduct;
        require(amountIn <= amountProvided, "SwapRouter: INSUFFICIENT_ETH_AMOUNT");
        if (path[0] == pairFeeAddress[pair]) TransferHelper.safeTransferFrom(path[0], msg.sender, adminFeeAddress, adminFeeDeduct);
        uint amountReceived = _swapWithPairFees(amountIn, msg.sender, path, address(this));
        if (path[path.length - 1] == pairFeeAddress[pair]) {
            (, uint __adminFeeDeduct) = SwapLibrary.adminFeeCalculation(amountReceived, adminFee);
            adminFeeDeduct = __adminFeeDeduct;
            TransferHelper.safeTransferFrom(path[path.length - 1], address(this), adminFeeAddress, adminFeeDeduct);
        }
        require(amountReceived == (path[path.length - 1] == pairFeeAddress[pair] ? amountOut + adminFeeDeduct : amountOut), "SwapRouter: INSUFFICIENT_OUTPUT_AMOUNT");
        TransferHelper.safeTransferFrom(path[path.length - 1], address(this), to, amountOut);
        if (amountIn < amountProvided) {
            IWETH(WETH).withdraw(amountProvided - amountIn);
            TransferHelper.safeTransferETH(msg.sender, amountProvided - amountIn);
        }
    }


    // **** SWAP (supporting fee-on-transfer tokens) ****
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override {
        swapExactTokensForTokens(amountIn, amountOutMin, path, to, deadline);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override payable {
        swapExactETHForTokens(amountOutMin, path, to, deadline);
    }

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override {
        swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
    }

     // sends the amounts with each swap.
    function _swapWithPairFees(
        uint amountIn,
        address _feeCheck, 
        address[] memory path, 
        address _to
    ) internal virtual returns (uint256 amountOut) {
        uint amountOutput;
        for (uint i; i < path.length - 1; i++) {
            uint _amountIn = i == 0 ? amountIn : amountOutput;
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = SwapLibrary.sortTokens(input, output);
            ISwapPair pair = ISwapPair(SwapLibrary.pairFor(input, output));
            amountOutput = SwapLibrary._amountOut(_feeCheck, input, output, _amountIn);
            uint amountFee = _amountIn - amountOutput;
            (uint amount0, uint amount1, uint amount0Fee, uint amount1Fee) = input == token0 ? (uint(0), amountOutput, uint(0), amountFee) : (amountOutput, uint(0), amountFee, uint(0));
            TransferHelper.safeTransferFrom(input, i == 0 ? msg.sender : SwapLibrary.pairFor(input, path[i-1]), address(pair), _amountIn);
            address to = i == path.length - 2 ? _to : SwapLibrary.pairFor(output, path[i + 2]);
            pair.swap(amount0, amount1, amount0Fee, amount1Fee, to, new bytes(0));
            amountOut = amount0 > 0 ? amount0 : amount1;
        }
    }


    function setMaxHops(uint8 _maxHops) external {
        require(msg.sender == adminFeeSetter, "Swap: NOT_AUTHORIZED");
        require(_maxHops >= 2, "Swap: Less than minimum");
        maxHops = _maxHops;
    }

    function setStableToken(address _token, bool _flag) external {
        require(msg.sender == adminFeeSetter, "Swap: NOT_AUTHORIZED");
        stables[_token] = _flag;
        emit StableTokenUpdated(_token, _flag);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ISwapFactory } from "./interfaces/ISwapFactory.sol";
import { ISwapPair } from "./interfaces/ISwapPair.sol";

abstract contract FeeStore {
    uint public swapFee;
    uint public adminFee;
    address public adminFeeAddress;
    address public adminFeeSetter;
    address public factoryAddress;
    mapping(address => address) public pairFeeAddress;

    event AdminFeeSet(uint adminFee, address adminFeeAddress);
    event SwapFeeSet(uint swapFee);
    event StableTokenUpdated(address token, bool isStable);

    constructor (
        address _factory, 
        uint256 _adminFee, 
        address _adminFeeAddress, 
        address _adminFeeSetter
    ) {
        factoryAddress = _factory;
        adminFee = _adminFee;
        adminFeeAddress = _adminFeeAddress;
        adminFeeSetter = _adminFeeSetter;
    }

    function setAdminFee(address _adminFeeAddress, uint _adminFee) external {
        require(msg.sender == adminFeeSetter, "Swap: NOT_AUTHORIZED");
        require(_adminFee + 17 <= 100, "Swap: EXCEEDS MAX FEE");
        adminFeeAddress = _adminFeeAddress;
        adminFee = _adminFee;
        swapFee = _adminFee + 17;
        emit AdminFeeSet(adminFee, adminFeeAddress);
        emit SwapFeeSet(swapFee);
    }

    function setAdminFeeSetter(address _adminFeeSetter) external {
        require(msg.sender == adminFeeSetter, "Swap: NOT_AUTHORIZED");
        adminFeeSetter = _adminFeeSetter;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IToken {

    function addPair(address pair, address token) external;

    function depositLPFee(uint amount, address token) external;

    function handleFee(uint amount, address token) external;

    function getTotalFee(address _feeCheck) external view returns (uint);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISwapFactory {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(
        address tokenA, 
        address tokenB, 
        bool supportsTokenFee, 
        address feeTaker
    ) external returns (
        address pair
    );

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function routerInitialize(address) external;

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint) external view returns (address pair);

    function allPairsLength() external view returns (uint);

    function pairExist(address pair) external view returns (bool);

    function routerAddress() external view returns (address);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ISwapPair } from "../interfaces/ISwapPair.sol";
import { IToken } from "../interfaces/IToken.sol";
import { IFeeStore } from "../interfaces/IFeeStore.sol";
import { IERC20 } from "../interfaces/IERC20.sol";

interface IFactory {
    function computeAddress(address token0, address token1) external view returns (address pair);
}

library SwapLibrary {

    // calculates the CREATE2 address for a pair
    function pairFor(address tokenA, address tokenB) internal view returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        address factory = IFeeStore(address(this)).factoryAddress();
        pair = IFactory(factory).computeAddress(token0, token1);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address tokenA, 
        address tokenB
    ) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,,) = ISwapPair(pairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }
    function _amountOut(
        address _feeCheck, 
        address input, 
        address output,
        uint amountIn
    ) internal view returns (uint amountOutput) {
        (address token0,) = sortTokens(input, output);
        ISwapPair pair = ISwapPair(pairFor(input, output));
        (uint reserve0, uint reserve1,, address baseToken) = pair.getReserves();
        address feeTaker = pair.feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(_feeCheck) : 0;
        bool baseIn = baseToken == input;
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountOutput = getAmountOut(
            amountIn, 
            reserveInput, 
            reserveOutput, 
            baseToken != address(0), 
            baseIn, 
            totalFee,
            0
        );
    }
    function _amountIn(
        address _feeCheck, 
        address input, 
        address output,
        uint amountOut
    ) internal view returns (uint amountInput) {
        (address token0,) = sortTokens(input, output);
        ISwapPair pair = ISwapPair(pairFor(input, output));
        (uint reserve0, uint reserve1,, address baseToken) = pair.getReserves();
        address feeTaker = pair.feeTaker();
        uint totalFee = feeTaker != address(0) ? IToken(feeTaker).getTotalFee(_feeCheck) : 0;
        bool baseOut = baseToken == output;
        (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        (amountInput,) = getAmountIn(
            amountOut,
            reserveInput,
            reserveOutput,
            baseToken != address(0),
            baseOut,
            totalFee,
            0
        );
    }
    function getRequiredAmountIn(uint totalAmountOut, address[] memory path, uint adminFee, address _feeCheck) internal view returns (uint amountInput, uint adminFeeDeduct) {
        for (uint i = path.length - 1; i > 0; i--) {
            uint amountOut = i == path.length - 1 ? totalAmountOut : amountInput;
            amountInput = _amountIn(_feeCheck, path[i-1], path[i], amountOut);
            if (i == 1) adminFeeDeduct = (amountInput * (10000 - adminFee)) / (10**4);
        }
    }
    function adminFeeCalculation(
        uint256 _amounts, 
        uint256 _adminFee
    ) internal pure returns (
        uint, 
        uint
    ) {
        uint adminFeeDeduct = (_amounts * _adminFee) / 10000;
        uint swapAmount = _amounts - adminFeeDeduct;

        return (swapAmount, adminFeeDeduct);
    }


     // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SwapLibrary: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "SwapLibrary: ZERO_ADDRESS");
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, "SwapLibrary: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "SwapLibrary: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint amountIn, 
        uint reserveIn, 
        uint reserveOut, 
        bool tokenFee, 
        bool baseIn, 
        uint totalFee,
        uint lpFee
    ) internal pure returns (
        uint amountOut
    ) {
        require(amountIn > 0, "SwapLibrary: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SwapLibrary: INSUFFICIENT_LIQUIDITY");
        uint amountInMultiplier = baseIn && tokenFee ? 10000 - totalFee : 10000;
        uint swapFeeAdjuster = amountInMultiplier - lpFee;
        uint amountInWithFee = amountIn * swapFeeAdjuster;
        uint numerator = amountInWithFee * reserveOut * 10**18;
        uint denominator = (reserveIn * 10000) + amountIn;
        uint rawAmountOut = numerator / denominator / 10**18;
        amountOut = lpFee == 0 ? ((rawAmountOut * 9983) / 10000) : rawAmountOut;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint amountOut, 
        uint reserveIn, 
        uint reserveOut, 
        bool tokenFee, 
        bool baseOut,
        uint totalFee,
        uint lpFee
    ) internal pure returns (
        uint, 
        uint
    ) {
        require(amountOut > 0, "SwapLibrary: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SwapLibrary: INSUFFICIENT_LIQUIDITY");
        return (amountOut * reserveIn * 10000 * 10**18 / reserveOut / (10000 - (lpFee > 0 ? lpFee : 17) - (baseOut && tokenFee ? totalFee : 0)) / 10**18, amountOut);
    }




    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        uint amountIn, 
        address[] memory path, 
        uint totalFee,
        uint _adminFee
    ) internal view returns (
        uint[] memory amounts
    ) {
        require(path.length >= 2, "SwapLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            ISwapPair pair = ISwapPair(pairFor(path[i], path[i + 1]));
            address _feeToken = IFeeStore(address(this)).pairFeeAddress(address(pair));
            uint lpFee = _feeToken == path[i] ? 17 : 0;
            address baseToken = pair.baseToken();
            bool baseIn = baseToken == path[i] && baseToken != address(0);
            (uint reserveIn, uint reserveOut) = getReserves(path[i], path[i + 1]);
            uint adjustedIn = i == 0 ? amounts[i] : ((amounts[i] * (10000 - _adminFee)) / 10000);
            amounts[i + 1] = getAmountOut(
                adjustedIn, 
                reserveIn, 
                reserveOut, 
                baseToken != address(0), 
                baseIn, 
                totalFee,
                lpFee
            );
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        uint amountOut, 
        address[] memory path, 
        uint totalFee,
        uint _adminFee
    ) internal view returns (
        uint[] memory amounts
    ) {
        require(path.length >= 2, "SwapLibrary: INVALID_PATH");
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            ISwapPair pair = ISwapPair(pairFor(path[i - 1], path[i]));
            address _feeToken = IFeeStore(address(this)).pairFeeAddress(address(pair));
            uint lpFee = 17;
            address baseToken = pair.baseToken();
            bool baseOut = baseToken == path[i] && baseToken != address(0);
            (uint reserveIn, uint reserveOut) = getReserves(path[i - 1], path[i]);

            uint adjustedOut = i > 1 && _feeToken == path[i - 1] ? 
                ((amounts[i] * 10000) / (10000 - _adminFee)) : amounts[i];

            (amounts[i - 1], amounts[i]) = getAmountIn(
                adjustedOut, 
                reserveIn, 
                reserveOut, 
                baseToken != address(0), 
                baseOut, 
                totalFee,
                lpFee
            );
        }
        amounts[amounts.length - 1] = amountOut;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.16;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper::safeApprove: approve failed"
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper::safeTransfer: transfer failed"
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)")));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      "TransferHelper: transferFrom failed"
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "TransferHelper: safeTransferETH failed");
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ISwapRouter01 } from "./ISwapRouter01.sol";

interface ISwapRouter is ISwapRouter01 {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IFeeStore {

    function pairFeeAddress(address token) external view returns (address);

    function factoryAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISwapPair {

    event Approval(address indexed owner, address indexed spender, uint value);

    event Transfer(address indexed from, address indexed to, uint value);

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

    function updateTotalFee(uint totalFee) external returns (bool);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function permit(
        address owner, 
        address spender, 
        uint value, 
        uint deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external;

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        uint amount0Out, 
        uint amount1Out, 
        uint amount0Fee, 
        uint amount1Fee, 
        address to, 
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function setBaseToken(address _baseToken) external;

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function baseToken() external view returns (address);

    function feeTaker() external view returns (address);

    function nonces(address owner) external view returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (
        uint112 reserve0, 
        uint112 reserve1, 
        uint32 blockTimestampLast, 
        address _baseToken
    );

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISwapRouter01 {

    function addLiquidity(
        address tokenA,
        address tokenB,
        address feeTaker,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        address feeTaker,
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
    ) external;

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable;

    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external;

    function swapExactTokensForETH(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external;

    function swapETHForExactTokens(
        uint amountOut, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable;

    function getAmountsOut(
        uint256 amountIn, 
        address[] calldata path, 
        uint totalFee
    ) external view returns (uint256[] memory amounts);

    function getAmountsIn(
        uint256 amountOut, 
        address[] calldata path, 
        uint totalFee
    ) external view returns (uint256[] memory amounts);

    function factory() external view returns (address);

    function WETH() external view returns (address);

    function stables(address token) external view returns (bool);

}