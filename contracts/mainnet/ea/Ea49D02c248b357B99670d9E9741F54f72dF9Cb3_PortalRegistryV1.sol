/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Aave V2 like markets using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/ILendingPool.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract AaveV2PortalIn is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Add liquidity to Aave V2 like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be the underlying token)
    /// @param buyToken The Aave V2 like market address (i.e. the aToken)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param lendingPool The Aave V2 like market lending pool
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        ILendingPool lendingPool
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);

        uint256 intermediateAmount = _execute(
            sellToken,
            amount,
            intermediateToken,
            target,
            data
        );

        buyAmount = _getBalance(msg.sender, buyToken);

        _approve(intermediateToken, address(lendingPool), intermediateAmount);
        lendingPool.deposit(
            intermediateToken,
            intermediateAmount,
            msg.sender,
            0
        );

        buyAmount = _getBalance(msg.sender, buyToken) - buyAmount;

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Base contract inherited by Portals

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/solmate/utils/SafeTransferLib.sol";
import "../interface/IWETH.sol";
import "../interface/IPortalFactory.sol";
import "../interface/IPortalRegistry.sol";

abstract contract PortalBaseV1_1 is Ownable {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    // Active status of this contract. If false, contract is active (i.e un-paused)
    bool public paused;

    // Fee in basis points (bps)
    uint256 public fee;

    // Address of the Portal Registry
    IPortalRegistry public registry;

    // Address of the exchange used for swaps
    address public immutable exchange;

    // Address of the wrapped network token (e.g. WETH, wMATIC, wFTM, wAVAX, etc.)
    address public immutable wrappedNetworkToken;

    // Circuit breaker
    modifier pausable() {
        require(!paused, "Paused");
        _;
    }

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry _registry,
        address _exchange,
        address _wrappedNetworkToken,
        uint256 _fee
    ) {
        wrappedNetworkToken = _wrappedNetworkToken;
        setFee(_fee);
        exchange = _exchange;
        registry = _registry;
        registry.addPortal(address(this), portalType, protocolId);
        transferOwnership(registry.owner());
    }

    /// @notice Transfers tokens or the network token from the caller to this contract
    /// @param token The address of the token to transfer (address(0) if network token)
    /// @param quantity The quantity of tokens to transfer from the caller
    /// @dev quantity must == msg.value when token == address(0)
    /// @dev msg.value must == 0 when token != address(0)
    /// @return The quantity of tokens or network tokens transferred from the caller to this contract
    function _transferFromCaller(address token, uint256 quantity)
        internal
        virtual
        returns (uint256)
    {
        if (token == address(0)) {
            require(
                msg.value > 0 && msg.value == quantity,
                "Invalid quantity or msg.value"
            );

            return msg.value;
        }

        require(
            quantity > 0 && msg.value == 0,
            "Invalid quantity or msg.value"
        );

        ERC20(token).safeTransferFrom(msg.sender, address(this), quantity);

        return quantity;
    }

    /// @notice Returns the quantity of tokens or network tokens after accounting for the fee
    /// @param quantity The quantity of tokens to subtract the fee from
    /// @param feeBps The fee in basis points (BPS)
    /// @return The quantity of tokens or network tokens to transact with less the fee
    function _getFeeAmount(uint256 quantity, uint256 feeBps)
        internal
        view
        returns (uint256)
    {
        return
            registry.isPortal(msg.sender)
                ? quantity
                : quantity - (quantity * feeBps) / 10000;
    }

    /// @notice Executes swap or portal data at the target address
    /// @param sellToken The sell token
    /// @param sellAmount The quantity of sellToken (in sellToken base units) to send
    /// @param buyToken The buy token
    /// @param target The execution target for the data
    /// @param data The swap or portal data
    /// @return amountBought Quantity of buyToken acquired
    function _execute(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address target,
        bytes memory data
    ) internal virtual returns (uint256 amountBought) {
        if (sellToken == buyToken) {
            return sellAmount;
        }

        if (sellToken == address(0) && buyToken == wrappedNetworkToken) {
            IWETH(wrappedNetworkToken).deposit{ value: sellAmount }();
            return sellAmount;
        }

        if (sellToken == wrappedNetworkToken && buyToken == address(0)) {
            IWETH(wrappedNetworkToken).withdraw(sellAmount);
            return sellAmount;
        }

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, target, sellAmount);
        }

        uint256 initialBalance = _getBalance(address(this), buyToken);

        require(
            target == exchange || registry.isPortal(target),
            "Unauthorized target"
        );
        (bool success, bytes memory returnData) = target.call{
            value: valueToSend
        }(data);
        require(success, string(returnData));

        amountBought = _getBalance(address(this), buyToken) - initialBalance;

        require(amountBought > 0, "Invalid execution");
    }

    /// @notice Get the token or network token balance of an account
    /// @param account The owner of the tokens or network tokens whose balance is being queried
    /// @param token The address of the token (address(0) if network token)
    /// @return The owner's token or network token balance
    function _getBalance(address account, address token)
        internal
        view
        returns (uint256)
    {
        if (token == address(0)) {
            return account.balance;
        } else {
            return ERC20(token).balanceOf(account);
        }
    }

    /// @notice Approve a token for spending with finite allowance
    /// @param token The ERC20 token to approve
    /// @param spender The spender of the token
    /// @param amount The allowance to grant to the spender
    function _approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        ERC20 _token = ERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    /// @notice Collects tokens or network tokens from this contract
    /// @param tokens An array of the tokens to withdraw (address(0) if network token)
    function collect(address[] calldata tokens) external {
        address collector = registry.collector();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                collector.safeTransferETH(qty);
            } else {
                qty = ERC20(tokens[i]).balanceOf(address(this));
                ERC20(tokens[i]).safeTransfer(collector, qty);
            }
        }
    }

    /// @dev Pause or unpause the contract
    function pause() external onlyOwner {
        paused = !paused;
    }

    /// @notice Sets the fee
    /// @param _fee The new fee amount between 0.06-1%
    function setFee(uint256 _fee) public onlyOwner {
        require(_fee >= 6 && _fee <= 100, "Invalid Fee");
        fee = _fee;
    }

    /// @notice Updates the registry
    /// @param _registry The address of the new registry
    function updateRegistry(IPortalRegistry _registry) external onlyOwner {
        registry = _registry;
    }

    /// @notice Reverts if networks tokens are sent directly to this contract
    receive() external payable {
        require(msg.sender != tx.origin);
    }
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

enum PortalType {
    IN,
    OUT
}

interface IPortalRegistry {
    function addPortal(
        address portal,
        PortalType portalType,
        bytes32 protocolId
    ) external;

    function addPortalFactory(
        address portalFactory,
        PortalType portalType,
        bytes32 protocolId
    ) external;

    function removePortal(bytes32 protocolId, PortalType portalType) external;

    function owner() external view returns (address owner);

    function registrars(address origin) external view returns (bool isDeployer);

    function collector() external view returns (address collector);

    function isPortal(address portal) external view returns (bool isPortal);
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface ILendingPool {
    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import { ERC20 } from "../tokens/ERC20.sol";

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
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
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
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
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
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            )
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(
                    and(eq(mload(0), 1), gt(returndatasize(), 31)),
                    iszero(returndatasize())
                ),
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

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

import "./IPortalRegistry.sol";

interface IPortalFactory {
    function fee() external view returns (uint256 fee);

    function registry() external view returns (IPortalRegistry registry);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

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

