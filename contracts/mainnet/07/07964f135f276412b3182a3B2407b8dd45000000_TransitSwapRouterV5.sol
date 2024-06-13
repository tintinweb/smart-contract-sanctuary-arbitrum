// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "./UniswapV2Router.sol";
import "./UniswapV3Router.sol";
import "./AggregateRouter.sol";
import "./CrossRouter.sol";

contract TransitSwapRouterV5 is UniswapV2Router, UniswapV3Router, AggregateRouter, CrossRouter  {

    function withdrawTokens(address[] memory tokens, address recipient) external onlyExecutor {
        for (uint index; index < tokens.length; index++) {
            uint amount;
            if (TransferHelper.isETH(tokens[index])) {
                amount = address(this).balance;
                TransferHelper.safeTransferETH(recipient, amount);
            } else {
                amount = IERC20(tokens[index]).balanceOf(address(this));
                TransferHelper.safeTransferWithoutRequire(tokens[index], recipient, amount);
            }
            emit Withdraw(tokens[index], msg.sender, recipient, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract CrossRouter is BaseCore {

    using SafeMath for uint256;

    constructor() {}

    function cross(CrossDescription calldata desc) external payable nonReentrant whenNotPaused(FunctionFlag.cross) {
        require(desc.calls.length > 0, "data should be not zero");
        require(desc.amount > 0, "amount should be greater than 0");
        require(_cross_caller_allowed[desc.caller], "invalid caller");
        
        uint256 swapAmount = executeFunds(FunctionFlag.cross, desc.srcToken, desc.wrappedToken, desc.caller, desc.amount, desc.fee, desc.signature);

        {
            (bool success, bytes memory result) = desc.caller.call{value:swapAmount}(desc.calls);
            if (!success) {
                revert(RevertReasonParser.parse(result, "TransitCrossV5:"));
            }
            TransferHelper.safeApprove(desc.srcToken, desc.caller, 0);
        }

        _emitTransit(desc.srcToken, desc.dstToken, desc.dstReceiver, desc.amount, 0, desc.toChain, desc.channel);
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract AggregateRouter is BaseCore {

    using SafeMath for uint256;

    constructor() {

    }

    function aggregateAndGasUsed(TransitSwapDescription calldata desc, CallbytesDescription calldata callbytesDesc) external payable returns (uint256 returnAmount, uint256 gasUsed) {
        uint256 gasLeftBefore = gasleft();
        returnAmount = _executeAggregate(desc, callbytesDesc);
        gasUsed = gasLeftBefore - gasleft();
    }

    function aggregate(TransitSwapDescription calldata desc, CallbytesDescription calldata callbytesDesc) external payable returns (uint256 returnAmount) {
        returnAmount = _executeAggregate(desc, callbytesDesc);
    }

    function _executeAggregate(TransitSwapDescription calldata desc, CallbytesDescription calldata callbytesDesc) internal nonReentrant whenNotPaused(FunctionFlag.executeAggregate) returns (uint256 returnAmount) {
        require(callbytesDesc.calldatas.length > 0, "data should be not zero");
        require(desc.amount > 0, "amount should be greater than 0");
        require(desc.dstReceiver != address(0), "receiver should be not address(0)");
        require(desc.minReturnAmount > 0, "minReturnAmount should be greater than 0");
        require(_wrapped_allowed[desc.wrappedToken], "invalid wrapped address");

        uint256 toBeforeBalance;
        address bridgeAddress = _aggregate_bridge;
        uint256 swapAmount = executeFunds(FunctionFlag.executeAggregate, desc.srcToken, desc.wrappedToken, bridgeAddress, desc.amount, desc.fee, desc.signature);

        if (TransferHelper.isETH(desc.dstToken)) {
            toBeforeBalance = desc.dstReceiver.balance;
        } else {
            toBeforeBalance = IERC20(desc.dstToken).balanceOf(desc.dstReceiver);
        }

        {
            //bytes4(keccak256(bytes('callbytes(CallbytesDescription)')));
            (bool success, bytes memory result) = bridgeAddress.call{value : swapAmount}(abi.encodeWithSelector(0x3f3204d2, callbytesDesc));
            if (!success) {
                revert(RevertReasonParser.parse(result, "TransitSwap:"));
            }
        }

        if (TransferHelper.isETH(desc.dstToken)) {
            returnAmount = desc.dstReceiver.balance.sub(toBeforeBalance);
        } else {
            returnAmount = IERC20(desc.dstToken).balanceOf(desc.dstReceiver).sub(toBeforeBalance);
        }
        require(returnAmount >= desc.minReturnAmount, "Too little received");

        _emitTransit(desc.srcToken, desc.dstToken, desc.dstReceiver, desc.amount, returnAmount, 0, desc.channel);

    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract UniswapV3Router is BaseCore {

    using SafeMath for uint256;

    uint256 private constant _ZERO_FOR_ONE_MASK = 1 << 255;
    uint160 private constant MIN_SQRT_RATIO = 4295128739;
    uint160 private constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    constructor() {}

    fallback() external {
        (int256 amount0Delta, int256 amount1Delta, bytes memory _data) = abi.decode(msg.data[4:], (int256,int256,bytes));
        _executeCallback(amount0Delta, amount1Delta, _data);
    }

    function pancakeV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _executeCallback(amount0Delta, amount1Delta, _data);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external {
        _executeCallback(amount0Delta, amount1Delta, _data);
    }

    function _executeCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory _data
    ) internal {
        require(amount0Delta > 0 || amount1Delta > 0, "M0 or M1"); // swaps entirely within 0-liquidity regions are not supported
        (uint256 pool, bytes memory tokenInAndPoolSalt) = abi.decode(_data, (uint256, bytes));
        (address tokenIn, bytes32 poolSalt) = abi.decode(tokenInAndPoolSalt, (address, bytes32));
        _verifyCallback(pool, poolSalt, msg.sender);

        uint256 amountToPay = uint256(amount1Delta);
        if (amount0Delta > 0) {
            amountToPay = uint256(amount0Delta);
        }

        TransferHelper.safeTransfer(tokenIn, msg.sender, amountToPay);
    }

    function exactInputV3SwapAndGasUsed(ExactInputV3SwapParams calldata params) external payable returns (uint256 returnAmount, uint256 gasUsed) {
        uint256 gasLeftBefore = gasleft();
        returnAmount = _executeV3Swap(params);
        gasUsed = gasLeftBefore - gasleft();

    }

    function exactInputV3Swap(ExactInputV3SwapParams calldata params) external payable returns (uint256 returnAmount) {
        returnAmount = _executeV3Swap(params);
    }

    function _executeV3Swap(ExactInputV3SwapParams calldata params) internal nonReentrant whenNotPaused(FunctionFlag.executeV3Swap) returns (uint256 returnAmount) {
        require(params.pools.length > 0, "Empty pools");
        require(params.deadline >= block.timestamp, "Expired");
        require(_wrapped_allowed[params.wrappedToken], "Invalid wrapped address");
        address tokenIn = params.srcToken;
        address tokenOut = params.dstToken;

        uint256 toBeforeBalance;
        bool isToETH;
        if (TransferHelper.isETH(params.srcToken)) {
            tokenIn = params.wrappedToken;
        }
        uint256 actualAmountIn = executeFunds(FunctionFlag.executeV3Swap, params.srcToken, params.wrappedToken, address(0), params.amount, params.fee, params.signature);

        if (TransferHelper.isETH(params.dstToken)) {
            tokenOut = params.wrappedToken;
            toBeforeBalance = IERC20(params.wrappedToken).balanceOf(address(this));
            isToETH = true;
        } else {
            toBeforeBalance = IERC20(params.dstToken).balanceOf(params.dstReceiver);
        }

        {
            uint256 len = params.pools.length;
            address recipient = address(this);
            bytes memory tokenInAndPoolSalt;
            if (len > 1) {
                address thisTokenIn = tokenIn;
                address thisTokenOut = address(0);
                for (uint256 i; i < len; i++) {
                    uint256 thisPool = params.pools[i];
                    (thisTokenIn, tokenInAndPoolSalt) = _verifyPool(thisTokenIn, thisTokenOut, thisPool);
                    if (i == len - 1 && !isToETH) {
                        recipient = params.dstReceiver;
                        thisTokenOut = tokenOut;
                    } 
                    actualAmountIn = _swap(recipient, thisPool, tokenInAndPoolSalt, actualAmountIn);
                }
                returnAmount = actualAmountIn;
            } else {
                (, tokenInAndPoolSalt) = _verifyPool(tokenIn, tokenOut, params.pools[0]);
                if (!isToETH) {
                    recipient = params.dstReceiver;
                }
                returnAmount = _swap(recipient, params.pools[0], tokenInAndPoolSalt, actualAmountIn);
            }
        }

        if (isToETH) {
            returnAmount = IERC20(params.wrappedToken).balanceOf(address(this)).sub(toBeforeBalance);
            require(returnAmount >= params.minReturnAmount, "Too little received");
            TransferHelper.safeWithdraw(params.wrappedToken, returnAmount);
            TransferHelper.safeTransferETH(params.dstReceiver, returnAmount);
        } else {
            returnAmount = IERC20(params.dstToken).balanceOf(params.dstReceiver).sub(toBeforeBalance);
            require(returnAmount >= params.minReturnAmount, "Too little received");
        }
        
        _emitTransit(params.srcToken, params.dstToken, params.dstReceiver, params.amount, returnAmount, 0, params.channel);

    }

    function _swap(address recipient, uint256 pool, bytes memory tokenInAndPoolSalt, uint256 amount) internal returns (uint256 amountOut) {
        bool zeroForOne = pool & _ZERO_FOR_ONE_MASK == 0;
        if (zeroForOne) {
            (, int256 amount1) =
                IUniswapV3Pool(address(uint160(pool))).swap(
                    recipient,
                    zeroForOne,
                    amount.toInt256(),
                    MIN_SQRT_RATIO + 1,
                    abi.encode(pool, tokenInAndPoolSalt)
                );
            amountOut = SafeMath.toUint256(-amount1);
        } else {
            (int256 amount0,) =
                IUniswapV3Pool(address(uint160(pool))).swap(
                    recipient,
                    zeroForOne,
                    amount.toInt256(),
                    MAX_SQRT_RATIO - 1,
                    abi.encode(pool, tokenInAndPoolSalt)
                );
            amountOut = SafeMath.toUint256(-amount0);
        }
    }

    function _verifyPool(address tokenIn, address tokenOut, uint256 pool) internal view returns (address nextTokenIn, bytes memory tokenInAndPoolSalt) {
        IUniswapV3Pool iPool = IUniswapV3Pool(address(uint160(pool)));
        address token0 = iPool.token0();
        address token1 = iPool.token1();
        uint24 fee = iPool.fee();
        bytes32 poolSalt = keccak256(abi.encode(token0, token1, fee));

        bool zeroForOne = pool & _ZERO_FOR_ONE_MASK == 0;
        if (zeroForOne) {
            require(tokenIn == token0, "Bad pool");
            if (tokenOut != address(0)) {
                require(tokenOut == token1, "Bad pool");
            }
            nextTokenIn = token1;
            tokenInAndPoolSalt = abi.encode(token0, poolSalt);
        } else {
            require(tokenIn == token1, "Bad pool");
            if (tokenOut != address(0)) {
                require(tokenOut == token0, "Bad pool");
            }
            nextTokenIn = token0;
            tokenInAndPoolSalt = abi.encode(token1, poolSalt);
        }
        _verifyCallback(pool, poolSalt, address(uint160(pool)));
    }

    function _verifyCallback(uint256 pool, bytes32 poolSalt, address caller) internal view {
        uint poolDigit = pool >> 248 & 0xf;
        UniswapV3Pool memory v3Pool = _uniswapV3_factory_allowed[poolDigit];
        require(v3Pool.factory != address(0), "Callback bad pool indexed");
        address calcPool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            v3Pool.factory,
                            poolSalt,
                            v3Pool.initCodeHash
                        )
                    )
                )
            )
        );
        require(calcPool == caller, "Callback bad pool");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BaseCore.sol";

contract UniswapV2Router is BaseCore {

    using SafeMath for uint256;

    constructor() {

    }

    function _beforeSwap(ExactInputV2SwapParams calldata exactInput, bool supportingFeeOn) internal returns (bool isToETH, uint256 actualAmountIn, address[] memory paths, uint256 thisAddressBeforeBalance, uint256 toBeforeBalance) {
        require(exactInput.path.length == exactInput.pool.length + 1, "Invalid path");
        require(_wrapped_allowed[exactInput.wrappedToken], "Invalid wrapped address");

        (bool isToVault, uint256 vaultFee) = splitFee(exactInput.fee);
        actualAmountIn = calculateTradeFee(true, exactInput.amount, vaultFee, exactInput.signature);
        address[] memory path = exactInput.path;
        address dstToken = path[exactInput.path.length - 1];
        if (TransferHelper.isETH(exactInput.path[0])) {
            require(msg.value == exactInput.amount, "Invalid msg.value");
            if (isToVault) {
                TransferHelper.safeTransferETH(_vault, vaultFee);
            }
            path[0] = exactInput.wrappedToken;
            TransferHelper.safeDeposit(exactInput.wrappedToken, actualAmountIn);
        } else {
            if (supportingFeeOn) {
                actualAmountIn = IERC20(path[0]).balanceOf(address(this));
                TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), exactInput.amount);
                actualAmountIn = IERC20(path[0]).balanceOf(address(this)).sub(actualAmountIn).sub(exactInput.fee);
            } else {
                TransferHelper.safeTransferFrom(path[0], msg.sender, address(this), exactInput.amount);
            }
            if (isToVault) {
                TransferHelper.safeTransferWithoutRequire(path[0], _vault, vaultFee);
            }
        }
        if (TransferHelper.isETH(dstToken)) {
            path[path.length - 1] = exactInput.wrappedToken;
            isToETH = true;
            thisAddressBeforeBalance = IERC20(exactInput.wrappedToken).balanceOf(address(this));
        } else {
            if (supportingFeeOn) {
                toBeforeBalance = IERC20(dstToken).balanceOf(exactInput.dstReceiver);
            }
        }
        paths = path;
    }

    function exactInputV2SwapAndGasUsed(ExactInputV2SwapParams calldata exactInput, uint256 deadline) external payable returns (uint256 returnAmount, uint256 gasUsed) {
        uint256 gasLeftBefore = gasleft();
        returnAmount = _executeV2Swap(exactInput, deadline);
        gasUsed = gasLeftBefore - gasleft();
    }

    function exactInputV2Swap(ExactInputV2SwapParams calldata exactInput, uint256 deadline) external payable returns (uint256 returnAmount) {
        returnAmount = _executeV2Swap(exactInput, deadline);
    }

    function _executeV2Swap(ExactInputV2SwapParams calldata exactInput, uint256 deadline) internal nonReentrant whenNotPaused(FunctionFlag.executeV2Swap) returns (uint256 returnAmount) {
        require(deadline >= block.timestamp, "Expired");
        
        bool supportingFeeOn = exactInput.router >> 248 & 0xf == 1;
        {
            (bool isToETH, uint256 actualAmountIn, address[] memory paths, uint256 thisAddressBeforeBalance, uint256 toBeforeBalance) = _beforeSwap(exactInput, supportingFeeOn);
            
            TransferHelper.safeTransfer(paths[0], exactInput.pool[0], actualAmountIn);

            if (supportingFeeOn) {
                if(isToETH) {
                    _swapSupportingFeeOnTransferTokens(address(uint160(exactInput.router)), paths, exactInput.pool, address(this));
                    returnAmount = IERC20(exactInput.wrappedToken).balanceOf(address(this)).sub(thisAddressBeforeBalance);
                } else {
                    _swapSupportingFeeOnTransferTokens(address(uint160(exactInput.router)), paths, exactInput.pool, exactInput.dstReceiver);
                    returnAmount = IERC20(paths[paths.length - 1]).balanceOf(exactInput.dstReceiver).sub(toBeforeBalance);
                }
            } else {
                uint[] memory amounts = IUniswapV2(address(uint160(exactInput.router))).getAmountsOut(actualAmountIn, paths);
                if(isToETH) {
                    _swap(amounts, paths, exactInput.pool, address(this));
                    returnAmount = IERC20(exactInput.wrappedToken).balanceOf(address(this)).sub(thisAddressBeforeBalance);
                } else {
                    _swap(amounts, paths, exactInput.pool, exactInput.dstReceiver);
                    returnAmount = IERC20(paths[paths.length - 1]).balanceOf(exactInput.dstReceiver).sub(toBeforeBalance);
                }
            }

            require(returnAmount >= exactInput.minReturnAmount, "Too little received");
            if (isToETH) {
                TransferHelper.safeWithdraw(exactInput.wrappedToken, returnAmount);
                TransferHelper.safeTransferETH(exactInput.dstReceiver, returnAmount);
            }
        }
        string memory channel = exactInput.channel;

        _emitTransit(exactInput.path[0], exactInput.path[exactInput.path.length - 1], exactInput.dstReceiver, exactInput.amount, returnAmount, 0, channel);
        
    }

    function _swap(uint[] memory amounts, address[] memory path, address[] memory pool, address _to) internal {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = input < output ? (input, output) : (output, input);
            uint amountOut = amounts[i + 1];
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
            address to = i < path.length - 2 ? pool[i + 1] : _to;
            IUniswapV2(pool[i]).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    function _swapSupportingFeeOnTransferTokens(address router, address[] memory path, address[] memory pool, address _to) internal virtual {
        for (uint i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0,) = input < output ? (input, output) : (output, input);
            IUniswapV2 pair = IUniswapV2(pool[i]);
            uint amountInput;
            uint amountOutput;
            { // scope to avoid stack too deep errors
                (uint reserve0, uint reserve1,) = pair.getReserves();
                (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
                amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);
                amountOutput = IUniswapV2(router).getAmountOut(amountInput, reserveInput, reserveOutput);
            }
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
            address to = i < path.length - 2 ? pool[i + 1] : _to;
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libs/Pausable.sol";
import "./libs/ReentrancyGuard.sol";
import "./libs/TransferHelper.sol";
import "./libs/RevertReasonParser.sol";
import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2.sol";
import "./interfaces/IUniswapV3Pool.sol";


contract BaseCore is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;

    struct ExactInputV2SwapParams {
        address dstReceiver;
        address wrappedToken;
        uint256 router;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 fee;
        address[] path;
        address[] pool;
        bytes signature;
        string channel;
    }

    struct ExactInputV3SwapParams {
        address srcToken;
        address dstToken;
        address dstReceiver;
        address wrappedToken;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 fee;
        uint256 deadline;
        uint256[] pools;
        bytes signature;
        string channel;
    }

    struct TransitSwapDescription {
        address srcToken;
        address dstToken;
        address dstReceiver;
        address wrappedToken;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 fee;
        string channel;
        bytes signature;
    }

    struct CrossDescription {
        address srcToken;
        address dstToken;
        address caller;
        address dstReceiver;
        address wrappedToken;
        uint256 amount;
        uint256 fee;
        uint256 toChain;
        string channel;
        bytes calls;
        bytes signature;
    }

    struct CallbytesDescription {
        address srcToken;
        bytes calldatas;
    }

    struct UniswapV3Pool {
        address factory;
        bytes initCodeHash;
    }

    uint256 internal _aggregate_fee;
    uint256 internal _cross_fee;
    address internal _aggregate_bridge;
    address internal _fee_signer;
    address internal _vault;
    bytes32 public DOMAIN_SEPARATOR;
    //whitelist cross's caller
    mapping(address => bool) internal _cross_caller_allowed;
    //whitelist wrapped
    mapping(address => bool) internal _wrapped_allowed;
    //whitelist uniswap v3 factory
    mapping(uint => UniswapV3Pool) internal _uniswapV3_factory_allowed;
    bytes32 public constant CHECKFEE_TYPEHASH = keccak256("CheckFee(address payer,uint256 amount,uint256 fee)");

    event Receipt(address from, uint256 amount);
    event Withdraw(address indexed token, address indexed executor, address indexed recipient, uint amount);
    event ChangeWrappedAllowed(address[] wrappedTokens, bool[] newAllowed);
    event ChangeV3FactoryAllowed(uint256[] poolIndex, address[] factories, bytes[] initCodeHash);
    event ChangeCrossCallerAllowed(address[] callers);
    event ChangeFeeRate(bool isAggregate, uint256 newRate);
    event ChangeSigner(address preSigner, address newSigner);
    event ChangeAggregateBridge(address newBridge);
    event ChangeVault(address preVault, address newVault);
    event TransitSwapped(address indexed srcToken, address indexed dstToken, address indexed dstReceiver, uint256 amount, uint256 returnAmount, uint256 toChainID, string channel);
    
    constructor() Ownable(msg.sender) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("TransitSwapV5")),
                keccak256(bytes("5")),
                block.chainid,
                address(this)
            )
        );
    }

    receive() external payable {
        emit Receipt(msg.sender, msg.value);
    }

    function calculateTradeFee(bool isAggregate, uint256 tradeAmount, uint256 fee, bytes calldata signature) internal view returns (uint256) {
        uint256 thisFee;
        if (isAggregate) {
            thisFee = tradeAmount.mul(_aggregate_fee).div(10000);
        } else {
            thisFee = tradeAmount.mul(_cross_fee).div(10000);
        }
        if (fee < thisFee) {
            require(verifySignature(tradeAmount, fee, signature), "Invalid signature fee");
        }
        return tradeAmount.sub(fee);
    }

    function _emitTransit(address srcToken, address dstToken, address dstReceiver, uint256 amount, uint256 returnAmount, uint256 toChainID, string memory channel) internal {
        emit TransitSwapped (
            srcToken, 
            dstToken, 
            dstReceiver,
            amount,
            returnAmount,
            toChainID,
            channel
        );
    }

    function changeFee(bool[] memory isAggregate, uint256[] memory newRate) external onlyExecutor {
        for (uint i; i < isAggregate.length; i++) {
            require(newRate[i] >= 0 && newRate[i] <= 1000, "fee rate is:0-1000");
            if (isAggregate[i]) {
                _aggregate_fee = newRate[i];
            } else {
                _cross_fee = newRate[i];
            }
            emit ChangeFeeRate(isAggregate[i], newRate[i]);
        }
    }

    function changeTransitProxy(address aggregator, address signer, address vault) external onlyExecutor {
        if (aggregator != address(0)) {
            _aggregate_bridge = aggregator;
            emit ChangeAggregateBridge(aggregator);
        }
        if (signer != address(0)) {
            address preSigner = _fee_signer;
            _fee_signer = signer;
            emit ChangeSigner(preSigner, signer);
        }
        if (vault != address(0)) {
            address preVault = _vault;
            _vault = vault;
            emit ChangeVault(preVault, vault);
        }
    }

    function changeAllowed(address[] calldata crossCallers, address[] calldata wrappedTokens) public onlyExecutor {
        if(crossCallers.length != 0){
            for (uint i; i < crossCallers.length; i++) {
                _cross_caller_allowed[crossCallers[i]] = !_cross_caller_allowed[crossCallers[i]];
            }
            emit ChangeCrossCallerAllowed(crossCallers);
        }
        if(wrappedTokens.length != 0) {
            bool[] memory newAllowed = new bool[](wrappedTokens.length);
            for (uint index; index < wrappedTokens.length; index++) {
                _wrapped_allowed[wrappedTokens[index]] = !_wrapped_allowed[wrappedTokens[index]];
                newAllowed[index] = _wrapped_allowed[wrappedTokens[index]];
            }
            emit ChangeWrappedAllowed(wrappedTokens, newAllowed);
        }
    }

    function changeUniswapV3FactoryAllowed(uint[] calldata poolIndex, address[] calldata factories, bytes[] calldata initCodeHash) public onlyExecutor {
        require(poolIndex.length == initCodeHash.length, "invalid data");
        require(factories.length == initCodeHash.length, "invalid data");
        uint len = factories.length;
        for (uint i; i < len; i++) {
            _uniswapV3_factory_allowed[poolIndex[i]] = UniswapV3Pool(factories[i],initCodeHash[i]);
        }
        emit ChangeV3FactoryAllowed(poolIndex, factories, initCodeHash);
    }

    function changePause(bool paused, FunctionFlag[] calldata flags) external onlyExecutor {
        uint len = flags.length;
        for (uint i; i < len; i++) {
            if (paused) {
                _pause(flags[i]);
            } else {
                _unpause(flags[i]);
            }
        }
    }

    function transitProxyAddress() external view returns (address bridgeProxy, address feeSigner) {
        bridgeProxy = _aggregate_bridge;
        feeSigner = _fee_signer;
    }

    function transitFee() external view returns (uint256, uint256, address) {
        return (_aggregate_fee, _cross_fee, _vault);
    }

    function transitAllowedQuery(address crossCaller, address wrappedToken, uint256 poolIndex) external view returns (bool isCrossCallerAllowed, bool isWrappedAllowed, UniswapV3Pool memory pool) {
        isCrossCallerAllowed = _cross_caller_allowed[crossCaller];
        isWrappedAllowed = _wrapped_allowed[wrappedToken];
        pool = _uniswapV3_factory_allowed[poolIndex];
    }

    function verifySignature(uint256 amount, uint256 fee, bytes calldata signature) internal view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(CHECKFEE_TYPEHASH, msg.sender, amount, fee))
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);
        address recovered = ecrecover(digest, v, r, s);
        return recovered == _fee_signer;
    }

    function splitSignature(bytes memory _signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(bytes(_signature).length == 65, "Invalid signature length");

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        return (v, r, s);
    }

    function splitFee(uint256 fee) internal view returns (bool isToVault, uint256 vaultFee) {
        uint vaultFlag = fee % 10;
        vaultFee = (fee.sub(vaultFlag)).div(10);
        if (vaultFlag == 1 && vaultFee > 0 && _vault != address(0)) {
            isToVault = true;
        }
    }

    function executeFunds(FunctionFlag flag, address srcToken, address wrappedToken, address caller, uint256 amount, uint256 fee, bytes calldata signature) internal returns (uint256 swapAmount) {
        (bool isToVault, uint256 vaultFee) = splitFee(fee);
        bool isAggregate = flag == FunctionFlag.cross ? false : true;
        uint256 actualAmountIn = calculateTradeFee(isAggregate, amount, vaultFee, signature);
        if (TransferHelper.isETH(srcToken)) {
            if (flag == FunctionFlag.cross) {
                require(msg.value >= amount, "invalid msg.value");
                swapAmount = msg.value.sub(vaultFee);
            } else {
                require(msg.value == amount, "invalid msg.value");
                swapAmount = actualAmountIn;
            }
            if (wrappedToken != address(0)) {
                require(_wrapped_allowed[wrappedToken], "Invalid wrapped address");
                if (flag == FunctionFlag.cross) {
                    TransferHelper.safeDeposit(wrappedToken, swapAmount);
                    TransferHelper.safeApprove(wrappedToken, caller, swapAmount);
                    swapAmount = 0;
                } else if (flag == FunctionFlag.executeV3Swap) {
                    TransferHelper.safeDeposit(wrappedToken, actualAmountIn);
                }
            }
            if (isToVault) {
                TransferHelper.safeTransferETH(_vault, vaultFee);
            }
        } else {
            TransferHelper.safeTransferFrom(srcToken, msg.sender, address(this), amount);
            if (flag == FunctionFlag.cross) {
                TransferHelper.safeApprove(srcToken, caller, actualAmountIn);
                swapAmount = msg.value;
            } else if (flag == FunctionFlag.executeAggregate) {
                TransferHelper.safeTransfer(srcToken, caller, actualAmountIn);
            } else if (flag == FunctionFlag.executeV3Swap) {
                swapAmount = actualAmountIn;
            }
            if (isToVault) {
                TransferHelper.safeTransferWithoutRequire(srcToken, _vault, vaultFee);
            }
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV3Pool {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function fee() external view returns (uint24);
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9;

interface IUniswapV2 {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.9;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
// Add executor extension

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {

    address private _executor;
    address private _pendingExecutor;
    bool internal _initialized;

    event ExecutorshipTransferStarted(address indexed previousExecutor, address indexed newExecutor);
    event ExecutorshipTransferred(address indexed previousExecutor, address indexed newExecutor);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address newExecutor) {
        require(!_initialized, "Ownable: initialized");
        _transferExecutorship(newExecutor);
        _initialized = true;
    }

    /**
     * @dev Throws if called by any account other than the executor.
     */
    modifier onlyExecutor() {
        _checkExecutor();
        _;
    }

    /**
     * @dev Returns the address of the current executor.
     */
    function executor() public view virtual returns (address) {
        return _executor;
    }

    /**
     * @dev Returns the address of the pending executor.
     */
    function pendingExecutor() public view virtual returns (address) {
        return _pendingExecutor;
    }

    /**
     * @dev Throws if the sender is not the executor.
     */
    function _checkExecutor() internal view virtual {
        require(executor() == msg.sender, "Ownable: caller is not the executor");
    }

    /**
     * @dev Transfers executorship of the contract to a new account (`newExecutor`).
     * Can only be called by the current executor.
     */
    function transferExecutorship(address newExecutor) public virtual onlyExecutor {
        _pendingExecutor = newExecutor;
        emit ExecutorshipTransferStarted(executor(), newExecutor);
    }

    function _transferExecutorship(address newExecutor) internal virtual {
        delete _pendingExecutor;
        address oldExecutor = _executor;
        _executor = newExecutor;
        emit ExecutorshipTransferred(oldExecutor, newExecutor);
    }

    function acceptExecutorship() external {
        address sender = msg.sender;
        require(pendingExecutor() == sender, "Ownable: caller is not the new executor");
        _transferExecutorship(sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library SafeMath {

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
    
    function div(uint x, uint y) internal pure returns (uint z) {
        require(y != 0 , 'ds-math-div-zero');
        z = x / y;
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library RevertReasonParser {
        function parse(bytes memory data, string memory prefix) internal pure returns (string memory) {
        // https://solidity.readthedocs.io/en/latest/control-structures.html#revert
        // We assume that revert reason is abi-encoded as Error(string)

        // 68 = 4-byte selector 0x08c379a0 + 32 bytes offset + 32 bytes length
        if (data.length >= 68 && data[0] == "\x08" && data[1] == "\xc3" && data[2] == "\x79" && data[3] == "\xa0") {
            string memory reason;
            // solhint-disable no-inline-assembly
            assembly {
                // 68 = 32 bytes data length + 4-byte selector + 32 bytes offset
                reason := add(data, 68)
            }
            /*
                revert reason is padded up to 32 bytes with ABI encoder: Error(string)
                also sometimes there is extra 32 bytes of zeros padded in the end:
                https://github.com/ethereum/solidity/issues/10170
                because of that we can't check for equality and instead check
                that string length + extra 68 bytes is less than overall data length
            */
            require(data.length >= 68 + bytes(reason).length, "Invalid revert reason");
            return string(abi.encodePacked(prefix, "Error(", reason, ")"));
        }
        // 36 = 4-byte selector 0x4e487b71 + 32 bytes integer
        else if (data.length == 36 && data[0] == "\x4e" && data[1] == "\x48" && data[2] == "\x7b" && data[3] == "\x71") {
            uint256 code;
            // solhint-disable no-inline-assembly
            assembly {
                // 36 = 32 bytes data length + 4-byte selector
                code := mload(add(data, 36))
            }
            return string(abi.encodePacked(prefix, "Panic(", _toHex(code), ")"));
        }

        return string(abi.encodePacked(prefix, "Unknown(", _toHex(data), ")"));
    }
    
    function _toHex(uint256 value) private pure returns(string memory) {
        return _toHex(abi.encodePacked(value));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes16 alphabet = 0x30313233343536373839616263646566;
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 * i + 2] = alphabet[uint8(data[i] >> 4)];
            str[2 * i + 3] = alphabet[uint8(data[i] & 0x0f)];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

library TransferHelper {
    
    address private constant _ETH_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    address private constant _ZERO_ADDRESS = address(0);
    
    function isETH(address token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }
    
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_TOKEN_FAILED');
    }

    function safeTransferWithoutRequire(address token, address to, uint256 value) internal returns (bool) {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        // solium-disable-next-line
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: TRANSFER_FAILED');
    }

    function safeDeposit(address wrapped, uint value) internal {
        // bytes4(keccak256(bytes('deposit()')));
        (bool success, bytes memory data) = wrapped.call{value:value}(abi.encodeWithSelector(0xd0e30db0));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: DEPOSIT_FAILED');
    }

    function safeWithdraw(address wrapped, uint value) internal {
        // bytes4(keccak256(bytes('withdraw(uint256 wad)')));
        (bool success, bytes memory data) = wrapped.call{value:0}(abi.encodeWithSelector(0x2e1a7d4d, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: WITHDRAW_FAILED');
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        assembly {
            sstore(_status.slot, _ENTERED)
        }
        _;
        assembly {
            sstore(_status.slot, _NOT_ENTERED)
        }
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account, FunctionFlag flag);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account, FunctionFlag flag);

    mapping(FunctionFlag => bool) private _paused;

    enum FunctionFlag {executeAggregate, executeV2Swap, executeV3Swap, cross}

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused(FunctionFlag flag) {
        _requireNotPaused(flag);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused(FunctionFlag flag) {
        _requirePaused(flag);
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused(FunctionFlag flag) public view virtual returns (bool) {
        return _paused[flag];
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused(FunctionFlag flag) internal view virtual {
        require(!paused(flag), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused(FunctionFlag flag) internal view virtual {
        require(paused(flag), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause(FunctionFlag flag) internal virtual whenNotPaused(flag) {
        _paused[flag] = true;
        emit Paused(msg.sender, flag);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause(FunctionFlag flag) internal virtual whenPaused(flag) {
        _paused[flag] = false;
        emit Unpaused(msg.sender, flag);
    }

    function pausedOverAll() public view virtual returns (bool executeAggregate, bool executeV2Swap, bool executeV3Swap, bool cross) {
        executeAggregate = _paused[FunctionFlag.executeAggregate];
        executeV2Swap = _paused[FunctionFlag.executeV2Swap];
        executeV3Swap = _paused[FunctionFlag.executeV3Swap];
        cross = _paused[FunctionFlag.cross];
    }
}