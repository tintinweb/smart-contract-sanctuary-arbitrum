// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity 0.8.16;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
        // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

        // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

        // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
            // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

            // To write each character, shift the 3 bytes (18 bits) chunk
            // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
            // and apply logical AND with 0x3F which is the number of
            // the previous character in the ASCII table prior to the Base64 Table
            // The result is then added to the table to get the character to write,
            // and finally write it in the result pointer but with a left shift
            // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

        // When data `bytes` is not exactly 3 bytes long
        // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
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

// SPDX-License-Identifier: BUSL 1.1
// Valorem Labs Inc. (c) 2023.
pragma solidity 0.8.16;

import "base64/Base64.sol";
import "solmate/tokens/ERC20.sol";

import "./interfaces/IValoremOptionsClearinghouse.sol";
import "./interfaces/ITokenURIGenerator.sol";

/// @title Library to dynamically generate Valorem token URIs
/// @author Thal0x
/// @author Flip-Liquid
/// @author neodaoist
/// @author 0xAlcibiades
contract TokenURIGenerator is ITokenURIGenerator {
    /// @inheritdoc ITokenURIGenerator
    function constructTokenURI(TokenURIParams memory params) public view returns (string memory) {
        string memory svg = generateNFT(params);

        /* solhint-disable quotes */
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"',
                        generateName(params),
                        '", "description": "',
                        generateDescription(params),
                        '", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );
        /* solhint-enable quotes */
    }

    /// @inheritdoc ITokenURIGenerator
    function generateName(TokenURIParams memory params) public pure returns (string memory) {
        (uint256 month, uint256 day, uint256 year) = _getDateUnits(params.expiryTimestamp);

        bytes memory yearDigits = bytes(_toString(year));
        bytes memory monthDigits = bytes(_toString(month));
        bytes memory dayDigits = bytes(_toString(day));

        return string(
            abi.encodePacked(
                _escapeQuotes(params.underlyingSymbol),
                _escapeQuotes(params.exerciseSymbol),
                yearDigits[2],
                yearDigits[3],
                monthDigits.length == 2 ? monthDigits[0] : bytes1(uint8(48)),
                monthDigits.length == 2 ? monthDigits[1] : monthDigits[0],
                dayDigits.length == 2 ? dayDigits[0] : bytes1(uint8(48)),
                dayDigits.length == 2 ? dayDigits[1] : dayDigits[0],
                "C"
            )
        );
    }

    /// @inheritdoc ITokenURIGenerator
    function generateDescription(TokenURIParams memory params) public pure returns (string memory) {
        return string(
            abi.encodePacked(
                "NFT representing a Valorem option contract. ",
                params.underlyingSymbol,
                " Address: ",
                addressToString(params.underlyingAsset),
                ". ",
                params.exerciseSymbol,
                " Address: ",
                addressToString(params.exerciseAsset),
                "."
            )
        );
    }

    /// @inheritdoc ITokenURIGenerator
    function generateNFT(TokenURIParams memory params) public view returns (string memory) {
        uint8 underlyingDecimals = ERC20(params.underlyingAsset).decimals();
        uint8 exerciseDecimals = ERC20(params.exerciseAsset).decimals();

        return string(
            abi.encodePacked(
                "<svg width='400' height='300' viewBox='0 0 400 300' xmlns='http://www.w3.org/2000/svg'>",
                "<rect width='100%' height='100%' rx='12' ry='12'  fill='#3E5DC7' />",
                "<g transform='scale(5), translate(25, 18)' fill-opacity='0.15'>",
                "<path xmlns='http://www.w3.org/2000/svg' d='M69.3577 14.5031H29.7265L39.6312 0H0L19.8156 29L29.7265 14.5031L39.6312 29H19.8156H0L19.8156 58L39.6312 29L49.5421 43.5031L69.3577 14.5031Z' fill='white'/>",
                "</g>",
                _generateHeaderSection(params.underlyingSymbol, params.exerciseSymbol, params.tokenType),
                _generateAmountsSection(
                    params.underlyingAmount,
                    params.underlyingSymbol,
                    underlyingDecimals,
                    params.exerciseAmount,
                    params.exerciseSymbol,
                    exerciseDecimals
                ),
                _generateDateSection(params),
                "</svg>"
            )
        );
    }

    function _generateHeaderSection(
        string memory _underlyingSymbol,
        string memory _exerciseSymbol,
        IValoremOptionsClearinghouse.TokenType _tokenType
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                abi.encodePacked(
                    "<text x='16px' y='55px' font-size='32px' fill='#fff' font-family='Helvetica'>",
                    _underlyingSymbol,
                    " / ",
                    _exerciseSymbol,
                    "</text>"
                ),
                _tokenType == IValoremOptionsClearinghouse.TokenType.Option
                    ?
                    "<text x='16px' y='80px' font-size='16' fill='#fff' font-family='Helvetica' font-weight='300'>Long Call</text>"
                    :
                    "<text x='16px' y='80px' font-size='16' fill='#fff' font-family='Helvetica' font-weight='300'>Short Call</text>"
            )
        );
    }

    function _generateAmountsSection(
        uint256 _underlyingAmount,
        string memory _underlyingSymbol,
        uint8 _underlyingDecimals,
        uint256 _exerciseAmount,
        string memory _exerciseSymbol,
        uint8 _exerciseDecimals
    ) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<text x='16px' y='116px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>UNDERLYING ASSET</text>",
                _generateAmountString(_underlyingAmount, _underlyingDecimals, _underlyingSymbol, 16, 140),
                "<text x='16px' y='176px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXERCISE ASSET</text>",
                _generateAmountString(_exerciseAmount, _exerciseDecimals, _exerciseSymbol, 16, 200)
            )
        );
    }

    function _generateDateSection(TokenURIParams memory params) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                "<text x='16px' y='236px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXERCISE DATE</text>",
                _generateTimestampString(params.exerciseTimestamp, 16, 260),
                "<text x='200px' y='236px' font-size='14' letter-spacing='0.01em' fill='#fff' font-family='Helvetica'>EXPIRY DATE</text>",
                _generateTimestampString(params.expiryTimestamp, 200, 260)
            )
        );
    }

    function _generateAmountString(uint256 _amount, uint8 _decimals, string memory _symbol, uint256 _x, uint256 _y)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<text x='",
                _toString(_x),
                "px' y='",
                _toString(_y),
                "px' font-size='18' fill='#fff' font-family='Helvetica' font-weight='300'>",
                _decimalString(_amount, _decimals, false),
                " ",
                _symbol,
                "</text>"
            )
        );
    }

    function _generateTimestampString(uint256 _timestamp, uint256 _x, uint256 _y)
        internal
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                "<text x='",
                _toString(_x),
                "px' y='",
                _toString(_y),
                "px' font-size='18' fill='#fff' font-family='Helvetica' font-weight='300'>",
                _generateDateString(_timestamp),
                "</text>"
            )
        );
    }

    /// @notice Utilities
    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
        // true if string should include "%"
        bool isPercent;
    }

    function _generateDecimalString(DecimalStringParams memory params) internal pure returns (string memory) {
        bytes memory buffer = new bytes(params.bufferLength);
        if (params.isPercent) {
            buffer[buffer.length - 1] = "%";
        }
        if (params.isLessThanOne) {
            buffer[0] = "0";
            buffer[1] = ".";
        }

        // add leading/trailing 0's
        for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex; zerosCursor++) {
            buffer[zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (params.sigfigs > 0) {
            if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
                buffer[--params.sigfigIndex] = ".";
            }
            buffer[--params.sigfigIndex] = bytes1(uint8(uint256(48) + (params.sigfigs % 10)));
            params.sigfigs /= 10;
        }
        return string(buffer);
    }

    function _decimalString(uint256 number, uint8 decimals, bool isPercent) internal pure returns (string memory) {
        uint8 percentBufferOffset = isPercent ? 1 : 0;
        uint256 tenPowDecimals = 10 ** decimals;

        uint256 temp = number;
        uint8 digits = 0;
        uint8 numSigfigs = 0;
        while (temp != 0) {
            if (numSigfigs > 0) {
                // count all digits preceding least significant figure
                numSigfigs++;
            } else if (temp % 10 != 0) {
                numSigfigs++;
            }
            digits++;
            temp /= 10;
        }

        DecimalStringParams memory params = DecimalStringParams({
            sigfigs: uint256(0),
            bufferLength: uint8(0),
            sigfigIndex: uint8(0),
            decimalIndex: uint8(0),
            zerosStartIndex: uint8(0),
            zerosEndIndex: uint8(0),
            isLessThanOne: false,
            isPercent: false
        });
        params.isPercent = isPercent;
        if ((digits - numSigfigs) >= decimals) {
            // no decimals, ensure we preserve all trailing zeros
            params.sigfigs = number / tenPowDecimals;
            params.sigfigIndex = digits - decimals;
            params.bufferLength = params.sigfigIndex + percentBufferOffset;
        } else {
            // chop all trailing zeros for numbers with decimals
            params.sigfigs = number / (10 ** (digits - numSigfigs));
            if (tenPowDecimals > number) {
                // number is less tahn one
                // in this case, there may be leading zeros after the decimal place
                // that need to be added

                // offset leading zeros by two to account for leading '0.'
                params.zerosStartIndex = 2;
                params.zerosEndIndex = decimals - digits + 2;
                // params.zerosStartIndex = 4;
                params.sigfigIndex = numSigfigs + params.zerosEndIndex;
                params.bufferLength = params.sigfigIndex + percentBufferOffset;
                params.isLessThanOne = true;
            } else {
                // In this case, there are digits before and
                // after the decimal place
                params.sigfigIndex = numSigfigs + 1;
                params.decimalIndex = digits - decimals + 1;
            }
        }
        params.bufferLength = params.sigfigIndex + percentBufferOffset;
        return _generateDecimalString(params);
    }

    function _getDateUnits(uint256 _timestamp) internal pure returns (uint256 month, uint256 day, uint256 year) {
        int256 z = int256(_timestamp) / 86400 + 719468;
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        int256 doe = z - era * 146097;
        int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int256 y = yoe + era * 400;
        int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        int256 mp = (5 * doy + 2) / 153;
        int256 d = doy - (153 * mp + 2) / 5 + 1;
        int256 m = mp + (mp < 10 ? int256(3) : -9);

        if (m <= 2) {
            y += 1;
        }

        month = uint256(m);
        day = uint256(d);
        year = uint256(y);
    }

    function _generateDateString(uint256 _timestamp) internal pure returns (string memory) {
        int256 z = int256(_timestamp) / 86400 + 719468;
        int256 era = (z >= 0 ? z : z - 146096) / 146097;
        int256 doe = z - era * 146097;
        int256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        int256 y = yoe + era * 400;
        int256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        int256 mp = (5 * doy + 2) / 153;
        int256 d = doy - (153 * mp + 2) / 5 + 1;
        int256 m = mp + (mp < 10 ? int256(3) : -9);

        if (m <= 2) {
            y += 1;
        }

        string memory s = "";

        if (m < 10) {
            s = _toString(0);
        }

        s = string(abi.encodePacked(s, _toString(uint256(m)), bytes1(0x2F)));

        if (d < 10) {
            s = string(abi.encodePacked(s, bytes1(0x30)));
        }

        s = string(abi.encodePacked(s, _toString(uint256(d)), bytes1(0x2F), _toString(uint256(y))));

        return string(s);
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // This is borrowed from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol#L16

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            // solhint-disable quotes
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(
                symbolBytes.length + (quotesCount)
            );
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                // solhint-disable quotes
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    bytes16 internal constant ALPHABET = "0123456789abcdef";

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function addressToString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), 20);
    }
}

