// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { BridgeValidator } from "src/crosschain-liquidity/BridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";
import { DeBridgeError } from "src/crosschain-liquidity/debridge/libraries/DeBridgeError.sol";
import { IDlnSource } from "src/vendor/deBridge/IDlnSource.sol";
import { DlnOrderLib } from "src/vendor/deBridge/DlnOrderLib.sol";
import { ICrossChainForwarder } from "src/vendor/deBridge/ICrossChainForwarder.sol";

/// @title DeBridgeForwarderValidator
/// @dev Asserts if De-Bridge swap + bridge input txData is valid
/// @author Zeropoint Labs
contract DeBridgeForwarderValidator is BridgeValidator {
    //////////////////////////////////////////////////////////////
    //                       CONSTANTS                          //
    //////////////////////////////////////////////////////////////
    address private constant DE_BRIDGE_SOURCE = 0xeF4fB24aD0916217251F553c0596F8Edc630EB66;
    ICrossChainForwarder private constant DE_BRIDGE_FORWARDER =
        ICrossChainForwarder(0x663DC15D3C1aC63ff12E45Ab68FeA3F0a883C251);

    //////////////////////////////////////////////////////////////
    //                       STRUCTS                            //
    //////////////////////////////////////////////////////////////

    struct DecodedQuote {
        /// swap input token
        address inputToken;
        /// swap input amount
        uint256 inputAmount;
        /// final bridging dst chain id
        uint256 dstChainId;
        /// final take token (after swap + bridge)
        address outputToken;
        /// final take token amount
        uint256 outputAmount;
        /// excess swap output receiver
        address swapRefundRecipient;
        /// bridge cancel beneficiary
        address bridgeRefundRecipient;
        /// final take token receiver on dst chain
        address finalReceiver;
        address givePatchAuthoritySrc;
        address orderAuthorityAddressDst;
    }
    /// order authority for bridge on dst chain

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) BridgeValidator(superRegistry_) { }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc BridgeValidator
    function validateReceiver(bytes calldata txData_, address receiver) external view override returns (bool) {
        DecodedQuote memory deBridgeQuote = _decodeTxData(txData_);

        return (receiver == deBridgeQuote.finalReceiver);
    }

    /// @inheritdoc BridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_) external view override returns (bool hasDstSwap) {
        DecodedQuote memory deBridgeQuote = _decodeTxData(args_.txData);

        /// @dev mandates the refund receiver to be args_.receiver
        if (
            deBridgeQuote.bridgeRefundRecipient != args_.receiverAddress
                || deBridgeQuote.swapRefundRecipient != args_.receiverAddress
        ) {
            revert DeBridgeError.INVALID_REFUND_ADDRESS();
        }

        /// @dev mandates the give patch authority src to be args_.receiver
        if (deBridgeQuote.givePatchAuthoritySrc != args_.receiverAddress) {
            revert DeBridgeError.INVALID_PATCH_ADDRESS();
        }

        if (
            superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY_RESCUER_ROLE"), args_.dstChainId)
                != deBridgeQuote.orderAuthorityAddressDst
        ) revert DeBridgeError.INVALID_DEBRIDGE_AUTHORITY();

        /// @dev 1. chain id validation
        if (uint64(deBridgeQuote.dstChainId) != args_.liqDstChainId || args_.liqDataToken != deBridgeQuote.inputToken) {
            revert Error.INVALID_TXDATA_CHAIN_ID();
        }

        /// @dev 2. receiver address validation
        /// @dev allows dst swaps by coupling debridge with other bridges
        if (args_.deposit) {
            if (args_.srcChainId == args_.dstChainId) {
                revert Error.INVALID_ACTION();
            }

            hasDstSwap = deBridgeQuote.finalReceiver
                == superRegistry.getAddressByChainId(keccak256("DST_SWAPPER"), args_.dstChainId);

            /// @dev if cross chain deposits, then receiver address must be CoreStateRegistry (or) Dst Swapper
            if (
                !(
                    deBridgeQuote.finalReceiver
                        == superRegistry.getAddressByChainId(keccak256("CORE_STATE_REGISTRY"), args_.dstChainId)
                        || hasDstSwap
                )
            ) {
                revert Error.INVALID_TXDATA_RECEIVER();
            }

            /// @dev if there is a dst swap then the interim token should be the quote of debridge
            if (hasDstSwap && (args_.liqDataInterimToken != deBridgeQuote.outputToken)) {
                revert Error.INVALID_INTERIM_TOKEN();
            }
        } else {
            /// @dev if withdrawal, then receiver address must be the receiverAddress
            if (deBridgeQuote.finalReceiver != args_.receiverAddress) revert Error.INVALID_TXDATA_RECEIVER();
        }
    }

    /// @inheritdoc BridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool /*genericSwapDisallowed_*/
    )
        external
        view
        override
        returns (uint256 amount_)
    {
        DecodedQuote memory deBridgeQuote = _decodeTxData(txData_);
        amount_ = deBridgeQuote.inputAmount;
    }

    /// @inheritdoc BridgeValidator
    function decodeDstSwap(bytes calldata /*txData_*/ )
        external
        pure
        override
        returns (address, /*token_*/ uint256 /*amount_*/ )
    {
        /// @dev debridge cannot be used for just swaps
        revert DeBridgeError.ONLY_SWAPS_DISALLOWED();
    }

    /// @inheritdoc BridgeValidator
    function decodeSwapOutputToken(bytes calldata /*txData_*/ ) external pure override returns (address /*token_*/ ) {
        /// @dev debridge cannot be used for same chain swaps
        revert DeBridgeError.ONLY_SWAPS_DISALLOWED();
    }

    //////////////////////////////////////////////////////////////
    //                  INTERNAL FUNCTIONS                      //
    //////////////////////////////////////////////////////////////

    struct InternalVars {
        bytes4 selector;
        address swapOutputToken;
        address swapRouter;
        bytes swapPermitEnvelope;
        address bridgeTarget;
        bytes bridgeTxData;
        bytes permitEnvelope;
        DlnOrderLib.OrderCreation xChainQuote;
    }

    /// @notice supports `strictlySwapAndCall` function for swapping using forwarder
    function _decodeTxData(bytes calldata txData_) internal view returns (DecodedQuote memory deBridgeQuote) {
        InternalVars memory v;

        /// @dev supports both the allowed order types by debridge
        v.selector = bytes4(txData_[:4]);

        if (v.selector == ICrossChainForwarder.strictlySwapAndCall.selector) {
            /// @decode the input txdata
            (
                deBridgeQuote.inputToken,
                deBridgeQuote.inputAmount,
                v.swapPermitEnvelope,
                v.swapRouter,
                ,
                v.swapOutputToken,
                ,
                deBridgeQuote.swapRefundRecipient,
                v.bridgeTarget,
                v.bridgeTxData
            ) = abi.decode(
                parseCallData(txData_),
                (address, uint256, bytes, address, bytes, address, uint256, address, address, bytes)
            );
        } else {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        /// swap permit envelope should be empty
        if (v.swapPermitEnvelope.length > 0) {
            revert DeBridgeError.INVALID_SWAP_PERMIT_ENVELOP();
        }

        /// defensive check to protect against unknown swap routers
        /// this check is also made in the debridge forwarder contract
        if (!DE_BRIDGE_FORWARDER.supportedRouters(v.swapRouter)) {
            revert DeBridgeError.INVALID_SWAP_ROUTER();
        }

        /// bridge tx data shouldn't be empty
        if (v.bridgeTxData.length == 0 || v.bridgeTarget != DE_BRIDGE_SOURCE) {
            revert DeBridgeError.INVALID_BRIDGE_DATA();
        }

        _decodeBridgeData(v, deBridgeQuote);
    }

    /// @notice supports `createOrder` and `createSaltedOrder` for bridging using dln source
    function _decodeBridgeData(InternalVars memory v, DecodedQuote memory deBridgeQuote) internal view {
        /// now decoding the bridge data
        v.selector = _parseSelectorMem(v.bridgeTxData);

        if (v.selector == IDlnSource.createOrder.selector) {
            (v.xChainQuote,,, v.permitEnvelope) =
                abi.decode(this.parseCallData(v.bridgeTxData), (DlnOrderLib.OrderCreation, bytes, uint32, bytes));
        } else if (v.selector == IDlnSource.createSaltedOrder.selector) {
            (v.xChainQuote,,,, v.permitEnvelope,) = abi.decode(
                this.parseCallData(v.bridgeTxData), (DlnOrderLib.OrderCreation, uint64, bytes, uint32, bytes, bytes)
            );
        } else {
            revert Error.BLACKLISTED_ROUTE_ID();
        }

        if (v.swapOutputToken != v.xChainQuote.giveTokenAddress) {
            revert DeBridgeError.INVALID_BRIDGE_TOKEN();
        }

        if (v.permitEnvelope.length > 0) {
            revert DeBridgeError.INVALID_PERMIT_ENVELOP();
        }

        if (v.xChainQuote.externalCall.length > 0) {
            revert DeBridgeError.INVALID_EXTRA_CALL_DATA();
        }

        if (v.xChainQuote.allowedTakerDst.length > 0) {
            revert DeBridgeError.INVALID_TAKER_DST();
        }

        deBridgeQuote.outputToken = _castToAddress(v.xChainQuote.takeTokenAddress);
        deBridgeQuote.outputAmount = v.xChainQuote.takeAmount;
        deBridgeQuote.finalReceiver = _castToAddress(v.xChainQuote.receiverDst);
        deBridgeQuote.dstChainId = v.xChainQuote.takeChainId;
        deBridgeQuote.orderAuthorityAddressDst = _castToAddress(v.xChainQuote.orderAuthorityAddressDst);
        deBridgeQuote.bridgeRefundRecipient = _castToAddress(v.xChainQuote.allowedCancelBeneficiarySrc);
        deBridgeQuote.givePatchAuthoritySrc = v.xChainQuote.givePatchAuthoritySrc;

        if (deBridgeQuote.outputToken == address(0)) deBridgeQuote.outputToken = NATIVE;
        if (deBridgeQuote.inputToken == address(0)) deBridgeQuote.inputToken = NATIVE;
    }

    /// @dev helps parsing debridge calldata and return the input parameters
    function parseCallData(bytes calldata callData) public pure returns (bytes calldata) {
        return callData[4:];
    }

    /// @dev helps parse bytes memory selector
    function _parseSelectorMem(bytes memory data) internal pure returns (bytes4 selector) {
        assembly {
            selector := mload(add(data, 0x20))
        }
    }

    /// @dev helps cast bytes to address
    function _castToAddress(bytes memory address_) internal pure returns (address) {
        return address(uint160(bytes20(address_)));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

import { ISuperRegistry } from "src/interfaces/ISuperRegistry.sol";
import { IBridgeValidator } from "src/interfaces/IBridgeValidator.sol";
import { Error } from "src/libraries/Error.sol";

/// @title BridgeValidator
/// @dev Inherited by specific bridge handlers to verify the calldata being sent
/// @author Zeropoint Labs
abstract contract BridgeValidator is IBridgeValidator {
    //////////////////////////////////////////////////////////////
    //                         CONSTANTS                        //
    //////////////////////////////////////////////////////////////

    ISuperRegistry public immutable superRegistry;
    address constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //////////////////////////////////////////////////////////////
    //                      CONSTRUCTOR                         //
    //////////////////////////////////////////////////////////////

    constructor(address superRegistry_) {
        if (superRegistry_ == address(0)) {
            revert Error.ZERO_ADDRESS();
        }
        superRegistry = ISuperRegistry(superRegistry_);
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @inheritdoc IBridgeValidator
    function validateReceiver(
        bytes calldata txData_,
        address receiver_
    )
        external
        view
        virtual
        override
        returns (bool valid_);

    /// @inheritdoc IBridgeValidator
    function validateTxData(ValidateTxDataArgs calldata args_)
        external
        view
        virtual
        override
        returns (bool hasDstSwap);

    /// @inheritdoc IBridgeValidator
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        virtual
        override
        returns (uint256 amount_);

    /// @inheritdoc IBridgeValidator
    function decodeDstSwap(bytes calldata txData_)
        external
        pure
        virtual
        override
        returns (address token_, uint256 amount_);

    /// @inheritdoc IBridgeValidator
    function decodeSwapOutputToken(bytes calldata txData_)
        external
        pure
        virtual
        override
        returns (address outputToken_);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library Error {
    //////////////////////////////////////////////////////////////
    //                  CONFIGURATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown in protocol setup

    /// @dev thrown if chain id exceeds max(uint64)
    error BLOCK_CHAIN_ID_OUT_OF_BOUNDS();

    /// @dev thrown if not possible to revoke a role in broadcasting
    error CANNOT_REVOKE_NON_BROADCASTABLE_ROLES();

    /// @dev thrown if not possible to revoke last admin
    error CANNOT_REVOKE_LAST_ADMIN();

    /// @dev thrown if trying to set again pseudo immutables in super registry
    error DISABLED();

    /// @dev thrown if rescue delay is not yet set for a chain
    error DELAY_NOT_SET();

    /// @dev thrown if get native token price estimate in paymentHelper is 0
    error INVALID_NATIVE_TOKEN_PRICE();

    /// @dev thrown if wormhole refund chain id is not set
    error REFUND_CHAIN_ID_NOT_SET();

    /// @dev thrown if wormhole relayer is not set
    error RELAYER_NOT_SET();

    /// @dev thrown if a role to be revoked is not assigned
    error ROLE_NOT_ASSIGNED();

    //////////////////////////////////////////////////////////////
    //                  AUTHORIZATION ERRORS                    //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if functions cannot be called

    /// COMMON AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if caller is not address(this), internal call
    error INVALID_INTERNAL_CALL();

    /// @dev thrown if msg.sender is not a valid amb implementation
    error NOT_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not an allowed broadcaster
    error NOT_ALLOWED_BROADCASTER();

    /// @dev thrown if msg.sender is not broadcast amb implementation
    error NOT_BROADCAST_AMB_IMPLEMENTATION();

    /// @dev thrown if msg.sender is not broadcast state registry
    error NOT_BROADCAST_REGISTRY();

    /// @dev thrown if msg.sender is not core state registry
    error NOT_CORE_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not emergency admin
    error NOT_EMERGENCY_ADMIN();

    /// @dev thrown if msg.sender is not emergency queue
    error NOT_EMERGENCY_QUEUE();

    /// @dev thrown if msg.sender is not minter
    error NOT_MINTER();

    /// @dev thrown if msg.sender is not minter state registry
    error NOT_MINTER_STATE_REGISTRY_ROLE();

    /// @dev thrown if msg.sender is not paymaster
    error NOT_PAYMASTER();

    /// @dev thrown if msg.sender is not payment admin
    error NOT_PAYMENT_ADMIN();

    /// @dev thrown if msg.sender is not protocol admin
    error NOT_PROTOCOL_ADMIN();

    /// @dev thrown if msg.sender is not state registry
    error NOT_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not super registry
    error NOT_SUPER_REGISTRY();

    /// @dev thrown if msg.sender is not superform router
    error NOT_SUPERFORM_ROUTER();

    /// @dev thrown if msg.sender is not a superform
    error NOT_SUPERFORM();

    /// @dev thrown if msg.sender is not superform factory
    error NOT_SUPERFORM_FACTORY();

    /// @dev thrown if msg.sender is not timelock form
    error NOT_TIMELOCK_SUPERFORM();

    /// @dev thrown if msg.sender is not timelock state registry
    error NOT_TIMELOCK_STATE_REGISTRY();

    /// @dev thrown if msg.sender is not user or disputer
    error NOT_VALID_DISPUTER();

    /// @dev thrown if the msg.sender is not privileged caller
    error NOT_PRIVILEGED_CALLER(bytes32 role);

    /// STATE REGISTRY AUTHORIZATION ERRORS
    /// ---------------------------------------------------------

    /// @dev layerzero adapter specific error, thrown if caller not layerzero endpoint
    error CALLER_NOT_ENDPOINT();

    /// @dev hyperlane adapter specific error, thrown if caller not hyperlane mailbox
    error CALLER_NOT_MAILBOX();

    /// @dev wormhole relayer specific error, thrown if caller not wormhole relayer
    error CALLER_NOT_RELAYER();

    /// @dev thrown if src chain sender is not valid
    error INVALID_SRC_SENDER();

    //////////////////////////////////////////////////////////////
    //                  INPUT VALIDATION ERRORS                 //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown if input variables are not valid

    /// COMMON INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if there is an array length mismatch
    error ARRAY_LENGTH_MISMATCH();

    /// @dev thrown if payload id does not exist
    error INVALID_PAYLOAD_ID();

    /// @dev error thrown when msg value should be zero in certain payable functions
    error MSG_VALUE_NOT_ZERO();

    /// @dev thrown if amb ids length is 0
    error ZERO_AMB_ID_LENGTH();

    /// @dev thrown if address input is address 0
    error ZERO_ADDRESS();

    /// @dev thrown if amount input is 0
    error ZERO_AMOUNT();

    /// @dev thrown if final token is address 0
    error ZERO_FINAL_TOKEN();

    /// @dev thrown if value input is 0
    error ZERO_INPUT_VALUE();

    /// SUPERFORM ROUTER INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the vaults data is invalid
    error INVALID_SUPERFORMS_DATA();

    /// @dev thrown if receiver address is not set
    error RECEIVER_ADDRESS_NOT_SET();

    /// SUPERFORM FACTORY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if a form is not ERC165 compatible
    error ERC165_UNSUPPORTED();

    /// @dev thrown if a form is not form interface compatible
    error FORM_INTERFACE_UNSUPPORTED();

    /// @dev error thrown if form implementation address already exists
    error FORM_IMPLEMENTATION_ALREADY_EXISTS();

    /// @dev error thrown if form implementation id already exists
    error FORM_IMPLEMENTATION_ID_ALREADY_EXISTS();

    /// @dev thrown if a form does not exist
    error FORM_DOES_NOT_EXIST();

    /// @dev thrown if form id is larger than max uint16
    error INVALID_FORM_ID();

    /// @dev thrown if superform not on factory
    error SUPERFORM_ID_NONEXISTENT();

    /// @dev thrown if same vault and form implementation is used to create new superform
    error VAULT_FORM_IMPLEMENTATION_COMBINATION_EXISTS();

    /// FORM INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if in case of no txData, if liqData.token != vault.asset()
    /// in case of txData, if token output of swap != vault.asset()
    error DIFFERENT_TOKENS();

    /// @dev thrown if the amount in direct withdraw is not correct
    error DIRECT_WITHDRAW_INVALID_LIQ_REQUEST();

    /// @dev thrown if the amount in xchain withdraw is not correct
    error XCHAIN_WITHDRAW_INVALID_LIQ_REQUEST();

    /// LIQUIDITY BRIDGE INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if route id is blacklisted in socket
    error BLACKLISTED_ROUTE_ID();

    /// @dev thrown if route id is not blacklisted in socket
    error NOT_BLACKLISTED_ROUTE_ID();

    /// @dev error thrown when txData selector of lifi bridge is a blacklisted selector
    error BLACKLISTED_SELECTOR();

    /// @dev error thrown when txData selector of lifi bridge is not a blacklisted selector
    error NOT_BLACKLISTED_SELECTOR();

    /// @dev thrown if a certain action of the user is not allowed given the txData provided
    error INVALID_ACTION();

    /// @dev thrown if in deposits, the liqDstChainId doesn't match the stateReq dstChainId
    error INVALID_DEPOSIT_LIQ_DST_CHAIN_ID();

    /// @dev thrown if index is invalid
    error INVALID_INDEX();

    /// @dev thrown if the chain id in the txdata is invalid
    error INVALID_TXDATA_CHAIN_ID();

    /// @dev thrown if the validation of bridge txData fails due to a destination call present
    error INVALID_TXDATA_NO_DESTINATIONCALL_ALLOWED();

    /// @dev thrown if the validation of bridge txData fails due to wrong receiver
    error INVALID_TXDATA_RECEIVER();

    /// @dev thrown if the validation of bridge txData fails due to wrong token
    error INVALID_TXDATA_TOKEN();

    /// @dev thrown if txData is not present (in case of xChain actions)
    error NO_TXDATA_PRESENT();

    /// STATE REGISTRY INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if payload is being updated with final amounts length different than amounts length
    error DIFFERENT_PAYLOAD_UPDATE_AMOUNTS_LENGTH();

    /// @dev thrown if payload is being updated with tx data length different than liq data length
    error DIFFERENT_PAYLOAD_UPDATE_TX_DATA_LENGTH();

    /// @dev thrown if keeper update final token is different than the vault underlying
    error INVALID_UPDATE_FINAL_TOKEN();

    /// @dev thrown if broadcast finality for wormhole is invalid
    error INVALID_BROADCAST_FINALITY();

    /// @dev thrown if amb id is not valid leading to an address 0 of the implementation
    error INVALID_BRIDGE_ID();

    /// @dev thrown if chain id involved in xchain message is invalid
    error INVALID_CHAIN_ID();

    /// @dev thrown if payload update amount isn't equal to dst swapper amount
    error INVALID_DST_SWAP_AMOUNT();

    /// @dev thrown if message amb and proof amb are the same
    error INVALID_PROOF_BRIDGE_ID();

    /// @dev thrown if order of proof AMBs is incorrect, either duplicated or not incrementing
    error INVALID_PROOF_BRIDGE_IDS();

    /// @dev thrown if rescue data lengths are invalid
    error INVALID_RESCUE_DATA();

    /// @dev thrown if delay is invalid
    error INVALID_TIMELOCK_DELAY();

    /// @dev thrown if amounts being sent in update payload mean a negative slippage
    error NEGATIVE_SLIPPAGE();

    /// @dev thrown if slippage is outside of bounds
    error SLIPPAGE_OUT_OF_BOUNDS();

    /// SUPERPOSITION INPUT VALIDATION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if src senders mismatch in state sync
    error SRC_SENDER_MISMATCH();

    /// @dev thrown if src tx types mismatch in state sync
    error SRC_TX_TYPE_MISMATCH();

    //////////////////////////////////////////////////////////////
    //                  EXECUTION ERRORS                        //
    //////////////////////////////////////////////////////////////
    ///@notice errors thrown due to function execution logic

    /// COMMON EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if the swap in a direct deposit resulted in insufficient tokens
    error DIRECT_DEPOSIT_SWAP_FAILED();

    /// @dev thrown if payload is not unique
    error DUPLICATE_PAYLOAD();

    /// @dev thrown if native tokens fail to be sent to superform contracts
    error FAILED_TO_SEND_NATIVE();

    /// @dev thrown if allowance is not correct to deposit
    error INSUFFICIENT_ALLOWANCE_FOR_DEPOSIT();

    /// @dev thrown if contract has insufficient balance for operations
    error INSUFFICIENT_BALANCE();

    /// @dev thrown if native amount is not at least equal to the amount in the request
    error INSUFFICIENT_NATIVE_AMOUNT();

    /// @dev thrown if payload cannot be decoded
    error INVALID_PAYLOAD();

    /// @dev thrown if payload status is invalid
    error INVALID_PAYLOAD_STATUS();

    /// @dev thrown if payload type is invalid
    error INVALID_PAYLOAD_TYPE();

    /// LIQUIDITY BRIDGE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if we try to decode the final swap output token in a xChain liquidity bridging action
    error CANNOT_DECODE_FINAL_SWAP_OUTPUT_TOKEN();

    /// @dev thrown if liquidity bridge fails for erc20 or native tokens
    error FAILED_TO_EXECUTE_TXDATA(address token);

    /// @dev thrown if asset being used for deposit mismatches in multivault deposits
    error INVALID_DEPOSIT_TOKEN();

    /// STATE REGISTRY EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if bridge tokens haven't arrived to destination
    error BRIDGE_TOKENS_PENDING();

    /// @dev thrown if withdrawal tx data cannot be updated
    error CANNOT_UPDATE_WITHDRAW_TX_DATA();

    /// @dev thrown if rescue passed dispute deadline
    error DISPUTE_TIME_ELAPSED();

    /// @dev thrown if message failed to reach the specified level of quorum needed
    error INSUFFICIENT_QUORUM();

    /// @dev thrown if broadcast payload is invalid
    error INVALID_BROADCAST_PAYLOAD();

    /// @dev thrown if broadcast fee is invalid
    error INVALID_BROADCAST_FEE();

    /// @dev thrown if retry fees is less than required
    error INVALID_RETRY_FEE();

    /// @dev thrown if broadcast message type is wrong
    error INVALID_MESSAGE_TYPE();

    /// @dev thrown if payload hash is invalid during `retryMessage` on Layezero implementation
    error INVALID_PAYLOAD_HASH();

    /// @dev thrown if update payload function was called on a wrong payload
    error INVALID_PAYLOAD_UPDATE_REQUEST();

    /// @dev thrown if a state registry id is 0
    error INVALID_REGISTRY_ID();

    /// @dev thrown if a form state registry id is 0
    error INVALID_FORM_REGISTRY_ID();

    /// @dev thrown if trying to finalize the payload but the withdraw is still locked
    error LOCKED();

    /// @dev thrown if payload is already updated (during xChain deposits)
    error PAYLOAD_ALREADY_UPDATED();

    /// @dev thrown if payload is already processed
    error PAYLOAD_ALREADY_PROCESSED();

    /// @dev thrown if payload is not in UPDATED state
    error PAYLOAD_NOT_UPDATED();

    /// @dev thrown if rescue is still in timelocked state
    error RESCUE_LOCKED();

    /// @dev thrown if rescue is already proposed
    error RESCUE_ALREADY_PROPOSED();

    /// @dev thrown if payload hash is zero during `retryMessage` on Layezero implementation
    error ZERO_PAYLOAD_HASH();

    /// DST SWAPPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if process dst swap is tried for processed payload id
    error DST_SWAP_ALREADY_PROCESSED();

    /// @dev thrown if indices have duplicates
    error DUPLICATE_INDEX();

    /// @dev thrown if failed dst swap is already updated
    error FAILED_DST_SWAP_ALREADY_UPDATED();

    /// @dev thrown if indices are out of bounds
    error INDEX_OUT_OF_BOUNDS();

    /// @dev thrown if failed swap token amount is 0
    error INVALID_DST_SWAPPER_FAILED_SWAP();

    /// @dev thrown if failed swap token amount is not 0 and if token balance is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_TOKEN_BALANCE();

    /// @dev thrown if failed swap token amount is not 0 and if native amount is less than amount (non zero)
    error INVALID_DST_SWAPPER_FAILED_SWAP_NO_NATIVE_BALANCE();

    /// @dev forbid xChain deposits with destination swaps without interim token set (for user protection)
    error INVALID_INTERIM_TOKEN();

    /// @dev thrown if dst swap output is less than minimum expected
    error INVALID_SWAP_OUTPUT();

    /// FORM EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if try to forward 4626 share from the superform
    error CANNOT_FORWARD_4646_TOKEN();

    /// @dev thrown in KYCDAO form if no KYC token is present
    error NO_VALID_KYC_TOKEN();

    /// @dev thrown in forms where a certain functionality is not allowed or implemented
    error NOT_IMPLEMENTED();

    /// @dev thrown if form implementation is PAUSED, users cannot perform any action
    error PAUSED();

    /// @dev thrown if shares != deposit output or assets != redeem output when minting SuperPositions
    error VAULT_IMPLEMENTATION_FAILED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TOKEN_NOT_UPDATED();

    /// @dev thrown if withdrawal tx data is not updated
    error WITHDRAW_TX_DATA_NOT_UPDATED();

    /// @dev thrown when redeeming from vault yields zero collateral
    error WITHDRAW_ZERO_COLLATERAL();

    /// PAYMENT HELPER EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if chainlink is reporting an improper price
    error CHAINLINK_MALFUNCTION();

    /// @dev thrown if chainlink is reporting an incomplete round
    error CHAINLINK_INCOMPLETE_ROUND();

    /// @dev thrown if feed decimals is not 8
    error CHAINLINK_UNSUPPORTED_DECIMAL();

    /// EMERGENCY QUEUE EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if emergency withdraw is not queued
    error EMERGENCY_WITHDRAW_NOT_QUEUED();

    /// @dev thrown if emergency withdraw is already processed
    error EMERGENCY_WITHDRAW_PROCESSED_ALREADY();

    /// SUPERPOSITION EXECUTION ERRORS
    /// ---------------------------------------------------------

    /// @dev thrown if uri cannot be updated
    error DYNAMIC_URI_FROZEN();

    /// @dev thrown if tx history is not found while state sync
    error TX_HISTORY_NOT_FOUND();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

library DeBridgeError {
    /// @dev if permit envelop length is greater than zero
    error INVALID_PERMIT_ENVELOP();

    /// @dev if dst authority address is not CORE_STATE_REGISTRY_RESCUER_ROLE
    /// only the CORE_STATE_REGISTRY_RESCUER_ROLE is allowed to cancel a debridge order on destination chain
    error INVALID_DEBRIDGE_AUTHORITY();

    /// @dev if external call is allowed
    error INVALID_EXTRA_CALL_DATA();

    /// @dev if bridge data is invalid
    error INVALID_BRIDGE_DATA();

    /// @dev if swap token and bridge token mismatch
    error INVALID_BRIDGE_TOKEN();

    /// @dev debridge don't allow same chain swaps
    error ONLY_SWAPS_DISALLOWED();

    /// @dev if dst taker is restricted
    error INVALID_TAKER_DST();

    /// @dev if cancel beneficiary is invalid
    error INVALID_REFUND_ADDRESS();

    /// @dev if swap permit envelope is  invalid
    error INVALID_SWAP_PERMIT_ENVELOP();

    /// @dev if the patch authority is not valid
    error INVALID_PATCH_ADDRESS();

    /// @dev if the swap router is invalid
    error INVALID_SWAP_ROUTER();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./DlnOrderLib.sol";

interface IDlnSource {
    /**
     * @notice This function returns the global fixed fee in the native asset of the protocol.
     * @dev This fee is denominated in the native asset (like Ether in Ethereum).
     * @return uint88 This return value represents the global fixed fee in the native asset.
     */
    function globalFixedNativeFee() external returns (uint88);

    /**
     * @notice This function provides the global transfer fee, expressed in Basis Points (BPS).
     * @dev It retrieves a global fee which is applied to order.giveAmount. The fee is represented in Basis Points
     * (BPS), where 1 BPS equals 0.01%.
     * @return uint16 The return value represents the global transfer fee in BPS.
     */
    function globalTransferFeeBps() external returns (uint16);

    /**
     * @dev Places a new order with pseudo-random orderId onto the DLN
     * @notice deprecated
     * @param _orderCreation a structured parameter from the DlnOrderLib.OrderCreation library, containing all the
     * necessary information required for creating a new order.
     * @param _affiliateFee a bytes parameter specifying the affiliate fee that will be rewarded to the beneficiary. It
     * includes the beneficiary's details and the affiliate amount.
     * @param _referralCode a 32-bit unsigned integer containing the referral code. This code is traced back to the
     * referral source or person that facilitated this order. This code is also emitted in an event for tracking
     * purposes.
     * @param _permitEnvelope a bytes parameter that is used to approve the spender through a signature. It contains the
     * amount, the deadline, and the signature.
     * @return bytes32 identifier (orderId) of a newly placed order
     */
    function createOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope
    )
        external
        payable
        returns (bytes32);

    /**
     * @dev Places a new order with deterministic orderId onto the DLN
     * @param _orderCreation a structured parameter from the DlnOrderLib.OrderCreation library, containing all the
     * necessary information required for creating a new order.
     * @param _salt an input source of randomness for getting a deterministic identifier of an order (orderId)
     * @param _affiliateFee a bytes parameter specifying the affiliate fee that will be rewarded to the beneficiary. It
     * includes the beneficiary's details and the affiliate amount.
     * @param _referralCode a 32-bit unsigned integer containing the referral code. This code is traced back to the
     * referral source or person that facilitated this order. This code is also emitted in an event for tracking
     * purposes.
     * @param _permitEnvelope a bytes parameter that is used to approve the spender through a signature. It contains the
     * amount, the deadline, and the signature.
     * @param _metadata an arbitrary data to be tied together with the order for future off-chain analysis
     * @return bytes32 identifier (orderId) of a newly placed order
     */
    function createSaltedOrder(
        DlnOrderLib.OrderCreation calldata _orderCreation,
        uint64 _salt,
        bytes calldata _affiliateFee,
        uint32 _referralCode,
        bytes calldata _permitEnvelope,
        bytes calldata _metadata
    )
        external
        payable
        returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library DlnOrderLib {
    /* ========== ENUMS ========== */

    /**
     * @dev Enum defining the supported blockchain engines.
     * - `UNDEFINED`: Represents an undefined or unknown blockchain engine (0).
     * - `EVM`: Represents the Ethereum Virtual Machine (EVM) blockchain engine (1).
     * - `SOLANA`: Represents the Solana blockchain engine (2).
     */
    enum ChainEngine {
        UNDEFINED, // 0
        EVM, // 1
        SOLANA // 2

    }

    /* ========== STRUCTS ========== */

    /// @dev Struct representing the creation parameters for creating an order on the (EVM) chain.
    struct OrderCreation {
        /// Address of the ERC-20 token that the maker is offering as part of this order.
        /// Use the zero address to indicate that the maker is offering a native blockchain token (such as Ether, Matic,
        /// etc.).
        address giveTokenAddress;
        /// Amount of tokens the maker is offering.
        uint256 giveAmount;
        /// Address of the ERC-20 token that the maker is willing to accept on the destination chain.
        bytes takeTokenAddress;
        /// Amount of tokens the maker is willing to accept on the destination chain.
        uint256 takeAmount;
        // the ID of the chain where an order should be fulfilled.
        uint256 takeChainId;
        /// Address on the destination chain where funds should be sent upon order fulfillment.
        bytes receiverDst;
        /// Address on the source (current) chain authorized to patch the order by adding more input tokens, making it
        /// more attractive to takers.
        address givePatchAuthoritySrc;
        /// Address on the destination chain authorized to patch the order by reducing the take amount, making it more
        /// attractive to takers,
        /// and can also cancel the order in the take chain.
        bytes orderAuthorityAddressDst;
        // An optional address restricting anyone in the open market from fulfilling
        // this order but the given address. This can be useful if you are creating a order
        // for a specific taker. By default, set to empty bytes array (0x)
        bytes allowedTakerDst;
        /// An optional external call data payload.
        bytes externalCall;
        // An optional address on the source (current) chain where the given input tokens
        // would be transferred to in case order cancellation is initiated by the orderAuthorityAddressDst
        // on the destination chain. This property can be safely set to an empty bytes array (0x):
        // in this case, tokens would be transferred to the arbitrary address specified
        // by the orderAuthorityAddressDst upon order cancellation
        bytes allowedCancelBeneficiarySrc;
    }

    /// @dev  Struct representing an order.
    struct Order {
        /// Nonce for each maker.
        uint64 makerOrderNonce;
        /// Order maker address (EOA signer for EVM) in the source chain.
        bytes makerSrc;
        /// Chain ID where the order's was created.
        uint256 giveChainId;
        /// Address of the ERC-20 token that the maker is offering as part of this order.
        /// Use the zero address to indicate that the maker is offering a native blockchain token (such as Ether, Matic,
        /// etc.).
        bytes giveTokenAddress;
        /// Amount of tokens the maker is offering.
        uint256 giveAmount;
        // the ID of the chain where an order should be fulfilled.
        uint256 takeChainId;
        /// Address of the ERC-20 token that the maker is willing to accept on the destination chain.
        bytes takeTokenAddress;
        /// Amount of tokens the maker is willing to accept on the destination chain.
        uint256 takeAmount;
        /// Address on the destination chain where funds should be sent upon order fulfillment.
        bytes receiverDst;
        /// Address on the source (current) chain authorized to patch the order by adding more input tokens, making it
        /// more attractive to takers.
        bytes givePatchAuthoritySrc;
        /// Address on the destination chain authorized to patch the order by reducing the take amount, making it more
        /// attractive to takers,
        /// and can also cancel the order in the take chain.
        bytes orderAuthorityAddressDst;
        // An optional address restricting anyone in the open market from fulfilling
        // this order but the given address. This can be useful if you are creating a order
        // for a specific taker. By default, set to empty bytes array (0x)
        bytes allowedTakerDst;
        // An optional address on the source (current) chain where the given input tokens
        // would be transferred to in case order cancellation is initiated by the orderAuthorityAddressDst
        // on the destination chain. This property can be safely set to an empty bytes array (0x):
        // in this case, tokens would be transferred to the arbitrary address specified
        // by the orderAuthorityAddressDst upon order cancellation
        bytes allowedCancelBeneficiarySrc;
        /// An optional external call data payload.
        bytes externalCall;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @notice is usually used for swap + bridge.
/// @dev interface built from their CrossChainForwarder
/// @dev refer: https://docs.dln.trade/the-core-protocol/trusted-smart-contracts#evm-chains
interface ICrossChainForwarder {
    /// @dev Performs swap against arbitrary input token, refunds excessive outcome of such swap (if any),
    ///      and calls the specified receiver supplying the outcome of the swap
    /// @param _srcTokenIn arbitrary input token to swap from
    /// @param _srcAmountIn amount of input token to swap
    /// @param _srcTokenInPermitEnvelope optional permit envelope to grab the token from the caller. bytes (amount +
    /// deadline + signature)
    /// @param _srcSwapRouter contract to call that performs swap from the input token to the output token
    /// @param _srcSwapCalldata calldata to call against _srcSwapRouter
    /// @param _srcTokenOut arbitrary output token to swap to
    /// @param _srcTokenExpectedAmountOut minimum acceptable outcome of the swap to provide to _target
    /// @param _srcTokenRefundRecipient address to send excessive outcome of the swap
    /// @param _target contract to call after successful swap
    /// @param _targetData calldata to call against _target
    function strictlySwapAndCall(
        address _srcTokenIn,
        uint256 _srcAmountIn,
        bytes memory _srcTokenInPermitEnvelope,
        address _srcSwapRouter,
        bytes calldata _srcSwapCalldata,
        address _srcTokenOut,
        uint256 _srcTokenExpectedAmountOut,
        address _srcTokenRefundRecipient,
        address _target,
        bytes calldata _targetData
    )
        external
        payable;

    /// @dev returns whether a swap router is whitelisted
    function supportedRouters(address router_) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title ISuperRegistry
/// @dev Interface for SuperRegistry
/// @author Zeropoint Labs
interface ISuperRegistry {
    //////////////////////////////////////////////////////////////
    //                          EVENTS                          //
    //////////////////////////////////////////////////////////////

    /// @dev emitted when permit2 is set.
    event SetPermit2(address indexed permit2);

    /// @dev is emitted when an address is set.
    event AddressUpdated(
        bytes32 indexed protocolAddressId, uint64 indexed chainId, address indexed oldAddress, address newAddress
    );

    /// @dev is emitted when a new token bridge is configured.
    event SetBridgeAddress(uint256 indexed bridgeId, address indexed bridgeAddress);

    /// @dev is emitted when a new bridge validator is configured.
    event SetBridgeValidator(uint256 indexed bridgeId, address indexed bridgeValidator);

    /// @dev is emitted when a new amb is configured.
    event SetAmbAddress(uint8 indexed ambId_, address indexed ambAddress_, bool indexed isBroadcastAMB_);

    /// @dev is emitted when a new state registry is configured.
    event SetStateRegistryAddress(uint8 indexed registryId_, address indexed registryAddress_);

    /// @dev is emitted when a new delay is configured.
    event SetDelay(uint256 indexed oldDelay_, uint256 indexed newDelay_);

    /// @dev is emitted when a new vault limit is configured
    event SetVaultLimitPerDestination(uint64 indexed chainId_, uint256 indexed vaultLimit_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev gets the deposit rescue delay
    function delay() external view returns (uint256);

    /// @dev returns the permit2 address
    function PERMIT2() external view returns (address);

    /// @dev returns the id of the superform router module
    function SUPERFORM_ROUTER() external view returns (bytes32);

    /// @dev returns the id of the superform factory module
    function SUPERFORM_FACTORY() external view returns (bytes32);

    /// @dev returns the id of the superform paymaster contract
    function PAYMASTER() external view returns (bytes32);

    /// @dev returns the id of the superform payload helper contract
    function PAYMENT_HELPER() external view returns (bytes32);

    /// @dev returns the id of the core state registry module
    function CORE_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry module
    function TIMELOCK_STATE_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the broadcast state registry module
    function BROADCAST_REGISTRY() external view returns (bytes32);

    /// @dev returns the id of the super positions module
    function SUPER_POSITIONS() external view returns (bytes32);

    /// @dev returns the id of the super rbac module
    function SUPER_RBAC() external view returns (bytes32);

    /// @dev returns the id of the payload helper module
    function PAYLOAD_HELPER() external view returns (bytes32);

    /// @dev returns the id of the dst swapper keeper
    function DST_SWAPPER() external view returns (bytes32);

    /// @dev returns the id of the emergency queue
    function EMERGENCY_QUEUE() external view returns (bytes32);

    /// @dev returns the id of the superform receiver
    function SUPERFORM_RECEIVER() external view returns (bytes32);

    /// @dev returns the id of the payment admin keeper
    function PAYMENT_ADMIN() external view returns (bytes32);

    /// @dev returns the id of the core state registry processor keeper
    function CORE_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the broadcast registry processor keeper
    function BROADCAST_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the timelock form state registry processor keeper
    function TIMELOCK_REGISTRY_PROCESSOR() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_UPDATER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_RESCUER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function CORE_REGISTRY_DISPUTER() external view returns (bytes32);

    /// @dev returns the id of the core state registry updater keeper
    function DST_SWAPPER_PROCESSOR() external view returns (bytes32);

    /// @dev gets the address of a contract on current chain
    /// @param id_ is the id of the contract
    function getAddress(bytes32 id_) external view returns (address);

    /// @dev gets the address of a contract on a target chain
    /// @param id_ is the id of the contract
    /// @param chainId_ is the chain id of that chain
    function getAddressByChainId(bytes32 id_, uint64 chainId_) external view returns (address);

    /// @dev gets the address of a bridge
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeAddress_ is the address of the form
    function getBridgeAddress(uint8 bridgeId_) external view returns (address bridgeAddress_);

    /// @dev gets the address of a bridge validator
    /// @param bridgeId_ is the id of a bridge
    /// @return bridgeValidator_ is the address of the form
    function getBridgeValidator(uint8 bridgeId_) external view returns (address bridgeValidator_);

    /// @dev gets the address of a amb
    /// @param ambId_ is the id of a bridge
    /// @return ambAddress_ is the address of the form
    function getAmbAddress(uint8 ambId_) external view returns (address ambAddress_);

    /// @dev gets the id of the amb
    /// @param ambAddress_ is the address of an amb
    /// @return ambId_ is the identifier of an amb
    function getAmbId(address ambAddress_) external view returns (uint8 ambId_);

    /// @dev gets the address of the registry
    /// @param registryId_ is the id of the state registry
    /// @return registryAddress_ is the address of the state registry
    function getStateRegistry(uint8 registryId_) external view returns (address registryAddress_);

    /// @dev gets the id of the registry
    /// @notice reverts if the id is not found
    /// @param registryAddress_ is the address of the state registry
    /// @return registryId_ is the id of the state registry
    function getStateRegistryId(address registryAddress_) external view returns (uint8 registryId_);

    /// @dev gets the safe vault limit
    /// @param chainId_ is the id of the remote chain
    /// @return vaultLimitPerDestination_ is the safe number of vaults to deposit
    /// without hitting out of gas error
    function getVaultLimitPerDestination(uint64 chainId_) external view returns (uint256 vaultLimitPerDestination_);

    /// @dev helps validate if an address is a valid state registry
    /// @param registryAddress_ is the address of the state registry
    /// @return valid_ a flag indicating if its valid.
    function isValidStateRegistry(address registryAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid amb implementation
    /// @param ambAddress_ is the address of the amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidAmbImpl(address ambAddress_) external view returns (bool valid_);

    /// @dev helps validate if an address is a valid broadcast amb implementation
    /// @param ambAddress_ is the address of the broadcast amb implementation
    /// @return valid_ a flag indicating if its valid.
    function isValidBroadcastAmbImpl(address ambAddress_) external view returns (bool valid_);

    //////////////////////////////////////////////////////////////
    //              EXTERNAL WRITE FUNCTIONS                    //
    //////////////////////////////////////////////////////////////

    /// @dev sets the deposit rescue delay
    /// @param delay_ the delay in seconds before the deposit rescue can be finalized
    function setDelay(uint256 delay_) external;

    /// @dev sets the permit2 address
    /// @param permit2_ the address of the permit2 contract
    function setPermit2(address permit2_) external;

    /// @dev sets the safe vault limit
    /// @param chainId_ is the remote chain identifier
    /// @param vaultLimit_ is the max limit of vaults per transaction
    function setVaultLimitPerDestination(uint64 chainId_, uint256 vaultLimit_) external;

    /// @dev sets new addresses on specific chains.
    /// @param ids_ are the identifiers of the address on that chain
    /// @param newAddresses_  are the new addresses on that chain
    /// @param chainIds_ are the chain ids of that chain
    function batchSetAddress(
        bytes32[] calldata ids_,
        address[] calldata newAddresses_,
        uint64[] calldata chainIds_
    )
        external;

    /// @dev sets a new address on a specific chain.
    /// @param id_ the identifier of the address on that chain
    /// @param newAddress_ the new address on that chain
    /// @param chainId_ the chain id of that chain
    function setAddress(bytes32 id_, address newAddress_, uint64 chainId_) external;

    /// @dev allows admin to set the bridge address for an bridge id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param bridgeId_         represents the bridge unique identifier.
    /// @param bridgeAddress_    represents the bridge address.
    /// @param bridgeValidator_  represents the bridge validator address.
    function setBridgeAddresses(
        uint8[] memory bridgeId_,
        address[] memory bridgeAddress_,
        address[] memory bridgeValidator_
    )
        external;

    /// @dev allows admin to set the amb address for an amb id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param ambId_         represents the bridge unique identifier.
    /// @param ambAddress_    represents the bridge address.
    /// @param isBroadcastAMB_ represents whether the amb implementation supports broadcasting
    function setAmbAddress(
        uint8[] memory ambId_,
        address[] memory ambAddress_,
        bool[] memory isBroadcastAMB_
    )
        external;

    /// @dev allows admin to set the state registry address for an state registry id.
    /// @notice this function operates in an APPEND-ONLY fashion.
    /// @param registryId_    represents the state registry's unique identifier.
    /// @param registryAddress_    represents the state registry's address.
    function setStateRegistryAddress(uint8[] memory registryId_, address[] memory registryAddress_) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.23;

/// @title Bridge Validator Interface
/// @dev Interface all Bridge Validators must follow
/// @author Zeropoint Labs
interface IBridgeValidator {
    //////////////////////////////////////////////////////////////
    //                           STRUCTS                        //
    //////////////////////////////////////////////////////////////

    struct ValidateTxDataArgs {
        bytes txData;
        uint64 srcChainId;
        uint64 dstChainId;
        uint64 liqDstChainId;
        bool deposit;
        address superform;
        address receiverAddress;
        address liqDataToken;
        address liqDataInterimToken;
    }

    //////////////////////////////////////////////////////////////
    //              EXTERNAL VIEW FUNCTIONS                     //
    //////////////////////////////////////////////////////////////

    /// @dev validates the receiver of the liquidity request
    /// @param txData_ is the txData of the cross chain deposit
    /// @param receiver_ is the address of the receiver to validate
    /// @return valid_ if the address is valid
    function validateReceiver(bytes calldata txData_, address receiver_) external view returns (bool valid_);

    /// @dev validates the txData of a cross chain deposit
    /// @param args_ the txData arguments to validate in txData
    /// @return hasDstSwap if the txData contains a destination swap
    function validateTxData(ValidateTxDataArgs calldata args_) external view returns (bool hasDstSwap);

    /// @dev decodes the txData and returns the amount of input token on source
    /// @param txData_ is the txData of the cross chain deposit
    /// @param genericSwapDisallowed_ true if generic swaps are disallowed
    /// @return amount_ the amount expected
    function decodeAmountIn(
        bytes calldata txData_,
        bool genericSwapDisallowed_
    )
        external
        view
        returns (uint256 amount_);

    /// @dev decodes neccesary information for processing swaps on the destination chain
    /// @param txData_ is the txData to be decoded
    /// @return token_ is the address of the token
    /// @return amount_ the amount expected
    function decodeDstSwap(bytes calldata txData_) external pure returns (address token_, uint256 amount_);

    /// @dev decodes the final output token address (for only direct chain actions!)
    /// @param txData_ is the txData to be decoded
    /// @return token_ the address of the token
    function decodeSwapOutputToken(bytes calldata txData_) external pure returns (address token_);
}