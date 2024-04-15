// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import { IPoolQuery, SpecifiedToken } from "../../interfaces/IPoolQuery.sol";
import "../../interfaces/IBalancerQuery.sol";
import "../BalancerAdapter.sol";

contract BalancerVolatilePoolQuery is IPoolQuery {
    uint8 public constant NORMALIZED_DECIMALS = 18;

    BalancerAdapter immutable adapter;
    IBalancerQuery immutable poolQuery;
    IPool immutable pool;

    uint256 public immutable xToken; // weth
    uint256 public immutable yToken; // reth
    uint256 public immutable lpTokenId;

    uint256 public immutable numAssets;

    mapping(uint256 => uint8) public decimals;

    mapping(uint256 => uint256) public indexOf;

    constructor(address payable adapter_, address query_) {
        adapter = BalancerAdapter(adapter_);
        poolQuery = IBalancerQuery(query_);

        pool = adapter.pool();

        xToken = adapter.xToken();
        yToken = adapter.yToken();
        lpTokenId = adapter.lpTokenId();

        decimals[xToken] = adapter.decimals(xToken);
        decimals[yToken] = adapter.decimals(yToken);
        decimals[lpTokenId] = adapter.decimals(lpTokenId);

        (IERC20[] memory tokens,,) = IBalancerVault(adapter.primitive()).getPoolTokens(pool.getPoolId());
        numAssets = tokens.length;

        uint256 bptIndex = pool.getBptIndex();
        if (bptIndex == 0) {
            indexOf[xToken] = 1;
            indexOf[yToken] = 2;
        } else if (bptIndex == 1) {
            indexOf[xToken] = 0;
            indexOf[yToken] = 2;
        } else {
            indexOf[xToken] = 0;
            indexOf[yToken] = 1;
        }
    }

    function swapGivenInputAmount(uint256 inputToken, uint256 inputAmount) external view override returns (uint256) { }
    function depositGivenInputAmount(uint256 depositToken, uint256 depositAmount) external view override returns (uint256) { }
    function withdrawGivenInputAmount(uint256 withdrawnToken, uint256 burnAmount) external view override returns (uint256) { }

    function swapGivenInputAmount(uint256 xBalance, uint256 yBalance, uint256 inputAmount, SpecifiedToken inputToken) public view returns (uint256 outputAmount) {
        bool isX = inputToken == SpecifiedToken.X;

        uint256 rawInputAmount = _convertDecimals(NORMALIZED_DECIMALS, decimals[isX ? xToken : yToken], inputAmount);

        uint256 rawXBalance = _convertDecimals(NORMALIZED_DECIMALS, decimals[xToken], xBalance);
        uint256 rawYBalance = _convertDecimals(NORMALIZED_DECIMALS, decimals[yToken], yBalance);

        (uint256 amplification,,) = pool.getAmplificationParameter();

        uint256[] memory balances = new uint256[](numAssets);
        balances[indexOf[xToken]] = rawXBalance;
        balances[indexOf[yToken]] = rawYBalance;
        balances[pool.getBptIndex()] = 1e18;

        uint256[] memory scalingFactors = pool.getScalingFactors();
        _upscaleArray(balances, scalingFactors);

        uint256 rawOutputAmount =
            poolQuery._onRegularSwap(true, mulDown(rawInputAmount, scalingFactors[isX ? indexOf[xToken] : indexOf[yToken]]), balances, isX ? indexOf[xToken] : indexOf[yToken], isX ? indexOf[yToken] : indexOf[xToken], amplification);

        uint256 feeAmount = mulUp(rawOutputAmount, pool.getSwapFeePercentage());
        rawOutputAmount = rawOutputAmount - feeAmount;

        rawOutputAmount = divDown(rawOutputAmount, scalingFactors[isX ? indexOf[yToken] : indexOf[xToken]]);

        uint256 outputToken = isX ? yToken : xToken;

        outputAmount = _convertDecimals(decimals[outputToken], NORMALIZED_DECIMALS, rawOutputAmount);
    }

    function depositGivenInputAmount(uint256 xBalance, uint256 yBalance, uint256 totalSupply, uint256 depositAmount, SpecifiedToken depositToken) public view returns (uint256 mintAmount) {
        bool isX = depositToken == SpecifiedToken.X;

        uint256 rawInputAmount = _convertDecimals(NORMALIZED_DECIMALS, decimals[isX ? xToken : yToken], depositAmount);

        uint256 rawXBalance = _convertDecimals(NORMALIZED_DECIMALS, decimals[xToken], xBalance);
        uint256 rawYBalance = _convertDecimals(NORMALIZED_DECIMALS, decimals[yToken], yBalance);
        uint256 rawTotalSupply = _convertDecimals(NORMALIZED_DECIMALS, decimals[lpTokenId], totalSupply);

        (uint256 amplification,,) = pool.getAmplificationParameter();

        uint256[] memory balances = new uint256[](numAssets);
        balances[indexOf[xToken]] = rawXBalance;
        balances[indexOf[yToken]] = rawYBalance;
        balances[pool.getBptIndex()] = totalSupply;

        uint256[] memory scalingFactors = pool.getScalingFactors();

        _upscaleArray(balances, scalingFactors);

        uint256[] memory updatedBalances = new uint256[](numAssets - 1);
        updatedBalances[0] = balances[indexOf[xToken]];
        updatedBalances[1] = balances[indexOf[yToken]];

        (uint256 rawOutputAmount,) = poolQuery._joinSwapExactTokenInForBptOut(mulDown(rawInputAmount, scalingFactors[isX ? indexOf[xToken] : indexOf[yToken]]), updatedBalances, isX ? 0 : 1, amplification, rawTotalSupply, 0);

        rawOutputAmount = divDown(rawOutputAmount, scalingFactors[pool.getBptIndex()]);

        mintAmount = _convertDecimals(decimals[lpTokenId], NORMALIZED_DECIMALS, rawOutputAmount);
    }

    function withdrawGivenInputAmount(uint256 xBalance, uint256 yBalance, uint256 totalSupply, uint256 burnAmount, SpecifiedToken withdrawnToken) public view returns (uint256 withdrawnAmount) {
        uint256 rawInputAmount = _convertDecimals(NORMALIZED_DECIMALS, decimals[lpTokenId], burnAmount);

        uint256 rawXBalance = _convertDecimals(NORMALIZED_DECIMALS, decimals[xToken], xBalance);
        uint256 rawYBalance = _convertDecimals(NORMALIZED_DECIMALS, decimals[yToken], yBalance);
        uint256 rawTotalSupply = _convertDecimals(NORMALIZED_DECIMALS, decimals[lpTokenId], totalSupply);

        uint256 outputToken = withdrawnToken == SpecifiedToken.X ? xToken : yToken;

        uint256 tokenIndex = indexOf[outputToken] == numAssets - 1 ? indexOf[outputToken] - 1 : indexOf[outputToken];

        (uint256 amplification,,) = pool.getAmplificationParameter();

        uint256[] memory balances = new uint256[](numAssets);
        balances[indexOf[xToken]] = rawXBalance;
        balances[indexOf[yToken]] = rawYBalance;
        balances[pool.getBptIndex()] = totalSupply;

        uint256[] memory scalingFactors = pool.getScalingFactors();

        _upscaleArray(balances, scalingFactors);

        uint256[] memory updatedBalances = new uint256[](numAssets - 1);
        updatedBalances[0] = balances[indexOf[xToken]];
        updatedBalances[1] = balances[indexOf[yToken]];

        (uint256 rawOutputAmount,) = poolQuery._exitSwapExactBptInForTokenOut(mulDown(rawInputAmount, scalingFactors[pool.getBptIndex()]), updatedBalances, tokenIndex, amplification, rawTotalSupply, 0);

        rawOutputAmount = divDown(rawOutputAmount, scalingFactors[indexOf[outputToken]]);

        withdrawnAmount = _convertDecimals(decimals[outputToken], NORMALIZED_DECIMALS, rawOutputAmount);
    }

    /**
     * @dev convert a uint256 from one fixed point decimal basis to another,
     *   returning the truncated amount if a truncation occurs.
     * @dev fn(from, to, a) => b
     * @dev a = (x * 10**from) => b = (x * 10**to), where x is constant.
     * @param amountToConvert the amount being converted
     * @param decimalsFrom the fixed decimal basis of amountToConvert
     * @param decimalsTo the fixed decimal basis of the returned convertedAmount
     * @return convertedAmount the amount after conversion
     */
    function _convertDecimals(uint8 decimalsFrom, uint8 decimalsTo, uint256 amountToConvert) internal pure returns (uint256 convertedAmount) {
        if (decimalsFrom == decimalsTo) {
            // no shift
            convertedAmount = amountToConvert;
        } else if (decimalsFrom < decimalsTo) {
            // Decimal shift left (add precision)
            uint256 shift = 10 ** (uint256(decimalsTo - decimalsFrom));
            convertedAmount = amountToConvert * shift;
        } else {
            // Decimal shift right (remove precision) -> truncation
            uint256 shift = 10 ** (uint256(decimalsFrom - decimalsTo));
            convertedAmount = amountToConvert / shift;
        }
    }

    function _upscaleArray(uint256[] memory amounts, uint256[] memory scalingFactors) internal pure {
        for (uint256 i = 0; i < amounts.length; ++i) {
            amounts[i] = mulDown(amounts[i], scalingFactors[i]);
        }
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        require(a == 0 || product / a == b, "revert");

        return product / 1e18;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "revert");

        uint256 aInflated = a * 1e18;
        require(a == 0 || aInflated / a == 1e18, "revert"); // mul overflow

        return aInflated / b;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256 result) {
        uint256 product = a * b;
        uint256 ONE = 1e18;
        require(a == 0 || product / a == b, "revert");

        // The traditional divUp formula is:
        // divUp(x, y) := (x + y - 1) / y
        // To avoid intermediate overflow in the addition, we distribute the division and get:
        // divUp(x, y) := (x - 1) / y + 1
        // Note that this requires x != 0, if x == 0 then the result is zero
        //
        // Equivalent to:
        // result = product == 0 ? 0 : ((product - 1) / FixedPoint.ONE) + 1;
        assembly {
            result := mul(iszero(iszero(product)), add(div(sub(product, 1), ONE), 1))
        }
    }
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

