// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/mixins/ERC4626.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/FixedPointMathLib.sol";
import "solmate/utils/SafeTransferLib.sol";
import "src/interfaces/uniswap/IUniswapV2Pair.sol";
import "src/interfaces/uniswap/IUniswapV2Router.sol";
import "src/interfaces/gmx/IGmxVault.sol";
import "src/interfaces/gmx/IGmxRouter.sol";
import "src/interfaces/gmx/IGmxPositionRouter.sol";
import "src/interfaces/gmx/IGmxVaultPriceFeed.sol";
import "src/interfaces/gmx/IGmxPositionManager.sol";
import "src/libraries/UniswapV2Library.sol";
import "src/libraries/SafeMathUniswap.sol";



contract LogarithmVaultUniV2 is ERC4626, Owned {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using SafeMathUniswap for uint256;
 
    
    address public immutable pool;
    address public immutable product;
    address public immutable swapRouter;
    address public immutable gmxVault;
    address public immutable gmxRouter;
    address public immutable gmxPositionRouter;
    address public immutable gmxVaultPriceFeed;
    address public immutable gmxPositionManager;

    mapping(address => bool) public keeper;
    mapping(address => bool) public whitelistedDepositor;

    uint16 internal immutable ASSET_DECIMALS;
    uint16 internal immutable PRODUCT_DECIMALS;
    uint16 internal immutable LP_DECIMALS;
    uint16 internal constant DECIMALS = 6;
    uint16 internal constant GMX_PRICE_PRECISION = 30;
    uint32 public rehedgeThreshold;
    uint32 public targetLeverage;
    uint32 public slippageTollerance;
    uint32 internal constant SIZE_DELTA_MULT = 998004; // 6 decimals
    uint48 internal executionFee = 200000000000000;

    uint256 public lastRebalanceTimestamp;
    uint256 public vaultActivationTimestamp;
    uint256 public depositedAssets;

    /*//////////////////////////////////////////////////////////////
                            MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyWhitelisted() {
        if (whitelistedDepositor[msg.sender]) {
            _;
        } else {
            revert("NOT_WHITELISTED");
        }
    }

    modifier onlyKeeper() {
        if(keeper[msg.sender] || msg.sender == owner || msg.sender == address(this)) {
            _;
        } else {
            revert("NOT_KEEPER");
        }
    }

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(
        address _asset,
        address _product,
        address _pool,
        address _swapRouter,
        address _gmxVault,
        address _gmxRouter,
        address _gmxPositionRouter,
        address _gmxVaultPriceFeed,
        address _gmxPositionManager,
        uint256 _rehedgeThreshold,
        uint256 _targetLeverage,
        uint256 _slippageTollerance
    ) 
    ERC4626(ERC20(_asset), "Logarithm Vault UniV2 POC", "LV-poc")
    Owned(msg.sender) {
        product = _product;
        pool = _pool;
        swapRouter = _swapRouter;
        gmxVault = _gmxVault;
        gmxRouter = _gmxRouter;
        gmxPositionRouter = _gmxPositionRouter;
        gmxVaultPriceFeed = _gmxVaultPriceFeed;
        gmxPositionManager = _gmxPositionManager;
        rehedgeThreshold = uint32(_rehedgeThreshold);
        targetLeverage = uint32(_targetLeverage);
        slippageTollerance = uint32(_slippageTollerance);

        ASSET_DECIMALS = ERC20(_asset).decimals();
        PRODUCT_DECIMALS = ERC20(_product).decimals();
        LP_DECIMALS = ERC20(_pool).decimals();

        
        // approve margin trading on GMX
        IGmxRouter(_gmxRouter).approvePlugin(_gmxPositionRouter);

        
        // TODO: push approvals from constructor to function execution
        // approve asset to GMX
        ERC20(_asset).approve(_gmxRouter, type(uint256).max);

        // approve asset to swap router
        ERC20(_asset).approve(_swapRouter, type(uint256).max);

        // approve product to swap router 
        ERC20(_product).approve(_swapRouter, type(uint256).max);

        // approve pool tokens to swap router
        ERC20(_pool).approve(_swapRouter, type(uint256).max);

        vaultActivationTimestamp = block.timestamp;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCESS LOGIC
    //////////////////////////////////////////////////////////////*/

    function addKeepers(address[] calldata _keepers) public onlyOwner {
        for (uint256 i = 0; i < _keepers.length; i++) {
            keeper[_keepers[i]] = true;
        }
    }

    function removeKeepers(address[] calldata _keepers) public onlyOwner {
        for (uint256 i = 0; i < _keepers.length; i++) {
            keeper[_keepers[i]] = false;
        }
    }
    
    function addWhitelistedDepositors(address[] calldata _depostiors) public onlyOwner {
        for (uint256 i = 0; i < _depostiors.length; i++) {
            whitelistedDepositor[_depostiors[i]] = true;
        }
    }

    function removeWitelistedDepositors(address[] calldata _depostiors) public onlyOwner {
        for (uint256 i = 0; i < _depostiors.length; i++) {
            whitelistedDepositor[_depostiors[i]] = false;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    function setReheadgeThreshold( uint256 _rehedgeThreshold) public onlyOwner {
        rehedgeThreshold = uint32(_rehedgeThreshold);
    }
    
    function setTargetLeverage(uint256 _targetLeverage) public onlyOwner {
        targetLeverage = uint32(_targetLeverage);
    }

    function setSlippageTollerance(uint256 _slippageTollerance) public onlyOwner {
        slippageTollerance = uint32(_slippageTollerance);
    }

    function setExecutionFee(uint256 _executionFee) public onlyOwner {
        executionFee = uint48(_executionFee);
    }

    function sweepETH() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function sweepERC(address token) external onlyOwner {
        ERC20(token).transfer(owner, ERC20(token).balanceOf(address(this)));
    }

    function resetDepositedAssets() external onlyOwner {
        depositedAssets = 0;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public onlyWhitelisted override returns (uint256 shares) {
        shares = super.deposit(assets, receiver);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public onlyWhitelisted override returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        uint256 assetBalanceBeforeWithdraw = asset.balanceOf(address(this));
        _removeLiquidity(assets);
        uint256 assetBalanceAfterWithdraw = asset.balanceOf(address(this));
        assets = assetBalanceAfterWithdraw - assetBalanceBeforeWithdraw;

        _burn(owner, shares);

        asset.safeTransfer(receiver, assets);

        if(rebalanceRequired()) {
            _rebalance();
        }

        uint256 sharesFraction = shares.mulDivDown(10 ** DECIMALS, totalSupply);
        depositedAssets = depositedAssets.mulDivDown(10 ** DECIMALS - sharesFraction, 10 ** DECIMALS);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /*//////////////////////////////////////////////////////////////
                            UNISWAP LOGIC
    //////////////////////////////////////////////////////////////*/

    function addLiquidity(uint256 amount) public onlyKeeper {
        _addLiquidity(amount);
    }
    
    function _addLiquidity(uint256 amount) internal {

        // get optimal swap amount
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        uint256 assetReserve = uint256(address(asset) < product ? reserve0 : reserve1);
        uint256 swapAmount = getSwapAmountIn(amount, assetReserve);
        
        // swap half of asset to product
        address[] memory path = new address[](2);
        path[0] = address(asset);
        path[1] = product;
        IUniswapV2Router(swapRouter).swapExactTokensForTokens(
            swapAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        // add liquidity to pool

        IUniswapV2Router(swapRouter).addLiquidity(
            address(asset),
            product,
            ERC20(asset).balanceOf(address(this)),
            ERC20(product).balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp
        );
        
    }

    function removeLiquidity(uint256 amount) public onlyKeeper {
        _removeLiquidity(amount);
    }

    function _removeLiquidity(uint256 amount) internal {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        uint256 assetReserve = uint256(address(asset) < product ? reserve0 : reserve1);
        uint256 swapAmount = getSwapAmountIn(amount, assetReserve);
        uint256 lpTotalSupply = ERC20(pool).totalSupply();
        uint256 lpToWithdraw = (swapAmount * lpTotalSupply) / (assetReserve);

        // remove liquidity from pool
        IUniswapV2Router(swapRouter).removeLiquidity(
            address(asset),
            product,
            lpToWithdraw,
            0,
            0,
            address(this),
            block.timestamp
        );

        // swap product to asset
        address[] memory path = new address[](2);
        path[0] = product;
        path[1] = address(asset);
        IUniswapV2Router(swapRouter).swapExactTokensForTokens(
            ERC20(product).balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function exitLiquidity() public onlyKeeper {
        _exitLiquidity();
    }

    function _exitLiquidity() internal {
        // remove liquidity from pool
        uint256 lpBalance = ERC20(pool).balanceOf(address(this));
        IUniswapV2Router(swapRouter).removeLiquidity(
            address(asset),
            product,
            lpBalance,
            0,
            0,
            address(this),
            block.timestamp
        );

        // swap product to asset
        address[] memory path = new address[](2);
        path[0] = product;
        path[1] = address(asset);
        IUniswapV2Router(swapRouter).swapExactTokensForTokens(
            ERC20(product).balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function getLpAssetBalance() public view returns (uint256 assetBalance) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        uint256 assetReserve = uint256(address(asset) < product ? reserve0 : reserve1);
        uint256 lpTotalSupply = ERC20(pool).totalSupply();
        uint256 lpVaultBalance = ERC20(pool).balanceOf(address(this));
        assetBalance = lpVaultBalance.mulDivUp(assetReserve, lpTotalSupply);
    }

    function getLpExposure() public view returns (uint256 exposure) {
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        uint256 productReserve = uint256(product < address(asset) ? reserve0 : reserve1);
        uint256 lpTotalSupply = ERC20(pool).totalSupply();
        uint256 lpVaultBalance = ERC20(pool).balanceOf(address(this));
        exposure = lpVaultBalance.mulDivUp(productReserve, lpTotalSupply);
    }

    function getLpNetBalance() public view returns (uint256 lpValue) {
        if(ERC20(pool).balanceOf(address(this)) == 0) return 0;
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        uint256 assetReserve = uint256(address(asset) < product ? reserve0 : reserve1);
        uint256 productReserve = uint256(product < address(asset) ? reserve0 : reserve1);
        uint256 lpTotalSupply = ERC20(pool).totalSupply();
        uint256 lpVaultBalance = ERC20(pool).balanceOf(address(this));
        uint256 assetValue = lpVaultBalance.mulDivUp(assetReserve, lpTotalSupply);
        uint256 productAmount = lpVaultBalance.mulDivUp(productReserve, lpTotalSupply);
        uint256 productValue = UniswapV2Library.getAmountOut(productAmount, productReserve, assetReserve);
        lpValue = assetValue + productValue;
    }

    function getSwapAmountIn(uint256 amtA, uint256 resA) internal pure returns (uint256) {
        return (FixedPointMathLib.sqrt(resA * (3988009 * resA + 3988000 * amtA)) - (1997 * resA)) / 1994;
    }

    /*//////////////////////////////////////////////////////////////
                                GMX LOGIC
    //////////////////////////////////////////////////////////////*/

    function increaseHedge(uint256 amount) public onlyKeeper returns (bytes32 positionKey) {
        return _increaseHedge(amount);
    }
    
    function _increaseHedge(uint256 amount) internal returns (bytes32 positionKey) {
        address[] memory path = new address[](1);
        path[0] = address(asset);
        uint256 sizeDelta = (amount * uint256(targetLeverage) * uint256(SIZE_DELTA_MULT)).mulDivDown(10 ** GMX_PRICE_PRECISION, 10 ** (ASSET_DECIMALS + DECIMALS * 2));
        uint256 markPrice = IGmxVaultPriceFeed(gmxVaultPriceFeed).getPrice(product, false, false, false);
        uint256 acceptablePrice = markPrice.mulDivDown(10 ** DECIMALS - slippageTollerance, 10 ** DECIMALS);

        positionKey = IGmxPositionRouter(gmxPositionRouter).createIncreasePosition{ value: executionFee }(
            path,
            product,
            amount,
            0,
            sizeDelta,
            false,
            acceptablePrice,
            executionFee,
            bytes32(0),
            address(0)
        );
    }

    function decreaseHedge(uint256 amount) public onlyKeeper returns (bytes32 positionKey) {
        return _decreaseHedge(amount);
    }

    function _decreaseHedge(uint256 amount) internal returns (bytes32 positionKey) {
        address[] memory path = new address[](1);
        path[0] = address(asset);
        uint256 collateralDelta = amount.mulDivDown(10 ** GMX_PRICE_PRECISION, 10 ** ASSET_DECIMALS);
        uint256 sizeDelta = collateralDelta.mulDivDown(uint256(targetLeverage) * uint256(SIZE_DELTA_MULT), 10 ** DECIMALS * 10 ** DECIMALS);
        uint256 acceptablePrice = IGmxVaultPriceFeed(gmxVaultPriceFeed).getPrice(product, false, false, false).mulDivDown(10 ** DECIMALS + slippageTollerance, 10 ** DECIMALS);


        positionKey = IGmxPositionRouter(gmxPositionRouter).createDecreasePosition{ value: executionFee }(
            path,
            product,
            collateralDelta,
            sizeDelta,
            false,
            address(this),
            acceptablePrice,
            0,
            executionFee,
            false,
            address(0)
        );
    }

    function exitPosition() public onlyKeeper {
        _exitPosition();
    }

    function _exitPosition() internal {
        bytes32 key = IGmxVault(gmxVault).getPositionKey(address(this), address(asset), product, false);
        Position memory position = IGmxVault(gmxVault).positions(key);

        address[] memory path = new address[](1);
        path[0] = address(asset);

        uint256 acceptablePrice = IGmxVaultPriceFeed(gmxVaultPriceFeed).getPrice(product, false, false, false).mulDivDown(10 ** DECIMALS + slippageTollerance, 10 ** DECIMALS);

        IGmxPositionRouter(gmxPositionRouter).createDecreasePosition{ value: executionFee }(
            path,
            product,
            position.collateral,
            position.size,
            false,
            address(this),
            acceptablePrice,
            0,
            executionFee,
            false,
            address(0)
        );
    }

    function getPositionLeverage() public view returns (uint256 leverage) {
        try IGmxVault(gmxVault).getPositionLeverage(
                address(this),
                address(asset),
                product,
                false
            ) returns (uint256 _leverage) {
            leverage =  _leverage;
        } catch {
            return 0;
        }
    }

    function getPositionSize() public view returns (uint256 positionSize) {
        (uint256 size, , uint256 averagePrice, , , , , uint256 lastIncreasedTime) = IGmxVault(gmxVault).getPosition(
            address(this),
            address(asset),
            product,
            false
        );
        if (size == 0) {
            return 0;
        }
        (bool hasProfit, uint256 sizeDelta) = IGmxVault(gmxVault).getDelta(product, size, averagePrice, false, lastIncreasedTime);
        positionSize = hasProfit ? size + sizeDelta : size - sizeDelta;
    }

    function getPositionHedge() public view returns (uint256 positionHedge) {
        uint256 positionSize = getPositionSize();
        if (positionSize == 0) {
            return 0;
        }
        positionHedge = IGmxVault(gmxVault).usdToTokenMax(product, positionSize);
    }


    function getPositionCollateral() public view returns (uint256 remainingCollateral) {
        bytes32 key = IGmxVault(gmxVault).getPositionKey(address(this), address(asset), product, false);
        Position memory position = IGmxVault(gmxVault).positions(key);
        if (position.collateral == 0) {
            return 0;
        }
        (bool hasProfit, uint256 delta) = IGmxVault(gmxVault).getDelta(product, position.size, position.averagePrice, false, position.lastIncreasedTime);
        remainingCollateral = position.collateral;
        if (!hasProfit) {
            remainingCollateral -= delta;
        }
        remainingCollateral = remainingCollateral.mulDivDown(10 ** ASSET_DECIMALS, 10 ** GMX_PRICE_PRECISION);
    }

    function getPositionMarginFees() public view returns (uint256 marginFees) {
        bytes32 key = IGmxVault(gmxVault).getPositionKey(address(this), address(asset), product, false);
        Position memory position = IGmxVault(gmxVault).positions(key);
        marginFees = IGmxVault(gmxVault).getFundingFee(address(asset), position.size, position.entryFundingRate);
        marginFees += IGmxVault(gmxVault).getPositionFee(position.size);
    }

    function getPositionNetBalance() public view returns (uint256 marginBalance) {
        bytes32 key = IGmxVault(gmxVault).getPositionKey(address(this), address(asset), product, false);
        Position memory position = IGmxVault(gmxVault).positions(key);
        if (position.size == 0) {
            return 0;
        }
        (bool hasProfit, uint256 delta) = IGmxVault(gmxVault).getDelta(product, position.size, position.averagePrice, false, position.lastIncreasedTime);
        marginBalance = position.collateral;
        if (hasProfit) {
            marginBalance += delta;
        } else {
            marginBalance -= delta;
        }
        uint256 positionMarginFees = getPositionMarginFees();
        marginBalance -= positionMarginFees;
        marginBalance = marginBalance.mulDivDown(10 ** ASSET_DECIMALS, 10 ** GMX_PRICE_PRECISION);
    }

    /*//////////////////////////////////////////////////////////////
                            REBALANCING LOGIC
    //////////////////////////////////////////////////////////////*/


    function getHedgeRatio() public view returns (uint256) {
        uint256 exposure = getLpExposure();
        if (exposure == 0) {
            return 0;
        }
        uint256 hedge = getPositionHedge();
        if (hedge == 0) {
            return 0;
        }
        return hedge.mulDivDown(10 ** DECIMALS, exposure);
    }

    function rebalanceRequired() public view returns (bool) {
        uint256 currentHedgeRatio = getHedgeRatio();
        uint256 _rehedegeThreshold = rehedgeThreshold;
        if (currentHedgeRatio > (10 ** DECIMALS + _rehedegeThreshold) || currentHedgeRatio < (10 ** DECIMALS - _rehedegeThreshold)) {
            return true;
        } else {
            return false;
        }
    }

    function desiredLpNetBalance(uint256 _totalAssets, uint256 _targetLeverage) public pure returns (uint256) {
        return (2 * _totalAssets).mulDivDown(_targetLeverage , 2 * _targetLeverage + 10 ** DECIMALS);
    }

    function desiredPositionSize(uint256 _totalAssets, uint256 _targetLeverage) public view returns (uint256) {
        return (_totalAssets).mulDivDown(_targetLeverage, 2 * _targetLeverage + 10 ** DECIMALS).mulDivDown(10 ** GMX_PRICE_PRECISION, 10 ** ASSET_DECIMALS);
    }

    function desiredPositionHedge(uint256 _totalAssets, uint256 _tagetLeverage) public view returns (uint256) {
        uint256 _desiredLpNetBalance = desiredLpNetBalance(_totalAssets, _tagetLeverage);
        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pool).getReserves();
        uint256 assetReserve = uint256(address(asset) < product ? reserve0 : reserve1);
        uint256 productReserve = uint256(product < address(asset) ? reserve0 : reserve1);
        uint256 productSpotPrice = assetReserve.mulDivDown(10 ** PRODUCT_DECIMALS * 10 ** ASSET_DECIMALS, productReserve * 10 ** ASSET_DECIMALS);
        uint256 desiredLpExposure = _desiredLpNetBalance.mulDivDown(10 ** ASSET_DECIMALS * 10 ** PRODUCT_DECIMALS, 2 * productSpotPrice * 10 ** ASSET_DECIMALS);
        return desiredLpExposure;
    }

    function rebalance() public onlyKeeper {
        if (rebalanceRequired()) {
            _rebalance();
        } else {
            revert("NO_REBALANCE_REQUIRED");
        }
    }

    function _rebalance() internal {
        uint256 vaultAssetBalance = asset.balanceOf(address(this));
        uint256 _targetLeverage = targetLeverage;

        // rebalance LP position
        uint256 currentLpBalance = getLpNetBalance();
        uint256 desiredLpBalance = desiredLpNetBalance(totalAssets(), _targetLeverage);
        if(currentLpBalance < desiredLpBalance) {
            // we need to increase LP position
            uint256 lpDelta = desiredLpBalance - currentLpBalance;
            lpDelta = lpDelta < vaultAssetBalance ? lpDelta : vaultAssetBalance;
            if(lpDelta > 0) {
                _addLiquidity(lpDelta);
            }
        } else if (currentLpBalance > desiredLpBalance) {
            // we need to reduce LP position
            uint256 lpDelta = currentLpBalance - desiredLpBalance;
            _removeLiquidity(lpDelta);
        }
        vaultAssetBalance = asset.balanceOf(address(this));

        // rebalance hedge position
        uint256 currentHedge = getPositionHedge();
        uint256 desiredHedge = desiredPositionHedge(totalAssets(), _targetLeverage);

        if(currentHedge > desiredHedge) {
            // we need to reduce hedge position
            uint256 hedgeDelta = currentHedge - desiredHedge;
            uint256 sizeDelta = IGmxVault(gmxVault).tokenToUsdMin(product, hedgeDelta);
            uint256 collateralDelta = sizeDelta.mulDivDown(10**DECIMALS * 10**DECIMALS , uint256(_targetLeverage) * uint256(SIZE_DELTA_MULT));
            uint256 acceptablePrice = IGmxVaultPriceFeed(gmxVaultPriceFeed).getPrice(product, false, false, false).mulDivDown(10 ** DECIMALS + slippageTollerance, 10 ** DECIMALS);

            address[] memory path = new address[](1);
            path[0] = address(asset);   

            IGmxPositionRouter(gmxPositionRouter).createDecreasePosition{ value: executionFee }(
                path,
                product,
                collateralDelta,
                sizeDelta,
                false,
                address(this),
                acceptablePrice,
                0,
                executionFee,
                false,
                address(0)
            );
        } else if (currentHedge < desiredHedge) {
            // we need to increase hedge position
            uint256 hedgeDelta = desiredHedge - currentHedge;
            uint256 price = IGmxVault(gmxVault).getMaxPrice(product);
            uint256 sizeDelta = hedgeDelta.mulDivDown(price, 10 ** PRODUCT_DECIMALS);
            sizeDelta = sizeDelta.mulDivDown(10 ** ASSET_DECIMALS, 10 ** GMX_PRICE_PRECISION);

            sizeDelta = sizeDelta < vaultAssetBalance ? sizeDelta : vaultAssetBalance;
            if(sizeDelta > 0) {
                _increaseHedge(sizeDelta);
            }
        }
        lastRebalanceTimestamp = block.timestamp;
    }

    function getVaultState() public view returns (
        uint256 vaultTotalAssets,
        uint256 assetBalance,
        uint256 lpSharesBalance,
        uint256 assetInLp,
        uint256 productInLp,
        uint256 lpNetBalance,
        uint256 positionSize,
        uint256 positionCollateral,
        uint256 positionHedge,
        uint256 positionLeverage,
        uint256 positionMarginFees,
        uint256 positionNetBalance,
        uint256 vaultHedgeRatio,
        int256 vaultPnl,
        int256 vaultApy,
        uint256 rebalanceTimestamp
    ) {
        vaultTotalAssets = totalAssets();
        assetBalance = asset.balanceOf(address(this));
        lpSharesBalance = ERC20(pool).balanceOf(address(this));
        assetInLp = getLpAssetBalance();
        productInLp = getLpExposure();
        lpNetBalance = getLpNetBalance();
        positionSize = getPositionSize();
        positionCollateral = getPositionCollateral();
        positionHedge = getPositionHedge();
        positionLeverage = getPositionLeverage();
        positionMarginFees = getPositionMarginFees();
        positionNetBalance = getPositionNetBalance();
        vaultHedgeRatio = getHedgeRatio();
        vaultPnl = getVaultPnl();
        vaultApy = getVaultApy();
        rebalanceTimestamp = lastRebalanceTimestamp;
    }

    function exitStrategy() external onlyOwner {
        _exitPosition();
        _exitLiquidity();
    }


    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view override returns (uint256) {
        return getLpNetBalance() + getPositionNetBalance() + asset.balanceOf(address(this));
    }

    function getVaultPnl() public view returns (int256 pnl) {
        if(depositedAssets == 0) {
            return int256(0);
        }
        pnl = int256(totalAssets()) - int256(depositedAssets);
    }

    function getVaultApy() public view returns (int256 apy) {
        if(depositedAssets == 0) {
            return 0;
        }
        uint256 timePassed = block.timestamp - vaultActivationTimestamp;
        if(timePassed == 0) {
            return 0;
        }
        int256 pnl = getVaultPnl();
        if(pnl >= 0) {
            apy = int256(uint256(pnl).mulDivDown(365 days * 10**DECIMALS, depositedAssets * timePassed));
        } else {
            apy = -int256(uint256(-pnl).mulDivDown(365 days * 10**DECIMALS, depositedAssets * timePassed));
        }
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function afterDeposit(uint256 assets, uint256) internal override {
        if(rebalanceRequired()) {
            _rebalance();
        }
        depositedAssets += assets;
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function extCall(address target, bytes calldata data, uint256 msgvalue) external onlyOwner returns (bytes memory) {
        (bool success, bytes memory returnData) = target.call{ value: msgvalue }(data);
        require(success, string(returnData));
        return returnData;
    }

    function sweepErc(address token) external onlyOwner {
        uint256 balance = ERC20(token).balanceOf(address(this));
        ERC20(token).transfer(msg.sender, balance);
    }

    function sweepEth() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
 
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGmxPositionManager {
    function setMaxGlobalSizes(
        address[] memory _tokens,
        uint256[] memory _longSizes,
        uint256[] memory _shortSizes
    ) external;

    function maxGlobalShortSizes(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGmxPositionRouter {
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
    ) external payable returns (bytes32);

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
    ) external payable returns (bytes32);

    function executeIncreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function executeDecreasePosition(
        bytes32 _key,
        address payable _executionFeeReceiver
    ) external returns (bool);

    function getRequestKey(
        address _account,
        uint256 _index
    ) external view returns (bytes32);


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGmxRouter {
    function approvePlugin(address _plugin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct Position {
    uint256 size;
    uint256 collateral;
    uint256 averagePrice;
    uint256 entryFundingRate;
    uint256 reserveAmount;
    int256 realisedPnl;
    uint256 lastIncreasedTime;
}

interface IGmxVault {

    function getPositionLeverage(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function getPosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        uint256 realisedPnl,
        bool realisedPnlOverZero,
        uint256 lastIncreaseTime
    );

    function globalShortSizes(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool hasProfit, uint256 delta);

    function getPositionKey(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bytes32);

    function getPositionFee(uint256 _size) external view returns (uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function positions(bytes32 key) external view returns (Position memory position);

    function reservedAmounts(address token) external view returns (uint256);

    function poolAmounts(address token) external view returns (uint256);

    function usdToTokenMax(address _token, uint256 _amount) external view returns (uint256);

    function usdToTokenMin(address _token, uint256 _amount) external view returns (uint256);

    function tokenToUsdMin(address _token, uint256 _amount) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGmxVaultPriceFeed {
    function getPrice(
        address _token,
        bool _maximise,
        bool _includeAmmPrice,
        bool
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;


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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Router {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "solmate/utils/FixedPointMathLib.sol";
import "src/interfaces/uniswap/IUniswapV2Pair.sol";

library UniswapV2Library {
    using FixedPointMathLib for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mulDivDown(reserveB, reserveA);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}