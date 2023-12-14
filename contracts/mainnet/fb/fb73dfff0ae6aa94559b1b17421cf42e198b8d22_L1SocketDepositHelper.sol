// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import {Owned} from "solmate/auth/Owned.sol";
import {VaultInterface} from "./interfaces/VaultInterface.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {WETHInterface} from "../interfaces/WETHInterface.sol";

/// @title L1SocketDepositHelper
/// @notice The L1 deposit helper for handling cross-chain yield vault deposits and usdc permit
contract L1SocketDepositHelper is Owned {
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The arb / op vault contract
    mapping(address => VaultInterface) public vaults;

    /// @notice The WETH address
    address public immutable weth;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TokensDeposited(
        address indexed connector,
        address indexed depositor,
        address indexed receiver,
        uint256 depositAmount,
        bytes data
    );
    event VaultUpdated(address indexed collateral, address indexed vault);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor
    /// @param _weth The WETH address
    constructor(address _weth, address _owner) Owned(_owner) {
        weth = _weth;
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER OPERATIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Updates the Socket vault for a collateral
    /// @dev Only callable by the owner
    /// @param _collateral The collateral address
    /// @param _vault The Socket vault address
    function updateVault(address _collateral, address _vault) external onlyOwner {
        vaults[_collateral] = VaultInterface(_vault);

        emit VaultUpdated(_collateral, _vault);
    }

    /// @notice Deposit an amount of the ERC20 to the senders balance on L2
    /// @param _receiver Receiver on the L2
    /// @param _amount Amount of to deposit
    /// @param _msgGasLimit Gas limit required to complete the deposit on L2
    /// @param _connector Socket connector
    /// @param _data Optional data to forward to L2
    function depositETHToAppChain(
        address _receiver,
        uint256 _amount,
        uint256 _msgGasLimit,
        address _connector,
        bytes calldata _data
    ) external payable {
        // Mint WETH
        WETHInterface(weth).deposit{value: _amount}();
        // Approve the tokens from this contract to the L1 bridge
        ERC20(weth).safeApprove(address(vaults[weth]), _amount);
        vaults[weth].depositToAppChain{value: msg.value - _amount}(_receiver, _amount, _msgGasLimit, _connector);
        emit TokensDeposited(_connector, msg.sender, _receiver, _amount, _data);
    }

    /// @notice Deposit an amount of the ERC20 to the senders balance on L2 using an EIP-2612 permit signature
    /// @param _receiver Receiver on the L2
    /// @param _asset Asset of the ERC20
    /// @param _amount Amount of the ERC20 to deposit
    /// @param _msgGasLimit Gas limit required to complete the deposit on L2
    /// @param _connector Socket connector
    /// @param _data Optional data to forward to L2
    /// @param _deadline A timestamp, the current blocktime must be less than or equal to this timestamp
    /// @param _v Must produce valid secp256k1 signature from the holder along with r and s
    /// @param _r Must produce valid secp256k1 signature from the holder along with v and s
    /// @param _s Must produce valid secp256k1 signature from the holder along with r and v
    function depositToAppChainWithPermit(
        address _receiver,
        address _asset,
        uint256 _amount,
        uint256 _msgGasLimit,
        address _connector,
        bytes calldata _data,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable {
        // Approve the tokens from the sender to this contract
        ERC20(_asset).permit(msg.sender, address(this), _amount, _deadline, _v, _r, _s);
        _depositToAppChain(_receiver, _asset, _amount, _msgGasLimit, _connector, _data);
    }

    /// @notice Deposit an amount of the ERC20 to the senders balance on L2
    /// @param _receiver Receiver on the L2
    /// @param _asset Asset of the ERC20
    /// @param _amount Amount of the ERC20 to deposit
    /// @param _msgGasLimit Gas limit required to complete the deposit on L2
    /// @param _connector Socket connector
    /// @param _data Optional data to forward to L2
    function depositToAppChain(
        address _receiver,
        address _asset,
        uint256 _amount,
        uint256 _msgGasLimit,
        address _connector,
        bytes calldata _data
    ) external payable {
        _depositToAppChain(_receiver, _asset, _amount, _msgGasLimit, _connector, _data);
    }

    function _depositToAppChain(
        address _receiver,
        address _asset,
        uint256 _amount,
        uint256 _msgGasLimit,
        address _connector,
        bytes calldata _data
    ) internal {
        // Transfer the tokens from the sender to this contract
        ERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        // Approve the tokens from this contract to the L1 bridge
        ERC20(_asset).safeApprove(address(vaults[_asset]), _amount);

        vaults[_asset].depositToAppChain{value: msg.value}(_receiver, _amount, _msgGasLimit, _connector);
        emit TokensDeposited(_connector, msg.sender, _receiver, _amount, _data);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
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

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.8.0. SEE SOURCE BELOW. !!
pragma solidity ^0.8.9;

interface VaultInterface {
    error AmountOutsideLimit();
    error ConnectorUnavailable();

    event LimitParamsUpdated(Vault.UpdateLimitParams[] updates);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PendingTokensTransferred(address connector, address receiver, uint256 unlockedAmount, uint256 pendingAmount);
    event TokensDeposited(address connector, address depositor, address receiver, uint256 depositAmount);
    event TokensPending(address connector, address receiver, uint256 pendingAmount, uint256 totalPendingAmount);
    event TokensUnlocked(address connector, address receiver, uint256 unlockedAmount);

    function acceptOwnership() external;

    function connectorPendingUnlocks(address) external view returns (uint256);

    function depositToAppChain(address receiver_, uint256 amount_, uint256 msgGasLimit_, address connector_)
        external
        payable;

    function getCurrentLockLimit(address connector_) external view returns (uint256);

    function getCurrentUnlockLimit(address connector_) external view returns (uint256);

    function getLockLimitParams(address connector_) external view returns (Gauge.LimitParams memory);

    function getMinFees(address connector_, uint256 msgGasLimit_) external view returns (uint256 totalFees);

    function getUnlockLimitParams(address connector_) external view returns (Gauge.LimitParams memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function pendingUnlocks(address, address) external view returns (uint256);

    function receiveInbound(bytes memory payload_) external;

    function renounceOwnership() external;

    function token__() external view returns (address);

    function transferOwnership(address newOwner) external;

    function unlockPendingFor(address receiver_, address connector_) external;

    function updateLimitParams(Vault.UpdateLimitParams[] memory updates_) external;
}

interface Vault {
    struct UpdateLimitParams {
        bool isLock;
        address connector;
        uint256 maxLimit;
        uint256 ratePerSecond;
    }
}

interface Gauge {
    struct LimitParams {
        uint256 lastUpdateTimestamp;
        uint256 ratePerSecond;
        uint256 maxLimit;
        uint256 lastUpdateLimit;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"address","name":"token_","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AmountOutsideLimit","type":"error"},{"inputs":[],"name":"ConnectorUnavailable","type":"error"},{"anonymous":false,"inputs":[{"components":[{"internalType":"bool","name":"isLock","type":"bool"},{"internalType":"address","name":"connector","type":"address"},{"internalType":"uint256","name":"maxLimit","type":"uint256"},{"internalType":"uint256","name":"ratePerSecond","type":"uint256"}],"indexed":false,"internalType":"struct Vault.UpdateLimitParams[]","name":"updates","type":"tuple[]"}],"name":"LimitParamsUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferStarted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"connector","type":"address"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"unlockedAmount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"pendingAmount","type":"uint256"}],"name":"PendingTokensTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"connector","type":"address"},{"indexed":false,"internalType":"address","name":"depositor","type":"address"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"depositAmount","type":"uint256"}],"name":"TokensDeposited","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"connector","type":"address"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"pendingAmount","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"totalPendingAmount","type":"uint256"}],"name":"TokensPending","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"connector","type":"address"},{"indexed":false,"internalType":"address","name":"receiver","type":"address"},{"indexed":false,"internalType":"uint256","name":"unlockedAmount","type":"uint256"}],"name":"TokensUnlocked","type":"event"},{"inputs":[],"name":"acceptOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"connectorPendingUnlocks","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"receiver_","type":"address"},{"internalType":"uint256","name":"amount_","type":"uint256"},{"internalType":"uint256","name":"msgGasLimit_","type":"uint256"},{"internalType":"address","name":"connector_","type":"address"}],"name":"depositToAppChain","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"address","name":"connector_","type":"address"}],"name":"getCurrentLockLimit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"connector_","type":"address"}],"name":"getCurrentUnlockLimit","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"connector_","type":"address"}],"name":"getLockLimitParams","outputs":[{"components":[{"internalType":"uint256","name":"lastUpdateTimestamp","type":"uint256"},{"internalType":"uint256","name":"ratePerSecond","type":"uint256"},{"internalType":"uint256","name":"maxLimit","type":"uint256"},{"internalType":"uint256","name":"lastUpdateLimit","type":"uint256"}],"internalType":"struct Gauge.LimitParams","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"connector_","type":"address"},{"internalType":"uint256","name":"msgGasLimit_","type":"uint256"}],"name":"getMinFees","outputs":[{"internalType":"uint256","name":"totalFees","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"connector_","type":"address"}],"name":"getUnlockLimitParams","outputs":[{"components":[{"internalType":"uint256","name":"lastUpdateTimestamp","type":"uint256"},{"internalType":"uint256","name":"ratePerSecond","type":"uint256"},{"internalType":"uint256","name":"maxLimit","type":"uint256"},{"internalType":"uint256","name":"lastUpdateLimit","type":"uint256"}],"internalType":"struct Gauge.LimitParams","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pendingOwner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"pendingUnlocks","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes","name":"payload_","type":"bytes"}],"name":"receiveInbound","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"token__","outputs":[{"internalType":"contract ERC20","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"receiver_","type":"address"},{"internalType":"address","name":"connector_","type":"address"}],"name":"unlockPendingFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"bool","name":"isLock","type":"bool"},{"internalType":"address","name":"connector","type":"address"},{"internalType":"uint256","name":"maxLimit","type":"uint256"},{"internalType":"uint256","name":"ratePerSecond","type":"uint256"}],"internalType":"struct Vault.UpdateLimitParams[]","name":"updates_","type":"tuple[]"}],"name":"updateLimitParams","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

/// @title Interface for WETH9
interface WETHInterface {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}