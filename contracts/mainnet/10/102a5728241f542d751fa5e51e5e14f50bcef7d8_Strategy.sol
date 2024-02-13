// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20, IStrategy} from "./interfaces/IStrategy.sol";
import {IUniSwapRouter} from "./interfaces/IUniSwapRouter.sol";
import {IGmxDataStore} from "./interfaces/IGmxDataStore.sol";
import {IGmxReader, Market} from "./interfaces/IGmxReader.sol";
import {Keys} from "./libraries/Keys.sol";
import {IGmxExchangeRouter, BaseOrderUtils, OrderType, DecreasePositionSwapType} from "./interfaces/IGmxExchangeRouter.sol";

// Upgrades
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:oz-upgrades-from src/StrategyOld.sol:StrategyOld
contract Strategy is IStrategy, UUPSUpgradeable, OwnableUpgradeable {

    using SafeTransferLib for ERC20;

    // The token the strategy accepts/returns (e.g. USDC).
    ERC20 public token;

    // The token the strategy uses (e.g. WETH).
    ERC20 public strategyToken;

    // Returns the GMX market the strategy will use.
    address public market;

    // Returns the new asset value of the strategy in token() units.
    uint256 public totalValue;

    // Uniswap V3 router.
    IUniSwapRouter private constant uniswapRouter = IUniSwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);

    // Gmx exchange router.
    IGmxExchangeRouter private constant gmxExchangeRouter = IGmxExchangeRouter(0x7C68C7866A64FA2160F78EEaE12217FFbf871fa8);

    // todo, not used
    IGmxDataStore private constant dataStore = IGmxDataStore(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);

    IGmxReader private constant reader = IGmxReader(0x60a0fF4cDaF0f6D496d71e0bC0fFa86FE8E6B23c);

    // Gmx order vautl.
    address private constant orderVault = 0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5;

    uint256 private constant PRECISION = 1e30;

    // gas limit for orders.
    uint256 public gasLimit;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Initializes the contract.
    function initialize(address _market) public initializer {
        __Ownable_init(msg.sender);
        (Market.Props memory marketProps) = reader.getMarket(address(dataStore), _market);
        strategyToken = ERC20(marketProps.longToken); // WETH
        token = ERC20(marketProps.shortToken); // USDC
        market = _market;
        token.approve(address(gmxExchangeRouter), type(uint256).max);
        token.approve(address(uniswapRouter), type(uint256).max);
        strategyToken.approve(address(gmxExchangeRouter), type(uint256).max);
        strategyToken.approve(address(uniswapRouter), type(uint256).max);
        gasLimit = 1500000 + 4000000; // deposit gas + increase order gas
    }

    /* constructor(address _token, address _strategyToken, address _market) Owned(msg.sender) {
        token = ERC20(_token);
        strategyToken = ERC20(_strategyToken);
        market = _market;
        token.approve(address(gmxExchangeRouter), type(uint256).max);
        token.approve(address(uniswapRouter), type(uint256).max);
        strategyToken.approve(address(gmxExchangeRouter), type(uint256).max);
        strategyToken.approve(address(uniswapRouter), type(uint256).max);
    } */

    /// @notice Restructs upgrades to the owner only.
    function _authorizeUpgrade(address) internal override onlyOwner {}

    function setGasLimit(uint256 _gasLimit) external onlyOwner {
        gasLimit = _gasLimit;
    }

    // Deployes the tokens in the strategy.
    /* 
    1) Wrap and send ETH to pay the open position fee
    2) Send USDC and create order (internal swap)

    ...or

    (lets go with this)

    1) Swap USDC to WETH
    2) Send all WETH to GMX
    3) Create order (no swap)
     */
    // 0.0011 ETH fee ~$2.5
    function enter() public payable onlyOwner {
        uint256 amount = token.balanceOf(address(this));
        uint256 strategyTokenAmount = _swap(address(token), address(strategyToken), address(orderVault), amount, 0);
        // Execution fee will be taken out of the deposited token amount.
        uint256 price = amount * 1e24 / strategyTokenAmount;
        uint256 executionFee = gasLimit * tx.gasprice * 2;
        uint256 executionFeeUsd = amount * executionFee / strategyTokenAmount;
        require (amount > executionFeeUsd, "GmxDeltaNeutralStrategy: insufficient amount");
        gmxExchangeRouter.createOrder(BaseOrderUtils.CreateOrderParams({
            addresses: BaseOrderUtils.CreateOrderParamsAddresses({
                receiver: address(this), //address 
                callbackContract: address(0), //address 
                uiFeeReceiver: address(0), //address 
                market: market, //address 
                initialCollateralToken: address(strategyToken), //address 
                swapPath: new address[](0) //address[] 
            }),
            numbers: BaseOrderUtils.CreateOrderParamsNumbers({
                sizeDeltaUsd: (amount - executionFeeUsd) * 1e24, //uint256
                initialCollateralDeltaAmount: 0, //uint256
                triggerPrice: 0, //uint256
                acceptablePrice: price * 99999 / 100000, //uint256
                executionFee: gasLimit, //uint256 // tx.gasprice * GasUtils.adjustGasLimitForEstimate(datastore, GasUtils.estimateExecuteOrderGasLimit)
                callbackGasLimit: 0, //uint256
                minOutputAmount: 0//uint256
            }),
            orderType: uint8(OrderType.MarketIncrease), // uint8
            decreasePositionSwapType: uint8(DecreasePositionSwapType.NoSwap),// uint8
            isLong: false, // bool
            shouldUnwrapNativeToken: true, // bool
            referralCode: bytes32(0) // bytes32
        }));
    }

    /* 
    get this from the datastore
    increaseOrder: {
        methodName: "getUint",
        params: [increaseOrderGasLimitKey()],
    },
        decreaseOrder: {
        methodName: "getUint",
        params: [decreaseOrderGasLimitKey()],
    },
    */

    // Withdraws tokens from the strategy.
    function exit(uint256) public payable onlyOwner returns(uint256) {

    }

    // Swaps through the uniswap 500bp pool of the two tokens.
    function _swap(address tokenIn, address tokenOut, address recipient, uint256 amountIn, uint256 minAmountOut) internal returns (uint256 amountOut) {
        return uniswapRouter.exactInputSingle(
            IUniSwapRouter.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 500,
                recipient: recipient,
                amountIn: amountIn,
                amountOutMinimum: minAmountOut,
                sqrtPriceLimitX96: 0
            })
        );
    }

    function getFunding() external view returns (bool longsPayShorts, int256 longFunding, int256 shortFunding) {
        address longToken = address(strategyToken); // WETH
        address shortToken = address(token); // USDC
        int256 fundingFactor = dataStore.getInt(Keys.savedFundingFactorPerSecondKey(market));
        uint256 longInterestUsingLongToken = dataStore.getUint(Keys.openInterestKey(market, longToken, true));
        uint256 longInterestUsingShortToken = dataStore.getUint(Keys.openInterestKey(market, shortToken, true));
        uint256 shortInterestUsingLongToken = dataStore.getUint(Keys.openInterestKey(market, longToken, false));
        uint256 shortInterestUsingShortToken = dataStore.getUint(Keys.openInterestKey(market, shortToken, false));
        uint256 longInterestUsd = longInterestUsingLongToken + longInterestUsingShortToken;
        uint256 shortInterestUsd = shortInterestUsingLongToken + shortInterestUsingShortToken;
        longsPayShorts = fundingFactor > 0;
        int256 factorPerHourA = -fundingFactor * 1 hours;
        uint256 ratio = shortInterestUsd < longInterestUsd ? (shortInterestUsd * PRECISION / longInterestUsd) : (longInterestUsd * PRECISION / shortInterestUsd);
        int256 factorPerHourB = (int256(ratio) * fundingFactor / int256(PRECISION)) * int256(1 hours);
        if (longsPayShorts) {
            longFunding = factorPerHourA / 1e20;
            shortFunding = factorPerHourB / 1e20;
        } else {
            longFunding = factorPerHourB / 1e20;
            shortFunding = factorPerHourA / 1e20;
        }
    }

    function execute(address to, bytes calldata data) external payable virtual onlyOwner returns (bytes memory returnData) {
        bool success;
        (success, returnData) = to.call{value: msg.value}(data);
        if (!success) {
            assembly {
                revert(add(returnData, 32), mload(returnData))
            }
        }
    }
}

