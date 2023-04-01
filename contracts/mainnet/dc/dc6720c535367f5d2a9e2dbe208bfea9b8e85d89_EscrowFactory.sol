// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/auth/Owned.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error Unauthorized();

    /// -----------------------------------------------------------------------
    /// Ownership Storage
    /// -----------------------------------------------------------------------

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Deploy to deterministic addresses without an initcode factor.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/CREATE3.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/CREATE3.sol)
library CREATE3 {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    error DeploymentFailed();

    error InitializationFailed();

    /// -----------------------------------------------------------------------
    /// Bytecode Constants
    /// -----------------------------------------------------------------------

    /**
     * -------------------------------------------------------------------+
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 36          | CALLDATASIZE     | cds          |                    |
     * 3d          | RETURNDATASIZE   | 0 cds        |                    |
     * 3d          | RETURNDATASIZE   | 0 0          |                    |
     * 37          | CALLDATACOPY     |              | [0..cds): calldata |
     * 36          | CALLDATASIZE     | cds          | [0..cds): calldata |
     * 3d          | RETURNDATASIZE   | 0 cds        | [0..cds): calldata |
     * 34          | CALLVALUE        | value 0 cds  | [0..cds): calldata |
     * f0          | CREATE           | newContract  | [0..cds): calldata |
     * -------------------------------------------------------------------|
     * Opcode      | Mnemonic         | Stack        | Memory             |
     * -------------------------------------------------------------------|
     * 67 bytecode | PUSH8 bytecode   | bytecode     |                    |
     * 3d          | RETURNDATASIZE   | 0 bytecode   |                    |
     * 52          | MSTORE           |              | [0..8): bytecode   |
     * 60 0x08     | PUSH1 0x08       | 0x08         | [0..8): bytecode   |
     * 60 0x18     | PUSH1 0x18       | 0x18 0x08    | [0..8): bytecode   |
     * f3          | RETURN           |              | [0..8): bytecode   |
     * -------------------------------------------------------------------+
     */

    uint256 private constant _PROXY_BYTECODE = 0x67363d3d37363d34f03d5260086018f3;

    bytes32 private constant _PROXY_BYTECODE_HASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    /// -----------------------------------------------------------------------
    /// Create3 Operations
    /// -----------------------------------------------------------------------

    function deploy(bytes32 salt, bytes memory creationCode, uint256 value) internal returns (address deployed) {
        assembly {
            // Store the `_PROXY_BYTECODE` into scratch space.
            mstore(0x00, _PROXY_BYTECODE)
            // Deploy a new contract with our pre-made bytecode via CREATE2.
            let proxy := create2(0, 0x10, 0x10, salt)

            // If the result of `create2` is the zero address, revert.
            if iszero(proxy) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the proxy's address.
            mstore(0x14, proxy)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)

            // If the `call` fails, revert.
            if iszero(
                call(
                    gas(), // Gas remaining.
                    proxy, // Proxy's address.
                    value, // Ether value.
                    add(creationCode, 0x20), // Start of `creationCode`.
                    mload(creationCode), // Length of `creationCode`.
                    0x00, // Offset of output.
                    0x00 // Length of output.
                )
            ) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If the code size of `deployed` is zero, revert.
            if iszero(extcodesize(deployed)) {
                // Store the function selector of `InitializationFailed()`.
                mstore(0x00, 0x19b991a8)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    function getDeployed(bytes32 salt) internal view returns (address deployed) {
        assembly {
            // Cache the free memory pointer.
            let m := mload(0x40)
            // Store `address(this)`.
            mstore(0x00, address())
            // Store the prefix.
            mstore8(0x0b, 0xff)
            // Store the salt.
            mstore(0x20, salt)
            // Store the bytecode hash.
            mstore(0x40, _PROXY_BYTECODE_HASH)

            // Store the proxy's address.
            mstore(0x14, keccak256(0x0b, 0x55))
            // Restore the free memory pointer.
            mstore(0x40, m)
            // 0xd6 = 0xc0 (short RLP prefix) + 0x16 (length of: 0x94 ++ proxy ++ 0x01).
            // 0x94 = 0x80 + 0x14 (0x14 = the length of an address, 20 bytes, in hex).
            mstore(0x00, 0xd694)
            // Nonce of the proxy contract (1).
            mstore8(0x34, 0x01)

            deployed := keccak256(0x1e, 0x17)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /// -----------------------------------------------------------------------
    /// Custom Errors
    /// -----------------------------------------------------------------------

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// -----------------------------------------------------------------------
    /// ETH Operations
    /// -----------------------------------------------------------------------

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC20 Operations
    /// -----------------------------------------------------------------------

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x095ea7b3)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Modern, minimalist, and gas-optimized ERC721 implementation.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// -----------------------------------------------------------------------
    /// Metadata Storage/Logic
    /// -----------------------------------------------------------------------

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /// -----------------------------------------------------------------------
    /// ERC721 Balance/Owner Storage
    /// -----------------------------------------------------------------------

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        if ((owner = _ownerOf[id]) == address(0)) revert("NotMinted");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) revert("ZeroAddress");
        return _balanceOf[owner];
    }

    /// -----------------------------------------------------------------------
    /// ERC721 Approval Storage
    /// -----------------------------------------------------------------------

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    //constructor(string memory _name, string memory _symbol) {
    //    init(_name, _symbol);
    //}

    function init(string memory _name, string memory _symbol) internal 
    {
        name = _name;
        symbol = _symbol;
    }

    /// -----------------------------------------------------------------------
    /// ERC721 Logic
    /// -----------------------------------------------------------------------

    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) revert("Unauthorized");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public virtual {
        if (from != _ownerOf[id]) revert("WrongFrom");

        if (to == address(0)) revert("InvalidRecipient");

        if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[id])
            revert("Unauthorized");

        _beforeTokenTransfer(from, to, id, 1);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }

    /// -----------------------------------------------------------------------
    /// ERC165 Logic
    /// -----------------------------------------------------------------------

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /// -----------------------------------------------------------------------
    /// Internal Mint/Burn Logic
    /// -----------------------------------------------------------------------

    function _mint(address to, uint256 id) internal virtual {
        if (to == address(0)) revert("InvalidRecipient");

        if (_ownerOf[id] != address(0)) revert("AlreadyMinted");

        _beforeTokenTransfer(address(0), to, id, 1);

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        if (owner == address(0)) revert("NotMinted");

        _beforeTokenTransfer(owner, address(0), id, 1);

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /// -----------------------------------------------------------------------
    /// Internal Safe Mint Logic
    /// -----------------------------------------------------------------------

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }

    function _safeMint(address to, uint256 id, bytes memory data) internal virtual {
        _mint(to, id);

        if (to.code.length != 0) {
            if (
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) !=
                ERC721TokenReceiver.onERC721Received.selector
            ) revert("UnsafeRecipient");
        }
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author SolDAO (https://github.com/Sol-DAO/solbase/blob/main/src/tokens/ERC721.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {SafeTransferLib} from "@solbase/utils/SafeTransferLib.sol";
import {ERC721, ERC721TokenReceiver} from "./ERC721.sol";
import {RewardRouterV2} from "./interfaces/IRewardRouterV2.sol";
import {IEscrowController} from "./interfaces/IEscrowController.sol";

contract Escrow is ERC721TokenReceiver
{
    using SafeTransferLib for address;

    uint16 immutable public feeBasisPoints;
    address immutable public seller;
    address immutable public factory;
    address immutable public rewardRouter;
    address immutable public escrowController;
    uint256 immutable public tokenId;

    /// -----------------------------------------------------------------------
    /// Ownership Logic
    /// -----------------------------------------------------------------------

    function escrowOwner() internal view returns (address)
    {
        address nftOwner = ERC721(escrowController).ownerOf(tokenId);
        return nftOwner == address(0) ? factory : (nftOwner == address(this) ? seller : nftOwner);
    }

    modifier onlyEscrowOwner() {
        require(msg.sender == escrowOwner(), "Unauthorized");
        _;
    }

    constructor(uint16 fee, address sellerAddress, address factoryAddress, address router, address controller, uint256 id) {
        require (fee <= 10000, "FEE_TOO_LARGE");
        feeBasisPoints = fee;
        seller = sellerAddress;
        factory = factoryAddress;
        rewardRouter = router;
        escrowController = controller;
        tokenId = id; 
    }

    fallback() external payable { }

    receive() external payable { }

    function getSeller() external view returns (address)
    {
        return seller;
    }

    function getFactory() external view returns (address)
    {
        return factory;
    }

    function getTokenId() external view returns (uint256)
    {
        return tokenId;
    }

    function getFeeBPs() external view returns (uint16)
    {
        return feeBasisPoints;
    }


    function acceptTransferIn() external onlyEscrowOwner 
    {
        RewardRouterV2(rewardRouter).acceptTransfer(seller);
        //IEscrowController(escrowController).safeTransferFrom(address(this), seller, tokenId);
    }

    function signalTransferOut() external onlyEscrowOwner 
    {
        address recipient = escrowOwner();
        IEscrowController(escrowController).safeTransferFrom(recipient, address(this), tokenId);
        IEscrowController(escrowController).burn(tokenId);
        _claim();
        RewardRouterV2(rewardRouter).signalTransfer(recipient);
    }

    function claim() external onlyEscrowOwner 
    {
        _claim();
    }

    function _claim() internal
    {
        uint256 oldBalance = address(this).balance;
        bytes memory payload = abi.encodeCall(RewardRouterV2(rewardRouter).handleRewards, (false, false, true, true, true, true, true));
        (bool success, ) = address(rewardRouter).call(payload);
        success = success;
        uint256 devFee = (address(this).balance - oldBalance) * feeBasisPoints / 10000;
        factory.safeTransferETH(devFee);
        seller.safeTransferETH(address(this).balance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.17;

import {Owned} from "@solbase/auth/Owned.sol";
import {CREATE3} from "@solbase/utils/CREATE3.sol";
import {SafeTransferLib} from "@solbase/utils/SafeTransferLib.sol";
import {RewardRouterV2} from "./interfaces/IRewardRouterV2.sol";
import {IEscrowController} from "./interfaces/IEscrowController.sol";
import {Escrow} from "./Escrow.sol";
import {ERC721TokenReceiver} from "./ERC721.sol";

contract EscrowFactory is Owned(tx.origin), ERC721TokenReceiver {
    using SafeTransferLib for address;

    address public rewardRouter;
    address public escrowController;
    uint16 fee = 4900;

    constructor() {
    }

    fallback() external payable { }

    receive() external payable { }

    function setFeeBasisPoints(uint16 newFee) external onlyOwner
    {
        require(newFee <= 10000, "FEE_TOO_LARGE");
        fee = newFee;
    }

    function setRewardRouter(address router) external onlyOwner
    {
        rewardRouter = router;
    }

    function setEscrowController(address controller) external onlyOwner
    {
        escrowController = controller;
    }

    function getSalt(address account) internal view returns (bytes32)
    {
        return keccak256(abi.encode(address(this), account));
    }
    
    function _getEscrow(address account) internal view returns (address)
    {
        bytes32 salt = getSalt(account);
        return CREATE3.getDeployed(salt);
    }

    function isEscrowDeployed(address account) external view returns (bool)
    {
        address escrow = _getEscrow(account);
        uint256 size;
        assembly { size := extcodesize(escrow) }
        return size > 0;
    }

    function getEscrow(address account) external view returns (address)
    {
        return _getEscrow(account);
    }

    function deployEscrow(address account, uint256 tokenId) internal returns (address)
    {
        bytes32 salt = getSalt(account);
        return CREATE3.deploy(
                salt,
                abi.encodePacked(type(Escrow).creationCode, abi.encode(fee, account, address(this), rewardRouter, escrowController, tokenId)),
                0
            );
    }

    function createEscrow() external returns (address payable) {
        require(rewardRouter != address(0), "REWARD_ROUTER_NOT_SET");
        require(escrowController != address(0), "ESCROW_CONTROLLER_NOT_SET");
        address escrowAddress = this.getEscrow(msg.sender);
        require(RewardRouterV2(rewardRouter).pendingReceivers(msg.sender) == escrowAddress, "NO_SIGNALXFER_TO_ESCROW");
        uint256 nftId = IEscrowController(escrowController).mint(address(this), escrowAddress);
        address escrow = deployEscrow(msg.sender, nftId);
        Escrow(payable(escrow)).acceptTransferIn();
        //IEscrowController(escrowController).safeTransferFrom(address(this), escrow, nftId);
        IEscrowController(escrowController).safeTransferFrom(address(this), msg.sender, nftId);
        return payable(escrow);
    }

    function withdraw() external onlyOwner
    {
        owner.safeTransferETH(address(this).balance);
    }

    function transferControllerOwnership(address newOwner) external onlyOwner
    {
        IEscrowController(escrowController).transferOwnership(newOwner);
    }
}

pragma solidity ^0.8.10;

interface IEscrowController {
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event OwnershipTransferred(address indexed user, address indexed newOwner);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    function approve(address spender, uint256 id) external;
    function balanceOf(address owner) external view returns (uint256);
    function burn(uint256 id) external;
    function escrows(uint256) external view returns (address);
    function getApproved(uint256) external view returns (address);
    function isApprovedForAll(address, address) external view returns (bool);
    function mint(address to, address escrow) external returns (uint256);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function ownerOf(uint256 id) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 id) external;
    function safeTransferFrom(address from, address to, uint256 id, bytes memory data) external;
    function setApprovalForAll(address operator, bool approved) external;
    function setRenderer(address r) external;
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 id) external view returns (string memory);
    function transferFrom(address from, address to, uint256 id) external;
    function transferOwnership(address newOwner) external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.10;

interface RewardRouterV2 {
    event StakeGlp(address account, uint256 amount);
    event StakeGmx(address account, address token, uint256 amount);
    event UnstakeGlp(address account, uint256 amount);
    event UnstakeGmx(address account, address token, uint256 amount);

    function acceptTransfer(address _sender) external;
    function batchCompoundForAccounts(address[] memory _accounts) external;
    function batchStakeGmxForAccount(address[] memory _accounts, uint256[] memory _amounts) external;
    function bnGmx() external view returns (address);
    function bonusGmxTracker() external view returns (address);
    function claim() external;
    function claimEsGmx() external;
    function claimFees() external;
    function compound() external;
    function compoundForAccount(address _account) external;
    function esGmx() external view returns (address);
    function feeGlpTracker() external view returns (address);
    function feeGmxTracker() external view returns (address);
    function glp() external view returns (address);
    function glpManager() external view returns (address);
    function glpVester() external view returns (address);
    function gmx() external view returns (address);
    function gmxVester() external view returns (address);
    function gov() external view returns (address);
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
    function initialize(
        address _weth,
        address _gmx,
        address _esGmx,
        address _bnGmx,
        address _glp,
        address _stakedGmxTracker,
        address _bonusGmxTracker,
        address _feeGmxTracker,
        address _feeGlpTracker,
        address _stakedGlpTracker,
        address _glpManager,
        address _gmxVester,
        address _glpVester
    ) external;
    function isInitialized() external view returns (bool);
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp)
        external
        returns (uint256);
    function mintAndStakeGlpETH(uint256 _minUsdg, uint256 _minGlp) external payable returns (uint256);
    function pendingReceivers(address) external view returns (address);
    function setGov(address _gov) external;
    function signalTransfer(address _receiver) external;
    function stakeEsGmx(uint256 _amount) external;
    function stakeGmx(uint256 _amount) external;
    function stakeGmxForAccount(address _account, uint256 _amount) external;
    function stakedGlpTracker() external view returns (address);
    function stakedGmxTracker() external view returns (address);
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver)
        external
        returns (uint256);
    function unstakeAndRedeemGlpETH(uint256 _glpAmount, uint256 _minOut, address _receiver)
        external
        returns (uint256);
    function unstakeEsGmx(uint256 _amount) external;
    function unstakeGmx(uint256 _amount) external;
    function weth() external view returns (address);
    function withdrawToken(address _token, address _account, uint256 _amount) external;
}