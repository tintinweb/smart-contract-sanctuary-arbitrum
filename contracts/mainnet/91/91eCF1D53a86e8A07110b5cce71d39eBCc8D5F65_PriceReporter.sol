// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.18;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IOrderManager} from "../interfaces/IOrderManager.sol";

interface IPriceFeed {
    function postPrices(address[] calldata tokens, uint256[] calldata prices) external;
}

/**
 * @title PriceReporter
 * @notice Utility contract to call post prices and execute orders on a single transaction
 */
contract PriceReporter is Ownable {
    uint256 public constant MAX_MARKET_ORDER_EXECUTION = 1000;
    IPriceFeed public immutable oracle;
    IOrderManager public immutable orderManager;
    mapping(address => bool) public isReporter;
    address[] public reporters;

    constructor(address _oracle, address _orderManager) {
        require(_oracle != address(0), "PriceReporter:invalidOracle");
        require(_orderManager != address(0), "PriceReporter:invalidPositionManager");
        oracle = IPriceFeed(_oracle);
        orderManager = IOrderManager(_orderManager);
    }

    function postPriceAndExecuteOrders(
        address[] calldata tokens,
        uint256[] calldata prices,
        uint256[] calldata leverageOrders,
        uint256[] calldata swapOrders
    ) external {
        require(isReporter[msg.sender], "PriceReporter:unauthorized");
        oracle.postPrices(tokens, prices);

        for (uint256 i = 0; i < leverageOrders.length;) {
            try orderManager.executeLeverageOrder(leverageOrders[i], payable(msg.sender)) {} catch {}
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < swapOrders.length; i++) {
            try orderManager.executeSwapOrder(swapOrders[i], payable(msg.sender)) {} catch {}
            unchecked {
                ++i;
            }
        }
    }

    function addReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "PriceReporter:invalidAddress");
        require(!isReporter[reporter], "PriceReporter:reporterAlreadyAdded");
        isReporter[reporter] = true;
        reporters.push(reporter);
    }

    function removeReporter(address reporter) external onlyOwner {
        require(isReporter[reporter], "PriceReporter:reporterNotExists");
        isReporter[reporter] = false;
        for (uint256 i = 0; i < reporters.length; i++) {
            if (reporters[i] == reporter) {
                reporters[i] = reporters[reporters.length - 1];
                break;
            }
        }
        reporters.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.8.0;

import {DataTypes} from "../lib/DataTypes.sol";

interface IOrderManager {
    function placeLeverageOrder(
        DataTypes.UpdatePositionType _updateType,
        DataTypes.Side _side,
        address _indexToken,
        address _collateralToken,
        DataTypes.OrderType _orderType,
        bytes calldata data
    ) external payable returns (uint256 orderId);

    function executeLeverageOrder(uint256 _orderId, address payable _feeTo) external;

    function cancelLeverageOrder(uint256 _orderId) external;

    function placeSwapOrder(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _price,
        bytes calldata _extradata
    ) external payable returns (uint256 orderId);

    function executeSwapOrder(uint256 _orderId, address payable _feeTo) external;

    function cancelSwapOrder(uint256 _orderId) external;

    function swap(
        address _fromToken,
        address _toToken,
        uint256 _amountIn,
        uint256 _minAmountOut,
        bytes calldata extradata
    ) external payable;

    // ========== EVENTS =========

    event LeverageOrderPlaced(
        uint256 indexed key, DataTypes.LeverageOrder order, DataTypes.UpdatePositionRequest request
    );
    event LeverageOrderCancelled(uint256 indexed key);
    event LeverageOrderExecuted(
        uint256 indexed key, DataTypes.LeverageOrder order, DataTypes.UpdatePositionRequest request, uint256 fillPrice
    );
    event LeverageOrderExpired(uint256 indexed key);
    event SwapOrderPlaced(uint256 indexed key, DataTypes.SwapOrder order);
    event SwapOrderCancelled(uint256 indexed key);
    event SwapOrderExecuted(uint256 indexed key, uint256 amountIn, uint256 amountOut);
    event Swap(
        address indexed account,
        address indexed tokenIn,
        address indexed tokenOut,
        address pool,
        uint256 amountIn,
        uint256 amountOut
    );
    event OracleChanged(address);
    event PoolSet(address indexed pool);
    event MinLeverageExecutionFeeSet(uint256 leverageExecutionFee);
    event MinSwapExecutionFeeSet(uint256 swapExecutionFee);
    event OrderHookSet(address indexed hook);
    event ExecutorSet(address indexed executor);
    event ControllerSet(address indexed controller);
    event SetEnablePublicExecution(bool isEnable);
    event SetExecutionDelayTime(uint256 delay);

    // ======= ERRORS ========

    error OnlyExecutor();
    error OnlyWeth();
    error ZeroAddress();
    error InvalidExecutionFee();
    error InvalidLeverageTokenPair(address indexToken, address collateralToken);
    error InvalidSwapPair();
    error SameTokenSwap();
    error OnlyOrderOwner();
    error OrderNotOpen();
    error ExecutionDelay();
    error ExecutionFeeTooLow();
    error SlippageReached();
    error ZeroPurchaseAmount();
    error InvalidPurchaseToken();
    error OnlyOwnerOrController();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.8.0;

library DataTypes {
    enum Side {
        LONG,
        SHORT
    }

    enum UpdatePositionType {
        INCREASE,
        DECREASE
    }

    struct UpdatePositionRequest {
        uint256 sizeChange;
        uint256 collateral;
        UpdatePositionType updateType;
        Side side;
    }

    enum OrderType {
        MARKET,
        LIMIT
    }

    enum OrderStatus {
        OPEN,
        FILLED,
        EXPIRED,
        CANCELLED
    }

    struct LeverageOrder {
        address owner;
        address indexToken;
        address collateralToken;
        OrderStatus status;
        bool triggerAboveThreshold;
        address payToken;
        uint256 price;
        uint256 executionFee;
        uint256 submissionBlock;
        uint256 expiresAt;
        uint256 submissionTimestamp;
    }

    struct SwapOrder {
        address owner;
        address tokenIn;
        address tokenOut;
        OrderStatus status;
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 price;
        uint256 executionFee;
        uint256 submissionBlock;
        uint256 submissionTimestamp;
    }

    struct AssetInfo {
        /// @notice amount of token deposited (via add liquidity or increase long position)
        uint256 poolAmount;
        /// @notice amount of token reserved for paying out when user decrease long position
        uint256 reservedAmount;
        /// @notice total borrowed (in USD) to leverage
        uint256 guaranteedValue;
        /// @notice total size of all short positions
        uint256 totalShortSize;
        /// @notice average entry price of all short positions
        uint256 averageShortPrice;
    }

    struct Position {
        /// @dev contract size is evaluated in dollar
        uint256 size;
        /// @dev collateral value in dollar
        uint256 collateralValue;
        /// @dev contract size in indexToken
        uint256 reserveAmount;
        /// @dev average entry price
        uint256 entryPrice;
        /// @dev last cumulative interest rate
        uint256 borrowIndex;
    }
}