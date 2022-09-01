// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

// All solidity behavior related comments are in reference to this version of
// the solc compiler.
pragma solidity =0.8.10;

// OpenZeppelin ERC Interfaces
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// OpenZeppelin Utility Library
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// OpenZeppelin inherited contract
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity =0.8.10;

/**
 * @param interactionTypeAndAddress the type of interaction and the external
 *  contract called during this interaction.
 * @param inputToken this field is ignored except when the interaction type
 *  begins with "Compute".  During a "Compute" interaction, this token is given
 *  to the external contract.
 * @param outputToken this field is ignored except when the interaction type
 *  begins with "Compute".  During a "Compute" interaction, this token is
 *  received from the external contract.
 * @param specifiedAmount This value is the amount of the specified token.
 *  See the comment above the declaration for InteractionType for information
 *  on specified tokens.  When this value is equal to type(uint256).max, it is
 *  a request by the user to use the intra-transaction delta of the specified
 *  token as the specified amount.  See LibBalanceDelta for more information
 *  about this.  When the Ocean executes an interaction, it resolves the
 *  specifiedAmount before calling the external contract.  During a "721"
 *  interaction, the resolved specifiedAmount must be identically "1".
 * @param metadata This value is used in two ways.  During "Compute"
 *  interactions, it is forwarded to the external contract.  The external
 *  contract can define whatever expectations it wants for these 32 bytes.  The
 *  caller is expected to be aware of the expectations of the external contract
 *  invoked during the interaction.  During 721/1155 and wraps and unwraps,
 *  these bytes are cast to uint256 and used as the external ledger's token ID
 *  for the interaction.
 */
struct Interaction {
    bytes32 interactionTypeAndAddress;
    uint256 inputToken;
    uint256 outputToken;
    uint256 specifiedAmount;
    bytes32 metadata;
}

/**
 * InteractionType determines how the properties of Interaction are interpreted
 *
 * The interface implemented by the external contract, the specified token
 *  for the interaction, and what sign (+/-) of delta can be used are
 *  determined by the InteractionType.
 *
 * @param WrapErc20
 *      type(externalContract).interfaceId == IERC20
 *      specifiedToken == calculateOceanId(externalContract, 0)
 *      negative delta can be used as specifiedAmount
 *
 * @param UnwrapErc20
 *      type(externalContract).interfaceId == IERC20
 *      specifiedToken == calculateOceanId(externalContract, 0)
 *      positive delta can be used as specifiedAmount
 *
 * @param WrapErc721
 *      type(externalContract).interfaceId == IERC721
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      negative delta can be used as specifiedAmount
 *
 * @param UnwrapErc721
 *      type(externalContract).interfaceId == IERC721
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      positive delta can be used as specifiedAmount
 *
 * @param WrapErc1155
 *      type(externalContract).interfaceId == IERC1155
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      negative delta can be used as specifiedAmount
 *
 * @param WrapErc1155
 *      type(externalContract).interfaceId == IERC1155
 *      specifiedToken == calculateOceanId(externalContract, metadata)
 *      positive delta can be used as specifiedAmount
 *
 * @param ComputeInputAmount
 *      type(externalContract).interfaceId == IOceanexternalContract
 *      specifiedToken == outputToken
 *      negative delta can be used as specifiedAmount
 *
 * @param ComputeOutputAmount
 *      type(externalContract).interfaceId == IOceanexternalContract
 *      specifiedToken == inputToken
 *      positive delta can be used as specifiedAmount
 */
enum InteractionType {
    WrapErc20,
    UnwrapErc20,
    WrapErc721,
    UnwrapErc721,
    WrapErc1155,
    UnwrapErc1155,
    ComputeInputAmount,
    ComputeOutputAmount,
    UnwrapEther
}

interface IOceanInteractions {
    function doMultipleInteractions(
        Interaction[] calldata interactions,
        uint256[] calldata ids
    )
        external
        payable
        returns (
            uint256[] memory burnIds,
            uint256[] memory burnAmounts,
            uint256[] memory mintIds,
            uint256[] memory mintAmounts
        );

    function forwardedDoMultipleInteractions(
        Interaction[] calldata interactions,
        uint256[] calldata ids,
        address userAddress
    )
        external
        payable
        returns (
            uint256[] memory burnIds,
            uint256[] memory burnAmounts,
            uint256[] memory mintIds,
            uint256[] memory mintAmounts
        );

