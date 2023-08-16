// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {CamelotSwapper} from "./libraries/CamelotSwapper.sol";
import {SushiSwapper} from "./libraries/SushiSwapper.sol";
import {UniswapV3Swapper} from "./libraries/UniswapV3Swapper.sol";
import {IErrors} from "../interfaces/IErrors.sol";
import {IRouter} from "./interfaces/IRouter.sol";

/// @title SwapRouter
/// @notice A contract that swaps tokens on selected DEX
contract SwapRouter is IRouter, UniswapV3Swapper {
    function swap(
        PathRoute memory path,
        uint256 amount,
        address receiver
    ) external returns (uint256 amountOut) {
        if (path.route == 1) {
            amountOut = CamelotSwapper._swapOnCamelot(
                path.bestPath,
                amount,
                path.toAmountMin,
                receiver
            );
        } else if (path.route == 2) {
            amountOut = SushiSwapper._swapOnSushi(
                path.bestPath,
                amount,
                path.toAmountMin,
                receiver
            );
        } else if (path.route == 3) {
            amountOut = _swapOnUniswapV3(
                path.bestPath,
                path.fee,
                amount,
                path.toAmountMin,
                receiver
            );
        } else revert IErrors.InvalidPath();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {ICamelotPair} from "../interfaces/ICamelotPair.sol";
import {IErrors} from "../../interfaces/IErrors.sol";

/// @title Camelot Swapper
/// @notice Tokens can be swapped on Camelot and deposited into Y2K vaults
library CamelotSwapper {
    using SafeTransferLib for ERC20;

    /////////////////////////////////////////
    //        PUBLIC FUNCTIONS             //
    /////////////////////////////////////////
    /** @notice Calculates the amounts to be received, pairs addresses, and swaps with each pair
        @param path The array of token addresses to swap between
        @param fromAmount The amount of fromToken to swap
        @param toAmountMin The minimum amount of destination token to receive
        @return amountOut The amount of destination token being received
    **/
    function _swapOnCamelot(
        address[] memory path,
        uint256 fromAmount,
        uint256 toAmountMin,
        address receiver
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = new uint256[](path.length - 1);
        address[] memory pairs = new address[](path.length - 1);

        amountOut = fromAmount;
        for (uint256 i = 0; i < path.length - 1; ) {
            {
                address fromToken = path[i];
                address toToken = path[i + 1];

                pairs[i] = _getPair(fromToken, toToken);
                (uint256 reserveA, uint256 reserveB, , ) = ICamelotPair(
                    pairs[i]
                ).getReserves();

                if (fromToken > toToken)
                    (reserveA, reserveB) = (reserveB, reserveA);

                // NOTE: Need to query the fee percent set by Camelot
                amounts[i] = ICamelotPair(pairs[i]).getAmountOut(
                    amountOut,
                    fromToken
                );
                amountOut = amounts[i];
            }

            unchecked {
                i++;
            }
        }

        if (amounts[amounts.length - 1] < toAmountMin)
            revert IErrors.InvalidMinOut(amounts[amounts.length - 1]);

        SafeTransferLib.safeTransfer(ERC20(path[0]), pairs[0], fromAmount);

        return _executeSwap(path, pairs, amounts, receiver);
    }

    /** @notice Simulates the address for the pair of two tokens
        @param tokenA The address of the first token
        @param tokenB The address of the second token
        @return pair The address of the pair
    **/
    function _getPair(
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            0x6EcCab422D763aC031210895C81787E87B43A652,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            hex"a856464ae65f7619087bc369daaf7e387dae1e5af69cfa7935850ebf754b04c1" // init code hash
                        )
                    )
                )
            )
        );
    }

    /** @notice Executes swaps on Camelot
        @param path The array of token addresses to swap between
        @param pairs The array of pairs to swap through
        @param amounts The array of amounts to swap with each pair 
        @return The amount of destination token being received
    **/
    function _executeSwap(
        address[] memory path,
        address[] memory pairs,
        uint256[] memory amounts,
        address receiver
    ) internal returns (uint256) {
        bool zeroForOne = path[0] < path[1];
        if (pairs.length > 1) {
            ICamelotPair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                pairs[1],
                ""
            );
            for (uint256 i = 1; i < pairs.length - 1; ) {
                zeroForOne = path[i] < path[i + 1];
                ICamelotPair(pairs[i]).swap(
                    zeroForOne ? 0 : amounts[i],
                    zeroForOne ? amounts[i] : 0,
                    pairs[i + 1],
                    ""
                );
                unchecked {
                    i++;
                }
            }
            zeroForOne = path[path.length - 2] < path[path.length - 1];
            ICamelotPair(pairs[pairs.length - 1]).swap(
                zeroForOne ? 0 : amounts[pairs.length - 1],
                zeroForOne ? amounts[pairs.length - 1] : 0,
                receiver,
                ""
            );
        } else {
            ICamelotPair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                receiver,
                ""
            );
        }

        return amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {IErrors} from "../../interfaces/IErrors.sol";

