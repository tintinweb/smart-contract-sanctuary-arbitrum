// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
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

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IOrder {
    enum OrderType {
        Loan,
        Borrow
    }

    enum OrderStatus {
        Open,
        Active,
        Repaid,
        Canceled,
        Liquidated
    }

    enum LiquidationType {
        ReturnAsIs,
        ConvertToLoanToken
    }

    function orderId() external view returns (uint256);

    function creator() external view returns (address);

    function duration() external view returns (uint256);

    function expireDate() external view returns (uint256);

    function activationTime() external view returns (uint256);

    function interestRate() external view returns (uint256);

    function threshold() external view returns (uint256);

    function borrower() external view returns (address);

    function lender() external view returns (address);

    function collateralToken() external view returns (address);

    function loanToken() external view returns (address);

    function collateralTokenAmount() external view returns (uint256);

    function loanTokenAmount() external view returns (uint256);

    function orderType() external view returns (OrderType);

    function status() external view returns (OrderStatus);

    function liquidationType() external view returns (LiquidationType);

    function protocolManager() external view returns (address);

    function uniswapV2Factory() external view returns (address);

    function initialize(
        uint256 orderId,
        address creator,
        uint256 duration,
        uint256 interestRate,
        uint256 threshold,
        address loanToken,
        address collateralToken,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        OrderType orderType,
        LiquidationType liquidationType,
        address protocolManager,
        address uniswapV2Factory
    ) external;

    function acceptOrder(address asker, LiquidationType liquidationType) external;

    function cancelOrder(address creator) external;

    function repayOrder(
        address payer,
        address protocolRewardAddress,
        uint256 protocolReward
    ) external returns (uint256);

    function liquidateOrder(uint256 protocolRewardRate, address uniswapV2Router) external;

    function sendTokens(
        address token,
        address recipient,
        uint256 amount
    ) external;

    function checkLiquidation(
        address loanToken,
        address collateralToken,
        uint256 loanTokenAmount,
        uint256 collateralTokenAmount,
        address uniswapV2Factory,
        uint256 threshold
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./interfaces/IOrder.sol";

contract Order is IOrder, Initializable {
    /// @notice Unique identifier for the order within the protocol manager's orders mapping
    uint256 public orderId;
    /// @notice Address of the order's creator
    address public creator;
    /// @notice Duration in seconds until the order expires
    uint256 public duration;
    /// @notice Timestamp when the order expires after accepting
    uint256 public expireDate;
    /// @notice Timestamp when the order becomes active
    uint256 public activationTime;
    /// @notice Annual interest rate for the loan
    uint256 public interestRate;
    /// @notice Liquidation threshold as a ratio of loan to collateral value
    uint256 public threshold;

    /// @notice Address of the borrower
    address public borrower;
    /// @notice Address of the lender
    address public lender;

    /// @notice ERC20 token address used for the loan
    address public loanToken;
    /// @notice ERC20 token address used as collateral
    address public collateralToken;
    /// @notice Amount of loan tokens involved in the order
    uint256 public loanTokenAmount;
    /// @notice Amount of collateral tokens involved in the order
    uint256 public collateralTokenAmount;
    /// @notice Type of the order (Loan or Borrow)
    OrderType public orderType;
    /// @notice Current status of the order
    OrderStatus public status;
    /// @notice Liquidation strategy for the collateral
    LiquidationType public liquidationType;

    /// @notice Address of the Protocol Manager contract
    address public protocolManager;
    /// @notice Address of the Uniswap V2 Factory contract
    address public uniswapV2Factory;

    /// @dev Ensures that only the protocol manager can call the function
    modifier onlyProtocolManager() {
        require(msg.sender == protocolManager, "Callable only by ProtocolManager");
        _;
    }

    /// @notice Initializes a new order with given parameters
    /// @dev Only callable once due to the `initializer` modifier from OZ's Initializable contract
    /// @param orderId_ Unique identifier for the order within the protocol
    /// @param creator_ Address of the user creating the order
    /// @param duration_ Duration in seconds from now until the order can no longer be accepted
    /// @param interestRate_ The annual interest rate for the loan
    /// @param threshold_ Liquidation threshold as a percentage
    /// @param loanToken_ The ERC20 token address to be used for the loan
    /// @param collateralToken_ The ERC20 token address to be used as collateral
    /// @param loanTokenAmount_ Amount of the loan token involved in the order
    /// @param collateralTokenAmount_ Amount of the collateral token involved in the order
    /// @param orderType_ Specifies the type of the order, either Loan or Borrow
    /// @param liquidationType_ Defines the strategy for liquidating the collateral
    /// @param protocolManager_ Address of the Protocol Manager contract
    /// @param uniswapV2Factory_ Address of the Uniswap V2 Factory contract for liquidity checks
    function initialize(
        uint256 orderId_,
        address creator_,
        uint256 duration_,
        uint256 interestRate_,
        uint256 threshold_,
        address loanToken_,
        address collateralToken_,
        uint256 loanTokenAmount_,
        uint256 collateralTokenAmount_,
        OrderType orderType_,
        LiquidationType liquidationType_,
        address protocolManager_,
        address uniswapV2Factory_
    ) external initializer {
        require(!checkLiquidation(loanToken_, collateralToken_, loanTokenAmount_, collateralTokenAmount_, uniswapV2Factory_, threshold_), "Collateral value below liquidation threshold");

        orderId = orderId_;
        creator = creator_;
        duration = duration_;
        interestRate = interestRate_;
        threshold = threshold_;
        orderType = orderType_;
        loanToken = loanToken_;
        collateralToken = collateralToken_;
        loanTokenAmount = loanTokenAmount_;
        collateralTokenAmount = collateralTokenAmount_;
        protocolManager = protocolManager_;
        uniswapV2Factory = uniswapV2Factory_;
        status = OrderStatus.Open;

        if (orderType == OrderType.Loan) {
            lender = creator_;
            liquidationType = liquidationType_;
        } else {
            borrower = creator_;
        }
    }

    /// @notice Accepts an open order by setting the borrower or lender and changing the order status to Active
    /// @dev Can only be called by the protocol manager and when the order has not yet been accepted
    /// @param asker Address of the user accepting the order
    /// @param liquidationType_ The liquidation strategy chosen by the asker, applicable to borrow orders
    function acceptOrder(address asker, LiquidationType liquidationType_) external onlyProtocolManager {
        require(asker != creator, "Invalid asker");
        require(!checkLiquidation(loanToken, collateralToken, loanTokenAmount, collateralTokenAmount, uniswapV2Factory, threshold), "Collateral value below liquidation threshold");

        if (orderType == OrderType.Loan) {
            borrower = asker;
        } else {
            lender = asker;
            liquidationType = liquidationType_;
        }

        expireDate = block.timestamp + duration;
        activationTime = block.timestamp;
        status = OrderStatus.Active;
    }

    /// @notice Cancels an order if it is still open
    /// @dev Can only be called by the protocol manager and by the creator of the order
    /// @param creator_ Address of the creator attempting to cancel the order
    function cancelOrder(address creator_) external onlyProtocolManager {
        require(creator_ == creator, "Only the creator can cancel the order");

        status = OrderStatus.Canceled;
    }

    /// @notice Allows the borrower to repay the loan, transferring the loan amount plus interest back to the lender and returning collateral
    /// @dev Can only be called by the protocol manager and by the borrower of the order
    /// @param payer Address of the borrower repaying the loan
    /// @param protocolRewardAddress Address to send the protocol's portion of the interest
    /// @param protocolRewardRate Protocol's fee rate from the interest, calculated as a proportion of 100 (e.g., 5 for 5%)
    /// @return repayAmount Total amount repaid, including interest
    function repayOrder(
        address payer,
        address protocolRewardAddress,
        uint256 protocolRewardRate
    ) external onlyProtocolManager returns (uint256) {
        require(borrower == payer, "Only the borrower can repay the loan");

        uint256 interest = (loanTokenAmount * interestRate) / 100;
        uint256 repayAmount = loanTokenAmount + interest;
        uint256 protocolReward = (interest * protocolRewardRate) / 100;

        IERC20(loanToken).transferFrom(payer, lender, repayAmount - protocolReward);
        IERC20(loanToken).transferFrom(payer, protocolRewardAddress, protocolReward);

        IERC20(collateralToken).transfer(borrower, collateralTokenAmount);

        status = OrderStatus.Repaid;

        return repayAmount;
    }

    /// @notice Liquidates an order if its collateral value falls below the specified threshold
    /// @dev Can only be called by the protocol manager and when the order is eligible for liquidation
    /// @param protocolRewardRate Protocol's fee rate from the interest, calculated as a proportion of 100 (e.g., 5 for 5%).
    /// @param uniswapV2Router Address of the Uniswap V2 Router for converting collateral to loan tokens if necessary
    function liquidateOrder(uint256 protocolRewardRate, address uniswapV2Router) external onlyProtocolManager {
        require(checkLiquidation(
            loanToken,
            collateralToken,
            loanTokenAmount,
            collateralTokenAmount,
            uniswapV2Factory,
            threshold)
        || block.timestamp > expireDate, "Collateral value above liquidation threshold or order not expired yet");

        uint256 protocolReward = (collateralTokenAmount * protocolRewardRate) / 100;

        if (liquidationType == LiquidationType.ConvertToLoanToken) {
            uint256 amountToConvert = collateralTokenAmount - protocolReward;

            IERC20(collateralToken).approve(uniswapV2Router, amountToConvert);

            address[] memory path = new address[](2);
            path[0] = collateralToken;
            path[1] = loanToken;

            IUniswapV2Router02(uniswapV2Router).swapExactTokensForTokens(
                amountToConvert,
                0,
                path,
                lender,
                block.timestamp + 300 // Deadline
            );
        } else {
            IERC20(collateralToken).transfer(lender, collateralTokenAmount - protocolReward);
        }

        IERC20(collateralToken).transfer(protocolManager, protocolReward);

        status = OrderStatus.Liquidated;
    }

    /// @notice Transfers tokens from the order contract to a specified recipient
    /// @dev Can only be called by the protocol manager to handle token transfers as part of order lifecycle events
    /// @param token The ERC20 token address to transfer
    /// @param recipient The address receiving the tokens
    /// @param amount The amount of tokens to transfer
    function sendTokens(
        address token,
        address recipient,
        uint256 amount
    ) external onlyProtocolManager {
        IERC20(token).transfer(recipient, amount);
    }

    /// @notice Checks if an order's collateral is below the liquidation threshold of if order has expired
    /// @dev Used to determine if an order is eligible for liquidation
    /// @param loanToken_ The loan token address
    /// @param collateralToken_ The collateral token address
    /// @param loanTokenAmount_ The amount of the loan token
    /// @param collateralTokenAmount_ The amount of the collateral token
    /// @param uniswapV2Factory_ The Uniswap V2 Factory address for getting the pair's reserves
    /// @param threshold_ The liquidation threshold percentage
    /// @return bool indicating whether the order is eligible for liquidation
    function checkLiquidation(
        address loanToken_,
        address collateralToken_,
        uint256 loanTokenAmount_,
        uint256 collateralTokenAmount_,
        address uniswapV2Factory_,
        uint256 threshold_
    ) public view returns (bool) {
        address pairAddress = IUniswapV2Factory(uniswapV2Factory_).getPair(loanToken_, collateralToken_);
        require(pairAddress != address(0), "No Uniswap pair exists for this token pair");

        (uint256 loanTokenReserve, uint256 collateralTokenReserve,) = IUniswapV2Pair(pairAddress).getReserves();
        require(loanTokenReserve > 0 && collateralTokenReserve > 0, "No liquidity in Uniswap pair");

        // Calculate the price based on the reserves
        uint256 collateralValueInLoanToken = (collateralTokenAmount_ * loanTokenReserve) / collateralTokenReserve;

        // Calculate the liquidation threshold value of the loan
        uint256 liquidationValue = (loanTokenAmount_ * threshold_) / 100;

        return collateralValueInLoanToken < liquidationValue;
    }
}