// SPDX-License-Identifier: BUSL 1.1
// Valorem Labs Inc. (c) 2023.
pragma solidity 0.8.16;

import "base64/Base64.sol";
import "solmate/tokens/ERC20.sol";
import "solmate/tokens/ERC1155.sol";
import "solmate/utils/SafeTransferLib.sol";
import "solmate/utils/FixedPointMathLib.sol";

import "./interfaces/IValoremOptionsClearinghouse.sol";
import "./TokenURIGenerator.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//   $$$$$$$$$$                                                                                   //
//    $$$$$$$$                                  _|                                                //
//     $$$$$$ $$$$$$$$$$   _|      _|   _|_|_|  _|    _|_|    _|  _|_|   _|_|    _|_|_|  _|_|     //
//       $$    $$$$$$$$    _|      _| _|    _|  _|  _|    _|  _|_|     _|_|_|_|  _|    _|    _|   //
//   $$$$$$$$$$ $$$$$$       _|  _|   _|    _|  _|  _|    _|  _|       _|        _|    _|    _|   //
//    $$$$$$$$    $$           _|       _|_|_|  _|    _|_|    _|         _|_|_|  _|    _|    _|   //
//     $$$$$$                                                                                     //
//       $$                                                                                       //
//                                                                                                //
//////////////////////////////////////////////////////////////////////////////////////////////////*/

/**
 * @title A clearing and settling engine for options on ERC20 tokens.
 * @author 0xAlcibiades
 * @author Flip-Liquid
 * @author neodaoist
 * @notice Valorem Options V1 is a DeFi money lego for writing physically
 * settled covered call and covered put options. All Valorem options are fully
 * collateralized with an ERC-20 underlying asset and exercised with an
 * ERC-20 exercise asset using a fair assignment process. Option contracts, or
 * long positions, are issued as fungible ERC-1155 tokens, with each token
 * representing a contract. Option writers are additionally issued an ERC-1155
 * NFT claim, or short position, which is used to claim collateral and for
 * option exercise assignment.
 */
