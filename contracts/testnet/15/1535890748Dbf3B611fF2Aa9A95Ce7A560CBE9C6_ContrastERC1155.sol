/**
 *Submitted for verification at Arbiscan on 2023-04-30
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.8.17;

/// @notice Class with helper read functions for clone with immutable args.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Clone.sol)
/// @author Adapted from clones with immutable args by zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
abstract contract Clone {
    /// @dev Reads an immutable arg with type bytes.
    function _getArgBytes(uint256 argOffset, uint256 length)
        internal
        pure
        returns (bytes memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            arg := mload(0x40)
            // Store the array length.
            mstore(arg, length)
            // Copy the array.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), length)
            // Allocate the memory, rounded up to the next 32 byte boudnary.
            mstore(0x40, and(add(add(arg, 0x3f), length), not(0x1f)))
        }
    }

    /// @dev Reads an immutable arg with type address.
    function _getArgAddress(uint256 argOffset) internal pure returns (address arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0x60, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint256
    function _getArgUint256(uint256 argOffset) internal pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := calldataload(add(offset, argOffset))
        }
    }

    /// @dev Reads a uint256 array stored in the immutable args.
    function _getArgUint256Array(uint256 argOffset, uint256 length)
        internal
        pure
        returns (uint256[] memory arg)
    {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            arg := mload(0x40)
            // Store the array length.
            mstore(arg, length)
            // Copy the array.
            calldatacopy(add(arg, 0x20), add(offset, argOffset), shl(5, length))
            // Allocate the memory.
            mstore(0x40, add(add(arg, 0x20), shl(5, length)))
        }
    }

    /// @dev Reads an immutable arg with type uint64.
    function _getArgUint64(uint256 argOffset) internal pure returns (uint64 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0xc0, calldataload(add(offset, argOffset)))
        }
    }

    /// @dev Reads an immutable arg with type uint8.
    function _getArgUint8(uint256 argOffset) internal pure returns (uint8 arg) {
        uint256 offset = _getImmutableArgsOffset();
        /// @solidity memory-safe-assembly
        assembly {
            arg := shr(0xf8, calldataload(add(offset, argOffset)))
        }
    }

    /// @return offset The offset of the packed immutable args in calldata.
    function _getImmutableArgsOffset() internal pure returns (uint256 offset) {
        /// @solidity memory-safe-assembly
        assembly {
            offset := sub(calldatasize(), shr(0xf0, calldataload(sub(calldatasize(), 2))))
        }
    }
}

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

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
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

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

abstract contract ERC1155Supply is ERC1155 {
    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @notice A mapping from token IDs to the sum of balances for that given token ID.
    mapping(uint256 => uint256) public totalSupply;

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id, uint256 amount, bytes memory data)
        internal
        virtual
        override
    {
        totalSupply[id] += amount;

        // Safe because balance cannot be greater than totalSupply.
        unchecked {
            balanceOf[to][id] += amount;
        }

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(
                    msg.sender, address(0), id, amount, data
                ) == ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength;) {
            totalSupply[ids[i]] += amounts[i];

            // Safe because balance cannot be greater than totalSupply.
            unchecked {
                balanceOf[to][ids[i]] += amounts[i];
            }

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
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(
                    msg.sender, address(0), ids, amounts, data
                ) == ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength;) {
            balanceOf[from][ids[i]] -= amounts[i];

            // Safe because totalSupply is always greater than or equal to any given balance.
            unchecked {
                totalSupply[ids[i]] -= amounts[i];
            }

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(address from, uint256 id, uint256 amount)
        internal
        virtual
        override
    {
        balanceOf[from][id] -= amount;

        // Safe because totalSupply is always greater than or equal to any given balance.
        unchecked {
            totalSupply[id] -= amount;
        }

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

enum Direction {
    PUT,
    CALL
}

enum Outcome {
    FALSE,
    TRUE,
    UNDETERMINED
}

/// @title Market
/// @dev A struct representing a prediction market.
/// @notice `priceFeed` Chainlink price feed used to determine the market outcome.
/// @notice `exchangeRate` Exchange rate for the market.
/// @notice `maturity` Timestamp when the market matures.
/// @notice `creation` Timestamp when the market was created.
/// @notice `strike` Strike price for the market.
/// @notice `settleWindow` Duration of the settle window, in seconds.
/// @notice `transferWindow` Duration of the transfer window, in seconds.
/// @notice `roundId` ID of the price feed round.
/// @notice `outcome` Outcome of the market.
/// @notice `direction` Type of option market.
struct Market {
    AggregatorV3Interface priceFeed;
    uint96 exchangeRate;
    uint64 maturity;
    uint64 creation;
    uint96 strike;
    uint32 settleWindow;
    uint32 transferWindow;
    uint80 roundId;
    Outcome outcome;
    Direction direction;
}

/// @title Quote
/// @dev A struct representing a quote provided by a user.
/// @notice `quoter` Address of the user that provided the quote.
/// @notice `roundId` ID of the price feed round.
/// @notice `creation` Timestamp when the quote was submitted to this contract.
/// @notice `inaccuracy` Time delta between the markets maturity and the time of the quote.
struct Quote {
    address quoter;
    uint80 roundId;
    uint64 creation;
    uint64 inaccuracy;
}

contract ContrastERC1155 is Owned(address(0)), Clone, ERC1155Supply {
    /// -----------------------------------------------------------------------
    /// Dependencies
    /// -----------------------------------------------------------------------

    using SafeCastLib for *;

    using SafeTransferLib for ERC20;

    using FixedPointMathLib for uint256;

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emitted when a new market is created.
    /// @param marketId The ID of the new market.
    /// @param priceFeed The price feed used to determine the market outcome.
    /// @param strike The strike price of the market.
    /// @param maturity The maturity time of the market.
    event MarketCreated(
        uint256 indexed marketId,
        address priceFeed,
        uint256 strike,
        uint256 maturity
    );

    /// @dev Emitted when a user enters a market.
    /// @param marketId The ID of the market.
    /// @param caller The address of the user who entered the market.
    /// @param amount0 The amount of the false outcome token minted.
    /// @param amount1 The amount of the true outcome token minted.
    event MarketEntered(
        uint256 indexed marketId,
        address indexed caller,
        uint256 amount0,
        uint256 amount1
    );

    /// @dev Emitted when a user exits a market.
    /// @param marketId The ID of the market.
    /// @param caller The address of the user who exited the market.
    /// @param amount0 The amount of the false outcome token burned.
    /// @param amount1 The amount of the true outcome token burned.
    event MarketExited(
        uint256 indexed marketId,
        address indexed caller,
        uint256 amount0,
        uint256 amount1
    );

    /// @dev Emitted when a user redeems their shares in a market.
    /// @param marketId The ID of the market.
    /// @param caller The address of the user who redeemed their shares.
    /// @param amountIn The amount of tokens input for redemption.
    /// @param amountOut The amount of tokens received after redemption.
    event MarketRedemption(
        uint256 indexed marketId,
        address indexed caller,
        uint256 amountIn,
        uint256 amountOut
    );

    /// @dev Emitted when a quote is added to a market.
    /// @param marketId The ID of the market.
    /// @param roundId The ID of the quote round.
    /// @param answer The answer of the quote.
    event MarketQuoted(
        uint256 indexed marketId, uint256 roundId, int256 answer
    );

    /// @dev Emitted when a market is settled.
    /// @param marketId The ID of the market.
    /// @param roundId The ID of the quote round used for settlement.
    /// @param answer The answer of the quote used for settlement.
    event MarketSettled(
        uint256 indexed marketId, uint256 roundId, int256 answer
    );

    /// @dev Emitted when an emergency withdrawal is made from a market.
    /// @param marketId The ID of the market.
    /// @param amountOut The amount of tokens withdrawn.
    event EmergencyWithdrawal(uint256 indexed marketId, uint256 amountOut);

    /// @dev Emitted when an fee withdrawal is made.
    /// @param amountOut The amount of tokens withdrawn.
    event FeeWithdrawal(uint256 amountOut);

    /// -----------------------------------------------------------------------
    /// Constants
    /// -----------------------------------------------------------------------

    uint256 internal constant TRANSFER_FEE_BIPS = 20;

    uint256 internal constant REDEEM_FEE_BIPS = 500;

    /// -----------------------------------------------------------------------
    /// Mutable Storage
    /// -----------------------------------------------------------------------

    /// @notice An array of Market structs to store all the available markets.
    Market[] public markets;

    /// @notice A mapping of Quote structs to store all the quotes indexed by their unique ID.
    mapping(uint256 => Quote) public quotes;

    /// @notice Total accumulated management fees.
    uint256 public accumulatedFees;

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    /// @dev The ERC20 token used for trading in every market.
    function ASSET() public pure returns (ERC20) {
        return ERC20(_getArgAddress(0x0));
    }

    /// @dev The amount of the bond currency required to create a quote.
    function QUOTE_BOND_AMOUNT() public pure returns (uint256 arg) {
        uint256 offset = _getImmutableArgsOffset();
        assembly {
            arg := shr(0xa0, calldataload(add(offset, 0x14)))
        }
    }

    /// @dev The duration of the dispute window for a quote in seconds.
    function QUOTE_DISPUTE_WINDOW() public pure returns (uint256) {
        return uint256(_getArgUint64(0x20));
    }

    /// @dev The duration of time in seconds after which emergency withdrawals can be made for a quote.
    function EMERGENCY_WITHDRAWAL_WINDOW() public pure returns (uint256) {
        return uint256(_getArgUint64(0x28));
    }

    function immutables()
        external
        pure
        returns (
            address asset,
            uint256 quoteBondAmount,
            uint256 quoteDisputeWindow,
            uint256 emergencyWithdrawalWindow
        )
    {
        return (
            address(ASSET()),
            QUOTE_BOND_AMOUNT(),
            QUOTE_DISPUTE_WINDOW(),
            EMERGENCY_WITHDRAWAL_WINDOW()
        );
    }

    /// -----------------------------------------------------------------------
    /// Immutable Storage
    /// -----------------------------------------------------------------------

    error ALREADY_INITIALIZED();

    bool internal initialized;

    function initialize(address _owner) external virtual {
        if (initialized) revert ALREADY_INITIALIZED();

        initialized = true;

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Market Helper Logic
    /// -----------------------------------------------------------------------

    function totalMarkets() external view returns (uint256) {
        return markets.length;
    }

    function idsForMarket(uint256 marketId)
        public
        pure
        returns (uint256 id0, uint256 id1)
    {
        id0 = marketId << 1;
        id1 = id0 + 1;
    }

    /// -----------------------------------------------------------------------
    /// Option Creation Logic
    /// -----------------------------------------------------------------------

    error TRANSFER_WINDOW_ELAPSES_MATURITY();

    /// @notice Creates a new prediction market.
    /// @param priceFeed The price feed used to determine the market outcome.
    /// @param strike The strike price for the market.
    /// @param maturity The timestamp when the market matures.
    /// @param transferWindow The duration of the transfer window, in seconds.
    /// @param settleWindow The duration of the settle window, in seconds.
    /// @param direction The type of option market (call/put).
    /// @return marketId The ID of the newly created market.
    function create(
        address priceFeed,
        uint96 strike,
        uint64 maturity,
        uint32 transferWindow,
        uint32 settleWindow,
        Direction direction
    ) external onlyOwner returns (uint256 marketId) {
        // Checks:
        //     - The function can only be called by the owner of the contract, as defined
        //         by the onlyOwner modifier. This ensures that only authorized parties can
        //         create new markets.
        //     - The function checks if the maturity date of the option is greater than
        //         the current block timestamp plus the transfer window period. This check
        //         ensures that the transfer window period ends before the option matures,
        //         which is required for proper option trading.
        if (maturity <= block.timestamp + transferWindow) {
            revert TRANSFER_WINDOW_ELAPSES_MATURITY();
        }

        // Effects:
        //     - The function creates two new ERC20 tokens (one for "true" outcomes and
        //         one for "false" outcomes) using the ContrastERC20 contract. These tokens
        //         will be used to represent the options being traded in the market.
        //     - The function creates a new Market struct and appends it to the markets
        //         array. This struct contains information about the market, including the
        //         currency being used, the price feed, the two ERC20 tokens representing
        //         the option outcomes, the option outcome, direction, strike price, maturity
        //         date, transfer and settle window periods, round ID, and exchange rate.
        //     - The function emits a MarketCreated event.
        marketId = markets.length;

        markets.push(
            Market({
                priceFeed: AggregatorV3Interface(priceFeed),
                exchangeRate: 0,
                maturity: maturity,
                creation: uint64(block.timestamp),
                strike: strike,
                settleWindow: settleWindow,
                transferWindow: transferWindow,
                roundId: 0,
                outcome: Outcome.UNDETERMINED,
                direction: direction
            })
        );

        emit MarketCreated(marketId, priceFeed, strike, maturity);
    }

    /// -----------------------------------------------------------------------
    /// Option User Actions
    /// -----------------------------------------------------------------------

    error TRANSFER_WINDOW_HAS_ELAPSED();

    /// @notice Allows users to enter the prediction market by depositing ERC20 tokens
    /// in exchange for the corresponding outcome tokens.
    /// @param marketId The ID of the market the user wishes to enter.
    /// @param amount0 The amount of false outcome tokens the user wishes to receive.
    /// @param amount1 The amount of true outcome tokens the user wishes to receive.
    /// @dev The function also collects a transfer fee, which is a percentage of the specified amount
    /// of outcome tokens being exchanged. The fee is defined by the TRANSFER_FEE_BIPS constant.
    function enter(uint256 marketId, uint256 amount0, uint256 amount1)
        external
        virtual
    {
        // Checks:
        // - The current timestamp must be less than or equal to the creation time plus
        //     the transfer window period for the specified market. This ensures that the transfer
        //     window is still open for the market, and users are not able to enter the market after
        //     the transfer window has closed.
        Market memory market = markets[marketId];

        if (block.timestamp > market.creation + market.transferWindow) {
            revert TRANSFER_WINDOW_HAS_ELAPSED();
        }

        // Effects:
        // - The function transfers the total specified amount of ERC20 tokens from the user to the contract.
        // - The function calculates the total transfer fees, which are a percentage of the specified amount
        //      of outcome tokens being exchanged, as defined by the TRANSFER_FEE_BIPS constant. It then increases
        //      the accumulated fees mapping for the market's currency by the total amount of fees collected.
        // - The function mints the specified amount of each outcome token to the user, minus the transfer fee.
        // - The function emits a MarketEntered event.
        ASSET().safeTransferFrom(msg.sender, address(this), amount0 + amount1);

        uint256 fee0 = amount0.mulDivDown(TRANSFER_FEE_BIPS, 10_000);
        uint256 fee1 = amount1.mulDivDown(TRANSFER_FEE_BIPS, 10_000);

        uint256 adjusted0 = amount0 - fee0;
        uint256 adjusted1 = amount1 - fee1;

        accumulatedFees += fee0 + fee1;

        (uint256 id0, uint256 id1) = idsForMarket(marketId);

        if (amount0 > 0) _mint(msg.sender, id0, adjusted0, "");
        if (amount1 > 0) _mint(msg.sender, id1, adjusted1, "");

        emit MarketEntered(marketId, msg.sender, adjusted0, adjusted1);
    }

    /// @notice Allows users to exit the prediction market by burning their outcome
    /// tokens in exchange for their underlying counterpart.
    /// @param marketId The ID of the market the user wishes to exit.
    /// @param amount0 The amount of false outcome tokens the user wishes to burn.
    /// @param amount1 The amount of true outcome tokens the user wishes to burn.
    /// @dev The function also collects a transfer fee, which is a percentage of the specified amount
    /// of outcome tokens being exchanged. The fee is defined by the TRANSFER_FEE_BIPS constant.
    function exit(uint256 marketId, uint256 amount0, uint256 amount1)
        external
        virtual
    {
        // Checks:
        // - The current timestamp must be less than or equal to the creation time plus
        //     the transfer window period for the specified market. This ensures that the transfer
        //     window is still open for the market, and users are not able to exit the market after
        //     the transfer window has closed.
        Market memory market = markets[marketId];

        if (block.timestamp > market.creation + market.transferWindow) {
            revert TRANSFER_WINDOW_HAS_ELAPSED();
        }

        // Effects:
        // - The function burns the specified amount of each outcome token from the user.
        // - The function calculates the total transfer fees, which are a percentage of the specified amount
        //      of outcome tokens being exchanged, as defined by the TRANSFER_FEE_BIPS constant. It then increases
        //      the accumulated fees mapping for the market's currency by the total amount of fees collected.
        // - The function transfers the corresponding amount of ERC20 tokens from the contract to the user,
        //      minus the tranfer fee.
        // - The function emits a MarketExited event.
        (uint256 id0, uint256 id1) = idsForMarket(marketId);

        if (amount0 > 0) _burn(msg.sender, id0, amount0);
        if (amount1 > 0) _burn(msg.sender, id1, amount1);

        uint256 fee = amount0.mulDivDown(TRANSFER_FEE_BIPS, 10_000)
            + amount1.mulDivDown(TRANSFER_FEE_BIPS, 10_000);

        uint256 adjusted = amount0 + amount1 - fee;

        accumulatedFees += fee;

        ASSET().safeTransfer(msg.sender, adjusted);

        emit MarketExited(marketId, msg.sender, amount0, amount1);
    }

    error MARKET_HAS_NOT_BEEN_SETTLED();

    /// @notice Allows users to redeem their winnings from a prediction market by burning their outcome
    /// tokens in exchange for their underlying counterpart.
    /// @param marketId The ID of the market the user wishes to exit.
    /// @param amountIn The amount of winning outcome tokens the user wishes to burn.
    /// @dev The function also collects a redemption fee, which is a percentage of the winnings from the
    /// specified amount of outcome tokens being exchanged. The fee is defined by the REDEMPTION_FEE_BIPS constant.
    function redeem(uint256 marketId, uint256 amountIn) external virtual {
        // Checks:
        // - The current market outcome must not be undetermined. This ensures proper option trading.
        Market memory market = markets[marketId];

        if (market.outcome == Outcome.UNDETERMINED) {
            revert MARKET_HAS_NOT_BEEN_SETTLED();
        }

        // Effects:
        // - The function burns the specified amount of winning outcome tokens from the user.
        // - The function calculates the total redemption fees, which are a percentage of the specified amount
        //      of winnings from the outcome tokens being exchanged, as defined by the REDEMPTION_FEE_BIPS constant.
        //      It then increases the accumulated fees mapping for the market's currency by the total amount of
        //      fees collected.
        // - The function sends the winnings from the contract to the user, minus redemption fee.
        // - The function emits the MarketRedemption event.
        (uint256 id0, uint256 id1) = idsForMarket(marketId);

        if (market.outcome == Outcome.FALSE) {
            _burn(msg.sender, id0, amountIn);
        } else {
            _burn(msg.sender, id1, amountIn);
        }

        uint256 winnings = amountIn.mulWadDown(market.exchangeRate);

        uint256 fee = winnings.mulDivDown(REDEEM_FEE_BIPS, 10_000);

        uint256 amountOut = winnings - fee + amountIn;

        accumulatedFees += fee;

        ASSET().safeTransfer(msg.sender, amountOut);

        emit MarketRedemption(marketId, msg.sender, amountIn, amountOut);
    }

    error MUST_PROVIDE_NON_ZERO_AMOUNT();

    error MARKET_HAS_ALREADY_SETTLED();

    error EMERGENCY_WINDOW_HAS_NOT_ELAPSED();

    /// @notice Allows users to exit the prediction market by burning their outcome
    /// tokens in exchange for their underlying counterpart, if the market's outcome
    /// has not been determined after the emergency window has elapsed.
    /// @param marketId The ID of the market the user wishes to exit.
    /// @param amount0 The amount of false outcome tokens the user wishes to burn.
    /// @param amount1 The amount of true outcome tokens the user wishes to burn.
    function emergencyExit(uint256 marketId, uint256 amount0, uint256 amount1)
        external
        virtual
    {
        // Checks:
        // - The sum of the amounts the user provided must exceed zero. This ensures the events guaruntee.
        // - The current market outcome must not be undetermined. This ensures proper option trading.
        // - The emergency window must have elapsed. This ensures proper option trading.
        Market storage market = markets[marketId];

        if (amount0 == 0 && amount1 == 0) {
            revert MUST_PROVIDE_NON_ZERO_AMOUNT();
        }

        if (market.outcome != Outcome.UNDETERMINED) {
            revert MARKET_HAS_ALREADY_SETTLED();
        }

        if (block.timestamp < market.maturity + EMERGENCY_WITHDRAWAL_WINDOW()) {
            revert EMERGENCY_WINDOW_HAS_NOT_ELAPSED();
        }

        // Effects:
        // - The function allows users to exit the prediction market by burning their outcome
        // tokens in exchange for their underlying counterpart.
        // - The function transfers the underlying currency to the user who is exiting the market.
        // - The function emits an EmergencyWithdrawal event.
        (uint256 id0, uint256 id1) = idsForMarket(marketId);

        if (amount0 > 0) _burn(msg.sender, id0, amount0);
        if (amount1 > 0) _burn(msg.sender, id1, amount1);

        uint256 sum = amount0 + amount1;

        ASSET().safeTransfer(msg.sender, sum);

        emit EmergencyWithdrawal(marketId, sum);
    }

    /// -----------------------------------------------------------------------
    /// Market Settlment Logic
    /// -----------------------------------------------------------------------

    error QUOTE_CANNOT_BE_REPLAYED();

    error DISPUTE_WINDOW_HAS_ELAPSED();

    error QUOTE_MUST_BE_MORE_ACCURATE();

    /// @notice Allows users to provide data to settle markets so long as they provide a
    /// quote bond, denominated in the quote currency.
    /// @param marketId The ID of the market the user wishes to exit.
    /// @param roundId The Chainlink ID of the quote being used.
    function price(uint256 marketId, uint80 roundId) external virtual {
        // Checks:
        // - The market outcome is undetermined. This ensures the immutability of markets outcome.
        // - The time delta between the markets maturity and the provided quote are within the
        // acceptable range denoted by `settleWindow`. This ensures data less accurate
        // than the market defines cannot be used to determine the markets outcome.
        // - If a quote has already been provided:
        //      1) The provided roundId must not equal the previous quotes roundId. This ensures
        //         a quote cannot be overwritten.
        //      2) The quote dispute window must not have elapsed since the last quote. This ensures
        //         the market can be settled in a timely manner.
        //      3) The time delta between the markets maturity and the provided quote is less than
        //         the previous quote. This ensures the new quote is more accurate.
        Market memory market = markets[marketId];
        Quote storage quote = quotes[marketId];

        if (market.outcome != Outcome.UNDETERMINED) {
            revert MARKET_HAS_ALREADY_SETTLED();
        }

        (, int256 answer,, uint256 updatedAt,) =
            market.priceFeed.getRoundData(roundId);

        uint256 timeDelta = updatedAt > market.maturity
            ? updatedAt - market.maturity
            : market.maturity - updatedAt;

        if (timeDelta > market.settleWindow) {
            revert QUOTE_MUST_BE_MORE_ACCURATE();
        }

        // Effects:
        // - If a quote has not been provided, the function transfers the quote bond from quoter to the contract.
        // - The function appends the new quote data for the market, which resets the quote dispute window.
        // - The function emits an MarketQuoted event.
        if (quote.quoter == address(0)) {
            ASSET().safeTransferFrom(
                msg.sender, address(this), QUOTE_BOND_AMOUNT()
            );
        } else {
            if (roundId == quote.roundId) {
                revert QUOTE_CANNOT_BE_REPLAYED();
            }

            if (block.timestamp > quote.creation + QUOTE_DISPUTE_WINDOW()) {
                revert DISPUTE_WINDOW_HAS_ELAPSED();
            }

            if (timeDelta >= quote.inaccuracy) {
                revert QUOTE_MUST_BE_MORE_ACCURATE();
            }
        }

        quote.quoter = msg.sender;
        quote.roundId = roundId;
        quote.creation = uint64(block.timestamp);
        quote.inaccuracy = uint64(timeDelta);

        emit MarketQuoted(marketId, roundId, answer);
    }

    error NONEXISTENT_QUOTE();
    
    error MARKET_HAS_BEEN_SETTLED();

    error DISPUTE_WINDOW_HAS_NOT_ELAPSED();

    /// @dev Settles a market by determining its final outcome and exchange rate.
    /// @param marketId ID of the market to settle.
    function settle(uint256 marketId) external virtual {
        // Checks:
        // - The market has been quoted. This ensures null data cannot be used to settle the market.
        // - The quote dispute window must have elapsed. This ensures accurate quote data.
        Market storage market = markets[marketId];
        Quote memory quote = quotes[marketId];

        if (market.outcome != Outcome.UNDETERMINED) {
            revert MARKET_HAS_BEEN_SETTLED();
        }

        if (quote.creation == 0) {
            revert NONEXISTENT_QUOTE();
        }

        if (block.timestamp < quote.creation + QUOTE_DISPUTE_WINDOW()) {
            revert DISPUTE_WINDOW_HAS_NOT_ELAPSED();
        }

        // Effects:
        // - The function determines the markets outcome based on the market type and updates
        // the markets final outcome and exchange rate.
        // - The function transfers the quote bond back to the latest quoter.
        // - The function emits an MarketSettled event.
        (, int256 answer,,,) = market.priceFeed.getRoundData(quote.roundId);

        bool isCall = market.direction == Direction.CALL;

        int256 strike = int256(uint256(market.strike));

        (uint256 id0, uint256 id1) = idsForMarket(marketId);

        if ((isCall && answer > strike) || (!isCall && answer <= strike)) {
            market.outcome = Outcome.TRUE;
            market.exchangeRate =
                totalSupply[id0].divWadDown(totalSupply[id1]).safeCastTo96();
        } else {
            market.outcome = Outcome.FALSE;
            market.exchangeRate =
                totalSupply[id1].divWadDown(totalSupply[id0]).safeCastTo96();
        }

        market.roundId = quote.roundId;

        ASSET().safeTransfer(quote.quoter, QUOTE_BOND_AMOUNT());

        emit MarketSettled(marketId, quote.roundId, answer);
    }

    /// -----------------------------------------------------------------------
    /// Metadata Logic
    /// -----------------------------------------------------------------------

    function uri(uint256 id)
        public
        view
        virtual
        override
        returns (string memory)
    {}

    /// -----------------------------------------------------------------------
    /// Fee Withdrawal Logic
    /// -----------------------------------------------------------------------

    function withdrawFees(address to)
        external
        onlyOwner
        returns (uint256 amountOut)
    {
        amountOut = accumulatedFees;

        delete accumulatedFees;

        ASSET().safeTransfer(to, amountOut);

        emit FeeWithdrawal(amountOut);
    }
}