/* 
Deployments: https://github.com/gmx-io/gmx-synthetics/blob/main/deployments/arbitrum
Data store: 0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8
Reader: 0x60a0fF4cDaF0f6D496d71e0bC0fFa86FE8E6B23c

executionFee = tx.gasprice * GasUtils.adjustGasLimitForEstimate(datastore, estimatedGasLimit)

For deposits: GasUtils.estimateExecuteDepositGasLimit
For orders: GasUtils.estimateExecuteOrderGasLimit
For withdrawals: GasUtils.estimateExecuteWithdrawalGasLimit
 */

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(4, from) // Append the "from" argument.
            mstore(36, to) // Append the "to" argument.
            mstore(68, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because that's the total length of our calldata (4 + 32 * 3)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 100, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(4, to) // Append the "to" argument.
            mstore(36, amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because that's the total length of our calldata (4 + 32 * 2)
                // Counterintuitively, this call() must be positioned after the or() in the
                // surrounding and() because and() evaluates its arguments from right to left.
                call(gas(), token, 0, 0, 68, 0, 32)
            )

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface IStrategy {
    // Returns the token the strategy accepts.
    function token() external view returns (ERC20);
    // Returns the total NAV (net asset value) of the strategy in token() units.
    function totalValue() external view returns (uint256);
    // Deployes the tokens in the strategy.
    function enter() external payable;
    // Withdraws tokens from the strategy.
    function exit(uint256 amount) external payable returns (uint256 withdrawn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8;

interface IUniSwapRouter {
    
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct IncreaseLiquidityParams {
        address token0;
        address token1;
        uint256 tokenId;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
    }

    function WETH9() external view returns (address);

    function approveMax(address token) external payable;

    function approveMaxMinusOne(address token) external payable;

    function approveZeroThenMax(address token) external payable;

    function approveZeroThenMaxMinusOne(address token) external payable;

    function callPositionManager(bytes memory data)
        external
        payable
        returns (bytes memory result);

    function checkOracleSlippage(
        bytes[] memory paths,
        uint128[] memory amounts,
        uint24 maximumTickDivergence,
        uint32 secondsAgo
    ) external view;

    function checkOracleSlippage(
        bytes memory path,
        uint24 maximumTickDivergence,
        uint32 secondsAgo
    ) external view;

    function exactInput(ExactInputParams memory params)
        external
        payable
        returns (uint256 amountOut);

    function exactInputSingle(
        ExactInputSingleParams memory params
    ) external payable returns (uint256 amountOut);

    function exactOutput(ExactOutputParams memory params)
        external
        payable
        returns (uint256 amountIn);

    function exactOutputSingle(
        ExactOutputSingleParams memory params
    ) external payable returns (uint256 amountIn);

    function factory() external view returns (address);

    function factoryV2() external view returns (address);

    function getApprovalType(address token, uint256 amount)
        external
        returns (uint8);

    function increaseLiquidity(
        IncreaseLiquidityParams memory params
    ) external payable returns (bytes memory result);

    function mint(MintParams memory params)
        external
        payable
        returns (bytes memory result);

    function multicall(bytes32 previousBlockhash, bytes[] memory data)
        external
        payable
        returns (bytes[] memory);

    function multicall(uint256 deadline, bytes[] memory data)
        external
        payable
        returns (bytes[] memory);

    function multicall(bytes[] memory data)
        external
        payable
        returns (bytes[] memory results);

    function positionManager() external view returns (address);

    function pull(address token, uint256 value) external payable;

    function refundETH() external payable;

    function selfPermit(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowed(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitAllowedIfNecessary(
        address token,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function selfPermitIfNecessary(
        address token,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) external payable returns (uint256 amountOut);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] memory path,
        address to
    ) external payable returns (uint256 amountIn);

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;

    function sweepToken(address token, uint256 amountMinimum) external payable;

    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    function sweepTokenWithFee(
        address token,
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes memory _data
    ) external;

    function unwrapWETH9(uint256 amountMinimum, address recipient)
        external
        payable;

    function unwrapWETH9(uint256 amountMinimum) external payable;

    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        address recipient,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    function unwrapWETH9WithFee(
        uint256 amountMinimum,
        uint256 feeBips,
        address feeRecipient
    ) external payable;

    function wrapETH(uint256 value) external payable;

    //receive() external payable;
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.20;

interface IGmxDataStore {
    error Unauthorized(address msgSender, string role);

    function addAddress(bytes32 setKey, address value) external;

    function addBytes32(bytes32 setKey, bytes32 value) external;

    function addUint(bytes32 setKey, uint256 value) external;

    function addressArrayValues(bytes32, uint256)
        external
        view
        returns (address);

    function addressValues(bytes32) external view returns (address);

    function applyBoundedDeltaToUint(bytes32 key, int256 value)
        external
        returns (uint256);

    function applyDeltaToInt(bytes32 key, int256 value)
        external
        returns (int256);

    function applyDeltaToUint(
        bytes32 key,
        int256 value,
        string memory errorMessage
    ) external returns (uint256);

    function applyDeltaToUint(bytes32 key, uint256 value)
        external
        returns (uint256);

    function boolArrayValues(bytes32, uint256) external view returns (bool);

    function boolValues(bytes32) external view returns (bool);

    function bytes32ArrayValues(bytes32, uint256)
        external
        view
        returns (bytes32);

    function bytes32Values(bytes32) external view returns (bytes32);

    function containsAddress(bytes32 setKey, address value)
        external
        view
        returns (bool);

    function containsBytes32(bytes32 setKey, bytes32 value)
        external
        view
        returns (bool);

    function containsUint(bytes32 setKey, uint256 value)
        external
        view
        returns (bool);

    function decrementInt(bytes32 key, int256 value) external returns (int256);

    function decrementUint(bytes32 key, uint256 value)
        external
        returns (uint256);

    function getAddress(bytes32 key) external view returns (address);

    function getAddressArray(bytes32 key)
        external
        view
        returns (address[] memory);

    function getAddressCount(bytes32 setKey) external view returns (uint256);

    function getAddressValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (address[] memory);

    function getBool(bytes32 key) external view returns (bool);

    function getBoolArray(bytes32 key) external view returns (bool[] memory);

    function getBytes32(bytes32 key) external view returns (bytes32);

    function getBytes32Array(bytes32 key)
        external
        view
        returns (bytes32[] memory);

    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    function getBytes32ValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory);

    function getInt(bytes32 key) external view returns (int256);

    function getIntArray(bytes32 key) external view returns (int256[] memory);

    function getString(bytes32 key) external view returns (string memory);

    function getStringArray(bytes32 key)
        external
        view
        returns (string[] memory);

    function getUint(bytes32 key) external view returns (uint256);

    function getUintArray(bytes32 key) external view returns (uint256[] memory);

    function getUintCount(bytes32 setKey) external view returns (uint256);

    function getUintValuesAt(
        bytes32 setKey,
        uint256 start,
        uint256 end
    ) external view returns (uint256[] memory);

    function incrementInt(bytes32 key, int256 value) external returns (int256);

    function incrementUint(bytes32 key, uint256 value)
        external
        returns (uint256);

    function intArrayValues(bytes32, uint256) external view returns (int256);

    function intValues(bytes32) external view returns (int256);

    function removeAddress(bytes32 setKey, address value) external;

    function removeAddress(bytes32 key) external;

    function removeAddressArray(bytes32 key) external;

    function removeBool(bytes32 key) external;

    function removeBoolArray(bytes32 key) external;

    function removeBytes32(bytes32 setKey, bytes32 value) external;

    function removeBytes32(bytes32 key) external;

    function removeBytes32Array(bytes32 key) external;

    function removeInt(bytes32 key) external;

    function removeIntArray(bytes32 key) external;

    function removeString(bytes32 key) external;

    function removeStringArray(bytes32 key) external;

    function removeUint(bytes32 key) external;

    function removeUint(bytes32 setKey, uint256 value) external;

    function removeUintArray(bytes32 key) external;

    function roleStore() external view returns (address);

    function setAddress(bytes32 key, address value) external returns (address);

    function setAddressArray(bytes32 key, address[] memory value) external;

    function setBool(bytes32 key, bool value) external returns (bool);

    function setBoolArray(bytes32 key, bool[] memory value) external;

    function setBytes32(bytes32 key, bytes32 value) external returns (bytes32);

    function setBytes32Array(bytes32 key, bytes32[] memory value) external;

    function setInt(bytes32 key, int256 value) external returns (int256);

    function setIntArray(bytes32 key, int256[] memory value) external;

    function setString(bytes32 key, string memory value)
        external
        returns (string memory);

    function setStringArray(bytes32 key, string[] memory value) external;

    function setUint(bytes32 key, uint256 value) external returns (uint256);

    function setUintArray(bytes32 key, uint256[] memory value) external;

    function stringArrayValues(bytes32, uint256)
        external
        view
        returns (string memory);

    function stringValues(bytes32) external view returns (string memory);

    function uintArrayValues(bytes32, uint256) external view returns (uint256);

    function uintValues(bytes32) external view returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"contract RoleStore","name":"_roleStore","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"address","name":"msgSender","type":"address"},{"internalType":"string","name":"role","type":"string"}],"name":"Unauthorized","type":"error"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"address","name":"value","type":"address"}],"name":"addAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"addBytes32","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"addUint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"addressArrayValues","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"addressValues","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"int256","name":"value","type":"int256"}],"name":"applyBoundedDeltaToUint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"int256","name":"value","type":"int256"}],"name":"applyDeltaToInt","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"int256","name":"value","type":"int256"},{"internalType":"string","name":"errorMessage","type":"string"}],"name":"applyDeltaToUint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"applyDeltaToUint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"boolArrayValues","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"boolValues","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"bytes32ArrayValues","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"bytes32Values","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"address","name":"value","type":"address"}],"name":"containsAddress","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"containsBytes32","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"containsUint","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"int256","name":"value","type":"int256"}],"name":"decrementInt","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"decrementUint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getAddressArray","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"}],"name":"getAddressCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"uint256","name":"start","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"}],"name":"getAddressValuesAt","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getBool","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getBoolArray","outputs":[{"internalType":"bool[]","name":"","type":"bool[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getBytes32","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getBytes32Array","outputs":[{"internalType":"bytes32[]","name":"","type":"bytes32[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"}],"name":"getBytes32Count","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"uint256","name":"start","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"}],"name":"getBytes32ValuesAt","outputs":[{"internalType":"bytes32[]","name":"","type":"bytes32[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getInt","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getIntArray","outputs":[{"internalType":"int256[]","name":"","type":"int256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getString","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getStringArray","outputs":[{"internalType":"string[]","name":"","type":"string[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getUint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getUintArray","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"}],"name":"getUintCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"uint256","name":"start","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"}],"name":"getUintValuesAt","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"int256","name":"value","type":"int256"}],"name":"incrementInt","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"incrementUint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"intArrayValues","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"intValues","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"address","name":"value","type":"address"}],"name":"removeAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeAddress","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeAddressArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeBool","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeBoolArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"removeBytes32","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeBytes32","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeBytes32Array","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeInt","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeIntArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeString","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeStringArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeUint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"setKey","type":"bytes32"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"removeUint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"removeUintArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"roleStore","outputs":[{"internalType":"contract RoleStore","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"address","name":"value","type":"address"}],"name":"setAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"address[]","name":"value","type":"address[]"}],"name":"setAddressArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"bool","name":"value","type":"bool"}],"name":"setBool","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"bool[]","name":"value","type":"bool[]"}],"name":"setBoolArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"bytes32","name":"value","type":"bytes32"}],"name":"setBytes32","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"bytes32[]","name":"value","type":"bytes32[]"}],"name":"setBytes32Array","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"int256","name":"value","type":"int256"}],"name":"setInt","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"int256[]","name":"value","type":"int256[]"}],"name":"setIntArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"string","name":"value","type":"string"}],"name":"setString","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"string[]","name":"value","type":"string[]"}],"name":"setStringArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"uint256","name":"value","type":"uint256"}],"name":"setUint","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"uint256[]","name":"value","type":"uint256[]"}],"name":"setUintArray","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"stringArrayValues","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"stringValues","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"uintArrayValues","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"uintValues","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.20;

interface IGmxReader {
    error DisabledMarket(address market);
    error EmptyMarket();

