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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity ^0.8.17;

import {IIndexState} from "./interfaces/IIndexState.sol";

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation with PhutureIndex related optimizations.
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract PhutureERC20 is IIndexState {
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
    State public state;

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

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();

        state.lastTransferTimestamp = uint32(block.timestamp);
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

    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
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

    function totalSupply() public view returns (uint256) {
        return state.totalSupply;
    }

    function reserve() public view returns (uint96) {
        return state.reserve;
    }

    function lastTransferTimestamp() public view returns (uint32) {
        return state.lastTransferTimestamp;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
    {
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
        return keccak256(
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

    function _mint(uint128 amount, address to, uint128 fees, address feePool, uint96 reserveAssets) internal {
        state = State(
            state.totalSupply + amount + fees, state.reserve + reserveAssets, uint32(block.timestamp % type(uint32).max)
        );

        unchecked {
            balanceOf[to] += amount;
            balanceOf[feePool] += fees;
        }

        emit Transfer(address(0), to, amount);
        if (fees != 0) {
            emit Transfer(address(0), feePool, fees);
        }
    }

    function _burn(uint128 amount, address from, uint128 fees, address feePool, uint96 reserveAssets) internal {
        balanceOf[from] -= amount;
        balanceOf[feePool] += fees;

        state = State(
            state.totalSupply - amount + fees, state.reserve - reserveAssets, uint32(block.timestamp % type(uint32).max)
        );

        emit Transfer(from, address(0), amount);
        if (fees != 0) {
            emit Transfer(address(0), feePool, fees);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IIndexAnatomyClient} from "./interfaces/IIndexAnatomyClient.sol";
import {IIndex, IIndexViewer, IIndexClient, IIndexManager} from "./interfaces/IIndex.sol";

import {SubIndexLib} from "./libraries/SubIndexLib.sol";

import {PhutureERC20} from "./PhutureERC20.sol";

/// @title PhutureIndexErrors interface
/// @notice Contains PhutureIndex's errors
interface IPhutureIndexErrors {
    /// @dev Reverts during deposit/redeem if index shares is 0
    error PhutureIndexZeroShares();
}

/// @title OMNI Index
/// @notice This contract is the main entry point for interacting with an OMNI Index.
/// @author Phuture Finance
contract PhutureIndex is PhutureERC20, Owned, ReentrancyGuard, IIndex, IPhutureIndexErrors {
    using SafeTransferLib for ERC20;
    using SafeCastLib for uint256;

    /// @inheritdoc IIndexViewer
    address public immutable override feePool;

    /// @notice IndexAnatomy contract
    IIndexAnatomyClient internal _indexAnatomy;

    constructor(string memory name, string memory symbol, address _feePool)
        PhutureERC20(name, symbol, 18)
        Owned(msg.sender)
    {
        feePool = _feePool;
    }

    /// @inheritdoc IIndexClient
    function deposit(uint256 reserveAssets, address receiver, SubIndexLib.SubIndex[] calldata subIndexes)
        external
        override
        nonReentrant
        returns (uint256)
    {
        uint96 _reserveAssets = reserveAssets.safeCastTo96();
        (uint128 indexShares, uint128 fee, address reserveAsset, address reserveVault) =
            _indexAnatomy.deposit(_reserveAssets, state, subIndexes);

        if (indexShares == 0) {
            revert PhutureIndexZeroShares();
        }

        ERC20(reserveAsset).safeTransferFrom(msg.sender, reserveVault, _reserveAssets);

        _mint(indexShares, receiver, fee, feePool, _reserveAssets);

        emit Deposit(msg.sender, receiver, reserveAssets, indexShares);

        return indexShares;
    }

    /// @inheritdoc IIndexClient
    function redeem(
        uint256 indexShares,
        address sender,
        address owner,
        address receiver,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) external nonReentrant returns (uint256 reserveBefore, uint32[] memory subIndexBurnBalances) {
        // TODO: only RedeemRouter
        uint128 _indexShares = indexShares.safeCastTo128();
        if (indexShares == 0) {
            revert PhutureIndexZeroShares();
        }

        if (sender != owner) {
            uint256 allowed = allowance[owner][sender];
            if (allowed != type(uint256).max) {
                allowance[owner][sender] = allowed - indexShares;
            }
        }
        reserveBefore = state.reserve;
        uint128 fee;
        uint256 reserveBurnt;
        (reserveBurnt, fee, subIndexBurnBalances) = _indexAnatomy.redeem(_indexShares, receiver, state, subIndexes);

        _burn(_indexShares, owner, fee, feePool, reserveBurnt.safeCastTo96());

        emit Withdraw(sender, receiver, owner, reserveBurnt, indexShares);
    }

    /// @inheritdoc IIndexManager
    function setIndexAnatomy(address anatomy_) external override onlyOwner {
        _indexAnatomy = IIndexAnatomyClient(anatomy_);
    }

    /// @inheritdoc IIndexManager
    function updateReserve(uint96 value) external override onlyOwner {
        state.reserve = value;
    }

    /// @inheritdoc IIndexViewer
    function indexAnatomy() external view override returns (address) {
        return address(_indexAnatomy);
    }

    /// @inheritdoc IIndexViewer
    function totalAssets() external view override returns (uint256 total) {
        return _indexAnatomy.totalAssets(state.reserve);
    }

    /// @inheritdoc IIndexViewer
    function previewDeposit(uint256 reserveAssets) external view override returns (uint256) {
        return _indexAnatomy.previewDeposit(uint96(reserveAssets), state);
    }

    /// @inheritdoc IIndexViewer
    function previewRedeem(uint256 indexShares, uint256 executionTimestamp)
        external
        view
        returns (RedeemInfo memory info)
    {
        return _indexAnatomy.previewRedeem(uint128(indexShares), executionTimestamp, state);
    }

    /// @inheritdoc IIndexViewer
    function anatomy() public view returns (SubIndexLib.SubIndex[] memory) {
        return _indexAnatomy.anatomy();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {IIndexClient} from "./IIndexClient.sol";
import {IIndexViewer} from "./IIndexViewer.sol";
import {IIndexManager} from "./IIndexManager.sol";

/// @title IIndex interface
/// @notice Contains common index logic
interface IIndex is IIndexClient, IIndexViewer, IIndexManager {}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {SubIndexLib} from "../libraries/SubIndexLib.sol";

import {IIndexState} from "../interfaces/IIndexState.sol";
import {IIndexClient} from "../interfaces/IIndexClient.sol";
import {IIndexViewer} from "../interfaces/IIndexViewer.sol";

/// @title IndexAnatomy Client interface
/// @notice Contains index related logic
interface IIndexAnatomyClient {
    /// @notice Burns index and transfers reserve assets to receiver
    function redeem(
        uint128 indexShares,
        address receiver,
        IIndexState.State calldata state,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) external returns (uint256 reserveBurnt, uint128 fee, uint32[] memory subIndexBurnBalances);

    /// @notice Calculates and returns data to mint index
    function deposit(
        uint256 reserveAssets,
        IIndexState.State calldata state,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) external view returns (uint128 shares, uint128 fee, address reserveAsset, address reserveVault);

    /// @notice Calculates and returns data to mint index
    ///
    /// @param reserveAssets Amount of reserve asset to mint for
    /// @param state State of Index
    ///
    /// @return shares Amount of index to mint
    function previewDeposit(uint256 reserveAssets, IIndexState.State calldata state)
        external
        view
        returns (uint128 shares);

    /// @notice Calculates and returns data to burn index
    ///
    /// @param indexShares Amount of index to burn
    /// @param executionTimestamp Transaction execution timestamp
    /// @param state State of Index
    ///
    /// @return info Redeem details
    function previewRedeem(uint128 indexShares, uint256 executionTimestamp, IIndexState.State calldata state)
        external
        view
        returns (IIndexViewer.RedeemInfo memory info);

    /// @notice Returns total amount of index underlying assets in reserve asset
    ///
    /// @param reserve Amount of reserve asset
    ///
    /// @return total Amount of index underlying assets in reserve asset
    function totalAssets(uint96 reserve) external view returns (uint256 total);

    /// @notice Returns list of Index's chains
    ///
    /// @return List of Index's chains
    function anatomy() external view returns (SubIndexLib.SubIndex[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {SubIndexLib} from "../libraries/SubIndexLib.sol";

/// @title IIndexClient interface
/// @notice Contains index minting and burning logic
interface IIndexClient {
    /// @notice Emits each time when index is minted
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /// @notice Emits each time when index is burnt
    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 withdrawnReserveAssets,
        uint256 shares
    );

    /// @notice Deposits reserve assets and mints index
    ///
    /// @param reserveAssets Amount of reserve asset
    /// @param receiver Address of index receiver
    ///
    /// @param indexShares Amount of minted index
    function deposit(uint256 reserveAssets, address receiver, SubIndexLib.SubIndex[] calldata subIndexes)
        external
        returns (uint256 indexShares);

    /// @notice Burns index and withdraws reserveAssets
    ///
    /// @param indexShares Amount of index to burn
    /// @param sender Address of msg.sender
    /// @param owner Address of index owner
    /// @param receiver Address of assets receiver
    /// @param subIndexes List of SubIndexes
    ///
    /// @param reserveBefore Reserve value before withdraw
    /// @param subIndexBurnBalances SubIndex balances to burn
    function redeem(
        uint256 indexShares,
        address sender,
        address owner,
        address receiver,
        SubIndexLib.SubIndex[] calldata subIndexes
    ) external returns (uint256 reserveBefore, uint32[] memory subIndexBurnBalances);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IIndexClient interface
/// @notice Contains index minting and burning logic
interface IIndexManager {
    /// @notice Sets new IndexAnatomy address
    ///
    /// @param anatomy Address of IndexAnatomy contract
    function setIndexAnatomy(address anatomy) external;

    /// @notice Updates reserve value
    ///
    /// @param value New amount of reserve assets
    function updateReserve(uint96 value) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

/// @title IIndexState interface
/// @notice Contains State struct
interface IIndexState {
    struct State {
        uint128 totalSupply;
        uint96 reserve;
        uint32 lastTransferTimestamp;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {SubIndexLib} from "../libraries/SubIndexLib.sol";

/// @title IIndexViewer interface
/// @notice Contains index's view methods
interface IIndexViewer {
    struct RedeemAssetInfo {
        uint256 chainId;
        address[] assets;
        uint256[] amounts;
    }

    struct RedeemInfo {
        uint128 feeAUM;
        uint256 reserve;
        RedeemAssetInfo[] assets;
    }

    /// @notice Returns total amount of index underlying assets in reserve asset
    ///
    /// @return total Amount of index underlying assets in reserve asset
    function totalAssets() external view returns (uint256 total);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
    /// current on-chain conditions
    ///
    /// @param reserveAssets Amount of reserve assets
    ///
    /// @return shares Amount of index
    function previewDeposit(uint256 reserveAssets) external view returns (uint256 shares);

    /// @notice Allows an on-chain or off-chain user to simulate the effects of their redeem at the current block,
    /// given current on-chain conditions
    ///
    /// @param indexShares Amount of index
    /// @param executionTimestamp Transaction execution timestamp
    ///
    /// @return info Redeem details
    function previewRedeem(uint256 indexShares, uint256 executionTimestamp)
        external
        view
        returns (RedeemInfo memory info);

    /// @notice Returns address of fee pool
    function feePool() external view returns (address);

    /// @notice Returns list of Index's chains
    ///
    /// @return List of Index's chains
    function anatomy() external view returns (SubIndexLib.SubIndex[] memory);

    /// @notice Returns address of IndexAnatomy contract
    function indexAnatomy() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library SubIndexLib {
    struct SubIndex {
        // TODO: make it uint128 ?
        uint256 id;
        uint256 chainId;
        address[] assets;
        uint256[] balances;
    }

    // TODO: increase precision
    uint32 internal constant TOTAL_SUPPLY = type(uint32).max;
}