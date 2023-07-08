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
 * @title ILayerr20
 * @author 0xth0mas (Layerr)
 * @notice ILayerr20 interface defines functions required in an ERC20 token contract to callable by the LayerrMinter contract.
 */
interface ILayerr20 {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();

    /**
     * @notice Mints tokens to the recipients in amounts specified
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param amounts amount of tokens to airdrop to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external;

    /**
     * @notice Mints `amount` of ERC20 tokens to the `to` address
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the minted amount will be credited to
     * @param to address that will receive the tokens being minted
     * @param amount amount of tokens being minted
     */
    function mint(address minter, address to, uint256 amount) external;

    /**
     * @notice Burns `amount` of ERC20 tokens from the `from` address
     * @dev This function should check that the caller has a sufficient spend allowance to burn these tokens
     * @param from address that the tokens will be burned from
     * @param amount amount of tokens to be burned
     */
    function burn(address from, uint256 amount) external;

    /**
     * @notice Returns the total supply of ERC20 tokens in circulation.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC20 tokens minted since token launch
     * @return minterMinted total number of ERC20 tokens minted by the `minter`
     */
    function totalMintedTokenAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
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
pragma solidity ^0.8.4;

/// @notice Simple ERC20 + EIP-2612 implementation.
/// @author 0xth0mas (Layerr) - Modifications to Solady ERC20 to pack minted quantity with balance quantity
/// @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol)
/// @dev Note:
/// The ERC20 standard allows minting and transferring to and from the zero address,
/// minting and transferring zero tokens, as well as self-approvals.
/// For performance, this implementation WILL NOT revert for such actions.
/// Please add any checks with overrides if desired.
abstract contract ERC20 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The total supply has overflowed.
    error TotalSupplyOverflow();

    /// @dev The allowance has overflowed.
    error AllowanceOverflow();

    /// @dev The allowance has underflowed.
    error AllowanceUnderflow();

    /// @dev The balance has overflowed
    error BalanceOverflow();

    /// @dev Insufficient balance.
    error InsufficientBalance();

    /// @dev Insufficient allowance.
    error InsufficientAllowance();

    /// @dev The permit is invalid.
    error InvalidPermit();

    /// @dev The permit has expired.
    error PermitExpired();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when `amount` tokens is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when `amount` tokens is approved by `owner` to be used by `spender`.
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev `keccak256(bytes("Transfer(address,address,uint256)"))`.
    uint256 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /// @dev `keccak256(bytes("Approval(address,address,uint256)"))`.
    uint256 private constant _APPROVAL_EVENT_SIGNATURE =
        0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The storage slot for the total minted.
    uint256 private constant _TOTAL_MINTED_SLOT = 0x05345cdf77eb68f44c;

    /// @dev The storage slot for the total burned.
    uint256 private constant _TOTAL_BURNED_SLOT = 0xc44f86be77fdc54350;

    uint256 private constant _BALANCE_MASK = 0x00000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /// @dev The balance slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _BALANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let balanceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _BALANCE_SLOT_SEED = 0x87a211a2;

    /// @dev The allowance slot of (`owner`, `spender`) is given by:
    /// ```
    ///     mstore(0x20, spender)
    ///     mstore(0x0c, _ALLOWANCE_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let allowanceSlot := keccak256(0x0c, 0x34)
    /// ```
    uint256 private constant _ALLOWANCE_SLOT_SEED = 0x7f5e9f20;

    /// @dev The nonce slot of `owner` is given by:
    /// ```
    ///     mstore(0x0c, _NONCES_SLOT_SEED)
    ///     mstore(0x00, owner)
    ///     let nonceSlot := keccak256(0x0c, 0x20)
    /// ```
    uint256 private constant _NONCES_SLOT_SEED = 0x38377508;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 METADATA                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the name of the token.
    function name() public view virtual returns (string memory);

    /// @dev Returns the symbol of the token.
    function symbol() public view virtual returns (string memory);