    function getAccountOrders(
        address dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (Order.Props[] memory);

    function getAccountPositionInfoList(
        address dataStore,
        address referralStorage,
        bytes32[] memory positionKeys,
        MarketUtils.MarketPrices[] memory prices,
        address uiFeeReceiver
    ) external view returns (ReaderUtils.PositionInfo[] memory);

    function getAccountPositions(
        address dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (Position.Props[] memory);

    function getAdlState(
        address dataStore,
        address market,
        bool isLong,
        MarketUtils.MarketPrices memory prices
    )
        external
        view
        returns (
            uint256,
            bool,
            int256,
            uint256
        );

    function getDeposit(address dataStore, bytes32 key)
        external
        view
        returns (Deposit.Props memory);

    function getDepositAmountOut(
        address dataStore,
        Market.Props memory market,
        MarketUtils.MarketPrices memory prices,
        uint256 longTokenAmount,
        uint256 shortTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256);

    function getExecutionPrice(
        address dataStore,
        address marketKey,
        Price.Props memory indexTokenPrice,
        uint256 positionSizeInUsd,
        uint256 positionSizeInTokens,
        int256 sizeDeltaUsd,
        bool isLong
    ) external view returns (ReaderPricingUtils.ExecutionPriceResult memory);

    function getMarket(address dataStore, address key)
        external
        view
        returns (Market.Props memory);

    function getMarketBySalt(address dataStore, bytes32 salt)
        external
        view
        returns (Market.Props memory);

    function getMarketInfo(
        address dataStore,
        MarketUtils.MarketPrices memory prices,
        address marketKey
    ) external view returns (ReaderUtils.MarketInfo memory);

    function getMarketInfoList(
        address dataStore,
        MarketUtils.MarketPrices[] memory marketPricesList,
        uint256 start,
        uint256 end
    ) external view returns (ReaderUtils.MarketInfo[] memory);

    function getMarketTokenPrice(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        Price.Props memory longTokenPrice,
        Price.Props memory shortTokenPrice,
        bytes32 pnlFactorType,
        bool maximize
    ) external view returns (int256, MarketPoolValueInfo.Props memory);

    function getMarkets(
        address dataStore,
        uint256 start,
        uint256 end
    ) external view returns (Market.Props[] memory);

    function getNetPnl(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool maximize
    ) external view returns (int256);

    function getOpenInterestWithPnl(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getOrder(address dataStore, bytes32 key)
        external
        view
        returns (Order.Props memory);

    function getPnl(
        address dataStore,
        Market.Props memory market,
        Price.Props memory indexTokenPrice,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getPnlToPoolFactor(
        address dataStore,
        address marketAddress,
        MarketUtils.MarketPrices memory prices,
        bool isLong,
        bool maximize
    ) external view returns (int256);

    function getPosition(address dataStore, bytes32 key)
        external
        view
        returns (Position.Props memory);

    function getPositionInfo(
        address dataStore,
        address referralStorage,
        bytes32 positionKey,
        MarketUtils.MarketPrices memory prices,
        uint256 sizeDeltaUsd,
        address uiFeeReceiver,
        bool usePositionSizeAsSizeDeltaUsd
    ) external view returns (ReaderUtils.PositionInfo memory);

    function getPositionPnlUsd(
        address dataStore,
        Market.Props memory market,
        MarketUtils.MarketPrices memory prices,
        bytes32 positionKey,
        uint256 sizeDeltaUsd
    )
        external
        view
        returns (
            int256,
            int256,
            uint256
        );

    function getSwapAmountOut(
        address dataStore,
        Market.Props memory market,
        MarketUtils.MarketPrices memory prices,
        address tokenIn,
        uint256 amountIn,
        address uiFeeReceiver
    )
        external
        view
        returns (
            uint256,
            int256,
            SwapPricingUtils.SwapFees memory fees
        );

    function getSwapPriceImpact(
        address dataStore,
        address marketKey,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        Price.Props memory tokenInPrice,
        Price.Props memory tokenOutPrice
    ) external view returns (int256, int256);

    function getWithdrawal(address dataStore, bytes32 key)
        external
        view
        returns (Withdrawal.Props memory);

    function getWithdrawalAmountOut(
        address dataStore,
        Market.Props memory market,
        MarketUtils.MarketPrices memory prices,
        uint256 marketTokenAmount,
        address uiFeeReceiver
    ) external view returns (uint256, uint256);
}

interface Order {
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct Numbers {
        uint8 orderType;
        uint8 decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }
}

interface Price {
    struct Props {
        uint256 min;
        uint256 max;
    }
}

interface MarketUtils {
    struct MarketPrices {
        Price.Props indexTokenPrice;
        Price.Props longTokenPrice;
        Price.Props shortTokenPrice;
    }

    struct CollateralType {
        uint256 longToken;
        uint256 shortToken;
    }

    struct PositionType {
        CollateralType long;
        CollateralType short;
    }

    struct GetNextFundingAmountPerSizeResult {
        bool longsPayShorts;
        uint256 fundingFactorPerSecond;
        int256 nextSavedFundingFactorPerSecond;
        PositionType fundingFeeAmountPerSizeDelta;
        PositionType claimableFundingAmountPerSizeDelta;
    }
}

interface Position {
    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }

    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    struct Flags {
        bool isLong;
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }
}

interface PositionPricingUtils {
    struct PositionReferralFees {
        bytes32 referralCode;
        address affiliate;
        address trader;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
    }

    struct PositionFundingFees {
        uint256 fundingFeeAmount;
        uint256 claimableLongTokenAmount;
        uint256 claimableShortTokenAmount;
        uint256 latestFundingFeeAmountPerSize;
        uint256 latestLongTokenClaimableFundingAmountPerSize;
        uint256 latestShortTokenClaimableFundingAmountPerSize;
    }

    struct PositionBorrowingFees {
        uint256 borrowingFeeUsd;
        uint256 borrowingFeeAmount;
        uint256 borrowingFeeReceiverFactor;
        uint256 borrowingFeeAmountForFeeReceiver;
    }

    struct PositionUiFees {
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }

    struct PositionFees {
        PositionReferralFees referral;
        PositionFundingFees funding;
        PositionBorrowingFees borrowing;
        PositionUiFees ui;
        Price.Props collateralTokenPrice;
        uint256 positionFeeFactor;
        uint256 protocolFeeAmount;
        uint256 positionFeeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 totalCostAmountExcludingFunding;
        uint256 totalCostAmount;
    }
}

interface ReaderPricingUtils {
    struct ExecutionPriceResult {
        int256 priceImpactUsd;
        uint256 priceImpactDiffUsd;
        uint256 executionPrice;
    }
}

interface ReaderUtils {
    struct PositionInfo {
        Position.Props position;
        PositionPricingUtils.PositionFees fees;
        ReaderPricingUtils.ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 uncappedBasePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    struct BaseFundingValues {
        MarketUtils.PositionType fundingFeeAmountPerSize;
        MarketUtils.PositionType claimableFundingAmountPerSize;
    }

    struct VirtualInventory {
        uint256 virtualPoolAmountForLongToken;
        uint256 virtualPoolAmountForShortToken;
        int256 virtualInventoryForPositions;
    }

    struct MarketInfo {
        Market.Props market;
        uint256 borrowingFactorPerSecondForLongs;
        uint256 borrowingFactorPerSecondForShorts;
        BaseFundingValues baseFunding;
        MarketUtils.GetNextFundingAmountPerSizeResult nextFunding;
        VirtualInventory virtualInventory;
        bool isDisabled;
    }
}

interface Deposit {
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct Numbers {
        uint256 initialLongTokenAmount;
        uint256 initialShortTokenAmount;
        uint256 minMarketTokens;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct Flags {
        bool shouldUnwrapNativeToken;
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }
}

interface Market {
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }
}

interface MarketPoolValueInfo {
    struct Props {
        int256 poolValue;
        int256 longPnl;
        int256 shortPnl;
        int256 netPnl;
        uint256 longTokenAmount;
        uint256 shortTokenAmount;
        uint256 longTokenUsd;
        uint256 shortTokenUsd;
        uint256 totalBorrowingFees;
        uint256 borrowingFeePoolFactor;
        uint256 impactPoolAmount;
    }
}

interface SwapPricingUtils {
    struct SwapFees {
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 amountAfterFees;
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }
}

interface Withdrawal {
    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
    }

    struct Numbers {
        uint256 marketTokenAmount;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        uint256 updatedAtBlock;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }

    struct Flags {
        bool shouldUnwrapNativeToken;
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"market","type":"address"}],"name":"DisabledMarket","type":"error"},{"inputs":[],"name":"EmptyMarket","type":"error"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"start","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"}],"name":"getAccountOrders","outputs":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"initialCollateralToken","type":"address"},{"internalType":"address[]","name":"swapPath","type":"address[]"}],"internalType":"struct Order.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"enum Order.OrderType","name":"orderType","type":"uint8"},{"internalType":"enum Order.DecreasePositionSwapType","name":"decreasePositionSwapType","type":"uint8"},{"internalType":"uint256","name":"sizeDeltaUsd","type":"uint256"},{"internalType":"uint256","name":"initialCollateralDeltaAmount","type":"uint256"},{"internalType":"uint256","name":"triggerPrice","type":"uint256"},{"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"callbackGasLimit","type":"uint256"},{"internalType":"uint256","name":"minOutputAmount","type":"uint256"},{"internalType":"uint256","name":"updatedAtBlock","type":"uint256"}],"internalType":"struct Order.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"bool","name":"shouldUnwrapNativeToken","type":"bool"},{"internalType":"bool","name":"isFrozen","type":"bool"}],"internalType":"struct Order.Flags","name":"flags","type":"tuple"}],"internalType":"struct Order.Props[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"contract IReferralStorage","name":"referralStorage","type":"address"},{"internalType":"bytes32[]","name":"positionKeys","type":"bytes32[]"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices[]","name":"prices","type":"tuple[]"},{"internalType":"address","name":"uiFeeReceiver","type":"address"}],"name":"getAccountPositionInfoList","outputs":[{"components":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"collateralToken","type":"address"}],"internalType":"struct Position.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"uint256","name":"sizeInUsd","type":"uint256"},{"internalType":"uint256","name":"sizeInTokens","type":"uint256"},{"internalType":"uint256","name":"collateralAmount","type":"uint256"},{"internalType":"uint256","name":"borrowingFactor","type":"uint256"},{"internalType":"uint256","name":"fundingFeeAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"longTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"shortTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"increasedAtBlock","type":"uint256"},{"internalType":"uint256","name":"decreasedAtBlock","type":"uint256"}],"internalType":"struct Position.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"isLong","type":"bool"}],"internalType":"struct Position.Flags","name":"flags","type":"tuple"}],"internalType":"struct Position.Props","name":"position","type":"tuple"},{"components":[{"components":[{"internalType":"bytes32","name":"referralCode","type":"bytes32"},{"internalType":"address","name":"affiliate","type":"address"},{"internalType":"address","name":"trader","type":"address"},{"internalType":"uint256","name":"totalRebateFactor","type":"uint256"},{"internalType":"uint256","name":"traderDiscountFactor","type":"uint256"},{"internalType":"uint256","name":"totalRebateAmount","type":"uint256"},{"internalType":"uint256","name":"traderDiscountAmount","type":"uint256"},{"internalType":"uint256","name":"affiliateRewardAmount","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionReferralFees","name":"referral","type":"tuple"},{"components":[{"internalType":"uint256","name":"fundingFeeAmount","type":"uint256"},{"internalType":"uint256","name":"claimableLongTokenAmount","type":"uint256"},{"internalType":"uint256","name":"claimableShortTokenAmount","type":"uint256"},{"internalType":"uint256","name":"latestFundingFeeAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"latestLongTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"latestShortTokenClaimableFundingAmountPerSize","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionFundingFees","name":"funding","type":"tuple"},{"components":[{"internalType":"uint256","name":"borrowingFeeUsd","type":"uint256"},{"internalType":"uint256","name":"borrowingFeeAmount","type":"uint256"},{"internalType":"uint256","name":"borrowingFeeReceiverFactor","type":"uint256"},{"internalType":"uint256","name":"borrowingFeeAmountForFeeReceiver","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionBorrowingFees","name":"borrowing","type":"tuple"},{"components":[{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"uint256","name":"uiFeeReceiverFactor","type":"uint256"},{"internalType":"uint256","name":"uiFeeAmount","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionUiFees","name":"ui","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"collateralTokenPrice","type":"tuple"},{"internalType":"uint256","name":"positionFeeFactor","type":"uint256"},{"internalType":"uint256","name":"protocolFeeAmount","type":"uint256"},{"internalType":"uint256","name":"positionFeeReceiverFactor","type":"uint256"},{"internalType":"uint256","name":"feeReceiverAmount","type":"uint256"},{"internalType":"uint256","name":"feeAmountForPool","type":"uint256"},{"internalType":"uint256","name":"positionFeeAmountForPool","type":"uint256"},{"internalType":"uint256","name":"positionFeeAmount","type":"uint256"},{"internalType":"uint256","name":"totalCostAmountExcludingFunding","type":"uint256"},{"internalType":"uint256","name":"totalCostAmount","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionFees","name":"fees","type":"tuple"},{"components":[{"internalType":"int256","name":"priceImpactUsd","type":"int256"},{"internalType":"uint256","name":"priceImpactDiffUsd","type":"uint256"},{"internalType":"uint256","name":"executionPrice","type":"uint256"}],"internalType":"struct ReaderPricingUtils.ExecutionPriceResult","name":"executionPriceResult","type":"tuple"},{"internalType":"int256","name":"basePnlUsd","type":"int256"},{"internalType":"int256","name":"uncappedBasePnlUsd","type":"int256"},{"internalType":"int256","name":"pnlAfterPriceImpactUsd","type":"int256"}],"internalType":"struct ReaderUtils.PositionInfo[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"start","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"}],"name":"getAccountPositions","outputs":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"collateralToken","type":"address"}],"internalType":"struct Position.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"uint256","name":"sizeInUsd","type":"uint256"},{"internalType":"uint256","name":"sizeInTokens","type":"uint256"},{"internalType":"uint256","name":"collateralAmount","type":"uint256"},{"internalType":"uint256","name":"borrowingFactor","type":"uint256"},{"internalType":"uint256","name":"fundingFeeAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"longTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"shortTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"increasedAtBlock","type":"uint256"},{"internalType":"uint256","name":"decreasedAtBlock","type":"uint256"}],"internalType":"struct Position.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"isLong","type":"bool"}],"internalType":"struct Position.Flags","name":"flags","type":"tuple"}],"internalType":"struct Position.Props[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"bool","name":"isLong","type":"bool"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"}],"name":"getAdlState","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"bool","name":"","type":"bool"},{"internalType":"int256","name":"","type":"int256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getDeposit","outputs":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"initialLongToken","type":"address"},{"internalType":"address","name":"initialShortToken","type":"address"},{"internalType":"address[]","name":"longTokenSwapPath","type":"address[]"},{"internalType":"address[]","name":"shortTokenSwapPath","type":"address[]"}],"internalType":"struct Deposit.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"uint256","name":"initialLongTokenAmount","type":"uint256"},{"internalType":"uint256","name":"initialShortTokenAmount","type":"uint256"},{"internalType":"uint256","name":"minMarketTokens","type":"uint256"},{"internalType":"uint256","name":"updatedAtBlock","type":"uint256"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"callbackGasLimit","type":"uint256"}],"internalType":"struct Deposit.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"shouldUnwrapNativeToken","type":"bool"}],"internalType":"struct Deposit.Flags","name":"flags","type":"tuple"}],"internalType":"struct Deposit.Props","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"},{"internalType":"uint256","name":"longTokenAmount","type":"uint256"},{"internalType":"uint256","name":"shortTokenAmount","type":"uint256"},{"internalType":"address","name":"uiFeeReceiver","type":"address"}],"name":"getDepositAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"address","name":"marketKey","type":"address"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"internalType":"uint256","name":"positionSizeInUsd","type":"uint256"},{"internalType":"uint256","name":"positionSizeInTokens","type":"uint256"},{"internalType":"int256","name":"sizeDeltaUsd","type":"int256"},{"internalType":"bool","name":"isLong","type":"bool"}],"name":"getExecutionPrice","outputs":[{"components":[{"internalType":"int256","name":"priceImpactUsd","type":"int256"},{"internalType":"uint256","name":"priceImpactDiffUsd","type":"uint256"},{"internalType":"uint256","name":"executionPrice","type":"uint256"}],"internalType":"struct ReaderPricingUtils.ExecutionPriceResult","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"address","name":"key","type":"address"}],"name":"getMarket","outputs":[{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"bytes32","name":"salt","type":"bytes32"}],"name":"getMarketBySalt","outputs":[{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"},{"internalType":"address","name":"marketKey","type":"address"}],"name":"getMarketInfo","outputs":[{"components":[{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"internalType":"uint256","name":"borrowingFactorPerSecondForLongs","type":"uint256"},{"internalType":"uint256","name":"borrowingFactorPerSecondForShorts","type":"uint256"},{"components":[{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"fundingFeeAmountPerSize","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"claimableFundingAmountPerSize","type":"tuple"}],"internalType":"struct ReaderUtils.BaseFundingValues","name":"baseFunding","type":"tuple"},{"components":[{"internalType":"bool","name":"longsPayShorts","type":"bool"},{"internalType":"uint256","name":"fundingFactorPerSecond","type":"uint256"},{"internalType":"int256","name":"nextSavedFundingFactorPerSecond","type":"int256"},{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"fundingFeeAmountPerSizeDelta","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"claimableFundingAmountPerSizeDelta","type":"tuple"}],"internalType":"struct MarketUtils.GetNextFundingAmountPerSizeResult","name":"nextFunding","type":"tuple"},{"components":[{"internalType":"uint256","name":"virtualPoolAmountForLongToken","type":"uint256"},{"internalType":"uint256","name":"virtualPoolAmountForShortToken","type":"uint256"},{"internalType":"int256","name":"virtualInventoryForPositions","type":"int256"}],"internalType":"struct ReaderUtils.VirtualInventory","name":"virtualInventory","type":"tuple"},{"internalType":"bool","name":"isDisabled","type":"bool"}],"internalType":"struct ReaderUtils.MarketInfo","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices[]","name":"marketPricesList","type":"tuple[]"},{"internalType":"uint256","name":"start","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"}],"name":"getMarketInfoList","outputs":[{"components":[{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"internalType":"uint256","name":"borrowingFactorPerSecondForLongs","type":"uint256"},{"internalType":"uint256","name":"borrowingFactorPerSecondForShorts","type":"uint256"},{"components":[{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"fundingFeeAmountPerSize","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"claimableFundingAmountPerSize","type":"tuple"}],"internalType":"struct ReaderUtils.BaseFundingValues","name":"baseFunding","type":"tuple"},{"components":[{"internalType":"bool","name":"longsPayShorts","type":"bool"},{"internalType":"uint256","name":"fundingFactorPerSecond","type":"uint256"},{"internalType":"int256","name":"nextSavedFundingFactorPerSecond","type":"int256"},{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"fundingFeeAmountPerSizeDelta","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"long","type":"tuple"},{"components":[{"internalType":"uint256","name":"longToken","type":"uint256"},{"internalType":"uint256","name":"shortToken","type":"uint256"}],"internalType":"struct MarketUtils.CollateralType","name":"short","type":"tuple"}],"internalType":"struct MarketUtils.PositionType","name":"claimableFundingAmountPerSizeDelta","type":"tuple"}],"internalType":"struct MarketUtils.GetNextFundingAmountPerSizeResult","name":"nextFunding","type":"tuple"},{"components":[{"internalType":"uint256","name":"virtualPoolAmountForLongToken","type":"uint256"},{"internalType":"uint256","name":"virtualPoolAmountForShortToken","type":"uint256"},{"internalType":"int256","name":"virtualInventoryForPositions","type":"int256"}],"internalType":"struct ReaderUtils.VirtualInventory","name":"virtualInventory","type":"tuple"},{"internalType":"bool","name":"isDisabled","type":"bool"}],"internalType":"struct ReaderUtils.MarketInfo[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"},{"internalType":"bytes32","name":"pnlFactorType","type":"bytes32"},{"internalType":"bool","name":"maximize","type":"bool"}],"name":"getMarketTokenPrice","outputs":[{"internalType":"int256","name":"","type":"int256"},{"components":[{"internalType":"int256","name":"poolValue","type":"int256"},{"internalType":"int256","name":"longPnl","type":"int256"},{"internalType":"int256","name":"shortPnl","type":"int256"},{"internalType":"int256","name":"netPnl","type":"int256"},{"internalType":"uint256","name":"longTokenAmount","type":"uint256"},{"internalType":"uint256","name":"shortTokenAmount","type":"uint256"},{"internalType":"uint256","name":"longTokenUsd","type":"uint256"},{"internalType":"uint256","name":"shortTokenUsd","type":"uint256"},{"internalType":"uint256","name":"totalBorrowingFees","type":"uint256"},{"internalType":"uint256","name":"borrowingFeePoolFactor","type":"uint256"},{"internalType":"uint256","name":"impactPoolAmount","type":"uint256"}],"internalType":"struct MarketPoolValueInfo.Props","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"uint256","name":"start","type":"uint256"},{"internalType":"uint256","name":"end","type":"uint256"}],"name":"getMarkets","outputs":[{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"internalType":"bool","name":"maximize","type":"bool"}],"name":"getNetPnl","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"bool","name":"maximize","type":"bool"}],"name":"getOpenInterestWithPnl","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getOrder","outputs":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"initialCollateralToken","type":"address"},{"internalType":"address[]","name":"swapPath","type":"address[]"}],"internalType":"struct Order.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"enum Order.OrderType","name":"orderType","type":"uint8"},{"internalType":"enum Order.DecreasePositionSwapType","name":"decreasePositionSwapType","type":"uint8"},{"internalType":"uint256","name":"sizeDeltaUsd","type":"uint256"},{"internalType":"uint256","name":"initialCollateralDeltaAmount","type":"uint256"},{"internalType":"uint256","name":"triggerPrice","type":"uint256"},{"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"callbackGasLimit","type":"uint256"},{"internalType":"uint256","name":"minOutputAmount","type":"uint256"},{"internalType":"uint256","name":"updatedAtBlock","type":"uint256"}],"internalType":"struct Order.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"bool","name":"shouldUnwrapNativeToken","type":"bool"},{"internalType":"bool","name":"isFrozen","type":"bool"}],"internalType":"struct Order.Flags","name":"flags","type":"tuple"}],"internalType":"struct Order.Props","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"bool","name":"maximize","type":"bool"}],"name":"getPnl","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"address","name":"marketAddress","type":"address"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"},{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"bool","name":"maximize","type":"bool"}],"name":"getPnlToPoolFactor","outputs":[{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getPosition","outputs":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"collateralToken","type":"address"}],"internalType":"struct Position.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"uint256","name":"sizeInUsd","type":"uint256"},{"internalType":"uint256","name":"sizeInTokens","type":"uint256"},{"internalType":"uint256","name":"collateralAmount","type":"uint256"},{"internalType":"uint256","name":"borrowingFactor","type":"uint256"},{"internalType":"uint256","name":"fundingFeeAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"longTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"shortTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"increasedAtBlock","type":"uint256"},{"internalType":"uint256","name":"decreasedAtBlock","type":"uint256"}],"internalType":"struct Position.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"isLong","type":"bool"}],"internalType":"struct Position.Flags","name":"flags","type":"tuple"}],"internalType":"struct Position.Props","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"contract IReferralStorage","name":"referralStorage","type":"address"},{"internalType":"bytes32","name":"positionKey","type":"bytes32"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"},{"internalType":"uint256","name":"sizeDeltaUsd","type":"uint256"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"bool","name":"usePositionSizeAsSizeDeltaUsd","type":"bool"}],"name":"getPositionInfo","outputs":[{"components":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"collateralToken","type":"address"}],"internalType":"struct Position.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"uint256","name":"sizeInUsd","type":"uint256"},{"internalType":"uint256","name":"sizeInTokens","type":"uint256"},{"internalType":"uint256","name":"collateralAmount","type":"uint256"},{"internalType":"uint256","name":"borrowingFactor","type":"uint256"},{"internalType":"uint256","name":"fundingFeeAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"longTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"shortTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"increasedAtBlock","type":"uint256"},{"internalType":"uint256","name":"decreasedAtBlock","type":"uint256"}],"internalType":"struct Position.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"isLong","type":"bool"}],"internalType":"struct Position.Flags","name":"flags","type":"tuple"}],"internalType":"struct Position.Props","name":"position","type":"tuple"},{"components":[{"components":[{"internalType":"bytes32","name":"referralCode","type":"bytes32"},{"internalType":"address","name":"affiliate","type":"address"},{"internalType":"address","name":"trader","type":"address"},{"internalType":"uint256","name":"totalRebateFactor","type":"uint256"},{"internalType":"uint256","name":"traderDiscountFactor","type":"uint256"},{"internalType":"uint256","name":"totalRebateAmount","type":"uint256"},{"internalType":"uint256","name":"traderDiscountAmount","type":"uint256"},{"internalType":"uint256","name":"affiliateRewardAmount","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionReferralFees","name":"referral","type":"tuple"},{"components":[{"internalType":"uint256","name":"fundingFeeAmount","type":"uint256"},{"internalType":"uint256","name":"claimableLongTokenAmount","type":"uint256"},{"internalType":"uint256","name":"claimableShortTokenAmount","type":"uint256"},{"internalType":"uint256","name":"latestFundingFeeAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"latestLongTokenClaimableFundingAmountPerSize","type":"uint256"},{"internalType":"uint256","name":"latestShortTokenClaimableFundingAmountPerSize","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionFundingFees","name":"funding","type":"tuple"},{"components":[{"internalType":"uint256","name":"borrowingFeeUsd","type":"uint256"},{"internalType":"uint256","name":"borrowingFeeAmount","type":"uint256"},{"internalType":"uint256","name":"borrowingFeeReceiverFactor","type":"uint256"},{"internalType":"uint256","name":"borrowingFeeAmountForFeeReceiver","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionBorrowingFees","name":"borrowing","type":"tuple"},{"components":[{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"uint256","name":"uiFeeReceiverFactor","type":"uint256"},{"internalType":"uint256","name":"uiFeeAmount","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionUiFees","name":"ui","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"collateralTokenPrice","type":"tuple"},{"internalType":"uint256","name":"positionFeeFactor","type":"uint256"},{"internalType":"uint256","name":"protocolFeeAmount","type":"uint256"},{"internalType":"uint256","name":"positionFeeReceiverFactor","type":"uint256"},{"internalType":"uint256","name":"feeReceiverAmount","type":"uint256"},{"internalType":"uint256","name":"feeAmountForPool","type":"uint256"},{"internalType":"uint256","name":"positionFeeAmountForPool","type":"uint256"},{"internalType":"uint256","name":"positionFeeAmount","type":"uint256"},{"internalType":"uint256","name":"totalCostAmountExcludingFunding","type":"uint256"},{"internalType":"uint256","name":"totalCostAmount","type":"uint256"}],"internalType":"struct PositionPricingUtils.PositionFees","name":"fees","type":"tuple"},{"components":[{"internalType":"int256","name":"priceImpactUsd","type":"int256"},{"internalType":"uint256","name":"priceImpactDiffUsd","type":"uint256"},{"internalType":"uint256","name":"executionPrice","type":"uint256"}],"internalType":"struct ReaderPricingUtils.ExecutionPriceResult","name":"executionPriceResult","type":"tuple"},{"internalType":"int256","name":"basePnlUsd","type":"int256"},{"internalType":"int256","name":"uncappedBasePnlUsd","type":"int256"},{"internalType":"int256","name":"pnlAfterPriceImpactUsd","type":"int256"}],"internalType":"struct ReaderUtils.PositionInfo","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"},{"internalType":"bytes32","name":"positionKey","type":"bytes32"},{"internalType":"uint256","name":"sizeDeltaUsd","type":"uint256"}],"name":"getPositionPnlUsd","outputs":[{"internalType":"int256","name":"","type":"int256"},{"internalType":"int256","name":"","type":"int256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"},{"internalType":"address","name":"tokenIn","type":"address"},{"internalType":"uint256","name":"amountIn","type":"uint256"},{"internalType":"address","name":"uiFeeReceiver","type":"address"}],"name":"getSwapAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"int256","name":"","type":"int256"},{"components":[{"internalType":"uint256","name":"feeReceiverAmount","type":"uint256"},{"internalType":"uint256","name":"feeAmountForPool","type":"uint256"},{"internalType":"uint256","name":"amountAfterFees","type":"uint256"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"uint256","name":"uiFeeReceiverFactor","type":"uint256"},{"internalType":"uint256","name":"uiFeeAmount","type":"uint256"}],"internalType":"struct SwapPricingUtils.SwapFees","name":"fees","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"address","name":"marketKey","type":"address"},{"internalType":"address","name":"tokenIn","type":"address"},{"internalType":"address","name":"tokenOut","type":"address"},{"internalType":"uint256","name":"amountIn","type":"uint256"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"tokenInPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"tokenOutPrice","type":"tuple"}],"name":"getSwapPriceImpact","outputs":[{"internalType":"int256","name":"","type":"int256"},{"internalType":"int256","name":"","type":"int256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"getWithdrawal","outputs":[{"components":[{"components":[{"internalType":"address","name":"account","type":"address"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address[]","name":"longTokenSwapPath","type":"address[]"},{"internalType":"address[]","name":"shortTokenSwapPath","type":"address[]"}],"internalType":"struct Withdrawal.Addresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"uint256","name":"marketTokenAmount","type":"uint256"},{"internalType":"uint256","name":"minLongTokenAmount","type":"uint256"},{"internalType":"uint256","name":"minShortTokenAmount","type":"uint256"},{"internalType":"uint256","name":"updatedAtBlock","type":"uint256"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"callbackGasLimit","type":"uint256"}],"internalType":"struct Withdrawal.Numbers","name":"numbers","type":"tuple"},{"components":[{"internalType":"bool","name":"shouldUnwrapNativeToken","type":"bool"}],"internalType":"struct Withdrawal.Flags","name":"flags","type":"tuple"}],"internalType":"struct Withdrawal.Props","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"contract DataStore","name":"dataStore","type":"address"},{"components":[{"internalType":"address","name":"marketToken","type":"address"},{"internalType":"address","name":"indexToken","type":"address"},{"internalType":"address","name":"longToken","type":"address"},{"internalType":"address","name":"shortToken","type":"address"}],"internalType":"struct Market.Props","name":"market","type":"tuple"},{"components":[{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"indexTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"longTokenPrice","type":"tuple"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props","name":"shortTokenPrice","type":"tuple"}],"internalType":"struct MarketUtils.MarketPrices","name":"prices","type":"tuple"},{"internalType":"uint256","name":"marketTokenAmount","type":"uint256"},{"internalType":"address","name":"uiFeeReceiver","type":"address"}],"name":"getWithdrawalAmountOut","outputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Keys
// @dev Keys for values in the DataStore
library Keys {
    // @dev key for the address of the wrapped native token
    bytes32 public constant WNT = keccak256(abi.encode("WNT"));
    // @dev key for the nonce value used in NonceUtils
    bytes32 public constant NONCE = keccak256(abi.encode("NONCE"));

    // @dev for sending received fees
    bytes32 public constant FEE_RECEIVER = keccak256(abi.encode("FEE_RECEIVER"));

    // @dev for holding tokens that could not be sent out
    bytes32 public constant HOLDING_ADDRESS = keccak256(abi.encode("HOLDING_ADDRESS"));

    // @dev key for in strict price feed mode
    bytes32 public constant IN_STRICT_PRICE_FEED_MODE = keccak256(abi.encode("IN_STRICT_PRICE_FEED_MODE"));

    // @dev key for the minimum gas for execution error
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS = keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS"));

    // @dev key for the minimum gas that should be forwarded for execution error handling
    bytes32 public constant MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD = keccak256(abi.encode("MIN_HANDLE_EXECUTION_ERROR_GAS_TO_FORWARD"));

    // @dev key for the min additional gas for execution
    bytes32 public constant MIN_ADDITIONAL_GAS_FOR_EXECUTION = keccak256(abi.encode("MIN_ADDITIONAL_GAS_FOR_EXECUTION"));

    // @dev for a global reentrancy guard
    bytes32 public constant REENTRANCY_GUARD_STATUS = keccak256(abi.encode("REENTRANCY_GUARD_STATUS"));

    // @dev key for deposit fees
    bytes32 public constant DEPOSIT_FEE_TYPE = keccak256(abi.encode("DEPOSIT_FEE_TYPE"));
    // @dev key for withdrawal fees
    bytes32 public constant WITHDRAWAL_FEE_TYPE = keccak256(abi.encode("WITHDRAWAL_FEE_TYPE"));
    // @dev key for swap fees
    bytes32 public constant SWAP_FEE_TYPE = keccak256(abi.encode("SWAP_FEE_TYPE"));
    // @dev key for position fees
    bytes32 public constant POSITION_FEE_TYPE = keccak256(abi.encode("POSITION_FEE_TYPE"));
    // @dev key for ui deposit fees
    bytes32 public constant UI_DEPOSIT_FEE_TYPE = keccak256(abi.encode("UI_DEPOSIT_FEE_TYPE"));
    // @dev key for ui withdrawal fees
    bytes32 public constant UI_WITHDRAWAL_FEE_TYPE = keccak256(abi.encode("UI_WITHDRAWAL_FEE_TYPE"));
    // @dev key for ui swap fees
    bytes32 public constant UI_SWAP_FEE_TYPE = keccak256(abi.encode("UI_SWAP_FEE_TYPE"));
    // @dev key for ui position fees
    bytes32 public constant UI_POSITION_FEE_TYPE = keccak256(abi.encode("UI_POSITION_FEE_TYPE"));

    // @dev key for ui fee factor
    bytes32 public constant UI_FEE_FACTOR = keccak256(abi.encode("UI_FEE_FACTOR"));
    // @dev key for max ui fee receiver factor
    bytes32 public constant MAX_UI_FEE_FACTOR = keccak256(abi.encode("MAX_UI_FEE_FACTOR"));

    // @dev key for the claimable fee amount
    bytes32 public constant CLAIMABLE_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_FEE_AMOUNT"));
    // @dev key for the claimable ui fee amount
    bytes32 public constant CLAIMABLE_UI_FEE_AMOUNT = keccak256(abi.encode("CLAIMABLE_UI_FEE_AMOUNT"));

    // @dev key for the market list
    bytes32 public constant MARKET_LIST = keccak256(abi.encode("MARKET_LIST"));

    // @dev key for the fee batch list
    bytes32 public constant FEE_BATCH_LIST = keccak256(abi.encode("FEE_BATCH_LIST"));

    // @dev key for the deposit list
    bytes32 public constant DEPOSIT_LIST = keccak256(abi.encode("DEPOSIT_LIST"));
    // @dev key for the account deposit list
    bytes32 public constant ACCOUNT_DEPOSIT_LIST = keccak256(abi.encode("ACCOUNT_DEPOSIT_LIST"));

    // @dev key for the withdrawal list
    bytes32 public constant WITHDRAWAL_LIST = keccak256(abi.encode("WITHDRAWAL_LIST"));
    // @dev key for the account withdrawal list
    bytes32 public constant ACCOUNT_WITHDRAWAL_LIST = keccak256(abi.encode("ACCOUNT_WITHDRAWAL_LIST"));

    // @dev key for the position list
    bytes32 public constant POSITION_LIST = keccak256(abi.encode("POSITION_LIST"));
    // @dev key for the account position list
    bytes32 public constant ACCOUNT_POSITION_LIST = keccak256(abi.encode("ACCOUNT_POSITION_LIST"));

    // @dev key for the order list
    bytes32 public constant ORDER_LIST = keccak256(abi.encode("ORDER_LIST"));
    // @dev key for the account order list
    bytes32 public constant ACCOUNT_ORDER_LIST = keccak256(abi.encode("ACCOUNT_ORDER_LIST"));

    // @dev key for the subaccount list
    bytes32 public constant SUBACCOUNT_LIST = keccak256(abi.encode("SUBACCOUNT_LIST"));

    // @dev key for is market disabled
    bytes32 public constant IS_MARKET_DISABLED = keccak256(abi.encode("IS_MARKET_DISABLED"));

    // @dev key for the max swap path length allowed
    bytes32 public constant MAX_SWAP_PATH_LENGTH = keccak256(abi.encode("MAX_SWAP_PATH_LENGTH"));
    // @dev key used to store markets observed in a swap path, to ensure that a swap path contains unique markets
    bytes32 public constant SWAP_PATH_MARKET_FLAG = keccak256(abi.encode("SWAP_PATH_MARKET_FLAG"));
    // @dev key used to store the min market tokens for the first deposit for a market
    bytes32 public constant MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT = keccak256(abi.encode("MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT"));

    // @dev key for whether the create deposit feature is disabled
    bytes32 public constant CREATE_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CREATE_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the cancel deposit feature is disabled
    bytes32 public constant CANCEL_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_DEPOSIT_FEATURE_DISABLED"));
    // @dev key for whether the execute deposit feature is disabled
    bytes32 public constant EXECUTE_DEPOSIT_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_DEPOSIT_FEATURE_DISABLED"));

    // @dev key for whether the create withdrawal feature is disabled
    bytes32 public constant CREATE_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("CREATE_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the cancel withdrawal feature is disabled
    bytes32 public constant CANCEL_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_WITHDRAWAL_FEATURE_DISABLED"));
    // @dev key for whether the execute withdrawal feature is disabled
    bytes32 public constant EXECUTE_WITHDRAWAL_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_WITHDRAWAL_FEATURE_DISABLED"));

    // @dev key for whether the create order feature is disabled
    bytes32 public constant CREATE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("CREATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute order feature is disabled
    bytes32 public constant EXECUTE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the execute adl feature is disabled
    // for liquidations, it can be disabled by using the EXECUTE_ORDER_FEATURE_DISABLED key with the Liquidation
    // order type, ADL orders have a MarketDecrease order type, so a separate key is needed to disable it
    bytes32 public constant EXECUTE_ADL_FEATURE_DISABLED = keccak256(abi.encode("EXECUTE_ADL_FEATURE_DISABLED"));
    // @dev key for whether the update order feature is disabled
    bytes32 public constant UPDATE_ORDER_FEATURE_DISABLED = keccak256(abi.encode("UPDATE_ORDER_FEATURE_DISABLED"));
    // @dev key for whether the cancel order feature is disabled
    bytes32 public constant CANCEL_ORDER_FEATURE_DISABLED = keccak256(abi.encode("CANCEL_ORDER_FEATURE_DISABLED"));

    // @dev key for whether the claim funding fees feature is disabled
    bytes32 public constant CLAIM_FUNDING_FEES_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_FUNDING_FEES_FEATURE_DISABLED"));
    // @dev key for whether the claim collateral feature is disabled
    bytes32 public constant CLAIM_COLLATERAL_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_COLLATERAL_FEATURE_DISABLED"));
    // @dev key for whether the claim affiliate rewards feature is disabled
    bytes32 public constant CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED"));
    // @dev key for whether the claim ui fees feature is disabled
    bytes32 public constant CLAIM_UI_FEES_FEATURE_DISABLED = keccak256(abi.encode("CLAIM_UI_FEES_FEATURE_DISABLED"));
    // @dev key for whether the subaccount feature is disabled
    bytes32 public constant SUBACCOUNT_FEATURE_DISABLED = keccak256(abi.encode("SUBACCOUNT_FEATURE_DISABLED"));

    // @dev key for the minimum required oracle signers for an oracle observation
    bytes32 public constant MIN_ORACLE_SIGNERS = keccak256(abi.encode("MIN_ORACLE_SIGNERS"));
    // @dev key for the minimum block confirmations before blockhash can be excluded for oracle signature validation
    bytes32 public constant MIN_ORACLE_BLOCK_CONFIRMATIONS = keccak256(abi.encode("MIN_ORACLE_BLOCK_CONFIRMATIONS"));
    // @dev key for the maximum usable oracle price age in seconds
    bytes32 public constant MAX_ORACLE_PRICE_AGE = keccak256(abi.encode("MAX_ORACLE_PRICE_AGE"));
    // @dev key for the maximum oracle price deviation factor from the ref price
    bytes32 public constant MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR = keccak256(abi.encode("MAX_ORACLE_REF_PRICE_DEVIATION_FACTOR"));
    // @dev key for the percentage amount of position fees to be received
    bytes32 public constant POSITION_FEE_RECEIVER_FACTOR = keccak256(abi.encode("POSITION_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of swap fees to be received
    bytes32 public constant SWAP_FEE_RECEIVER_FACTOR = keccak256(abi.encode("SWAP_FEE_RECEIVER_FACTOR"));
    // @dev key for the percentage amount of borrowing fees to be received
    bytes32 public constant BORROWING_FEE_RECEIVER_FACTOR = keccak256(abi.encode("BORROWING_FEE_RECEIVER_FACTOR"));

    // @dev key for the base gas limit used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_BASE_AMOUNT = keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when estimating execution fee
    bytes32 public constant ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the base gas limit used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_BASE_AMOUNT = keccak256(abi.encode("EXECUTION_GAS_FEE_BASE_AMOUNT"));
    // @dev key for the multiplier used when calculating execution fee
    bytes32 public constant EXECUTION_GAS_FEE_MULTIPLIER_FACTOR = keccak256(abi.encode("EXECUTION_GAS_FEE_MULTIPLIER_FACTOR"));

    // @dev key for the estimated gas limit for deposits
    bytes32 public constant DEPOSIT_GAS_LIMIT = keccak256(abi.encode("DEPOSIT_GAS_LIMIT"));
    // @dev key for the estimated gas limit for withdrawals
    bytes32 public constant WITHDRAWAL_GAS_LIMIT = keccak256(abi.encode("WITHDRAWAL_GAS_LIMIT"));
    // @dev key for the estimated gas limit for single swaps
    bytes32 public constant SINGLE_SWAP_GAS_LIMIT = keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));
    // @dev key for the estimated gas limit for increase orders
    bytes32 public constant INCREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for decrease orders
    bytes32 public constant DECREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for swap orders
    bytes32 public constant SWAP_ORDER_GAS_LIMIT = keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for token transfers
    bytes32 public constant TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the amount of gas to forward for native token transfers
    bytes32 public constant NATIVE_TOKEN_TRANSFER_GAS_LIMIT = keccak256(abi.encode("NATIVE_TOKEN_TRANSFER_GAS_LIMIT"));
    // @dev key for the maximum request block age, after which the request will be considered expired
    bytes32 public constant REQUEST_EXPIRATION_BLOCK_AGE = keccak256(abi.encode("REQUEST_EXPIRATION_BLOCK_AGE"));

    bytes32 public constant MAX_CALLBACK_GAS_LIMIT = keccak256(abi.encode("MAX_CALLBACK_GAS_LIMIT"));
    bytes32 public constant SAVED_CALLBACK_CONTRACT = keccak256(abi.encode("SAVED_CALLBACK_CONTRACT"));

    // @dev key for the min collateral factor
    bytes32 public constant MIN_COLLATERAL_FACTOR = keccak256(abi.encode("MIN_COLLATERAL_FACTOR"));
    // @dev key for the min collateral factor for open interest multiplier
    bytes32 public constant MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER = keccak256(abi.encode("MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER"));
    // @dev key for the min allowed collateral in USD
    bytes32 public constant MIN_COLLATERAL_USD = keccak256(abi.encode("MIN_COLLATERAL_USD"));
    // @dev key for the min allowed position size in USD
    bytes32 public constant MIN_POSITION_SIZE_USD = keccak256(abi.encode("MIN_POSITION_SIZE_USD"));

    // @dev key for the virtual id of tokens
    bytes32 public constant VIRTUAL_TOKEN_ID = keccak256(abi.encode("VIRTUAL_TOKEN_ID"));
    // @dev key for the virtual id of markets
    bytes32 public constant VIRTUAL_MARKET_ID = keccak256(abi.encode("VIRTUAL_MARKET_ID"));
    // @dev key for the virtual inventory for swaps
    bytes32 public constant VIRTUAL_INVENTORY_FOR_SWAPS = keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_SWAPS"));
    // @dev key for the virtual inventory for positions
    bytes32 public constant VIRTUAL_INVENTORY_FOR_POSITIONS = keccak256(abi.encode("VIRTUAL_INVENTORY_FOR_POSITIONS"));

    // @dev key for the position impact factor
    bytes32 public constant POSITION_IMPACT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_FACTOR"));
    // @dev key for the position impact exponent factor
    bytes32 public constant POSITION_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("POSITION_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the max decrease position impact factor
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR = keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR"));
    // @dev key for the max position impact factor for liquidations
    bytes32 public constant MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS = keccak256(abi.encode("MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS"));
    // @dev key for the position fee factor
    bytes32 public constant POSITION_FEE_FACTOR = keccak256(abi.encode("POSITION_FEE_FACTOR"));
    // @dev key for the swap impact factor
    bytes32 public constant SWAP_IMPACT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_FACTOR"));
    // @dev key for the swap impact exponent factor
    bytes32 public constant SWAP_IMPACT_EXPONENT_FACTOR = keccak256(abi.encode("SWAP_IMPACT_EXPONENT_FACTOR"));
    // @dev key for the swap fee factor
    bytes32 public constant SWAP_FEE_FACTOR = keccak256(abi.encode("SWAP_FEE_FACTOR"));
    // @dev key for the oracle type
    bytes32 public constant ORACLE_TYPE = keccak256(abi.encode("ORACLE_TYPE"));
    // @dev key for open interest
    bytes32 public constant OPEN_INTEREST = keccak256(abi.encode("OPEN_INTEREST"));
    // @dev key for open interest in tokens
    bytes32 public constant OPEN_INTEREST_IN_TOKENS = keccak256(abi.encode("OPEN_INTEREST_IN_TOKENS"));
    // @dev key for collateral sum for a market
    bytes32 public constant COLLATERAL_SUM = keccak256(abi.encode("COLLATERAL_SUM"));
    // @dev key for pool amount
    bytes32 public constant POOL_AMOUNT = keccak256(abi.encode("POOL_AMOUNT"));
    // @dev key for max pool amount
    bytes32 public constant MAX_POOL_AMOUNT = keccak256(abi.encode("MAX_POOL_AMOUNT"));
    // @dev key for max pool amount for deposit
    bytes32 public constant MAX_POOL_AMOUNT_FOR_DEPOSIT = keccak256(abi.encode("MAX_POOL_AMOUNT_FOR_DEPOSIT"));
    // @dev key for max open interest
    bytes32 public constant MAX_OPEN_INTEREST = keccak256(abi.encode("MAX_OPEN_INTEREST"));
    // @dev key for position impact pool amount
    bytes32 public constant POSITION_IMPACT_POOL_AMOUNT = keccak256(abi.encode("POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for min position impact pool amount
    bytes32 public constant MIN_POSITION_IMPACT_POOL_AMOUNT = keccak256(abi.encode("MIN_POSITION_IMPACT_POOL_AMOUNT"));
    // @dev key for position impact pool distribution rate
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTION_RATE = keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTION_RATE"));
    // @dev key for position impact pool distributed at
    bytes32 public constant POSITION_IMPACT_POOL_DISTRIBUTED_AT = keccak256(abi.encode("POSITION_IMPACT_POOL_DISTRIBUTED_AT"));
    // @dev key for swap impact pool amount
    bytes32 public constant SWAP_IMPACT_POOL_AMOUNT = keccak256(abi.encode("SWAP_IMPACT_POOL_AMOUNT"));
    // @dev key for price feed
    bytes32 public constant PRICE_FEED = keccak256(abi.encode("PRICE_FEED"));
    // @dev key for price feed multiplier
    bytes32 public constant PRICE_FEED_MULTIPLIER = keccak256(abi.encode("PRICE_FEED_MULTIPLIER"));
    // @dev key for price feed heartbeat
    bytes32 public constant PRICE_FEED_HEARTBEAT_DURATION = keccak256(abi.encode("PRICE_FEED_HEARTBEAT_DURATION"));
    // @dev key for realtime feed id
    bytes32 public constant REALTIME_FEED_ID = keccak256(abi.encode("REALTIME_FEED_ID"));
    // @dev key for realtime feed multipler
    bytes32 public constant REALTIME_FEED_MULTIPLIER = keccak256(abi.encode("REALTIME_FEED_MULTIPLIER"));
    // @dev key for stable price
    bytes32 public constant STABLE_PRICE = keccak256(abi.encode("STABLE_PRICE"));
    // @dev key for reserve factor
    bytes32 public constant RESERVE_FACTOR = keccak256(abi.encode("RESERVE_FACTOR"));
    // @dev key for open interest reserve factor
    bytes32 public constant OPEN_INTEREST_RESERVE_FACTOR = keccak256(abi.encode("OPEN_INTEREST_RESERVE_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR = keccak256(abi.encode("MAX_PNL_FACTOR"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_TRADERS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_TRADERS"));
    // @dev key for max pnl factor for adl
    bytes32 public constant MAX_PNL_FACTOR_FOR_ADL = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_ADL"));
    // @dev key for min pnl factor for adl
    bytes32 public constant MIN_PNL_FACTOR_AFTER_ADL = keccak256(abi.encode("MIN_PNL_FACTOR_AFTER_ADL"));
    // @dev key for max pnl factor
    bytes32 public constant MAX_PNL_FACTOR_FOR_DEPOSITS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_DEPOSITS"));
    // @dev key for max pnl factor for withdrawals
    bytes32 public constant MAX_PNL_FACTOR_FOR_WITHDRAWALS = keccak256(abi.encode("MAX_PNL_FACTOR_FOR_WITHDRAWALS"));
    // @dev key for latest ADL block
    bytes32 public constant LATEST_ADL_BLOCK = keccak256(abi.encode("LATEST_ADL_BLOCK"));
    // @dev key for whether ADL is enabled
    bytes32 public constant IS_ADL_ENABLED = keccak256(abi.encode("IS_ADL_ENABLED"));
    // @dev key for funding factor
    bytes32 public constant FUNDING_FACTOR = keccak256(abi.encode("FUNDING_FACTOR"));
    // @dev key for funding exponent factor
    bytes32 public constant FUNDING_EXPONENT_FACTOR = keccak256(abi.encode("FUNDING_EXPONENT_FACTOR"));
    // @dev key for saved funding factor
    bytes32 public constant SAVED_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("SAVED_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for funding increase factor
    bytes32 public constant FUNDING_INCREASE_FACTOR_PER_SECOND = keccak256(abi.encode("FUNDING_INCREASE_FACTOR_PER_SECOND"));
    // @dev key for funding decrease factor
    bytes32 public constant FUNDING_DECREASE_FACTOR_PER_SECOND = keccak256(abi.encode("FUNDING_DECREASE_FACTOR_PER_SECOND"));
    // @dev key for min funding factor
    bytes32 public constant MIN_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("MIN_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for max funding factor
    bytes32 public constant MAX_FUNDING_FACTOR_PER_SECOND = keccak256(abi.encode("MAX_FUNDING_FACTOR_PER_SECOND"));
    // @dev key for threshold for stable funding
    bytes32 public constant THRESHOLD_FOR_STABLE_FUNDING = keccak256(abi.encode("THRESHOLD_FOR_STABLE_FUNDING"));
    // @dev key for threshold for decrease funding
    bytes32 public constant THRESHOLD_FOR_DECREASE_FUNDING = keccak256(abi.encode("THRESHOLD_FOR_DECREASE_FUNDING"));
    // @dev key for funding fee amount per size
    bytes32 public constant FUNDING_FEE_AMOUNT_PER_SIZE = keccak256(abi.encode("FUNDING_FEE_AMOUNT_PER_SIZE"));
    // @dev key for claimable funding amount per size
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT_PER_SIZE = keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT_PER_SIZE"));
    // @dev key for when funding was last updated at
    bytes32 public constant FUNDING_UPDATED_AT = keccak256(abi.encode("FUNDING_UPDATED_AT"));
    // @dev key for claimable funding amount
    bytes32 public constant CLAIMABLE_FUNDING_AMOUNT = keccak256(abi.encode("CLAIMABLE_FUNDING_AMOUNT"));
    // @dev key for claimable collateral amount
    bytes32 public constant CLAIMABLE_COLLATERAL_AMOUNT = keccak256(abi.encode("CLAIMABLE_COLLATERAL_AMOUNT"));
    // @dev key for claimable collateral factor
    bytes32 public constant CLAIMABLE_COLLATERAL_FACTOR = keccak256(abi.encode("CLAIMABLE_COLLATERAL_FACTOR"));
    // @dev key for claimable collateral time divisor
    bytes32 public constant CLAIMABLE_COLLATERAL_TIME_DIVISOR = keccak256(abi.encode("CLAIMABLE_COLLATERAL_TIME_DIVISOR"));
    // @dev key for claimed collateral amount
    bytes32 public constant CLAIMED_COLLATERAL_AMOUNT = keccak256(abi.encode("CLAIMED_COLLATERAL_AMOUNT"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_FACTOR = keccak256(abi.encode("BORROWING_FACTOR"));
    // @dev key for borrowing factor
    bytes32 public constant BORROWING_EXPONENT_FACTOR = keccak256(abi.encode("BORROWING_EXPONENT_FACTOR"));
    // @dev key for skipping the borrowing factor for the smaller side
    bytes32 public constant SKIP_BORROWING_FEE_FOR_SMALLER_SIDE = keccak256(abi.encode("SKIP_BORROWING_FEE_FOR_SMALLER_SIDE"));
    // @dev key for cumulative borrowing factor
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR"));
    // @dev key for when the cumulative borrowing factor was last updated at
    bytes32 public constant CUMULATIVE_BORROWING_FACTOR_UPDATED_AT = keccak256(abi.encode("CUMULATIVE_BORROWING_FACTOR_UPDATED_AT"));
    // @dev key for total borrowing amount
    bytes32 public constant TOTAL_BORROWING = keccak256(abi.encode("TOTAL_BORROWING"));
    // @dev key for affiliate reward
    bytes32 public constant AFFILIATE_REWARD = keccak256(abi.encode("AFFILIATE_REWARD"));
    // @dev key for max allowed subaccount action count
    bytes32 public constant MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT = keccak256(abi.encode("MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount action count
    bytes32 public constant SUBACCOUNT_ACTION_COUNT = keccak256(abi.encode("SUBACCOUNT_ACTION_COUNT"));
    // @dev key for subaccount auto top up amount
    bytes32 public constant SUBACCOUNT_AUTO_TOP_UP_AMOUNT = keccak256(abi.encode("SUBACCOUNT_AUTO_TOP_UP_AMOUNT"));
    // @dev key for subaccount order action
    bytes32 public constant SUBACCOUNT_ORDER_ACTION = keccak256(abi.encode("SUBACCOUNT_ORDER_ACTION"));
    // @dev key for fee distributor swap order token index
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX = keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX"));
    // @dev key for fee distributor swap fee batch
    bytes32 public constant FEE_DISTRIBUTOR_SWAP_FEE_BATCH = keccak256(abi.encode("FEE_DISTRIBUTOR_SWAP_FEE_BATCH"));

    // @dev constant for user initiated cancel reason
    string public constant USER_INITIATED_CANCEL = "USER_INITIATED_CANCEL";

    // @dev key for the account deposit list
    // @param account the account for the list
    function accountDepositListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_DEPOSIT_LIST, account));
    }

    // @dev key for the account withdrawal list
    // @param account the account for the list
    function accountWithdrawalListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_WITHDRAWAL_LIST, account));
    }

    // @dev key for the account position list
    // @param account the account for the list
    function accountPositionListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_POSITION_LIST, account));
    }

    // @dev key for the account order list
    // @param account the account for the list
    function accountOrderListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(ACCOUNT_ORDER_LIST, account));
    }

    // @dev key for the subaccount list
    // @param account the account for the list
    function subaccountListKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(SUBACCOUNT_LIST, account));
    }

    // @dev key for the claimable fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    function claimableFeeAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token));
    }

    // @dev key for the claimable ui fee amount for account
    // @param market the market for the fee
    // @param token the token for the fee
    // @param account the account that can claim the ui fee
    function claimableUiFeeAmountKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(CLAIMABLE_UI_FEE_AMOUNT, market, token, account));
    }

    // @dev key for deposit gas limit
    // @param singleToken whether a single token or pair tokens are being deposited
    // @return key for deposit gas limit
    function depositGasLimitKey(bool singleToken) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            DEPOSIT_GAS_LIMIT,
            singleToken
        ));
    }

    // @dev key for withdrawal gas limit
    // @return key for withdrawal gas limit
    function withdrawalGasLimitKey() internal pure returns (bytes32) {
        return keccak256(abi.encode(
            WITHDRAWAL_GAS_LIMIT
        ));
    }

    // @dev key for single swap gas limit
    // @return key for single swap gas limit
    function singleSwapGasLimitKey() internal pure returns (bytes32) {
        return SINGLE_SWAP_GAS_LIMIT;
    }

    // @dev key for increase order gas limit
    // @return key for increase order gas limit
    function increaseOrderGasLimitKey() internal pure returns (bytes32) {
        return INCREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for decrease order gas limit
    // @return key for decrease order gas limit
    function decreaseOrderGasLimitKey() internal pure returns (bytes32) {
        return DECREASE_ORDER_GAS_LIMIT;
    }

    // @dev key for swap order gas limit
    // @return key for swap order gas limit
    function swapOrderGasLimitKey() internal pure returns (bytes32) {
        return SWAP_ORDER_GAS_LIMIT;
    }

    function swapPathMarketFlagKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_PATH_MARKET_FLAG,
            market
        ));
    }

    // @dev key for whether create deposit is disabled
    // @param the create deposit module
    // @return key for whether create deposit is disabled
    function createDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel deposit is disabled
    // @param the cancel deposit module
    // @return key for whether cancel deposit is disabled
    function cancelDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute deposit is disabled
    // @param the execute deposit module
    // @return key for whether execute deposit is disabled
    function executeDepositFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_DEPOSIT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether create withdrawal is disabled
    // @param the create withdrawal module
    // @return key for whether create withdrawal is disabled
    function createWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether cancel withdrawal is disabled
    // @param the cancel withdrawal module
    // @return key for whether cancel withdrawal is disabled
    function cancelWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether execute withdrawal is disabled
    // @param the execute withdrawal module
    // @return key for whether execute withdrawal is disabled
    function executeWithdrawalFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_WITHDRAWAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether create order is disabled
    // @param the create order module
    // @return key for whether create order is disabled
    function createOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CREATE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether execute order is disabled
    // @param the execute order module
    // @return key for whether execute order is disabled
    function executeOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether execute adl is disabled
    // @param the execute adl module
    // @return key for whether execute adl is disabled
    function executeAdlFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            EXECUTE_ADL_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether update order is disabled
    // @param the update order module
    // @return key for whether update order is disabled
    function updateOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UPDATE_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether cancel order is disabled
    // @param the cancel order module
    // @return key for whether cancel order is disabled
    function cancelOrderFeatureDisabledKey(address module, uint256 orderType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CANCEL_ORDER_FEATURE_DISABLED,
            module,
            orderType
        ));
    }

    // @dev key for whether claim funding fees is disabled
    // @param the claim funding fees module
    function claimFundingFeesFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_FUNDING_FEES_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim colltareral is disabled
    // @param the claim funding fees module
    function claimCollateralFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_COLLATERAL_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim affiliate rewards is disabled
    // @param the claim affiliate rewards module
    function claimAffiliateRewardsFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_AFFILIATE_REWARDS_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether claim ui fees is disabled
    // @param the claim ui fees module
    function claimUiFeesFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIM_UI_FEES_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for whether subaccounts are disabled
    // @param the subaccount module
    function subaccountFeatureDisabledKey(address module) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_FEATURE_DISABLED,
            module
        ));
    }

    // @dev key for ui fee factor
    // @param account the fee receiver account
    // @return key for ui fee factor
    function uiFeeFactorKey(address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            UI_FEE_FACTOR,
            account
        ));
    }

    // @dev key for gas to forward for token transfer
    // @param the token to check
    // @return key for gas to forward for token transfer
    function tokenTransferGasLimit(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOKEN_TRANSFER_GAS_LIMIT,
            token
        ));
   }

   // @dev the default callback contract
   // @param account the user's account
   // @param market the address of the market
   // @param callbackContract the callback contract
   function savedCallbackContract(address account, address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           SAVED_CALLBACK_CONTRACT,
           account,
           market
       ));
   }

   // @dev the min collateral factor key
   // @param the market for the min collateral factor
   function minCollateralFactorKey(address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           MIN_COLLATERAL_FACTOR,
           market
       ));
   }

   // @dev the min collateral factor for open interest multiplier key
   // @param the market for the factor
   function minCollateralFactorForOpenInterestMultiplierKey(address market, bool isLong) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           MIN_COLLATERAL_FACTOR_FOR_OPEN_INTEREST_MULTIPLIER,
           market,
           isLong
       ));
   }

   // @dev the key for the virtual token id
   // @param the token to get the virtual id for
   function virtualTokenIdKey(address token) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_TOKEN_ID,
           token
       ));
   }

   // @dev the key for the virtual market id
   // @param the market to get the virtual id for
   function virtualMarketIdKey(address market) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_MARKET_ID,
           market
       ));
   }

   // @dev the key for the virtual inventory for positions
   // @param the virtualTokenId the virtual token id
   function virtualInventoryForPositionsKey(bytes32 virtualTokenId) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_INVENTORY_FOR_POSITIONS,
           virtualTokenId
       ));
   }

   // @dev the key for the virtual inventory for swaps
   // @param the virtualMarketId the virtual market id
   // @param the token to check the inventory for
   function virtualInventoryForSwapsKey(bytes32 virtualMarketId, bool isLongToken) internal pure returns (bytes32) {
       return keccak256(abi.encode(
           VIRTUAL_INVENTORY_FOR_SWAPS,
           virtualMarketId,
           isLongToken
       ));
   }

    // @dev key for position impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for position impact factor
    function positionImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_FACTOR,
            market,
            isPositive
        ));
   }

    // @dev key for position impact exponent factor
    // @param market the market address to check
    // @return key for position impact exponent factor
    function positionImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_EXPONENT_FACTOR,
            market
        ));
    }

    // @dev key for the max position impact factor
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POSITION_IMPACT_FACTOR,
            market,
            isPositive
        ));
    }

    // @dev key for the max position impact factor for liquidations
    // @param market the market address to check
    // @return key for the max position impact factor
    function maxPositionImpactFactorForLiquidationsKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POSITION_IMPACT_FACTOR_FOR_LIQUIDATIONS,
            market
        ));
    }

    // @dev key for position fee factor
    // @param market the market address to check
    // @param forPositiveImpact whether the fee is for an action that has a positive price impact
    // @return key for position fee factor
    function positionFeeFactorKey(address market, bool forPositiveImpact) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_FEE_FACTOR,
            market,
            forPositiveImpact
        ));
    }

    // @dev key for swap impact factor
    // @param market the market address to check
    // @param isPositive whether the impact is positive or negative
    // @return key for swap impact factor
    function swapImpactFactorKey(address market, bool isPositive) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_FACTOR,
            market,
            isPositive
        ));
    }

    // @dev key for swap impact exponent factor
    // @param market the market address to check
    // @return key for swap impact exponent factor
    function swapImpactExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_EXPONENT_FACTOR,
            market
        ));
    }


    // @dev key for swap fee factor
    // @param market the market address to check
    // @return key for swap fee factor
    function swapFeeFactorKey(address market, bool forPositiveImpact) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_FEE_FACTOR,
            market,
            forPositiveImpact
        ));
    }

    // @dev key for oracle type
    // @param token the token to check
    // @return key for oracle type
    function oracleTypeKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ORACLE_TYPE,
            token
        ));
    }

    // @dev key for open interest
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest
    function openInterestKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for open interest in tokens
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for open interest in tokens
    function openInterestInTokensKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST_IN_TOKENS,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for collateral sum for a market
    // @param market the market to check
    // @param collateralToken the collateralToken to check
    // @param isLong whether to check the long or short open interest
    // @return key for collateral sum
    function collateralSumKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            COLLATERAL_SUM,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for amount of tokens in a market's pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's pool
    function poolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev the key for the max amount of pool tokens
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev the key for the max amount of pool tokens for deposits
    // @param market the market for the pool
    // @param token the token for the pool
    function maxPoolAmountForDepositKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_POOL_AMOUNT_FOR_DEPOSIT,
            market,
            token
        ));
    }

    // @dev the key for the max open interest
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function maxOpenInterestKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_OPEN_INTEREST,
            market,
            isLong
        ));
    }

    // @dev key for amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for amount of tokens in a market's position impact pool
    function positionImpactPoolAmountKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_AMOUNT,
            market
        ));
    }

    // @dev key for min amount of tokens in a market's position impact pool
    // @param market the market to check
    // @return key for min amount of tokens in a market's position impact pool
    function minPositionImpactPoolAmountKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_POSITION_IMPACT_POOL_AMOUNT,
            market
        ));
    }

    // @dev key for position impact pool distribution rate
    // @param market the market to check
    // @return key for position impact pool distribution rate
    function positionImpactPoolDistributionRateKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_DISTRIBUTION_RATE,
            market
        ));
    }

    // @dev key for position impact pool distributed at
    // @param market the market to check
    // @return key for position impact pool distributed at
    function positionImpactPoolDistributedAtKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            POSITION_IMPACT_POOL_DISTRIBUTED_AT,
            market
        ));
    }

    // @dev key for amount of tokens in a market's swap impact pool
    // @param market the market to check
    // @param token the token to check
    // @return key for amount of tokens in a market's swap impact pool
    function swapImpactPoolAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SWAP_IMPACT_POOL_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for reserve factor
    function reserveFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            RESERVE_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for open interest reserve factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for open interest reserve factor
    function openInterestReserveFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            OPEN_INTEREST_RESERVE_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for max pnl factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for max pnl factor
    function maxPnlFactorKey(bytes32 pnlFactorType, address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_PNL_FACTOR,
            pnlFactorType,
            market,
            isLong
        ));
    }

    // @dev the key for min PnL factor after ADL
    // @param market the market for the pool
    // @param isLong whether the key is for the long or short side
    function minPnlFactorAfterAdlKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_PNL_FACTOR_AFTER_ADL,
            market,
            isLong
        ));
    }

    // @dev key for latest adl block
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for latest adl block
    function latestAdlBlockKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            LATEST_ADL_BLOCK,
            market,
            isLong
        ));
    }

    // @dev key for whether adl is enabled
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for whether adl is enabled
    function isAdlEnabledKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_ADL_ENABLED,
            market,
            isLong
        ));
    }

    // @dev key for funding factor
    // @param market the market to check
    // @return key for funding factor
    function fundingFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_FACTOR,
            market
        ));
    }

    // @dev the key for funding exponent
    // @param market the market for the pool
    function fundingExponentFactorKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_EXPONENT_FACTOR,
            market
        ));
    }

    // @dev the key for saved funding factor
    // @param market the market for the pool
    function savedFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SAVED_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for funding increase factor
    // @param market the market for the pool
    function fundingIncreaseFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_INCREASE_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for funding decrease factor
    // @param market the market for the pool
    function fundingDecreaseFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_DECREASE_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for min funding factor
    // @param market the market for the pool
    function minFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for max funding factor
    // @param market the market for the pool
    function maxFundingFactorPerSecondKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_FUNDING_FACTOR_PER_SECOND,
            market
        ));
    }

    // @dev the key for threshold for stable funding
    // @param market the market for the pool
    function thresholdForStableFundingKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            THRESHOLD_FOR_STABLE_FUNDING,
            market
        ));
    }

    // @dev the key for threshold for decreasing funding
    // @param market the market for the pool
    function thresholdForDecreaseFundingKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            THRESHOLD_FOR_DECREASE_FUNDING,
            market
        ));
    }

    // @dev key for funding fee amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for funding fee amount per size
    function fundingFeeAmountPerSizeKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_FEE_AMOUNT_PER_SIZE,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for claimabel funding amount per size
    // @param market the market to check
    // @param collateralToken the collateralToken to get the key for
    // @param isLong whether to get the key for the long or short side
    // @return key for claimable funding amount per size
    function claimableFundingAmountPerSizeKey(address market, address collateralToken, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT_PER_SIZE,
            market,
            collateralToken,
            isLong
        ));
    }

    // @dev key for when funding was last updated
    // @param market the market to check
    // @return key for when funding was last updated
    function fundingUpdatedAtKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FUNDING_UPDATED_AT,
            market
        ));
    }

    // @dev key for claimable funding amount
    // @param market the market to check
    // @param token the token to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for claimable funding amount by account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableFundingAmountKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_FUNDING_AMOUNT,
            market,
            token,
            account
        ));
    }

    // @dev key for claimable collateral amount
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_AMOUNT,
            market,
            token
        ));
    }

    // @dev key for claimable collateral amount for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralAmountKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_AMOUNT,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for claimable collateral factor for a timeKey
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(address market, address token, uint256 timeKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_FACTOR,
            market,
            token,
            timeKey
        ));
    }

    // @dev key for claimable collateral factor for a timeKey for an account
    // @param market the market to check
    // @param token the token to check
    // @param timeKey the time key for the claimable amount
    // @param account the account to check
    // @return key for claimable funding amount
    function claimableCollateralFactorKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMABLE_COLLATERAL_FACTOR,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for claimable collateral factor
    // @param market the market to check
    // @param token the token to check
    // @param account the account to check
    // @param timeKey the time key for the claimable amount
    // @return key for claimable funding amount
    function claimedCollateralAmountKey(address market, address token, uint256 timeKey, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CLAIMED_COLLATERAL_AMOUNT,
            market,
            token,
            timeKey,
            account
        ));
    }

    // @dev key for borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for borrowing factor
    function borrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev the key for borrowing exponent
    // @param market the market for the pool
    // @param isLong whether to get the key for the long or short side
    function borrowingExponentFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            BORROWING_EXPONENT_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for cumulative borrowing factor
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor
    function cumulativeBorrowingFactorKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR,
            market,
            isLong
        ));
    }

    // @dev key for cumulative borrowing factor updated at
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for cumulative borrowing factor updated at
    function cumulativeBorrowingFactorUpdatedAtKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            CUMULATIVE_BORROWING_FACTOR_UPDATED_AT,
            market,
            isLong
        ));
    }

    // @dev key for total borrowing amount
    // @param market the market to check
    // @param isLong whether to get the key for the long or short side
    // @return key for total borrowing amount
    function totalBorrowingKey(address market, bool isLong) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            TOTAL_BORROWING,
            market,
            isLong
        ));
    }

    // @dev key for affiliate reward amount
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(address market, address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AFFILIATE_REWARD,
            market,
            token
        ));
    }

    function maxAllowedSubaccountActionCountKey(address account, address subaccount, bytes32 actionType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MAX_ALLOWED_SUBACCOUNT_ACTION_COUNT,
            account,
            subaccount,
            actionType
        ));
    }

    function subaccountActionCountKey(address account, address subaccount, bytes32 actionType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_ACTION_COUNT,
            account,
            subaccount,
            actionType
        ));
    }

    function subaccountAutoTopUpAmountKey(address account, address subaccount) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            SUBACCOUNT_AUTO_TOP_UP_AMOUNT,
            account,
            subaccount
        ));
    }

    // @dev key for affiliate reward amount for an account
    // @param market the market to check
    // @param token the token to get the key for
    // @param account the account to get the key for
    // @return key for affiliate reward amount
    function affiliateRewardKey(address market, address token, address account) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            AFFILIATE_REWARD,
            market,
            token,
            account
        ));
    }

    // @dev key for is market disabled
    // @param market the market to check
    // @return key for is market disabled
    function isMarketDisabledKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            IS_MARKET_DISABLED,
            market
        ));
    }

    // @dev key for min market tokens for first deposit
    // @param market the market to check
    // @return key for min market tokens for first deposit
    function minMarketTokensForFirstDepositKey(address market) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            MIN_MARKET_TOKENS_FOR_FIRST_DEPOSIT,
            market
        ));
    }

    // @dev key for price feed address
    // @param token the token to get the key for
    // @return key for price feed address
    function priceFeedKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED,
            token
        ));
    }

    // @dev key for realtime feed ID
    // @param token the token to get the key for
    // @return key for realtime feed ID
    function realtimeFeedIdKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            REALTIME_FEED_ID,
            token
        ));
    }

    // @dev key for realtime feed multiplier
    // @param token the token to get the key for
    // @return key for realtime feed multiplier
    function realtimeFeedMultiplierKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            REALTIME_FEED_MULTIPLIER,
            token
        ));
    }

    // @dev key for price feed multiplier
    // @param token the token to get the key for
    // @return key for price feed multiplier
    function priceFeedMultiplierKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED_MULTIPLIER,
            token
        ));
    }

    function priceFeedHeartbeatDurationKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            PRICE_FEED_HEARTBEAT_DURATION,
            token
        ));
    }

    // @dev key for stable price value
    // @param token the token to get the key for
    // @return key for stable price value
    function stablePriceKey(address token) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            STABLE_PRICE,
            token
        ));
    }

    // @dev key for fee distributor swap token index
    // @param orderKey the swap order key
    // @return key for fee distributor swap token index
    function feeDistributorSwapTokenIndexKey(bytes32 orderKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FEE_DISTRIBUTOR_SWAP_TOKEN_INDEX,
            orderKey
        ));
    }

    // @dev key for fee distributor swap fee batch key
    // @param orderKey the swap order key
    // @return key for fee distributor swap fee batch key
    function feeDistributorSwapFeeBatchKey(bytes32 orderKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            FEE_DISTRIBUTOR_SWAP_FEE_BATCH,
            orderKey
        ));
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.20;