    function doInteraction(Interaction calldata interaction)
        external
        returns (
            uint256 burnId,
            uint256 burnAmount,
            uint256 mintId,
            uint256 mintAmount
        );

    function forwardedDoInteraction(
        Interaction calldata interaction,
        address userAddress
    )
        external
        returns (
            uint256 burnId,
            uint256 burnAmount,
            uint256 mintId,
            uint256 mintAmount
        );
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity =0.8.10;

/// @notice to be implemented by a contract that is the Ocean.owner()
interface IOceanFeeChange {
    function changeUnwrapFee(uint256 nextUnwrapFeeDivisor) external;
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity =0.8.10;

/// @notice Implementing this allows a primitive to be called by the Ocean's
///  defi framework.
interface IOceanPrimitive {
    function computeOutputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 inputAmount,
        address userAddress,
        bytes32 metadata
    ) external returns (uint256 outputAmount);

    function computeInputAmount(
        uint256 inputToken,
        uint256 outputToken,
        uint256 outputAmount,
        address userAddress,
        bytes32 metadata
    ) external returns (uint256 inputAmount);

    function getTokenSupply(uint256 tokenId)
        external
        view
        returns (uint256 totalSupply);
}

// SPDX-License-Identifier: MIT
// Cowri Labs Inc.

pragma solidity =0.8.10;

import {InteractionType} from "./Interactions.sol";

/**
 * A BalanceDelta structure tracks a user's intra-transaction balance change
 *  for a particular token
 * @param tokenId ID of the tracked token in the accounting system
 * @param delta a signed integer that records the user's accumulated debit
 *  or credit.
 *
 * Examples:
 * BalanceDelta positiveDelta = BalanceDelta(0xDE..AD, 100);
 * BalanceDelta negativeDelta = BalanceDelta(0xBE..EF, -100);
 *
 * At the end of the transaction the deltas are applied to the user's balances
 *  to persist the effects of the transaction.
 */
struct BalanceDelta {
    uint256 tokenId;
    int256 delta;
}

/**
 * @dev Functions relating to the intra-transaction accounting system.
 * @dev This library relies on the fact that arrays in solidity are passed by
 *  reference, rather than by value.
 *
 * `self` is an array of BalanceDelta structures.
 *
 * @dev each function uses a greedy linear search, so if there are duplicate
 *  deltas for the same tokenId, only the first delta is operated on. The
 *  duplicates will always have {tokenID: $DUPLICATE, delta: 0}.  If an tokenId
 *  is missing, the library functions will revert the transaction.  If there is
 *  an unecessary tokenId or a duplicated tokenId, the only consequence is
 *  wasted gas, so the incentive for the user is to provide the minimal set of
 *  tokenIds.
 *
 * Because the delta is a signed integer, it can be positive or negative.
 *
 * At the end of the transaction, positive deltas are minted to the user and
 *  negative deltas are burned from the user.  This is done using the ERC-1155's
 *  _mintBatch() and _burnBatch().  Each take an array of IDs and an array
 *  of amounts.  BalanceDelta => (ids[i], amounts[i])
 */
library LibBalanceDelta {
    /**
     * @dev a BalanceDelta holds an int256 delta while the caller passes
     *  a uint256.  We need to make sure the cast won't silently truncate
     *  the most significant bit.
     * @dev because solidity numbers are two's complement representation,
     *  the absolute value of the maximum value is one unit higher than the
     *  maximum value of the minimum value.  By testing against
     *  type(int256).max, we know that amount will safely cast to both positive
     *  and negative int256 values.
     */
    modifier safeCast(uint256 amount) {
        require(
            uint256(type(int256).max) > amount,
            "Delta :: amount > int256max"
        );
        _;
    }

    /**
     * @dev increase a given tokenId's delta by an amount.
     */
    function increaseBalanceDelta(
        BalanceDelta[] memory self,
        uint256 tokenId,
        uint256 amount
    ) internal pure safeCast(amount) {
        uint256 index = _findIndexOfTokenId(self, tokenId);
        self[index].delta += int256(amount);
        return;
    }

    /**
     * @dev decrease a given tokenId's delta by an amount.
     */
    function decreaseBalanceDelta(
        BalanceDelta[] memory self,
        uint256 tokenId,
        uint256 amount
    ) internal pure safeCast(amount) {
        uint256 index = _findIndexOfTokenId(self, tokenId);
        self[index].delta -= int256(amount);
        return;
    }

    /**
     * @dev This function returns an unsigned amount given a tokenId and an
     *  interaction type.
     * @dev This function reverts when the sign of the tokenId's delta
     *  does not match the sign expected by the interaction type.
     *
     *  - All interaction types expect unsigned amounts as arguments.
     *  - Some interaction types, like wraps, increase a user's balance.
     *  - Others, like unwraps, decrease a user's balance.
     *  - The interactions that increase a user's balance can take a negative
     *   delta as an input. In effect, the debit represented by the delta is
     *   offset by the credit from the interaction.
     *  - Similarly, interactions that decrease a user's balance can take
     *   a positive delta as an input.
     *  - When a delta is of the wrong sign for the interaction type, we need
     *   to revert the transaction.
     *
     * EXAMPLE 1. Convert 100 DAI into as many USDC as possible
     * [0]  BalanceDelta[] = [ BalanceDelta(DAI, 0), BalanceDelta(USDC, 0) ]
     *  wrap(token: DAI, amount: 100)
     * [1]  BalanceDelta[] = [ BalanceDelta(DAI, 100), BalanceDelta(USDC, 0) ]
     *  computeOutputAmount(input: DAI, output: USDC, amount: GET_BALANCE_DELTA)
     * [2]  BalanceDelta[] = [ BalanceDelta(DAI, 0), BalanceDelta(USDC, 99.997) ]
     *  unwrap(token: USDC, amount: GET_BALANCE_DELTA)
     *
     * EXAMPLE 2. Convert as few DAI as possible into exactly 100 USDC
     * [0]  BalanceDelta[] = [ BalanceDelta(DAI, 0), BalanceDelta(USDC, 0) ]
     *  unwrap(token: USDC, amount: 100)
     * [1]  BalanceDelta[] = [ BalanceDelta(DAI, 0), BalanceDelta(USDC, -100) ]
     *  computeInputAmount(input: DAI, output: USDC, amount: GET_BALANCE_DELTA)
     * [2]  BalanceDelta[] = [ BalanceDelta(DAI, -100.003), BalanceDelta(USDC, 0) ]
     *  wrap(token: DAI, amount: GET_BALANCE_DELTA)
     *
     * EXAMPLE 3. Unwrap DAI twice (reverts)
     * [0]  BalanceDelta[] = [ BalanceDelta(DAI, 0), ]
     *  unwrap(token: DAI, amount: 100)
     * [1]  BalanceDelta[] = [ BalanceDelta(DAI, -100), ]
     *  unwrap(token: DAI, amount: GET_BALANCE_DELTA)
     * !!! Throw("PosDelta :: amount < 0") !!!
     */
    function getBalanceDelta(
        BalanceDelta[] memory self,
        InteractionType interaction,
        uint256 tokenId
    ) internal pure returns (uint256) {
        if (
            interaction == InteractionType.UnwrapErc20 ||
            interaction == InteractionType.UnwrapErc721 ||
            interaction == InteractionType.UnwrapErc1155 ||
            interaction == InteractionType.UnwrapEther ||
            interaction == InteractionType.ComputeOutputAmount
        ) {
            return _getPositiveBalanceDelta(self, tokenId);
        } else {
            // interaction == (Wrap* || ComputeInputAmount)
            return _getNegativeBalanceDelta(self, tokenId);
        }
    }

    /**
     * @dev This function transforms the accumulated deltas into the arguments
     *  expected by ERC-1155 _mintBatch() and _burnBatch so that the caller
     *  can apply the deltas to the ledger.
     * @dev ERC-1155 expects an array of ids and an array of amounts, paired by
     *  index.
     *  +-------+-------+-----------+
     *  | index | ids[] | amounts[] |
     *  +-------+-------+-----------+
     *  |  0    |  808  |  35       | <= BalanceDelta(tokenId: 808, delta: 35)
     *  |  1    |  310  |  12       | <= BalanceDelta(tokenId: 310, delta: 12)
     *  |  2    |  408  |  19       | <= BalanceDelta(tokenId: 408, delta: 19)
     *  +-------+-------+-----------+
     * @dev Positive deltas are minted to the user's balances
     * @dev Negative deltas are burned from the user's balances
     * @dev for an entry where (delta == 0), nothing is done
     * @notice the returned arrays may be empty (arr.length == 0) or singleton
     *  arrays (arr.length == 1).
     * @return mintIds array of IDs expected by ERC-1155 _mintBatch
     * @return mintAmounts array of amounts expected by ERC-1155 _mintBatch
     * @return burnIds array of IDs expected by ERC-1155 _burnBatch
     * @return burnAmounts array of amounts expected by ERC-1155 _burnBatch
     */
    function createMintAndBurnArrays(BalanceDelta[] memory self)
        internal
        pure
        returns (
            uint256[] memory mintIds,
            uint256[] memory mintAmounts,
            uint256[] memory burnIds,
            uint256[] memory burnAmounts
        )
    {
        (uint256 numberOfMints, uint256 numberOfBurns) = _getMintsAndBurns(
            self
        );

        mintIds = new uint256[](numberOfMints);
        mintAmounts = new uint256[](numberOfMints);

        burnIds = new uint256[](numberOfBurns);
        burnAmounts = new uint256[](numberOfBurns);

        _copyDeltasToMintAndBurnArrays(
            self,
            mintIds,
            mintAmounts,
            burnIds,
            burnAmounts
        );
    }

    /**
     * @dev Count the number of positive deltas and the number of negative
     *  deltas among the accumulated deltas.
     * @dev The return values of this function are used to allocate memory
     *  arrays.  This function is necessary because in-memory arrays in
     *  solidity do not support push() and pop() style operations.
     * @return numberOfMints the number of positive deltas
     * @return numberOfBurns the number of negative deltas
     */
    function _getMintsAndBurns(BalanceDelta[] memory self)
        private
        pure
        returns (uint256 numberOfMints, uint256 numberOfBurns)
    {
        uint256 numberOfZeros = 0;
        for (uint256 i = 0; i < self.length; ++i) {
            int256 delta = self[i].delta;
            if (delta > 0) {
                ++numberOfMints;
            } else if (delta < 0) {
                ++numberOfBurns;
            } else {
                ++numberOfZeros;
            }
        }
        assert((numberOfMints + numberOfBurns + numberOfZeros) == self.length);
    }

    /**
     * @dev Now that we have allocated a pair of mint arrays and a pair of burn
     *  arrays, we iterate over the balance deltas again, this time moving the
     *  positive deltas, along with their assosciated tokenIds into the mints
     *  arrays, and moving the negative deltas and their assosciated tokenIds
     *  into the burns arrays.
     */
    function _copyDeltasToMintAndBurnArrays(
        BalanceDelta[] memory self,
        uint256[] memory mintIds,
        uint256[] memory mintAmounts,
        uint256[] memory burnIds,
        uint256[] memory burnAmounts
    ) private pure {
        uint256 mintsSoFar = 0;
        uint256 burnsSoFar = 0;
        for (uint256 i = 0; i < self.length; ++i) {
            int256 delta = self[i].delta;
            if (delta > 0) {
                mintIds[mintsSoFar] = self[i].tokenId;
                mintAmounts[mintsSoFar] = uint256(delta);
                mintsSoFar += 1;
            } else if (delta < 0) {
                burnIds[burnsSoFar] = self[i].tokenId;
                burnAmounts[burnsSoFar] = uint256(-delta);
                burnsSoFar += 1;
            }
        }
        assert(
            (mintsSoFar == mintIds.length) && (burnsSoFar == burnIds.length)
        );
    }

    /**
     * @dev returns a delta for a interaction type that expects a positive delta
     *
     * SteInterps that take a positive delta:
     *   Unwrap*
     *   ComputeOutputAmount
     */
    function _getPositiveBalanceDelta(
        BalanceDelta[] memory self,
        uint256 tokenId
    ) private pure returns (uint256) {
        uint256 index = _findIndexOfTokenId(self, tokenId);
        int256 amount = self[index].delta;
        require(amount >= 0, "PosDelta :: amount < 0");
        return uint256(amount);
    }

    /**
     * @dev returns a delta for a interaction type that expects a negative delta
     *
     * Interactions that take a negative delta:
     *   Wrap*
     *   ComputeInputAmount
     */
    function _getNegativeBalanceDelta(
        BalanceDelta[] memory self,
        uint256 tokenId
    ) private pure returns (uint256) {
        uint256 index = _findIndexOfTokenId(self, tokenId);
        int256 amount = self[index].delta;
        require(amount <= 0, "NegDelta :: amount > 0");
        return uint256(-amount);
    }

    /**
     @dev a linear search for the first BalanceDelta with a certain tokenId
     @param tokenId the key we're searching for
     @return index the location of the key
     */
    function _findIndexOfTokenId(BalanceDelta[] memory self, uint256 tokenId)
        private
        pure
        returns (uint256 index)
    {
        for (index = 0; index < self.length; ++index) {
            if (self[index].tokenId == tokenId) {
                return index;
            }
        }
        revert("Delta :: missing token ID");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC1155/ERC1155.sol)
// Cowri Labs, Inc., modifications licensed under: MIT

pragma solidity =0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// OpenZeppelin Inherited Contracts
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// ShellV2 Interface
import {IOceanToken} from "./IOceanToken.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 * @dev modifications include removing unused hooks, creating a minting
 *  function that does not do a safeTransferAcceptanceCheck, and adding a
 *  mapping and functions to register and manage authority over tokens.
 * @dev Registered Tokens are Ocean-native issuances, such as Liquidity
 *  Provider tokens issued by an AMM built on top of the Ocean.
 */
contract OceanERC1155 is
    Context,
    ERC165,
    IERC1155,
    IERC1155MetadataURI,
    IOceanToken,
    ReentrancyGuard
{
    using Address for address;

    /// @notice EIP-712 Ethereum typed structured data hashing and signing
    bytes32 public immutable DOMAIN_SEPARATOR;
    bytes32 public immutable SETPERMITFORALL_TYPEHASH;

    /// @notice Mapping from token ID to address with authority over token's issuance
    mapping(uint256 => address) public tokensToPrimitives;

    /// @notice Nonces used for EIP-2612 sytle permits
    mapping(address => uint256) public approvalNonces;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    event NewTokensRegistered(
        address indexed creator,
        uint256[] tokens,
        uint256[] nonces
    );

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("shell-protocol-ocean")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
        SETPERMITFORALL_TYPEHASH = keccak256(
            "SetPermitForAll(address owner,address operator,bool approved,uint256 nonce,uint256 deadline)"
        );
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(account != address(0), "balanceOf(address(0))");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "accounts.length != ids.length");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function setPermitForAll(
        address owner,
        address operator,
        bool approved,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp);
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        SETPERMITFORALL_TYPEHASH,
                        owner,
                        operator,
                        approved,
                        approvalNonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner);
        _setApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override nonReentrant {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Registered Tokens are tokens issued directly on the ocean's 1155 ledger.
     * @dev These are tokens that cannot be wrapped or unwrapped.
     * @dev We don't validate the inputs.  The happy path usage is for callers
     *  to obtain authority over tokens that have their ids derived from
     *  successive nonces.
     *
     *  registerNewTokens(0, n):
     *      _calculateOceanId(caller, 0)
     *      _calculateOceanId(caller, 1)
     *      ...
     *      _calculateOceanId(caller, n)
     *
     *  Since the ocean tracks the one to one relationship of:
     *    token => authority
     *  but not the one to many relationship of:
     *    authority => tokens
     *  it is nice UX to be able to re-derive the tokens on the fly from the
     *  authority's address and successive (predictable) nonces are used.
     *
     *  However, if the caller wants to use this interface in a different way,
     *  they could easily make a call like:
     *  registerNewTokens($SOME_NUMBER, 1); to use $SOME_NUMBER
     *  as the nonce.  A user could request to buy an in-ocean nft with a
     *  specific seed value, and the external contract gains authority over
     *  this id on the fly in order to sell it.
     *
     *  If the caller tries to reassert authority over a token they've already
     *  registered, they just waste gas.  If a caller expects to create
     *  new tokens over time, it should track how many tokens it has already
     *  created
     * @dev the guiding philosophy is to track only essential information in
     *  the Ocean's state, and let users (both EOAs and contracts) track other
     *  information as they see fit.
     * @param currentNumberOfTokens the starting nonce
     * @param numberOfAdditionalTokens the number of new tokens registered
     * @return oceanIds Ocean IDs of the tokens the caller now has authority over
     */
    function registerNewTokens(
        uint256 currentNumberOfTokens,
        uint256 numberOfAdditionalTokens
    ) external override returns (uint256[] memory oceanIds) {
        oceanIds = new uint256[](numberOfAdditionalTokens);
        uint256[] memory nonces = new uint256[](numberOfAdditionalTokens);

        for (uint256 i = 0; i < numberOfAdditionalTokens; ++i) {
            uint256 tokenNonce = currentNumberOfTokens + i;
            uint256 newToken = _calculateOceanId(msg.sender, tokenNonce);
            nonces[i] = tokenNonce;
            oceanIds[i] = newToken;
            tokensToPrimitives[newToken] = msg.sender;
        }
        emit NewTokensRegistered(msg.sender, oceanIds, nonces);
    }

    /**
     * @dev returns true when a primitive did NOT register an ID
     *
     * Used  to determine if the Ocean needs to explicitly mint/burn tokens
     *  balance a transaction.
     */
    function _isNotTokenOfPrimitive(uint256 oceanId, address primitive)
        internal
        view
        returns (bool)
    {
        return (tokensToPrimitives[oceanId] != primitive);
    }

    /**
     * @dev calculates a collision-resistant token ID
     *
     * OceanIds are derived from their origin. The origin can be:
     *  - ERC20 contracts that have their token wrapped into the ocean
     *  - ERC721 contracts that have tokens with IDs wrapped into the ocean
     *  - ERC1155 contracts that have tokens with IDs wrapped into the ocean
     *  - Contracts that issue Ocean-native tokens
     *      When a contract registers a new token, the token has an associated
     *      nonce, which functions just like an ERC721 or ERC1155 token ID.
     *
     * The oceanId is calculated by using the contract address of the origin
     *      and the relevant ID.  For ERC20 tokens, the ID is always 0.
     */
    function _calculateOceanId(address tokenContract, uint256 tokenId)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(tokenContract, tokenId)));
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "transfer to the zero address");

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "insufficient balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ids.length != amounts.length");
        require(to != address(0), "transfer to the zero address");

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "insufficient balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - Should only be called by
     *      - _mint(...)
     *      - LiquidityOcean._computeOutputAmount(...)
     *      - LiquidityOcean._computeInputAmount(...)
     *      - LiquidityOcean._grantFeeToOcean(...)
     *
     * - When called by _mint(...) this function complies with the ERC-1155 spec
     * - When called by the LiquidityOcean functions, this function breaks the
     *      ERC-1155 spec deliberately.  The contract that is the target of a
     *      compute*() call can revert the transaction if it does not want to
     *      receive the tokens, so the safeTransferAcceptanceCheck is redundant.
     *      The address receiving the fees (immutable DAO) is required to handle
     *      receiving fees without a safeTransferCheck.  By avoiding an SLOAD
     *      and an external call during the fee assignment, we save users gas.
     */
    function _mintWithoutSafeTransferAcceptanceCheck(
        address to,
        uint256 id,
        uint256 amount
    ) internal returns (address) {
        address operator = _msgSender();

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        return operator;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount
    ) internal virtual {
        assert(to != address(0));

        address operator = _mintWithoutSafeTransferAcceptanceCheck(
            to,
            id,
            amount
        );

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            id,
            amount,
            ""
        );
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        assert(to != address(0));
        assert(ids.length == amounts.length);

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            address(0),
            to,
            ids,
            amounts,
            ""
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        assert(from != address(0));

        address operator = _msgSender();

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        assert(from != address(0));
        assert(ids.length == amounts.length);

        address operator = _msgSender();

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "Set approval for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155Receiver rejected");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("non-ERC1155Receiver");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155Receiver(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response != IERC1155Receiver.onERC1155BatchReceived.selector
                ) {
                    revert("ERC1155Receiver rejected");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("non-ERC1155Receiver");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: unlicensed
// Cowri Labs Inc.

pragma solidity =0.8.10;

/**
 * @title Interface for external contracts that issue tokens on the Ocean's
 *  public multitoken ledger
 * @dev Implemented by OceanERC1155.
 */
interface IOceanToken {
    function registerNewTokens(
        uint256 currentNumberOfTokens,
        uint256 numberOfAdditionalTokens
    ) external returns (uint256[] memory);
}