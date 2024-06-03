/**
 *Submitted for verification at Arbiscan.io on 2024-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address _to, uint256 _value) external returns (bool);
    function decimals() external view returns (uint256);
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

pragma solidity >=0.8.0;


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

struct TokenFees {
    uint256 buyFeeBps;
    uint256 sellFeeBps;
}

/// @notice Detects the buy and sell fee for a fee-on-transfer token
contract FeeOnTransferDetector {
    using SafeTransferLib for ERC20;

    error SameToken();
    error PairLookupFailed();

    uint256 constant BPS = 10_000;

    constructor() {}

    /// @notice detects FoT fees for a single token
    function validate(address token, address baseToken, uint256 amountToBorrow, address pairAddress)
        public
        returns (TokenFees memory fotResult)
    {
        return _validate(token, baseToken, amountToBorrow, pairAddress);
    }

    /// @notice detects FoT fees for a batch of tokens
    function batchValidate(address[] calldata tokens, address baseToken, uint256 amountToBorrow, address pairAddress)
        public
        returns (TokenFees[] memory fotResults)
    {
        fotResults = new TokenFees[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            fotResults[i] = _validate(tokens[i], baseToken, amountToBorrow, pairAddress);
        }
    }

    function _validate(address token, address baseToken, uint256 amountToBorrow, address pairAddress)
        internal
        returns (TokenFees memory result)
    {
        if (token == baseToken) {
            revert SameToken();
        }

        // If the token/baseToken pair exists, get token0.
        // Must do low level call as try/catch does not support case where contract does not exist.
        (, bytes memory returnData) = address(pairAddress).call(abi.encodeWithSelector(IUniswapV2Pair.token0.selector));

        if (returnData.length == 0) {
            revert PairLookupFailed();
        }

        address token0Address = abi.decode(returnData, (address));

        // Flash loan {amountToBorrow}
        (uint256 amount0Out, uint256 amount1Out) =
            token == token0Address ? (amountToBorrow, uint256(0)) : (uint256(0), amountToBorrow);

        uint256 balanceBeforeLoan = ERC20(token).balanceOf(address(this));

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        try pair.swap(amount0Out, amount1Out, address(this), abi.encode(balanceBeforeLoan, amountToBorrow)) {}
        catch (bytes memory reason) {
            result = parseRevertReason(reason);
        }
    }

    function parseRevertReason(bytes memory reason) private pure returns (TokenFees memory) {
        if (reason.length != 64) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (TokenFees));
        }
    }

    // External wrapper around safeTransfer
    function callTransfer(ERC20 token, address to, uint256 amount) external {
        token.safeTransfer(to, amount);
    }

    /// @notice Swaps through a list of pairs and returns the final token and amount
    function smartRoute(address[] calldata pairs, uint256 amountIn, address initialToken)
        external
        returns (address finalToken, uint256 finalAmount)
    {
        require(pairs.length > 0, "No pairs provided");

        (uint256 amount0Out, uint256 amount1Out) = _getAmountsOut(initialToken, amountIn, pairs[0]);

        // Initiate the flash loan with the first pair
        IUniswapV2Pair(pairs[0]).swap(amount0Out, amount1Out, address(this), abi.encode(pairs, amountIn, initialToken));

        (finalToken, finalAmount) = _getFinalTokenAndAmount(pairs, initialToken, amountIn);
    }

    function _dexCallback(address sender, uint256 amount0, uint256 amount1, bytes calldata data) internal {
        (address[] memory pairs, uint256 amountIn, address initialToken) = abi.decode(data, (address[], uint256, address));

        _performSwaps(pairs, initialToken, amountIn, sender);
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        _dexCallback(sender, amount0, amount1, data);
    }

    function pancakeCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        _dexCallback(sender, amount0, amount1, data);
    }

    function sushiCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        _dexCallback(sender, amount0, amount1, data);
    }

    function _getAmountsOut(address tokenIn, uint256 amountIn, address pair) internal view returns (uint256 amount0Out, uint256 amount1Out) {
        (address token0, address token1) = IUniswapV2Pair(pair).token0() == tokenIn ? (tokenIn, IUniswapV2Pair(pair).token1()) : (IUniswapV2Pair(pair).token0(), tokenIn);
        (amount0Out, amount1Out) = tokenIn == token0 ? (amountIn, uint256(0)) : (uint256(0), amountIn);
    }

    function _performSwaps(address[] memory pairs, address initialToken, uint256 amountIn, address sender) internal {
        address currentToken = initialToken;
        uint256 currentAmount = amountIn;

        for (uint256 i = 0; i < pairs.length; i++) {
            require(sender == pairs[i], "Invalid sender");

            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            (address token0, address token1) = (pair.token0(), pair.token1());

            (uint256 amount0Out, uint256 amount1Out) =
                currentToken == token0 ? (uint256(0), currentAmount) : (currentAmount, uint256(0));

            pair.swap(amount0Out, amount1Out, address(this), new bytes(0));

            currentToken = currentToken == token0 ? token1 : token0;
            currentAmount = ERC20(currentToken).balanceOf(address(this));

            if (i < pairs.length - 1) {
                ERC20(currentToken).approve(pairs[i + 1], currentAmount);
            }
        }

        _repayLoan(currentToken, currentAmount);
    }

    function _getFinalTokenAndAmount(address[] memory pairs, address initialToken, uint256 amountIn) internal view returns (address finalToken, uint256 finalAmount) {
        address currentToken = initialToken;
        uint256 currentAmount = amountIn;

        for (uint256 i = 0; i < pairs.length; i++) {
            IUniswapV2Pair pair = IUniswapV2Pair(pairs[i]);
            (address token0, address token1) = (pair.token0(), pair.token1());

            currentToken = currentToken == token0 ? token1 : token0;
            currentAmount = ERC20(currentToken).balanceOf(address(this));
        }

        finalToken = currentToken;
        finalAmount = currentAmount;
    }

    function _repayLoan(address finalToken, uint256 finalAmount) internal {
        ERC20(finalToken).transfer(msg.sender, finalAmount);

        uint256 profit = ERC20(finalToken).balanceOf(address(this)) - finalAmount;
        if (profit > 0) {
            ERC20(finalToken).transfer(tx.origin, profit);
        }
    }
}