interface IGmxExchangeRouter {
    error CollateralAlreadyClaimed(
        uint256 adjustedClaimableAmount,
        uint256 claimedAmount
    );
    error DisabledFeature(bytes32 key);
    error DisabledMarket(address market);
    error EmptyAddressInMarketTokenBalanceValidation(
        address market,
        address token
    );
    error EmptyDeposit();
    error EmptyHoldingAddress();
    error EmptyMarket();
    error EmptyOrder();
    error EmptyReceiver();
    error EmptyTokenTranferGasLimit(address token);
    error InvalidClaimAffiliateRewardsInput(
        uint256 marketsLength,
        uint256 tokensLength
    );
    error InvalidClaimCollateralInput(
        uint256 marketsLength,
        uint256 tokensLength,
        uint256 timeKeysLength
    );
    error InvalidClaimFundingFeesInput(
        uint256 marketsLength,
        uint256 tokensLength
    );
    error InvalidClaimUiFeesInput(uint256 marketsLength, uint256 tokensLength);
    error InvalidMarketTokenBalance(
        address market,
        address token,
        uint256 balance,
        uint256 expectedMinBalance
    );
    error InvalidMarketTokenBalanceForClaimableFunding(
        address market,
        address token,
        uint256 balance,
        uint256 claimableFundingFeeAmount
    );
    error InvalidMarketTokenBalanceForCollateralAmount(
        address market,
        address token,
        uint256 balance,
        uint256 collateralAmount
    );
    error InvalidUiFeeFactor(uint256 uiFeeFactor, uint256 maxUiFeeFactor);
    error TokenTransferError(address token, address receiver, uint256 amount);
    error Unauthorized(address msgSender, string role);