    function approve(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        returns (bool)
    {
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

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

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

            require(
                recoveredAddress != address(0) && recoveredAddress == owner,
                "INVALID_SIGNER"
            );

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return
            block.chainid == INITIAL_CHAIN_ID
                ? INITIAL_DOMAIN_SEPARATOR
                : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
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

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Aave V2 like markets into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/ILendingPool.sol";

/// Thrown when insufficient buyAmount is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract AaveV2PortalOut is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Remove liquidity from Aave V2 like pools into network tokens/ERC20 tokens
    /// @param sellToken The Aave V2 like market address (i.e. the aToken)
    /// @param sellAmount The quantity of sellToken to Portal out (aTokens are 1:1 with underlying asset)
    /// @param intermediateToken The underlying asset of the aToken
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param lendingPool The Aave V2 like market lending pool
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        ILendingPool lendingPool
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);

        uint256 intermediateAmount = lendingPool.withdraw(
            intermediateToken,
            amount,
            address(this)
        );

        buyAmount = _execute(
            intermediateToken,
            intermediateAmount,
            buyToken,
            target,
            data
        );

        buyAmount = _getFeeAmount(buyAmount, fee);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Uniswap V2-like pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router.sol";
import "./interface/IUniswapV2Pair.sol";
import "../interface/IPortalRegistry.sol";

contract UniswapV2PortalOut is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    uint256 internal constant DEADLINE = type(uint256).max;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    /// Thrown when insufficient liquidity is received after withdrawal
    /// @param buyAmount The amount of liquidity received
    /// @param minBuyAmount The minimum acceptable quantity of liquidity received
    error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Remove liquidity from Uniswap V2-like pools into network tokens/ERC20 tokens
    /// @param sellToken The pool (i.e. pair) address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the swaps
    /// @param data  The encoded calls for the buyToken swaps
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes[] calldata data,
        address partner,
        IUniswapV2Router02 router
    ) external pausable returns (uint256 buyAmount) {
        sellAmount = _transferFromCaller(sellToken, sellAmount);

        buyAmount = _remove(
            router,
            sellToken,
            sellAmount,
            buyToken,
            target,
            data
        );

        buyAmount = _getFeeAmount(buyAmount, fee);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Removes both tokens from the pool and swaps for buyToken
    /// @param router The router belonging to the protocol to remove liquidity from
    /// @param sellToken The pair address (i.e. the LP address)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param sellAmount The quantity of LP tokens to remove from the pool
    /// @param target The excecution target for the swaps
    /// @param data  The encoded calls for the buyToken swaps
    /// @return buyAmount The quantity of buyToken acquired
    function _remove(
        IUniswapV2Router02 router,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address target,
        bytes[] calldata data
    ) internal returns (uint256 buyAmount) {
        IUniswapV2Pair pair = IUniswapV2Pair(sellToken);

        _approve(sellToken, address(router), sellAmount);

        address token0 = pair.token0();
        address token1 = pair.token1();

        (uint256 amount0, uint256 amount1) = router.removeLiquidity(
            token0,
            token1,
            sellAmount,
            1,
            1,
            address(this),
            DEADLINE
        );

        buyAmount = _execute(token0, amount0, buyToken, target, data[0]);
        buyAmount += _execute(token1, amount1, buyToken, target, data[1]);
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Base contract inherited by Portal Factories

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/solmate/utils/SafeTransferLib.sol";
import "../interface/IWETH.sol";
import "../interface/IPortalFactory.sol";
import "../interface/IPortalRegistry.sol";

abstract contract PortalBaseV1 is Ownable {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    // Active status of this contract. If false, contract is active (i.e un-paused)
    bool public paused;

    // Fee in basis points (bps)
    uint256 public fee;

    // Address of the Portal Registry
    IPortalRegistry public registry;

    // Address of the exchange used for swaps
    address public immutable exchange;

    // Address of the wrapped network token (e.g. WETH, wMATIC, wFTM, wAVAX, etc.)
    address public immutable wrappedNetworkToken;

    // Circuit breaker
    modifier pausable() {
        require(!paused, "Paused");
        _;
    }

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry _registry,
        address _exchange,
        address _wrappedNetworkToken,
        uint256 _fee
    ) {
        wrappedNetworkToken = _wrappedNetworkToken;
        setFee(_fee);
        exchange = _exchange;
        registry = _registry;
        registry.addPortal(address(this), portalType, protocolId);
        transferOwnership(registry.owner());
    }

    /// @notice Transfers tokens or the network token from the caller to this contract
    /// @param token The address of the token to transfer (address(0) if network token)
    /// @param quantity The quantity of tokens to transfer from the caller
    /// @dev quantity must == msg.value when token == address(0)
    /// @dev msg.value must == 0 when token != address(0)
    /// @return The quantity of tokens or network tokens transferred from the caller to this contract
    function _transferFromCaller(address token, uint256 quantity)
        internal
        virtual
        returns (uint256)
    {
        if (token == address(0)) {
            require(
                msg.value > 0 && msg.value == quantity,
                "Invalid quantity or msg.value"
            );

            return msg.value;
        }

        require(
            quantity > 0 && msg.value == 0,
            "Invalid quantity or msg.value"
        );

        ERC20(token).safeTransferFrom(msg.sender, address(this), quantity);

        return quantity;
    }

    /// @notice Returns the quantity of tokens or network tokens after accounting for the fee
    /// @param quantity The quantity of tokens to subtract the fee from
    /// @param feeBps The fee in basis points (BPS)
    /// @return The quantity of tokens or network tokens to transact with less the fee
    function _getFeeAmount(uint256 quantity, uint256 feeBps)
        internal
        pure
        returns (uint256)
    {
        return quantity - (quantity * feeBps) / 10000;
    }

    /// @notice Executes swap or portal data at the target address
    /// @param sellToken The sell token
    /// @param sellAmount The quantity of sellToken (in sellToken base units) to send
    /// @param buyToken The buy token
    /// @param target The execution target for the data
    /// @param data The swap or portal data
    /// @return amountBought Quantity of buyToken acquired
    function _execute(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address target,
        bytes memory data
    ) internal virtual returns (uint256 amountBought) {
        if (sellToken == buyToken) {
            return sellAmount;
        }

        if (sellToken == address(0) && buyToken == wrappedNetworkToken) {
            IWETH(wrappedNetworkToken).deposit{ value: sellAmount }();
            return sellAmount;
        }

        if (sellToken == wrappedNetworkToken && buyToken == address(0)) {
            IWETH(wrappedNetworkToken).withdraw(sellAmount);
            return sellAmount;
        }

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, target, sellAmount);
        }

        uint256 initialBalance = _getBalance(address(this), buyToken);

        require(
            target == exchange || registry.isPortal(target),
            "Unauthorized target"
        );
        (bool success, bytes memory returnData) = target.call{
            value: valueToSend
        }(data);
        require(success, string(returnData));

        amountBought = _getBalance(address(this), buyToken) - initialBalance;

        require(amountBought > 0, "Invalid execution");
    }

    /// @notice Get the token or network token balance of an account
    /// @param account The owner of the tokens or network tokens whose balance is being queried
    /// @param token The address of the token (address(0) if network token)
    /// @return The owner's token or network token balance
    function _getBalance(address account, address token)
        internal
        view
        returns (uint256)
    {
        if (token == address(0)) {
            return account.balance;
        } else {
            return ERC20(token).balanceOf(account);
        }
    }