enum SpecifiedToken {
    X,
    Y
}

interface IPoolQuery {
    function swapGivenInputAmount(uint256 inputToken, uint256 inputAmount) external view returns (uint256);
    function depositGivenInputAmount(uint256 depositToken, uint256 depositAmount) external view returns (uint256);
    function withdrawGivenInputAmount(uint256 withdrawnToken, uint256 burnAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import { IBalancerVault } from "./IBalancerVault.sol";

interface IBalancerQuery {
    function _onRegularSwap(bool isGivenIn, uint256 amountGiven, uint256[] memory registeredBalances, uint256 registeredIndexIn, uint256 registeredIndexOut, uint256 currentAmp) external view returns (uint256);

    function _joinSwapExactTokenInForBptOut(uint256 amountIn, uint256[] memory balances, uint256 indexIn, uint256 currentAmp, uint256 actualSupply, uint256 preJoinExitInvariant) external view returns (uint256, uint256);

    function _exitSwapExactBptInForTokenOut(uint256 bptAmount, uint256[] memory balances, uint256 indexOut, uint256 currentAmp, uint256 actualSupply, uint256 preJoinExitInvariant) external view returns (uint256, uint256);

    function getAmplificationParameter() external view returns (uint256 value, bool isUpdating, uint256 precision);

    function getScalingFactors() external view returns (uint256[] memory);

    function getBptIndex() external view returns (uint256);

    function getSwapFeePercentage() external view returns (uint256);

    function getActualSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./OceanAdapter.sol";
import "../interfaces/IBalancerVault.sol";

enum ComputeType {
    Deposit,
    Swap,
    Withdraw
}

/**
 * @notice
 *   balancer adapter to do swaps/deposits and withdrawals through balancer
 */
contract BalancerAdapter is OceanAdapter {
    /////////////////////////////////////////////////////////////////////
    //                             Errors                              //
    /////////////////////////////////////////////////////////////////////
    error INVALID_COMPUTE_TYPE();
    error SLIPPAGE_LIMIT_EXCEEDED();

    /////////////////////////////////////////////////////////////////////
    //                             Events                              //
    /////////////////////////////////////////////////////////////////////
    event Swap(uint256 inputToken, uint256 inputAmount, uint256 outputAmount, bytes32 slippageProtection, address user, bool computeOutput);
    event Deposit(uint256 inputToken, uint256 inputAmount, uint256 outputAmount, bytes32 slippageProtection, address user, bool computeOutput);
    event Withdraw(uint256 outputToken, uint256 inputAmount, uint256 outputAmount, bytes32 slippageProtection, address user, bool computeOutput);

    /// @notice x token Ocean ID.
    uint256 public immutable xToken;

    /// @notice y token Ocean ID.
    uint256 public immutable yToken;

    /// @notice lp token Ocean ID.
    uint256 public immutable lpTokenId;

    /// @notice pool address
    IPool public immutable pool;

    /// @notice pool asset list
    IAsset[] public assets;

    /// @notice map token Ocean IDs to corresponding Curve pool indices
    mapping(uint256 => uint256) public indexOf;

    //*********************************************************************//
    // ---------------------------- constructor -------------------------- //
    //*********************************************************************//

    /**
     * @notice only initializing the immutables, mappings & approves tokens
     */
    constructor(address ocean_, address primitive_, address underlyingTokenX_, address underlyingTokenY_, uint256 tokenXIndex_, uint256 tokenYIndex_, bytes32 poolId_) OceanAdapter(ocean_, primitive_) {
        address xTokenAddress = underlyingTokenX_;
        xToken = _calculateOceanId(xTokenAddress, 0);
        underlying[xToken] = xTokenAddress;
        indexOf[xToken] = tokenXIndex_;
        decimals[xToken] = IERC20Metadata(xTokenAddress).decimals();
        _approveToken(xTokenAddress);

        address yTokenAddress = underlyingTokenY_;
        yToken = _calculateOceanId(yTokenAddress, 0);
        indexOf[yToken] = tokenYIndex_;
        underlying[yToken] = yTokenAddress;
        decimals[yToken] = IERC20Metadata(yTokenAddress).decimals();
        _approveToken(yTokenAddress);

        (address _pool,) = IBalancerVault(primitive).getPool(poolId_);
        pool = IPool(_pool);

        lpTokenId = _calculateOceanId(_pool, 0);
        underlying[lpTokenId] = _pool;
        decimals[lpTokenId] = 18;
        _approveToken(_pool);

        (IERC20[] memory tokens,,) = IBalancerVault(primitive).getPoolTokens(pool.getPoolId());
        for (uint256 i; i < tokens.length;) {
            assets.push(IAsset(address(tokens[i])));
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev wraps the underlying token into the Ocean
     * @param tokenId Ocean ID of token to wrap
     * @param amount wrap amount
     */
    function wrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal override {
        address tokenAddress = underlying[tokenId];

        Interaction memory interaction = Interaction({ interactionTypeAndAddress: _fetchInteractionId(tokenAddress, uint256(InteractionType.WrapErc20)), inputToken: 0, outputToken: 0, specifiedAmount: amount, metadata: bytes32(0) });

        IOceanInteractions(ocean).doInteraction(interaction);
    }

    /**
     * @dev unwraps the underlying token from the Ocean
     * @param tokenId Ocean ID of token to unwrap
     * @param amount unwrap amount
     */
    function unwrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal override returns (uint256 unwrappedAmount) {
        address tokenAddress = underlying[tokenId];

        Interaction memory interaction = Interaction({ interactionTypeAndAddress: _fetchInteractionId(tokenAddress, uint256(InteractionType.UnwrapErc20)), inputToken: 0, outputToken: 0, specifiedAmount: amount, metadata: bytes32(0) });

        IOceanInteractions(ocean).doInteraction(interaction);

        // handle the unwrap fee scenario
        uint256 unwrapFee = amount / IOceanInteractions(ocean).unwrapFeeDivisor();
        (, uint256 truncated) = _convertDecimals(NORMALIZED_DECIMALS, decimals[tokenId], amount - unwrapFee);
        unwrapFee = unwrapFee + truncated;

        unwrappedAmount = amount - unwrapFee;
    }

    /**
     * @dev swaps/add liquidity/remove liquidity from Curve 2pool
     * @param inputToken The user is giving this token to the pool
     * @param outputToken The pool is giving this token to the user
     * @param inputAmount The amount of the inputToken the user is giving to the pool
     * @param minimumOutputAmount The minimum amount of tokens expected back after the exchange
     */
    function primitiveOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, bytes32 minimumOutputAmount) internal override returns (uint256 outputAmount) {
        (uint256 rawInputAmount,) = _convertDecimals(NORMALIZED_DECIMALS, decimals[inputToken], inputAmount);

        ComputeType action = _determineComputeType(inputToken, outputToken);

        uint256 rawOutputAmount;

        // avoid multiple SLOADS
        uint256 indexOfInputAmount = indexOf[inputToken];
        uint256 indexOfOutputAmount = indexOf[outputToken];
        uint256 assetLength = assets.length;

        if (action == ComputeType.Swap) {
            IBalancerVault.SingleSwap memory singleSwap = IBalancerVault.SingleSwap({
                poolId: pool.getPoolId(),
                kind: IBalancerVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(underlying[inputToken]),
                assetOut: IAsset(underlying[outputToken]),
                amount: rawInputAmount,
                userData: new bytes(0)
            });

            IBalancerVault.FundManagement memory fundManagement = IBalancerVault.FundManagement({ sender: payable(address(this)), fromInternalBalance: false, recipient: payable(address(this)), toInternalBalance: false });
            rawOutputAmount = IBalancerVault(primitive).swap(singleSwap, fundManagement, uint256(minimumOutputAmount), block.timestamp + 300);
        } else if (action == ComputeType.Deposit) {
            uint256[] memory amounts = new uint256[](assetLength);
            amounts[indexOfInputAmount] = rawInputAmount;

            uint256[] memory amountsWithoutBpt = new uint256[](amounts.length - 1);
            for (uint256 i; i < amountsWithoutBpt.length;) {
                amountsWithoutBpt[i] = amounts[i < pool.getBptIndex() ? i : i + 1];
                unchecked {
                    ++i;
                }
            }

            IBalancerVault.JoinPoolRequest memory joinPool = IBalancerVault.JoinPoolRequest({ assets: assets, maxAmountsIn: amounts, userData: abi.encode(1, amountsWithoutBpt, uint256(minimumOutputAmount)), fromInternalBalance: false });

            uint256 bptBalanceBeforeDeposit = IERC20Metadata(address(pool)).balanceOf(address(this));
            IBalancerVault(primitive).joinPool(pool.getPoolId(), address(this), address(this), joinPool);
            rawOutputAmount = IERC20Metadata(address(pool)).balanceOf(address(this)) - bptBalanceBeforeDeposit;
        } else {
            uint256[] memory amounts = new uint256[](assetLength);
            amounts[indexOfOutputAmount] = uint256(minimumOutputAmount);

            IBalancerVault.ExitPoolRequest memory exitPool = IBalancerVault.ExitPoolRequest({
                assets: assets,
                minAmountsOut: amounts,
                userData: abi.encode(0, rawInputAmount, indexOfOutputAmount < pool.getBptIndex() ? indexOfOutputAmount : indexOfOutputAmount - 1),
                toInternalBalance: false
            });
            address outputTokenAddress = underlying[outputToken];
            uint256 outputTokenBalanceBeforeWithdraw = IERC20Metadata(outputTokenAddress).balanceOf(address(this));

            IBalancerVault(primitive).exitPool(pool.getPoolId(), address(this), payable(address(this)), exitPool);
            rawOutputAmount = IERC20Metadata(outputTokenAddress).balanceOf(address(this)) - outputTokenBalanceBeforeWithdraw;
        }

        (outputAmount,) = _convertDecimals(decimals[outputToken], NORMALIZED_DECIMALS, rawOutputAmount);

        if (uint256(minimumOutputAmount) > outputAmount) revert SLIPPAGE_LIMIT_EXCEEDED();

        if (action == ComputeType.Swap) {
            emit Swap(inputToken, inputAmount, outputAmount, minimumOutputAmount, primitive, true);
        } else if (action == ComputeType.Deposit) {
            emit Deposit(inputToken, inputAmount, outputAmount, minimumOutputAmount, primitive, true);
        } else {
            emit Withdraw(outputToken, inputAmount, outputAmount, minimumOutputAmount, primitive, true);
        }
    }

    /**
     * @dev Approves token to be spent by the Ocean and the Curve pool
     */
    function _approveToken(address tokenAddress) private {
        IERC20Metadata(tokenAddress).approve(ocean, type(uint256).max);
        IERC20Metadata(tokenAddress).approve(primitive, type(uint256).max);
    }

    /**
     * @dev Uses the inputToken and outputToken to determine the ComputeType
     *  (input: xToken, output: yToken) | (input: yToken, output: xToken) => SWAP
     *  base := xToken | yToken
     *  (input: base, output: lpToken) => DEPOSIT
     *  (input: lpToken, output: base) => WITHDRAW
     */
    function _determineComputeType(uint256 inputToken, uint256 outputToken) private view returns (ComputeType computeType) {
        if (((inputToken == xToken) && (outputToken == yToken)) || ((inputToken == yToken) && (outputToken == xToken))) {
            return ComputeType.Swap;
        } else if (((inputToken == xToken) || (inputToken == yToken)) && (outputToken == lpTokenId)) {
            return ComputeType.Deposit;
        } else if ((inputToken == lpTokenId) && ((outputToken == xToken) || (outputToken == yToken))) {
            return ComputeType.Withdraw;
        } else {
            revert INVALID_COMPUTE_TYPE();
        }
    }

    receive() external payable { }
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAsset {
// solhint-disable-previous-line no-empty-blocks
}

interface IBalancerQueries {
    function queryExit(bytes32 poolId, address sender, address recipient, IBalancerVault.ExitPoolRequest memory request) external returns (uint256 bptIn, uint256[] memory amountsOut);
}

interface IPool {
    function getBptIndex() external view returns (uint256);

    function getPoolId() external view returns (bytes32);

    function getAmplificationParameter() external view returns (uint256, bool, uint256);

    function getScalingFactors() external view returns (uint256[] memory);

    function getSwapFeePercentage() external view returns (uint256);
}

interface IBalancerVault {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    enum PoolSpecialization {
        GENERAL,
        MINIMAL_SWAP_INFO,
        TWO_TOKEN
    }

    function getPoolTokens(bytes32 poolId) external view returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline) external payable returns (uint256);

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity ^0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOceanPrimitive.sol";
import "../interfaces/Interactions.sol";

/**
 * @notice
 *   Helper contract for shell adapters
 */
abstract contract OceanAdapter is IOceanPrimitive {
    /// @notice normalized decimals to be compatible with the Ocean.
    uint8 constant NORMALIZED_DECIMALS = 18;

    /// @notice Ocean address.
    address public immutable ocean;

    /// @notice external primitive address.
    address public immutable primitive;

    /// @notice The underlying token address corresponding to the Ocean ID.
    mapping(uint256 => address) public underlying;

    /// @notice The underlying token decimals wrt to the Ocean ID
    mapping(uint256 => uint8) public decimals;

    //*********************************************************************//
    // ---------------------------- constructor -------------------------- //
    //*********************************************************************//

    /// @notice only initializing the immutables
    constructor(address ocean_, address primitive_) {
        ocean = ocean_;
        primitive = primitive_;
    }

    /// @notice only allow the Ocean to call a method
    modifier onlyOcean() {
        require(msg.sender == ocean);
        _;
    }

    /**
     * @dev The Ocean must always know the input and output tokens in order to
     *  do the accounting.  One of the token amounts is chosen by the user, and
     *  the other amount is chosen by the primitive.  When computeOutputAmount is
     *  called, the user provides the inputAmount, and the primitive uses this to
     *  compute the outputAmount
     * @param inputToken The user is giving this token to the primitive
     * @param outputToken The primitive is giving this token to the user
     * @param inputAmount The amount of the inputToken the user is giving to the primitive
     * @param metadata a bytes32 value that the user provides the Ocean
     * @dev the unused param is an address field called userAddress
     */
    function computeOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, address, bytes32 metadata) external override onlyOcean returns (uint256 outputAmount) {
        uint256 unwrappedAmount = unwrapToken(inputToken, inputAmount, metadata);

        outputAmount = primitiveOutputAmount(inputToken, outputToken, unwrappedAmount, metadata);

        wrapToken(outputToken, outputAmount, metadata);
    }

    /**
     * @notice Not implemented for this primitive
     */
    function computeInputAmount(uint256 inputToken, uint256 outputToken, uint256 outputAmount, address userAddress, bytes32 maximumInputAmount) external override onlyOcean returns (uint256 inputAmount) {
        revert();
    }

    /**
     * @notice used to fetch the Ocean interaction ID
     */
    function _fetchInteractionId(address token, uint256 interactionType) internal pure returns (bytes32) {
        uint256 packedValue = uint256(uint160(token));
        packedValue |= interactionType << 248;
        return bytes32(abi.encode(packedValue));
    }

    /**
     * @notice calculates Ocean ID for a underlying token
     */
    function _calculateOceanId(address tokenAddress, uint256 tokenId) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tokenAddress, tokenId)));
    }

    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) public pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @notice returning 0 here since this primitive should not have any tokens
     */
    function getTokenSupply(uint256 tokenId) external view virtual override returns (uint256) {
        return 0;
    }

    /**
     * @dev convert a uint256 from one fixed point decimal basis to another,
     *   returning the truncated amount if a truncation occurs.
     * @dev fn(from, to, a) => b
     * @dev a = (x * 10**from) => b = (x * 10**to), where x is constant.
     * @param amountToConvert the amount being converted
     * @param decimalsFrom the fixed decimal basis of amountToConvert
     * @param decimalsTo the fixed decimal basis of the returned convertedAmount
     * @return convertedAmount the amount after conversion
     * @return truncatedAmount if (from > to), there may be some truncation, it
     *  is up to the caller to decide what to do with the truncated amount.
     */
    function _convertDecimals(uint8 decimalsFrom, uint8 decimalsTo, uint256 amountToConvert) internal pure returns (uint256 convertedAmount, uint256 truncatedAmount) {
        if (decimalsFrom == decimalsTo) {
            // no shift
            convertedAmount = amountToConvert;
            truncatedAmount = 0;
        } else if (decimalsFrom < decimalsTo) {
            // Decimal shift left (add precision)
            uint256 shift = 10 ** (uint256(decimalsTo - decimalsFrom));
            convertedAmount = amountToConvert * shift;
            truncatedAmount = 0;
        } else {
            // Decimal shift right (remove precision) -> truncation
            uint256 shift = 10 ** (uint256(decimalsFrom - decimalsTo));
            convertedAmount = amountToConvert / shift;
            truncatedAmount = amountToConvert % shift;
        }
    }

    function primitiveOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, bytes32 metadata) internal virtual returns (uint256 outputAmount);

    function wrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal virtual;

    function unwrapToken(uint256 tokenId, uint256 amount, bytes32 metadata) internal virtual returns (uint256 unwrappedAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity ^0.8.19;

/// @notice Implementing this allows a primitive to be called by the Ocean's
///  defi framework.
interface IOceanPrimitive {
    function computeOutputAmount(uint256 inputToken, uint256 outputToken, uint256 inputAmount, address userAddress, bytes32 metadata) external returns (uint256 outputAmount);

    function computeInputAmount(uint256 inputToken, uint256 outputToken, uint256 outputAmount, address userAddress, bytes32 metadata) external returns (uint256 inputAmount);

    function getTokenSupply(uint256 tokenId) external view returns (uint256 totalSupply);
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity ^0.8.19;

/**
 * @param interactionTypeAndAddress the type of interaction and the external
 *  contract called during this interaction.
 * @param inputToken this field is ignored except when the interaction type
 *  begins with "Compute".  During a "Compute" interaction, this token is given
 *  to the external contract.
 * @param outputToken this field is ignored except when the interaction type
 *  begins with "Compute".  During a "Compute" interaction, this token is
 *  received from the external contract.
 * @param specifiedAmount This value is the amount of the specified token.
 *  See the comment above the declaration for InteractionType for information
 *  on specified tokens.  When this value is equal to type(uint256).max, it is
 *  a request by the user to use the intra-transaction delta of the specified
 *  token as the specified amount.  See LibBalanceDelta for more information
 *  about this.  When the Ocean executes an interaction, it resolves the
 *  specifiedAmount before calling the external contract.  During a "721"
 *  interaction, the resolved specifiedAmount must be identically "1".
 * @param metadata This value is used in two ways.  During "Compute"
 *  interactions, it is forwarded to the external contract.  The external
 *  contract can define whatever expectations it wants for these 32 bytes.  The
 *  caller is expected to be aware of the expectations of the external contract
 *  invoked during the interaction.  During 721/1155 and wraps and unwraps,
 *  these bytes are cast to uint256 and used as the external ledger's token ID
 *  for the interaction.
 */
struct Interaction {
    bytes32 interactionTypeAndAddress;
    uint256 inputToken;
    uint256 outputToken;
    uint256 specifiedAmount;
    bytes32 metadata;
}

/**
 * InteractionType determines how the properties of Interaction are interpreted
 *
 * The interface implemented by the external contract, the specified token
 *  for the interaction, and what sign (+/-) of delta can be used are
 *  determined by the InteractionType.
 *
 * @param WrapErc20
 *      type(externalContract).interfaceId == IERC20
 *      specifiedToken == calculateOceanId(externalContract, 0)
 *      negative delta can be used as specifiedAmount
 *
 * @param UnwrapErc20
 *      type(externalContract).interfaceId == IERC20
 *      specifiedToken == calculateOceanId(externalContract, 0)
 *      positive delta can be used as specifiedAmount
 *
 * @param WrapErc721
 *      type(externalContract).interfaceId == IERC721
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      negative delta can be used as specifiedAmount
 *
 * @param UnwrapErc721
 *      type(externalContract).interfaceId == IERC721
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      positive delta can be used as specifiedAmount
 *
 * @param WrapErc1155
 *      type(externalContract).interfaceId == IERC1155
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      negative delta can be used as specifiedAmount
 *
 * @param WrapErc1155
 *      type(externalContract).interfaceId == IERC1155
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      positive delta can be used as specifiedAmount
 *
 * @param ComputeInputAmount
 *      type(externalContract).interfaceId == IOceanexternalContract
 *      specifiedToken == outputToken
 *      negative delta can be used as specifiedAmount
 *
 * @param ComputeOutputAmount
 *      type(externalContract).interfaceId == IOceanexternalContract
 *      specifiedToken == inputToken
 *      positive delta can be used as specifiedAmount
 */
enum InteractionType {
    WrapErc20,
    UnwrapErc20,
    WrapErc721,
    UnwrapErc721,
    WrapErc1155,
    UnwrapErc1155,
    ComputeInputAmount,
    ComputeOutputAmount,
    UnwrapEther
}

interface IOceanInteractions {
    function unwrapFeeDivisor() external view returns (uint256);

    function doMultipleInteractions(Interaction[] calldata interactions, uint256[] calldata ids) external payable returns (uint256[] memory burnIds, uint256[] memory burnAmounts, uint256[] memory mintIds, uint256[] memory mintAmounts);

    function forwardedDoMultipleInteractions(
        Interaction[] calldata interactions,
        uint256[] calldata ids,
        address userAddress
    )
        external
        payable
        returns (uint256[] memory burnIds, uint256[] memory burnAmounts, uint256[] memory mintIds, uint256[] memory mintAmounts);

    function doInteraction(Interaction calldata interaction) external payable returns (uint256 burnId, uint256 burnAmount, uint256 mintId, uint256 mintAmount);

    function forwardedDoInteraction(Interaction calldata interaction, address userAddress) external payable returns (uint256 burnId, uint256 burnAmount, uint256 mintId, uint256 mintAmount);
}