    function cancelDeposit(bytes32 key) external payable;

    function cancelOrder(bytes32 key) external payable;

    function cancelWithdrawal(bytes32 key) external payable;

    function claimAffiliateRewards(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimCollateral(
        address[] memory markets,
        address[] memory tokens,
        uint256[] memory timeKeys,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimUiFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function createDeposit(DepositUtils.CreateDepositParams memory params)
        external
        payable
        returns (bytes32);

    function createOrder(BaseOrderUtils.CreateOrderParams memory params)
        external
        payable
        returns (bytes32);

    function createWithdrawal(
        WithdrawalUtils.CreateWithdrawalParams memory params
    ) external payable returns (bytes32);

    function dataStore() external view returns (address);

    function depositHandler() external view returns (address);

    function eventEmitter() external view returns (address);

    function multicall(bytes[] memory data)
        external
        payable
        returns (bytes[] memory results);

    function orderHandler() external view returns (address);

    function roleStore() external view returns (address);

    function router() external view returns (address);

    function sendNativeToken(address receiver, uint256 amount) external payable;

    function sendTokens(
        address token,
        address receiver,
        uint256 amount
    ) external payable;

    function sendWnt(address receiver, uint256 amount) external payable;

    function setSavedCallbackContract(address market, address callbackContract)
        external
        payable;

    function setUiFeeFactor(uint256 uiFeeFactor) external payable;

    function simulateExecuteDeposit(
        bytes32 key,
        OracleUtils.SimulatePricesParams memory simulatedOracleParams
    ) external payable;

    function simulateExecuteOrder(
        bytes32 key,
        OracleUtils.SimulatePricesParams memory simulatedOracleParams
    ) external payable;

    function simulateExecuteWithdrawal(
        bytes32 key,
        OracleUtils.SimulatePricesParams memory simulatedOracleParams
    ) external payable;

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external payable;

    function withdrawalHandler() external view returns (address);
}

interface DepositUtils {
    struct CreateDepositParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialLongToken;
        address initialShortToken;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minMarketTokens;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }
}

enum OrderType {
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    MarketSwap,
    // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
    LimitSwap,
    // @dev MarketIncrease: increase position at the current market price
    // the order will be cancelled if the position cannot be increased at the acceptablePrice
    MarketIncrease,
    // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitIncrease,
    // @dev MarketDecrease: decrease position at the current market price
    // the order will be cancelled if the position cannot be decreased at the acceptablePrice
    MarketDecrease,
    // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    LimitDecrease,
    // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
    StopLossDecrease,
    // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
    Liquidation
}

enum DecreasePositionSwapType {
    NoSwap,
    SwapPnlTokenToCollateralToken,
    SwapCollateralTokenToPnlToken
}

interface BaseOrderUtils {
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        uint8 orderType;
        uint8 decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }
}