/// @title UniswapV2 Swapper
/// @notice Tokens can be swapped on UniswapV2 and deposited into Y2K vaults
library SushiSwapper {
    using SafeTransferLib for ERC20;

    /////////////////////////////////////////
    //        PUBLIC FUNCTIONS             //
    /////////////////////////////////////////
    function _swapOnSushi(
        address[] memory path,
        uint256 fromAmount,
        uint256 toAmountMin,
        address receiver
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = new uint256[](path.length - 1);
        address[] memory pairs = new address[](path.length - 1);

        // NOTE: Use amountOut to reduce declaration of additional variable
        amountOut = fromAmount;
        for (uint256 i = 0; i < path.length - 1; ) {
            {
                address fromToken = path[i];
                address toToken = path[i + 1];

                pairs[i] = _getPair(fromToken, toToken);
                (uint256 reserveA, uint256 reserveB, ) = IUniswapV2Pair(
                    pairs[i]
                ).getReserves();

                if (fromToken > toToken)
                    (reserveA, reserveB) = (reserveB, reserveA);

                amounts[i] =
                    ((amountOut * 997) * reserveB) /
                    ((reserveA * 1000) + (amountOut * 997));
                amountOut = amounts[i];
            }

            unchecked {
                i++;
            }
        }

        if (amounts[amounts.length - 1] < toAmountMin)
            revert IErrors.InvalidMinOut(amounts[amounts.length - 1]);

        SafeTransferLib.safeTransfer(ERC20(path[0]), pairs[0], fromAmount);

        return _executeSwap(path, pairs, amounts, receiver);
    }

    /** @notice Simulates the address for the pair of two tokens
        @param tokenA The address of the first token
        @param tokenB The address of the second token
        @return pair The address of the pair
    **/
    function _getPair(
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            0xc35DADB65012eC5796536bD9864eD8773aBc74C4,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                        )
                    )
                )
            )
        );
    }

    /** @notice Executes swaps on UniswapV2 fork
        @param path The array of token addresses to swap between
        @param pairs The array of pairs to swap through
        @param amounts The array of amounts to swap with each pair 
        @return The amount of destination token being received
    **/
    function _executeSwap(
        address[] memory path,
        address[] memory pairs,
        uint256[] memory amounts,
        address receiver
    ) internal returns (uint256) {
        bool zeroForOne = path[0] < path[1];
        if (pairs.length > 1) {
            IUniswapV2Pair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                pairs[1],
                ""
            );
            for (uint256 i = 1; i < pairs.length - 1; ) {
                zeroForOne = path[i] < path[i + 1];
                IUniswapV2Pair(pairs[i]).swap(
                    zeroForOne ? 0 : amounts[i],
                    zeroForOne ? amounts[i] : 0,
                    pairs[i + 1],
                    ""
                );
                unchecked {
                    i++;
                }
            }
            zeroForOne = path[path.length - 2] < path[path.length - 1];
            IUniswapV2Pair(pairs[pairs.length - 1]).swap(
                zeroForOne ? 0 : amounts[pairs.length - 1],
                zeroForOne ? amounts[pairs.length - 1] : 0,
                receiver,
                ""
            );
        } else {
            IUniswapV2Pair(pairs[0]).swap(
                zeroForOne ? 0 : amounts[0],
                zeroForOne ? amounts[0] : 0,
                receiver,
                ""
            );
        }

        return amounts[amounts.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "lib/solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "lib/solmate/src/utils/SafeTransferLib.sol";
import {BytesLib} from "./BytesLib.sol";
import {IUniswapV3Pool} from "../interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Callback} from "../interfaces/IUniswapV3Callback.sol";
import {IErrors} from "../../interfaces/IErrors.sol";

/// @title UniswapV3Swapper
/// @notice A contract that swaps tokens on Uniswap V3
contract UniswapV3Swapper is IUniswapV3Callback {
    using SafeTransferLib for ERC20;
    using BytesLib for bytes;

    /// @notice The address of the Uniswap V3 factory on Arbitrum
    address public constant UNISWAP_V3_FACTORY =
        0x1F98431c8aD98523631AE4a59f267346ea31F984;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant _MIN_SQRT_RATIO = 4295128740;

    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant _MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970341;
    bytes32 internal constant _POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /////////////////////////////////////////
    //        PUBLIC FUNCTIONS             //
    /////////////////////////////////////////
    /** @notice The callback implementation for UniswapV3 pools
        @param amount0Delta The amount of token0 received
        @param amount1Delta The amount of token1 received
        @param _data The encoded pool address, fee, and tokenOut address
    **/
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata _data
    ) external override {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported
        (address tokenIn, address tokenOut, uint24 fee) = decodePool(_data);

        if (msg.sender != getPool(tokenIn, tokenOut, fee))
            revert IErrors.InvalidCaller();

        SafeTransferLib.safeTransfer(
            ERC20(tokenIn),
            msg.sender,
            amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta)
        );
    }

    /////////////////////////////////////////
    //    INTERNAL & PRIVATE FUNCTIONS     //
    /////////////////////////////////////////
    /** @notice Decodes the payload and conducts the swaps
        @param fromAmount The amount of the fromToken being swapped
        @param toAmountMin The minimum amount of the toToken to receive
        @param path The path of the swap
        @param fee The fee of the swap
        @param receiver The address to receive the swapped tokens
        @return amountOut The amount of the toToken received
    **/
    function _swapOnUniswapV3(
        address[] memory path,
        uint24[] memory fee,
        uint256 fromAmount,
        uint256 toAmountMin,
        address receiver
    ) internal returns (uint256 amountOut) {
        if (path.length > 2) {
            amountOut = _executeSwap(
                path[0],
                path[1],
                fromAmount,
                fee[0],
                address(this)
            );
            for (uint256 i = 1; i < path.length - 2; ) {
                amountOut = _executeSwap(
                    path[i],
                    path[i + 1],
                    amountOut,
                    fee[i],
                    address(this)
                );
                unchecked {
                    i++;
                }
            }
            amountOut = _executeSwap(
                path[path.length - 2],
                path[path.length - 1],
                amountOut,
                fee[path.length - 2],
                receiver
            );
        } else {
            amountOut = _executeSwap(
                path[0],
                path[1],
                fromAmount,
                fee[0],
                receiver
            );
        }

        if (amountOut < toAmountMin) revert IErrors.InvalidMinOut(amountOut);
    }

    /** @notice Executes the swap with the simulated V3 pool from tokenIn, tokenOut, and fee
        @param tokenIn The address of the fromToken
        @param tokenOut The address of the toToken
        @param fromAmount The amount of fromToken to swap
        @param fee The fee for the pool
        @return The amount of toToken received
    **/
    function _executeSwap(
        address tokenIn,
        address tokenOut,
        uint256 fromAmount,
        uint24 fee,
        address receiver
    ) internal returns (uint256) {
        bool zeroForOne = tokenIn < tokenOut;

        if (zeroForOne) {
            (, int256 amountOut) = IUniswapV3Pool(
                getPool(tokenIn, tokenOut, fee)
            ).swap(
                    receiver,
                    zeroForOne,
                    int256(fromAmount),
                    _MIN_SQRT_RATIO,
                    abi.encodePacked(tokenIn, fee, tokenOut)
                );
            return uint256(-amountOut);
        } else {
            (int256 amountOut, ) = IUniswapV3Pool(
                getPool(tokenIn, tokenOut, fee)
            ).swap(
                    receiver,
                    zeroForOne,
                    int256(fromAmount),
                    _MAX_SQRT_RATIO,
                    abi.encodePacked(tokenIn, fee, tokenOut)
                );
            return uint256(-amountOut);
        }
    }

    /** @notice Simulates the address for the pool of two tokens
        @param tokenA The address of the first token
        @param tokenB The address of the second token
        @param fee The fee for the pool
        @return pool The address of the pool
    **/
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            UNISWAP_V3_FACTORY,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            _POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /** @notice Decodes bytes to retrieve the fee and token addresses
        @param path The encoded data for fee and tokens
        @return tokenA tokenB fee
    **/
    function decodePool(
        bytes memory path
    ) internal pure returns (address tokenA, address tokenB, uint24 fee) {
        tokenA = path.toAddress(0);
        fee = path.toUint24(20);
        tokenB = path.toAddress(23);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IErrors {
    // Generic Errors
    error InvalidInput();
    error InsufficientBalance();

    // Vault Errors
    error VaultNotApproved();
    error FundsNotDeployed();
    error FundsAlreadyDeployed();
    error InvalidLengths();
    error InvalidUnqueueAmount();
    error InvalidWeightId();
    error InvalidQueueSize();
    error InvalidQueueId();
    error InvalidArrayLength();
    error InvalidDepositAmount();
    error ZeroShares();
    error QueuedAmountInsufficient();
    error NoQueuedWithdrawals();
    error QueuedWithdrawalPending();
    error UnableToUnqueue();
    error PositionClosePending();

    // Hook Errors
    error Unauthorized();
    error VaultSet();
    error AssetIdNotSet();
    error InvalidPathCount();
    error OutdatedPathInfo();
    error InvalidToken();

    // Queue Contract Errors
    error InvalidAsset();

    // Getter Errors
    error InvalidVaultAddress();
    error InvalidVaultAsset();
    error InvalidVaultEmissions();
    error MarketNotExist();
    error InvalidVaultController();
    error InvalidVaultCounterParty();
    error InvalidTreasury();

    // Position Sizer
    error InvalidWeightStrategy();
    error ProportionUnassigned();
    error LengthMismatch();
    error NoValidThreshold();

    // DEX Errors
    error InvalidPath();
    error InvalidCaller();
    error InvalidMinOut(uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IRouter {
    struct Path {
        uint256 updated;
        PathRoute BToD; // Borrow to deposit
        PathRoute DToB; // Deposit to borrow
    }

    struct PathRoute {
        uint128 toAmountMin;
        uint8 route;
        address[] bestPath;
        uint24[] fee;
    }

    function swap(
        PathRoute memory path,
        uint256 amount,
        address receiver
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Append and mask the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument. Masking not required as it's a full 32 byte type.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICamelotPair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint16 _token0FeePercent,
            uint16 _token1FeePercent
        );

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getAmountOut(
        uint256 amountIn,
        address tokenIn
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getAmountOut(
        uint256 amountIn,
        address tokenIn
    ) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: MIT

/// @title Library for Bytes Manipulation
pragma solidity ^0.8.9;

library BytesLib {
    function toAddress(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (address tempAddress) {
        assembly {
            tempAddress := mload(add(add(_bytes, 0x14), _start))
        }
    }

    function toUint24(
        bytes memory _bytes,
        uint256 _start
    ) internal pure returns (uint24 amount) {
        assembly {
            amount := mload(add(add(_bytes, 0x3), _start))
        }
    }

    /// @param _bytes The bytes input
    /// @param _start The start index of the slice
    /// @param _length The length of the slice
    function sliceBytes(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory slicedBytes) {
        assembly {
            slicedBytes := mload(0x40)

            let lengthmod := and(_length, 31)

            let mc := add(
                add(slicedBytes, lengthmod),
                mul(0x20, iszero(lengthmod))
            )
            let end := add(mc, _length)

            for {
                let cc := add(
                    add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))),
                    _start
                )
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            mstore(slicedBytes, _length)
            mstore(0x40, and(add(mc, 31), not(31)))
        }
        return slicedBytes;
    }

    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    ) internal pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }
}

pragma solidity 0.8.18;

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3Callback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}