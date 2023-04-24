/**
 *Submitted for verification at Arbiscan on 2023-04-24
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

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
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

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
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

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

contract Refund is ReentrancyGuard {
    using FixedPointMathLib for uint256;

    uint256 public totalRefunds;
    uint256 public constant totalRefundsWeight = 10.89 ether + 7.1415 ether;
    mapping(address => uint256) public refundsWeight;

    address public constant admin = 0x05340E6CD21F5e3B12DeFA9593d1C58A271E7b7B;

    constructor() {
        refundsWeight[0x8ff7cEDeE234a43dB49b87Ef04300a43009D5aA1] = 1 ether;
        refundsWeight[0xCB128eA7d057e02f26DcF6DCaC00EaA5ab5DEeb2] = 0.67 ether;
        refundsWeight[0x88c978E5d2e7319CC2E21f9460709DF7028E1D6e] = 0.59 ether;
        refundsWeight[0x4eA3588cF3F628D2F0902B2aB24843c2A3C11dd9] = 0.5 ether;
        refundsWeight[0x5b049c3Bef543a181A720DcC6fEbc9afdab5D377] = 0.5 ether;
        refundsWeight[0x240163239d99ca6572826Aa491F235728aBC335f] = 0.5 ether;
        refundsWeight[0x2FFa6b6c34c2c268aFD0E33e6b3d5B9ed3b7b034] = 0.46 ether;
        refundsWeight[0xdBE7DB333Afc08D2B1FCbA4947b1d647916f2f08] = 0.41 ether;
        refundsWeight[0xEA796013Ffc41a91Eb92BdaA02735F945BCeaC54] = 0.4 ether;
        refundsWeight[0xbA4F13f545022a4772E1F0fd2c00E25EC37cF667] = 0.4 ether;
        refundsWeight[0xF8318eeE38a5a1da616E7268Aec20Ce7E46A11ab] = 0.4 ether;
        refundsWeight[0xA69C7d711AD1D87a422Cc4DF2A43E8C6a25c03Be] = 0.39 ether;
        refundsWeight[0x93cdB0a93Fc36f6a53ED21eCf6305Ab80D06becA] = 0.29 ether;
        refundsWeight[0x1140E000BC127c1799040D8B61AfD822083274A3] = 0.27 ether;
        refundsWeight[0x23B88B1DE1d58bf36242B62A9c1A08bB62730258] = 0.26 ether;
        refundsWeight[0x89cE7BbbB0Acf4C373FE4C7FD51e6f0e410e12D8] = 0.5 ether;
        refundsWeight[0x901Ab2d7EBe247f2247DF9cC090f81714920E0ec] = 0.2 ether;
        refundsWeight[0x15752B992b5A9EaF61630dCe7B795534f72Dd739] = 0.2 ether;
        refundsWeight[0x2C9340D59D22D5C7C3eA7B35B01887046E89a450] = 0.2 ether;
        refundsWeight[0x84572C31ACdd30c03982e27b809D30b1eFbCD8f2] = 0.2 ether;
        refundsWeight[0xC7b25121f05457fd6eB6143950D653d4BeE15765] = 0.19 ether;
        refundsWeight[0x1b319e3f01805Ff2c54234868732F90d3c20E67D] = 0.15 ether;
        refundsWeight[0xCeA3ac59D5c47C0c864B4D3F1d4712B69B9149E0] = 0.12 ether;
        refundsWeight[0xa16d423D5F4680052DD568C8CC19903F85F6bA89] = 0.11 ether;
        refundsWeight[0x358d169cBA881C03E5754baF97873d5e32100Fcb] = 0.1 ether;
        refundsWeight[0xC1c8B1b7d53E1546AAAe05947eB1b381534E13f5] = 0.1 ether;
        refundsWeight[0x48D7227E04a62b1c9c216eBb7E2Eb422a5f13567] = 0.1 ether;
        refundsWeight[0xa8da5912dB11C6cAA2762473f0B5D3Dba6Aff992] = 0.1 ether;
        refundsWeight[0x37c6503732e8C8B9AF50Bd3755c3530f6B032Dfd] = 0.1 ether;
        refundsWeight[0x8C09aBE8cefA7346E6F69820A802c37047ba9382] = 0.1 ether;
        refundsWeight[0x3265a87200542D7fc68408723e3296DFc577C7F3] = 0.1 ether;
        refundsWeight[0x1F906aB7Bd49059d29cac759Bc84f9008dBF4112] = 0.1 ether;
        refundsWeight[0x422251eB379AC25c8a981ade561C22DE154D9575] = 0.08 ether;
        refundsWeight[0x65642b4A7ce06AB9b99ab1d344C6D1b529c9C039] = 0.07 ether;
        refundsWeight[0xE512cbB6cb2382c45bd47F34dF165601ffE1Aa00] = 0.07 ether;
        refundsWeight[0x8A7E87881FE4e345ee7Ab7d3c081a8aB98Bf645C] = 0.07 ether;
        refundsWeight[0x5e9A337E16DEe75e8d4DF5e626aA352fb1f1F745] = 0.06 ether;
        refundsWeight[0x369d78d707909bFE5168891Cf024fc979Aea84C6] = 0.06 ether;
        refundsWeight[0x28f1aaed8d452DDaac77c7B2f5aeC82935466BaC] = 0.06 ether;
        refundsWeight[0x2762D061C322771e7b12E63E8d3a9c3a3D1e4539] = 0.06 ether;
        refundsWeight[0x156A5Ab014C34A569ba23B4991A5aB349652B8B5] = 0.05 ether;
        refundsWeight[0x69904EEe814A8330edF58d123acbB7d84880CEF9] = 0.05 ether;
        refundsWeight[0x9A67BD909E9FBD36B78CDB6e7574ef8b23070EAd] = 0.05 ether;
        refundsWeight[0x20945694A79Bba6AE2FD3EC11663236319EC7854] = 0.05 ether;
        refundsWeight[0x16fe80ACE4c0C5159548d93449baDC1ccE8fe83f] = 0.05 ether;
        refundsWeight[0x1E6a88Eb72c7fE401E4E7CeF70f686E3aeE3d39E] = 0.05 ether;
        refundsWeight[0x3471C23E302CB6538921EC5655A0708781F9BAae] = 0.04 ether;
        refundsWeight[0x9c9E2555da511EFf3B48F18c3ee4D7320aB8D3b9] = 0.04 ether;
        refundsWeight[0xbf7604ed600e765eA2a322E269DcdD2D93cc8eBc] = 0.04 ether;
        refundsWeight[0x675CfC33F9A98E9fEB3d2cD3E7e76B26c40aDDF3] = 0.04 ether;
        refundsWeight[0x5AaB17e615fF3d8A4Ac32efA3b6925729D2955aE] = 0.04 ether;
        refundsWeight[0x6D5239106010e9A3A7d70404de49924d66d4e27B] = 0.04 ether;
        refundsWeight[0x36D75b48a700C2215097eaA41fCbDCa2FE91aBa7] = 0.03 ether;
        refundsWeight[0x1F9eF2B6fCc0cC4AB88369b9272891774a5e5c11] = 0.02 ether;
        refundsWeight[0xfC21D184B6B42C0698ed01E04ABd28331BEA0730] = 0.02 ether;
        refundsWeight[0x475b8edf7836aE843F862793d9e091E95cA26273] = 0.01 ether;
        refundsWeight[0x0DcE22998B74E89F0F9E34897884503B821108E8] = 0.01 ether;
        refundsWeight[0x2Ce5D659CD9dA83D64160ECD606fA12460ebB601] = 0.01 ether;
        refundsWeight[0x3769881A7a2C4C10a816cbcAd364c0560754E9C7] = 0.01 ether;
        refundsWeight[0x083EF906b2CAD19d603F4c58651af24E5c24FcFE] = 0.28 ether * 115 / 100;
        refundsWeight[0x44447dd5344Fd033a53d8179E840e8aE1F47EB38] = 0.3 ether * 115 / 100;
        refundsWeight[0xa42fB39955c30cd34bE723533CDD8056525cDE95] = 0.3 ether * 115 / 100;
        refundsWeight[0x11Ad3F9158691C5E49B100a8517E23cE98F1421f] = 0.3 ether * 115 / 100;
        refundsWeight[0x8Cfa8Dd7BD8a1316f145c52D842C09EaC212F642] = 0.3 ether * 115 / 100;
        refundsWeight[0x631794a6eed2d23087aF0182CD6d56B0304b8cDB] = 0.28 ether * 115 / 100;
        refundsWeight[0x7CD593c4d6A2f484345468BB4F3CAfe0Dfa5ACCE] = 0.28 ether * 115 / 100;
        refundsWeight[0xE874946c5876E5e6a9Fbc1e17DB759e06E3B3ffe] = 0.27 ether * 115 / 100;
        refundsWeight[0x05340E6CD21F5e3B12DeFA9593d1C58A271E7b7B] = 0.3 ether * 115 / 100;
        refundsWeight[0x2891F651ffb4706A3ACFE3d9c889Ea83E2bd6582] = 0.3 ether * 115 / 100;
        refundsWeight[0x220582C5d0F17eC95eb367A03fB85266abc3523d] = 0.3 ether * 115 / 100;
        refundsWeight[0x9BA686e601E53462C3aB5C93D5f17027739C76a3] = 0.3 ether * 115 / 100;
        refundsWeight[0x1170bb94703380F066d012B71751D18ec14Fed18] = 0.3 ether * 115 / 100;
        refundsWeight[0x5925B177E38090B3407fc0041A70c5bffA7e716B] = 0.3 ether * 115 / 100;
        refundsWeight[0xB290Fd44A628A21FCCBf6347668D80dE4177dA42] = 0.3 ether * 115 / 100;
        refundsWeight[0x2b48D01f4cFe3A7496856f6F420AD2B4a892B599] = 0.3 ether * 115 / 100;
        refundsWeight[0xA25429E1FaEa4F5e73fb85EE0D9e1829EC0a0AFa] = 0.3 ether * 115 / 100;
        refundsWeight[0x4eBFF6be907E4B4159dCA69DE83688F8c83AabA7] = 0.3 ether * 115 / 100;
        refundsWeight[0xEb7402568c59a00182F9fd493343f01af104b378] = 0.3 ether * 115 / 100;
        refundsWeight[0xeC4BbAF888B17F1038b9BBc1221f3cFF0d49e817] = 0.3 ether * 115 / 100;
        refundsWeight[0x37d35049c84E07ca00D3e38930a65C90BC04a1a0] = 0.3 ether * 115 / 100;
    }

    function depositRefund() public payable {
        totalRefunds += msg.value;
    }

    function withdrawRefund() public nonReentrant {
        require(refundsWeight[msg.sender] > 0);
        uint256 amount = totalRefunds.mulWadDown(refundsWeight[msg.sender].divWadDown(totalRefundsWeight));
        refundsWeight[msg.sender] = 0;
        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    function itsOver() public {
        require(admin == msg.sender);
        selfdestruct(payable(admin));
    }
}