interface WithdrawalUtils {
    struct CreateWithdrawalParams {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address[] longTokenSwapPath;
        address[] shortTokenSwapPath;
        uint256 minLongTokenAmount;
        uint256 minShortTokenAmount;
        bool shouldUnwrapNativeToken;
        uint256 executionFee;
        uint256 callbackGasLimit;
    }
}

interface Price {
    struct Props {
        uint256 min;
        uint256 max;
    }
}

interface OracleUtils {
    struct SimulatePricesParams {
        address[] primaryTokens;
        Price.Props[] primaryPrices;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"contract Router","name":"_router","type":"address"},{"internalType":"contract RoleStore","name":"_roleStore","type":"address"},{"internalType":"contract DataStore","name":"_dataStore","type":"address"},{"internalType":"contract EventEmitter","name":"_eventEmitter","type":"address"},{"internalType":"contract IDepositHandler","name":"_depositHandler","type":"address"},{"internalType":"contract IWithdrawalHandler","name":"_withdrawalHandler","type":"address"},{"internalType":"contract IOrderHandler","name":"_orderHandler","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[{"internalType":"uint256","name":"adjustedClaimableAmount","type":"uint256"},{"internalType":"uint256","name":"claimedAmount","type":"uint256"}],"name":"CollateralAlreadyClaimed","type":"error"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"DisabledFeature","type":"error"},{"inputs":[{"internalType":"address","name":"market","type":"address"}],"name":"DisabledMarket","type":"error"},{"inputs":[{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"token","type":"address"}],"name":"EmptyAddressInMarketTokenBalanceValidation","type":"error"},{"inputs":[],"name":"EmptyDeposit","type":"error"},{"inputs":[],"name":"EmptyHoldingAddress","type":"error"},{"inputs":[],"name":"EmptyMarket","type":"error"},{"inputs":[],"name":"EmptyOrder","type":"error"},{"inputs":[],"name":"EmptyReceiver","type":"error"},{"inputs":[{"internalType":"address","name":"token","type":"address"}],"name":"EmptyTokenTranferGasLimit","type":"error"},{"inputs":[{"internalType":"uint256","name":"marketsLength","type":"uint256"},{"internalType":"uint256","name":"tokensLength","type":"uint256"}],"name":"InvalidClaimAffiliateRewardsInput","type":"error"},{"inputs":[{"internalType":"uint256","name":"marketsLength","type":"uint256"},{"internalType":"uint256","name":"tokensLength","type":"uint256"},{"internalType":"uint256","name":"timeKeysLength","type":"uint256"}],"name":"InvalidClaimCollateralInput","type":"error"},{"inputs":[{"internalType":"uint256","name":"marketsLength","type":"uint256"},{"internalType":"uint256","name":"tokensLength","type":"uint256"}],"name":"InvalidClaimFundingFeesInput","type":"error"},{"inputs":[{"internalType":"uint256","name":"marketsLength","type":"uint256"},{"internalType":"uint256","name":"tokensLength","type":"uint256"}],"name":"InvalidClaimUiFeesInput","type":"error"},{"inputs":[{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"balance","type":"uint256"},{"internalType":"uint256","name":"expectedMinBalance","type":"uint256"}],"name":"InvalidMarketTokenBalance","type":"error"},{"inputs":[{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"balance","type":"uint256"},{"internalType":"uint256","name":"claimableFundingFeeAmount","type":"uint256"}],"name":"InvalidMarketTokenBalanceForClaimableFunding","type":"error"},{"inputs":[{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"token","type":"address"},{"internalType":"uint256","name":"balance","type":"uint256"},{"internalType":"uint256","name":"collateralAmount","type":"uint256"}],"name":"InvalidMarketTokenBalanceForCollateralAmount","type":"error"},{"inputs":[{"internalType":"uint256","name":"uiFeeFactor","type":"uint256"},{"internalType":"uint256","name":"maxUiFeeFactor","type":"uint256"}],"name":"InvalidUiFeeFactor","type":"error"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"TokenTransferError","type":"error"},{"inputs":[{"internalType":"address","name":"msgSender","type":"address"},{"internalType":"string","name":"role","type":"string"}],"name":"Unauthorized","type":"error"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"cancelDeposit","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"cancelOrder","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"}],"name":"cancelWithdrawal","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address[]","name":"markets","type":"address[]"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"address","name":"receiver","type":"address"}],"name":"claimAffiliateRewards","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address[]","name":"markets","type":"address[]"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"timeKeys","type":"uint256[]"},{"internalType":"address","name":"receiver","type":"address"}],"name":"claimCollateral","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address[]","name":"markets","type":"address[]"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"address","name":"receiver","type":"address"}],"name":"claimFundingFees","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address[]","name":"markets","type":"address[]"},{"internalType":"address[]","name":"tokens","type":"address[]"},{"internalType":"address","name":"receiver","type":"address"}],"name":"claimUiFees","outputs":[{"internalType":"uint256[]","name":"","type":"uint256[]"}],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"receiver","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"initialLongToken","type":"address"},{"internalType":"address","name":"initialShortToken","type":"address"},{"internalType":"address[]","name":"longTokenSwapPath","type":"address[]"},{"internalType":"address[]","name":"shortTokenSwapPath","type":"address[]"},{"internalType":"uint256","name":"minMarketTokens","type":"uint256"},{"internalType":"bool","name":"shouldUnwrapNativeToken","type":"bool"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"callbackGasLimit","type":"uint256"}],"internalType":"struct DepositUtils.CreateDepositParams","name":"params","type":"tuple"}],"name":"createDeposit","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"components":[{"internalType":"address","name":"receiver","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"initialCollateralToken","type":"address"},{"internalType":"address[]","name":"swapPath","type":"address[]"}],"internalType":"struct BaseOrderUtils.CreateOrderParamsAddresses","name":"addresses","type":"tuple"},{"components":[{"internalType":"uint256","name":"sizeDeltaUsd","type":"uint256"},{"internalType":"uint256","name":"initialCollateralDeltaAmount","type":"uint256"},{"internalType":"uint256","name":"triggerPrice","type":"uint256"},{"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"callbackGasLimit","type":"uint256"},{"internalType":"uint256","name":"minOutputAmount","type":"uint256"}],"internalType":"struct BaseOrderUtils.CreateOrderParamsNumbers","name":"numbers","type":"tuple"},{"internalType":"enum Order.OrderType","name":"orderType","type":"uint8"},{"internalType":"enum Order.DecreasePositionSwapType","name":"decreasePositionSwapType","type":"uint8"},{"internalType":"bool","name":"isLong","type":"bool"},{"internalType":"bool","name":"shouldUnwrapNativeToken","type":"bool"},{"internalType":"bytes32","name":"referralCode","type":"bytes32"}],"internalType":"struct BaseOrderUtils.CreateOrderParams","name":"params","type":"tuple"}],"name":"createOrder","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"payable","type":"function"},{"inputs":[{"components":[{"internalType":"address","name":"receiver","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"},{"internalType":"address","name":"uiFeeReceiver","type":"address"},{"internalType":"address","name":"market","type":"address"},{"internalType":"address[]","name":"longTokenSwapPath","type":"address[]"},{"internalType":"address[]","name":"shortTokenSwapPath","type":"address[]"},{"internalType":"uint256","name":"minLongTokenAmount","type":"uint256"},{"internalType":"uint256","name":"minShortTokenAmount","type":"uint256"},{"internalType":"bool","name":"shouldUnwrapNativeToken","type":"bool"},{"internalType":"uint256","name":"executionFee","type":"uint256"},{"internalType":"uint256","name":"callbackGasLimit","type":"uint256"}],"internalType":"struct WithdrawalUtils.CreateWithdrawalParams","name":"params","type":"tuple"}],"name":"createWithdrawal","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"dataStore","outputs":[{"internalType":"contract DataStore","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"depositHandler","outputs":[{"internalType":"contract IDepositHandler","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"eventEmitter","outputs":[{"internalType":"contract EventEmitter","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes[]","name":"data","type":"bytes[]"}],"name":"multicall","outputs":[{"internalType":"bytes[]","name":"results","type":"bytes[]"}],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"orderHandler","outputs":[{"internalType":"contract IOrderHandler","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"roleStore","outputs":[{"internalType":"contract RoleStore","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"router","outputs":[{"internalType":"contract Router","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"receiver","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"sendNativeToken","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"token","type":"address"},{"internalType":"address","name":"receiver","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"sendTokens","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"receiver","type":"address"},{"internalType":"uint256","name":"amount","type":"uint256"}],"name":"sendWnt","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"market","type":"address"},{"internalType":"address","name":"callbackContract","type":"address"}],"name":"setSavedCallbackContract","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"uiFeeFactor","type":"uint256"}],"name":"setUiFeeFactor","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"components":[{"internalType":"address[]","name":"primaryTokens","type":"address[]"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props[]","name":"primaryPrices","type":"tuple[]"}],"internalType":"struct OracleUtils.SimulatePricesParams","name":"simulatedOracleParams","type":"tuple"}],"name":"simulateExecuteDeposit","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"components":[{"internalType":"address[]","name":"primaryTokens","type":"address[]"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props[]","name":"primaryPrices","type":"tuple[]"}],"internalType":"struct OracleUtils.SimulatePricesParams","name":"simulatedOracleParams","type":"tuple"}],"name":"simulateExecuteOrder","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"components":[{"internalType":"address[]","name":"primaryTokens","type":"address[]"},{"components":[{"internalType":"uint256","name":"min","type":"uint256"},{"internalType":"uint256","name":"max","type":"uint256"}],"internalType":"struct Price.Props[]","name":"primaryPrices","type":"tuple[]"}],"internalType":"struct OracleUtils.SimulatePricesParams","name":"simulatedOracleParams","type":"tuple"}],"name":"simulateExecuteWithdrawal","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"key","type":"bytes32"},{"internalType":"uint256","name":"sizeDeltaUsd","type":"uint256"},{"internalType":"uint256","name":"acceptablePrice","type":"uint256"},{"internalType":"uint256","name":"triggerPrice","type":"uint256"},{"internalType":"uint256","name":"minOutputAmount","type":"uint256"}],"name":"updateOrder","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"withdrawalHandler","outputs":[{"internalType":"contract IWithdrawalHandler","name":"","type":"address"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {Initializable} from "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self || // Must be called through delegatecall
            ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {IBeacon} from "../beacon/IBeacon.sol";
import {Address} from "../../utils/Address.sol";
import {StorageSlot} from "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev The `admin` of the proxy is invalid.
     */
    error ERC1967InvalidAdmin(address admin);

    /**
     * @dev The `beacon` of the proxy is invalid.
     */
    error ERC1967InvalidBeacon(address beacon);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using
     * the https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0)) {
            revert ERC1967InvalidAdmin(address(0));
        }
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {IERC1967-AdminChanged} event.
     */
    function changeAdmin(address newAdmin) internal {
        emit AdminChanged(getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is the keccak-256 hash of "eip1967.proxy.beacon" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (newBeacon.code.length == 0) {
            revert ERC1967InvalidBeacon(newBeacon);
        }

        StorageSlot.getAddressSlot(BEACON_SLOT).value = newBeacon;

        address beaconImplementation = IBeacon(newBeacon).implementation();
        if (beaconImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(beaconImplementation);
        }
    }

    /**
     * @dev Change the beacon and trigger a setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-BeaconUpgraded} event.
     *
     * CAUTION: Invoking this function has no effect on an instance of {BeaconProxy} since v5, since
     * it uses an immutable beacon without looking at the value of the ERC-1967 beacon slot for
     * efficiency.
     */
    function upgradeBeaconToAndCall(address newBeacon, bytes memory data) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);

        if (data.length > 0) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {UpgradeableBeacon} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}