contract ValoremOptionsClearinghouse is ERC1155, IValoremOptionsClearinghouse {
    /*//////////////////////////////////////////////////////////////
    // Internal Data Structures
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Stores the state of options written and exercised for a bucket.
     * Used in fair exercise assignment assignment to calculate the ratio of
     * underlying assets to exercise assets to be transferred to claimants.
     */
    struct Bucket {
        /// @custom:member amountWritten The number of option contracts written into this bucket.
        uint112 amountWritten;
        /// @custom:member amountExercised The number of option contracts exercised from this bucket.
        uint112 amountExercised;
    }

    /// @notice The bucket information for a given option type.
    struct BucketInfo {
        /// @custom:member An array of buckets for a given option type.
        Bucket[] buckets;
        /// @custom:member An array of bucket indices with collateral available for exercise.
        uint96[] unexercisedBucketIndices;
    }

    /**
     * @notice Claims can be used to write multiple times. This struct is used to
     * keep track of how many options are written from a claim into each bucket,
     * in order to correctly perform fair exercise assignment.
     */
    struct ClaimIndex {
        /// @custom:member amountWritten The amount of option contracts written into claim for given bucket.
        uint112 amountWritten;
        /// @custom:member bucketIndex The index of the Bucket into which the options collateral was deposited.
        uint96 bucketIndex;
    }

    /// @notice A storage container for the engine state of a given option type.
    struct OptionTypeState {
        /// @custom:member State for this option type.
        Option option;
        /// @custom:member State for assignment buckets on this option type.
        BucketInfo bucketInfo;
        /// @custom:member A mapping to an array of bucket indices per claim token for this option type.
        mapping(uint96 => ClaimIndex[]) claimIndices;
    }

    /*//////////////////////////////////////////////////////////////
    //  Immutable/Constant - Private
    //////////////////////////////////////////////////////////////*/

    /// @dev The bit padding for optionKey -> optionId.
    uint8 private constant OPTION_KEY_PADDING = 96;

    /// @dev The mask to mask out a claimKey from a claimId.
    uint96 private constant CLAIM_KEY_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFF;

    /*//////////////////////////////////////////////////////////////
    //  Immutable/Constant - Public
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValoremOptionsClearinghouse
    // solhint-disable-next-line const-name-snakecase
    uint8 public constant feeBps = 5;

    /*//////////////////////////////////////////////////////////////
    //  State Variables - Private
    //////////////////////////////////////////////////////////////*/

    /// @notice Details about the option, buckets, and claims per option type.
    mapping(uint160 => OptionTypeState) private optionTypeStates;

    /// @notice The new feeTo address, pending explicit acceptance by this address.
    address private pendingFeeTo;

    /*//////////////////////////////////////////////////////////////
    //  State Variables - Public
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IValoremOptionsClearinghouse
    mapping(address => uint256) public feeBalance;

    /// @inheritdoc IValoremOptionsClearinghouse
    address public feeTo;

    /// @inheritdoc IValoremOptionsClearinghouse
    bool public feesEnabled;

    /// @inheritdoc IValoremOptionsClearinghouse
    ITokenURIGenerator public tokenURIGenerator;

    /*//////////////////////////////////////////////////////////////
    //  Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @notice This modifier restricts function access to the feeTo address.
    modifier onlyFeeTo() {
        if (msg.sender != feeTo) {
            revert AccessControlViolation(msg.sender, feeTo);
        }

        _;
    }

    /*//////////////////////////////////////////////////////////////
    //  Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructs the ValoremOptionsClearinghouse.
     * @param _feeTo The address to which fees accrue.
     * @param _tokenURIGenerator The contract address of the token URI generator.
     */
    constructor(address _feeTo, address _tokenURIGenerator) {
        if (_feeTo == address(0) || _tokenURIGenerator == address(0)) {
            revert InvalidAddress(address(0));
        }

        feeTo = _feeTo;
        tokenURIGenerator = ITokenURIGenerator(_tokenURIGenerator);
    }

    /*//////////////////////////////////////////////////////////////
    //  External Views
    //////////////////////////////////////////////////////////////*/

    //
    // Option information
    //

    /// @inheritdoc IValoremOptionsClearinghouse
    function option(uint256 tokenId) external view returns (Option memory optionInfo) {
        (uint160 optionKey,) = _decodeTokenId(tokenId);

        if (!_isOptionInitialized(optionKey)) {
            revert TokenNotFound(tokenId);
        }

        optionInfo = optionTypeStates[optionKey].option;
    }

    /// @inheritdoc IValoremOptionsClearinghouse
    function claim(uint256 claimId) external view returns (Claim memory claimInfo) {
        (uint160 optionKey, uint96 claimKey) = _decodeTokenId(claimId);

        if (!_isClaimInitialized(optionKey, claimKey)) {
            revert TokenNotFound(claimId);
        }

        // The sum of exercised and unexercised is the amount written.
        uint256 amountWritten;
        uint256 amountExercised;

        OptionTypeState storage optionTypeState = optionTypeStates[optionKey];
        ClaimIndex[] storage claimIndexArray = optionTypeState.claimIndices[claimKey];
        uint256 len = claimIndexArray.length;

        for (uint256 i = 0; i < len; i++) {
            ClaimIndex storage claimIndex = claimIndexArray[i];
            Bucket storage bucket = optionTypeState.bucketInfo.buckets[claimIndex.bucketIndex];
            amountWritten += claimIndex.amountWritten;
            amountExercised +=
                FixedPointMathLib.divWadDown((bucket.amountExercised * claimIndex.amountWritten), bucket.amountWritten);
        }

        claimInfo = Claim({
            // Scale the amount written by WAD for consistency.
            amountWritten: amountWritten * 1e18,
            amountExercised: amountExercised,
            optionId: uint256(optionKey) << OPTION_KEY_PADDING
        });
    }

    /// @inheritdoc IValoremOptionsClearinghouse
    function position(uint256 tokenId) external view returns (Position memory positionInfo) {
        (uint160 optionKey, uint96 claimKey) = _decodeTokenId(tokenId);

        // Check the type of token and if it exists.
        TokenType typeOfToken = tokenType(tokenId);

        if (typeOfToken == TokenType.None) {
            revert TokenNotFound(tokenId);
        }

        Option storage optionRecord = optionTypeStates[optionKey].option;

        if (typeOfToken == TokenType.Option) {
            // Then tokenId is an initialized option type.

            // If the option type is expired, then it has no underlying position.
            uint40 expiry = optionRecord.expiryTimestamp;
            if (expiry <= block.timestamp) {
                revert ExpiredOption(tokenId, expiry);
            }

            positionInfo = Position({
                underlyingAsset: optionRecord.underlyingAsset,
                underlyingAmount: int256(uint256(optionRecord.underlyingAmount)),
                exerciseAsset: optionRecord.exerciseAsset,
                exerciseAmount: -int256(uint256(optionRecord.exerciseAmount))
            });
        } else {
            // Then tokenId is an initialized/unredeemed claim.
            uint256 totalUnderlyingAmount = 0;
            uint256 totalExerciseAmount = 0;

            OptionTypeState storage optionTypeState = optionTypeStates[optionKey];
            ClaimIndex[] storage claimIndices = optionTypeState.claimIndices[claimKey];
            uint256 len = claimIndices.length;
            uint256 underlyingAssetAmount = optionTypeState.option.underlyingAmount;
            uint256 exerciseAssetAmount = optionTypeState.option.exerciseAmount;

            for (uint256 i = 0; i < len; i++) {
                (uint256 indexUnderlyingAmount, uint256 indexExerciseAmount) = _getAssetAmountsForClaimIndex(
                    underlyingAssetAmount, exerciseAssetAmount, optionTypeState, claimIndices, i
                );
                totalUnderlyingAmount += indexUnderlyingAmount;
                totalExerciseAmount += indexExerciseAmount;
            }

            positionInfo = Position({
                underlyingAsset: optionRecord.underlyingAsset,
                underlyingAmount: int256(totalUnderlyingAmount),
                exerciseAsset: optionRecord.exerciseAsset,
                exerciseAmount: int256(totalExerciseAmount)
            });
        }
    }

    //
    // Token information
    //

    /// @inheritdoc IValoremOptionsClearinghouse
    function tokenType(uint256 tokenId) public view returns (TokenType typeOfToken) {
        (uint160 optionKey, uint96 claimKey) = _decodeTokenId(tokenId);

        // Default to None if option or claim is uninitialized or redeemed.
        typeOfToken = TokenType.None;

        // Check if the token is an initialized option or claim and update accordingly.
        if (_isOptionInitialized(optionKey)) {
            if ((tokenId & CLAIM_KEY_MASK) == 0) {
                typeOfToken = TokenType.Option;
            } else if (_isClaimInitialized(optionKey, claimKey)) {
                typeOfToken = TokenType.Claim;
            }
        }
    }

    /**
     * @notice Returns the URI for a given tokenId.
     * @param tokenId The tokenId of an option or claim.
     * @return The URI for the tokenId.
     */
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        Option memory optionInfo = optionTypeStates[uint160(tokenId >> OPTION_KEY_PADDING)].option;

        // Get the type of token.
        TokenType typeOfToken = tokenType(tokenId);

        // Check the token exists.
        if (typeOfToken == TokenType.None) {
            revert TokenNotFound(tokenId);
        }

        // Create the token URI params.
        ITokenURIGenerator.TokenURIParams memory params = ITokenURIGenerator.TokenURIParams({
            underlyingAsset: optionInfo.underlyingAsset,
            underlyingSymbol: ERC20(optionInfo.underlyingAsset).symbol(),
            exerciseAsset: optionInfo.exerciseAsset,
            exerciseSymbol: ERC20(optionInfo.exerciseAsset).symbol(),
            exerciseTimestamp: optionInfo.exerciseTimestamp,
            expiryTimestamp: optionInfo.expiryTimestamp,
            underlyingAmount: optionInfo.underlyingAmount,
            exerciseAmount: optionInfo.exerciseAmount,
            tokenType: typeOfToken
        });

        return tokenURIGenerator.constructTokenURI(params);
    }

    /*//////////////////////////////////////////////////////////////
    //  External Mutators
    //////////////////////////////////////////////////////////////*/

    //
    //  Write Options
    //

    /// @inheritdoc IValoremOptionsClearinghouse
    function newOptionType(
        address underlyingAsset,
        uint96 underlyingAmount,
        address exerciseAsset,
        uint96 exerciseAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp
    ) external returns (uint256 optionId) {
        // This is how to precalculate the option key and id.
        uint160 optionKey = uint160(
            bytes20(
                keccak256(
                    abi.encode(
                        underlyingAsset,
                        underlyingAmount,
                        exerciseAsset,
                        exerciseAmount,
                        exerciseTimestamp,
                        expiryTimestamp
                    )
                )
            )
        );
        optionId = uint256(optionKey) << OPTION_KEY_PADDING;

        // Check that option type does not already exist.
        if (_isOptionInitialized(optionKey)) {
            revert OptionsTypeExists(optionId);
        }

        // Check that the expiry window is of sufficient length.
        if (expiryTimestamp < (block.timestamp + 1 days)) {
            revert ExpiryWindowTooShort(expiryTimestamp);
        }

        // Check that the exercise window is of sufficient length.
        if (expiryTimestamp < (exerciseTimestamp + 1 days)) {
            revert ExerciseWindowTooShort(exerciseTimestamp);
        }

        // Check that the exercise and underlying assets are not the same.
        if (exerciseAsset == underlyingAsset) {
            revert InvalidAssets(exerciseAsset, underlyingAsset);
        }

        // Check that both tokens are ERC20 and will be redeemable by
        // instantiating them and checking supply.
        ERC20 underlyingToken = ERC20(underlyingAsset);
        ERC20 exerciseToken = ERC20(exerciseAsset);
        if (underlyingToken.totalSupply() < underlyingAmount || exerciseToken.totalSupply() < exerciseAmount) {
            revert InvalidAssets(underlyingAsset, exerciseAsset);
        }

        // Store the option type.
        optionTypeStates[optionKey].option = Option({
            underlyingAsset: underlyingAsset,
            underlyingAmount: underlyingAmount,
            exerciseAsset: exerciseAsset,
            exerciseAmount: exerciseAmount,
            exerciseTimestamp: exerciseTimestamp,
            expiryTimestamp: expiryTimestamp,
            settlementSeed: optionKey,
            nextClaimKey: 1
        });

        emit NewOptionType(
            optionId,
            exerciseAsset,
            underlyingAsset,
            exerciseAmount,
            underlyingAmount,
            exerciseTimestamp,
            expiryTimestamp
        );
    }

    /// @inheritdoc IValoremOptionsClearinghouse
    function write(uint256 tokenId, uint112 amount) external returns (uint256) {
        // Amount written must be greater than zero.
        if (amount == 0) {
            revert AmountWrittenCannotBeZero();
        }

        // Decode the optionKey and claimKey from the tokenId.
        (uint160 optionKey, uint96 claimKey) = _decodeTokenId(tokenId);

        // Sanitize a zeroed encodedOptionId from the optionKey.
        uint256 encodedOptionId = uint256(optionKey) << OPTION_KEY_PADDING;

        // Get the option record and check that it's valid to write against,
        OptionTypeState storage optionTypeState = optionTypeStates[optionKey];

        // by making sure the option exists, and hasn't expired.
        uint40 expiry = optionTypeState.option.expiryTimestamp;
        if (expiry == 0) {
            revert InvalidOption(encodedOptionId);
        }
        if (expiry <= block.timestamp) {
            revert ExpiredOption(encodedOptionId, expiry);
        }

        // Update internal bucket accounting.
        uint96 bucketIndex = _addOrUpdateBucket(optionTypeState, amount);

        // Calculate the amount to transfer in.
        uint256 rxAmount = optionTypeState.option.underlyingAmount * amount;
        address underlyingAsset = optionTypeState.option.underlyingAsset;

        // Assess a fee (if fee switch enabled) and emit events.
        uint256 fee = 0;
        if (feesEnabled) {
            fee = _calculateRecordAndEmitFee(encodedOptionId, underlyingAsset, rxAmount);
        }

        if (claimKey == 0) {
            // Then create a new claim.

            // Make encodedClaimId reflect the next available claim, and increment the next
            // available claim in storage.
            uint96 nextClaimKey = optionTypeState.option.nextClaimKey++;
            tokenId = _encodeTokenId(optionKey, nextClaimKey);

            // Add claim bucket indices.
            _addOrUpdateClaimIndex(optionTypeStates[optionKey], nextClaimKey, bucketIndex, amount);

            // Emit events about options written on a new claim.
            emit OptionsWritten(encodedOptionId, msg.sender, tokenId, amount);
            emit BucketWrittenInto(encodedOptionId, tokenId, bucketIndex, amount);

            // Transfer in the requisite underlying asset amount.
            SafeTransferLib.safeTransferFrom(ERC20(underlyingAsset), msg.sender, address(this), (rxAmount + fee));

            // Mint a new claim token and option tokens.
            uint256[] memory tokens = new uint256[](2);
            tokens[0] = encodedOptionId;
            tokens[1] = tokenId;

            uint256[] memory amounts = new uint256[](2);
            amounts[0] = amount;
            amounts[1] = 1; // claim NFT

            _batchMint(msg.sender, tokens, amounts, "");
        } else {
            // Then add to an existing claim.

            // The user must own the existing claim.
            uint256 balance = balanceOf[msg.sender][tokenId];
            if (balance != 1) {
                revert CallerDoesNotOwnClaimId(tokenId);
            }

            // Add claim bucket indices.
            _addOrUpdateClaimIndex(optionTypeStates[optionKey], claimKey, bucketIndex, amount);

            // Emit events about options written on existing claim.
            emit OptionsWritten(encodedOptionId, msg.sender, tokenId, amount);
            emit BucketWrittenInto(encodedOptionId, tokenId, bucketIndex, amount);

            // Transfer in the requisite underlying asset amount.
            SafeTransferLib.safeTransferFrom(ERC20(underlyingAsset), msg.sender, address(this), (rxAmount + fee));

            // Mint more options on existing claim to writer.
            _mint(msg.sender, encodedOptionId, amount, "");
        }

        return tokenId;
    }

    //
    //  Redeem Claims
    //

    /// @inheritdoc IValoremOptionsClearinghouse
    function redeem(uint256 claimId) external {
        (uint160 optionKey, uint96 claimKey) = _decodeTokenId(claimId);

        // You can't redeem an option.
        if (claimKey == 0) {
            revert InvalidClaim(claimId);
        }

        // If the user has a claim, we already know the claim exists and is initialized.
        uint256 balance = balanceOf[msg.sender][claimId];
        if (balance != 1) {
            revert CallerDoesNotOwnClaimId(claimId);
        }

        // Setup pointers to the option and info.
        OptionTypeState storage optionTypeState = optionTypeStates[optionKey];
        Option memory optionRecord = optionTypeState.option;

        // Can't redeem until expiry.
        if (optionRecord.expiryTimestamp > block.timestamp) {
            revert ClaimTooSoon(claimId, optionRecord.expiryTimestamp);
        }

        // Set up accumulators.
        ClaimIndex[] storage claimIndices = optionTypeState.claimIndices[claimKey];
        uint256 len = claimIndices.length;
        uint256 underlyingAssetAmount = optionTypeState.option.underlyingAmount;
        uint256 exerciseAssetAmount = optionTypeState.option.exerciseAmount;
        uint256 totalUnderlyingAssetAmount;
        uint256 totalExerciseAssetAmount;

        for (uint256 i = len; i > 0; i--) {
            (uint256 indexUnderlyingAmount, uint256 indexExerciseAmount) = _getAssetAmountsForClaimIndex(
                underlyingAssetAmount, exerciseAssetAmount, optionTypeState, claimIndices, i - 1
            );
            // Accumulate the amount exercised and unexercised in these variables
            // for later multiplication by optionRecord.exerciseAmount/underlyingAmount.
            totalUnderlyingAssetAmount += indexUnderlyingAmount;
            totalExerciseAssetAmount += indexExerciseAmount;
            // This zeroes out the array during the redemption process for a gas refund.
            claimIndices.pop();
        }

        emit ClaimRedeemed(
            claimId,
            uint256(optionKey) << OPTION_KEY_PADDING,
            msg.sender,
            totalExerciseAssetAmount,
            totalUnderlyingAssetAmount
        );

        // Burn the claim NFT and make transfers.
        _burn(msg.sender, claimId, 1);

        if (totalExerciseAssetAmount > 0) {
            SafeTransferLib.safeTransfer(ERC20(optionRecord.exerciseAsset), msg.sender, totalExerciseAssetAmount);
        }

        if (totalUnderlyingAssetAmount > 0) {
            SafeTransferLib.safeTransfer(ERC20(optionRecord.underlyingAsset), msg.sender, totalUnderlyingAssetAmount);
        }
    }

    //
    //  Exercise Options
    //

    /// @inheritdoc IValoremOptionsClearinghouse
    function exercise(uint256 optionId, uint112 amount) external {
        (uint160 optionKey, uint96 claimKey) = _decodeTokenId(optionId);

        // Must be an optionId.
        if (claimKey != 0) {
            revert InvalidOption(optionId);
        }

        OptionTypeState storage optionTypeState = optionTypeStates[optionKey];
        Option storage optionRecord = optionTypeState.option;

        // The following checks implicitly check that the option type is initialized.

        // Can't exercise an option at or after expiry.
        if (optionRecord.expiryTimestamp <= block.timestamp) {
            revert ExpiredOption(optionId, optionRecord.expiryTimestamp);
        }

        // Can't exercise an option before the exercise timestamp.
        if (optionRecord.exerciseTimestamp > block.timestamp) {
            revert ExerciseTooEarly(optionId, optionRecord.exerciseTimestamp);
        }

        if (balanceOf[msg.sender][optionId] < amount) {
            revert CallerHoldsInsufficientOptions(optionId, amount);
        }

        // Calculate the amount to transfer in/out.
        uint256 rxAmount = optionRecord.exerciseAmount * amount;
        uint256 txAmount = optionRecord.underlyingAmount * amount;
        address exerciseAsset = optionRecord.exerciseAsset;
        address underlyingAsset = optionRecord.underlyingAsset;

        // Assign exercise to writers.
        _assignExercise(optionId, optionTypeState, optionRecord, amount);

        // Assess a fee (if fee switch enabled) and emit events.
        uint256 fee = 0;
        if (feesEnabled) {
            fee = _calculateRecordAndEmitFee(optionId, exerciseAsset, rxAmount);
        }
        emit OptionsExercised(optionId, msg.sender, amount);

        _burn(msg.sender, optionId, amount);

        // Transfer in the required amount of the exercise asset.
        SafeTransferLib.safeTransferFrom(ERC20(exerciseAsset), msg.sender, address(this), (rxAmount + fee));

        // Transfer out the required amount of the underlying asset.
        SafeTransferLib.safeTransfer(ERC20(underlyingAsset), msg.sender, txAmount);
    }

    //
    //  Protocol Admin
    //

    /// @inheritdoc IValoremOptionsClearinghouse
    function setFeesEnabled(bool enabled) external onlyFeeTo {
        feesEnabled = enabled;

        emit FeeSwitchUpdated(feeTo, enabled);
    }

    /// @inheritdoc IValoremOptionsClearinghouse
    function setFeeTo(address newFeeTo) external onlyFeeTo {
        if (newFeeTo == address(0)) {
            revert InvalidAddress(address(0));
        }
        pendingFeeTo = newFeeTo;
    }

    /// @inheritdoc IValoremOptionsClearinghouse
    function acceptFeeTo() external {
        if (msg.sender != pendingFeeTo) {
            revert AccessControlViolation(msg.sender, pendingFeeTo);
        }

        feeTo = msg.sender;
        pendingFeeTo = address(0);

        emit FeeToUpdated(feeTo);
    }

    /// @inheritdoc IValoremOptionsClearinghouse
    function setTokenURIGenerator(address newTokenURIGenerator) external onlyFeeTo {
        if (newTokenURIGenerator == address(0)) {
            revert InvalidAddress(address(0));
        }
        tokenURIGenerator = ITokenURIGenerator(newTokenURIGenerator);

        emit TokenURIGeneratorUpdated(newTokenURIGenerator);
    }

    /// @inheritdoc IValoremOptionsClearinghouse
    function sweepFees(address[] calldata tokens) external onlyFeeTo {
        address sendFeeTo = feeTo;
        address token;
        uint256 fee;
        uint256 sweep;
        uint256 numTokens = tokens.length;

        unchecked {
            for (uint256 i = 0; i < numTokens; i++) {
                // Get the token and balance to sweep.
                token = tokens[i];
                fee = feeBalance[token];
                // Leave 1 wei here as a gas optimization.
                if (fee > 1) {
                    sweep = fee - 1;
                    feeBalance[token] = 1;
                    emit FeeSwept(token, sendFeeTo, sweep);
                    SafeTransferLib.safeTransfer(ERC20(token), sendFeeTo, sweep);
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
    //  Private Views
    //////////////////////////////////////////////////////////////*/

    //
    // Option information
    //

    /**
     * @notice Checks if an option type is already initialized.
     * @param optionKey The option key to check.
     * @return initialized Whether or not the option type is initialized.
     */
    function _isOptionInitialized(uint160 optionKey) private view returns (bool initialized) {
        return optionTypeStates[optionKey].option.underlyingAsset != address(0);
    }

    /**
     * @notice Checks if a claim is already initialized.
     * @param optionKey The option key to check.
     * @param claimKey The claim key to check.
     * @return initialized Whether or not the claim is initialized.
     */
    function _isClaimInitialized(uint160 optionKey, uint96 claimKey) private view returns (bool initialized) {
        return optionTypeStates[optionKey].claimIndices[claimKey].length > 0;
    }

    /// @notice Returns the exercised and unexercised amounts for a given claim index.
    function _getAssetAmountsForClaimIndex(
        uint256 underlyingAssetAmount,
        uint256 exerciseAssetAmount,
        OptionTypeState storage optionTypeState,
        ClaimIndex[] storage claimIndexArray,
        uint256 index
    ) private view returns (uint256 underlyingAmount, uint256 exerciseAmount) {
        ClaimIndex storage claimIndex = claimIndexArray[index];
        Bucket storage bucket = optionTypeState.bucketInfo.buckets[claimIndex.bucketIndex];
        uint256 claimIndexAmountWritten = claimIndex.amountWritten;
        uint256 bucketAmountWritten = bucket.amountWritten;
        uint256 bucketAmountExercised = bucket.amountExercised;
        underlyingAmount += (
            (bucketAmountWritten - bucketAmountExercised) * underlyingAssetAmount * claimIndexAmountWritten
        ) / bucketAmountWritten;
        exerciseAmount += (bucketAmountExercised * exerciseAssetAmount * claimIndexAmountWritten) / bucketAmountWritten;
    }

    //
    // Token information
    //

    /**
     * @notice Encodes the supplied option id and claim id.
     * @dev See tokenType() for encoding scheme.
     * @param optionKey The optionKey to encode.
     * @param claimKey The claimKey to encode.
     * @return tokenId The encoded token id.
     */
    function _encodeTokenId(uint160 optionKey, uint96 claimKey) private pure returns (uint256 tokenId) {
        // Encode uint160 option key into upper 160b.
        tokenId |= uint256(optionKey) << OPTION_KEY_PADDING;

        // Encode uint96 claim key into lower 96b.
        tokenId |= uint256(claimKey);
    }

    /**
     * @notice Decodes the supplied token id.
     * @dev See tokenType() for encoding scheme.
     * @param tokenId The token id to decode.
     * @return optionKey claimNum The decoded components of the id as described above, padded as required.
     */
    function _decodeTokenId(uint256 tokenId) private pure returns (uint160 optionKey, uint96 claimKey) {
        // Move option key to lsb to fit into uint160.
        optionKey = uint160(tokenId >> OPTION_KEY_PADDING);

        // Get lower 96b of tokenId for uint96 claim key.
        claimKey = uint96(tokenId & CLAIM_KEY_MASK);
    }

    /*//////////////////////////////////////////////////////////////
    //  Private Mutators
    //////////////////////////////////////////////////////////////*/

    //
    // Exercise Assignment
    //

    /**
     * @notice Performs fair exercise assignment via the pseudorandom selection of an
     * unexercised or partially exercised bucket. If the exercise amount overflows into
     * another bucket, the buckets are iterated from oldest to newest.
     */
    function _assignExercise(
        uint256 optionId,
        OptionTypeState storage optionTypeState,
        Option storage optionRecord,
        uint112 amount
    ) private {
        // Setup pointers to buckets and buckets with collateral available for exercise.
        Bucket[] storage buckets = optionTypeState.bucketInfo.buckets;
        uint96[] storage unexercisedBucketIndices = optionTypeState.bucketInfo.unexercisedBucketIndices;
        uint96 numUnexercisedBuckets = uint96(unexercisedBucketIndices.length);
        uint96 exerciseIndex = uint96(optionRecord.settlementSeed % numUnexercisedBuckets);

        while (amount > 0) {
            // Get the claim bucket to assign exercise to.
            uint96 bucketIndex = unexercisedBucketIndices[exerciseIndex];
            Bucket storage bucketInfo = buckets[bucketIndex];

            uint112 amountAvailable = bucketInfo.amountWritten - bucketInfo.amountExercised;
            uint112 amountPresentlyExercised = 0;
            if (amountAvailable <= amount) {
                // Bucket is fully exercised/assigned.
                amount -= amountAvailable;
                amountPresentlyExercised = amountAvailable;
                // Perform "swap and pop" index management.
                numUnexercisedBuckets--;
                uint96 overwrite = unexercisedBucketIndices[numUnexercisedBuckets];
                unexercisedBucketIndices[exerciseIndex] = overwrite;
                unexercisedBucketIndices.pop();
            } else {
                // Bucket is partially exercised/assigned.
                amountPresentlyExercised = amount;
                amount = 0;
            }
            bucketInfo.amountExercised += amountPresentlyExercised;

            emit BucketAssignedExercise(optionId, bucketIndex, amountPresentlyExercised);

            if (amount != 0) {
                // Get an additional bucket, because we still have options to exercise.
                exerciseIndex = (exerciseIndex + 1) % numUnexercisedBuckets;
            }
        }
    }

    /// @notice Adds or updates a bucket as needed for a given option type and amount written.
    function _addOrUpdateBucket(OptionTypeState storage optionTypeState, uint112 amount) private returns (uint96) {
        // Setup pointers to buckets.
        BucketInfo storage bucketInfo = optionTypeState.bucketInfo;
        Bucket[] storage buckets = bucketInfo.buckets;
        uint96 writtenBucketIndex = uint96(buckets.length);

        if (buckets.length == 0) {
            // Add a new bucket for this option type, because none exist.
            buckets.push(Bucket(amount, 0));
            bucketInfo.unexercisedBucketIndices.push(writtenBucketIndex);

            return writtenBucketIndex;
        }

        // Else, get the current bucket.
        uint96 currentBucketIndex = writtenBucketIndex - 1;
        Bucket storage currentBucket = buckets[currentBucketIndex];

        if (currentBucket.amountExercised != 0) {
            // Add a new bucket to this option type, because the last was partially or fully exercised.
            buckets.push(Bucket(amount, 0));
            bucketInfo.unexercisedBucketIndices.push(writtenBucketIndex);
        } else {
            // Write to the existing unexercised bucket.
            currentBucket.amountWritten += amount;
            writtenBucketIndex = currentBucketIndex;
        }

        return writtenBucketIndex;
    }

    /// @notice Updates claimIndices for a given claim key.
    function _addOrUpdateClaimIndex(
        OptionTypeState storage optionTypeState,
        uint96 claimKey,
        uint96 bucketIndex,
        uint112 amount
    ) private {
        ClaimIndex[] storage claimIndices = optionTypeState.claimIndices[claimKey];
        uint256 arrayLength = claimIndices.length;

        // If the array is empty, create a new index and return.
        if (arrayLength == 0) {
            claimIndices.push(ClaimIndex({amountWritten: amount, bucketIndex: bucketIndex}));

            return;
        }

        ClaimIndex storage lastIndex = claimIndices[arrayLength - 1];

        // If we are writing to an index that doesn't yet exist, create it and return.
        if (lastIndex.bucketIndex < bucketIndex) {
            claimIndices.push(ClaimIndex({amountWritten: amount, bucketIndex: bucketIndex}));

            return;
        }

        // Else, we are writing to an index that already exists. Update the amount written.
        lastIndex.amountWritten += amount;
    }

    //
    // Protocol Fee
    //

    /// @notice Calculates, records, and emits an event for a fee accrual.
    function _calculateRecordAndEmitFee(uint256 optionId, address assetAddress, uint256 assetAmount)
        private
        returns (uint256 fee)
    {
        // Calculate fee.
        fee = (assetAmount * feeBps) / 10_000;
        if (fee == 0) {
            fee = 1;
        }

        // Record fee.
        feeBalance[assetAddress] += fee;

        emit FeeAccrued(optionId, assetAddress, msg.sender, fee);
    }
}

// SPDX-License-Identifier: BUSL 1.1
// Valorem Labs Inc. (c) 2023.
pragma solidity 0.8.16;

import "./IValoremOptionsClearinghouse.sol";

interface ITokenURIGenerator {
    struct TokenURIParams {
        /// @param underlyingAsset The underlying asset to be received
        address underlyingAsset;
        /// @param underlyingSymbol The symbol of the underlying asset
        string underlyingSymbol;
        /// @param exerciseAsset The address of the asset needed for exercise
        address exerciseAsset;
        /// @param exerciseSymbol The symbol of the underlying asset
        string exerciseSymbol;
        /// @param exerciseTimestamp The timestamp after which this option may be exercised
        uint40 exerciseTimestamp;
        /// @param expiryTimestamp The timestamp before which this option must be exercised
        uint40 expiryTimestamp;
        /// @param underlyingAmount The amount of the underlying asset contained within an option contract of this type
        uint96 underlyingAmount;
        /// @param exerciseAmount The amount of the exercise asset required to exercise this option
        uint96 exerciseAmount;
        /// @param tokenType Option or Claim
        IValoremOptionsClearinghouse.TokenType tokenType;
    }

    /**
     * @notice Constructs a URI for a claim NFT, encoding an SVG based on parameters of the claims lot.
     * @param params Parameters for the token URI.
     * @return A string with the SVG encoded in Base64.
     */
    function constructTokenURI(TokenURIParams memory params) external view returns (string memory);

    /**
     * @notice Generates a name for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated name for the NFT.
     */
    function generateName(TokenURIParams memory params) external pure returns (string memory);

    /**
     * @notice Generates a description for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated description for the NFT.
     */
    function generateDescription(TokenURIParams memory params) external pure returns (string memory);

    /**
     * @notice Generates a svg for the NFT based on the supplied params.
     * @param params Parameters for the token URI.
     * @return A generated svg for the NFT.
     */
    function generateNFT(TokenURIParams memory params) external view returns (string memory);
}

// SPDX-License-Identifier: BUSL 1.1
// Valorem Labs Inc. (c) 2023.
pragma solidity 0.8.16;

import "./ITokenURIGenerator.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                //
//   $$$$$$$$$$                                                                                   //
//    $$$$$$$$                                  _|                                                //
//     $$$$$$ $$$$$$$$$$   _|      _|   _|_|_|  _|    _|_|    _|  _|_|   _|_|    _|_|_|  _|_|     //
//       $$    $$$$$$$$    _|      _| _|    _|  _|  _|    _|  _|_|     _|_|_|_|  _|    _|    _|   //
//   $$$$$$$$$$ $$$$$$       _|  _|   _|    _|  _|  _|    _|  _|       _|        _|    _|    _|   //
//    $$$$$$$$    $$           _|       _|_|_|  _|    _|_|    _|         _|_|_|  _|    _|    _|   //
//     $$$$$$                                                                                     //
//       $$                                                                                       //
//                                                                                                //
//////////////////////////////////////////////////////////////////////////////////////////////////*/

/**
 * @title A clearing and settling engine for options on ERC20 tokens.
 * @author 0xAlcibiades
 * @author Flip-Liquid
 * @author neodaoist
 * @notice Valorem Options V1 is a DeFi money lego for writing physically
 * settled covered call and covered put options. All Valorem options are fully
 * collateralized with an ERC-20 underlying asset and exercised with an
 * ERC-20 exercise asset using a fair assignment process. Option contracts, or
 * long positions, are issued as fungible ERC-1155 tokens, with each token
 * representing a contract. Option writers are additionally issued an ERC-1155
 * NFT claim, or short position, which is used to claim collateral and for
 * option exercise assignment.
 */
interface IValoremOptionsClearinghouse {
    /*//////////////////////////////////////////////////////////////
    //  Events
    //////////////////////////////////////////////////////////////*/

    //
    // Write events
    //

    /**
     * @notice Emitted when a new option type is created.
     * @param optionId The token id of the new option type created.
     * @param exerciseAsset The ERC20 contract address of the exercise asset.
     * @param underlyingAsset The ERC20 contract address of the underlying asset.
     * @param exerciseAmount The amount, in wei, of the exercise asset required to exercise each contract.
     * @param underlyingAmount The amount, in wei of the underlying asset in each contract.
     * @param exerciseTimestamp The timestamp after which this option type can be exercised.
     * @param expiryTimestamp The timestamp before which this option type can be exercised.
     */
    event NewOptionType(
        uint256 optionId,
        address indexed exerciseAsset,
        address indexed underlyingAsset,
        uint96 exerciseAmount,
        uint96 underlyingAmount,
        uint40 exerciseTimestamp,
        uint40 indexed expiryTimestamp
    );

    /**
     * @notice Emitted when new options contracts are written.
     * @param optionId The token id of the option type written.
     * @param writer The address of the writer.
     * @param claimId The claim token id of the new or existing short position written against.
     * @param amount The amount of options contracts written.
     */
    event OptionsWritten(uint256 indexed optionId, address indexed writer, uint256 indexed claimId, uint112 amount);

    /**
     * @notice Emitted when options contracts are written into a bucket.
     * @param optionId The token id of the option type written.
     * @param claimId The claim token id of the new or existing short position written against.
     * @param bucketIndex The index of the bucket to which the options were written.
     * @param amount The amount of options contracts written.
     */
    event BucketWrittenInto(
        uint256 indexed optionId, uint256 indexed claimId, uint96 indexed bucketIndex, uint112 amount
    );

    //
    // Redeem events
    //

    /**
     * @notice Emitted when a claim is redeemed.
     * @param optionId The token id of the option type of the claim being redeemed.
     * @param claimId The token id of the claim being redeemed.
     * @param redeemer The address redeeming the claim.
     * @param exerciseAmountRedeemed The amount of the option.exerciseAsset redeemed.
     * @param underlyingAmountRedeemed The amount of option.underlyingAsset redeemed.
     */
    event ClaimRedeemed(
        uint256 indexed claimId,
        uint256 indexed optionId,
        address indexed redeemer,
        uint256 exerciseAmountRedeemed,
        uint256 underlyingAmountRedeemed
    );

    //
    // Exercise events
    //

    /**
     * @notice Emitted when option contract(s) is(are) exercised.
     * @param optionId The token id of the option type exercised.
     * @param exerciser The address that exercised the option contract(s).
     * @param amount The amount of option contracts exercised.
     */
    event OptionsExercised(uint256 indexed optionId, address indexed exerciser, uint112 amount);

    /**
     * @notice Emitted when a bucket is assigned exercise.
     * @param optionId The token id of the option type exercised.
     * @param bucketIndex The index of the bucket which is being assigned exercise.
     * @param amountAssigned The amount of options contracts assigned exercise in the given bucket.
     */
    event BucketAssignedExercise(uint256 indexed optionId, uint96 indexed bucketIndex, uint112 amountAssigned);

    //
    // Fee events
    //

    /**
     * @notice Emitted when protocol fees are accrued for a given asset.
     * @dev Emitted on write() when fees are accrued on the underlying asset,
     * or exercise() when fees are accrued on the exercise asset.
     * Will not be emitted when feesEnabled is false.
     * @param optionId The token id of the option type being written or exercised.
     * @param asset The ERC20 asset in which fees were accrued.
     * @param payer The address paying the fee.
     * @param amount The amount, in wei, of fees accrued.
     */
    event FeeAccrued(uint256 indexed optionId, address indexed asset, address indexed payer, uint256 amount);

    /**
     * @notice Emitted when accrued protocol fees for a given ERC20 asset are swept to the
     * feeTo address.
     * @param asset The ERC20 asset of the protocol fees swept.
     * @param feeTo The account to which fees were swept.
     * @param amount The total amount swept.
     */
    event FeeSwept(address indexed asset, address indexed feeTo, uint256 amount);

    /**
     * @notice Emitted when protocol fees are enabled or disabled.
     * @param feeTo The address which enabled or disabled fees.
     * @param enabled Whether fees are enabled or disabled.
     */
    event FeeSwitchUpdated(address feeTo, bool enabled);

    //
    // Access control events
    //

    /**
     * @notice Emitted when feeTo address is updated.
     * @param newFeeTo The new feeTo address.
     */
    event FeeToUpdated(address indexed newFeeTo);

    /**
     * @notice Emitted when TokenURIGenerator is updated.
     * @param newTokenURIGenerator The new TokenURIGenerator address.
     */
    event TokenURIGeneratorUpdated(address indexed newTokenURIGenerator);

    /*//////////////////////////////////////////////////////////////
    //  Errors
    //////////////////////////////////////////////////////////////*/

    //
    // Access control errors
    //

    /**
     * @notice The caller doesn't have permission to access that function.
     * @param accessor The requesting address.
     * @param permissioned The address which has the requisite permissions.
     */
    error AccessControlViolation(address accessor, address permissioned);

    //
    // Input errors
    //

    /// @notice The amount of option contracts written must be greater than zero.
    error AmountWrittenCannotBeZero();

    /**
     * @notice This claim is not owned by the caller.
     * @param claimId Supplied claim ID.
     */
    error CallerDoesNotOwnClaimId(uint256 claimId);

    /**
     * @notice The caller does not have enough option contracts to exercise the amount
     * specified.
     * @param optionId The supplied option id.
     * @param amount The amount of option contracts which the caller attempted to exercise.
     */
    error CallerHoldsInsufficientOptions(uint256 optionId, uint112 amount);

    /**
     * @notice Claims cannot be redeemed before expiry.
     * @param claimId Supplied claim ID.
     * @param expiry timestamp at which the option type expires.
     */
    error ClaimTooSoon(uint256 claimId, uint40 expiry);

    /**
     * @notice This option cannot yet be exercised.
     * @param optionId Supplied option ID.
     * @param exercise The time after which the option optionId be exercised.
     */
    error ExerciseTooEarly(uint256 optionId, uint40 exercise);

    /**
     * @notice The option exercise window is too short.
     * @param exercise The timestamp supplied for exercise.
     */
    error ExerciseWindowTooShort(uint40 exercise);

    /**
     * @notice The optionId specified expired has already expired.
     * @param optionId The id of the expired option.
     * @param expiry The expiry time for the supplied option Id.
     */
    error ExpiredOption(uint256 optionId, uint40 expiry);

    /**
     * @notice The expiry timestamp is too soon.
     * @param expiry Timestamp of expiry.
     */
    error ExpiryWindowTooShort(uint40 expiry);

    /**
     * @notice Invalid (zero) address.
     * @param input The address input.
     */
    error InvalidAddress(address input);

    /**
     * @notice The assets specified are invalid or duplicate.
     * @param asset1 Supplied ERC20 asset.
     * @param asset2 Supplied ERC20 asset.
     */
    error InvalidAssets(address asset1, address asset2);

    /**
     * @notice The token specified is not a claim token.
     * @param token The supplied token id.
     */
    error InvalidClaim(uint256 token);

    /**
     * @notice The token specified is not an option token.
     * @param token The supplied token id.
     */
    error InvalidOption(uint256 token);

    /**
     * @notice This option contract type already exists and thus cannot be created.
     * @param optionId The token id of the option type which already exists.
     */
    error OptionsTypeExists(uint256 optionId);

    /**
     * @notice The requested token is not found.
     * @param token The token requested.
     */
    error TokenNotFound(uint256 token);

    /*//////////////////////////////////////////////////////////////
    //  Data Structures
    //////////////////////////////////////////////////////////////*/

    /// @notice The type of an ERC1155 subtoken in the clearinghouse.
    enum TokenType {
        None,
        Option,
        Claim
    }

    /// @notice Data comprising the unique tuple of an option type associated with an ERC-1155 option token.
    struct Option {
        /// @custom:member underlyingAsset The underlying ERC20 asset which the option is collateralized with.
        address underlyingAsset;
        /// @custom:member underlyingAmount The amount of the underlying asset contained within an option contract of this type.
        uint96 underlyingAmount;
        /// @custom:member exerciseAsset The ERC20 asset which the option can be exercised using.
        address exerciseAsset;
        /// @custom:member exerciseAmount The amount of the exercise asset required to exercise each option contract of this type.
        uint96 exerciseAmount;
        /// @custom:member exerciseTimestamp The timestamp after which this option can be exercised.
        uint40 exerciseTimestamp;
        /// @custom:member expiryTimestamp The timestamp before which this option can be exercised.
        uint40 expiryTimestamp;
        /// @custom:member settlementSeed Deterministic seed used for option fair exercise assignment.
        uint160 settlementSeed;
        /// @custom:member nextClaimKey The next claim key available for this option type.
        uint96 nextClaimKey;
    }

    /**
     * @notice Data about a claim to a short position written on an option type.
     * When writing an amount of options of a particular type, the writer will be issued an ERC 1155 NFT
     * that represents a claim to the underlying and exercise assets, to be claimed after
     * expiry of the option. The amount of each (underlying asset and exercise asset) paid to the claimant upon
     * redeeming their claim NFT depends on the option type, the amount of options written, represented in this struct,
     * and what portion of this claim was assigned exercise, if any, before expiry.
     */
    struct Claim {
        /// @custom:member amountWritten The number of option contracts written against this claim expressed as a 1e18 scalar value.
        uint256 amountWritten;
        /// @custom:member amountExercised The amount of option contracts exercised against this claim expressed as a 1e18 scalar value.
        uint256 amountExercised;
        /// @custom:member optionId The option ID of the option type this claim is for.
        uint256 optionId;
    }

    /**
     * @notice Data about the ERC20 assets and liabilities for a given option (long) or claim (short) token,
     * in terms of the underlying and exercise ERC20 tokens.
     */
    struct Position {
        /// @custom:member underlyingAsset The address of the ERC20 underlying asset.
        address underlyingAsset;
        /// @custom:member underlyingAmount The amount, in wei, of the underlying asset represented by this position.
        int256 underlyingAmount;
        /// @custom:member exerciseAsset The address of the ERC20 exercise asset.
        address exerciseAsset;
        /// @custom:member exerciseAmount The amount, in wei, of the exercise asset represented by this position.
        int256 exerciseAmount;
    }

    /*//////////////////////////////////////////////////////////////
    //  Views
    //////////////////////////////////////////////////////////////*/

    //
    // Option information
    //

    /**
     * @notice Gets information about an option.
     * @param tokenId The tokenId of an option or claim.
     * @return optionInfo The Option for the given tokenId.
     */
    function option(uint256 tokenId) external view returns (Option memory optionInfo);

    /**
     * @notice Gets information about a claim.
     * @param claimId The tokenId of the claim.
     * @return claimInfo The Claim for the given claimId.
     */
    function claim(uint256 claimId) external view returns (Claim memory claimInfo);

    /**
     * @notice Gets information about the ERC20 token positions of an option or claim.
     * @param tokenId The tokenId of the option or claim.
     * @return positionInfo The underlying and exercise token positions for the given tokenId.
     */
    function position(uint256 tokenId) external view returns (Position memory positionInfo);

    //
    // Token information
    //

    /**
     * @notice Gets the TokenType for a given tokenId.
     * @dev Option and claim token ids are encoded as follows:
     *
     *   MSb
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 160b option key, created Option struct hash.
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 │
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┐
     *   0000 0000   0000 0000   0000 0000   0000 0000 │ 96b auto-incrementing claim key.
     *   0000 0000   0000 0000   0000 0000   0000 0000 ┘
     *                                             LSb
     * This function accounts for that, and whether or not tokenId has been initialized/decommissioned yet.
     * @param tokenId The token id to get the TokenType of.
     * @return typeOfToken The enum TokenType of the tokenId.
     */
    function tokenType(uint256 tokenId) external view returns (TokenType typeOfToken);

    /**
     * @notice Gets the contract address for generating token URIs for tokens.
     * @return uriGenerator the address of the URI generator contract.
     */
    function tokenURIGenerator() external view returns (ITokenURIGenerator uriGenerator);

    //
    // Fee information
    //

    /**
     * @notice Gets the balance of protocol fees for a given token which have not been swept yet.
     * @param token The token for the un-swept fee balance.
     * @return The balance of un-swept fees.
     */
    function feeBalance(address token) external view returns (uint256);

    /**
     * @notice Gets the protocol fee, expressed in basis points.
     * @return fee The protocol fee.
     */
    function feeBps() external view returns (uint8 fee);

    /**
     * @notice Checks if protocol fees are enabled.
     * @return enabled Whether or not protocol fees are enabled.
     */
    function feesEnabled() external view returns (bool enabled);

    /**
     * @notice Returns the address to which protocol fees are swept.
     * @return The address to which fees are swept.
     */
    function feeTo() external view returns (address);

    /*//////////////////////////////////////////////////////////////
    //  Write Options
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a new option contract type if it doesn't already exist.
     * @dev optionId can be precomputed using
     *  uint160 optionKey = uint160(
     *      bytes20(
     *          keccak256(
     *              abi.encode(
     *                  underlyingAsset,
     *                  underlyingAmount,
     *                  exerciseAsset,
     *                  exerciseAmount,
     *                  exerciseTimestamp,
     *                  expiryTimestamp,
     *                  uint160(0),
     *                  uint96(0)
     *              )
     *          )
     *      )
     *  );
     *  optionId = uint256(optionKey) << OPTION_ID_PADDING;
     * and then tokenType(optionId) == TokenType.Option if the option already exists.
     * @param underlyingAsset The contract address of the ERC20 underlying asset.
     * @param underlyingAmount The amount of underlyingAsset, in wei, collateralizing each option contract.
     * @param exerciseAsset The contract address of the ERC20 exercise asset.
     * @param exerciseAmount The amount of exerciseAsset, in wei, required to exercise each option contract.
     * @param exerciseTimestamp The timestamp after which this option can be exercised.
     * @param expiryTimestamp The timestamp before which this option can be exercised.
     * @return optionId The token id for the new option type created by this call.
     */
    function newOptionType(
        address underlyingAsset,
        uint96 underlyingAmount,
        address exerciseAsset,
        uint96 exerciseAmount,
        uint40 exerciseTimestamp,
        uint40 expiryTimestamp
    ) external returns (uint256 optionId);

    /**
     * @notice Writes a specified amount of the specified option, returning claim NFT id.
     * @param tokenId The desired token id to write against, input an optionId to get a new claim, or a claimId
     * to add to an existing claim.
     * @param amount The desired number of option contracts to write.
     * @return claimId The token id of the claim NFT which was input or created.
     */
    function write(uint256 tokenId, uint112 amount) external returns (uint256 claimId);

    /*//////////////////////////////////////////////////////////////
    //  Redeem Claims
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Redeems a claim NFT, transfers the underlying/exercise tokens to the caller.
     * Can be called after option expiry timestamp (inclusive).
     * @param claimId The ID of the claim to redeem.
     */
    function redeem(uint256 claimId) external;

    /*//////////////////////////////////////////////////////////////
    //  Exercise Options
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Exercises specified amount of optionId, transferring in the exercise asset,
     * and transferring out the underlying asset if requirements are met. Can be called
     * from exercise timestamp (inclusive), until option expiry timestamp (exclusive).
     * @param optionId The option token id of the option type to exercise.
     * @param amount The amount of option contracts to exercise.
     */
    function exercise(uint256 optionId, uint112 amount) external;

    /*//////////////////////////////////////////////////////////////
    //  Protocol Admin
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Enables or disables protocol fees.
     * @param enabled Whether or not protocol fees should be enabled.
     */
    function setFeesEnabled(bool enabled) external;

    /**
     * @notice Nominates a new address to which fees should be swept, requiring
     * the new feeTo address to accept before the update is complete. See also
     * acceptFeeTo().
     * @param newFeeTo The new address to which fees should be swept.
     */
    function setFeeTo(address newFeeTo) external;

    /**
     * @notice Accepts the new feeTo address and completes the update.
     * See also setFeeTo(address newFeeTo).
     */
    function acceptFeeTo() external;

    /**
     * @notice Updates the contract address for generating token URIs for tokens.
     * @param newTokenURIGenerator The address of the new ITokenURIGenerator contract.
     */
    function setTokenURIGenerator(address newTokenURIGenerator) external;

    /**
     * @notice Sweeps fees to the feeTo address if there is more than 1 wei for
     * feeBalance for a given token.
     * @param tokens An array of tokens to sweep fees for.
     */
    function sweepFees(address[] memory tokens) external;
}