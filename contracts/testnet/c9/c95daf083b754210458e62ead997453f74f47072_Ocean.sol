// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

// All solidity behavior related comments are in reference to this version of
// the solc compiler.
pragma solidity =0.8.10;

// OpenZeppelin ERC Interfaces
import {IERC20Metadata} from "./IERC20Metadata.sol";
import {IERC20} from "./IERC20.sol";
import {IERC165} from "./IERC165.sol";
import {IERC721} from "./IERC721.sol";
import {IERC1155} from "./IERC1155.sol";
import {IERC1155Receiver} from "./IERC1155Receiver.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";

// OpenZeppelin Utility Library
import {SafeERC20} from "./SafeERC20.sol";

// OpenZeppelin inherited contract
import {Ownable} from "./Ownable.sol";

// ShellV2 Interfaces, Data Structures, and Library
import {IOceanInteractions, Interaction, InteractionType} from "./Interactions.sol";
import {IOceanFeeChange} from "./IOceanFeeChange.sol";
import {IOceanPrimitive} from "./IOceanPrimitive.sol";
import {BalanceDelta, LibBalanceDelta} from "./BalanceDelta.sol";

// ShellV2 ERC-1155 with logic related to public multitoken ledger management.
import {OceanERC1155} from "./OceanERC1155.sol";

/**
 * @title A public multitoken ledger for defi
 * @author Cowri Labs Team
 * @dev The ocean is designed to interact with contracts that implement IERC20,
 *  IERC721, IERC-1155, or IOceanPrimitive.
 * @dev The ocean is three things.
 *  1. At the highest level, it is a defi framework[0]. Users provide a list
 *   of interactions, and the ocean executes those interactions. Each
 *   interaction involves a call to an external contract. These calls result
 *   in updates to the ocean's accounting system.
 *  2. Suporting this defi framework is an accounting system that can transfer,
 *   mint, or burn tokens. Each token in the accounting system is identified by
 *   its oceanId. Every oceanId is uniquely derived from an external contract
 *   address. This external contract is the only contract able to cause mints
 *   or burns of this token[1].
 *  3. Supporting this accounting system is an ERC-1155 ledger with all the
 *   standard ERC-1155 features. Users and primitives can interact with their
 *   tokens using both the defi framework and the ERC-1155 functions.

 * [0] We call it a framework because the ocean calls predefined functions on
 *  external contracts at certain points in its exection. The lifecycle is
 *  managed by the ocean, while the business logic is managed by external
 *  contracts.  Conceptually this is quite similar to a typical web framework.
 * [1] For example, when a user wraps an ERC-20 token into the ocean, the
 *   framework calls the ERC-20 transfer function, and upon success, mints the
 *   wrapped token to the user. In another case, when a user deposits a base
 *   token into a liquidity pool to recieve liquidity provider tokens, the
 *   framework calls the liquidity pool, tells it how much of the base token it
 *   will receive, and asks it how much of the liquidity provider token it
 *   would like to mint. When the pool responds, the framework mints this
 *   amount to the user.
 *
 * @dev Getting started tips:
 *  1. Check out Interactions.sol
 *  2. Read through the implementation of Ocean.doInteraction(), glossing over
 *   the function call to _executeInteraction().
 *  3. Read through the imlementation of Ocean.doMultipleInteractions(), again
 *   glossing over the function call to _executeInteraction(). When you
 *   encounter calls to LibBalanceDelta, check out their implementations.
 *  4. Read through _executeInteraction() and all the functions it calls.
 *   Understand how this is the line separating the accounting for the external
 *   contracts and the accounting for the current user.
 *   You can read the implementations of the specific interactions in any
 *   order, but it might be good to go through them in order of increasing
 *   complexity. The called functions, in order of increasing complexity, are:
 *   wrapErc721, unwrapErc721, wrapErc1155, unwrapErc1155, computeOutputAmount,
 *   computeInputAmount, unwrapErc20, and wrapErc20.  When you get to 
 *   computeOutputAmount, check out IOceanPrimitive, IOceanToken, and the
 *   function registerNewTokens() in OceanERC1155.
 */
