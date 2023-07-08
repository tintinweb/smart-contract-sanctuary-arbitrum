// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

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
    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );

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
    function balanceOf(
        address account,
        uint256 id
    ) external view returns (uint256);

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
    function isApprovedForAll(
        address account,
        address operator
    ) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
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

/**
 * @title ILayerr721
 * @author 0xth0mas (Layerr)
 * @notice ILayerr721 interface defines functions required in an ERC721 token contract to callable by the LayerrMinter contract.
 * @dev ILayerr721 should be used for non-sequential token minting.
 */
interface ILayerr721 {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();

    /**
     * @notice Mints tokens to the recipients, each recipient gets the corresponding tokenId in the `tokenIds` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param tokenIds ids of tokens to be airdropped to recipients
     */
    function airdrop(address[] calldata recipients, uint256[] calldata tokenIds) external;

    /**
     * @notice Mints `tokenId` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the token
     * @param tokenId the id of the token to mint
     */
    function mintTokenId(address minter, address to, uint256 tokenId) external;

    /**
     * @notice Mints `tokenIds` to `to`.
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param tokenIds the ids of tokens to mint
     */
    function mintBatchTokenIds(
        address minter,
        address to,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     */
    function burnTokenId(address from, uint256 tokenId) external;

    /**
     * @notice Burns `tokenIds` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenIds from
     * @param tokenIds ids of tokens to be burned
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Emits ERC-4906 BatchMetadataUpdate event for all tokens
     */
    function updateMetadataAllTokens() external;

    /**
     * @notice Emits ERC-4906 MetadataUpdate event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC721 tokens in circulation.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC721 tokens minted since token launch
     * @return minterMinted total number of ERC721 tokens minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILayerr721A
 * @author 0xth0mas (Layerr)
 * @notice ILayerr721A interface defines functions required in an ERC721A token contract to callable by the LayerrMinter contract.
 * @dev ILayerr721A should be used for sequential token minting.
 */
interface ILayerr721A {
    /// @dev Thrown when two or more sets of arrays are supplied that require equal lengths but differ in length.
    error ArrayLengthMismatch();


    /**
     * @notice Mints tokens to the recipients, each recipient receives the corresponding amount of tokens in the `amounts` array
     * @dev This function should be protected by a role so that it is not callable by any address
     * @param recipients addresses to airdrop tokens to
     * @param amounts amount of tokens that should be airdropped to each recipient
     */
    function airdrop(address[] calldata recipients, uint256[] calldata amounts) external;


    /**
     * @notice Sequentially mints `quantity` of tokens to `to`
     * @dev `minter` and `to` may be the same address but are passed as two separate parameters to properly account for
     *      allowlist mints where a minter is using a delegated wallet to mint
     * @param minter address that the mint count will be credited to
     * @param to address that will receive the tokens
     * @param quantity the number of tokens to sequentially mint to `to`
     */
    function mintSequential(address minter, address to, uint256 quantity) external;

    /**
     * @notice Burns `tokenId` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenId from
     * @param tokenId id of token to be burned
     */
    function burnTokenId(address from, uint256 tokenId) external;

    /**
     * @notice Burns `tokenIds` from `from` address
     * @dev This function should check that the caller has permission to burn tokens on behalf of `from`
     * @param from address to burn the tokenIds from
     * @param tokenIds ids of tokens to be burned
     */
    function burnBatchTokenIds(
        address from,
        uint256[] calldata tokenIds
    ) external;

    /**
     * @notice Emits ERC-4906 BatchMetadataUpdate event for all tokens
     */
    function updateMetadataAllTokens() external;

    /**
     * @notice Emits ERC-4906 MetadataUpdate event for tokens provided
     * @param tokenIds array of token ids to emit MetadataUpdate event for
     */
    function updateMetadataSpecificTokens(uint256[] calldata tokenIds) external;

    /**
     * @notice Returns the total supply of ERC721 tokens in circulation.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the total number of tokens minted for the contract and the number of tokens minted by the `minter`
     * @param minter address to check for number of tokens minted
     * @return totalMinted total number of ERC721 tokens minted since token launch
     * @return minterMinted total number of ERC721 tokens minted by the `minter`
     */
    function totalMintedCollectionAndMinter(address minter) external view returns(uint256 totalMinted, uint256 minterMinted);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {TOKEN_TYPE_NATIVE, TOKEN_TYPE_ERC20, TOKEN_TYPE_ERC721, TOKEN_TYPE_ERC1155} from "./lib/TokenType.sol";
import {BURN_TYPE_CONTRACT_BURN, BURN_TYPE_SEND_TO_DEAD} from "./lib/BurnType.sol";
import {MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "./lib/MinterStructs.sol";
import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {ILayerrMinter} from "./interfaces/ILayerrMinter.sol";
import {ILayerr20} from "./interfaces/ILayerr20.sol";
import {ILayerr721} from "./interfaces/ILayerr721.sol";
import {ILayerr721A} from "./interfaces/ILayerr721A.sol";
import {ILayerr1155} from "./interfaces/ILayerr1155.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC1155} from "./interfaces/IERC1155.sol";
import {IDelegationRegistry} from "./interfaces/IDelegationRegistry.sol";
import {MerkleProof} from "./lib/MerkleProof.sol";
import {SignatureVerification} from "./lib/SignatureVerification.sol";

/**
 * @title LayerrMinter
 * @author 0xth0mas (Layerr)
 * @notice LayerrMinter is an unowned immutable primative for ERC20, ERC721 and ERC1155
 *         token minting on EVM-based blockchains. Token contract owners build and sign
 *         MintParameters which are used by minters to create MintOrders to mint tokens.
 *         MintParameters define what to mint and conditions for minting.
 *         Conditions for minting include requiring tokens be burned, payment amounts,
 *         start time, end time, additional oracle signature, maximum supply, max per 
 *         wallet and max signature use.
 *         Mint tokens can be ERC20, ERC721 or ERC1155
 *         Burn tokens can be ERC20, ERC721 or ERC1155
 *         Payment tokens can be the chain native token or ERC20
 *         Payment tokens can specify a referral BPS to pay a referral fee at time of mint
 *         LayerrMinter has native support for delegate.cash delegation on allowlist mints
 */
contract LayerrMinter is ILayerrMinter, ReentrancyGuard, SignatureVerification {

    /// @dev mapping of signature digests that have been marked as invalid for a token contract
    mapping(address => mapping(bytes32 => bool)) public signatureInvalid;

    /// @dev counter for number of times a signature has been used, only incremented if signatureMaxUses > 0
    mapping(bytes32 => uint256) public signatureUseCount;

    /// @dev mapping of addresses that are allowed signers for token contracts
    mapping(address => mapping(address => bool)) public contractAllowedSigner;

    /// @dev mapping of addresses that are allowed oracle signers for token contracts
    mapping(address => mapping(address => bool)) public contractAllowedOracle;

    /// @dev mapping of nonces for signers, used to invalidate all previously signed MintParameters
    mapping(address => uint256) public signerNonce;

    /// @dev address to send tokens when burn type is SEND_TO_DEAD
    address private constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    /// @dev delegate.cash registry for users that want to use a hot wallet for minting an allowlist mint
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    /**
     * @inheritdoc ILayerrMinter
     */
    function setContractAllowedSigner(address _signer, bool _allowed) external {
        contractAllowedSigner[msg.sender][_signer] = _allowed;

        emit ContractAllowedSignerUpdate(msg.sender, _signer, _allowed);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function setContractAllowedOracle(address _oracle, bool _allowed) external {
        contractAllowedOracle[msg.sender][_oracle] = _allowed;

        emit ContractOracleUpdated(msg.sender, _oracle, _allowed);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function incrementSignerNonce() external {
        unchecked {
            signerNonce[msg.sender] += uint256(
                keccak256(abi.encodePacked(block.timestamp))
            );
        }

        emit SignerNonceIncremented(msg.sender, signerNonce[msg.sender]);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function incrementNonceFor(address signer, bytes calldata signature) external {
        if(!_validateIncrementNonceSigner(signer, signerNonce[signer], signature)) revert InvalidSignatureToIncrementNonce();
        unchecked {
            signerNonce[signer] += uint256(
                keccak256(abi.encodePacked(block.timestamp))
            );
        }

        emit SignerNonceIncremented(signer, signerNonce[signer]);
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function setSignatureValidity(
        bytes32[] calldata signatureDigests,
        bool invalid
    ) external {
        for (uint256 i; i < signatureDigests.length; ) {
            signatureInvalid[msg.sender][signatureDigests[i]] = invalid;
            emit SignatureValidityUpdated(msg.sender, invalid, signatureDigests[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mint(
        MintOrder calldata mintOrder
    ) external payable NonReentrant {
        _processMintOrder(msg.sender, mintOrder, 0);

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintBatch(
        MintOrder[] calldata mintOrders
    ) external payable NonReentrant {
        uint256 suppliedBurnTokenIdIndex = 0;

        for (uint256 orderIndex; orderIndex < mintOrders.length; ) {
            MintOrder calldata mintOrder = mintOrders[orderIndex];

            suppliedBurnTokenIdIndex = _processMintOrder(msg.sender, mintOrder, suppliedBurnTokenIdIndex);

            unchecked {
                ++orderIndex;
            }
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintTo(
        address mintToWallet,
        MintOrder calldata mintOrder,
        uint256 paymentContext
    ) external payable NonReentrant {
        _processMintOrder(mintToWallet, mintOrder, 0);

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @inheritdoc ILayerrMinter
     */
    function mintBatchTo(
        address mintToWallet,
        MintOrder[] calldata mintOrders,
        uint256 paymentContext
    ) external payable NonReentrant {
        uint256 suppliedBurnTokenIdIndex = 0;

        for (uint256 orderIndex; orderIndex < mintOrders.length; ) {
            MintOrder calldata mintOrder = mintOrders[orderIndex];

            suppliedBurnTokenIdIndex = _processMintOrder(mintToWallet, mintOrder, suppliedBurnTokenIdIndex);

            unchecked {
                ++orderIndex;
            }
        }

        uint256 remainingBalance = address(this).balance;
        if (remainingBalance > 0) {
            _transferNative(msg.sender, remainingBalance);
        }
    }

    /**
     * @notice Validates mint parameters, processes payments and burns, mint tokens
     * @param mintToWallet address that tokens will be minted to
     * @param mintOrder struct containing the mint order details
     * @param suppliedBurnTokenIdIndex the current burn token index before processing the mint order
     * @return suppliedBurnTokenIdIndex the current burn token index after processing the mint order
     */
    function _processMintOrder(
        address mintToWallet, 
        MintOrder calldata mintOrder, 
        uint256 suppliedBurnTokenIdIndex
    ) internal returns (uint256) {
        MintParameters calldata mintParameters = mintOrder.mintParameters;
        bytes calldata mintParametersSignature = mintOrder.mintParametersSignature;
        uint256 quantity = mintOrder.quantity;

        (address mintParametersSigner, bytes32 mintParametersDigest) = _recoverMintParametersSigner(
            mintParameters,
            mintParametersSignature
        );

        (bool useDelegate, address oracleSigner) = _validateMintParameters(mintToWallet, mintOrder, mintParametersSignature, mintParametersSigner, mintParametersDigest);

        _processPayments(
            quantity,
            mintParameters.paymentTokens,
            mintOrder.referrer
        );
        if(mintParameters.burnTokens.length > 0) {
            suppliedBurnTokenIdIndex = _processBurns(
                quantity,
                suppliedBurnTokenIdIndex,
                mintParameters.burnTokens,
                mintOrder.suppliedBurnTokenIds
            );
        }

        address mintCountWallet;
        if(useDelegate) {
            mintCountWallet = mintOrder.vaultWallet;
        } else {
            mintCountWallet = mintToWallet;
        }
        
        _processMints(
            mintParameters.mintTokens,
            mintParametersSigner,
            mintParametersDigest,
            oracleSigner,
            quantity,
            mintCountWallet,
            mintToWallet
        );

        emit MintOrderFulfilled(mintParametersDigest, mintToWallet, quantity);

        return suppliedBurnTokenIdIndex;
    }

    /**
     * @notice Checks the MintParameters for start/end time compliance, signer nonce, allowlist, signature max uses and oracle signature
     * @param mintToWallet address tokens will be minted to
     * @param mintOrder struct containing the mint order details 
     * @param mintParametersSignature EIP712 signature of the MintParameters
     * @param mintParametersSigner recovered signer of the mintParametersSignature
     * @param mintParametersDigest hash digest of the MintParameters
     * @return useDelegate true for allowlist mint that mintToWallet 
     * @return oracleSigner recovered address of the oracle signer if oracle signature is required or address(0) if oracle signature is not required
     */
    function _validateMintParameters(
        address mintToWallet, 
        MintOrder calldata mintOrder, 
        bytes calldata mintParametersSignature, 
        address mintParametersSigner, 
        bytes32 mintParametersDigest
    ) internal returns(bool useDelegate, address oracleSigner) {
        MintParameters calldata mintParameters = mintOrder.mintParameters;
        if (mintParameters.startTime > block.timestamp) {
            revert MintHasNotStarted();
        }
        if (mintParameters.endTime < block.timestamp) {
            revert MintHasEnded();
        }
        if (signerNonce[mintParametersSigner] != mintParameters.nonce) {
            revert SignerNonceInvalid();
        }
        if (mintParameters.merkleRoot != bytes32(0)) {
            if (
                !MerkleProof.verifyCalldata(
                    mintOrder.merkleProof,
                    mintParameters.merkleRoot,
                    keccak256(abi.encodePacked(mintToWallet))
                )
            ) {
                address vaultWallet = mintOrder.vaultWallet;
                if(vaultWallet == address(0)) {
                    revert InvalidMerkleProof();
                } else {
                    // check delegate for all first as it's more likely than delegate for contract, saves 3200 gas
                    if(!delegateCash.checkDelegateForAll(mintToWallet, vaultWallet)) {
                        if(!delegateCash.checkDelegateForContract(mintToWallet, vaultWallet, address(this))) {
                            revert InvalidMerkleProof();
                        }
                    }
                    if (
                        MerkleProof.verifyCalldata(
                            mintOrder.merkleProof,
                            mintParameters.merkleRoot,
                            keccak256(abi.encodePacked(vaultWallet))
                        )
                    ) {
                        useDelegate = true;
                    } else {
                        revert InvalidMerkleProof();
                    }
                }
            }
        }
        
        if (mintParameters.signatureMaxUses != 0) {
            signatureUseCount[mintParametersDigest] += mintOrder.quantity;
            if (signatureUseCount[mintParametersDigest] > mintParameters.signatureMaxUses) {
                revert ExceedsMaxSignatureUsage();
            }
        }

        if(mintParameters.oracleSignatureRequired) {
            oracleSigner = _recoverOracleSigner(mintToWallet, mintParametersSignature, mintOrder.oracleSignature);
            if(oracleSigner == address(0)) {
                revert InvalidOracleSignature();
            }
        }
    }

    /**
     * @notice Iterates over payment tokens and sends payment amounts to recipients. 
     *         If there is a referrer and a payment token has a referralBPS the referral amount is split and sent to the referrer
     *         Payment token types can be native token or ERC20.
     * @param mintOrderQuantity multipier for each payment token
     * @param paymentTokens array of payment tokens for a mint order
     * @param referrer wallet address of user that made the referral for this sale
     */
    function _processPayments(
        uint256 mintOrderQuantity,
        PaymentToken[] calldata paymentTokens,
        address referrer
    ) internal {
        for (uint256 paymentTokenIndex = 0; paymentTokenIndex < paymentTokens.length; ) {
            PaymentToken calldata paymentToken = paymentTokens[paymentTokenIndex];
            uint256 paymentAmount = paymentToken.paymentAmount * mintOrderQuantity;
            uint256 tokenType = paymentToken.tokenType;

            if (tokenType == TOKEN_TYPE_NATIVE) {
                if(referrer == address(0) || paymentToken.referralBPS == 0) {
                    _transferNative(paymentToken.payTo, paymentAmount);
                } else {
                    uint256 referrerPayment = paymentAmount * paymentToken.referralBPS / 10000;
                    _transferNative(referrer, referrerPayment);
                    paymentAmount -= referrerPayment;
                    _transferNative(paymentToken.payTo, paymentAmount);
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                if(referrer == address(0) || paymentToken.referralBPS == 0) {
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        paymentToken.payTo,
                        paymentAmount
                    );
                } else {
                    uint256 referrerPayment = paymentAmount * paymentToken.referralBPS / 10000;
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        referrer,
                        referrerPayment
                    );
                    paymentAmount -= referrerPayment;
                    _transferERC20(
                        paymentToken.contractAddress,
                        msg.sender,
                        paymentToken.payTo,
                        paymentAmount
                    );
                }
            } else {
                revert InvalidPaymentTokenType();
            }
            unchecked {
                ++paymentTokenIndex;
            }
        }
    }

    /**
     * @notice Processes burns for a mint order. Burn tokens can be ERC20, ERC721, or ERC1155. Burn types can be
     *         contract burns or send to dead address.
     * @param mintOrderQuantity multiplier for each burn token
     * @param suppliedBurnTokenIdIndex current index for the supplied burn token ids before processing burns
     * @param burnTokens array of burn tokens for a mint order
     * @param suppliedBurnTokenIds array of burn token ids supplied by minter
     * @return suppliedBurnTokenIdIndex current index for the supplied burn token ids after processing burns
     */
    function _processBurns(
        uint256 mintOrderQuantity,
        uint256 suppliedBurnTokenIdIndex,
        BurnToken[] calldata burnTokens,
        uint256[] calldata suppliedBurnTokenIds
    ) internal returns (uint256) {
        for (uint256 burnTokenIndex = 0; burnTokenIndex < burnTokens.length; ) {
            BurnToken calldata burnToken = burnTokens[burnTokenIndex];

            address contractAddress = burnToken.contractAddress;
            uint256 tokenId = burnToken.tokenId;
            bool specificTokenId = burnToken.specificTokenId;
            uint256 burnType = burnToken.burnType;
            uint256 tokenType = burnToken.tokenType;
            uint256 burnAmount = burnToken.burnAmount * mintOrderQuantity;

            if (tokenType == TOKEN_TYPE_ERC1155) {
                uint256 burnTokenEnd = burnTokenIndex;
                for (; burnTokenEnd < burnTokens.length; ) {
                    if (burnTokens[burnTokenEnd].contractAddress != contractAddress) {
                        break;
                    }
                    unchecked {
                        ++burnTokenEnd;
                    }
                }
                unchecked { --burnTokenEnd; }
                if (burnTokenEnd == burnTokenIndex) {
                    if (specificTokenId) {
                        if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                            revert InvalidBurnTokenId();
                        }
                    }
                    if (burnType == BURN_TYPE_CONTRACT_BURN) {
                        ILayerr1155(contractAddress).burnTokenId(
                            msg.sender,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex],
                            burnAmount
                        );
                    } else if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                        IERC1155(contractAddress).safeTransferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex],
                            burnAmount,
                            ""
                        );
                    } else {
                        revert InvalidBurnType();
                    }
                    unchecked {
                        ++suppliedBurnTokenIdIndex;
                    }
                } else {
                    unchecked {
                        ++burnTokenEnd;
                    }
                    uint256[] memory burnTokenIds = new uint256[]((burnTokenEnd - burnTokenIndex));
                    uint256[] memory burnTokenAmounts = new uint256[]((burnTokenEnd - burnTokenIndex));
                    for (uint256 arrayIndex = 0; burnTokenIndex < burnTokenEnd; ) {
                        burnToken = burnTokens[burnTokenIndex];
                        specificTokenId = burnToken.specificTokenId;
                        tokenId = burnToken.tokenId;
                        burnAmount = burnToken.burnAmount * mintOrderQuantity;

                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }

                        burnTokenIds[arrayIndex] = suppliedBurnTokenIds[suppliedBurnTokenIdIndex];
                        burnTokenAmounts[arrayIndex] = burnAmount;
                        unchecked {
                            ++burnTokenIndex;
                            ++arrayIndex;
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                    unchecked {
                        --burnTokenIndex;
                    }
                    if (burnType == BURN_TYPE_CONTRACT_BURN) {
                        ILayerr1155(contractAddress).burnBatchTokenIds(
                            msg.sender,
                            burnTokenIds,
                            burnTokenAmounts
                        );
                    } else if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                        IERC1155(contractAddress).safeBatchTransferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            burnTokenIds,
                            burnTokenAmounts,
                            ""
                        );
                    } else {
                        revert InvalidBurnType();
                    }
                }
            } else if (tokenType == TOKEN_TYPE_ERC721) {
                if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                    if (burnAmount > 1) {
                        if (specificTokenId) {
                            revert CannotBurnMultipleERC721WithSameId();
                        }
                        for (uint256 burnCounter = 0; burnCounter < burnAmount; ) {
                            IERC721(contractAddress).transferFrom(
                                msg.sender,
                                DEAD_ADDRESS,
                                suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                            );
                            unchecked {
                                ++burnCounter;
                                ++suppliedBurnTokenIdIndex;
                            }
                        }
                    } else {
                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }
                        IERC721(contractAddress).transferFrom(
                            msg.sender,
                            DEAD_ADDRESS,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                        );
                        unchecked {
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                } else if (burnType == BURN_TYPE_CONTRACT_BURN) {
                    if (burnAmount > 1) {
                        if (specificTokenId) {
                            revert CannotBurnMultipleERC721WithSameId();
                        }
                        uint256[] memory burnTokenIds = new uint256[](burnAmount);
                        for (uint256 arrayIndex = 0; arrayIndex < burnAmount;) {
                            burnTokenIds[arrayIndex] = suppliedBurnTokenIds[suppliedBurnTokenIdIndex];
                            unchecked {
                                ++arrayIndex;
                                ++suppliedBurnTokenIdIndex;
                            }
                        }
                        ILayerr721(contractAddress).burnBatchTokenIds(msg.sender, burnTokenIds);
                    } else {
                        if (specificTokenId) {
                            if (tokenId != suppliedBurnTokenIds[suppliedBurnTokenIdIndex]) {
                                revert InvalidBurnTokenId();
                            }
                        }
                        ILayerr721(contractAddress).burnTokenId(
                            msg.sender,
                            suppliedBurnTokenIds[suppliedBurnTokenIdIndex]
                        );
                        unchecked {
                            ++suppliedBurnTokenIdIndex;
                        }
                    }
                } else {
                    revert InvalidBurnType();
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                if (burnType == BURN_TYPE_SEND_TO_DEAD) {
                    _transferERC20(
                        contractAddress,
                        msg.sender,
                        DEAD_ADDRESS,
                        burnAmount
                    );
                } else if (burnType == BURN_TYPE_CONTRACT_BURN) {
                    ILayerr20(contractAddress).burn(msg.sender, burnAmount);
                } else {
                    revert InvalidBurnType();
                }
            } else {
                revert InvalidBurnTokenType();
            }
            unchecked {
                ++burnTokenIndex;
            }
        }

        return suppliedBurnTokenIdIndex;
    }

    /**
     * @notice Processes mints for a mint order. Token types can be ERC20, ERC721, or ERC1155. 
     * @param mintTokens array of mint tokens from the mint order
     * @param mintParametersSigner recovered address from the mint parameters signature
     * @param mintParametersDigest hash digest of the supplied mint parameters
     * @param oracleSigner recovered address of the oracle signer if oracle signature required was true, address(0) otherwise
     * @param mintOrderQuantity multiplier for each mint token
     * @param mintCountWallet wallet address that will be used for checking max per wallet mint conditions
     * @param mintToWallet wallet address that tokens will be minted to
     */
    function _processMints(
        MintToken[] calldata mintTokens,
        address mintParametersSigner,
        bytes32 mintParametersDigest,
        address oracleSigner,
        uint256 mintOrderQuantity,
        address mintCountWallet,
        address mintToWallet
    ) internal {
        uint256 mintTokenIndex;
        uint256 mintTokensLength = mintTokens.length;
        for ( ; mintTokenIndex < mintTokensLength; ) {
            MintToken calldata mintToken = mintTokens[mintTokenIndex];

            address contractAddress = mintToken.contractAddress;
            _checkContractSigners(contractAddress, mintParametersSigner, mintParametersDigest, oracleSigner);

            uint256 tokenId = mintToken.tokenId;
            uint256 maxSupply = mintToken.maxSupply;
            uint256 maxMintPerWallet = mintToken.maxMintPerWallet;
            bool specificTokenId = mintToken.specificTokenId;
            uint256 mintAmount = mintToken.mintAmount * mintOrderQuantity;
            uint256 tokenType = mintToken.tokenType;

            if (tokenType == TOKEN_TYPE_ERC1155) {
                uint256 mintTokenEnd = mintTokenIndex;
                for (; mintTokenEnd < mintTokensLength; ) {
                    if (mintTokens[mintTokenEnd].contractAddress != contractAddress) {
                        break;
                    }
                    unchecked {
                        ++mintTokenEnd;
                    }
                }
                unchecked { --mintTokenEnd; }
                if (mintTokenEnd == mintTokenIndex) {
                    _checkERC1155MintQuantities(contractAddress, tokenId, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                    ILayerr1155(contractAddress).mintTokenId(
                        mintCountWallet,
                        mintToWallet,
                        tokenId,
                        mintAmount
                    );
                } else {
                    unchecked {
                        ++mintTokenEnd;
                    }
                    uint256[] memory mintTokenIds = new uint256[]((mintTokenEnd - mintTokenIndex));
                    uint256[] memory mintTokenAmounts = new uint256[]((mintTokenEnd - mintTokenIndex));
                    for (uint256 arrayIndex = 0; mintTokenIndex < mintTokenEnd; ) {
                        mintToken = mintTokens[mintTokenIndex];
                        maxSupply = mintToken.maxSupply;
                        maxMintPerWallet = mintToken.maxMintPerWallet;
                        tokenId = mintToken.tokenId;
                        mintAmount = mintToken.mintAmount * mintOrderQuantity;

                        _checkERC1155MintQuantities(contractAddress, tokenId, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                        mintTokenIds[arrayIndex] = tokenId;
                        mintTokenAmounts[arrayIndex] = mintAmount;
                        unchecked {
                            ++mintTokenIndex;
                            ++arrayIndex;
                        }
                    }
                    unchecked {
                        --mintTokenIndex;
                    }
                    ILayerr1155(contractAddress)
                        .mintBatchTokenIds(
                            mintCountWallet,
                            mintToWallet,
                            mintTokenIds,
                            mintTokenAmounts
                        );
                }
            } else if (tokenType == TOKEN_TYPE_ERC721) {
                _checkERC721MintQuantities(contractAddress, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);

                if (!specificTokenId || mintAmount > 1) {
                    if (specificTokenId) {
                        revert CannotMintMultipleERC721WithSameId();
                    }
                    ILayerr721A(contractAddress).mintSequential(mintCountWallet, mintToWallet, mintAmount);
                } else {
                    ILayerr721(contractAddress).mintTokenId(mintCountWallet, mintToWallet, tokenId);
                }
            } else if (tokenType == TOKEN_TYPE_ERC20) {
                _checkERC20MintQuantities(contractAddress, maxSupply, maxMintPerWallet, mintCountWallet, mintAmount);
                ILayerr20(contractAddress).mint(mintCountWallet, mintToWallet, mintAmount);
            } else {
                revert InvalidMintTokenType();
            }
            unchecked {
                ++mintTokenIndex;
            }
        }
    }

    /**
     * @notice Checks the mint parameters and oracle signers to ensure they are authorized for the token contract.
     *         Checks that the mint parameters signature digest has not been marked as invalid.
     * @param contractAddress token contract to check signers for
     * @param mintParametersSigner recovered signer for the mint parameters
     * @param mintParametersDigest hash digest of the supplied mint parameters 
     * @param oracleSigner recovered oracle signer if oracle signature is required by mint parameters
     */
    function _checkContractSigners(address contractAddress, address mintParametersSigner, bytes32 mintParametersDigest, address oracleSigner) internal view {
        if (!contractAllowedSigner[contractAddress][mintParametersSigner]) {
            revert NotAllowedSigner();
        }
        if (signatureInvalid[contractAddress][mintParametersDigest]) {
            revert SignatureInvalid();
        }
        if(oracleSigner != address(0)) {
            if(!contractAllowedOracle[contractAddress][oracleSigner]) {
                revert InvalidOracleSignature();
            }
        }
    }

    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param tokenId id of the token to check
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC1155MintQuantities(address contractAddress, uint256 tokenId, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr1155(contractAddress).totalMintedCollectionAndMinter(mintCountWallet, tokenId);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }


    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC721MintQuantities(address contractAddress, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr721(contractAddress).totalMintedCollectionAndMinter(mintCountWallet);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }


    /**
     * @notice Calls the token contract to get total minted and minted by wallet, checks against mint parameters max supply and max per wallet
     * @param contractAddress token contract to check mint counts for
     * @param maxSupply maximum supply for a token defined in mint parameters
     * @param maxMintPerWallet maximum per wallet for a token defined in mint parameters
     * @param mintCountWallet wallet to check for minted amount
     * @param mintAmount the amount that will be minted
     */
    function _checkERC20MintQuantities(address contractAddress, uint256 maxSupply, uint256 maxMintPerWallet, address mintCountWallet, uint256 mintAmount) internal view {
        if(maxSupply != 0 || maxMintPerWallet != 0) {
            (uint256 totalMinted, uint256 minterMinted) = ILayerr20(contractAddress).totalMintedTokenAndMinter(mintCountWallet);
            if (maxSupply != 0) {
                if (totalMinted + mintAmount > maxSupply) {
                    revert MintExceedsMaxSupply();
                }
            }
            if (maxMintPerWallet != 0) {
                if (minterMinted + mintAmount > maxMintPerWallet) {
                    revert MintExceedsMaxPerWallet();
                }
            }
        }
    }

    /**
     * @notice Transfers `amount` of native token to `to` address. Reverts if the transfer fails.
     * @param to address to send native token to
     * @param amount amount of native token to send
     */
    function _transferNative(address to, uint256 amount) internal {
        (bool sent, ) = payable(to).call{value: amount}("");
        if (!sent) {
            if(address(this).balance < amount) {
                revert InsufficientPayment();
            } else {
                revert PaymentFailed();
            }
        }
    }

    /**
     * @notice Transfers `amount` of ERC20 token from `from` address to `to` address.
     * @param contractAddress ERC20 token address
     * @param from address to transfer ERC20 tokens from
     * @param to address to send ERC20 tokens to
     * @param amount amount of ERC20 tokens to send
     */
    function _transferERC20(
        address contractAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20(contractAddress).transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Burn type that specifies the token will be burned with a contract call that reduces supply
uint256 constant BURN_TYPE_CONTRACT_BURN = 0;
/// @dev Burn type that specifies the token will be transferred to the 0x000...dead address without reducing supply
uint256 constant BURN_TYPE_SEND_TO_DEAD = 1;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized verification of proof of inclusion for a leaf in a Merkle tree.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/MerkleProof.sol)
library MerkleProof {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*            MERKLE PROOF VERIFICATION OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if mload(proof) {
                // Initialize `offset` to the offset of `proof` elements in memory.
                let offset := add(proof, 0x20)
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(offset, shl(5, mload(proof)))
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, mload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), mload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether `leaf` exists in the Merkle tree with `root`, given `proof`.
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf)
        internal
        pure
        returns (bool isValid)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shift by 5 is equivalent to multiplying by 0x20.
                let end := add(proof.offset, shl(5, proof.length))
                // Initialize `offset` to the offset of `proof` in the calldata.
                let offset := proof.offset
                // Iterate over proof elements to compute root hash.
                for {} 1 {} {
                    // Slot of `leaf` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(leaf, calldataload(offset)))
                    // Store elements to hash contiguously in scratch space.
                    // Scratch space is 64 bytes (0x00 - 0x3f) and both elements are 32 bytes.
                    mstore(scratch, leaf)
                    mstore(xor(scratch, 0x20), calldataload(offset))
                    // Reuse `leaf` to store the hash to reduce stack operations.
                    leaf := keccak256(0x00, 0x40)
                    offset := add(offset, 0x20)
                    if iszero(lt(offset, end)) { break }
                }
            }
            isValid := eq(leaf, root)
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32[] memory leaves,
        bool[] memory flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // Cache the lengths of the arrays.
            let leavesLength := mload(leaves)
            let proofLength := mload(proof)
            let flagsLength := mload(flags)

            // Advance the pointers of the arrays to point to the data.
            leaves := add(0x20, leaves)
            proof := add(0x20, proof)
            flags := add(0x20, flags)

            // If the number of flags is correct.
            for {} eq(add(leavesLength, proofLength), add(flagsLength, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flagsLength) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    isValid := eq(mload(xor(leaves, mul(xor(proof, leaves), proofLength))), root)
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd := mul(iszero(iszero(flagsLength)), add(proof, shl(5, proofLength)))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                leavesLength := shl(5, leavesLength)
                for { let i := 0 } iszero(eq(i, leavesLength)) { i := add(i, 0x20) } {
                    mstore(add(hashesFront, i), mload(add(leaves, i)))
                }
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, leavesLength)
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flagsLength := add(hashesBack, shl(5, flagsLength))

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(mload(flags)) {
                        // Loads the next proof.
                        b := mload(proof)
                        proof := add(proof, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag.
                    flags := add(flags, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flagsLength)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required (i.e. `proofEnd != 0`).
                        or(iszero(proofEnd), eq(proofEnd, proof))
                    )
                break
            }
        }
    }

    /// @dev Returns whether all `leaves` exist in the Merkle tree with `root`,
    /// given `proof` and `flags`.
    function verifyMultiProofCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32[] calldata leaves,
        bool[] calldata flags
    ) internal pure returns (bool isValid) {
        // Rebuilds the root by consuming and producing values on a queue.
        // The queue starts with the `leaves` array, and goes into a `hashes` array.
        // After the process, the last element on the queue is verified
        // to be equal to the `root`.
        //
        // The `flags` array denotes whether the sibling
        // should be popped from the queue (`flag == true`), or
        // should be popped from the `proof` (`flag == false`).
        /// @solidity memory-safe-assembly
        assembly {
            // If the number of flags is correct.
            for {} eq(add(leaves.length, proof.length), add(flags.length, 1)) {} {
                // For the case where `proof.length + leaves.length == 1`.
                if iszero(flags.length) {
                    // `isValid = (proof.length == 1 ? proof[0] : leaves[0]) == root`.
                    // forgefmt: disable-next-item
                    isValid := eq(
                        calldataload(
                            xor(leaves.offset, mul(xor(proof.offset, leaves.offset), proof.length))
                        ),
                        root
                    )
                    break
                }

                // The required final proof offset if `flagsLength` is not zero, otherwise zero.
                let proofEnd :=
                    mul(iszero(iszero(flags.length)), add(proof.offset, shl(5, proof.length)))
                // We can use the free memory space for the queue.
                // We don't need to allocate, since the queue is temporary.
                let hashesFront := mload(0x40)
                // Copy the leaves into the hashes.
                // Sometimes, a little memory expansion costs less than branching.
                // Should cost less, even with a high free memory offset of 0x7d00.
                calldatacopy(hashesFront, leaves.offset, shl(5, leaves.length))
                // Compute the back of the hashes.
                let hashesBack := add(hashesFront, shl(5, leaves.length))
                // This is the end of the memory for the queue.
                // We recycle `flagsLength` to save on stack variables (sometimes save gas).
                flags.length := add(hashesBack, shl(5, flags.length))

                // We don't need to make a copy of `proof.offset` or `flags.offset`,
                // as they are pass-by-value (this trick may not always save gas).

                for {} 1 {} {
                    // Pop from `hashes`.
                    let a := mload(hashesFront)
                    // Pop from `hashes`.
                    let b := mload(add(hashesFront, 0x20))
                    hashesFront := add(hashesFront, 0x40)

                    // If the flag is false, load the next proof,
                    // else, pops from the queue.
                    if iszero(calldataload(flags.offset)) {
                        // Loads the next proof.
                        b := calldataload(proof.offset)
                        proof.offset := add(proof.offset, 0x20)
                        // Unpop from `hashes`.
                        hashesFront := sub(hashesFront, 0x20)
                    }

                    // Advance to the next flag offset.
                    flags.offset := add(flags.offset, 0x20)

                    // Slot of `a` in scratch space.
                    // If the condition is true: 0x20, otherwise: 0x00.
                    let scratch := shl(5, gt(a, b))
                    // Hash the scratch space and push the result onto the queue.
                    mstore(scratch, a)
                    mstore(xor(scratch, 0x20), b)
                    mstore(hashesBack, keccak256(0x00, 0x40))
                    hashesBack := add(hashesBack, 0x20)
                    if iszero(lt(hashesBack, flags.length)) { break }
                }
                isValid :=
                    and(
                        // Checks if the last value in the queue is same as the root.
                        eq(mload(sub(hashesBack, 0x20)), root),
                        // And whether all the proofs are used, if required (i.e. `proofEnd != 0`).
                        or(iszero(proofEnd), eq(proofEnd, proof.offset))
                    )
                break
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   EMPTY CALLDATA HELPERS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an empty calldata bytes32 array.
    function emptyProof() internal pure returns (bytes32[] calldata proof) {
        /// @solidity memory-safe-assembly
        assembly {
            proof.length := 0
        }
    }

    /// @dev Returns an empty calldata bytes32 array.
    function emptyLeaves() internal pure returns (bytes32[] calldata leaves) {
        /// @solidity memory-safe-assembly
        assembly {
            leaves.length := 0
        }
    }

    /// @dev Returns an empty calldata bool array.
    function emptyFlags() internal pure returns (bool[] calldata flags) {
        /// @solidity memory-safe-assembly
        assembly {
            flags.length := 0
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReentrancyGuard
 * @author 0xth0mas (Layerr)
 * @notice Simple reentrancy guard to prevent callers from re-entering the LayerrMinter mint functions
 */
contract ReentrancyGuard {
    uint256 private _reentrancyGuard = 1;
    error ReentrancyProhibited();

    modifier NonReentrant() {
        if (_reentrancyGuard > 1) {
            revert ReentrancyProhibited();
        }
        _reentrancyGuard = 2;
        _;
        _reentrancyGuard = 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {EIP712Domain, MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "./MinterStructs.sol";
import {EIP712_DOMAIN_TYPEHASH, MINTPARAMETERS_TYPEHASH, MINTTOKEN_TYPEHASH, BURNTOKEN_TYPEHASH, PAYMENTTOKEN_TYPEHASH} from "./TypeHashes.sol";

/**
 * @title SignatureVerification
 * @author 0xth0mas (Layerr)
 * @author Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/EIP712.sol)
 * @author Modified from Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/EIP712.sol)
 * @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol)
 * @notice Recovers the EIP712 signer for MintParameters and oracle signers
 *         for the LayerrMinter contract.
 */
contract SignatureVerification {
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    string private constant _name = "LayerrMinter";
    string private constant _version = "1.0";

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    constructor() {
        _hashedName = keccak256(bytes(_name));
        _hashedVersion = keccak256(bytes(_version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }
    
    /**
     * @notice Recovers the signer address for the supplied mint parameters and signature
     * @param input MintParameters to recover the signer for
     * @param signature Signature for the MintParameters `_input` to recover signer
     * @return signer recovered signer of `signature` and `_input`
     * @return digest hash digest of `_input`
     */
    function _recoverMintParametersSigner(
        MintParameters calldata input,
        bytes calldata signature
    ) internal view returns (address signer, bytes32 digest) {
        bytes32 hash = _getMintParametersHash(input);
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), hash)
        );
        signer = _recover(digest, signature);
    }

    /**
     * @notice Recovers the signer address for the supplied oracle signature
     * @param minter address of wallet performing the mint
     * @param mintParametersSignature signature of MintParameters to check oracle signature of
     * @param oracleSignature supplied oracle signature
     * @return signer recovered oracle signer address
     */
    function _recoverOracleSigner(
        address minter, 
        bytes calldata mintParametersSignature, 
        bytes calldata oracleSignature
    ) internal pure returns(address signer) {
        bytes32 digest = keccak256(abi.encodePacked(minter, mintParametersSignature));
        signer = _recover(digest, oracleSignature);
    }

    /**
     * @notice Recovers the signer address for the increment nonce transaction
     * @param signer address of the account to increment nonce
     * @param currentNonce current nonce for the signer account
     * @param signature signature of message to validate
     * @return valid if the signature came from the signer
     */
    function _validateIncrementNonceSigner(
        address signer, 
        uint256 currentNonce,
        bytes calldata signature
    ) internal view returns(bool valid) {
        unchecked {
            // add chain id to current nonce to guard against replay on other chains
            currentNonce += block.chainid;
        }
        bytes memory nonceString = bytes(_toString(currentNonce));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", _toString(nonceString.length), nonceString));
        valid = signer == _recover(digest, signature) && signer != address(0);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparator() private view returns (bytes32 separator) {
        separator = _cachedDomainSeparator;
        if (_cachedDomainSeparatorInvalidated()) {
            separator = _buildDomainSeparator();
        }
    }

    /**
     *  @dev Returns if the cached domain separator has been invalidated.
     */ 
    function _cachedDomainSeparatorInvalidated() private view returns (bool result) {
        uint256 cachedChainId = _cachedChainId;
        address cachedThis = _cachedThis;
        /// @solidity memory-safe-assembly
        assembly {
            result := iszero(and(eq(chainid(), cachedChainId), eq(address(), cachedThis)))
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    _hashedName,
                    _hashedVersion,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Recover signer address from a message by using their signature
     * @param hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
     * @param sig bytes signature, the signature is generated using web3.eth.sign()
     */
    function _recover(
        bytes32 hash,
        bytes calldata sig
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Check the signature length
        if (sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        /// @solidity memory-safe-assembly
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            str := sub(m, 0x20)
            mstore(str, 0)
            let end := str

            for { let temp := value } 1 {} {
                str := sub(str, 1)
                mstore8(str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            str := sub(str, 0x20)
            mstore(str, length)
        }
    }

    function _getMintTokenArrayHash(
        MintToken[] calldata mintTokens
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint256 i = 0; i < mintTokens.length; ) {
            encoded = abi.encodePacked(encoded, _getMintTokenHash(mintTokens[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getBurnTokenArrayHash(
        BurnToken[] calldata burnTokens
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint256 i = 0; i < burnTokens.length; ) {
            encoded = abi.encodePacked(encoded, _getBurnTokenHash(burnTokens[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getPaymentTokenArrayHash(
        PaymentToken[] calldata paymentTokens
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded;
        for (uint256 i = 0; i < paymentTokens.length; ) {
            encoded = abi.encodePacked(encoded, _getPaymentTokenHash(paymentTokens[i]));
            unchecked {
                ++i;
            }
        }
        hash = keccak256(encoded);
    }

    function _getMintTokenHash(
        MintToken calldata mintToken
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                MINTTOKEN_TYPEHASH,
                mintToken.contractAddress,
                mintToken.specificTokenId,
                mintToken.tokenType,
                mintToken.tokenId,
                mintToken.mintAmount,
                mintToken.maxSupply,
                mintToken.maxMintPerWallet
            )
        );
    }

    function _getBurnTokenHash(
        BurnToken calldata burnToken
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                BURNTOKEN_TYPEHASH,
                burnToken.contractAddress,
                burnToken.specificTokenId,
                burnToken.tokenType,
                burnToken.burnType,
                burnToken.tokenId,
                burnToken.burnAmount
            )
        );
    }

    function _getPaymentTokenHash(
        PaymentToken calldata paymentToken
    ) internal pure returns (bytes32 hash) {
        hash = keccak256(
            abi.encode(
                PAYMENTTOKEN_TYPEHASH,
                paymentToken.contractAddress,
                paymentToken.tokenType,
                paymentToken.payTo,
                paymentToken.paymentAmount,
                paymentToken.referralBPS
            )
        );
    }

    function _getMintParametersHash(
        MintParameters calldata mintParameters
    ) internal pure returns (bytes32 hash) {
        bytes memory encoded = abi.encode(
            MINTPARAMETERS_TYPEHASH,
            _getMintTokenArrayHash(mintParameters.mintTokens),
            _getBurnTokenArrayHash(mintParameters.burnTokens),
            _getPaymentTokenArrayHash(mintParameters.paymentTokens),
            mintParameters.startTime,
            mintParameters.endTime,
            mintParameters.signatureMaxUses,
            mintParameters.merkleRoot,
            mintParameters.nonce,
            mintParameters.oracleSignatureRequired
        );
        hash = keccak256(encoded);
    }

    function getMintParametersSignatureDigest(
        MintParameters calldata mintParameters
    ) external view returns (bytes32 digest) {
        bytes32 hash = _getMintParametersHash(mintParameters);
        digest = keccak256(
            abi.encodePacked("\x19\x01", _domainSeparator(), hash)
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Token type used for payment tokens to specify payment is in the blockchain native token
uint256 constant TOKEN_TYPE_NATIVE  = 0;
/// @dev Token type used for payments, mints and burns to specify the token is an ERC20
uint256 constant TOKEN_TYPE_ERC20 = 1;
/// @dev Token type used for mints and burns to specify the token is an ERC721
uint256 constant TOKEN_TYPE_ERC721 = 2;
/// @dev Token type used for mints and burns to specify the token is an ERC1155
uint256 constant TOKEN_TYPE_ERC1155 = 3;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

bytes32 constant EIP712_DOMAIN_TYPEHASH = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
);

bytes32 constant MINTPARAMETERS_TYPEHASH = keccak256(
    "MintParameters(MintToken[] mintTokens,"
    "BurnToken[] burnTokens,"
    "PaymentToken[] paymentTokens,"
    "uint256 startTime,"
    "uint256 endTime,"
    "uint256 signatureMaxUses,"
    "bytes32 merkleRoot,"
    "uint256 nonce,"
    "bool oracleSignatureRequired)"
    "BurnToken(address contractAddress,"
    "bool specificTokenId,"
    "uint8 tokenType,"
    "uint8 burnType,"
    "uint256 tokenId,"
    "uint256 burnAmount)"
    "MintToken(address contractAddress,"
    "bool specificTokenId,"
    "uint8 tokenType,"
    "uint256 tokenId,"
    "uint256 mintAmount,"
    "uint256 maxSupply,"
    "uint256 maxMintPerWallet)"
    "PaymentToken(address contractAddress,"
    "uint8 tokenType,"
    "address payTo,"
    "uint256 paymentAmount,"
    "uint256 referralBPS)"
);

bytes32 constant MINTTOKEN_TYPEHASH = keccak256(
    "MintToken(address contractAddress,bool specificTokenId,uint8 tokenType,uint256 tokenId,uint256 mintAmount,uint256 maxSupply,uint256 maxMintPerWallet)"
);

bytes32 constant BURNTOKEN_TYPEHASH = keccak256(
    "BurnToken(address contractAddress,bool specificTokenId,uint8 tokenType,uint8 burnType,uint256 tokenId,uint256 burnAmount)"
);

bytes32 constant PAYMENTTOKEN_TYPEHASH = keccak256(
    "PaymentToken(address contractAddress,uint8 tokenType,address payTo,uint256 paymentAmount,uint256 referralBPS)"
);