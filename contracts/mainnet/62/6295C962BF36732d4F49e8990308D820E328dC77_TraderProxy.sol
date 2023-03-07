/**
 *Submitted for verification at Arbiscan on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ISwappiRouter01 {
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

interface ChiToken {
    function freeUpTo(uint256 value) external;
}

interface LPPair {
     function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
     function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint) external;
}

library PancakeLibrary {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address pair, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        LPPair Pair = LPPair(pair);
        (uint reserve0, uint reserve1,) = Pair.getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'PancakeLibrary: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'PancakeLibrary: INSUFFICIENT_LIQUIDITY');
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint feeRatio) internal pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * feeRatio;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 10000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut, uint feeRatio) internal pure returns (uint amountIn) {
        uint numerator = reserveIn * amountOut * 10000;
        uint denominator = (reserveOut - amountOut) * feeRatio;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address pair, uint amountIn, address path_0, address path_1, uint feeRatio) internal view returns (uint amountOut) {
        (uint reserveIn, uint reserveOut) = getReserves(pair, path_0, path_1);
        amountOut = getAmountOut(amountIn, reserveIn, reserveOut, feeRatio);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address pair, uint amountOut, address path_0, address path_1, uint feeRatio) internal view returns (uint amountIn) {
        (uint reserveIn, uint reserveOut) = getReserves(pair, path_0, path_1);
        amountIn = getAmountIn(amountOut, reserveIn, reserveOut, feeRatio);
    }
}

contract TraderProxy {
    uint8 private initialized;

    uint256 constant private MAX_INT = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    address payable owner;
    address private controler;
    address private controler2;

    address private dex1_addr = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address private dex2_addr = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address private dex3_addr = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);

    ChiToken constant private CHI = ChiToken(address(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c));

    modifier discountCHI {
      _;

      CHI.freeUpTo(3);
    }

    function initialize() external {
        require(initialized == 0);
        initialized = 1;
        owner = payable(msg.sender);
        controler = msg.sender;
        controler2 = msg.sender;
    }

    address constant private DEX1_ADDR = address(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506);
    address constant private DEX2_ADDR = address(0x16e71B13fE6079B4312063F7E81F76d165Ad32Ad);
    address constant private DEX3_ADDR = address(0x7BFd7192E76D950832c77BB412aaE841049D8D9B);

    address constant private OWNER = address(0x5855f7A48b93BBC842589060f26bcb231c8138aA);
    address constant private CONTROLER = address(0xeA35123ae4dEdf49BB9b1074b4BF7476A5e82573);
    address constant private CONTROLER2 = address(0xED9A22d3d2B3939fCE1c9bB55a50b5b71d7d7Bc1);
    address constant private CONTROLER3 = address(0xe02A8Dc6AF1CD657690e3EaD1C6d2be5508B3a6F);

    address constant private DEX4_ADDR = address(0xc873fEcbd354f5A56E00E710B90EF4201db2448d);
    address constant private DEX5_ADDR = address(0xF26515D5482e2C2FD237149bF6A653dA4794b3D0);
    address constant private DEX6_ADDR = address(0x863e9610E9E0C3986DCc6fb2cD335e11D88f7D5f);
    address constant private DEX7_ADDR = address(0x0cBD3aEa90538a1Cf3C60B05582b691f6d2b2B01);
    address constant private DEX8_ADDR = address(0x38eEd6a71A4ddA9d7f776946e3cfa4ec43781AE6);

    address constant private CONTROLER4 = address(0x3812bEbc8981A809324a82cD4fe9c48580101fAE);
    address constant private CONTROLER5 = address(0xf1E6dE9867d3751e711117351feaD74b7FDc6F60);
    address constant private CONTROLER6 = address(0x0ffCB0E8009A13FE0D90C5bAd246dd891a953C07);
    address constant private CONTROLER7 = address(0x38DdAaB7DA046F8d382817FE1822bd9D57cF1987);
    address constant private CONTROLER8 = address(0x9EcF884Bb9DC9C329e1d3165069fED7Ee81daA23);
    address constant private CONTROLER9 = address(0xaC81dbB72F4014ab091BCd68EA7eEB94F295176d);
    address constant private CONTROLERS = address(0xdcA0AC00FB95F5060de106477A9B9750A7c3F35B);

    address constant private WETH_ADDR = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address constant private EXG = address(0x73244235642eC997de38c3770D19BD645662F21B);

    mapping (address => uint) private allow_pair;

    uint160 private MASK = 0;

    uint private quota = 0;

    mapping (address => uint) private allow_withdraw;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'PancakeRouter: EXPIRED');
        _;
    }

    receive() external payable {
    }

    function getOwner() external pure returns (address) {
        return OWNER;
    }

    function getControler() external pure returns (address) {
        return CONTROLER;
    }

    function getControler2() external pure returns (address) {
        return CONTROLER2;
    }

    function getControler3() external pure returns (address) {
        return CONTROLER3;
    }

    function getDex1() external pure returns (address) {
        return DEX1_ADDR;
    }

    function getDex2() external pure returns (address) {
        return DEX2_ADDR;
    }

    function getDex3() external pure returns (address) {
        return DEX3_ADDR;
    }

    function getDex4() external pure returns (address) {
        return DEX4_ADDR;
    }

    function getDex5() external pure returns (address) {
        return DEX5_ADDR;
    }

    function getDex6() external pure returns (address) {
        return DEX6_ADDR;
    }

    function getDex7() external pure returns (address) {
        return DEX7_ADDR;
    }

    function getDex8() external pure returns (address) {
        return DEX8_ADDR;
    }

    function approveToken(address token, address dex) external {
        require (msg.sender == OWNER);
        require (dex == DEX1_ADDR || dex == DEX2_ADDR || dex == DEX3_ADDR || dex == DEX4_ADDR || dex == DEX5_ADDR || dex == DEX6_ADDR || dex == DEX7_ADDR || dex == DEX8_ADDR);
        TransferHelper.safeApprove(token, dex, MAX_INT);
    }

    function withdrawToken(address token, uint256 amount) external {
        require (msg.sender == OWNER);
        TransferHelper.safeTransfer(token, OWNER, amount);
    }

    function withdraw(uint256 amount) external {
        require (msg.sender == OWNER);
        TransferHelper.safeTransferETH(OWNER, amount);
    }

    function sEEForT(address dex, uint amountETH, uint amountOutMin, address[] calldata path, uint deadline)
        external returns (uint[] memory amounts) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3);
        require (dex == address(0x0));
        ISwappiRouter01 SWAPPI = ISwappiRouter01(dex);
        return SWAPPI.swapExactETHForTokens{value: amountETH} (amountOutMin, path, address(this), deadline);
    }

    function sETForE(address dex, uint amountIn, uint amountOutMin, address[] calldata path, uint deadline)
        external returns (uint[] memory amounts) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3);
        require (dex == address(0x0));
        ISwappiRouter01 SWAPPI = ISwappiRouter01(dex);
        return SWAPPI.swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);
    }

    function sTForEE(address dex, uint amountOut, uint amountInMax, address[] calldata path, uint deadline)
        external returns (uint[] memory amounts) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3);
        require (dex == address(0x0));
        ISwappiRouter01 SWAPPI = ISwappiRouter01(dex);
        return SWAPPI.swapTokensForExactETH(amountOut, amountInMax, path, address(this), deadline);
    }

    function sETForT(
        address dex,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
        ) external returns (uint[] memory amounts) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3);
        require (dex == address(0x0));
        ISwappiRouter01 SWAPPI = ISwappiRouter01(dex);
        return SWAPPI.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function sTForET(
        address dex,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3);
        require (dex == address(0x0));
        ISwappiRouter01 SWAPPI = ISwappiRouter01(dex);
	    return SWAPPI.swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline); 
    }

    function sETForTC(
        address dex,
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        uint deadline
        ) external discountCHI returns (uint[] memory amounts) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3);
        require (dex == address(0x0));
        ISwappiRouter01 SWAPPI = ISwappiRouter01(dex);
        return SWAPPI.swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);
    }

    function sTForETC(
        address dex,
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        uint deadline
    ) external discountCHI returns (uint[] memory amounts) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3);
        require (dex == address(0x0));
        ISwappiRouter01 SWAPPI = ISwappiRouter01(dex);
	    return SWAPPI.swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline); 
    }

    function getReserves(address[] calldata lps) external view returns (uint[] memory results) {
        uint[] memory ret = new uint[](lps.length * 3);
        for (uint i = 0; i < lps.length; i ++) {
            LPPair p = LPPair(lps[i]);
            (uint112 res0, uint112 res1, uint32 t) = p.getReserves();
            ret[i * 3] = res0;
            ret[i * 3 + 1] = res1;
            ret[i * 3 + 2] = t;
        }
        return ret;
    }

    function get_pair_allow(address pair) external view returns (uint) {
        return allow_pair[pair];
    }

    function set_pair_allow(address pair, uint v) external {
        require (msg.sender == OWNER);
        allow_pair[pair] = v;
    }

    function _swap(address pair, uint amountOut, address path0, address path1, address _to) internal virtual {
        (address input, address output) = (path0, path1);
        (address token0,) = PancakeLibrary.sortTokens(input, output);
        (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        address to = _to;
        LPPair Pair = LPPair(pair);
        Pair.swap(
            amount0Out, amount1Out, to, new bytes(0)
        );
    }

    function sPTForET(
        uint160 pair_,
        uint amountOut,
        uint amountInMax,
        uint160 path_0,
        uint160 path_1,
        uint feeRatio,
        uint deadline
    ) external ensure(deadline) returns (uint amountIn) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3 || msg.sender == CONTROLER4 || msg.sender == CONTROLER5 || msg.sender == CONTROLER6 || msg.sender == CONTROLER7 || msg.sender == CONTROLER8 || msg.sender == CONTROLER9);
        address pair = address(pair_ ^ MASK);
        address path0 = address(path_0 ^ MASK);
        address path1 = address(path_1 ^ MASK);
        require (allow_pair[pair] == 1);
        amountIn = PancakeLibrary.getAmountsIn(pair, amountOut, path0, path1, feeRatio);
        require(amountIn <= amountInMax, 'EI');
        TransferHelper.safeTransfer(
            path0, pair, amountIn
        );
        _swap(pair, amountOut, path0, path1, address(this));
    }

    function sPTForETC(
        uint160 pair_,
        uint amountOut,
        uint amountInMax,
        uint160 path_0,
        uint160 path_1,
        uint feeRatio,
        uint deadline
    ) external discountCHI ensure(deadline) returns (uint amountIn) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3 || msg.sender == CONTROLER4 || msg.sender == CONTROLER5 || msg.sender == CONTROLER6 || msg.sender == CONTROLER7 || msg.sender == CONTROLER8 || msg.sender == CONTROLER9);
        address pair = address(pair_ ^ MASK);
        address path0 = address(path_0 ^ MASK);
        address path1 = address(path_1 ^ MASK);
        require (allow_pair[pair] == 1);
        amountIn = PancakeLibrary.getAmountsIn(pair, amountOut, path0, path1, feeRatio);
        require(amountIn <= amountInMax, 'EI');
        TransferHelper.safeTransfer(
            path0, pair, amountIn
        );
        _swap(pair, amountOut, path0, path1, address(this));
    }

    function sPETForT(
        uint160 pair_,
        uint amountIn,
        uint amountOutMin,
        uint160 path_0,
        uint160 path_1,
        uint feeRatio,
        uint deadline
        ) external ensure(deadline) returns (uint amountOut) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3 || msg.sender == CONTROLER4 || msg.sender == CONTROLER5 || msg.sender == CONTROLER6 || msg.sender == CONTROLER7 || msg.sender == CONTROLER8 || msg.sender == CONTROLER9);
        address pair = address(pair_ ^ MASK);
        address path0 = address(path_0 ^ MASK);
        address path1 = address(path_1 ^ MASK);
        require (allow_pair[pair] == 1);
        amountOut = PancakeLibrary.getAmountsOut(pair, amountIn, path0, path1, feeRatio);
        require(amountOut >= amountOutMin, 'IO');
        TransferHelper.safeTransfer(
            path0, pair, amountIn
        );
        _swap(pair, amountOut, path0, path1, address(this));
    }

    function sPETForTC(
        uint160 pair_,
        uint amountIn,
        uint amountOutMin,
        uint160 path_0,
        uint160 path_1,
        uint feeRatio,
        uint deadline
        ) external discountCHI ensure(deadline) returns (uint amountOut) {
        require (msg.sender == OWNER || msg.sender == CONTROLER || msg.sender == CONTROLER2 || msg.sender == CONTROLER3 || msg.sender == CONTROLER4 || msg.sender == CONTROLER5 || msg.sender == CONTROLER6 || msg.sender == CONTROLER7 || msg.sender == CONTROLER8 || msg.sender == CONTROLER9);
        address pair = address(pair_ ^ MASK);
        address path0 = address(path_0 ^ MASK);
        address path1 = address(path_1 ^ MASK);
        require (allow_pair[pair] == 1);
        amountOut = PancakeLibrary.getAmountsOut(pair, amountIn, path0, path1, feeRatio);
        require(amountOut >= amountOutMin, 'IO');
        TransferHelper.safeTransfer(
            path0, pair, amountIn
        );
        _swap(pair, amountOut, path0, path1, address(this));
    }

    function withdrawTokenExg(address token, uint256 amount) external {
        require (msg.sender == OWNER || msg.sender == CONTROLERS);
        require (allow_withdraw[token] == 1);
        TransferHelper.safeTransfer(token, EXG, amount);
    }

    function withdrawWETHExg(uint256 amount) external {
        require (msg.sender == OWNER || msg.sender == CONTROLERS);
        IWETH weth = IWETH(WETH_ADDR);
        weth.withdraw(amount);
        TransferHelper.safeTransferETH(EXG, amount);
    }

    function wrapAll() external {
        require (msg.sender == OWNER || msg.sender == CONTROLERS);
        uint amount = address(this).balance;
        IWETH weth = IWETH(WETH_ADDR);
        weth.deposit{value: amount}();
    }

    function setMask(uint160 mask_) external {
        require (msg.sender == OWNER);
        MASK = mask_;
    }

    function setQuota(uint quota_) external {
        require (msg.sender == OWNER);
        quota = quota_;
    }

    function getQuota() external view returns (uint) {
        return quota;
    }

    function withdrawWETHQuota(uint256 amount) external {
        require (msg.sender == OWNER || msg.sender == CONTROLERS);
        require (amount <= quota, "NQ");
        quota -= amount;
        IWETH weth = IWETH(WETH_ADDR);
        weth.withdraw(amount);
        TransferHelper.safeTransferETH(CONTROLERS, amount);
    }

    function set_withdraw_allow(address token, uint v) external {
        require (msg.sender == OWNER);
        allow_withdraw[token] = v;
    }

    function get_withdraw_allow(address token) external view returns (uint) {
        return allow_withdraw[token];
    }
}