contract Ocean is
    IOceanInteractions,
    IOceanFeeChange,
    OceanERC1155,
    Ownable,
    IERC721Receiver,
    IERC1155Receiver
{
    using LibBalanceDelta for BalanceDelta[];

    /// @notice this is the oceanId used for shETH
    /// @dev hexadecimal(ascii("shETH"))
    uint256 public immutable WRAPPED_ETHER_ID;

    /// @notice Used to calculate the unwrap fee
    /// unwrapFee = unwrapAmount / unwrapFeeDivisor
    /// Because this uses integer division, the fee is always rounded down
    /// If unwrapAmount < unwrapFeeDivisor, unwrapFee == 0
    uint256 public unwrapFeeDivisor;
    /// @dev this is equivalent to 5 basis points: 1 / 2000 = 0.05%
    /// @dev When limited to 5 bips or less an integer divisor is an efficient
    ///  and precise method of calculating a fee.
    /// @notice As the divisor shrinks, the fee charged grows
    uint256 private constant MIN_UNWRAP_FEE_DIVISOR = 2000;

    /// @notice wrapped ERC20 tokens are stored in an 18 decimal representation
    /// @dev this makes it easier to implement AMMs between similar tokens
    uint8 private constant NORMALIZED_DECIMALS = 18;
    /// @notice When the specifiedAmount is equal to this value, we set
    ///  specifiedAmount to the balance delta.
    uint256 private constant GET_BALANCE_DELTA = type(uint256).max;

    /// @dev Determines if a transfer callback is expected.
    /// @dev adapted from OpenZeppelin Reentrancy Guard
    uint256 private constant NOT_INTERACTION = 1;
    uint256 private constant INTERACTION = 2;
    uint256 private _ERC1155InteractionStatus;
    uint256 private _ERC721InteractionStatus;

    event ChangeUnwrapFee(uint256 oldFee, uint256 newFee, address sender);
    event Erc20Wrap(
        address indexed erc20Token,
        uint256 transferredAmount,
        uint256 wrappedAmount,
        uint256 dust,
        address indexed user,
        uint256 indexed oceanId
    );
    event Erc20Unwrap(
        address indexed erc20Token,
        uint256 transferredAmount,
        uint256 unwrappedAmount,
        uint256 feeCharged,
        address indexed user,
        uint256 indexed oceanId
    );
    event Erc721Wrap(
        address indexed erc721Token,
        uint256 erc721id,
        address indexed user,
        uint256 indexed oceanId
    );
    event Erc721Unwrap(
        address indexed erc721Token,
        uint256 erc721Id,
        address indexed user,
        uint256 indexed oceanId
    );
    event Erc1155Wrap(
        address indexed erc1155Token,
        uint256 erc1155Id,
        uint256 amount,
        address indexed user,
        uint256 indexed oceanId
    );
    event Erc1155Unwrap(
        address indexed erc1155Token,
        uint256 erc1155Id,
        uint256 amount,
        uint256 feeCharged,
        address indexed user,
        uint256 indexed oceanId
    );
    event ComputeOutputAmount(
        address indexed primitive,
        uint256 inputToken,
        uint256 outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        address indexed user
    );
    event ComputeInputAmount(
        address indexed primitive,
        uint256 inputToken,
        uint256 outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        address indexed user
    );
    event EtherUnwrap(uint256 amount, uint256 feeCharged, address indexed user);
    event OceanTransaction(address indexed user, uint256 numberOfInteractions);
    event ForwardedOceanTransaction(
        address indexed forwarder,
        address indexed user,
        uint256 numberOfInteractions
    );

    /**
     * @dev Creates custom ERC-1155 with passed uri_, sets DAO address, and
     *  initializes ERC-1155 transfer guard.
     * @notice initializes the fee divisor to uint256 max, which results in
     *  a fee of zero unless unwrapAmount == type(uint256).max, in which
     *  case the fee is one part in 1.16 * 10^77.
     */
    constructor(string memory uri_) OceanERC1155(uri_) {
        unwrapFeeDivisor = type(uint256).max;
        _ERC1155InteractionStatus = NOT_INTERACTION;
        _ERC721InteractionStatus = NOT_INTERACTION;
        WRAPPED_ETHER_ID = _calculateOceanId(address(0x4574686572), 0); // hexadecimal(ascii("Ether"))
    }

    /**
     * @dev ERC1155 Approvals also function as permission to execute
     *  interactions on a user's behalf
     * @param userAddress the address passed by the forwarder
     *
     * Because poorly chosen interactions are vulnerable to economic attacks,
     *  calling do{Interaction|MultipleInteractions} on a user's behalf must
     *  require the  same level of trust as direct balance transfers.
     */
    modifier onlyApprovedForwarder(address userAddress) {
        require(
            isApprovedForAll(userAddress, msg.sender),
            "Forwarder not approved"
        );
        _;
    }

    /**
     * @notice this changes the unwrap fee immediately
     * @notice The governance structure must appropriately handle any
     *  time lock or other mechanism for managing fee changes
     * @param nextUnwrapFeeDivisor the reciprocal of the next fee percentage.
     */
    function changeUnwrapFee(uint256 nextUnwrapFeeDivisor)
        external
        override
        onlyOwner
    {
        /// @notice as the divisor gets smaller, the fee charged gets larger
        require(MIN_UNWRAP_FEE_DIVISOR <= nextUnwrapFeeDivisor);
        emit ChangeUnwrapFee(
            unwrapFeeDivisor,
            nextUnwrapFeeDivisor,
            msg.sender
        );
        unwrapFeeDivisor = nextUnwrapFeeDivisor;
    }

    /**
     * @notice Execute interactions `interaction`
     * @notice Does not need ids because a single interaction does not require
     *  the accounting system
     * @dev MUST HAVE nonReentrant modifier.
     * @dev call to _doInteraction() binds msg.sender to userAddress
     * @param interaction Executed to produce a set of balance updates
     */
    function doInteraction(Interaction calldata interaction)
        external
        override
        nonReentrant
        returns (
            uint256 burnId,
            uint256 burnAmount,
            uint256 mintId,
            uint256 mintAmount
        )
    {
        emit OceanTransaction(msg.sender, 1);
        return _doInteraction(interaction, msg.sender);
    }

    /**
     * @notice Execute interactions `interactions` with tokens `ids`
     * @notice ids must include all tokens invoked during the transaction
     * @notice ids are used for memory allocation in the intra-transaction
     *  accounting system.
     * @dev MUST HAVE nonReentrant modifier.
     * @dev call to _doMultipleInteractions() binds msg.sender to userAddress
     * @param interactions Executed to produce a set of balance updates
     * @param ids Ocean IDs of the tokens invoked by the interactions.
     */
    function doMultipleInteractions(
        Interaction[] calldata interactions,
        uint256[] calldata ids
    )
        external
        payable
        override
        nonReentrant
        returns (
            uint256[] memory burnIds,
            uint256[] memory burnAmounts,
            uint256[] memory mintIds,
            uint256[] memory mintAmounts
        )
    {
        emit OceanTransaction(msg.sender, interactions.length);
        return _doMultipleInteractions(interactions, ids, msg.sender);
    }

    /**
     * @notice Execute interactions `interactions` on behalf of `userAddress`
     * @notice Does not need ids because a single interaction does not require
     *  the overhead of the intra-transaction accounting system
     * @dev MUST HAVE nonReentrant modifier.
     * @dev MUST HAVE onlyApprovedForwarder modifer.
     * @dev call to _doMultipleInteractions() forwards the userAddress
     * @param interaction Executed to produce a set of balance updates
     * @param userAddress interactions are executed on behalf of this address
     */
    function forwardedDoInteraction(
        Interaction calldata interaction,
        address userAddress
    )
        external
        override
        nonReentrant
        onlyApprovedForwarder(userAddress)
        returns (
            uint256 burnId,
            uint256 burnAmount,
            uint256 mintId,
            uint256 mintAmount
        )
    {
        emit ForwardedOceanTransaction(msg.sender, userAddress, 1);
        return _doInteraction(interaction, userAddress);
    }

    /**
     * @notice Execute interactions `interactions` with tokens `ids` on behalf of `userAddress`
     * @notice ids must include all tokens invoked during the transaction
     * @notice ids are used for memory allocation in the intra-transaction
     *  accounting system.
     * @dev MUST HAVE nonReentrant modifier.
     * @dev MUST HAVE onlyApprovedForwarder modifer.
     * @dev call to _doMultipleInteractions() forwards the userAddress
     * @param interactions Executed to produce a set of balance updates
     * @param ids Ocean IDs of the tokens invoked by the interactions.
     * @param userAddress interactions are executed on behalf of this address
     */
    function forwardedDoMultipleInteractions(
        Interaction[] calldata interactions,
        uint256[] calldata ids,
        address userAddress
    )
        external
        payable
        override
        nonReentrant
        onlyApprovedForwarder(userAddress)
        returns (
            uint256[] memory burnIds,
            uint256[] memory burnAmounts,
            uint256[] memory mintIds,
            uint256[] memory mintAmounts
        )
    {
        emit ForwardedOceanTransaction(
            msg.sender,
            userAddress,
            interactions.length
        );
        return _doMultipleInteractions(interactions, ids, userAddress);
    }

    /**
     * @dev This callback is part of IERC1155Receiver, which we must implement
     *  to wrap ERC-1155 tokens.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(OceanERC1155, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        if (_ERC721InteractionStatus == INTERACTION) {
            return IERC721Receiver.onERC721Received.selector;
        } else {
            return 0;
        }
    }

    /**
     * @dev This callback is part of IERC1155Receiver, which we must implement
     *  to wrap ERC-1155 tokens.
     * @dev The Ocean only accepts ERC1155 transfers initiated by the Ocean
     *  while executing interactions.
     * @dev We don't revert, prefering to let the external contract
     *  decide what it wants to do when safeTransfer is called on a contract
     *  that does not return the expected selector.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        if (_ERC1155InteractionStatus == INTERACTION) {
            return IERC1155Receiver.onERC1155Received.selector;
        } else {
            return 0;
        }
    }

    /**
     * @dev This callback is part of IERC1155Receiver, which we must implement
     *  to wrap ERC-1155 tokens.
     * @dev The Ocean never initiates ERC1155 Batch Transfers.
     * @dev We don't revert, prefering to let the external contract
     *  decide what it wants to do when safeTransfer is called on a contract
     *  that does not return the expected selector.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0;
    }

    /**
     * @dev This function handles both forwarded and non-forwarded single
     *  interactions
     * @dev the external functions that pass through their arguments to this
     *  function have more information about the arguments.
     * @param interaction the current interaction passed by the caller
     * @param userAddress In the case of a forwarded interaction, this value
     *  is passed by the caller, and this value must be validated against the
     *  approvals set on this address and the caller's address (`msg.sender`)
     *  In the case of a non-forwarded interaction, this value is the caller's
     *  address.
     */
    function _doInteraction(
        Interaction calldata interaction,
        address userAddress
    )
        internal
        returns (
            uint256 inputToken,
            uint256 inputAmount,
            uint256 outputToken,
            uint256 outputAmount
        )
    {
        // Begin by unpacking the interaction type and the external contract
        (
            InteractionType interactionType,
            address externalContract
        ) = _unpackInteractionTypeAndAddress(interaction);

        // Determine the specified token based on the interaction type and the
        // interaction's external contract address, inputToken, outputToken,
        // and metadata fields. The specified token is the token
        // whose amount the user specifies.
        uint256 specifiedToken = _getSpecifiedToken(
            interactionType,
            externalContract,
            interaction
        );

        // Here we call _executeInteraction(), which is just a big
        // if... else if... block branching on interaction type.
        // Each branch sets the inputToken and outputToken and their
        // respective amounts. This abstraction is what lets us treat
        // interactions uniformly.
        (
            inputToken,
            inputAmount,
            outputToken,
            outputAmount
        ) = _executeInteraction(
            interaction,
            interactionType,
            externalContract,
            specifiedToken,
            interaction.specifiedAmount,
            userAddress
        );

        // if _executeInteraction returned a positive value for inputAmount,
        // this amount must be deducted from the user's Ocean balance
        if (inputAmount > 0) {
            // since uint, same as (inputAmount != 0)
            _burn(userAddress, inputToken, inputAmount);
        }

        // if _executeInteraction returned a positive value for outputAmount,
        // this amount must be credited to the user's Ocean balance
        if (outputAmount > 0) {
            // since uint, same as (outputAmount != 0)
            _mint(userAddress, outputToken, outputAmount);
        }
    }

    /**
     * @dev This function handles both forwarded and non-forwarded multiple
     *  interactions
     * @dev the external functions that pass through their arguments to this
     *  function have more information about the arguments.
     * @param interactions The interactions passed by the caller
     * @param ids the ids passed by the caller
     * @param userAddress In the case of a forwarded interaction, this value
     *  is passed by the caller, and this value must be validated against the
     *  approvals set on this address and the caller's address (`msg.sender`)
     *  In the case of a non-forwarded interaction, this value is the caller's
     *  address.
     */
    function _doMultipleInteractions(
        Interaction[] calldata interactions,
        uint256[] calldata ids,
        address userAddress
    )
        internal
        returns (
            uint256[] memory burnIds,
            uint256[] memory burnAmounts,
            uint256[] memory mintIds,
            uint256[] memory mintAmounts
        )
    {
        // Use the passed ids to create an array of balance deltas, used in
        // the intra-transaction accounting system.
        BalanceDelta[] memory balanceDeltas = new BalanceDelta[](ids.length);
        for (uint256 i = 0; i < ids.length; ++i) {
            balanceDeltas[i] = BalanceDelta(ids[i], 0);
        }

        // Ether payments are push only.  We always wrap ERC-X tokens using pull
        // payments, so we cannot wrap Ether using the same pattern.
        // We unwrap ERC-X tokens using push payments, so we can unwrap Ether
        // the same way.
        if (msg.value != 0) {
            balanceDeltas.increaseBalanceDelta(WRAPPED_ETHER_ID, msg.value);
        }

        // Execute the interactions
        {
            /**
             * @dev Solidity does not reuse memory that has gone out of scope
             *  and the gas cost of memory usage grows quadratically.
             * @dev We passed interactions as calldata to lower memory usage.
             *  However, accessing the members of a calldata structure uses
             *  more local identifiers than accessing the members of an
             *  in-memory structure. We're right up against the limit on
             *  local identifiers. To solve this, we allocate a single
             *  structure in memory and copy the calldata structures over one
             *  by one as we process them.
             */
            Interaction memory interaction;
            // This pulls the user's address to the top of the stack, above
            // the ids array, which we won't need again. We're right up against
            // the locals limit and this does the trick. Is there a better way?
            address userAddress_ = userAddress;
            for (uint256 i = 0; i < interactions.length; ++i) {
                interaction = interactions[i];

                (
                    InteractionType interactionType,
                    address externalContract
                ) = _unpackInteractionTypeAndAddress(interaction);

                // specifiedToken is the token whose amount the user specifies
                uint256 specifiedToken = _getSpecifiedToken(
                    interactionType,
                    externalContract,
                    interaction
                );

                // A user can pass uint256.max as the specifiedAmount when they
                // want to use the total amount of the token held in the
                // balance delta. Otherwise, the specifiedAmount is just the
                // amount the user passed for this interaction.
                uint256 specifiedAmount;
                if (interaction.specifiedAmount == GET_BALANCE_DELTA) {
                    specifiedAmount = balanceDeltas.getBalanceDelta(
                        interactionType,
                        specifiedToken
                    );
                } else {
                    specifiedAmount = interaction.specifiedAmount;
                }

                (
                    uint256 inputToken,
                    uint256 inputAmount,
                    uint256 outputToken,
                    uint256 outputAmount
                ) = _executeInteraction(
                        interaction,
                        interactionType,
                        externalContract,
                        specifiedToken,
                        specifiedAmount,
                        userAddress_
                    );

                // inputToken is given up by the user during the interaction
                if (inputAmount > 0) {
                    // equivalent to (inputAmount != 0)
                    balanceDeltas.decreaseBalanceDelta(inputToken, inputAmount);
                }

                // outputToken is gained by the user during the interaction
                if (outputAmount > 0) {
                    // equivalent to (outputAmount != 0)
                    balanceDeltas.increaseBalanceDelta(
                        outputToken,
                        outputAmount
                    );
                }
            }
        }

        // Persist intra-transaction balance deltas to the Ocean's public ledger
        {
            // Place positive deltas into mintIds and mintAmounts
            // Place negative deltas into burnIds and burnAmounts
            (mintIds, mintAmounts, burnIds, burnAmounts) = balanceDeltas
                .createMintAndBurnArrays();

            // Here we should know that uint[] memory arr = new uint[](0);
            // produces a reference to an empty array called arr with property
            // (arr.length == 0)

            // mint the positive deltas to the user's balances
            if (mintIds.length == 1) {
                // if there's only one we can just use the more semantically
                // appropriate _mint
                _mint(userAddress, mintIds[0], mintAmounts[0]);
            } else if (mintIds.length > 1) {
                // if there's more than one we use _mintBatch
                _mintBatch(userAddress, mintIds, mintAmounts);
            } // if there are none, we do nothing

            // burn the positive deltas from the user's balances
            if (burnIds.length == 1) {
                // if there's only one we can just use the more semantically
                // appropriate _burn
                _burn(userAddress, burnIds[0], burnAmounts[0]);
            } else if (burnIds.length > 1) {
                // if there's more than one we use _burnBatch
                _burnBatch(userAddress, burnIds, burnAmounts);
            } // if there are none, we do nothing
        }
    }

    /**
     * @dev Here is the core logic shared between doInteraction and
     *  doMultipleInteractions
     * @dev State mutations on the external ledgers happen during wraps/unwraps
     * @dev State mutations on the Ocean's ledger for the externalContract
     *  happen during computeInputAmount/computeOutputAmount
     * @dev State mutations for the userAddress MUST happen in the calling
     *  context based on the return values of this function.
     * @param interaction the current interaction passed from calldata
     * @param interactionType the type of interaction unpacked by caller
     * @param externalContract the address of the external contract parsed by caller
     * @param specifiedToken the token in this interaction that specifiedAmount
     *  refers to
     * @param specifiedAmount the amount of specifiedToken being used in this
     *  interaction
     * @param userAddress the address of the user this interaction is being
     *  executed on behalf of. This is passed to the external contract.
     * @return inputToken The token on the Ocean that the user is giving up
     * @return inputAmount The amount of inputToken that the user is giving up
     * @return outputToken The token on the Ocean that the user is gaining
     * @return outputAmount The amount of ouputToken that the user is gaining
     */
    function _executeInteraction(
        Interaction memory interaction,
        InteractionType interactionType,
        address externalContract,
        uint256 specifiedToken,
        uint256 specifiedAmount,
        address userAddress
    )
        internal
        returns (
            uint256 inputToken,
            uint256 inputAmount,
            uint256 outputToken,
            uint256 outputAmount
        )
    {
        if (interactionType == InteractionType.ComputeOutputAmount) {
            inputToken = specifiedToken;
            inputAmount = specifiedAmount;
            outputToken = interaction.outputToken;
            outputAmount = _computeOutputAmount(
                externalContract,
                inputToken,
                outputToken,
                inputAmount,
                userAddress,
                interaction.metadata
            );
        } else if (interactionType == InteractionType.ComputeInputAmount) {
            inputToken = interaction.inputToken;
            outputToken = specifiedToken;
            outputAmount = specifiedAmount;
            inputAmount = _computeInputAmount(
                externalContract,
                inputToken,
                outputToken,
                outputAmount,
                userAddress,
                interaction.metadata
            );
        } else if (interactionType == InteractionType.WrapErc20) {
            inputToken = 0;
            inputAmount = 0;
            outputToken = specifiedToken;
            outputAmount = specifiedAmount;
            _erc20Wrap(
                externalContract,
                outputAmount,
                userAddress,
                outputToken
            );
        } else if (interactionType == InteractionType.UnwrapErc20) {
            inputToken = specifiedToken;
            inputAmount = specifiedAmount;
            outputToken = 0;
            outputAmount = 0;
            _erc20Unwrap(
                externalContract,
                inputAmount,
                userAddress,
                inputToken
            );
        } else if (interactionType == InteractionType.WrapErc721) {
            // An ERC-20 or ERC-1155 contract can have a transfer with
            // any amount including zero. Here, we need to require that
            // the specifiedAmount is equal to one, since the external
            // call to the ERC-721 contract does not include an amount,
            // and the ledger is mutated based on the specifiedAmount.
            require(specifiedAmount == 1, "NFT amount != 1");
            inputToken = 0;
            inputAmount = 0;
            outputToken = specifiedToken;
            outputAmount = specifiedAmount;
            _erc721Wrap(
                externalContract,
                uint256(interaction.metadata),
                userAddress,
                outputToken
            );
        } else if (interactionType == InteractionType.UnwrapErc721) {
            // See the comment in the preceeding else if block.
            require(specifiedAmount == 1, "NFT amount != 1");
            inputToken = specifiedToken;
            inputAmount = specifiedAmount;
            outputToken = 0;
            outputAmount = 0;
            _erc721Unwrap(
                externalContract,
                uint256(interaction.metadata),
                userAddress,
                inputToken
            );
        } else if (interactionType == InteractionType.WrapErc1155) {
            inputToken = 0;
            inputAmount = 0;
            outputToken = specifiedToken;
            outputAmount = specifiedAmount;
            _erc1155Wrap(
                externalContract,
                uint256(interaction.metadata),
                outputAmount,
                userAddress,
                outputToken
            );
        } else if (interactionType == InteractionType.UnwrapErc1155) {
            inputToken = specifiedToken;
            inputAmount = specifiedAmount;
            outputToken = 0;
            outputAmount = 0;
            _erc1155Unwrap(
                externalContract,
                uint256(interaction.metadata),
                inputAmount,
                userAddress,
                inputToken
            );
        } else {
            assert(interactionType == InteractionType.UnwrapEther);
            require(specifiedToken == WRAPPED_ETHER_ID);
            inputToken = specifiedToken;
            inputAmount = specifiedAmount;
            outputToken = 0;
            outputAmount = 0;
            _etherUnwrap(inputAmount, userAddress);
        }
    }

    /**
     * @param interaction the interaction
     * @dev the first byte contains the interactionType
     * @dev the next eleven bytes are IGNORED
     * @dev the final twenty bytes are the address targeted by the interaction
     */
    function _unpackInteractionTypeAndAddress(Interaction memory interaction)
        internal
        pure
        returns (InteractionType interactionType, address externalContract)
    {
        bytes32 interactionTypeAndAddress = interaction
            .interactionTypeAndAddress;
        interactionType = InteractionType(uint8(interactionTypeAndAddress[0]));
        externalContract = address(uint160(uint256(interactionTypeAndAddress)));
    }

    /**
     * @param interactionType determines how we derive the specifiedToken
     * @param externalContract is the target of the interaction's external call
     * @param interaction the interaction's fields are interpreted based on
     *  the Interaction type. See the declarations in Interactions.sol
     * @return specifiedToken is the ocean's internal ID for the token in a
     *  interaction that's amount is specified by the user.
     */
    function _getSpecifiedToken(
        InteractionType interactionType,
        address externalContract,
        Interaction memory interaction
    ) internal view returns (uint256 specifiedToken) {
        if (
            interactionType == InteractionType.WrapErc20 ||
            interactionType == InteractionType.UnwrapErc20
        ) {
            specifiedToken = _calculateOceanId(externalContract, 0);
        } else if (
            interactionType == InteractionType.WrapErc721 ||
            interactionType == InteractionType.WrapErc1155 ||
            interactionType == InteractionType.UnwrapErc721 ||
            interactionType == InteractionType.UnwrapErc1155
        ) {
            specifiedToken = _calculateOceanId(
                externalContract,
                uint256(interaction.metadata)
            );
        } else if (interactionType == InteractionType.ComputeInputAmount) {
            specifiedToken = interaction.outputToken;
        } else if (interactionType == InteractionType.ComputeOutputAmount) {
            specifiedToken = interaction.inputToken;
        } else {
            assert(interactionType == InteractionType.UnwrapEther);
            specifiedToken = WRAPPED_ETHER_ID;
        }
    }

    /**
     * @dev A primitive is an external smart contract that establishes a market
     *  between two or more tokens.
     * @dev the external contract's Ocean balances are mutated
     *  immediately after the external call returns. If the external
     *  contract does not want to receive the inputToken, it should revert
     *  the transaction.
     * @param primitive A contract that implements IOceanPrimitive
     * @param inputToken The token offered to the contract
     * @param outputToken The token requested from the contract
     * @param inputAmount The amount of the inputToken offered
     * @param userAddress The address of the user whose balances are being
     *  updated during the transaction.
     * @param metadata The function of this parameter is up to the contract
     *  it is the responsibility of the caller to know what the called contract
     *  expects.
     * @return outputAmount the amount of the outputToken the contract gives
     *  in return for the inputAmount of the inputToken.
     */
    function _computeOutputAmount(
        address primitive,
        uint256 inputToken,
        uint256 outputToken,
        uint256 inputAmount,
        address userAddress,
        bytes32 metadata
    ) internal returns (uint256 outputAmount) {
        outputAmount = IOceanPrimitive(primitive).computeOutputAmount(
            inputToken,
            outputToken,
            inputAmount,
            userAddress,
            metadata
        );

        _updateBalancesOfPrimitive(
            primitive,
            inputToken,
            inputAmount,
            outputToken,
            outputAmount
        );

        emit ComputeOutputAmount(
            primitive,
            inputToken,
            outputToken,
            inputAmount,
            outputAmount,
            userAddress
        );
    }

    /**
     * @dev A primitive is an external smart contract that establishes a market
     *  between two or more tokens.
     * @dev the external contract's Ocean balances are mutated
     *  immediately after the external call returns. If the external
     *  contract does not want to receive the outputToken, it should revert
     *  the transaction.
     * @param primitive A contract that implements IOceanPrimitive
     * @param inputToken The token offered to the contract
     * @param outputToken The token requested from the contract
     * @param outputAmount The amount of the outputToken offered
     * @param userAddress The address of the user whose balances are being
     *  updated during the transaction.
     * @param metadata The function of this parameter is up to the contract
     *  it is the responsibility of the caller to know what the called contract
     *  expects.
     * @return inputAmount the amount of the inputToken the contract gives
     *  in return for the outputAmount of the outputToken.
     */
    function _computeInputAmount(
        address primitive,
        uint256 inputToken,
        uint256 outputToken,
        uint256 outputAmount,
        address userAddress,
        bytes32 metadata
    ) internal returns (uint256 inputAmount) {
        inputAmount = IOceanPrimitive(primitive).computeInputAmount(
            inputToken,
            outputToken,
            outputAmount,
            userAddress,
            metadata
        );

        _updateBalancesOfPrimitive(
            primitive,
            inputToken,
            inputAmount,
            outputToken,
            outputAmount
        );

        emit ComputeInputAmount(
            primitive,
            inputToken,
            outputToken,
            inputAmount,
            outputAmount,
            userAddress
        );
    }

    /**
     * @dev Wrap an ERC-20 token into the ocean. The Ocean ID is
     *  derived from the contract address and a tokenId of 0.
     * @notice Token amounts are normalized to 18 decimal places.
     * @dev This means that to wrap 5 units of token A, which has 6 decimals,
     *  and 5 units of token B, which has 18 decimals, the user would specify
     *  5 * 10**18 for both token A and B.
     * @param tokenAddress address of the ERC-20 token
     * @param amount amount of the ERC-20 token to be wrapped, in terms of
     *  18-decimal fixed point
     * @param userAddress the address of the user who is wrapping the token
     */
    function _erc20Wrap(
        address tokenAddress,
        uint256 amount,
        address userAddress,
        uint256 outputToken
    ) private {
        try IERC20Metadata(tokenAddress).decimals() returns (uint8 decimals) {
            /// @dev the amount passed as an argument to the external token
            uint256 transferAmount;
            /// @dev the leftover amount accumulated by the Ocean.
            uint256 dust;

            (transferAmount, dust) = _determineTransferAmount(amount, decimals);

            // If the user is unwrapping a delta, the residual dust could be
            // written to the user's ledger balance. However, it costs the
            // same amount of gas to place the dust on the owner's balance,
            // and accumulation of dust may eventually result in
            // transferrable units again.
            _grantFeeToOcean(outputToken, dust);

            SafeERC20.safeTransferFrom(
                IERC20(tokenAddress),
                userAddress,
                address(this),
                transferAmount
            );

            emit Erc20Wrap(
                tokenAddress,
                transferAmount,
                amount,
                dust,
                userAddress,
                outputToken
            );
        } catch {
            revert("Could not get decimals()");
        }
    }

    /**
     * @dev Unwrap an ERC-20 token out of the ocean. The Ocean ID is
     *  derived from the contract address and a tokenId of 0.
     * @notice tokens are normalized to 18 decimal places.
     * @notice unwrap amounts may be subject to a fee that reduces the amount
     *  moved on the external token's ledger. To unwrap an exact amount, the
     *  caller should compute off-chain what specifiedAmount results in the
     *  desired unwrap amount.
     * @dev This means that to wrap 5 units of token A, which has 6 decimals,
     *  and 5 units of token B, which has 18 decimals, when the fee is zero,
     *  the user would specify 5 * 10**18 for both token A and B.
     * @dev If the fee is 1 basis point, the user would specify
     *  5000500050005000500
     *  This value was found by solving for x in the equation:
     *      x - Floor[x * (1/10000)] = 5000000000000000000
     * @param tokenAddress address of the ERC-20 token
     * @param amount amount of the ERC-20 token to be unwrapped, in terms of
     *  18-decimal fixed point
     * @param userAddress the address of the user who is unwrapping the token
     */
    function _erc20Unwrap(
        address tokenAddress,
        uint256 amount,
        address userAddress,
        uint256 inputToken
    ) private {
        try IERC20Metadata(tokenAddress).decimals() returns (uint8 decimals) {
            uint256 feeCharged = _calculateUnwrapFee(amount);
            uint256 amountRemaining = amount - feeCharged;

            (uint256 transferAmount, uint256 truncated) = _convertDecimals(
                NORMALIZED_DECIMALS,
                decimals,
                amountRemaining
            );
            feeCharged += truncated;

            _grantFeeToOcean(inputToken, feeCharged);

            SafeERC20.safeTransfer(
                IERC20(tokenAddress),
                userAddress,
                transferAmount
            );
            emit Erc20Unwrap(
                tokenAddress,
                transferAmount,
                amount,
                feeCharged,
                userAddress,
                inputToken
            );
        } catch {
            revert("Could not get decimals()");
        }
    }

    /**
     * @dev wrap an ERC-721 NFT into the Ocean. The Ocean ID is derived from
     *  tokenAddress and tokenId.
     * @param tokenAddress address of the ERC-721 contract
     * @param tokenId ID of the NFT on the ERC-721 ledger
     * @param userAddress the address of the user who is wrapping the NFT
     */
    function _erc721Wrap(
        address tokenAddress,
        uint256 tokenId,
        address userAddress,
        uint256 oceanId
    ) private {
        _ERC721InteractionStatus = INTERACTION;
        IERC721(tokenAddress).safeTransferFrom(
            userAddress,
            address(this),
            tokenId
        );
        _ERC721InteractionStatus = NOT_INTERACTION;
        emit Erc721Wrap(tokenAddress, tokenId, userAddress, oceanId);
    }

    /**
     * @dev Unwrap an ERC-721 NFT out of the Ocean. The Ocean ID is derived
     *  from tokenAddress and tokenId.
     * @param tokenAddress address of the ERC-721 contract
     * @param tokenId ID of the NFT on the ERC-721 ledger
     * @param userAddress the address of the user who is unwrapping the NFT
     */
    function _erc721Unwrap(
        address tokenAddress,
        uint256 tokenId,
        address userAddress,
        uint256 oceanId
    ) private {
        IERC721(tokenAddress).safeTransferFrom(
            address(this),
            userAddress,
            tokenId
        );
        emit Erc721Unwrap(tokenAddress, tokenId, userAddress, oceanId);
    }

    /**
     * @dev Wrap an ERC-1155 token into the Ocean. The Ocean ID is derived
     *  from tokenAddress and tokenId.
     * @notice ERC-1155 amounts and in-Ocean amounts are equal. If a token
     *  implemented using ERC-1155 should have the same value as other tokens
     *  implemented using ERC-20, the ERC-1155 should use an 18-decimal
     *  representation.
     * @param tokenAddress address of the ERC-1155 contract
     * @param tokenId ID of the token on the ERC-1155 ledger
     * @param amount the amount of the token being wrapped.
     * @param userAddress the address of the user who is wrapping the token
     */
    function _erc1155Wrap(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address userAddress,
        uint256 oceanId
    ) private {
        require(tokenAddress != address(this));
        _ERC1155InteractionStatus = INTERACTION;
        IERC1155(tokenAddress).safeTransferFrom(
            userAddress,
            address(this),
            tokenId,
            amount,
            ""
        );
        _ERC1155InteractionStatus = NOT_INTERACTION;
        emit Erc1155Wrap(tokenAddress, tokenId, amount, userAddress, oceanId);
    }

    /**
     * @dev Unwrap an ERC-1155 token out of the Ocean. The Ocean ID is derived
     *  from tokenAddress and tokenId.
     * @notice ERC-1155 amounts and in-Ocean amounts are equal. If a token
     *  implemented using ERC-1155 should have the same value as other tokens
     *  implemented using ERC-20, the ERC-1155 should use an 18-decimal
     *  representation.
     * @notice unwrap amounts may be subject to a fee that reduces the amount
     *  moved on the external token's ledger. To unwrap an exact amount, the
     *  caller should compute off-chain what specifiedAmount results in the
     *  desired unwrap amount. If the user wants to receive 100_000 of a token
     *  and the fee is 1 basis point, the user should specify 100_010
     *  This value was found by solving for x in the equation:
     *      x - Floor[x * (1/10000)] = 100000
     * @param tokenAddress address of the ERC-1155 contract
     * @param tokenId ID of the token on the ERC-1155 ledger
     * @param amount the amount of the token being wrapped.
     * @param userAddress the address of the user who is wrapping the token
     */
    function _erc1155Unwrap(
        address tokenAddress,
        uint256 tokenId,
        uint256 amount,
        address userAddress,
        uint256 oceanId
    ) private {
        require(tokenAddress != address(this));
        uint256 feeCharged = _calculateUnwrapFee(amount);
        uint256 amountRemaining = amount - feeCharged;
        _grantFeeToOcean(oceanId, feeCharged);
        IERC1155(tokenAddress).safeTransferFrom(
            address(this),
            userAddress,
            tokenId,
            amountRemaining,
            ""
        );
        emit Erc1155Unwrap(
            tokenAddress,
            tokenId,
            amount,
            feeCharged,
            userAddress,
            oceanId
        );
    }

    /**
     * @dev Unwrap Ether out of the ocean.  The Ocean ID of shETH is computed
     *  in the constructor using the address of the ocean and a tokenId of 0.
     * @param amount The amount of Ether to unwrap.
     * @param userAddress The user performing the unwrap.
     */
    function _etherUnwrap(uint256 amount, address userAddress) private {
        uint256 feeCharged = _calculateUnwrapFee(amount);
        uint256 amountRemaining = amount - feeCharged;
        _grantFeeToOcean(WRAPPED_ETHER_ID, feeCharged);
        payable(userAddress).transfer(amountRemaining);
        emit EtherUnwrap(amountRemaining, feeCharged, userAddress);
    }

    /**
     * @notice If the primitive registered the inputToken, it does not
     *  receive any of the inputToken.
     * @notice If the primitive registered the outputToken, it does not
     *  lose any of the outputToken.
     * @notice look at the public function registerNewTokens()
     * @notice We cannot keep the primitive's balance changes in memory.
     *  A primitive relies on the ocean for its accounting, so it must always
     *  receive a correct answer when it queries balanceOf() or
     *  balanceOfBatch().
     *  When the ocean receives a balanceOf() call, this call has its own
     *  memory space. The ocean cannot reach down through the call stack to
     *  get a delta stored in the memory of an earlier call.
     *      primitive -> ocean.balanceOf(address(this), token)  [mem_space_2]
     *      ocean -> primitive.computeOutputAmount()          [mem_space_1]
     *      EOA -> ocean.doMultipleInteractions()               [mem_space_0]
     *  Because we have no way of maintaining coherence between dirty memory
     *  and stale storage, our only option is to always have up-to-date values
     *  in storage.
     */
    function _updateBalancesOfPrimitive(
        address primitive,
        uint256 inputToken,
        uint256 inputAmount,
        uint256 outputToken,
        uint256 outputAmount
    ) internal {
        // If the input token is not one of the primitive's registered tokens,
        // the primitive receives the input amount it was passed.
        // Otherwise, the tokens will be implicitly burned by the primitive
        // later in the transaction
        if (
            _isNotTokenOfPrimitive(inputToken, primitive) && (inputAmount > 0)
        ) {
            // Since the primitive consented to receiving this token by not
            // reverting when it was called, we mint the token without
            // doing a safe transfer acceptance check. This breaks the
            // ERC1155 specification but in a way we hope is inconsequential, since
            // all primitives are developed by people who must be
            // aware of how the ocean works.
            _mintWithoutSafeTransferAcceptanceCheck(
                primitive,
                inputToken,
                inputAmount
            );
        }

        // If the output token is not one of the primitive's tokens, the
        // primitive loses the output amount it just computed.
        // Otherwise, the tokens will be implicitly minted by the primitive
        // later in the transaction
        if (
            _isNotTokenOfPrimitive(outputToken, primitive) && (outputAmount > 0)
        ) {
            _burn(primitive, outputToken, outputAmount);
        }
    }

    /**
     * @dev This function determines the correct argument to pass to
     *  the external token contract
     * @dev Say the in-Ocean unwrap amount (in 18-decimal) is 0.123456789012345678
     *      If the external token uses decimals == 6:
     *          transferAmount == 123456
     *          dust == 789012345678
     *      If the external token uses decimals == 18:
     *          transferAmount == 123456789012345678
     *          dust == 0
     *      If the external token uses decimals == 21:
     *          transferAmount == 123456789012345678000
     *          dust == 0
     * @param amount the amount of in-Ocean tokens being unwrapped
     * @param decimals returned by IERC20(token).decimals()
     * @return transferAmount the amount passed to SafeERC20.safeTransfer()
     * @return dust The amount of in-Ocean token that are not unwrapped
     *  due to the mismatch between the external token's decimal basis and the
     *  Ocean's NORMALIZED_DECIMALS basis.
     */
    function _determineTransferAmount(uint256 amount, uint8 decimals)
        private
        pure
        returns (uint256 transferAmount, uint256 dust)
    {
        // if (decimals < 18), then converting 18-decimal amount to decimals
        // transferAmount will likely result in amount being truncated. This
        // case is most likely to occur when a user is wrapping a delta as the
        // final interaction in a transaction.
        uint256 truncated;

        (transferAmount, truncated) = _convertDecimals(
            NORMALIZED_DECIMALS,
            decimals,
            amount
        );

        if (truncated > 0) {
            // Here, FLOORish(x) is not to the nearest integer less than `x`,
            // but rather to the nearest value with `decimals` precision less
            // than `x`. Likewise with CEILish(x).
            // When truncating, transferAmount is FLOORish(amount), but to
            // fully cover a potential delta, we need to transfer CEILish(amount)
            // if truncated == 0, FLOORish(amount) == CEILish(amount)
            // When truncated > 0, FLOORish(amount) + 1 == CEILish(AMOUNT)
            transferAmount += 1;
            // Now that we are transferring enough to cover the delta, we
            // need to determine how much of the token the user is actually
            // wrapping, in terms of 18-decimals.
            (
                uint256 normalizedTransferAmount,
                uint256 normalizedTruncatedAmount
            ) = _convertDecimals(decimals, NORMALIZED_DECIMALS, transferAmount);
            // If we truncated earlier, converting the other direction is adding
            // precision, which cannot truncate.
            assert(normalizedTruncatedAmount == 0);
            assert(normalizedTransferAmount > amount);
            dust = normalizedTransferAmount - amount;
        } else {
            // if truncated == 0, then we don't need to do anything fancy to
            // determine transferAmount, the result _convertDecimals() returns
            // is correct.
            dust = 0;
        }
    }

    /**
     * @dev convert a uint256 from one fixed point decimal basis to another,
     *   returning the truncated amount if a truncation occurs.
     * @dev fn(from, to, a) => b
     * @dev a = (x * 10**from) => b = (x * 10**to), where x is constant.
     * @param amountToConvert the amount being converted
     * @param decimalsFrom the fixed decimal basis of amountToConvert
     * @param decimalsTo the fixed decimal basis of the returned convertedAmount
     * @return convertedAmount the amount after conversion
     * @return truncatedAmount if (from > to), there may be some truncation, it
     *  is up to the caller to decide what to do with the truncated amount.
     */
    function _convertDecimals(
        uint8 decimalsFrom,
        uint8 decimalsTo,
        uint256 amountToConvert
    ) internal pure returns (uint256 convertedAmount, uint256 truncatedAmount) {
        if (decimalsFrom == decimalsTo) {
            // no shift
            convertedAmount = amountToConvert;
            truncatedAmount = 0;
        } else if (decimalsFrom < decimalsTo) {
            // Decimal shift left (add precision)
            uint256 shift = 10**(uint256(decimalsTo - decimalsFrom));
            convertedAmount = amountToConvert * shift;
            truncatedAmount = 0;
        } else {
            // Decimal shift right (remove precision) -> truncation
            uint256 shift = 10**(uint256(decimalsFrom - decimalsTo));
            convertedAmount = amountToConvert / shift;
            truncatedAmount = amountToConvert % shift;
        }
    }

    /**
     * @dev Divides an amount by the unwrapFeeDivisor state variable to
     *  determine the amount to deduct from the unwrap.
     * @dev when unwrapFeeDivisor > unwrapAmount, feeCharged == 0 due to floor
     *  behavior of integer division
     * @param unwrapAmount the amount being unwrapped
     * @return feeCharged the amount to be deducted from the unwrapAmount and
     *  granted to the Ocean's owner.
     */
    function _calculateUnwrapFee(uint256 unwrapAmount)
        private
        view
        returns (uint256 feeCharged)
    {
        feeCharged = unwrapAmount / unwrapFeeDivisor;
    }

    /**
     * @dev Updates the DAO's balance of a token when the fee is assessed.
     * @dev We only call the mint function when the fee amount is non-zero.
     */
    function _grantFeeToOcean(uint256 oceanId, uint256 amount) private {
        if (amount > 0) {
            // since uint, same as (amount != 0)
            _mintWithoutSafeTransferAcceptanceCheck(owner(), oceanId, amount);
        }
    }
}