// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {OrderInfo, ResolvedOrder, SignedOrder} from "../base/ReactorStructs.sol";
import {IReactorCallback} from "../interfaces/IReactorCallback.sol";
import {IGladiusReactor} from "../interfaces/IGladiusReactor.sol";

/// @notice Quoter contract for orders
/// @dev note this is meant to be used as an off-chain lens contract to pre-validate generic orders
contract GladiusOrderQuoter is IReactorCallback {
    /// @notice thrown if reactorCallback receives more than one order
    error OrdersLengthIncorrect();

    uint256 constant ORDER_INFO_OFFSET = 64;

    /// @notice Quote the given order, returning the ResolvedOrder object which defines
    /// the current input and output token amounts required to satisfy it
    /// Also bubbles up any reverts that would occur during the processing of the order
    /// @param order abi-encoded order, including `reactor` as the first encoded struct member
    /// @param sig The order signature
    /// @return result The ResolvedOrder
    function quote(
        bytes memory order,
        bytes memory sig,
        uint256 quantity
    ) external returns (ResolvedOrder memory result) {
        try
            getReactor(order).executeWithCallback(
                SignedOrder(order, sig),
                quantity,
                bytes("")
            )
        {} catch (bytes memory reason) {
            result = parseRevertReason(reason);
        }
    }

    /// @notice Return the reactor of a given order (abi.encoded bytes).
    /// @param order abi-encoded order, including `reactor` as the first encoded struct member
    /// @return reactor
    function getReactor(
        bytes memory order
    ) public pure returns (IGladiusReactor reactor) {
        assembly {
            let orderInfoOffsetPointer := add(order, ORDER_INFO_OFFSET)
            reactor := mload(
                add(orderInfoOffsetPointer, mload(orderInfoOffsetPointer))
            )
        }
    }

    /// @notice Return the order info of a given order (abi-encoded bytes).
    /// @param order abi-encoded order, including `reactor` as the first encoded struct member
    function parseRevertReason(
        bytes memory reason
    ) private pure returns (ResolvedOrder memory order) {
        if (reason.length < 192) {
            assembly {
                revert(add(32, reason), mload(reason))
            }
        } else {
            return abi.decode(reason, (ResolvedOrder));
        }
    }

    /// @notice Reactor callback function
    /// @dev reverts with the resolved order as reason
    /// @param resolvedOrders The resolved orders
    function reactorCallback(
        ResolvedOrder[] memory resolvedOrders,
        bytes memory
    ) external pure {
        if (resolvedOrders.length != 1) {
            revert OrdersLengthIncorrect();
        }
        bytes memory order = abi.encode(resolvedOrders[0]);
        assembly {
            revert(add(32, order), mload(order))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IReactor} from "../interfaces/IReactor.sol";
import {IValidationCallback} from "../interfaces/IValidationCallback.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

/// @dev generic order information
///  should be included as the first field in any concrete order types
struct OrderInfo {
    // The address of the reactor that this order is targeting
    // Note that this must be included in every order so the swapper
    // signature commits to the specific reactor that they trust to fill their order properly
    IReactor reactor;
    // The address of the user which created the order
    // Note that this must be included so that order hashes are unique by swapper
    address swapper;
    // The nonce of the order, allowing for signature replay protection and cancellation
    uint256 nonce;
    // The timestamp after which this order is no longer valid
    uint256 deadline;
    // Custom validation contract
    IValidationCallback additionalValidationContract;
    // Encoded validation params for additionalValidationContract
    bytes additionalValidationData;
}

/// @dev tokens that need to be sent from the swapper in order to satisfy an order
struct InputToken {
    ERC20 token;
    uint256 amount;
    // Needed for dutch decaying inputs
    uint256 maxAmount;
}

/// @dev tokens that need to be received by the recipient in order to satisfy an order
struct OutputToken {
    address token;
    uint256 amount;
    address recipient;
}

/// @dev generic concrete order that specifies exact tokens which need to be sent and received
struct ResolvedOrder {
    OrderInfo info;
    InputToken input;
    OutputToken[] outputs;
    bytes sig;
    bytes32 hash;
}

/// @dev external struct including a generic encoded order and swapper signature
///  The order bytes will be parsed and mapped to a ResolvedOrder in the concrete reactor contract
struct SignedOrder {
    bytes order;
    bytes sig; /// @dev Permit2 sig.
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ResolvedOrder} from "../base/ReactorStructs.sol";

/// @notice Callback for executing orders through a reactor.
interface IReactorCallback {
    /// @notice Called by the reactor during the execution of an order
    /// @param resolvedOrders Has inputs and outputs
    /// @param callbackData The callbackData specified for an order execution
    /// @dev Must have approved each token and amount in outputs to the msg.sender
    function reactorCallback(ResolvedOrder[] memory resolvedOrders, bytes memory callbackData) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {SignedOrder} from "../base/ReactorStructs.sol";

/// @notice Interface for 'GladiusReactor'.
interface IGladiusReactor {
    /// @notice Execute part of a single order, specified in 'quantity'.
    /// @param order The order definition and valid signature to execute.
    /// @param quantity An amount in a form of input token, to take from the order.
    function execute(
        SignedOrder calldata order,
        uint256 quantity
    ) external payable;

    /// @notice Execute part of a single order using the given callback data.
    /// @param order The order definition and valid signature to execute.
    /// @param quantity An amount in a form of input token, to take from the order.
    /// @param callbackData The 'callbackData' to pass to the callback.
    function executeWithCallback(
        SignedOrder calldata order,
        uint256 quantity,
        bytes calldata callbackData
    ) external payable;

    /// @notice Execute parts of the given orders at once.
    /// @param orders The order definitions and valid signatures to execute.
    /// @param quantities Amounts in a form of input tokens, to take from orders.
    function executeBatch(
        SignedOrder[] calldata orders,
        uint256[] calldata quantities
    ) external payable;

    /// @notice Execute parts of the given orders at once using a callback with the given callback data.
    /// @param orders The order definitions and valid signatures to execute.
    /// @param quantities Amounts in a form of input tokens, to take from orders.
    /// @param callbackData The 'callbackData' to pass to the callback.
    function executeBatchWithCallback(
        SignedOrder[] calldata orders,
        uint256[] calldata quantities,
        bytes calldata callbackData
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ResolvedOrder, SignedOrder} from "../base/ReactorStructs.sol";
import {IReactorCallback} from "./IReactorCallback.sol";

/// @notice Interface for order execution reactors
interface IReactor {
    /// @notice Execute a single order
    /// @param order The order definition and valid signature to execute
    function execute(SignedOrder calldata order) external payable;

    /// @notice Execute a single order using the given callback data
    /// @param order The order definition and valid signature to execute
    function executeWithCallback(SignedOrder calldata order, bytes calldata callbackData) external payable;

    /// @notice Execute the given orders at once
    /// @param orders The order definitions and valid signatures to execute
    function executeBatch(SignedOrder[] calldata orders) external payable;

    /// @notice Execute the given orders at once using a callback with the given callback data
    /// @param orders The order definitions and valid signatures to execute
    /// @param callbackData The callbackData to pass to the callback
    function executeBatchWithCallback(SignedOrder[] calldata orders, bytes calldata callbackData) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {OrderInfo, ResolvedOrder} from "../base/ReactorStructs.sol";

/// @notice Callback to validate an order
interface IValidationCallback {
    /// @notice Called by the reactor for custom validation of an order. Will revert if validation fails
    /// @param filler The filler of the order
    /// @param resolvedOrder The resolved order to fill
    function validate(address filler, ResolvedOrder calldata resolvedOrder) external view;
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