    /// @notice Approve a token for spending with finite allowance
    /// @param token The ERC20 token to approve
    /// @param spender The spender of the token
    /// @param amount The allowance to grant to the spender
    function _approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        ERC20 _token = ERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    /// @notice Collects tokens or network tokens from this contract
    /// @param tokens An array of the tokens to withdraw (address(0) if network token)
    function collect(address[] calldata tokens) external {
        address collector = registry.collector();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                collector.safeTransferETH(qty);
            } else {
                qty = ERC20(tokens[i]).balanceOf(address(this));
                ERC20(tokens[i]).safeTransfer(collector, qty);
            }
        }
    }

    /// @dev Pause or unpause the contract
    function pause() external onlyOwner {
        paused = !paused;
    }

    /// @notice Sets the fee
    /// @param _fee The new fee amount between 0.06-1%
    function setFee(uint256 _fee) public onlyOwner {
        require(_fee >= 6 && _fee <= 100, "Invalid Fee");
        fee = _fee;
    }

    /// @notice Updates the registry
    /// @param _registry The address of the new registry
    function updateRegistry(IPortalRegistry _registry) external onlyOwner {
        registry = _registry;
    }

    /// @notice Reverts if networks tokens are sent directly to this contract
    receive() external payable {
        require(msg.sender != tx.origin);
    }
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function factory() external pure returns (address);
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Uniswap V2-like pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "./interface/Babylonian.sol";
import "./interface/IUniswapV2Factory.sol";
import "./interface/IUniswapV2Router.sol";
import "./interface/IUniswapV2Pair.sol";
import "../interface/IPortalRegistry.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract UniswapV2PortalIn is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Add liquidity to Uniswap V2-like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The pool (i.e. pair) address
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param router The Uniswap V2-like router to be used for adding liquidity
    /// @param returnResidual Return residual, if any, that remains
    /// following the deposit. Note: Probably a waste of gas to set to true
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        IUniswapV2Router02 router,
        bool returnResidual
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(
            router,
            intermediateToken,
            amount,
            buyToken,
            returnResidual
        );

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Sets up the correct token ratio and deposits into the pool
    /// @param router The router belonging to the protocol to add liquidity to
    /// @param sellToken The token address to swap from
    /// @param sellAmount The quantity of tokens to sell
    /// @param buyToken The pool (i.e. pair) address
    /// @param returnResidual Return residual, if any, that remains
    /// following the deposit. Note: Probably a waste of gas to set to true
    /// @return liquidity The quantity of LP tokens acquired
    function _deposit(
        IUniswapV2Router02 router,
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        bool returnResidual
    ) internal returns (uint256 liquidity) {
        IUniswapV2Pair pair = IUniswapV2Pair(buyToken);

        (uint256 res0, uint256 res1, ) = pair.getReserves();

        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 token0Amount;
        uint256 token1Amount;

        if (sellToken == token0) {
            uint256 swapAmount = _getSwapAmount(res0, sellAmount);
            if (swapAmount <= 0) swapAmount = sellAmount / 2;

            token1Amount = _intraSwap(
                router,
                sellToken,
                swapAmount,
                pair.token1()
            );

            token0Amount = sellAmount - swapAmount;
        } else {
            uint256 swapAmount = _getSwapAmount(res1, sellAmount);
            if (swapAmount <= 0) swapAmount = sellAmount / 2;

            token0Amount = _intraSwap(router, sellToken, swapAmount, token0);

            token1Amount = sellAmount - swapAmount;
        }
        liquidity = _addLiquidity(
            router,
            buyToken,
            token0,
            token0Amount,
            token1,
            token1Amount,
            returnResidual
        );
    }

    /// @notice Returns the optimal intra-pool swap quantity such that
    /// that the proportion of both tokens held subsequent to the swap is
    /// equal to the proportion of the assets in the pool. Assumes typical
    /// Uniswap V2 fee.
    /// @param reserves The reserves of the sellToken
    /// @param amount The total quantity of tokens held
    /// @return The quantity of the sell token to swap
    function _getSwapAmount(uint256 reserves, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return
            (Babylonian.sqrt(
                reserves * ((amount * 3988000) + (reserves * 3988009))
            ) - (reserves * 1997)) / 1994;
    }

    /// @notice Used for intra-pool swaps of ERC20 assets
    /// @param router The Uniswap V2-like router to use for the swap
    /// @param sellToken The token address to swap from
    /// @param sellAmount The quantity of tokens to sell
    /// @param buyToken The token address to swap to
    /// @return tokenBought The quantity of tokens bought
    function _intraSwap(
        IUniswapV2Router02 router,
        address sellToken,
        uint256 sellAmount,
        address buyToken
    ) internal returns (uint256 tokenBought) {
        if (sellToken == buyToken) {
            return sellAmount;
        }

        _approve(sellToken, address(router), sellAmount);

        address[] memory path = new address[](2);
        path[0] = sellToken;
        path[1] = buyToken;

        tokenBought = router.swapExactTokensForTokens(
            sellAmount,
            1,
            path,
            address(this),
            block.timestamp
        )[path.length - 1];
    }

    /// @notice Deposits both tokens into the pool
    /// @param router The Uniswap V2-like router to use to add liquidity
    /// @param token0Amount The quantity of token0 to add to the pool
    /// @param token1 The address of the 1st token in the pool
    /// @param token1Amount The quantity of token1 to add to the pool
    /// @param returnResidual Return residual, if any, that remains
    /// following the deposit. Note: Probably a waste of gas to set to true
    /// @return liquidity pool tokens acquired
    function _addLiquidity(
        IUniswapV2Router02 router,
        address buyToken,
        address token0,
        uint256 token0Amount,
        address token1,
        uint256 token1Amount,
        bool returnResidual
    ) internal returns (uint256) {
        _approve(token0, address(router), token0Amount);
        _approve(token1, address(router), token1Amount);

        uint256 beforeLiquidity = _getBalance(msg.sender, buyToken);

        (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
            token0,
            token1,
            token0Amount,
            token1Amount,
            1,
            1,
            msg.sender,
            block.timestamp
        );

        if (returnResidual) {
            if (token0Amount - amountA > 0) {
                ERC20(token0).safeTransfer(msg.sender, token0Amount - amountA);
            }
            if (token1Amount - amountB > 0) {
                ERC20(token1).safeTransfer(msg.sender, token1Amount - amountB);
            }
        }
        return _getBalance(msg.sender, buyToken) - beforeLiquidity;
    }
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Yearn Vaults using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "./interface/IVault.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract YearnPortalIn is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Add liquidity to Yearn like vaults with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be the vault underlying token)
    /// @param buyToken The vault token address (i.e. the vault token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        uint256 balance = _getBalance(address(this), buyToken);

        _approve(intermediateToken, buyToken, amount);
        uint256 valueToSend = intermediateToken == address(0) ? amount : 0;
        IVault(buyToken).deposit{ value: valueToSend }(amount);

        buyAmount = _getBalance(address(this), buyToken) - balance;

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IVault {
    function deposit(uint256 _amount) external payable;

    function withdraw(uint256 _amount) external;

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Yearn Vaults into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "./interface/IVault.sol";

/// Thrown when insufficient liquidity is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract YearnPortalOut is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Remove liquidity from Yearn like vaults into network tokens/ERC20 tokens
    /// @param sellToken The vault token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be the vault underlying token)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner
    ) public payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);

        uint256 balance = _getBalance(address(this), intermediateToken);
        IVault(sellToken).withdraw(amount);
        amount = _getBalance(address(this), intermediateToken) - balance;

        buyAmount = _execute(intermediateToken, amount, buyToken, target, data);

        buyAmount = _getFeeAmount(buyAmount, fee);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Remove liquidity from Yearn like vaults into network tokens/ERC20 tokens with permit
    /// @param sellToken The vault token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be the vault underlying token)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v
    /// @return buyAmount The quantity of buyToken acquired
    function portalOutWithPermit(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata signature
    ) external payable pausable returns (uint256 buyAmount) {
        _permit(sellToken, sellAmount, signature);

        return
            portalOut(
                sellToken,
                sellAmount,
                intermediateToken,
                buyToken,
                minBuyAmount,
                target,
                data,
                partner
            );
    }

    function _permit(
        address sellToken,
        uint256 sellAmount,
        bytes calldata signature
    ) internal {
        bool success = IVault(sellToken).permit(
            msg.sender,
            address(this),
            sellAmount,
            0,
            signature
        );
        require(success, "Could Not Permit");
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Yearn Vaults using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "./interface/IYearnPartnerTracker.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract YearnPartnerPortalIn is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IYearnPartnerTracker immutable YearnPartnerTracker;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IYearnPartnerTracker yearnPartnerTracker
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        YearnPartnerTracker = yearnPartnerTracker;
    }

    /// @notice Add liquidity to Yearn like vaults with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be the vault underlying token)
    /// @param buyToken The vault token address (i.e. the vault token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param yearnAffiliate The Yearn affiliate address
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        address yearnAffiliate
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        uint256 balance = _getBalance(address(this), buyToken);

        _approve(intermediateToken, address(YearnPartnerTracker), amount);
        YearnPartnerTracker.deposit(buyToken, yearnAffiliate, amount);

        buyAmount = _getBalance(address(this), buyToken) - balance;

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IYearnPartnerTracker {
    /**
     * @notice Deposit into a vault the specified amount from depositer
     * @param vault The address of the vault
     * @param partnerId The address of the partner who has referred this deposit
     * @param amount The amount to deposit
     * @return The number of yVault tokens received
     */
    function deposit(
        address vault,
        address partnerId,
        uint256 amount
    ) external returns (uint256);
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Stargate pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IStargateRouter.sol";

/// Thrown when insufficient liquidity is received after withdrawal
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract StargatePortalOut is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IStargateRouter public immutable ROUTER;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IStargateRouter _router
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        ROUTER = _router;
    }

    /// @notice Remove liquidity from Stargate pools into network tokens/ERC20 tokens
    /// @param sellToken  The Stargate pool address (i.e. the LP token address)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be an underlying pool token)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolId The ID of the pool
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        uint16 poolId
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);

        _approve(sellToken, address(ROUTER), amount);

        uint256 intermediateAmount = _getBalance(
            address(this),
            intermediateToken
        );
        ROUTER.instantRedeemLocal(poolId, amount, address(this));
        intermediateAmount =
            _getBalance(address(this), intermediateToken) -
            intermediateAmount;

        buyAmount = _execute(
            intermediateToken,
            intermediateAmount,
            buyToken,
            target,
            data
        );

        buyAmount = _getFeeAmount(buyAmount, fee);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IStargateRouter {
    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256 amountSD);
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Stargate like pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IStargateRouter.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract StargatePortalIn is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IStargateRouter public immutable ROUTER;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IStargateRouter _router
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        ROUTER = _router;
    }

    /// @notice Add liquidity to Stargate like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The Stargate pool address (i.e. the LP token address)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolId The ID of the pool
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        uint256 poolId
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        uint256 balance = _getBalance(msg.sender, buyToken);

        _approve(intermediateToken, address(ROUTER), amount);

        ROUTER.addLiquidity(poolId, amount, msg.sender);

        buyAmount = _getBalance(msg.sender, buyToken) - balance;

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Curve pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "./interface/ICurveAddressProvider.sol";
import "./interface/ICurvePool.sol";
import "./interface/ICurveRegistry.sol";

