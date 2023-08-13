// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxAdapter {
    /// @notice Swaps tokens along the route determined by the path
    /// @dev The input token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens that must be received
    /// @return boughtAmount Amount of the bought tokens
    function buy(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 boughtAmount);

    /// @notice Sells back part of  bought tokens along the route
    /// @dev The output token is Vault's underlying
    /// @param path An array of token address to swap through
    /// @param amountIn The amount of input tokens
    /// @param minOut The minimum amount of output tokens (vault't underlying) that must be received
    /// @return amount of the bought tokens
    function sell(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut
    ) external returns (uint256 amount);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed only by trader
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function close(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Sells all specified tokens for Vault's underlying
    /// @dev Can be executed by anyone with delay
    /// @param path An array of token address to swap through
    /// @param minOut The minimum amount of output tokens that must be received
    function forceClose(
        address[] memory path,
        uint256 minOut
    ) external returns (uint256);

    /// @notice Creates leverage long or short position order at GMX
    /// @dev Calls createIncreasePosition() in GMXPositionRouter
    function leveragePosition() external returns (uint256);

    /// @notice Create order for closing/decreasing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    function closePosition() external returns (uint256);

    /// @notice Create order for closing position at GMX
    /// @dev Calls createDecreasePosition() in GMXPositionRouter
    ///      Can be executed by any user
    /// @param positionId Position index for vault
    function forceClosePosition(uint256 positionId) external returns (uint256);

    /// @notice Returns data for open position
    // todo
    function getPosition(uint256) external view returns (uint256[] memory);

    struct AdapterOperation {
        uint8 operationId;
        bytes data;
    }

    /// @notice Checks if operations are allowed on adapter
    /// @param traderOperations Array of suggested trader operations
    /// @return Returns 'true' if operation is allowed on adapter
    function isOperationAllowed(
        AdapterOperation[] memory traderOperations
    ) external view returns (bool);

    /// @notice Executes array of trader operations
    /// @param traderOperations Array of trader operations
    /// @return Returns 'true' if all trades completed with success
    function executeOperation(
        AdapterOperation[] memory traderOperations
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxOrderBook {
    struct IncreaseOrder {
        address account;
        address purchaseToken;
        uint256 purchaseTokenAmount;
        address collateralToken;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    struct DecreaseOrder {
        address account;
        address collateralToken;
        uint256 collateralDelta;
        address indexToken;
        uint256 sizeDelta;
        bool isLong;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
    }

    function minExecutionFee() external view returns (uint256);

    function increaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function increaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (IncreaseOrder memory);

    function decreaseOrdersIndex(
        address orderCreator
    ) external view returns (uint256);

    function decreaseOrders(
        address orderCreator,
        uint256 index
    ) external view returns (DecreaseOrder memory);

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    function executeDecreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeIncreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;
}

interface IGmxOrderBookReader {
    function getIncreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getDecreaseOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);

    function getSwapOrders(
        address payable _orderBookAddress,
        address _account,
        uint256[] memory _indices
    ) external view returns (uint256[] memory, address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxPositionManager {
    function executeDecreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function executeIncreaseOrder(
        address _address,
        uint256 _orderIndex,
        address payable _feeReceiver
    ) external;

    function maxGlobalLongSizes(address _token) external view returns (uint256);

    function maxGlobalShortSizes(
        address _token
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxReader {
    function getMaxAmountIn(
        address _vault,
        address _tokenIn,
        address _tokenOut
    ) external view returns (uint256);

    function getAmountOut(
        address _vault,
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256, uint256);

    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) external view returns (uint256[] memory);

    function getTokenBalances(
        address _account,
        address[] memory _tokens
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    function increasePositionRequests(
        bytes32 requestKey
    ) external view returns (IncreasePositionRequest memory);

    struct DecreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function decreasePositionRequests(
        bytes32 requestKey
    ) external view returns (DecreasePositionRequest memory);

    /// @notice Returns current account's increase position index
    function increasePositionsIndex(
        address account
    ) external view returns (uint256);

    /// @notice Returns current account's decrease position index
    function decreasePositionsIndex(
        address positionRequester
    ) external view returns (uint256);

    /// @notice Returns request key
    function getRequestKey(
        address account,
        uint256 index
    ) external view returns (bytes32);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external returns (bytes32);

    function cancelIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function cancelDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function minExecutionFee() external view returns (uint256);
}

interface IGmxRouter {
    function approvedPlugins(
        address user,
        address plugin
    ) external view returns (bool);

    function approvePlugin(address plugin) external;

    function denyPlugin(address plugin) external;

    function swap(
        address[] memory path,
        uint256 amountIn,
        uint256 minOut,
        address receiver
    ) external;

    function increasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _price
    ) external;

    function decreasePosition(
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _price
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IGmxVault {
    function whitelistedTokens(address token) external view returns (bool);

    function stableTokens(address token) external view returns (bool);

    function shortableTokens(address token) external view returns (bool);

    function getMaxPrice(address indexToken) external view returns (uint256);

    function getMinPrice(address indexToken) external view returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            uint256
        );

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function isLeverageEnabled() external view returns (bool);

    function guaranteedUsd(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {IQuoterV2} from "./uniswap/interfaces/IQuoterV2.sol";
import {IUniswapV3Router} from "./uniswap/interfaces/IUniswapV3Router.sol";
import {IUniswapV3Factory} from "./uniswap/interfaces/IUniswapV3Factory.sol";
import {IGmxAdapter} from "./gmx/interfaces/IGmxAdapter.sol";
import {IGmxReader} from "./gmx/interfaces/IGmxReader.sol";
import {IGmxPositionRouter, IGmxRouter} from "./gmx/interfaces/IGmxRouter.sol";
import {IGmxOrderBook, IGmxOrderBookReader} from "./gmx/interfaces/IGmxOrderBook.sol";
import {IGmxVault} from "./gmx/interfaces/IGmxVault.sol";
import {IGmxPositionManager} from "./gmx/interfaces/IGmxPositionManager.sol";

import {IBaseVault} from "../interfaces/IBaseVault.sol";
import {IUsersVault} from "../interfaces/IUsersVault.sol";
import {ITraderWallet} from "../interfaces/ITraderWallet.sol";
import {IContractsFactory} from "../interfaces/IContractsFactory.sol";
import {IDynamicValuation} from "../interfaces/IDynamicValuation.sol";

contract Lens {
    // uniswap
    IQuoterV2 public constant quoter =
        IQuoterV2(0x61fFE014bA17989E743c5F6cB21bF9697530B21e);
    IUniswapV3Factory public constant uniswapV3Factory =
        IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    uint24[4] public uniswapV3Fees = [
        100, // 0.01%
        500, // 0.05%
        3000, // 0.3%
        10000 // 1%
    ];

    // gmx
    IGmxPositionRouter public constant gmxPositionRouter =
        IGmxPositionRouter(0xb87a436B93fFE9D75c5cFA7bAcFff96430b09868);
    IGmxOrderBookReader public constant gmxOrderBookReader =
        IGmxOrderBookReader(0xa27C20A7CF0e1C68C0460706bB674f98F362Bc21);
    IGmxVault public constant gmxVault =
        IGmxVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    address public constant gmxOrderBook =
        0x09f77E8A13De9a35a7231028187e9fD5DB8a2ACB;
    address public constant gmxReader =
        0x22199a49A999c351eF7927602CFB187ec3cae489;
    IGmxPositionManager public constant gmxPositionManager =
        IGmxPositionManager(0x75E42e6f01baf1D6022bEa862A28774a9f8a4A0C);

    /// /// /// /// /// ///
    /// Uniswap
    /// /// /// /// /// ///

    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function getAmountOut(
        bytes memory path,
        uint256 amountIn
    )
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        return quoter.quoteExactInput(path, amountIn);
    }

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function getAmountIn(
        bytes memory path,
        uint256 amountOut
    )
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        )
    {
        return quoter.quoteExactOutput(path, amountOut);
    }

    function getUniswapV3Fees(
        address token1,
        address token2
    ) external view returns (uint24[4] memory resultFees) {
        for (uint8 i; i < 4; i++) {
            uint24 fee = uniswapV3Fees[i];
            address pool = uniswapV3Factory.getPool(token1, token2, fee);

            if (
                pool != address(0) &&
                IERC20(token1).balanceOf(pool) > 0 &&
                IERC20(token2).balanceOf(pool) > 0
            ) {
                resultFees[i] = fee;
            }
        }        
    }

    /// /// /// /// /// ///
    /// GMX
    /// /// /// /// /// ///

    /// increase requests
    function getIncreasePositionRequest(
        bytes32 requestKey
    ) public view returns (IGmxPositionRouter.IncreasePositionRequest memory) {
        return gmxPositionRouter.increasePositionRequests(requestKey);
    }

    /// decrease requests
    function getDecreasePositionRequest(
        bytes32 requestKey
    ) public view returns (IGmxPositionRouter.DecreasePositionRequest memory) {
        return gmxPositionRouter.decreasePositionRequests(requestKey);
    }

    function getIncreasePositionsIndex(
        address account
    ) public view returns (uint256) {
        return gmxPositionRouter.increasePositionsIndex(account);
    }

    function getDecreasePositionsIndex(
        address account
    ) public view returns (uint256) {
        return gmxPositionRouter.decreasePositionsIndex(account);
    }

    function getLatestIncreaseRequest(
        address account
    )
        external
        view
        returns (IGmxPositionRouter.IncreasePositionRequest memory)
    {
        uint256 index = getIncreasePositionsIndex(account);
        bytes32 latestIncreaseKey = gmxPositionRouter.getRequestKey(
            account,
            index
        );
        return getIncreasePositionRequest(latestIncreaseKey);
    }

    function getLatestDecreaseRequest(
        address account
    )
        external
        view
        returns (IGmxPositionRouter.DecreasePositionRequest memory)
    {
        uint256 index = getDecreasePositionsIndex(account);
        bytes32 latestIncreaseKey = gmxPositionRouter.getRequestKey(
            account,
            index
        );
        return getDecreasePositionRequest(latestIncreaseKey);
    }

    function getRequestKey(
        address account,
        uint256 index
    ) external view returns (bytes32) {
        return gmxPositionRouter.getRequestKey(account, index);
    }

    /// @notice Returns current min request execution fee
    function requestMinExecutionFee() external view returns (uint256) {
        return IGmxPositionRouter(gmxPositionRouter).minExecutionFee();
    }

    /// @notice Returns list of positions along specified collateral and index tokens
    /// @param account Wallet or Vault
    /// @param collateralTokens array of collaterals
    /// @param indexTokens array of shorted (or longed) tokens
    /// @param isLong array of position types ('true' for Long position)
    /// @return array with positions current characteristics:
    ///     0 size:         position size in USD (inputAmount * leverage)
    ///     1 collateral:   position collateral in USD
    ///     2 averagePrice: average entry price of the position in USD
    ///     3 entryFundingRate: snapshot of the cumulative funding rate at the time the position was entered
    ///     4 hasRealisedProfit: '1' if the position has a positive realized profit, '0' otherwise
    ///     5 realisedPnl: the realized PnL for the position in USD
    ///     6 lastIncreasedTime: timestamp of the last time the position was increased
    ///     7 hasProfit: 1 if the position is currently in profit, 0 otherwise
    ///     8 delta: amount of current profit or loss of the position in USD
    function getPositions(
        address account,
        address[] memory collateralTokens,
        address[] memory indexTokens,
        bool[] memory isLong
    ) external view returns (uint256[] memory) {
        return
            IGmxReader(gmxReader).getPositions(
                address(gmxVault),
                account,
                collateralTokens,
                indexTokens,
                isLong
            );
    }

    struct ProcessedPosition {
        uint256 size;
        uint256 collateral;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 hasRealisedProfit;
        uint256 realisedPnl;
        uint256 lastIncreasedTime;
        bool hasProfit;
        uint256 delta;
        address collateralToken;
        address indexToken;
        bool isLong;
    }

    /// @notice Returns all current opened positions
    /// @dev Returns all 'short' positions at first
    /// @param account The TraderWallet ir UsersVault address to find all positions
    function getAllPositionsProcessed(
        address account
    ) external view returns (ProcessedPosition[] memory result) {
        address[] memory gmxShortCollaterals = IBaseVault(account)
            .getGmxShortCollaterals();
        address[] memory gmxShortIndexTokens = IBaseVault(account)
            .getGmxShortIndexTokens();
        address[] memory allowedLongTokens = IBaseVault(account)
            .getAllowedTradeTokens();

        uint256 lengthShorts = gmxShortCollaterals.length;
        uint256 lengthLongs = allowedLongTokens.length;
        uint256 totalLength = lengthLongs + lengthShorts;

        if (totalLength == 0) {
            return result;
        }

        result = new ProcessedPosition[](totalLength);

        address[] memory collateralTokens = new address[](totalLength);
        address[] memory indexTokens = new address[](totalLength);
        bool[] memory isLong = new bool[](totalLength);

        // shorts
        for (uint256 i = 0; i < lengthShorts; ++i) {
            collateralTokens[i] = gmxShortCollaterals[i];
            indexTokens[i] = gmxShortIndexTokens[i];
            // isLong[i] = false;  // it is 'false' by default
        }

        // longs
        for (uint256 i = lengthShorts; i < totalLength; ++i) {
            address allowedLongToken = allowedLongTokens[i - lengthShorts];
            collateralTokens[i] = allowedLongToken;
            indexTokens[i] = allowedLongToken;
            isLong[i] = true;
        }

        uint256[] memory positions = IGmxReader(gmxReader).getPositions(
            address(gmxVault),
            account,
            collateralTokens,
            indexTokens,
            isLong
        );

        uint256 index;
        for (uint256 i = 0; i < totalLength; ++i) {
            uint256 positionIndex = i * 9;
            uint256 collateralUSD = positions[positionIndex + 1];
            if (collateralUSD == 0) {
                continue;
            }

            result[index++] = ProcessedPosition({
                size: positions[positionIndex],
                collateral: collateralUSD,
                averagePrice: positions[positionIndex + 2],
                entryFundingRate: positions[positionIndex + 3],
                hasRealisedProfit: positions[positionIndex + 4],
                realisedPnl: positions[positionIndex + 5],
                lastIncreasedTime: positions[positionIndex + 6],
                hasProfit: positions[positionIndex + 7] == 1,
                delta: positions[positionIndex + 8],
                collateralToken: collateralTokens[i],
                indexToken: indexTokens[i],
                isLong: isLong[i]
            });
        }

        if (index != totalLength) {
            assembly {
                mstore(result, index)
            }
        }
    }

    struct AvailableTokenLiquidity {
        uint256 availableLong;
        uint256 availableShort;
    }

    /// @notice Returns current available liquidity for creating position
    /// @param token The token address
    /// @return liquidity Available 'long' and 'short' liquidities in USD scaled to 1e3
    function getAvailableLiquidity(
        address token
    ) external view returns (AvailableTokenLiquidity memory liquidity) {
        liquidity.availableLong =
            gmxPositionManager.maxGlobalLongSizes(token) -
            gmxVault.guaranteedUsd(token);
        liquidity.availableShort =
            gmxPositionManager.maxGlobalShortSizes(token) -
            gmxVault.globalShortSizes(token);
    }

    /// GMX Limit Orders

    /// @notice Returns current account's increase order index
    function increaseOrdersIndex(
        address account
    ) external view returns (uint256) {
        return IGmxOrderBook(gmxOrderBook).increaseOrdersIndex(account);
    }

    /// @notice Returns current account's decrease order index
    function decreaseOrdersIndex(
        address account
    ) external view returns (uint256) {
        return IGmxOrderBook(gmxOrderBook).decreaseOrdersIndex(account);
    }

    /// @notice Returns struct with increase order properties
    function increaseOrder(
        address account,
        uint256 index
    ) external view returns (IGmxOrderBook.IncreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).increaseOrders(account, index);
    }

    /// @notice Returns struct with decrease order properties
    function decreaseOrder(
        address account,
        uint256 index
    ) external view returns (IGmxOrderBook.DecreaseOrder memory) {
        return IGmxOrderBook(gmxOrderBook).decreaseOrders(account, index);
    }

    /// @notice Returns current min order execution fee
    function limitOrderMinExecutionFee() external view returns (uint256) {
        return IGmxOrderBook(gmxOrderBook).minExecutionFee();
    }

    function getIncreaseOrders(
        address account,
        uint256[] memory indices
    ) external view returns (uint256[] memory, address[] memory) {
        return
            gmxOrderBookReader.getIncreaseOrders(
                payable(gmxOrderBook),
                account,
                indices
            );
    }

    function getDecreaseOrders(
        address account,
        uint256[] memory indices
    ) external view returns (uint256[] memory, address[] memory) {
        return
            gmxOrderBookReader.getDecreaseOrders(
                payable(gmxOrderBook),
                account,
                indices
            );
    }

    // /// @notice Calculates the max amount of tokenIn that can be swapped
    // /// @param tokenIn The address of input token
    // /// @param tokenOut The address of output token
    // /// @return amountIn Maximum available amount to be swapped
    // function getMaxAmountIn(
    //     address tokenIn,
    //     address tokenOut
    // ) external view returns (uint256 amountIn) {
    //     return IGmxReader(gmxReader).getMaxAmountIn(address(gmxVault), tokenIn, tokenOut);
    // }

    // /// @notice Returns amount out after fees and the fee amount
    // /// @param tokenIn The address of input token
    // /// @param tokenOut The address of output token
    // /// @param amountIn The amount of tokenIn to be swapped
    // /// @return amountOutAfterFees The amount out after fees,
    // /// @return feeAmount The fee amount in terms of tokenOut
    // function getAmountOut(
    //     address tokenIn,
    //     address tokenOut,
    //     uint256 amountIn
    // ) external view returns (uint256 amountOutAfterFees, uint256 feeAmount) {
    //     return
    //         IGmxReader(gmxReader).getAmountOut(
    //             address(gmxVault),
    //             tokenIn,
    //             tokenOut,
    //             amountIn
    //         );
    // }

    struct DepositData {
        uint256 amountUSD;
        uint256 sharesToMint;
        uint256 sharePrice;
        uint256 totalRequests;
        uint256 usdDecimals;
    }

    function getDepositData(
        address usersVault
    ) public view returns (DepositData memory result) {
        uint256 pendingDepositAssets = IUsersVault(usersVault)
            .pendingDepositAssets();
        address underlyingTokenAddress = IUsersVault(usersVault)
            .underlyingTokenAddress();

        address contractsFactoryAddress = IUsersVault(usersVault)
            .contractsFactoryAddress();
        address dynamicValuationAddress = IContractsFactory(
            contractsFactoryAddress
        ).dynamicValuationAddress();

        result.usdDecimals = IDynamicValuation(dynamicValuationAddress)
            .decimals();

        result.amountUSD = IDynamicValuation(dynamicValuationAddress)
            .getOraclePrice(underlyingTokenAddress, pendingDepositAssets);

        uint256 currentRound = IUsersVault(usersVault).currentRound();
        if (currentRound == 0) {
            uint256 balance = IERC20(underlyingTokenAddress).balanceOf(
                usersVault
            );

            result.sharesToMint = IDynamicValuation(dynamicValuationAddress)
                .getOraclePrice(underlyingTokenAddress, balance);

            result.sharePrice = 1e18;
        } else {
            uint256 contractValuation = IUsersVault(usersVault)
                .getContractValuation();
            uint256 _totalSupply = IUsersVault(usersVault).totalSupply();

            result.sharePrice = _totalSupply != 0
                ? (contractValuation * 1e18) / _totalSupply
                : 1e18;

            uint256 depositPrice = IDynamicValuation(dynamicValuationAddress)
                .getOraclePrice(underlyingTokenAddress, pendingDepositAssets);

            result.sharesToMint = (depositPrice * 1e18) / result.sharePrice;
        }
    }

    struct WithdrawData {
        uint256 amountUSD;
        uint256 sharesToBurn;
        uint256 sharePrice;
        uint256 totalRequests;
        uint256 usdDecimals;
    }

    function getWithdrawData(
        address usersVault
    ) public view returns (WithdrawData memory result) {
        uint256 pendingWithdrawShares = IUsersVault(usersVault)
            .pendingWithdrawShares();
        address underlyingTokenAddress = IUsersVault(usersVault)
            .underlyingTokenAddress();

        address contractsFactoryAddress = IUsersVault(usersVault)
            .contractsFactoryAddress();
        address dynamicValuationAddress = IContractsFactory(
            contractsFactoryAddress
        ).dynamicValuationAddress();

        result.usdDecimals = IDynamicValuation(dynamicValuationAddress)
            .decimals();

        result.sharesToBurn = pendingWithdrawShares;

        uint256 _totalSupply = IUsersVault(usersVault).totalSupply();
        result.sharePrice = _totalSupply != 0
            ? (IUsersVault(usersVault).getContractValuation() * 1e18) /
                _totalSupply
            : 1e18;

        uint256 processedWithdrawAssets = (result.sharePrice *
            pendingWithdrawShares) / 1e18;

        result.amountUSD = IDynamicValuation(dynamicValuationAddress)
            .getOraclePrice(underlyingTokenAddress, processedWithdrawAssets);
    }

    struct BaseVaultData {
        uint256 totalFundsUSD;
        uint256 unusedFundsUSD;
        uint256 deployedUSD;
        uint256 currentValueUSD;
        int256 returnsUSD;
        int256 returnsPercent;
        uint256 usdDecimals;
    }

    function _getBaseVaultData(
        address baseVault
    ) private view returns (BaseVaultData memory result) {
        address contractsFactoryAddress = IBaseVault(baseVault)
            .contractsFactoryAddress();
        address dynamicValuationAddress = IContractsFactory(
            contractsFactoryAddress
        ).dynamicValuationAddress();

        result.totalFundsUSD = IDynamicValuation(dynamicValuationAddress)
            .getDynamicValuation(baseVault);
        result.currentValueUSD = result.totalFundsUSD;

        uint256 afterRoundBalance = IBaseVault(baseVault).afterRoundBalance();
        if (afterRoundBalance != 0) {
            result.returnsPercent =
                int256((result.totalFundsUSD * 1e18) / afterRoundBalance) -
                int256(1e18);
        }

        result.returnsUSD =
            int256(result.totalFundsUSD) -
            int256(IBaseVault(baseVault).afterRoundBalance());

        address underlyingTokenAddress = IBaseVault(baseVault)
            .underlyingTokenAddress();
        uint256 underlyingAmount = IERC20(underlyingTokenAddress).balanceOf(
            baseVault
        );
        result.unusedFundsUSD = IDynamicValuation(dynamicValuationAddress)
            .getOraclePrice(underlyingTokenAddress, underlyingAmount);

        if (result.totalFundsUSD > result.unusedFundsUSD) {
            result.deployedUSD = result.totalFundsUSD - result.unusedFundsUSD;
        } else {
            result.deployedUSD = 0;
        }

        result.usdDecimals = IDynamicValuation(dynamicValuationAddress)
            .decimals();
    }

    struct UsersVaultData {
        uint256 totalFundsUSD;
        uint256 unusedFundsUSD;
        uint256 deployedUSD;
        uint256 currentValueUSD;
        int256 returnsUSD;
        int256 returnsPercent;
        uint256 totalShares;
        uint256 sharePrice;
        uint256 usdDecimals;
    }

    function getUsersVaultData(
        address usersVault
    ) public view returns (UsersVaultData memory result) {
        BaseVaultData memory baseVaultResult = _getBaseVaultData(usersVault);

        result.totalFundsUSD = baseVaultResult.totalFundsUSD;
        result.unusedFundsUSD = baseVaultResult.unusedFundsUSD;
        result.deployedUSD = baseVaultResult.deployedUSD;
        result.currentValueUSD = baseVaultResult.currentValueUSD;
        result.returnsUSD = baseVaultResult.returnsUSD;
        result.returnsPercent = baseVaultResult.returnsPercent;
        result.usdDecimals = baseVaultResult.usdDecimals;

        address contractsFactoryAddress = IUsersVault(usersVault)
            .contractsFactoryAddress();
        address dynamicValuationAddress = IContractsFactory(
            contractsFactoryAddress
        ).dynamicValuationAddress();
        address underlyingTokenAddress = IUsersVault(usersVault)
            .underlyingTokenAddress();

        uint256 oneUnderlyingToken = 10 **
            IERC20Metadata(underlyingTokenAddress).decimals();
        uint256 underlyingPrice = IDynamicValuation(dynamicValuationAddress)
            .getOraclePrice(underlyingTokenAddress, oneUnderlyingToken);

        uint256 reservedAssets = IUsersVault(usersVault).kunjiFeesAssets() +
            IUsersVault(usersVault).pendingDepositAssets() +
            IUsersVault(usersVault).processedWithdrawAssets();
        uint256 reservedValuation = (reservedAssets * underlyingPrice) /
            oneUnderlyingToken;

        if (result.unusedFundsUSD > reservedValuation) {
            result.unusedFundsUSD -= reservedValuation;
        } else {
            result.unusedFundsUSD = 0;
        }

        if (result.deployedUSD > reservedValuation) {
            result.deployedUSD -= reservedValuation;
        } else {
            result.deployedUSD = 0;
        }

        if (result.totalFundsUSD > reservedValuation) {
            result.totalFundsUSD -= reservedValuation;
        } else {
            result.totalFundsUSD = 0;
        }

        result.totalShares = IUsersVault(usersVault).totalSupply();
        if (result.totalShares != 0 && result.totalFundsUSD != 0) {
            result.sharePrice =
                (result.totalFundsUSD * 1e18) /
                result.totalShares;
        } else {
            result.sharePrice = 1e18;
        }
    }

    struct TraderWalletData {
        uint256 totalFundsUSD;
        uint256 unusedFundsUSD;
        uint256 deployedUSD;
        uint256 currentValueUSD;
        int256 returnsUSD;
        int256 returnsPercent;
        uint256 uvTvUnused;
        uint256 usdDecimals;
    }

    function getTraderWalletData(
        address traderWallet
    ) public view returns (TraderWalletData memory result) {
        BaseVaultData memory baseVaultResult = _getBaseVaultData(traderWallet);

        result.totalFundsUSD = baseVaultResult.totalFundsUSD;
        result.unusedFundsUSD = baseVaultResult.unusedFundsUSD;
        result.deployedUSD = baseVaultResult.deployedUSD;
        result.currentValueUSD = baseVaultResult.currentValueUSD;
        result.returnsUSD = baseVaultResult.returnsUSD;
        result.returnsPercent = baseVaultResult.returnsPercent;
        result.usdDecimals = baseVaultResult.usdDecimals;
    }

    function getDashboardInfo(
        address traderWallet
    )
        external
        view
        returns (
            UsersVaultData memory usersVaultData,
            TraderWalletData memory traderWalletData,
            DepositData memory depositDataRollover,
            WithdrawData memory withdrawDataRollover
        )
    {
        address usersVault = ITraderWallet(traderWallet).vaultAddress();

        usersVaultData = getUsersVaultData(usersVault);
        traderWalletData = getTraderWalletData(traderWallet);

        depositDataRollover = getDepositData(usersVault);
        withdrawDataRollover = getWithdrawData(usersVault);
    }

    struct GmxPrices {
        uint256 tokenMaxPrice;
        uint256 tokenMinPrice;
    }

    /// @notice Returns token prices from gmx oracle
    /// @dev max is used for long positions, min for short
    /// @param token The token address
    /// @return prices Token's max and min prices in USD scaled to 1e30
    function getGmxPrices(
        address token
    ) external view returns (GmxPrices memory prices) {
        prices.tokenMaxPrice = gmxVault.getMaxPrice(token);
        prices.tokenMinPrice = gmxVault.getMinPrice(token);
    }

    /// @notice Returns token price from gmx oracle
    /// @dev used for long positions
    /// @param token The token address
    /// @return Token price in USD scaled to 1e30
    function getGmxMaxPrice(address token) external view returns (uint256) {
        return gmxVault.getMaxPrice(token);
    }

    /// @notice Returns token price from gmx oracle
    /// @dev used for short positions
    /// @param token The token address
    /// @return Token price in USD scaled to 1e30
    function getGmxMinPrice(address token) external view returns (uint256) {
        return gmxVault.getMinPrice(token);
    }

    /// @notice Returns fee amount for opening/increasing/decreasing/closing position
    /// @return ETH amount of required fee
    function getGmxExecutionFee() external view returns (uint256) {
        return gmxPositionRouter.minExecutionFee();
    }

    /// @notice Returns fee amount for executing orders
    /// @return ETH amount of required fee for executing orders
    function getGmxOrderExecutionFee() external view returns (uint256) {
        return IGmxOrderBook(gmxOrderBook).minExecutionFee();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IQuoterV2 {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInput(
        bytes memory path,
        uint256 amountIn
    )
        external
        returns (
            uint256 amountOut,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactInputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountIn The desired input amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactInputSingle(
        QuoteExactInputSingleParams memory params
    )
        external
        returns (
            uint256 amountOut,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    /// @return sqrtPriceX96AfterList List of the sqrt price after the swap for each pool in the path
    /// @return initializedTicksCrossedList List of the initialized ticks that the swap crossed for each pool in the path
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutput(
        bytes memory path,
        uint256 amountOut
    )
        external
        returns (
            uint256 amountIn,
            uint160[] memory sqrtPriceX96AfterList,
            uint32[] memory initializedTicksCrossedList,
            uint256 gasEstimate
        );

    struct QuoteExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint24 fee;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param params The params for the quote, encoded as `QuoteExactOutputSingleParams`
    /// tokenIn The token being swapped in
    /// tokenOut The token being swapped out
    /// fee The fee of the token pool to consider for the pair
    /// amountOut The desired output amount
    /// sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    /// @return sqrtPriceX96After The sqrt price of the pool after the swap
    /// @return initializedTicksCrossed The number of initialized ticks that the swap crossed
    /// @return gasEstimate The estimate of the gas that the swap consumes
    function quoteExactOutputSingle(
        QuoteExactOutputSingleParams memory params
    )
        external
        returns (
            uint256 amountIn,
            uint160 sqrtPriceX96After,
            uint32 initializedTicksCrossed,
            uint256 gasEstimate
        );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IUniswapV3Router {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(
        ExactInputParams calldata params
    ) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(
        ExactOutputParams calldata params
    ) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IAdapter {
    struct AdapterOperation {
        // id to identify what type of operation the adapter should do
        // this is a generic operation
        uint8 operationId;
        // signatura of the funcion
        // abi.encodeWithSignature
        bytes data;
    }

    // receives the operation to perform in the adapter and the ratio to scale whatever needed
    // answers if the operation was successfull
    function executeOperation(
        bool,
        address,
        address,
        uint256,
        AdapterOperation memory
    ) external returns (bool, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBaseVault {
    function underlyingTokenAddress() external view returns (address);

    function contractsFactoryAddress() external view returns (address);

    function currentRound() external view returns (uint256);

    function afterRoundBalance() external view returns (uint256);

    function getGmxShortCollaterals() external view returns (address[] memory);

    function getGmxShortIndexTokens() external view returns (address[] memory);

    function getAllowedTradeTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IContractsFactory {
    error ZeroAddress(string target);
    error InvalidCaller();
    error FeeRateError();
    error ZeroAmount();
    error InvestorAlreadyExists();
    error InvestorNotExists();
    error TraderAlreadyExists();
    error TraderNotExists();
    error FailedWalletDeployment();
    error FailedVaultDeployment();
    error InvalidWallet();
    error InvalidVault();
    error InvalidTrader();
    error InvalidToken();
    error TokenPresent();
    error UsersVaultAlreadyDeployed();

    event FeeRateSet(uint256 newFeeRate);
    event FeeReceiverSet(address newFeeReceiver);
    event InvestorAdded(address indexed investorAddress);
    event InvestorRemoved(address indexed investorAddress);
    event TraderAdded(address indexed traderAddress);
    event TraderRemoved(address indexed traderAddress);
    event GlobalTokenAdded(address tokenAddress);
    event GlobalTokenRemoved(address tokenAddress);
    event AdaptersRegistryAddressSet(address indexed adaptersRegistryAddress);
    event DynamicValuationAddressSet(address indexed dynamicValuationAddress);
    event LensAddressSet(address indexed lensAddress);
    event TraderWalletDeployed(
        address indexed traderWalletAddress,
        address indexed traderAddress,
        address indexed underlyingTokenAddress
    );
    event UsersVaultDeployed(
        address indexed usersVaultAddress,
        address indexed traderWalletAddress
    );
    event OwnershipToWalletChanged(
        address indexed traderWalletAddress,
        address indexed newOwner
    );
    event OwnershipToVaultChanged(
        address indexed usersVaultAddress,
        address indexed newOwner
    );
    event TraderWalletImplementationChanged(address indexed newImplementation);
    event UsersVaultImplementationChanged(address indexed newImplementation);

    function BASE() external view returns (uint256);

    function feeRate() external view returns (uint256);

    function feeReceiver() external view returns (address);

    function dynamicValuationAddress() external view returns (address);

    function adaptersRegistryAddress() external view returns (address);

    function lensAddress() external view returns (address);

    function traderWalletsArray(uint256) external view returns (address);

    function isTraderWallet(address) external view returns (bool);

    function usersVaultsArray(uint256) external view returns (address);

    function isUsersVault(address) external view returns (bool);

    function allowedTraders(address) external view returns (bool);

    function allowedInvestors(address) external view returns (bool);

    function initialize(
        uint256 feeRate,
        address feeReceiver,
        address traderWalletImplementation,
        address usersVaultImplementation
    ) external;

    function addInvestors(address[] calldata investors) external;

    function addInvestor(address investorAddress) external;

    function removeInvestor(address investorAddress) external;

    function addTraders(address[] calldata traders) external;

    function addTrader(address traderAddress) external;

    function removeTrader(address traderAddress) external;

    function setDynamicValuationAddress(
        address dynamicValuationAddress
    ) external;

    function setAdaptersRegistryAddress(
        address adaptersRegistryAddress
    ) external;

    function setLensAddress(address lensAddress) external;

    function setFeeReceiver(address newFeeReceiver) external;

    function setFeeRate(uint256 newFeeRate) external;

    function setUsersVaultImplementation(address newImplementation) external;

    function setTraderWalletImplementation(address newImplementation) external;

    function addGlobalAllowedTokens(address[] calldata) external;

    function removeGlobalToken(address) external;

    function deployTraderWallet(
        address underlyingTokenAddress,
        address traderAddress,
        address owner
    ) external;

    function deployUsersVault(
        address traderWalletAddress,
        address owner,
        string memory sharesName,
        string memory sharesSymbol
    ) external;

    function usersVaultImplementation() external view returns (address);

    function traderWalletImplementation() external view returns (address);

    function numOfTraderWallets() external view returns (uint256);

    function numOfUsersVaults() external view returns (uint256);

    function isAllowedGlobalToken(address token) external returns (bool);

    function allowedGlobalTokensAt(
        uint256 index
    ) external view returns (address);

    function allowedGlobalTokensLength() external view returns (uint256);

    function getAllowedGlobalTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IDynamicValuation {
    struct OracleData {
        address dataFeed;
        uint8 dataFeedDecimals;
        uint32 heartbeat;
        uint8 tokenDecimals;
    }

    error WrongAddress();
    error NotUniqiueValues();

    error BadPrice();
    error TooOldPrice();
    error NoOracleForToken(address token);

    error NoObserver();

    error SequencerDown();
    error GracePeriodNotOver();

    event SetChainlinkOracle(address indexed token, OracleData oracleData);

    event SetGmxObserver(address indexed newGmxObserver);

    function factory() external view returns (address);

    function decimals() external view returns (uint8);

    function sequencerUptimeFeed() external view returns (address);

    function gmxObserver() external view returns (address);

    function initialize(
        address _factory,
        address _sequencerUptimeFeed,
        address _gmxObserver
    ) external;

    function setChainlinkPriceFeed(
        address token,
        address priceFeed,
        uint32 heartbeat
    ) external;

    function setGmxObserver(address newValue) external;

    function chainlinkOracles(
        address token
    ) external view returns (OracleData memory);

    function getOraclePrice(
        address token,
        uint256 amount
    ) external view returns (uint256);

    function getDynamicValuation(
        address addr
    ) external view returns (uint256 valuation);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {IBaseVault} from "./IBaseVault.sol";
import {IAdapter} from "./IAdapter.sol";

interface ITraderWallet is IBaseVault {
    function vaultAddress() external view returns (address);

    function traderAddress() external view returns (address);

    function cumulativePendingDeposits() external view returns (uint256);

    function cumulativePendingWithdrawals() external view returns (uint256);

    function lastRolloverTimestamp() external view returns (uint256);

    function gmxShortPairs(address, address) external view returns (bool);

    function gmxShortCollaterals(uint256) external view returns (address);

    function gmxShortIndexTokens(uint256) external view returns (address);

    function initialize(
        address underlyingTokenAddress,
        address traderAddress,
        address ownerAddress
    ) external;

    function setVaultAddress(address vaultAddress) external;

    function setTraderAddress(address traderAddress) external;

    function addGmxShortPairs(
        address[] calldata collateralTokens,
        address[] calldata indexTokens
    ) external;

    function addAllowedTradeTokens(address[] calldata tokens) external;

    function removeAllowedTradeToken(address token) external;

    function addProtocolToUse(uint256 protocolId) external;

    function removeProtocolToUse(uint256 protocolId) external;

    function traderDeposit(uint256 amount) external;

    function withdrawRequest(uint256 amount) external;

    function setAdapterAllowanceOnToken(
        uint256 protocolId,
        address tokenAddress,
        bool revoke
    ) external;

    function rollover() external;

    function executeOnProtocol(
        uint256 protocolId,
        IAdapter.AdapterOperation memory traderOperation,
        bool replicate
    ) external;

    function getAdapterAddressPerProtocol(
        uint256 protocolId
    ) external view returns (address);

    function isAllowedTradeToken(address token) external view returns (bool);

    function allowedTradeTokensLength() external view returns (uint256);

    function allowedTradeTokensAt(
        uint256 index
    ) external view returns (address);

    function isTraderSelectedProtocol(
        uint256 protocolId
    ) external view returns (bool);

    function traderSelectedProtocolIdsLength() external view returns (uint256);

    function traderSelectedProtocolIdsAt(
        uint256 index
    ) external view returns (uint256);

    function getTraderSelectedProtocolIds()
        external
        view
        returns (uint256[] memory);

    function getContractValuation() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {IBaseVault} from "./IBaseVault.sol";
import {IAdapter} from "./IAdapter.sol";

interface IUsersVault is IBaseVault, IERC20Upgradeable {
    struct UserData {
        uint256 round;
        uint256 pendingDepositAssets;
        uint256 pendingWithdrawShares;
        uint256 unclaimedDepositShares;
        uint256 unclaimedWithdrawAssets;
    }

    function traderWalletAddress() external view returns (address);

    function pendingDepositAssets() external view returns (uint256);

    function pendingWithdrawShares() external view returns (uint256);

    function processedWithdrawAssets() external view returns (uint256);

    function kunjiFeesAssets() external view returns (uint256);

    function userData(address) external view returns (UserData memory);

    function assetsPerShareXRound(uint256) external view returns (uint256);

    function initialize(
        address underlyingTokenAddress,
        address traderWalletAddress,
        address ownerAddress,
        string memory sharesName,
        string memory sharesSymbol
    ) external;

    function collectFees(uint256 amount) external;

    function setAdapterAllowanceOnToken(
        uint256 protocolId,
        address tokenAddress,
        bool revoke
    ) external;

    function userDeposit(uint256 amount) external;

    function withdrawRequest(uint256 sharesAmount) external;

    function rolloverFromTrader() external;

    function executeOnProtocol(
        uint256 protocolId,
        IAdapter.AdapterOperation memory traderOperation,
        uint256 walletRatio
    ) external;

    function getContractValuation() external view returns (uint256);

    function previewShares(address receiver) external view returns (uint256);

    function claim() external;
}