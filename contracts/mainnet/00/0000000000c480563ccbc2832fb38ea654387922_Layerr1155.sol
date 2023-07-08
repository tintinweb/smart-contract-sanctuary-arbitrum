// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {AddressValue} from "../lib/StorageTypes.sol";
import {IOwnable} from "../interfaces/IOwnable.sol";
import {LAYERROWNABLE_OWNER_SLOT, LAYERROWNABLE_NEW_OWNER_SLOT} from "./LayerrStorage.sol";

/**
 * @title LayerrOwnable
 * @author 0xth0mas (Layerr)
 * @notice ERC173 compliant ownership interface with two-step transfer/acceptance.
 * @dev LayerrOwnable uses two custom storage slots for current contract owner and new owner as defined in LayerrStorage.
 */
contract LayerrOwnable is IOwnable {
    modifier onlyOwner() {
        if (msg.sender != _getOwner()) {
            revert NotContractOwner();
        }
        _;
    }

    modifier onlyNewOwner() {
        if (msg.sender != _getNewOwner()) {
            revert NotContractOwner();
        }
        _;
    }

    /**
     * @notice Returns the current contract owner
     */
    function owner() external view returns(address _owner) {
        _owner = _getOwner();
    }

    /**
     * @notice Begins first step of ownership transfer. _newOwner will need to call acceptTransfer() to complete.
     * @param _newOwner address to transfer ownership of contract to
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        _setNewOwner(_newOwner);
    }

    /**
     * @notice Second step of ownership transfer called by the new contract owner.
     */
    function acceptTransfer() external onlyNewOwner {
        address _previousOwner = _getOwner();

        //set contract owner to new owner, clear out the newOwner value
        _setOwner(_getNewOwner());
        _setNewOwner(address(0));

        emit OwnershipTransferred(_previousOwner, _getOwner());
    }

    /**
     * @notice Cancels ownership transfer to newOwner before the transfer is accepted.
     */
    function cancelTransfer() external onlyOwner {
        _setNewOwner(address(0));
    }

    /**
     * @notice EIP165 supportsInterface for introspection
     */
    function supportsInterface(bytes4 interfaceID) public view virtual returns (bool) {
        return interfaceID == 0x7f5828d0;
    }

    /** INTERNAL FUNCTIONS */

    /**
     * @dev Internal helper function to load custom storage slot address value
     */
    function _getOwner() internal view returns(address _owner) {
        AddressValue storage ownerValue;
        /// @solidity memory-safe-assembly
        assembly {
            ownerValue.slot := LAYERROWNABLE_OWNER_SLOT
        }
        _owner = ownerValue.value;
    }

    /**
     * @dev Internal helper function to set owner address in custom storage slot
     */
    function _setOwner(address _owner) internal {
        AddressValue storage ownerValue;
        /// @solidity memory-safe-assembly
        assembly {
            ownerValue.slot := LAYERROWNABLE_OWNER_SLOT
        }
        ownerValue.value = _owner;
    }

    /**
     * @dev Internal helper function to load custom storage slot address value
     */
    function _getNewOwner() internal view returns(address _newOwner) {
        AddressValue storage newOwnerValue;
        /// @solidity memory-safe-assembly
        assembly {
            newOwnerValue.slot := LAYERROWNABLE_NEW_OWNER_SLOT
        }
        _newOwner = newOwnerValue.value;
    }

    /**
     * @dev Internal helper function to set new owner address in custom storage slot
     */
    function _setNewOwner(address _newOwner) internal {
        AddressValue storage newOwnerValue;
        /// @solidity memory-safe-assembly
        assembly {
            newOwnerValue.slot := LAYERROWNABLE_NEW_OWNER_SLOT
        }
        newOwnerValue.value = _newOwner;
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Storage slot for current owner calculated from keccak256('Layerr.LayerrOwnable.owner')
bytes32 constant LAYERROWNABLE_OWNER_SLOT = 0xedc628ad38a73ae7d50600532f1bf21da1bfb1390b4f8174f361aca54d4c6b66;

/// @dev Storage slot for pending ownership transfer calculated from keccak256('Layerr.LayerrOwnable.newOwner')
bytes32 constant LAYERROWNABLE_NEW_OWNER_SLOT = 0x15c115ab76de082272ae65126522082d4aad634b6478097549f84086af3b84bc;

/// @dev Storage slot for token name calculated from keccak256('Layerr.LayerrToken.name')
bytes32 constant LAYERRTOKEN_NAME_SLOT = 0x7f84c61ed30727f282b62cab23f49ac7f4d263f04a4948416b7b9ba7f34a20dc;

/// @dev Storage slot for token symbol calculated from keccak256('Layerr.LayerrToken.symbol')
bytes32 constant LAYERRTOKEN_SYMBOL_SLOT = 0xdc0f2363b26c589c72caecd2357dae5fee235863060295a057e8d69d61a96d8a;

/// @dev Storage slot for URI renderer calculated from keccak256('Layerr.LayerrToken.renderer')
bytes32 constant LAYERRTOKEN_RENDERER_SLOT = 0x395b7021d979c3dbed0f5d530785632316942232113ba3dbe325dc167550e320;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. 
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr1155
 * @author 0xth0mas (Layerr)
 * @notice ILayerr1155 interface defines functions required in an ERC1155 token contract to callable by the LayerrMinter contract.
 */
interface ILayerr1155 {

    /**
     * @notice Mints tokens to the recipients, each recipient gets the corresponding tokenId in the `tokenIds` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @dev `recipients`, `tokenIds` and `amounts` arrays must be equal length, each recipient will receive the corresponding 
     *      tokenId and amount from the `tokenIds` and `amounts` arrays
     * @param recipients addresses to airdrop tokens to
     * @param tokenIds ids of tokens to be airdropped to recipients
     * @param amounts amounts of tokens to be airdropped to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds, uint256[] calldata amounts) external;

    /**
     * @notice Mints `amount` of `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenId id of the token to mint
     * @param amount amount of token to mint
     */
    function mintTokenId(address minter, address to, uint256 tokenId, uint256 amount) external;

    /**
     * @notice Mints `amount` of `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenIds array of ids to mint
     * @param amounts array of amounts to mint
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     * @param amount amount of `tokenId` to burn from `from`
     */
    function burnTokenId(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenIds array of token ids to be burned
     * @param amounts array of amounts to burn from `from`
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external;

    /**
     * @notice Emits URI event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC1155 tokens in circulation for given `id`.
     * @param id the token id to check total supply of
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @param id the token id to check number of tokens minted for
     * @return totalMinted total number of ERC1155 tokens for given `id` minted since token launch
     * @return minterMinted total number of ERC1155 tokens for given `id` minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter, uint256 id) external view returns(uint256 totalMinted, uint256 minterMinted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "../lib/MinterStructs.sol";

/**
 * @title ILayerrMinter
 * @author 0xth0mas (Layerr)
 * @notice ILayerrMinter interface defines functions required in the LayerrMinter to be callable by token contracts
 */
interface ILayerrMinter {

    /// @dev Event emitted when a mint order is fulfilled
    event MintOrderFulfilled(
        bytes32 indexed mintParametersDigest,
        address indexed minter,
        uint256 indexed quantity
    );

    /// @dev Event emitted when a token contract updates an allowed signer for EIP712 signatures
    event ContractAllowedSignerUpdate(
        address indexed _contract,
        address indexed _signer,
        bool indexed _allowed
    );

    /// @dev Event emitted when a token contract updates an allowed oracle signer for offchain authorization of a wallet to use a signature
    event ContractOracleUpdated(
        address indexed _contract,
        address indexed _oracle,
        bool indexed _allowed
    );

    /// @dev Event emitted when a signer updates their nonce with LayerrMinter. Updating a nonce invalidates all previously signed EIP712 signatures.
    event SignerNonceIncremented(
        address indexed _signer,
        uint256 indexed _nonce
    );

    /// @dev Event emitted when a specific signature's validity is updated with the LayerrMinter contract.
    event SignatureValidityUpdated(
        address indexed _contract,
        bool indexed invalid,
        bytes32 mintParametersDigests
    );

    /// @dev Thrown when the amount of native tokens supplied in msg.value is insufficient for the mint order
    error InsufficientPayment();

    /// @dev Thrown when a payment fails to be forwarded to the intended recipient
    error PaymentFailed();

    /// @dev Thrown when a MintParameters payment token uses a token type value other than native or ERC20
    error InvalidPaymentTokenType();

    /// @dev Thrown when a MintParameters burn token uses a token type value other than ERC20, ERC721 or ERC1155
    error InvalidBurnTokenType();

    /// @dev Thrown when a MintParameters mint token uses a token type value other than ERC20, ERC721 or ERC1155
    error InvalidMintTokenType();

    /// @dev Thrown when a MintParameters burn token uses a burn type value other than contract burn or send to dead
    error InvalidBurnType();

    /// @dev Thrown when a MintParameters burn token requires a specific burn token id and the tokenId supplied does not match
    error InvalidBurnTokenId();

    /// @dev Thrown when a MintParameters burn token requires a specific ERC721 token and the burn amount is greater than 1
    error CannotBurnMultipleERC721WithSameId();

    /// @dev Thrown when attempting to mint with MintParameters that have a start time greater than the current block time
    error MintHasNotStarted();

    /// @dev Thrown when attempting to mint with MintParameters that have an end time less than the current block time
    error MintHasEnded();

    /// @dev Thrown when a MintParameters has a merkleroot set but the supplied merkle proof is invalid
    error InvalidMerkleProof();

    /// @dev Thrown when a MintOrder will cause a token's minted supply to exceed the defined maximum supply in MintParameters
    error MintExceedsMaxSupply();

    /// @dev Thrown when a MintOrder will cause a minter's minted amount to exceed the defined max per wallet in MintParameters
    error MintExceedsMaxPerWallet();

    /// @dev Thrown when a MintParameters mint token has a specific ERC721 token and the mint amount is greater than 1
    error CannotMintMultipleERC721WithSameId();

    /// @dev Thrown when the recovered signer for the MintParameters is not an allowed signer for the mint token
    error NotAllowedSigner();

    /// @dev Thrown when the recovered signer's nonce does not match the current nonce in LayerrMinter
    error SignerNonceInvalid();

    /// @dev Thrown when a signature has been marked as invalid for a mint token contract
    error SignatureInvalid();

    /// @dev Thrown when MintParameters requires an oracle signature and the recovered signer is not an allowed oracle for the contract
    error InvalidOracleSignature();

    /// @dev Thrown when MintParameters has a max signature use set and the MintOrder will exceed the maximum uses
    error ExceedsMaxSignatureUsage();

    /// @dev Thrown when attempting to increment nonce on behalf of another account and the signature is invalid
    error InvalidSignatureToIncrementNonce();

    /**
     * @notice This function is called by token contracts to update allowed signers for minting
     * @param _signer address of the EIP712 signer
     * @param _allowed if the `_signer` is allowed to sign for minting
     */
    function setContractAllowedSigner(address _signer, bool _allowed) external;

    /**
     * @notice This function is called by token contracts to update allowed oracles for offchain authorizations
     * @param _oracle address of the oracle
     * @param _allowed if the `_oracle` is allowed to sign offchain authorizations
     */
    function setContractAllowedOracle(address _oracle, bool _allowed) external;

    /**
     * @notice This function is called by token contracts to update validity of signatures for the LayerrMinter contract
     * @dev `invalid` should be true to invalidate signatures, the default state of `invalid` being false means 
     *      a signature is valid for a contract assuming all other conditions are met
     * @param mintParametersDigests an array of message digests for MintParameters to update validity of
     * @param invalid if the supplied digests will be marked as valid or invalid
     */
    function setSignatureValidity(
        bytes32[] calldata mintParametersDigests,
        bool invalid
    ) external;

    /**
     * @notice Increments the nonce for a signer to invalidate all previous signed MintParameters
     */
    function incrementSignerNonce() external;

    /**
     * @notice Increments the nonce on behalf of another account by validating a signature from that account
     * @dev The signature is an eth personal sign message of the current signer nonce plus the chain id
     *      ex. current nonce 0 on chain 5 would be a signature of \x19Ethereum Signed Message:\n15
     *          current nonce 50 on chain 1 would be a signature of \x19Ethereum Signed Message:\n251
     * @param signer account to increment nonce for
     * @param signature signature proof that the request is coming from the account
     */
    function incrementNonceFor(address signer, bytes calldata signature) external;

    /**
     * @notice Validates and processes a single MintOrder, tokens are minted to msg.sender
     * @param mintOrder struct containing the details of the mint order
     */
    function mint(
        MintOrder calldata mintOrder
    ) external payable;

    /**
     * @notice Validates and processes an array of MintOrders, tokens are minted to msg.sender
     * @param mintOrders array of structs containing the details of the mint orders
     */
    function mintBatch(
        MintOrder[] calldata mintOrders
    ) external payable;

    /**
     * @notice Validates and processes a single MintOrder, tokens are minted to `mintToWallet`
     * @param mintToWallet the address tokens will be minted to
     * @param mintOrder struct containing the details of the mint order
     * @param paymentContext Contextual information related to the payment process
     *                     (Note: This parameter is required for integration with 
     *                     the payment processor and does not impact the behavior 
     *                     of the function)
     */
    function mintTo(
        address mintToWallet,
        MintOrder calldata mintOrder,
        uint256 paymentContext
    ) external payable;

    /**
     * @notice Validates and processes an array of MintOrders, tokens are minted to `mintToWallet`
     * @param mintToWallet the address tokens will be minted to
     * @param mintOrders array of structs containing the details of the mint orders
     * @param paymentContext Contextual information related to the payment process
     *                     (Note: This parameter is required for integration with 
     *                     the payment processor and does not impact the behavior 
     *                     of the function)
     */
    function mintBatchTo(
        address mintToWallet,
        MintOrder[] calldata mintOrders,
        uint256 paymentContext
    ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165} from "./IERC165.sol";

/**
 * @title ILayerrRenderer
 * @author 0xth0mas (Layerr)
 * @notice ILayerrRenderer interface defines functions required in LayerrRenderer to be callable by token contracts
 */
interface ILayerrRenderer is ERC165 {

    enum RenderType {
        LAYERR_HOSTED,
        PREREVEAL,
        BASE_PLUS_TOKEN
    }

    /// @dev Thrown when a payment fails for Layerr-hosted IPFS
    error PaymentFailed();

    /// @dev Thrown when a call is made for an owner-function by a non-contract owner
    error NotContractOwner();

    /// @dev Thrown when a signature is not made by the authorized account
    error InvalidSignature();

    /**
     * @notice Generates a tokenURI for the `contractAddress` and `tokenId`
     * @param contractAddress token contract address to render a token URI for
     * @param tokenId token id to render
     * @return uri for the token metadata
     */
    function tokenURI(
        address contractAddress,
        uint256 tokenId
    ) external view returns (string memory);

    /**
     * @notice Generates a contractURI for the `contractAddress`
     * @param contractAddress contract address to render a contract URI for
     * @return uri for the contract metadata
     */
    function contractURI(
        address contractAddress
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerrToken
 * @author 0xth0mas (Layerr)
 * @notice ILayerrToken interface defines functions required to be supported by the Layerr platform
 */
interface ILayerrToken {

    /// @dev Emitted when the contract is deployed so that it can be indexed and assigned to its owner
    event LayerrContractDeployed();

    /// @dev Emitted when a mint extension is updated to allowed or disallowed
    event MintExtensionUpdated(address mintExtension, bool allowed);

    /// @dev Emitted when the contract's renderer is updated
    event RendererUpdated(address renderer);

    /// @dev Thrown when a caller that is not a mint extension attempts to execute a mint function
    error NotValidMintingExtension();

    /// @dev Thrown when a non-owner attempts to execute an only owner function
    error NotAuthorized();

    /// @dev Thrown when attempting to withdraw funds from the contract and the call fails
    error WithdrawFailed();

    /**
     * @return name the name of the token
     */
    function name() external view returns(string memory);

    /**
     * @return symbol the token symbol
     */
    function symbol() external view returns(string memory);

    /**
     * @return renderer the address that will render token/contract URIs
     */
    function renderer() external view returns(address);
    
    /**
     * @notice Sets the renderer for token/contract URIs
     * @dev This function should be restricted to contract owners
     * @param _renderer address to set as the token/contract URI renderer
     */
    function setRenderer(address _renderer) external;

    /**
     * @notice Sets whether or not an address is allowed to call minting functions
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param _allowed if the mint extension is allowed to mint tokens
     */
    function setMintExtension(
        address _extension,
        bool _allowed
    ) external;

    /**
     * @notice This function calls the mint extension to update `_signer`'s allowance
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param _signer address of the signer to update
     * @param _allowed if `_signer` is allowed to sign for `_extension`
     */
    function setContractAllowedSigner(
        address _extension,
        address _signer,
        bool _allowed
    ) external;

    /**
     * @notice This function calls the mint extension to update `_oracle`'s allowance
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param _oracle address of the oracle to update
     * @param _allowed if `_oracle` is allowed to sign for `_extension`
     */
    function setContractAllowedOracle(
        address _extension,
        address _oracle,
        bool _allowed
    ) external;

    /**
     * @notice This function calls the mint extension to update signature validity
     * @dev This function should be restricted to contract owners
     * @param _extension address of the mint extension to update
     * @param signatureDigests hash digests of signatures parameters to update
     * @param invalid true if the signature digests should be marked as invalid
     */
    function setSignatureValidity(
        address _extension,
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external;

    /**
     * @notice This function updates the ERC2981 royalty percentages
     * @dev This function should be restricted to contract owners
     * @param pct royalty percentage in BPS
     * @param royaltyReciever address to receive royalties
     */
    function setRoyalty(
        uint96 pct,
        address royaltyReciever
    ) external;

    /**
     * @notice This function updates the token contract's name and symbol
     * @dev This function should be restricted to contract owners
     * @param _name new name for the token contract
     * @param _symbol new symbol for the token contract
     */
    function editContract(
        string calldata _name,
        string calldata _symbol
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC165} from './IERC165.sol';

interface IOwnable is ERC165 {

    /// @dev Thrown when a non-owner is attempting to perform an owner function
    error NotContractOwner();

    /// @dev Emitted when contract ownership is transferred to a new owner
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner    
    /// @return The address of the owner.
    function owner() view external returns(address);
	
    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract    
    function transferOwnership(address _newOwner) external;	
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple ERC2981 NFT Royalty Standard implementation.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC2981.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/common/ERC2981.sol)
abstract contract ERC2981 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The royalty fee numerator exceeds the fee denominator.
    error RoyaltyOverflow();

    /// @dev The royalty receiver cannot be the zero address.
    error RoyaltyReceiverIsZeroAddress();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The default royalty info is given by:
    /// ```
    ///     let packed := sload(_ERC2981_MASTER_SLOT_SEED)
    ///     let receiver := shr(96, packed)
    ///     let royaltyFraction := xor(packed, shl(96, receiver))
    /// ```
    ///
    /// The per token royalty info is given by.
    /// ```
    ///     mstore(0x00, tokenId)
    ///     mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
    ///     let packed := sload(keccak256(0x00, 0x40))
    ///     let receiver := shr(96, packed)
    ///     let royaltyFraction := xor(packed, shl(96, receiver))
    /// ```
    uint256 private constant _ERC2981_MASTER_SLOT_SEED = 0xaa4ec00224afccfdb7;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          ERC2981                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Checks that `_feeDenominator` is non-zero.
    constructor() {
        require(_feeDenominator() != 0, "Fee denominator cannot be zero.");
    }

    /// @dev Returns the denominator for the royalty amount.
    /// Defaults to 10000, which represents fees in basis points.
    /// Override this function to return a custom amount if needed.
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /// @dev Returns true if this contract implements the interface defined by `interfaceId`.
    /// See: https://eips.ethereum.org/EIPS/eip-165
    /// This function call must use less than 30000 gas.
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool result) {
        /// @solidity memory-safe-assembly
        assembly {
            let s := shr(224, interfaceId)
            // ERC165: 0x01ffc9a7, ERC2981: 0x2a55205a.
            result := or(eq(s, 0x01ffc9a7), eq(s, 0x2a55205a))
        }
    }

    /// @dev Returns the `receiver` and `royaltyAmount` for `tokenId` sold at `salePrice`.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        virtual
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 feeDenominator = _feeDenominator();
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
            let packed := sload(keccak256(0x00, 0x40))
            receiver := shr(96, packed)
            if iszero(receiver) {
                packed := sload(mload(0x20))
                receiver := shr(96, packed)
            }
            let x := salePrice
            let y := xor(packed, shl(96, receiver)) // `feeNumerator`.
            // Overflow check, equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            // Out-of-gas revert. Should not be triggered in practice, but included for safety.
            returndatacopy(returndatasize(), returndatasize(), mul(y, gt(x, div(not(0), y))))
            royaltyAmount := div(mul(x, y), feeDenominator)
        }
    }

    /// @dev Sets the default royalty `receiver` and `feeNumerator`.
    ///
    /// Requirements:
    /// - `receiver` must not be the zero address.
    /// - `feeNumerator` must not be greater than the fee denominator.
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        uint256 feeDenominator = _feeDenominator();
        /// @solidity memory-safe-assembly
        assembly {
            feeNumerator := shr(160, shl(160, feeNumerator))
            if gt(feeNumerator, feeDenominator) {
                mstore(0x00, 0x350a88b3) // `RoyaltyOverflow()`.
                revert(0x1c, 0x04)
            }
            let packed := shl(96, receiver)
            if iszero(packed) {
                mstore(0x00, 0xb4457eaa) // `RoyaltyReceiverIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            sstore(_ERC2981_MASTER_SLOT_SEED, or(packed, feeNumerator))
        }
    }

    /// @dev Sets the default royalty `receiver` and `feeNumerator` to zero.
    function _deleteDefaultRoyalty() internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_ERC2981_MASTER_SLOT_SEED, 0)
        }
    }

    /// @dev Sets the royalty `receiver` and `feeNumerator` for `tokenId`.
    ///
    /// Requirements:
    /// - `receiver` must not be the zero address.
    /// - `feeNumerator` must not be greater than the fee denominator.
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator)
        internal
        virtual
    {
        uint256 feeDenominator = _feeDenominator();
        /// @solidity memory-safe-assembly
        assembly {
            feeNumerator := shr(160, shl(160, feeNumerator))
            if gt(feeNumerator, feeDenominator) {
                mstore(0x00, 0x350a88b3) // `RoyaltyOverflow()`.
                revert(0x1c, 0x04)
            }
            let packed := shl(96, receiver)
            if iszero(packed) {
                mstore(0x00, 0xb4457eaa) // `RoyaltyReceiverIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, tokenId)
            mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
            sstore(keccak256(0x00, 0x40), or(packed, feeNumerator))
        }
    }

    /// @dev Sets the royalty `receiver` and `feeNumerator` for `tokenId` to zero.
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, tokenId)
            mstore(0x20, _ERC2981_MASTER_SLOT_SEED)
            sstore(keccak256(0x00, 0x40), 0)
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/**
 * @dev EIP712 Domain for signature verification
 */
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

/**
 * @dev MintOrders contain MintParameters as defined by a token creator
 *      along with proofs required to validate the MintParameters and 
 *      parameters specific to the mint being performed.
 * 
 *      `mintParameters` are the parameters signed by the token creator
 *      `quantity` is a multiplier for mintTokens, burnTokens and paymentTokens
 *          defined in mintParameters
 *      `mintParametersSignature` is the signature from the token creator
 *      `oracleSignature` is a signature of the hash of the mintParameters digest 
 *          and msg.sender. The recovered signer must be an allowed oracle for 
 *          the token contract if oracleSignatureRequired is true for mintParameters.
 *      `merkleProof` is the proof that is checked if merkleRoot is not bytes(0) in
 *          mintParameters
 *      `suppliedBurnTokenIds` is an array of tokenIds to be used when processing
 *          burnTokens. There must be one item in the array for each ERC1155 burnToken
 *          regardless of `quantity` and `quantity` items in the array for each ERC721
 *          burnToken.
 *      `referrer` is the address that will receive a portion of a paymentToken if
 *          not address(0) and paymentToken's referralBPS is greater than 0
 *      `vaultWallet` is used for allowlist mints if the msg.sender address it not on
 *          the allowlist but their delegate.cash vault wallet is.
 *      
 */
struct MintOrder {
    MintParameters mintParameters;
    uint256 quantity;
    bytes mintParametersSignature;
    bytes oracleSignature;
    bytes32[] merkleProof;
    uint256[] suppliedBurnTokenIds;
    address referrer;
    address vaultWallet;
}

/**
 * @dev MintParameters define the tokens to be minted and conditions that must be met
 *      for the mint to be successfully processed.
 * 
 *      `mintTokens` is an array of tokens that will be minted
 *      `burnTokens` is an array of tokens required to be burned
 *      `paymentTokens` is an array of tokens required as payment
 *      `startTime` is the UTC timestamp of when the mint will start
 *      `endTime` is the UTC timestamp of when the mint will end
 *      `signatureMaxUses` limits the number of mints that can be performed with the
 *          specific mintParameters/signature
 *      `merkleRoot` is the root of the merkletree for allowlist minting
 *      `nonce` is the signer nonce that can be incremented on the LayerrMinter 
 *          contract to invalidate all previous signatures
 *      `oracleSignatureRequired` if true requires a secondary signature to process the mint
 */
struct MintParameters {
    MintToken[] mintTokens;
    BurnToken[] burnTokens;
    PaymentToken[] paymentTokens;
    uint256 startTime;
    uint256 endTime;
    uint256 signatureMaxUses;
    bytes32 merkleRoot;
    uint256 nonce;
    bool oracleSignatureRequired;
}

/**
 * @dev Defines the token that will be minted
 *      
 *      `contractAddress` address of contract to mint tokens from
 *      `specificTokenId` used for ERC721 - 
 *          if true, mint is non-sequential ERC721
 *          if false, mint is sequential ERC721A
 *      `tokenType` is the type of token being minted defined in TokenTypes.sol
 *      `tokenId` the tokenId to mint if specificTokenId is true
 *      `mintAmount` is the quantity to be minted
 *      `maxSupply` is checked against the total minted amount at time of mint
 *          minting reverts if `mintAmount` * `quantity` will cause total minted to 
 *          exceed `maxSupply`
 *      `maxMintPerWallet` is checked against the number minted for the wallet
 *          minting reverts if `mintAmount` * `quantity` will cause wallet minted to 
 *          exceed `maxMintPerWallet`
 */
struct MintToken {
    address contractAddress;
    bool specificTokenId;
    uint256 tokenType;
    uint256 tokenId;
    uint256 mintAmount;
    uint256 maxSupply;
    uint256 maxMintPerWallet;
}

/**
 * @dev Defines the token that will be burned
 *      
 *      `contractAddress` address of contract to burn tokens from
 *      `specificTokenId` specifies if the user has the option of choosing any token
 *          from the contract or if they must burn a specific token
 *      `tokenType` is the type of token being burned, defined in TokenTypes.sol
 *      `burnType` is the type of burn to perform, burn function call or transfer to 
 *          dead address, defined in BurnType.sol
 *      `tokenId` the tokenId to burn if specificTokenId is true
 *      `burnAmount` is the quantity to be burned
 */
struct BurnToken {
    address contractAddress;
    bool specificTokenId;
    uint256 tokenType;
    uint256 burnType;
    uint256 tokenId;
    uint256 burnAmount;
}

/**
 * @dev Defines the token that will be used for payment
 *      
 *      `contractAddress` address of contract to for payment if ERC20
 *          if tokenType is native token then this should be set to 0x000...000
 *          to save calldata gas units
 *      `tokenType` is the type of token being used for payment, defined in TokenTypes.sol
 *      `payTo` the address that will receive the payment
 *      `paymentAmount` the amount for the payment in base units for the token
 *          ex. a native payment on Ethereum for 1 ETH would be specified in wei
 *          which would be 1**18 wei
 *      `referralBPS` is the percentage of the payment in BPS that will be sent to the 
 *          `referrer` on the MintOrder if `referralBPS` is greater than 0 and `referrer`
 *          is not address(0)
 */
struct PaymentToken {
    address contractAddress;
    uint256 tokenType;
    address payTo;
    uint256 paymentAmount;
    uint256 referralBPS;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Simple struct to store a string value in a custom storage slot
struct StringValue {
    string value;
}

/// @dev Simple struct to store an address value in a custom storage slot
struct AddressValue {
    address value;
}

// SPDX-License-Identifier: MIT
// ERC1155P Contracts v1.1
// Creator: 0xjustadev/0xth0mas

pragma solidity ^0.8.20;

import "./IERC1155P.sol";

/**
 * @dev Interface of ERC1155 token receiver.
 */
interface ERC1155P__IERC1155Receiver {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Interface for IERC1155MetadataURI.
 */

interface ERC1155P__IERC1155MetadataURI {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

 /**
 * @title ERC1155P
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155 including the Metadata extension.
 * Optimized for lower gas for users collecting multiple tokens.
 *
 * Assumptions:
 * - An owner cannot have more than 2**16 - 1 of a single token
 * - The maximum token ID cannot exceed 2**100 - 1
 */
abstract contract ERC1155P is IERC1155P, ERC1155P__IERC1155MetadataURI {

    /**
     * @dev MAX_ACCOUNT_TOKEN_BALANCE is 2^16-1 because token balances are
     *      are being packed into 16 bits within each bucket.
     */
    uint256 private constant MAX_ACCOUNT_TOKEN_BALANCE = 0xFFFF;

    uint256 private constant BALANCE_STORAGE_OFFSET =
        0xE000000000000000000000000000000000000000000000000000000000000000;

    uint256 private constant APPROVAL_STORAGE_OFFSET =
        0xD000000000000000000000000000000000000000000000000000000000000000;

    /**
     * @dev MAX_TOKEN_ID is derived from custom storage pointer location for 
     *      account/token balance data. Wallet address is shifted 92 bits left
     *      and leaves 92 bits for bucket #'s. Each bucket holds 8 token balances
     *      2^92*8-1 = MAX_TOKEN_ID
     */
    uint256 private constant MAX_TOKEN_ID = 0x07FFFFFFFFFFFFFFFFFFFFFFF;

    // The `TransferSingle` event signature is given by:
    // `keccak256(bytes("TransferSingle(address,address,address,uint256,uint256)"))`.
    bytes32 private constant _TRANSFER_SINGLE_EVENT_SIGNATURE =
        0xc3d58168c5ae7397731d063d5bbf3d657854427343f4c083240f7aacaa2d0f62;
    // The `TransferBatch` event signature is given by:
    // `keccak256(bytes("TransferBatch(address,address,address,uint256[],uint256[])"))`.
    bytes32 private constant _TRANSFER_BATCH_EVENT_SIGNATURE =
        0x4a39dc06d4c0dbc64b70af90fd698a233a518aa5d07e595d983b8c0526c8f7fb;
    // The `ApprovalForAll` event signature is given by:
    // `keccak256(bytes("ApprovalForAll(address,address,bool)"))`.
    bytes32 private constant _APPROVAL_FOR_ALL_EVENT_SIGNATURE =
        0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31;

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0xd9b67a26 || // ERC165 interface ID for ERC1155.
            interfaceId == 0x0e89341c; // ERC165 interface ID for ERC1155MetadataURI.
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        if(account == address(0)) { _revert(BalanceQueryForZeroAddress.selector); }
        return getBalance(account, id);
    }

    /**
     * @dev Gets the amount of tokens minted by an account for a given token id
     */
    function _numberMinted(address account, uint256 id) internal view returns (uint256) {
        if(account == address(0)) { _revert(BalanceQueryForZeroAddress.selector); }
        return getMinted(account, id);
    }

    /**
     * @dev Gets the balance of an account's token id from packed token data
     *
     */
    function getBalance(address account, uint256 id) private view returns (uint256 _balance) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            _balance := shr(shl(5, and(id, 0x07)), and(sload(keccak256(0x00, 0x20)), shl(shl(5, and(id, 0x07)), 0x0000FFFF)))
        }
    }

    /**
     * @dev Sets the balance of an account's token id in packed token data
     *
     */
    function setBalance(address account, uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            mstore(0x00, keccak256(0x00, 0x20))
            sstore(mload(0x00), or(and(not(shl(shl(5, and(id, 0x07)), 0x0000FFFF)), sload(mload(0x00))), shl(shl(5, and(id, 0x07)), amount)))
        }
    }

    /**
     * @dev Gets the number minted of an account's token id from packed token data
     *
     */
    function getMinted(address account, uint256 id) private view returns (uint256 _minted) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            _minted := shr(16, shr(shl(5, and(id, 0x07)), and(sload(keccak256(0x00, 0x20)), shl(shl(5, and(id, 0x07)), 0xFFFF0000))))
        }
    }

    /**
     * @dev Sets the number minted of an account's token id in packed token data
     *
     */
    function setMinted(address account, uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(BALANCE_STORAGE_OFFSET, or(shr(4, shl(96, account)), shr(3, id))))
            mstore(0x00, keccak256(0x00, 0x20))
            sstore(mload(0x00), or(and(not(shl(shl(5, and(id, 0x07)), 0xFFFF0000)), sload(mload(0x00))), shl(shl(5, and(id, 0x07)), shl(16, amount))))
        }
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) public view virtual override returns (uint256[] memory) {
        if(accounts.length != ids.length) { _revert(ArrayLengthMismatch.selector); }

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i; i < accounts.length;) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
            unchecked {
                ++i;
            }
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool _approved) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, shr(96, shl(96, account)))
            mstore(0x20, or(APPROVAL_STORAGE_OFFSET, shr(96, shl(96, operator))))
            mstore(0x00, keccak256(0x00, 0x40))
            _approved := sload(mload(0x00))
        }
        return _approved; 
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
    ) public virtual override {
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override {
        _safeBatchTransferFrom(from, to, ids, amounts, data);
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
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(to == address(0)) { _revert(TransferToZeroAddress.selector); }
        
        if(from != _msgSenderERC1155P())
            if (!isApprovedForAll(from, _msgSenderERC1155P())) _revert(TransferCallerNotOwnerNorApproved.selector);

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, from, to, id, amount, data);

        uint256 fromBalance = getBalance(from, id);
        if(amount > fromBalance) { _revert(TransferExceedsBalance.selector); }

        if(from != to) {
            uint256 toBalance = getBalance(to, id);
            unchecked {
                fromBalance -= amount;
                toBalance += amount;
            }
            if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            setBalance(from, id, fromBalance);
            setBalance(to, id, toBalance);   
        }

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data .
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                to // `to`.
            )
        }

        _afterTokenTransfer(operator, from, to, id, amount, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155Received(from, to, id, amount, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
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
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if(to == address(0)) { _revert(TransferToZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        if(from != _msgSenderERC1155P())
            if (!isApprovedForAll(from, _msgSenderERC1155P())) _revert(TransferCallerNotOwnerNorApproved.selector);

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }

            uint256 fromBalance = getBalance(from, id);
            if(amount > fromBalance) { _revert(TransferExceedsBalance.selector); }

            if(from != to) {
                uint256 toBalance = getBalance(to, id);
                unchecked {
                    fromBalance -= amount;
                    toBalance += amount;
                }
                if(toBalance > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
                setBalance(from, id, fromBalance);
                setBalance(to, id, toBalance);
            }

            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                to // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, from, to, ids, amounts, data);


        if(to.code.length != 0)
            if(!_checkContractOnERC1155BatchReceived(from, to, ids, amounts, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
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
    function _mint(address minter, address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(to == address(0)) { _revert(MintToZeroAddress.selector); }
        if(amount == 0) { _revert(MintZeroQuantity.selector); }

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, address(0), to, id, amount, data);

        uint256 toBalanceBefore = getBalance(to, id);
        uint256 toBalanceAfter;
        unchecked {
            toBalanceAfter = toBalanceBefore + amount;
        }
        if(toBalanceAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
        if(toBalanceAfter < toBalanceBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
        setBalance(to, id, toBalanceAfter);

        uint256 toMintedBefore = getMinted(minter, id);
        uint256 toMintedAfter;
        unchecked {
            toMintedAfter = toMintedBefore + amount;
        }
        if(toMintedAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
        if(toMintedAfter < toMintedBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
        setMinted(minter, id, toMintedAfter);

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data .
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                0, // `from`.
                to // `to`.
            )
        }

        _afterTokenTransfer(operator, address(0), to, id, amount, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155Received(address(0), to, id, amount, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address minter,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {
        if(to == address(0)) { _revert(MintToZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        uint256 id;
        uint256 amount;
        for (uint256 i; i < ids.length;) {
            id = ids[i];
            amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
            if(amount == 0) { _revert(MintZeroQuantity.selector); }

            uint256 toBalanceBefore = getBalance(to, id);
            uint256 toBalanceAfter;
            unchecked {
                toBalanceAfter = toBalanceBefore + amount;
            }
            if(toBalanceAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            if(toBalanceAfter < toBalanceBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
            setBalance(to, id, toBalanceAfter);

            uint256 toMintedBefore = getMinted(minter, id);
            uint256 toMintedAfter;
            unchecked {
                toMintedAfter = toMintedBefore + amount;
            }
            if(toMintedAfter > MAX_ACCOUNT_TOKEN_BALANCE) { _revert(ExceedsMaximumBalance.selector); }
            if(toMintedAfter < toMintedBefore) { _revert(ExceedsMaximumBalance.selector); } // catches overflow
            setMinted(minter, id, toMintedAfter);

            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                0, // `from`.
                to // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, address(0), to, ids, amounts, data);

        if(to.code.length != 0)
            if(!_checkContractOnERC1155BatchReceived(address(0), to, ids, amounts, data))  {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }
        if(from == address(0)) { _revert(BurnFromZeroAddress.selector); }

        address operator = _msgSenderERC1155P();

        _beforeTokenTransfer(operator, from, address(0), id, amount, "");

        uint256 fromBalance = getBalance(from, id);
        if(amount > fromBalance) { _revert(BurnExceedsBalance.selector); }
        unchecked {
            fromBalance -= amount;
        }
        setBalance(from, id, fromBalance);

        /// @solidity memory-safe-assembly
        assembly {
            // Emit the `TransferSingle` event.
            let memOffset := mload(0x40)
            mstore(memOffset, id)
            mstore(add(memOffset, 0x20), amount)
            log4(
                memOffset, // Start of data.
                0x40, // Length of data.
                _TRANSFER_SINGLE_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                0 // `to`.
            )
        }

        _afterTokenTransfer(operator, from, address(0), id, amount, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] calldata ids, uint256[] calldata amounts) internal virtual {
        if(from == address(0)) { _revert(BurnFromZeroAddress.selector); }
        if(ids.length != amounts.length) { _revert(ArrayLengthMismatch.selector); }

        address operator = _msgSenderERC1155P();

        _beforeBatchTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i; i < ids.length;) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            if(id > MAX_TOKEN_ID) { _revert(ExceedsMaximumTokenId.selector); }

            uint256 fromBalance = getBalance(from, id);
            if(amount > fromBalance) { _revert(BurnExceedsBalance.selector); }
            unchecked {
                fromBalance -= amount;
            }
            setBalance(from, id, fromBalance);
            unchecked {
                ++i;
            }
        }

        /// @solidity memory-safe-assembly
        assembly {
            let memOffset := mload(0x40)
            mstore(memOffset, 0x40)
            mstore(add(memOffset,0x20), add(0x60, mul(0x20,ids.length)))
            mstore(add(memOffset,0x40), ids.length)
            calldatacopy(add(memOffset,0x60), ids.offset, mul(0x20,ids.length))
            mstore(add(add(memOffset,0x60),mul(0x20,ids.length)), amounts.length)
            calldatacopy(add(add(memOffset,0x80),mul(0x20,ids.length)), amounts.offset, mul(0x20,amounts.length))
            log4(
                memOffset, 
                add(0x80,mul(0x40,amounts.length)),
                _TRANSFER_BATCH_EVENT_SIGNATURE, // Signature.
                operator, // `operator`.
                from, // `from`.
                0 // `to`.
            )
        }

        _afterBatchTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, caller())
            mstore(0x20, or(APPROVAL_STORAGE_OFFSET, shr(96, shl(96, operator))))
            mstore(0x00, keccak256(0x00, 0x40))
            mstore(0x20, approved)
            sstore(mload(0x00), mload(0x20))
            log3(
                0x20,
                0x20,
                _APPROVAL_FOR_ALL_EVENT_SIGNATURE,
                caller(),
                shr(96, shl(96, operator))
            )
        }
    }

    /**
     * @dev Hook that is called before any single token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    

    /**
     * @dev Hook that is called before any batch token transfer. This includes minting
     * and burning.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    
    function _beforeBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any single token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any batch token transfer. This includes minting
     * and burning.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    
    function _afterBatchTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC1155Receiver-onERC155Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `id` - Token ID to be transferred.
     * `amount` - Balance of token to be transferred
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC1155Received(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory _data
    ) private returns (bool) {
        try ERC1155P__IERC1155Receiver(to).onERC1155Received(_msgSenderERC1155P(), from, id, amount, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC1155P__IERC1155Receiver(to).onERC1155Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }

    /**
     * @dev Private function to invoke {IERC1155Receiver-onERC155Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `id` - Token ID to be transferred.
     * `amount` - Balance of token to be transferred
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC1155BatchReceived(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory _data
    ) private returns (bool) {
        try ERC1155P__IERC1155Receiver(to).onERC1155BatchReceived(_msgSenderERC1155P(), from, ids, amounts, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC1155P__IERC1155Receiver(to).onERC1155BatchReceived.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                _revert(TransferToNonERC1155ReceiverImplementer.selector);
            }
            /// @solidity memory-safe-assembly
            assembly {
                revert(add(32, reason), mload(reason))
            }
        }
    }
    
    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC1155P() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }

    /**
     * @dev For more efficient reverts.
     */
    function _revert(bytes4 errorSelector) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, errorSelector)
            revert(0x00, 0x04)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "../ERC1155P.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155PSupply is ERC1155P {
    /**
     * @dev Custom storage pointer for total token supply. Total supply is
     *      split into buckets of 4 tokens per bucket allowing for 64 bits
     *      per token. 
     *      32 bits are used to store total supply for a max value of 0xFFFFFFFF 
     *      (~4.3B) of a single token. 
     *      32 bits are used to store the mint count for a token
     * 
     *      The standard ERC1155P implementation allows a maximum token id
     *      of 0x07FFFFFFFFFFFFFFFFFFFFFFF which requires a max bucket id of
     *      0x1FFFFFFFFFFFFFFFFFFFFFFF. Storage slots for buckets start at
     *      0xF000000000000000000000000000000000000000000000000000000000000000
     *      and continue through
     *      0xF0000000000000000000000000000000000000001FFFFFFFFFFFFFFFFFFFFFFF
     * 
     *      Storage pointers for ERC1155P account balances start at
     *      0xE000000000000000000000000000000000000000000000000000000000000000
     *      and continue through
     *      0xEFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
     * 
     *      All custom pointers get hashed to avoid potential conflicts with
     *      standard mappings or incorrect returns on view functions.
     */
    uint256 private constant TOTAL_SUPPLY_STORAGE_OFFSET =
        0xF000000000000000000000000000000000000000000000000000000000000000;
    uint256 private constant MAX_TOTAL_SUPPLY = 0xFFFFFFFF;

    /**
     * Total supply exceeds maximum.
     */
    error ExceedsMaximumTotalSupply();

    /**
     * @dev Total amount of tokens with a given id.
     */
    function totalSupply(
        uint256 id
    ) public view virtual returns (uint256 _totalSupply) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            _totalSupply := shr(shl(6, and(id, 0x03)), and(sload(keccak256(0x00, 0x20)), shl(shl(6, and(id, 0x03)), 0x00000000FFFFFFFF)))
        }
    }

    /**
     * @dev Sets total supply in custom storage slot location
     */
    function setTotalSupply(uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            mstore(0x00, keccak256(0x00, 0x20))
            sstore(mload(0x00), or(and(not(shl(shl(6, and(id, 0x03)), 0x00000000FFFFFFFF)), sload(mload(0x00))), shl(shl(6, and(id, 0x03)), amount)))
        }
    }

    /**
     * @dev Total amount of tokens minted with a given id.
     */
    function totalMinted(
        uint256 id
    ) public view virtual returns (uint256 _totalMinted) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            _totalMinted := shr(32, shr(shl(6, and(id, 0x03)), and(sload(keccak256(0x00, 0x20)), shl(shl(6, and(id, 0x03)), 0xFFFFFFFF00000000))))
        }
    }

    /**
     * @dev Sets total minted in custom storage slot location
     */
    function setTotalMinted(uint256 id, uint256 amount) private {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, or(TOTAL_SUPPLY_STORAGE_OFFSET, shr(2, id)))
            mstore(0x00, keccak256(0x00, 0x20))
            sstore(mload(0x00), or(and(not(shl(shl(6, and(id, 0x03)), 0xFFFFFFFF00000000)), sload(mload(0x00))), shl(shl(6, and(id, 0x03)), shl(32, amount))))
        }
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return this.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory
    ) internal virtual override {
        if (from == address(0)) {
            uint256 supply = this.totalSupply(id);
            uint256 minted = this.totalMinted(id);
            unchecked {
                supply += amount;
                minted += amount;
            }
            if (supply > MAX_TOTAL_SUPPLY || minted > MAX_TOTAL_SUPPLY) {
                ERC1155P._revert(ExceedsMaximumTotalSupply.selector);
            }
            setTotalSupply(id, supply);
            setTotalMinted(id, minted);
        }

        if (to == address(0)) {
            uint256 supply = this.totalSupply(id);
            unchecked {
                supply -= amount;
            }
            setTotalSupply(id, supply);
        }
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeBatchTokenTransfer(
        address,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory
    ) internal virtual override {
        if (from == address(0)) {
            for (uint256 i; i < ids.length; ) {
                uint256 id = ids[i];
                uint256 supply = this.totalSupply(id);
                uint256 minted = this.totalMinted(id);
                unchecked {
                    supply += amounts[i];
                    minted += amounts[i];
                    ++i;
                }
                if (supply > MAX_TOTAL_SUPPLY || minted > MAX_TOTAL_SUPPLY) {
                    ERC1155P._revert(ExceedsMaximumTotalSupply.selector);
                }
                setTotalSupply(id, supply);
                setTotalMinted(id, minted);
            }
        }

        if (to == address(0)) {
            for (uint256 i; i < ids.length; ) {
                uint256 id = ids[i];
                uint256 supply = this.totalSupply(id);
                unchecked {
                    supply -= amounts[i];
                    ++i;
                }
                setTotalSupply(id, supply);
            }
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// ERC1155P Contracts v1.1

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155P {

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Arrays cannot be different lengths.
     */
    error ArrayLengthMismatch();

    /**
     * Cannot burn from the zero address.
     */
    error BurnFromZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The quantity of tokens being burned is greater than account balance.
     */
    error BurnExceedsBalance();

    /**
     * The quantity of tokens being transferred is greater than account balance.
     */
    error TransferExceedsBalance();

    /**
     * The resulting token balance exceeds the maximum storable by ERC1155P
     */
    error ExceedsMaximumBalance();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC1155Receiver interface.
     */
    error TransferToNonERC1155ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * Exceeds max token ID
     */
    error ExceedsMaximumTokenId();
    
    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import {ERC1155PSupply} from "./extensions/ERC1155PSupply.sol";
import {ILayerr1155} from "../../interfaces/ILayerr1155.sol";
import {ILayerrRenderer} from "../../interfaces/ILayerrRenderer.sol";
import {LayerrToken} from "../LayerrToken.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

/**
 * @title Layerr1155
 * @author 0xth0mas (Layerr)
 * @notice Layerr1155 is an ERC1155 contract built for the Layerr platform using
 *         the ERC1155P implementation for gas efficient mints, burns, purchases,  
 *         and transfers of multiple tokens.
 */
contract Layerr1155 is
    DefaultOperatorFilterer,
    ERC1155PSupply,
    ILayerr1155,
    LayerrToken
{

    /** METADATA FUNCTIONS */

    /**
     * @notice Returns the URI for a given `tokenId`
     * @param id id of token to return URI of
     * @return tokenURI location of the token metadata
     */
    function uri(
        uint256 id
    ) public view virtual override returns (string memory) {
        return ILayerrRenderer(_getRenderer()).tokenURI(address(this), id);
    }

    /**
     * @notice Returns the URI for the contract metadata
     * @return contractURI location of the contract metadata
     */
    function contractURI() public view returns (string memory) {
        return ILayerrRenderer(_getRenderer()).contractURI(address(this));
    }

    /** MINT FUNCTIONS */

    /**
     * @inheritdoc ILayerr1155
     */
    function mintTokenId(
        address minter,
        address to,
        uint256 id,
        uint256 amount
    ) external onlyMinter {
        _mint(minter, to, id, amount, "");
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyMinter {
        _mintBatch(minter, to, ids, amounts, "");
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function burnTokenId(
        address from,
        uint256 tokenId,
        uint256 amount
    ) external {
        if (!isApprovedForAll(from, msg.sender)) {
            revert NotAuthorized();
        }
        _burn(from, tokenId, amount);
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external {
        if (!isApprovedForAll(from, msg.sender)) {
            revert NotAuthorized();
        }
        _burnBatch(from, tokenIds, amounts);
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function totalSupply(uint256 id) public view override(ERC1155PSupply, ILayerr1155) returns (uint256) {
        return ERC1155PSupply.totalSupply(id);
    }
    
    /**
     * @inheritdoc ILayerr1155
     */
    function totalMintedCollectionAndMinter(address minter, uint256 id) external view returns(uint256 totalMinted, uint256 minterMinted) {
        totalMinted = totalSupply(id);
        minterMinted = _numberMinted(minter, id);
    }
    
    /** OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerr1155
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds, uint256[] calldata amounts) external onlyOwner {
        if(recipients.length != tokenIds.length || tokenIds.length != amounts.length) { revert ArrayLengthMismatch(); }

        for(uint256 index = 0;index < recipients.length;) {
            _mint(msg.sender, recipients[index], tokenIds[index], amounts[index], "");

            unchecked { ++index; }
        }
    }

    /**
     * @notice Subscribes to an operator filter registry
     * @param operatorFilterRegistry operator filter address to subscribe to
     */
    function setOperatorFilter(address operatorFilterRegistry) external onlyOwner {
        if (operatorFilterRegistry != address(0)) {
            OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
                address(this),
                operatorFilterRegistry
            );
        }
    }

    /**
     * @notice Unsubscribes from the operator filter registry
     */
    function removeOperatorFilter() external onlyOwner {
        OPERATOR_FILTER_REGISTRY.unregister(
            address(this)
        );
    }

    /**
     * @inheritdoc ILayerr1155
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external onlyOwner {
        ILayerrRenderer renderer = ILayerrRenderer(_getRenderer());
        for(uint256 i; i < tokenIds.length; ) {
            uint256 tokenId = tokenIds[i];
            emit URI(renderer.tokenURI(address(this), tokenId), tokenId);
            
            unchecked { ++i; }
        }
    }

    /** OPERATOR FILTER OVERRIDES */

    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /** ERC165 */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LayerrToken, ERC1155PSupply) returns (bool) {
        return
            interfaceId == type(ILayerr1155).interfaceId ||
            LayerrToken.supportsInterface(interfaceId) ||
            ERC1155PSupply.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {AddressValue, StringValue} from "../lib/StorageTypes.sol";
import {LAYERRTOKEN_NAME_SLOT, LAYERRTOKEN_SYMBOL_SLOT, LAYERRTOKEN_RENDERER_SLOT} from "../common/LayerrStorage.sol";
import {LayerrOwnable} from "../common/LayerrOwnable.sol";
import {ILayerrToken} from "../interfaces/ILayerrToken.sol";
import {ILayerrMinter} from "../interfaces/ILayerrMinter.sol";
import {ERC2981} from "../lib/ERC2981.sol";

/**
 * @title LayerrToken
 * @author 0xth0mas (Layerr)
 * @notice LayerrToken contains the general purpose token contract functions for interacting
 *         with the Layerr platform.
 */
contract LayerrToken is ILayerrToken, LayerrOwnable, ERC2981 {

    /// @dev mapping of allowed mint extensions
    mapping(address => bool) public mintingExtensions;

    modifier onlyMinter() {
        if (!mintingExtensions[msg.sender]) {
            revert NotValidMintingExtension();
        }
        _;
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function name() public virtual view returns(string memory _name) {
        StringValue storage nameValue;
        /// @solidity memory-safe-assembly
        assembly {
            nameValue.slot := LAYERRTOKEN_NAME_SLOT
        }
        _name = nameValue.value;
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function symbol() public virtual view returns(string memory _symbol) {
        StringValue storage symbolValue;
        /// @solidity memory-safe-assembly
        assembly {
            symbolValue.slot := LAYERRTOKEN_SYMBOL_SLOT
        }
        _symbol = symbolValue.value;
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function renderer() external view returns(address _renderer) {
        _renderer = _getRenderer();
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(LayerrOwnable, ERC2981) returns (bool) {
        return interfaceId == type(ILayerrToken).interfaceId ||
            ERC2981.supportsInterface(interfaceId) ||
            LayerrOwnable.supportsInterface(interfaceId);
    }

    /* OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerrToken
     */
    function setRenderer(address _renderer) external onlyOwner {
        _setRenderer(_renderer);

        emit RendererUpdated(_renderer);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setMintExtension(
        address _extension,
        bool _allowed
    ) external onlyOwner {
        mintingExtensions[_extension] = _allowed;

        emit MintExtensionUpdated(_extension, _allowed);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setContractAllowedSigner(
        address _extension,
        address _signer,
        bool _allowed
    ) external onlyOwner {
        ILayerrMinter(_extension).setContractAllowedSigner(_signer, _allowed);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setContractAllowedOracle(
        address _extension,
        address _oracle,
        bool _allowed
    ) external onlyOwner {
        ILayerrMinter(_extension).setContractAllowedOracle(_oracle, _allowed);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setSignatureValidity(
        address _extension,
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external onlyOwner {
        ILayerrMinter(_extension).setSignatureValidity(signatureDigests, invalid);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function setRoyalty(
        uint96 pct,
        address royaltyReciever
    ) external onlyOwner {
        _setDefaultRoyalty(royaltyReciever, pct);
    }

    /**
     * @inheritdoc ILayerrToken
     */
    function editContract(
        string calldata _name,
        string calldata _symbol
    ) external onlyOwner {
        _setName(_name);
        _setSymbol(_symbol);
    }

    /**
     * @notice Called during a proxy deployment to emit the LayerrContractDeployed event
     */
    function initialize() external onlyOwner {
        emit LayerrContractDeployed();
    }

    /**
     * @notice Called to withdraw any funds that may be sent to the contract
     */
    function withdraw() external onlyOwner {
        (bool sent, ) = payable(_getOwner()).call{value: address(this).balance}("");
        if (!sent) {
            revert WithdrawFailed();
        }
    }

    /**
     *  INTERNAL FUNCTIONS
     */

    /**
     * @notice Internal function to set the renderer address in a custom storage slot location
     * @param _renderer address of the renderer to set
     */
    function _setRenderer(address _renderer) internal {
        AddressValue storage rendererValue;
        /// @solidity memory-safe-assembly
        assembly {
            rendererValue.slot := LAYERRTOKEN_RENDERER_SLOT
        }
        rendererValue.value = _renderer;
    }

    /**
     * @notice Internal function to get the renderer address from a custom storage slot location
     * @return _renderer address of the renderer
     */
    function _getRenderer() internal view returns(address _renderer) {
        AddressValue storage rendererValue;
        /// @solidity memory-safe-assembly
        assembly {
            rendererValue.slot := LAYERRTOKEN_RENDERER_SLOT
        }
        _renderer = rendererValue.value;
    }

    /**
     * @notice Internal function to set the token contract name in a custom storage slot location
     * @param _name name for the token contract
     */
    function _setName(string calldata _name) internal {
        StringValue storage nameValue;
        /// @solidity memory-safe-assembly
        assembly {
            nameValue.slot := LAYERRTOKEN_NAME_SLOT
        }
        nameValue.value = _name;
    }

    /**
     * @notice Internal function to set the token contract symbol in a custom storage slot location
     * @param _symbol symbol for the token contract
     */
    function _setSymbol(string calldata _symbol) internal {
        StringValue storage symbolValue;
        /// @solidity memory-safe-assembly
        assembly {
            symbolValue.slot := LAYERRTOKEN_SYMBOL_SLOT
        }
        symbolValue.value = _symbol;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}