/// Thrown when insufficient liquidity is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract CurvePortalOut is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Removes liquidity from Curve pools into network tokens/ERC20 tokens
    /// @param sellToken The curve pool token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolData Encoded pool data including the following for the pool and metapool sequentially (if applicable):
    /// pool The address of the swap/deposit contract (address(0) for metapool set if not metapool)
    /// intermediateToken The address of the token at the index
    /// The index of the token being removed from the pool (i.e the index of intermediateToken)
    /// isInt128 A boolean value specifying whether the index is int128 or uint256
    /// removeUnderlying A boolean value specifying whether to withdraw the unwrapped version of the token
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata poolData
    ) external payable pausable returns (uint256 buyAmount) {
        sellAmount = _transferFromCaller(sellToken, sellAmount);

        address intermediateToken;
        (sellAmount, intermediateToken) = _remove(
            sellToken,
            sellAmount,
            poolData
        );

        buyAmount = _execute(
            intermediateToken,
            sellAmount,
            buyToken,
            target,
            data
        );

        buyAmount = _getFeeAmount(buyAmount, fee);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Handles removal of tokens and parsing of pooldata for pools and metapools
    /// @param sellToken The curve pool token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param poolData Encoded pool data including the following for the pool and metapool sequentially (if applicable):
    /// pool The address of the swap/deposit contract (address(0) for metapool set if not metapool)
    /// intermediateToken The address of the token at the index
    /// The index of the token being removed from the pool (i.e the index of intermediateToken)
    /// isInt128 A boolean value specifying whether the index is int128 or uint256
    /// removeUnderlying A boolean value specifying whether to withdraw the unwrapped version of the token
    /// @return buyAmount The quantity buyToken acquired
    /// @return intermediateToken The address of the intermediate token to swap to buyToken
    function _remove(
        address sellToken,
        uint256 sellAmount,
        bytes calldata poolData
    ) internal returns (uint256 buyAmount, address intermediateToken) {
        address pool;
        uint256 coinIndex;
        bool isInt128;
        bool removeUnderlying;

        (
            pool,
            intermediateToken,
            coinIndex,
            isInt128,
            removeUnderlying
        ) = _parsePoolData(poolData, false);

        buyAmount = _exitCurve(
            sellToken,
            sellAmount,
            pool,
            intermediateToken,
            coinIndex,
            isInt128,
            removeUnderlying
        );

        if (
            keccak256(abi.encodePacked(poolData[160:180])) !=
            keccak256(abi.encodePacked(address(0)))
        ) {
            address poolToken = intermediateToken;
            (
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying
            ) = _parsePoolData(poolData, true);

            buyAmount = _exitCurve(
                poolToken,
                buyAmount,
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying
            );
        }
    }

    /// @notice Removes liquidity from the pool
    /// @param sellToken The curve pool token address
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param pool The address of the swap/deposit contract (address(0) for metapool set if not metapool)
    /// @param coinIndex The index of the token being removed from the pool (i.e the index of intermediateToken)
    /// @param isInt128 A boolean value specifying whether the index is int128 or uint256
    /// @param removeUnderlying A boolean value specifying whether to withdraw the unwrapped version of the token
    /// @return buyAmount The quantity buyToken acquired
    function _exitCurve(
        address sellToken,
        uint256 sellAmount,
        address pool,
        address buyToken,
        uint256 coinIndex,
        bool isInt128,
        bool removeUnderlying
    ) internal returns (uint256) {
        _approve(sellToken, pool, sellAmount);

        uint256 balance = _getBalance(address(this), buyToken);

        ICurvePool _pool = ICurvePool(pool);

        if (isInt128) {
            if (removeUnderlying) {
                _pool.remove_liquidity_one_coin(
                    sellAmount,
                    int128(uint128(coinIndex)),
                    0,
                    true
                );
            } else {
                _pool.remove_liquidity_one_coin(
                    sellAmount,
                    int128(uint128(coinIndex)),
                    0
                );
            }
        } else {
            if (removeUnderlying) {
                _pool.remove_liquidity_one_coin(sellAmount, coinIndex, 0, true);
            } else {
                _pool.remove_liquidity_one_coin(sellAmount, coinIndex, 0);
            }
        }

        return _getBalance(address(this), buyToken) - balance;
    }

    function _parsePoolData(bytes calldata poolData, bool isMetapool)
        internal
        pure
        returns (
            address pool,
            address intermediateToken,
            uint256 coinIndex,
            bool isInt128,
            bool removeUnderlying
        )
    {
        if (isMetapool) {
            (
                ,
                ,
                ,
                ,
                ,
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying
            ) = abi.decode(
                poolData,
                (
                    address,
                    address,
                    uint256,
                    bool,
                    bool,
                    address,
                    address,
                    uint256,
                    bool,
                    bool
                )
            );
        } else {
            (
                pool,
                intermediateToken,
                coinIndex,
                isInt128,
                removeUnderlying,
                ,
                ,
                ,
                ,

            ) = abi.decode(
                poolData,
                (
                    address,
                    address,
                    uint256,
                    bool,
                    bool,
                    address,
                    address,
                    uint256,
                    bool,
                    bool
                )
            );
        }
    }
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface ICurveAddressProvider {
    function get_registry() external view returns (address);

    function get_address(uint256 _id) external view returns (address);
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface ICurvePool {
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount)
        external
        payable;

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external payable;

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount)
        external
        payable;

    function add_liquidity(
        uint256[3] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external payable;

    function add_liquidity(uint256[4] memory _amounts, uint256 _min_mint_amount)
        external
        payable;

    function add_liquidity(
        uint256[4] memory _amounts,
        uint256 _min_mint_amount,
        bool _use_underlying
    ) external payable;

    function coins(uint256 i) external view returns (address);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool _use_underlying
    ) external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        int128 i,
        uint256 min_amount,
        bool _use_underlying
    ) external;
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface ICurveRegistry {
    function get_coins(address _pool) external view returns (address[8] memory);

    function get_n_coins(address _pool) external view returns (uint256);
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Curve pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "./interface/ICurveAddressProvider.sol";
import "./interface/ICurvePool.sol";
import "./interface/ICurveRegistry.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract CurvePortalIn is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Add liquidity to Curve pools with network tokens/ERC20 tokens
    /// @dev This contract can call itself in cases where the pool is a metapool.
    /// In these cases, transfers, events and fees are omitted.
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The curve pool token address
    /// NOTE This may be different from the swap/deposit address!
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param poolData Encoded pool data including the following:
    /// pool The address of the swap/deposit contract
    /// numCoins The number of coins in the pool
    /// The index of the intermediateToken in the pool
    /// depositUnderlying A boolean value specifying whether to deposit the unwrapped version of intermediateToken
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata poolData
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = sellAmount;
        if (msg.sender != address(this)) {
            amount = _transferFromCaller(sellToken, sellAmount);
            amount = _getFeeAmount(amount, fee);
        }
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(intermediateToken, amount, buyToken, poolData);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        if (msg.sender != address(this)) {
            ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

            emit PortalIn(
                sellToken,
                sellAmount,
                buyToken,
                buyAmount,
                fee,
                msg.sender,
                partner
            );
        }
    }

    /// @notice Deposits the sellToken into the pool using the correct interface based on the
    /// number of coins in the pool
    /// @param sellToken The token address to swap from
    /// @param sellAmount The quantity of tokens to sell
    /// @param buyToken The curve pool token address
    /// @param poolData Encoded pool data including the following:
    /// pool The address of the swap/deposit contract
    /// numCoins The number of coins in the pool
    /// The index of the intermediateToken in the pool
    /// depositUnderlying A boolean value specifying whether to deposit the unwrapped version of intermediateToken
    /// @return liquidity The quantity of LP tokens acquired
    function _deposit(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        bytes calldata poolData
    ) internal returns (uint256) {
        (
            address pool,
            uint256 numCoins,
            uint256 coinIndex,
            bool depositUnderlying
        ) = abi.decode(poolData, (address, uint256, uint256, bool));

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, pool, sellAmount);
        }

        uint256 balance = _getBalance(address(this), buyToken);

        ICurvePool _pool = ICurvePool(pool);

        if (numCoins == 2) {
            uint256[2] memory _amounts;
            _amounts[coinIndex] = sellAmount;
            depositUnderlying
                ? _pool.add_liquidity{ value: valueToSend }(_amounts, 0, true)
                : _pool.add_liquidity{ value: valueToSend }(_amounts, 0);
        } else if (numCoins == 3) {
            uint256[3] memory _amounts;
            _amounts[coinIndex] = sellAmount;
            depositUnderlying
                ? _pool.add_liquidity{ value: valueToSend }(_amounts, 0, true)
                : _pool.add_liquidity{ value: valueToSend }(_amounts, 0);
        } else {
            uint256[4] memory _amounts;
            _amounts[coinIndex] = sellAmount;
            depositUnderlying
                ? _pool.add_liquidity{ value: valueToSend }(_amounts, 0, true)
                : _pool.add_liquidity{ value: valueToSend }(_amounts, 0);
        }
        return _getBalance(address(this), buyToken) - balance;
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract deposits into Aave V3 using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1_1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IPool.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract AaveV3PortalIn is PortalBaseV1_1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1_1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Add liquidity to Aave V3 like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be the underlying token)
    /// @param buyToken The Aave V3 like market address (i.e. the aToken)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param lendingPool The Aave V3 like market lending pool
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        IPool lendingPool
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);

        uint256 intermediateAmount = _execute(
            sellToken,
            amount,
            intermediateToken,
            target,
            data
        );

        buyAmount = _getBalance(msg.sender, buyToken);

        _approve(intermediateToken, address(lendingPool), intermediateAmount);
        lendingPool.supply(
            intermediateToken,
            intermediateAmount,
            msg.sender,
            0
        );

        buyAmount = _getBalance(msg.sender, buyToken) - buyAmount;

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IPool {
    /**
     * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to supply
     * @param amount The amount to be supplied
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to The address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Base contract inherited by Portal Factories

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/solmate/utils/SafeTransferLib.sol";
import "../interface/IWETH.sol";
import "../interface/IPortalFactory.sol";
import "../interface/IPortalRegistry.sol";

abstract contract PortalFactoryBaseV1 is Ownable {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    // Active status of this contract. If false, contract is active (i.e un-paused)
    bool public paused;

    // Fee in basis points (bps)
    uint256 public fee;

    // Address of the Portal Factory
    IPortalFactory public immutable factory;

    // Address of the Portal Registry
    IPortalRegistry public registry;

    // Address of the exchange used for swaps
    address public immutable exchange;

    // Address of the wrapped network token (e.g. WETH, wMATIC, wFTM, wAVAX, etc.)
    address public immutable wrappedNetworkToken;

    // Circuit breaker
    modifier pausable() {
        require(!paused, "Paused");
        _;
    }

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        address _factory,
        IPortalRegistry _registry,
        address _exchange,
        address _wrappedNetworkToken,
        uint256 _fee
    ) {
        factory = IPortalFactory(_factory);
        wrappedNetworkToken = _wrappedNetworkToken;
        fee = _fee;
        exchange = _exchange;
        registry = _registry;
        registry.addPortal(address(this), portalType, protocolId);
        transferOwnership(registry.owner());
    }

    /// @notice Transfers tokens or the network token from the caller to this contract
    /// @param token The address of the token to transfer (address(0) if network token)
    /// @param quantity The quantity of tokens to transfer from the caller (ignored if network tokens)
    /// @return The quantity of tokens or network tokens transferred from the caller to this contract
    function _transferFromCaller(address token, uint256 quantity)
        internal
        virtual
        returns (uint256)
    {
        if (token == address(0)) {
            require(msg.value > 0, "No network tokens sent");

            return msg.value;
        }

        require(quantity > 0, "Invalid quantity");
        require(msg.value == 0, "Network tokens sent with token");

        ERC20(token).safeTransferFrom(msg.sender, address(this), quantity);

        return quantity;
    }

    /// @notice Returns the quantity of tokens or network tokens after accounting for the fee
    /// @param quantity The quantity of tokens being transacted
    /// @param feeBps The fee in basis points (BPS)
    /// @return The quantity of tokens or network tokens to transact with less the fee
    function _getFeeAmount(uint256 quantity, uint256 feeBps)
        internal
        pure
        returns (uint256)
    {
        return quantity - (quantity * feeBps) / 10000;
    }

    /// @notice Executes swap or portal data at the target address
    /// @param sellToken The sell token
    /// @param sellAmount The quantity of sellToken (in sellToken base units) to send
    /// @param buyToken The buy token
    /// @param target The execution target for the data
    /// @param data The swap or portal data
    /// @return amountBought Quantity of buyToken acquired
    function _execute(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        address target,
        bytes memory data
    ) internal virtual returns (uint256 amountBought) {
        if (sellToken == buyToken) {
            return sellAmount;
        }

        if (sellToken == address(0) && buyToken == wrappedNetworkToken) {
            IWETH(wrappedNetworkToken).deposit{ value: sellAmount }();
            return sellAmount;
        }

        if (sellToken == wrappedNetworkToken && buyToken == address(0)) {
            IWETH(wrappedNetworkToken).withdraw(sellAmount);
            return sellAmount;
        }

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, target, sellAmount);
        }

        uint256 initialBalance = _getBalance(address(this), buyToken);

        require(
            target == exchange || registry.isPortal(target),
            "Unauthorized target"
        );
        (bool success, bytes memory returnData) = target.call{
            value: valueToSend
        }(data);
        require(success, string(returnData));

        amountBought = _getBalance(address(this), buyToken) - initialBalance;

        require(amountBought > 0, "Invalid execution");
    }

    /// @notice Get the token or network token balance of an account
    /// @param account The owner of the tokens or network tokens whose balance is being queried
    /// @param token The address of the token (address(0) if network token)
    /// @return The owner's token or network token balance
    function _getBalance(address account, address token)
        internal
        view
        returns (uint256)
    {
        if (token == address(0)) {
            return account.balance;
        } else {
            return ERC20(token).balanceOf(account);
        }
    }

    /// @notice Approve a token for spending with finite allowance
    /// @param token The ERC20 token to approve
    /// @param spender The spender of the token
    /// @param amount The allowance to grant to the spender
    function _approve(
        address token,
        address spender,
        uint256 amount
    ) internal {
        ERC20 _token = ERC20(token);
        _token.safeApprove(spender, 0);
        _token.safeApprove(spender, amount);
    }

    /// @notice Collects tokens or network tokens from this contract
    /// @param tokens An array of the tokens to withdraw (address(0) if network token)
    function collect(address[] calldata tokens) external {
        address collector = registry.collector();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == address(0)) {
                qty = address(this).balance;
                collector.safeTransferETH(qty);
            } else {
                qty = ERC20(tokens[i]).balanceOf(address(this));
                ERC20(tokens[i]).safeTransfer(collector, qty);
            }
        }
    }

    /// @dev Pause or unpause the contract
    function pause() external onlyOwner {
        paused = !paused;
    }

    /// @notice Updates the fee from the factory
    function updateFee() external {
        fee = factory.fee();
    }

    /// @notice Updates the registry from the factory
    function updateRegistry() external {
        registry = factory.registry();
    }

    /// @notice Reverts if networks tokens are sent directly to this contract
    receive() external payable {
        require(msg.sender != tx.origin);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "./ERC20.sol";

import {SafeTransferLib} from "../utils/SafeTransferLib.sol";

/// @notice Minimalist and modern Wrapped Ether implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/WETH.sol)
/// @author Inspired by WETH9 (https://github.com/dapphub/ds-weth/blob/master/src/weth9.sol)
contract WETH is ERC20("Wrapped Ether", "WETH", 18) {
    using SafeTransferLib for address;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    function deposit() public payable virtual {
        _mint(msg.sender, msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public virtual {
        _burn(msg.sender, amount);

        emit Withdrawal(msg.sender, amount);

        msg.sender.safeTransferETH(amount);
    }

    receive() external payable virtual {
        deposit();
    }
}

// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Registry of Portals and Portal Factories

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";

contract PortalRegistryV1 is Ownable {
    // The multisig collector address
    address public collector;

    // The addresses of the registrars
    mapping(address => bool) public registrars;

    // Tracks existing portals for use as targets for calldata execution
    mapping(address => bool) public isPortal;

    // Tracks portal partners for revenue sharing
    mapping(address => bool) public partners;

    // Returns a portal address given a protocolId and portal type
    mapping(bytes32 => mapping(PortalType => Portal)) public getPortalById;

    // Tracks supported platforms
    bytes32[] internal supportedPlatforms;

    // Tracks the total number of portals
    uint256 public numPortals;

    // The type of Portal where 1 = Portal In and 2 = Portal Out
    enum PortalType {
        IN,
        OUT
    }

    struct Portal {
        address portal;
        PortalType portalType;
        bytes32 protocolId;
        uint96 version;
        bool active;
    }

    /// @notice Emitted when a new portal is created
    /// @param portal The newly created portal
    /// @param numPortals The total number of portals in existence
    event AddPortal(Portal portal, uint256 numPortals);

    /// @notice Emitted when a portal is updated
    /// @param portal The updated portal
    /// @param numPortals The total number of portals in existence
    event UpdatePortal(Portal portal, uint256 numPortals);

    /// @notice Emitted when a portal is removed
    /// @param portal The removed portal
    /// @param numPortals The total number of portals in existence
    event RemovePortal(Portal portal, uint256 numPortals);

    // Only registrars may add new portals to the registry
    modifier onlyRegistrars() {
        require(registrars[tx.origin], "Invalid origin");
        _;
    }

    constructor(address _collector, address _owner) {
        collector = _collector;
        registrars[msg.sender] = true;
        registrars[_owner] = true;
        transferOwnership(_owner);
    }

    /// @notice Adds new portals deployed by active registrars
    /// @param portal The address of the new portal
    /// @param portalType The type of portal - in or out
    /// @param protocolId The bytes32 representation of the name of the protocol
    function addPortal(
        address portal,
        PortalType portalType,
        bytes32 protocolId
    ) external onlyRegistrars {
        Portal storage existingPortal = getPortalById[protocolId][portalType];
        if (existingPortal.version != 0) {
            isPortal[existingPortal.portal] = false;
            existingPortal.portal = portal;
            existingPortal.version++;
            existingPortal.active = true;
            isPortal[portal] = true;
            emit UpdatePortal(existingPortal, numPortals);
        } else {
            Portal memory newPortal = Portal(
                portal,
                portalType,
                protocolId,
                1,
                true
            );
            getPortalById[protocolId][portalType] = newPortal;
            isPortal[portal] = true;
            supportedPlatforms.push(protocolId);
            emit AddPortal(newPortal, numPortals++);
        }
    }

    /// @notice Removes an inactivates existing portals
    /// @param portalType The type of portal - in or out
    /// @param protocolId The bytes32 representation of the name of the protocol
    function removePortal(bytes32 protocolId, PortalType portalType)
        external
        onlyOwner
    {
        Portal storage deletedPortal = getPortalById[protocolId][portalType];
        deletedPortal.active = false;
        isPortal[deletedPortal.portal] = false;

        emit RemovePortal(deletedPortal, numPortals);
    }

    /// @notice Returns an array of all of the portal objects by type
    /// @param portalType The type of portal - in or out
    function getAllPortals(PortalType portalType)
        external
        view
        returns (Portal[] memory)
    {
        Portal[] memory portals = new Portal[](numPortals);
        for (uint256 i = 0; i < supportedPlatforms.length; i++) {
            Portal memory portal = getPortalById[supportedPlatforms[i]][
                portalType
            ];

            portals[i] = portal;
        }
        return portals;
    }

    /// @notice Returns an array of all supported platforms
    function getSupportedPlatforms() external view returns (bytes32[] memory) {
        return supportedPlatforms;
    }

    /// @notice Updates a registrar's active status
    /// @param registrar The address of the registrar
    /// @param active The status of the registrar. Set true if
    /// the registrar is active, false otherwise
    function updateRegistrars(address registrar, bool active)
        external
        onlyOwner
    {
        registrars[registrar] = active;
    }

    /// @notice Updates a partner's active status
    /// @param partner The address of the registrar
    /// @param active The status of the partner. Set true if
    /// the partner is active, false otherwise
    function updatePartners(address partner, bool active) external onlyOwner {
        partners[partner] = active;
    }

    /// @notice Updates the collector's address
    /// @param _collector The address of the new collector
    function updateCollector(address _collector) external onlyOwner {
        collector = _collector;
    }

    /// @notice Helper function to convert a protocolId string into bytes32
    function stringToBytes32(string memory _string)
        external
        pure
        returns (bytes32 _bytes32String)
    {
        assembly {
            _bytes32String := mload(add(_string, 32))
        }
    }

    /// @notice Helper function to convert protocolId bytes32 into a string
    function bytes32ToString(bytes32 _bytes)
        external
        pure
        returns (string memory)
    {
        return string(abi.encode(_bytes));
    }
}

// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice Portals registry address provider

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";

contract PortalAddressProviderV1 is Ownable {
    /// @notice Registry is inactive if the registry address is address(0)
    struct RegistryInfo {
        address addr;
        uint256 version;
        uint256 updated;
        string description;
    }

    // Array of registries
    RegistryInfo[] internal registries;

    /// @notice Emitted when a new registry is added
    /// @param registry The newly added registry
    event AddRegistry(RegistryInfo registry);

    /// @notice Emitted when a registry is removed
    /// @param registry The removed registry
    event RemoveRegistry(RegistryInfo registry);

    /// @notice Emitted when a registry is updated
    /// @param registry The updated registry
    event UpdateRegistry(RegistryInfo registry);

    constructor(address _owner) {
        transferOwnership(_owner);
    }

    /// @notice Adds a new registry
    /// @param addr The address of the new registry
    /// @param description The description of the registry
    function addRegistry(address addr, string memory description)
        external
        onlyOwner
    {
        uint256 index = registries.length;
        registries.push(RegistryInfo(addr, 1, block.timestamp, description));

        emit AddRegistry(registries[index]);
    }

    /// @notice Removes a registry
    /// @dev sets the registry (address) to address(0)
    /// @param index The index of the registry in the registries array that is being removed
    function removeRegistry(uint256 index) external onlyOwner {
        registries[index].addr = address(0);
        registries[index].updated = block.timestamp;

        emit RemoveRegistry(registries[index]);
    }

    /// @notice Updates a registry
    /// @param index The index of the registry in the registries array that is being updated
    /// @param addr The address of the updated registry
    function updateRegistry(uint256 index, address addr) external onlyOwner {
        registries[index].addr = addr;
        ++registries[index].version;
        registries[index].updated = block.timestamp;

        emit UpdateRegistry(registries[index]);
    }

    /// @notice Returns an array of all of the registry info objects
    function getAllRegistries() external view returns (RegistryInfo[] memory) {
        return registries;
    }

    /// @notice Returns the address of the main registry
    function getRegistry() external view returns (address) {
        return registries[0].addr;
    }

    /// @notice Returns the address of the registry at the index
    /// @param index The index of the registry in the registries array whose address is being returned
    function getAddress(uint256 index) external view returns (address) {
        return registries[index].addr;
    }

    /// @notice Returns the total number of registries
    function numRegistries() external view returns (uint256) {
        return registries.length;
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity and stakes liquiditity into Convex like pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IBaseRewardPool.sol";
import "./interface/IBooster.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract ConvexPortalIn is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IBooster internal immutable BOOSTER;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IBooster _booster
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        BOOSTER = _booster;
    }

    /// @notice Add liquidity and stake into Convex like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be the underlying LP token)
    /// @param buyToken The Convex like deposit token address (i.e. the cvxToken)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// note: crv tokens are 1:1 with cvx tokens
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @param rewardPool The base reward pool for the buyToken
    /// @return buyAmount The quantity of buyToken acquired
    /// @dev buyAmount is staked and not returned to msg.sender!
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        IBaseRewardPool rewardPool
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(intermediateToken, amount, buyToken, rewardPool);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        _stake(buyToken, buyAmount, rewardPool);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Deposits the Underlying LP (e.g. Curve LP) into the pool
    /// @param intermediateToken The underlying LP token to deposit
    /// @param amount The quantity of intermediateToken to deposit
    /// @param buyToken The Convex like deposit token address (i.e. the cvxToken)
    /// @param rewardPool The base reward pool for the buyToken
    function _deposit(
        address intermediateToken,
        uint256 amount,
        address buyToken,
        IBaseRewardPool rewardPool
    ) internal returns (uint256 buyAmount) {
        uint256 pid = rewardPool.pid();

        uint256 balance = _getBalance(address(this), buyToken);

        _approve(intermediateToken, address(BOOSTER), amount);
        BOOSTER.deposit(pid, amount, false);

        buyAmount = _getBalance(address(this), buyToken) - balance;
    }

    /// @notice Stakes the cvxToken into the reward pool
    /// @param buyToken The Convex like deposit token address (i.e. the cvxToken)
    /// @param buyAmount The quantity of buyToken to deposit
    /// @param rewardPool The base reward pool for the buyToken
    function _stake(
        address buyToken,
        uint256 buyAmount,
        IBaseRewardPool rewardPool
    ) internal {
        _approve(buyToken, address(rewardPool), buyAmount);
        rewardPool.stakeFor(msg.sender, buyAmount);
    }
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface IBaseRewardPool {
    function pid() external view returns (uint256);

    function stakeFor(address _for, uint256 _amount) external returns (bool);
}

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

interface IBooster {
    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Compound like pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/ICtoken.sol";

/// Thrown when insufficient buyAmount is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract CompoundPortalOut is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Remove liquidity from Compound like pools into network tokens/ERC20 tokens
    /// @param sellToken The Compound like market address (i.e. the cToken, fToken, etc.)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap to (i.e. the underlying token)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the swap
    /// @param data  The encoded call for the swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);

        uint256 balance = _getBalance(address(this), intermediateToken);

        assert(ICtoken(sellToken).redeem(amount) == 0);

        amount = _getBalance(address(this), intermediateToken) - balance;

        buyAmount = _execute(intermediateToken, amount, buyToken, target, data);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyAmount = _getFeeAmount(buyAmount, fee);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface ICtoken {
    function mint(uint256 mintAmount) external returns (uint256);

    function mint() external payable;

    function redeem(uint256 redeemTokens) external returns (uint256);
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Compound like pools (e.g. Rari Fuse) using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/ICtoken.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract CompoundPortalIn is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {}

    /// @notice Add liquidity to Compound like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The Compound like market address (i.e. the cToken, fToken, etc.)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        uint256 balance = _getBalance(address(this), buyToken);

        if (intermediateToken == address(0))
            ICtoken(buyToken).mint{ value: amount }();
        else {
            _approve(intermediateToken, buyToken, amount);
            assert(ICtoken(buyToken).mint(amount) == 0);
        }

        buyAmount = _getBalance(address(this), buyToken) - balance;

        ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract removes liquidity from Balancer V2 like pools into any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IBalancerVault.sol";

/// Thrown when insufficient buyAmount is received after withdrawal
/// @param buyAmount The amount of tokens received
/// @param minBuyAmount The minimum acceptable quantity of buyAmount
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract BalancerV2PortalOut is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IBalancerVault public immutable VAULT;

    /// @notice Emitted when a portal is exited
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalOut(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IBalancerVault _vault
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        VAULT = _vault;
    }

    /// @notice Remove liquidity from Balancer V2 like pools into network tokens/ERC20 tokens
    /// @param sellToken The Balancer V2 pool address (i.e. the LP token address)
    /// @param sellAmount The quantity of sellToken to Portal out
    /// @param intermediateToken The intermediate token to swap from (must be one of the pool tokens)
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalOut(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata poolData
    ) external payable pausable returns (uint256 buyAmount) {
        sellAmount = _transferFromCaller(sellToken, sellAmount);

        uint256 intermediateAmount = _withdraw(
            sellToken,
            sellAmount,
            intermediateToken,
            poolData
        );

        buyAmount = _execute(
            intermediateToken,
            intermediateAmount,
            buyToken,
            target,
            data
        );

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        buyAmount = _getFeeAmount(buyAmount, fee);

        buyToken == address(0)
            ? msg.sender.safeTransferETH(buyAmount)
            : ERC20(buyToken).safeTransfer(msg.sender, buyAmount);

        emit PortalOut(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Removes the intermediate token from the pool
    /// @param sellToken The pool address
    /// @param sellAmount The quantity of LP tokens to remove from the pool
    /// @param buyToken The ERC20 token being removed (i.e. the intermediate token)
    /// @param poolData Encoded pool data including the following:
    /// poolId The balancer pool ID
    /// assets An array of all tokens in the pool
    /// The index of the intermediate in the pool
    /// @return liquidity The quantity of LP tokens acquired
    function _withdraw(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        bytes calldata poolData
    ) internal returns (uint256) {
        (bytes32 poolId, address[] memory assets, uint256 index) = abi.decode(
            poolData,
            (bytes32, address[], uint256)
        );

        uint256[] memory minAmountsOut = new uint256[](assets.length);

        bytes memory userData = abi.encode(0, sellAmount, index);

        uint256 balance = _getBalance(address(this), buyToken);

        _approve(sellToken, address(VAULT), sellAmount);

        VAULT.exitPool(
            poolId,
            address(this),
            payable(address(this)),
            IBalancerVault.ExitPoolRequest({
                assets: assets,
                minAmountsOut: minAmountsOut,
                userData: userData,
                toInternalBalance: false
            })
        );

        return _getBalance(address(this), buyToken) - balance;
    }
}

/// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

interface IBalancerVault {
    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        address[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );
}

/// Copyright (C) 2022 Portals.fi

/// @author Portals.fi
/// @notice This contract adds liquidity to Balancer V2 like pools using any ERC20 token or the network token.

/// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.11;

import "../base/PortalBaseV1.sol";
import "../interface/IPortalRegistry.sol";
import "./interface/IBalancerVault.sol";

/// Thrown when insufficient liquidity is received after deposit
/// @param buyAmount The amount of liquidity received
/// @param minBuyAmount The minimum acceptable quantity of liquidity received
error InsufficientBuy(uint256 buyAmount, uint256 minBuyAmount);

contract BalancerV2PortalIn is PortalBaseV1 {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    IBalancerVault public immutable VAULT;

    /// @notice Emitted when a portal is entered
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param buyToken The ERC20 token address to buy (address(0) if network token)
    /// @param buyAmount The quantity of buyToken received
    /// @param fee The fee in BPS
    /// @param sender The  msg.sender
    /// @param partner The front end operator address
    event PortalIn(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        uint256 buyAmount,
        uint256 fee,
        address indexed sender,
        address indexed partner
    );

    constructor(
        bytes32 protocolId,
        PortalType portalType,
        IPortalRegistry registry,
        address exchange,
        address wrappedNetworkToken,
        uint256 fee,
        IBalancerVault _vault
    )
        PortalBaseV1(
            protocolId,
            portalType,
            registry,
            exchange,
            wrappedNetworkToken,
            fee
        )
    {
        VAULT = _vault;
    }

    /// @notice Add liquidity to Balancer V2 like pools with network tokens/ERC20 tokens
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to Portal in
    /// @param intermediateToken The intermediate token to swap to (must be one of the pool tokens)
    /// @param buyToken The Balancer V2 pool address (i.e. the LP token address)
    /// @param minBuyAmount The minimum quantity of buyTokens to receive. Reverts otherwise
    /// @param target The excecution target for the intermediate swap
    /// @param data  The encoded call for the intermediate swap
    /// @param partner The front end operator address
    /// @return buyAmount The quantity of buyToken acquired
    function portalIn(
        address sellToken,
        uint256 sellAmount,
        address intermediateToken,
        address buyToken,
        uint256 minBuyAmount,
        address target,
        bytes calldata data,
        address partner,
        bytes calldata poolData
    ) external payable pausable returns (uint256 buyAmount) {
        uint256 amount = _transferFromCaller(sellToken, sellAmount);
        amount = _getFeeAmount(amount, fee);
        amount = _execute(sellToken, amount, intermediateToken, target, data);

        buyAmount = _deposit(intermediateToken, amount, buyToken, poolData);

        if (buyAmount < minBuyAmount)
            revert InsufficientBuy(buyAmount, minBuyAmount);

        emit PortalIn(
            sellToken,
            sellAmount,
            buyToken,
            buyAmount,
            fee,
            msg.sender,
            partner
        );
    }

    /// @notice Deposits the sellToken into the pool
    /// @param sellToken The ERC20 token address to spend (address(0) if network token)
    /// @param sellAmount The quantity of sellToken to deposit
    /// @param buyToken The Balancer V2 pool token address
    /// @param poolData Encoded pool data including the following:
    /// poolId The balancer pool ID
    /// assets An array of all tokens in the pool
    /// The index of the sellToken in the pool
    /// @return liquidity The quantity of LP tokens acquired
    function _deposit(
        address sellToken,
        uint256 sellAmount,
        address buyToken,
        bytes calldata poolData
    ) internal returns (uint256) {
        (bytes32 poolId, address[] memory assets, uint256 index) = abi.decode(
            poolData,
            (bytes32, address[], uint256)
        );

        uint256[] memory maxAmountsIn = new uint256[](assets.length);
        maxAmountsIn[index] = sellAmount;

        bytes memory userData = abi.encode(1, maxAmountsIn, 0);

        uint256 balance = _getBalance(msg.sender, buyToken);

        uint256 valueToSend;
        if (sellToken == address(0)) {
            valueToSend = sellAmount;
        } else {
            _approve(sellToken, address(VAULT), sellAmount);
        }

        VAULT.joinPool{ value: valueToSend }(
            poolId,
            address(this),
            msg.sender,
            IBalancerVault.JoinPoolRequest({
                assets: assets,
                maxAmountsIn: maxAmountsIn,
                userData: userData,
                fromInternalBalance: false
            })
        );

        return _getBalance(msg.sender, buyToken) - balance;
    }
}