    /// @dev Returns the decimals places of the token.
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           ERC20                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the amount of tokens in existence.
    function totalSupply() public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sub(sload(_TOTAL_MINTED_SLOT), sload(_TOTAL_BURNED_SLOT))
        }
    }

    /// @dev Returns the amount of tokens minted.
    function _totalMinted() internal view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_MINTED_SLOT)
        }
    }

    /// @dev Returns the amount of tokens burned.
    function _totalBurned() internal view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(_TOTAL_BURNED_SLOT)
        }
    }

    /// @dev Returns the amount of tokens owned by `owner`.
    function balanceOf(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := and(sload(keccak256(0x0c, 0x20)), _BALANCE_MASK)
        }
    }

    /// @dev Returns the amount of tokens minted by `wallet`.
    function _numberMinted(address wallet) internal view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, wallet)
            result := shr(128, sload(keccak256(0x0c, 0x20)))
        }
    }

    /// @dev Returns the amount of tokens that `spender` can spend on behalf of `owner`.
    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x34))
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    ///
    /// Emits a {Approval} event.
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically increases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function increaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Add to the allowance.
            let allowanceAfter := add(allowanceBefore, difference)
            // Revert upon overflow.
            if lt(allowanceAfter, allowanceBefore) {
                mstore(0x00, 0xf9067066) // `AllowanceOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated allowance.
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Atomically decreases the allowance granted to `spender` by the caller.
    ///
    /// Emits a {Approval} event.
    function decreaseAllowance(address spender, uint256 difference) public virtual returns (bool) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, caller())
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowanceBefore := sload(allowanceSlot)
            // Revert if will underflow.
            if lt(allowanceBefore, difference) {
                mstore(0x00, 0x8301ab38) // `AllowanceUnderflow()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated allowance.
            let allowanceAfter := sub(allowanceBefore, difference)
            sstore(allowanceSlot, allowanceAfter)
            // Emit the {Approval} event.
            mstore(0x00, allowanceAfter)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, caller(), shr(96, mload(0x2c)))
        }
        return true;
    }

    /// @dev Transfer `amount` tokens from the caller to `to`.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    ///
    /// Emits a {Transfer} event.
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(msg.sender, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, caller())
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toBalanceAfter := add(toBalanceBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, or(and(toBalanceSlotValue, not(_BALANCE_MASK)), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, caller(), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(msg.sender, to, amount);
        return true;
    }

    /// @dev Transfers `amount` tokens from `from` to `to`.
    ///
    /// Note: does not update the allowance if it is the maximum uint256 value.
    ///
    /// Requirements:
    /// - `from` must at least have `amount`.
    /// - The caller must have at least `amount` of allowance to transfer the tokens of `from`.
    ///
    /// Emits a {Transfer} event.
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the allowance slot and load its value.
            mstore(0x20, caller())
            mstore(0x0c, or(from_, _ALLOWANCE_SLOT_SEED))
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toBalanceAfter := add(toBalanceBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, or(and(toBalanceSlotValue, not(_BALANCE_MASK)), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          EIP-2612                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the current nonce for `owner`.
    /// This value is used to compute the signature for EIP-2612 permit.
    function nonces(address owner) public view virtual returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /// @dev Sets `value` as the allowance of `spender` over the tokens of `owner`,
    /// authorized by a signed approval by `owner`.
    ///
    /// Emits a {Approval} event.
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        bytes32 domainSeparator = DOMAIN_SEPARATOR();
        /// @solidity memory-safe-assembly
        assembly {
            // Grab the free memory pointer.
            let m := mload(0x40)
            // Revert if the block timestamp greater than `deadline`.
            if gt(timestamp(), deadline) {
                mstore(0x00, 0x1a15a3cc) // `PermitExpired()`.
                revert(0x1c, 0x04)
            }
            // Clean the upper 96 bits.
            owner := shr(96, shl(96, owner))
            spender := shr(96, shl(96, spender))
            // Compute the nonce slot and load its value.
            mstore(0x0c, _NONCES_SLOT_SEED)
            mstore(0x00, owner)
            let nonceSlot := keccak256(0x0c, 0x20)
            let nonceValue := sload(nonceSlot)
            // Increment and store the updated nonce.
            sstore(nonceSlot, add(nonceValue, 1))
            // Prepare the inner hash.
            // `keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9)
            mstore(add(m, 0x20), owner)
            mstore(add(m, 0x40), spender)
            mstore(add(m, 0x60), value)
            mstore(add(m, 0x80), nonceValue)
            mstore(add(m, 0xa0), deadline)
            // Prepare the outer hash.
            mstore(0, 0x1901)
            mstore(0x20, domainSeparator)
            mstore(0x40, keccak256(m, 0xc0))
            // Prepare the ecrecover calldata.
            mstore(0, keccak256(0x1e, 0x42))
            mstore(0x20, and(0xff, v))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(staticcall(gas(), 1, 0, 0x80, 0x20, 0x20))
            // If the ecrecover fails, the returndatasize will be 0x00,
            // `owner` will be be checked if it equals the hash at 0x00,
            // which evaluates to false (i.e. 0), and we will revert.
            // If the ecrecover succeeds, the returndatasize will be 0x20,
            // `owner` will be compared against the returned address at 0x20.
            if iszero(eq(mload(returndatasize()), owner)) {
                mstore(0x00, 0xddafbaef) // `InvalidPermit()`.
                revert(0x1c, 0x04)
            }
            // Compute the allowance slot and store the value.
            // The `owner` is already at slot 0x20.
            mstore(0x40, or(shl(160, _ALLOWANCE_SLOT_SEED), spender))
            sstore(keccak256(0x2c, 0x34), value)
            // Emit the {Approval} event.
            log3(add(m, 0x60), 0x20, _APPROVAL_EVENT_SIGNATURE, owner, spender)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero pointer.
        }
    }

    /// @dev Returns the EIP-2612 domains separator.
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40) // Grab the free memory pointer.
        }
        //  We simply calculate it on-the-fly to allow for cases where the `name` may change.
        bytes32 nameHash = keccak256(bytes(name()));
        /// @solidity memory-safe-assembly
        assembly {
            let m := result
            // `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
            // forgefmt: disable-next-item
            mstore(m, 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f)
            mstore(add(m, 0x20), nameHash)
            // `keccak256("1")`.
            // forgefmt: disable-next-item
            mstore(add(m, 0x40), 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), address())
            result := keccak256(m, 0xa0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL MINT FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Mints `amount` tokens to `to`, increasing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _mint(address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(address(0), to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let totalMintedBefore := sload(_TOTAL_MINTED_SLOT)
            let totalMintedAfter := add(totalMintedBefore, amount)
            // Revert if the total minted overflows.
            if lt(totalMintedAfter, totalMintedBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total minted.
            sstore(_TOTAL_MINTED_SLOT, totalMintedAfter)
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toMintedBefore := shr(128, toBalanceSlotValue)
            let toBalanceAfter := add(toBalanceBefore, amount)
            let toMintedAfter := add(toMintedBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            if gt(toMintedAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, add(shl(128, toMintedAfter), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, 0, shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(address(0), to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  INTERNAL BURN FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Burns `amount` tokens from `from`, reducing the total supply.
    ///
    /// Emits a {Transfer} event.
    function _burn(address from, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, address(0), amount);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the balance slot and load its value.
            mstore(0x0c, _BALANCE_SLOT_SEED)
            mstore(0x00, from)
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Update burned
            let totalBurnedBefore := sload(_TOTAL_BURNED_SLOT)
            let totalBurnedAfter := add(totalBurnedBefore, amount)
            // Revert if the total minted overflows.
            if lt(totalBurnedAfter, totalBurnedBefore) {
                mstore(0x00, 0xe5cfe957) // `TotalSupplyOverflow()`.
                revert(0x1c, 0x04)
            }
            // Store the updated total burned.
            sstore(_TOTAL_BURNED_SLOT, totalBurnedAfter)
            // Emit the {Transfer} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, shl(96, from)), 0)
        }
        _afterTokenTransfer(from, address(0), amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL TRANSFER FUNCTIONS                 */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Moves `amount` of tokens from `from` to `to`.
    function _transfer(address from, address to, uint256 amount) internal virtual {
        _beforeTokenTransfer(from, to, amount);
        /// @solidity memory-safe-assembly
        assembly {
            let from_ := shl(96, from)
            // Compute the balance slot and load its value.
            mstore(0x0c, or(from_, _BALANCE_SLOT_SEED))
            let fromBalanceSlot := keccak256(0x0c, 0x20)
            let fromBalanceSlotValue := sload(fromBalanceSlot)
            let fromBalance := and(fromBalanceSlotValue, _BALANCE_MASK)
            // Revert if insufficient balance.
            if gt(amount, fromBalance) {
                mstore(0x00, 0xf4d678b8) // `InsufficientBalance()`.
                revert(0x1c, 0x04)
            }
            // Subtract and store the updated balance.
            sstore(fromBalanceSlot, or(and(fromBalanceSlotValue, not(_BALANCE_MASK)), sub(fromBalance, amount)))
            // Compute the balance slot of `to`.
            mstore(0x00, to)
            let toBalanceSlot := keccak256(0x0c, 0x20)
            let toBalanceSlotValue := sload(toBalanceSlot)
            let toBalanceBefore := and(toBalanceSlotValue, _BALANCE_MASK)
            let toBalanceAfter := add(toBalanceBefore, amount)
            if gt(toBalanceAfter, _BALANCE_MASK) {
                mstore(0x00, 0x89560ca1)
                revert(0x1c, 0x04)
            }
            // Add and store the updated balance.
            sstore(toBalanceSlot, or(and(toBalanceSlotValue, not(_BALANCE_MASK)), toBalanceAfter))
            // Emit the {Transfer} event.
            mstore(0x20, amount)
            log3(0x20, 0x20, _TRANSFER_EVENT_SIGNATURE, shr(96, from_), shr(96, mload(0x0c)))
        }
        _afterTokenTransfer(from, to, amount);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                INTERNAL ALLOWANCE FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Updates the allowance of `owner` for `spender` based on spent `amount`.
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the allowance slot and load its value.
            mstore(0x20, spender)
            mstore(0x0c, _ALLOWANCE_SLOT_SEED)
            mstore(0x00, owner)
            let allowanceSlot := keccak256(0x0c, 0x34)
            let allowance_ := sload(allowanceSlot)
            // If the allowance is not the maximum uint256 value.
            if iszero(eq(allowance_, not(0))) {
                // Revert if the amount to be transferred exceeds the allowance.
                if gt(amount, allowance_) {
                    mstore(0x00, 0x13be252b) // `InsufficientAllowance()`.
                    revert(0x1c, 0x04)
                }
                // Subtract and store the updated allowance.
                sstore(allowanceSlot, sub(allowance_, amount))
            }
        }
    }

    /// @dev Sets `amount` as the allowance of `spender` over the tokens of `owner`.
    ///
    /// Emits a {Approval} event.
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let owner_ := shl(96, owner)
            // Compute the allowance slot and store the amount.
            mstore(0x20, spender)
            mstore(0x0c, or(owner_, _ALLOWANCE_SLOT_SEED))
            sstore(keccak256(0x0c, 0x34), amount)
            // Emit the {Approval} event.
            mstore(0x00, amount)
            log3(0x00, 0x20, _APPROVAL_EVENT_SIGNATURE, shr(96, owner_), shr(96, mload(0x2c)))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HOOKS TO OVERRIDE                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Hook that is called before any transfer of tokens.
    /// This includes minting and burning.
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /// @dev Hook that is called after any transfer of tokens.
    /// This includes minting and burning.
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0 <0.9.0;

import "./ERC20.sol";
import {ILayerr20} from "../../interfaces/ILayerr20.sol";
import {ILayerrRenderer} from "../../interfaces/ILayerrRenderer.sol";
import {LayerrToken} from "../LayerrToken.sol";

/**
 * @title Layerr20
 * @author 0xth0mas (Layerr)
 * @notice Layerr20 is an ERC20 contract built for the Layerr platform using
 *         the Solady ERC20 implementation.
 */
contract Layerr20 is ERC20, ILayerr20, LayerrToken {

    /** METADATA FUNCTIONS */

    /**
     * @notice Returns the URI for the contract metadata
     * @return contractURI location of the contract metadata
     */
    function contractURI() public view returns (string memory) {
        return ILayerrRenderer(_getRenderer()).contractURI(address(this));
    }

    /**
     * @inheritdoc LayerrToken
     */
    function name() public view virtual override(LayerrToken, ERC20) returns (string memory) {
        return LayerrToken.name();
    }

    /**
     * @inheritdoc LayerrToken
     */
    function symbol() public view virtual override(LayerrToken, ERC20) returns (string memory) {
        return LayerrToken.symbol();
    }

    /** MINT FUNCTIONS */

    /**
     * @inheritdoc ILayerr20
     */
    function mint(address, address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    /**
     * @inheritdoc ILayerr20
     */
    function burn(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    /**
     * @inheritdoc ILayerr20
     */
    function totalSupply() public view override(ERC20, ILayerr20) returns (uint256) {
        return ERC20.totalSupply();
    }

    /**
     * @inheritdoc ILayerr20
     */
    function totalMintedTokenAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted) {
        totalMinted = _totalMinted();
        minterMinted = _numberMinted(minter);
    }

    /** OWNER FUNCTIONS */

    /**
     * @inheritdoc ILayerr20
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        if(recipients.length != amounts.length) { revert ArrayLengthMismatch(); }

        for(uint256 index = 0;index < recipients.length;) {
            uint256 amount = amounts[index];
            _mint(recipients[index], amount);
            unchecked { ++index; }
        }
    }

    /** ERC165 */

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(LayerrToken) returns (bool) {
        return
            interfaceId == type(ILayerr20).interfaceId ||
            LayerrToken.supportsInterface(interfaceId);
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