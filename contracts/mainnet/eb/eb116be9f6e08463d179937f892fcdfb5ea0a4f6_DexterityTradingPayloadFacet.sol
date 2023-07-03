// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "../../types/DexterityTrading.sol";
import "../../types/Main.sol";
import "../../storage/payload-assemblers/DexterityTrading.sol";
import "../../storage/core/Core.sol";

/**
 * @title Dexterity Trading Payload Facet
 * @author Ofir Smolinsky @OfirYC
 * @notice The facet responsible for building the eHXRO payloads for trading on Dexterity
 */

contract DexterityTradingPayloadFacet {
    // ================
    //     METHODS
    // ================
    /**
     * Build a deposit payload
     * @param account - The account to build this payload on
     * @param context - DepositFunds accounts for solana "access list"
     * @param amt - Amount to deposit (denominated in LOCAL DECIMALS)
     */
    function buildDepositPayload(
        address account,
        DepositFundsAccounts calldata context,
        uint256 amt
    ) external view returns (InboundPayload memory depositPayload) {
        CoreStorage storage coreStorage = CoreStorageLib.retreive();

        uint256 userNonce = coreStorage.nonces[account];

        address localToken = coreStorage
            .tokens[context.token_program]
            .localAddress;

        if (localToken == address(0)) revert UnsupportedToken();

        uint256 tokenDecimals = IERC20(localToken).decimals();

        bytes memory msgHash = bytes.concat(
            abi.encode(context),
            abi.encode(
                DepositFundsParams({
                    quantity: Fractional({m: amt, exp: tokenDecimals})
                })
            ),
            abi.encode(userNonce)
        );

        depositPayload = InboundPayload(context.token_program, amt, msgHash);
    }

    /**
     * Build a New Order payload
     * @param account - The account to build this payload ontop of
     * @param context - New Order Accounts Context
     * @param newOrderParams - New Order Params
     * @return newOrderPayload - The encoded HXRO payload
     */
    function buildNewOrderMessage(
        address account,
        NewOrderAccounts calldata context,
        NewOrderParams calldata newOrderParams
    ) external view returns (InboundPayload memory newOrderPayload) {
        CoreStorage storage coreStorage = CoreStorageLib.retreive();

        uint256 userNonce = coreStorage.nonces[account];

        bytes memory msgHash = bytes.concat(
            abi.encode(context),
            abi.encode(newOrderParams),
            abi.encode(userNonce)
        );

        newOrderPayload = InboundPayload(bytes32(0), 0, msgHash);
    }

    /**
     * Build a Cancel Order payload
     * @param account - The account to build this payload ontop of
     * @param context - Cancel Order Accounts Context
     * @param cancelOrderParams - Cancel Order Params
     */
    function buildCancelOrderPayload(
        address account,
        CancelOrderAccounts calldata context,
        CancelOrderParams calldata cancelOrderParams
    ) external view returns (InboundPayload memory cancelOrderPayload) {
        CoreStorage storage coreStorage = CoreStorageLib.retreive();

        uint256 userNonce = coreStorage.nonces[account];

        bytes memory msgHash = bytes.concat(
            abi.encode(context),
            abi.encode(cancelOrderParams),
            abi.encode(userNonce)
        );

        cancelOrderPayload = InboundPayload(bytes32(0), 0, msgHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// =================
//      ENUMS
// =================

// The order's side (Bid or Ask)
enum Side {
    BID,
    ASK
}

// The order type (supported types include Limit, FOK, IOC and PostOnly)
enum OrderType {
    LIMIT,
    IMMEDIATE_OR_CANCEL,
    FILL_OR_KILL,
    POST_ONLY
}

// Configures what happens when this order is at least partially matched against an order belonging to the same user account
enum SelfTradeBehavior {
    // The orders are matched together
    DECREMENT_TAKE,
    // The order on the provide side is cancelled. Matching for the current order continues and essentially bypasses
    // the self-provided order.
    CANCEL_PROVIDE,
    // The entire transaction fails and the program returns an error.
    ABORT_TRANSACTION
}

// =================
//     STRUCTS
// =================

// The max quantity of base token to match and post
struct Fractional {
    uint256 m;
    uint256 exp;
}

// Params for a new order
struct NewOrderParams {
    Side side;
    Fractional max_base_qty;
    OrderType order_type;
    SelfTradeBehavior self_trade_behavior;
    uint256 match_limit;
    Fractional limit_price;
}

// Accounts required
struct NewOrderAccounts {
    bytes32 user;
    bytes32 trader_risk_group;
    bytes32 market_product_group;
    bytes32 product;
    bytes32 aaob_program;
    bytes32 orderbook;
    bytes32 market_signer;
    bytes32 event_queue;
    bytes32 bids;
    bytes32 asks;
    bytes32 system_program;
    bytes32 fee_model_program;
    bytes32 fee_model_configuration_acct;
    bytes32 trader_fee_state_acct;
    bytes32 fee_output_register;
    bytes32 risk_engine_program;
    bytes32 risk_model_configuration_acct;
    bytes32 risk_output_register;
    bytes32 trader_risk_state_acct;
    bytes32 risk_and_fee_signer;
}
struct CancelOrderAccounts {
    bytes32 user;
    bytes32 trader_risk_group;
    bytes32 market_product_group;
    bytes32 product;
    bytes32 aaob_program;
    bytes32 orderbook;
    bytes32 market_signer;
    bytes32 event_queue;
    bytes32 bids;
    bytes32 asks;
    bytes32 risk_engine_program;
    bytes32 risk_model_configuration_acct;
    bytes32 risk_output_register;
    bytes32 trader_risk_state_acct;
    bytes32 risk_and_fee_signer;
}

struct CancelOrderParams {
    uint128 order_id;
    bool no_err;
}

struct DepositFundsAccounts {
    bytes32 token_program;
    bytes32 user;
    bytes32 user_token_account;
    bytes32 trader_risk_group;
    bytes32 market_product_group;
    bytes32 market_product_group_vault;
    bytes32 capital_limits;
    bytes32 whitelist_ata_acct;
}

struct DepositFundsParams {
    Fractional quantity;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/interfaces/IERC20.sol";
/**
 * Types for the eHXRO contracts
 */

struct InboundPayload {
    bytes32 solToken;
    uint256 amount;
    bytes messageHash;
}

enum Bridge {
    WORMHOLE,
    MAYAN_SWAP,
    VERY_REAL_BRIDGE
}

struct BridgeResult {
    Bridge id;
    bytes trackableHash;
}

error NotSigOwner();

error UnsupportedToken();

error InvalidNonce();

error BridgeFailed(bytes revertReason);

/**
 * Storage specific to the DexterityTrading payload facet
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct DexterityTradingStorage {
    /**
     * Map user address => nonce
     */
    mapping(address => uint64) nonces;
    /**
     * Identifier of the Dexterity Trading processor on Solana
     */
    bytes8 dexterityProcessorSelector;
}

/**
 * The lib to use to retreive the storage
 */
library DexterityTradingStorageLib {
    // ======================
    //       STORAGE
    // ======================
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256(
            "diamond.hxro.storage.facets.payload_assemblers.dexterity_trading"
        );

    // Function to retreive our storage
    function retreive()
        internal
        pure
        returns (DexterityTradingStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function _getAndIncrementNonce(
        address user
    ) internal returns (uint256 oldNonce) {
        DexterityTradingStorage storage dexterityStorage = retreive();
        oldNonce = dexterityStorage.nonces[user];
        dexterityStorage.nonces[user]++;
    }
}

/**
 * Storage specific to the execution facet
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IERC20} from "src/interfaces/IERC20.sol";
import {ITokenBridge, IPayloadBridge} from "src/interfaces/IBridgeProvider.sol";
import {IDataProvider} from "src/interfaces/IDataProvider.sol";

// Token data
struct Token {
    bytes32 solAddress;
    address localAddress;
    ITokenBridge bridgeProvider;
    
}

struct CoreStorage {
    /**
     * Address of the solana eHXRO program
     */
    bytes32 solanaProgram;
    /**
     * All supported tokens
     */
    bytes32[] allSupportedTokens;
    /**
     * Mapping supported tokens (SOL Address) => Token data
     */
    mapping(bytes32 supportedToken => Token tokenData) tokens;
    /**
     * The address of the bridge provider for bridging plain payload
     */
    IPayloadBridge plainBridgeProvider;
    /**
     * Map user address => nonce
     */
    mapping(address => uint256) nonces;
    /**
     * Chainlink oracle address
     */
    IDataProvider dataProvider;
}

/**
 * The lib to use to retreive the storage
 */
library CoreStorageLib {
    // ======================
    //       STORAGE
    // ======================
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.hxro.storage.core.execution");

    // Function to retreive our storage
    function retreive() internal pure returns (CoreStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
}

/**
 * Interface for a bridge provider
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/diamond/types/Main.sol";
import "./IERC20.sol";

interface ITokenBridge {
    function bridgeHxroPayloadWithTokens(
        bytes32 destToken,
        uint256 amount,
        address msgSender,
        bytes calldata hxroPayload
    ) external returns (BridgeResult memory);
}

interface IPayloadBridge {
    function bridgeHXROPayload(
        bytes calldata hxroPayload,
        address msgSender
    ) external returns (BridgeResult memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * Interface for a data provider adapters
 */
interface IDataProvider {
    function quoteSOLToETH(
        uint256 solAmount
    ) external view returns (uint256 ethAmount);

    function quoteSOLToToken(
        address pairToken,
        uint256 solAmount
    ) external view returns (uint256 tokenAmount);

    function quoteETHToToken(
        address pairToken,
        uint256 ethAmount
    ) external view returns (uint256 tokenAmount);
}