/**
 *Submitted for verification at Arbiscan.io on 2024-06-16
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/common/ERC2981.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/ERC1155.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
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
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
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
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
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
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
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
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
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
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
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
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// File: contracts/TheGame.sol


pragma solidity 0.8.25;





contract TheChroniclesOfAstrinea_NFTcollection_Arbitrum is ERC1155, ERC2981 {

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// basic setup
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    address private _owner;
    address private _game;
    constructor() ERC1155("") {_owner = msg.sender; _setDefaultRoyalty(_owner, 250);}
    modifier onlyOwner() {if (_owner != msg.sender) {revert genericError();} _;}
    modifier onlyGame() {if (_game != msg.sender) {revert genericError();} _;}
    string public name = "The Chronicles of Astrinea - Arbitrum";
    mapping(uint256 => string) internal baseURIs;
    uint256 private nonce = 0;
    error genericError();
    function setBaseURI(uint256 skin, string memory _uri) external onlyOwner {baseURIs[skin] = _uri;} // URI prefix (constant part of URI for each skin)
    function setGameContract(address game) external onlyOwner {_game = game;}




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// internal game content
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    mapping(uint256 => uint256) internal Content_ID;                        // NFT ID mapping to the game content ID
    mapping(uint256 => mapping(uint256 => string)) internal Content_uriID;  // static part of the URI: Content_ID => skin => URI
    mapping(uint256 => string) internal Content_Name;
    mapping(uint256 => uint256) internal Content_GoodOrEvil;                // 0 = devil, 100 = saint
    mapping(uint256 => uint256) internal Content_Type;                      // 0 = material, 1 = one handed weapon, 2 = two handed weapon, 3 = bow, 4 = staff, 5 = shield, 6 = armor, 7 = character or monster, 8 = NPC
    mapping(uint256 => uint256) internal Content_Rarity;                    // 0 = unspecified, 1 = Common, 2 = Standard, 3 = Rare, 4 = Exceptional, 5 = Legendary, 6 = Mythical
    mapping(uint256 => uint256) internal Content_PotentialEffect;           // 0 = unused, 1 = damage +2, 2 = agility +2, 3 = health +20, 4 = armor +2, 5 = block +1

    mapping(uint256 => mapping(uint256 => bool)) public skinAvailable;      // skinAvailable[Content_ID][skin]

    mapping(uint256 => int256) internal Content_MinDmg;
    mapping(uint256 => int256) internal Content_MinAgility;
    mapping(uint256 => int256) internal Content_MinHealth;
    mapping(uint256 => int256) internal Content_MinArmor;
    mapping(uint256 => int256) internal Content_Block;
    mapping(uint256 => int256) internal Content_Range;
    mapping(uint256 => uint256) internal Content_PartyPoints;                 // how much space content occupies in the party
    mapping(uint256 => bool) internal Content_UseEquipment;                   // whether the character can use equipment or not

    mapping(uint256 => int256) internal Content_Skill_1_Area;                 // affected tiles around target
    mapping(uint256 => int256) internal Content_Skill_1_Range;                // max agility points between the character and target
    mapping(uint256 => int256) internal Content_Skill_1_DamagePercentage;     // percentage of character's damage used as skill damage
    mapping(uint256 => int256) internal Content_Skill_1_Cooldown;             // how many full team rotations it takes for the skill to be available again
    mapping(uint256 => int256) internal Content_Skill_1_Cost;
    mapping(uint256 => uint256) internal Content_Skill_1_SpecialEffect;       // 0 = no special effect, 1 = stun, 2 = dmg converted to ally heal, 3 = self dmg buff, 4 = target(s) dmg buff
    mapping(uint256 => uint256) internal Content_Skill_WeaponType;            // weapon required to use skills

    mapping(uint256 => int256) internal Content_Skill_2_Area;
    mapping(uint256 => int256) internal Content_Skill_2_Range;
    mapping(uint256 => int256) internal Content_Skill_2_DamagePercentage;
    mapping(uint256 => int256) internal Content_Skill_2_Cooldown;
    mapping(uint256 => int256) internal Content_Skill_2_Cost;
    mapping(uint256 => uint256) internal Content_Skill_2_SpecialEffect;

    mapping(uint256 => uint256) internal content_Ranges;
    // fungible equip: 0;   fungible monsters: general 10; forest 20; dark places 30; undead 40; savanna 50; desert 60;
    // player character: 100;   rare equip: 200;    exceptional equip: 210;    legendary equip: 220
    // rare characters: 300;    rare monsters: angels 310; demons 320; general 330; forest 340; dark places 350; undead 360; savanna 370; desert 380;
    // exceptional characters: 400;     exceptional monsters: angels 410; demons 420; general 430; forest 440; dark places 450; undead 460; savanna 470; desert 480;
    // legendary characters: 500;     legendary monsters: angels 510; demons 520; general 530; forest 540; dark places 550; undead 560; savanna 570; desert 580;
    // mythical monsters: 600;     NPCs/bosses: 610;

    function setContent(uint256 contentID, string memory contentName, uint256 contentType, uint256 rarity) internal {
        if (contentID <= 199) {Content_ID[contentID] = contentID;} // if content is fungible, NFT ID is static and matches content ID
        Content_Name[contentID] = contentName;
        Content_Type[contentID] = contentType;
        Content_Rarity[contentID] = rarity;
    }
    function setContentAttributes(uint256 contentID, int256 minDmg, int256 minAgility, int256 minHealth, int256 minArmor, int256 damageBlock, int256 range, uint256 partyPoints, bool useEquipment, uint256 GoodOrEvil) internal {
        Content_MinDmg[contentID] = minDmg;
        Content_MinAgility[contentID] = minAgility;
        Content_MinHealth[contentID] = minHealth;
        Content_MinArmor[contentID] = minArmor;
        Content_Block[contentID] = damageBlock;
        Content_Range[contentID] = range;
        Content_PartyPoints[contentID] = partyPoints;
        Content_UseEquipment[contentID] = useEquipment;
        Content_GoodOrEvil[contentID] = GoodOrEvil;
    }
    function setCharacterSkill_1(uint256 contentID, int256 Area, int256 Range, int256 DamagePercentage, int256 Cooldown, int256 Cost, uint256 SpecialEffect, uint256 weaponType, uint256 potentialEffect) internal {
        Content_Skill_1_Area[contentID] = Area;
        Content_Skill_1_Range[contentID] = Range;
        Content_Skill_1_DamagePercentage[contentID] = DamagePercentage;
        Content_Skill_1_Cooldown[contentID] = Cooldown;
        Content_Skill_1_Cost[contentID] = Cost;
        Content_Skill_1_SpecialEffect[contentID] = SpecialEffect;
        Content_Skill_WeaponType[contentID] = weaponType;
        Content_PotentialEffect[contentID] = potentialEffect;
    }
    function setCharacterSkill_2(uint256 contentID, int256 Area, int256 Range, int256 DamagePercentage, int256 Cooldown, int256 Cost, uint256 SpecialEffect) internal {
        Content_Skill_2_Area[contentID] = Area;
        Content_Skill_2_Range[contentID] = Range;
        Content_Skill_2_DamagePercentage[contentID] = DamagePercentage;
        Content_Skill_2_Cooldown[contentID] = Cooldown;
        Content_Skill_2_Cost[contentID] = Cost;
        Content_Skill_2_SpecialEffect[contentID] = SpecialEffect;
    }
    function batchSetContent(uint256[] memory contentID, string[] memory contentName, uint256[] memory contentType, uint256[] memory rarity) external onlyOwner { unchecked {
        for (uint256 i = 0; i < contentID.length; i++) {
            setContent(contentID[i], contentName[i], contentType[i], rarity[i]);
        }
    }}
    function batchSetUriIDs(uint256[] memory ContentIDs, string[] memory uriIDs, uint256 skin, bool skinAvailability) external onlyOwner { unchecked {
        for (uint256 i = 0; i < ContentIDs.length; i++) {
            uint256 contentID = ContentIDs[i];
            if ((contentID <= 199) && (skin >= 1)) {revert genericError();} // fungible content can't have alternative skins
            Content_uriID[contentID][skin] = uriIDs[i];
            skinAvailable[contentID][skin] = skinAvailability;
    }}}
    function batchSetContentAttributes(uint256[] memory contentID, int256[] memory minDmg, int256[] memory minAgility, int256[] memory minHealth, int256[] memory minArmor, int256[] memory damageBlock, int256[] memory range, uint256[] memory partyPoints, bool[] memory useEquipment, uint256[] memory GoodOrEvil) external onlyOwner { unchecked {
        for (uint256 i = 0; i < contentID.length; i++) {
            setContentAttributes(contentID[i], minDmg[i], minAgility[i], minHealth[i], minArmor[i], damageBlock[i], range[i], partyPoints[i], useEquipment[i], GoodOrEvil[i]);
        }
    }}
    function batchSetCharacterSkill_1(uint256[] memory contentID, int256[] memory Area, int256[] memory Range, int256[] memory DamagePercentage, int256[] memory Cooldown, int256[] memory Cost, uint256[] memory SpecialEffect, uint256[] memory weaponType, uint256[] memory potentialEffect) external onlyOwner { unchecked {
    for (uint256 i = 0; i < contentID.length; i++) {
            setCharacterSkill_1(contentID[i], Area[i], Range[i], DamagePercentage[i], Cooldown[i], Cost[i], SpecialEffect[i], weaponType[i], potentialEffect[i]);
        }
    }}
    function batchSetCharacterSkill_2(uint256[] memory contentID, int256[] memory Area, int256[] memory Range, int256[] memory DamagePercentage, int256[] memory Cooldown, int256[] memory Cost, uint256[] memory SpecialEffect) external onlyOwner { unchecked {
    for (uint256 i = 0; i < contentID.length; i++) {
            setCharacterSkill_2(contentID[i], Area[i], Range[i], DamagePercentage[i], Cooldown[i], Cost[i], SpecialEffect[i]);
        }
    }}
    function setContentRange(uint256 contentGroup, uint256 Min, uint256 Max) internal { unchecked {
        if ((Min > Max) || ((contentGroup % 10) != 0)) {revert genericError();}
        content_Ranges[contentGroup] = Min;
        content_Ranges[contentGroup+1] = Max;
    }}
    function batchSetContentRanges(uint256[] memory contentGroup, uint256[] memory Min, uint256[] memory Max) external onlyOwner { unchecked {
    for (uint256 i = 0; i < contentGroup.length; i++) {
            setContentRange(contentGroup[i], Min[i], Max[i]);
        }
    }}





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// individual NFT minting and parameters
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    uint256 internal lastMintedNFT = 199;
    mapping(uint256 => mapping(uint256 => uint256[])) internal burnedIDs;    // [NFT ID][skin][array items]
    mapping(uint256 => uint256) internal precalculatedExpToLevelUp;
    mapping(uint256 => int256) internal levelMultiplier;

    mapping(address => uint256) public PlayerCharacters;
    mapping(address => uint256) internal PlayerCharacters_SkillsSet;         // 0 = not set, 1 = skill 1 only, 2 = both skills set
    mapping(address => uint256) internal Player_Skill_WeaponType;            // weapon required to use skills

    mapping(address => int256) internal Player_Skill_1_Area;                 // affected tiles around target - 90° movement = 10 agility points, 45° movement = 15 agility points
    mapping(address => int256) internal Player_Skill_1_Range;                // max number of agility points between the character and target
    mapping(address => int256) internal Player_Skill_1_DamagePercentage;     // percentage of character's damage used as skill damage
    mapping(address => int256) internal Player_Skill_1_Cooldown;             // how many full team rotations it takes for the skill to be available again
    mapping(address => int256) internal Player_Skill_1_Cost;
    mapping(address => uint256) internal Player_Skill_1_SpecialEffect;       // 0 = no special effect, 1 = stun, 2 = dmg converted to ally heal, 3 = self dmg buff, 4 = target(s) dmg buff
    mapping(address => int256) internal Player_Skill_2_Area;
    mapping(address => int256) internal Player_Skill_2_Range;
    mapping(address => int256) internal Player_Skill_2_DamagePercentage;
    mapping(address => int256) internal Player_Skill_2_Cooldown;
    mapping(address => int256) internal Player_Skill_2_Cost;
    mapping(address => uint256) internal Player_Skill_2_SpecialEffect;

    mapping(address => mapping(uint256 => uint256)) internal fungibleExp;
    mapping(address => mapping(uint256 => uint256)) internal fungibleLevels;
    mapping(uint256 => uint256) internal nonFungibleExp;
    mapping(uint256 => uint256) internal nonFungibleLevels;

    mapping(uint256 => int256) internal NFT_Damage;
    mapping(uint256 => int256) internal NFT_Agility;
    mapping(uint256 => int256) internal NFT_Health;
    mapping(uint256 => int256) internal NFT_Armor;
    mapping(uint256 => uint256) public selectedSkin;
    mapping(uint256 => int256) internal potential;

//randomNumberSeed % 1000; (randomNumberSeed / 10) % 1000; etc. ...  max 74 numbers with overlap, or with dividing by 1000 max 24 independent numbers
    function randomNumber() internal returns (uint256) {
        unchecked {nonce++;}
        return uint256(keccak256(abi.encodePacked(blockhash(block.number), block.timestamp, nonce)));
    }
    function batchSetExpToLevelUp(uint256[] memory expTable) external onlyOwner { unchecked {
        for (uint256 i = 0; i < expTable.length; i++) {
            precalculatedExpToLevelUp[i+1] = expTable[i];
        }
    }}
    function batchSetLevelMultipliers(int256[] memory multipliers) external onlyOwner { unchecked {
        for (uint256 i = 0; i < multipliers.length; i++) {
            levelMultiplier[i+1] = multipliers[i];
        }
    }}
    function mintMaterial(address player, uint256 contentID, uint256 amount) external onlyGame {
        if (contentID >= content_Ranges[0]) {revert genericError();}
        _mint(player, contentID, amount, "");
    }
    function createPlayerCharacter(uint256 contentID, int256 damage, int256 agility, int256 armor, uint256 weaponType) external {
        address player = msg.sender;
        uint256 CurrentPlayerCharacter = PlayerCharacters[player];
        if ((contentID > content_Ranges[101]) || (contentID < content_Ranges[100])) {revert genericError();}
        if ((damage<=59) || (agility<=64) || (armor<=59) || (damage>=111) || (agility>=101) || (armor>=111) || (weaponType>=6) || (weaponType==0)) {revert genericError();}
        int256 health;
        unchecked {health = 3724 - 10*(damage + agility + armor);}
        if (CurrentPlayerCharacter >= 1) {
            _burn (player, CurrentPlayerCharacter, 1);                                                                                // burns player's current character if it's already created
            burnedIDs[Content_ID[CurrentPlayerCharacter]][selectedSkin[CurrentPlayerCharacter]].push(CurrentPlayerCharacter);         // adds burned ID to the list of IDs that can be reused when minting identical content
            PlayerCharacters_SkillsSet[player] = 0;                                                                                   // allows player to set both skills again
        }
        uint256 NFT_ID;
        if (burnedIDs[contentID][0].length >= 1) {unchecked{NFT_ID = burnedIDs[contentID][0][burnedIDs[contentID][0].length - 1];} burnedIDs[contentID][0].pop();} else {unchecked {lastMintedNFT++;} NFT_ID = lastMintedNFT;}
        _mint(player, NFT_ID, 1, "");
        NFT_Damage[NFT_ID] = damage;
        NFT_Agility[NFT_ID] = agility;
        NFT_Health[NFT_ID] = health;
        NFT_Armor[NFT_ID] = armor;
        Player_Skill_WeaponType[player] = weaponType;
        Content_ID[NFT_ID] = contentID;
        nonFungibleLevels[NFT_ID] = 1;
        nonFungibleExp[NFT_ID] = 0;
        PlayerCharacters[player] = NFT_ID;
        potential[NFT_ID] = 0;
    }
    function addPlayerCharacterSkill_1(int256 Area, int256 Range, int256 Cooldown, int256 Cost, uint256 SpecialEffect) external {
        address player = msg.sender;
        if ((PlayerCharacters[player] == 0) || (PlayerCharacters_SkillsSet[player] >= 1)) {revert genericError();} // player character must already exist and skills can't be set yet
        if ((Area < 0) || (Area >= 51) || (Range >= 91) || (Range <= 14) || (Cooldown <= 2) || (Cooldown >= 11) || (Cost <= 19) || (Cost >= 81) || (SpecialEffect >= 5)) {revert genericError();}
        if ((SpecialEffect == 3) && (Range >= 16)) {revert genericError();}
        int256 multiplier = 150;
        if (SpecialEffect == 1) {multiplier = 75;} else {if (SpecialEffect == 2) {multiplier = 200;}}
        int256 DamagePercentage;
        unchecked {DamagePercentage = (multiplier * Cooldown * Cost) / (2 * ((Range/10) + 9) * ((Area/10) + 3));}
        Player_Skill_1_Area[player] = Area;
        Player_Skill_1_Range[player] = Range;
        Player_Skill_1_DamagePercentage[player] = DamagePercentage;
        Player_Skill_1_Cooldown[player] = Cooldown;
        Player_Skill_1_Cost[player] = Cost;
        Player_Skill_1_SpecialEffect[player] = SpecialEffect;
        PlayerCharacters_SkillsSet[player] = 1;
    }
    function addPlayerCharacterSkill_2(int256 Area, int256 Range, int256 Cooldown, int256 Cost, uint256 SpecialEffect) external {
        address player = msg.sender;
        if ((PlayerCharacters[player] == 0) || (PlayerCharacters_SkillsSet[player] >= 2)) {revert genericError();} // player character must already exist and skills can't be set yet
        if ((Area < 0) || (Area >= 51) || (Range >= 91) || (Range <= 14) || (Cooldown <= 2) || (Cooldown >= 11) || (Cost <= 19) || (Cost >= 81) || (SpecialEffect >= 5)) {revert genericError();}
        if ((SpecialEffect == 3) && (Range >= 16)) {revert genericError();}
        int256 multiplier = 150;
        if (SpecialEffect == 1) {multiplier = 75;} else {if (SpecialEffect == 2) {multiplier = 200;}}
        int256 DamagePercentage;
        unchecked {DamagePercentage = (multiplier * Cooldown * Cost) / (2 * ((Range/10) + 9) * ((Area/10) + 3));}
        Player_Skill_2_Area[player] = Area;
        Player_Skill_2_Range[player] = Range;
        Player_Skill_2_DamagePercentage[player] = DamagePercentage;
        Player_Skill_2_Cooldown[player] = Cooldown;
        Player_Skill_2_Cost[player] = Cost;
        Player_Skill_2_SpecialEffect[player] = SpecialEffect;
        PlayerCharacters_SkillsSet[player] = 2;
    }
    function addExperience(address player, uint256 tokenID, uint256 amount) external onlyGame { unchecked {
        uint256 current_level;
        if (tokenID >= 200) {
            current_level = nonFungibleLevels[tokenID];
            if (current_level == 0) {revert genericError();}       // NFT is not a character or doesn't exist
            if (current_level <= 99) {
                nonFungibleExp[tokenID] = nonFungibleExp[tokenID] + amount;
                if (nonFungibleExp[tokenID] >= precalculatedExpToLevelUp[current_level]) {nonFungibleLevels[tokenID]++;}
            }
        } else {
            current_level = fungibleLevels[player][tokenID];
            if (current_level == 0) {revert genericError();}       // content is not a character or doesn't exist
            if (current_level <= 99) {
                fungibleExp[player][tokenID] = fungibleExp[player][tokenID] + amount;
                if (fungibleExp[player][tokenID] >= precalculatedExpToLevelUp[current_level]) {fungibleLevels[player][tokenID]++;}
            }
        }
    }}
    function mintContent(address player, uint256 contentGroup) external onlyGame returns (uint256) { unchecked {
        if (((contentGroup % 10) >= 1) || (contentGroup == 100)) {revert genericError();}
        uint256 RandomNum = randomNumber();
        uint256 contentID;
        uint256 rangeMin = content_Ranges[contentGroup];
        contentID = rangeMin + (((RandomNum % 1000) * (content_Ranges[contentGroup+1] - rangeMin + 1)) / 1000);
        if ((contentGroup <= 90)) {
        _mint(player, contentID, 1, "");
        if ((contentGroup >= 10) && (fungibleLevels[player][contentID] == 0)) {fungibleLevels[player][contentID] = 1;}
        return contentID;
        } else {return _mintNFT(player, contentID, int256(RandomNum / 1000));}
    }}
    function mintConcreteNFTcontent(address player, uint256 contentID) external onlyGame returns (uint256) {
        if (contentID <= 499) {revert genericError();}      // can't mint fungible content or custom character
        return _mintNFT(player, contentID, int256(randomNumber() / 1000));
    }
    function _mintNFT(address player, uint256 contentID, int256 RandomInteger) internal returns (uint256) { unchecked {
        if (RandomInteger < 0) {RandomInteger = -RandomInteger;}
        uint256 NFT_ID;
        uint256 burnedLength = burnedIDs[contentID][0].length;
        if (burnedLength >= 1) {NFT_ID = burnedIDs[contentID][0][burnedLength - 1]; burnedIDs[contentID][0].pop();} else {lastMintedNFT++; NFT_ID = lastMintedNFT;}
        _mint(player, NFT_ID, 1, "");
        Content_ID[NFT_ID] = contentID;
        if (Content_Type[contentID] == 7) {nonFungibleLevels[NFT_ID] = 1; nonFungibleExp[NFT_ID] = 0; potential[NFT_ID] = 0;}
        int256 MinDmg = Content_MinDmg[contentID];
        int256 MinAgility = Content_MinAgility[contentID];
        int256 MinHealth = Content_MinHealth[contentID];
        int256 MinArmor = Content_MinArmor[contentID];
        NFT_Damage[NFT_ID] = MinDmg + (((RandomInteger % 1000) * MinDmg) / 4000);
        NFT_Agility[NFT_ID] = MinAgility + ((((RandomInteger / 1000) % 1000) * MinAgility) / 4000);
        NFT_Health[NFT_ID] = MinHealth + ((((RandomInteger / 1000000) % 1000) * MinHealth) / 4000);
        NFT_Armor[NFT_ID] = MinArmor + ((((RandomInteger / 1000000000) % 1000) * MinArmor) / 4000);
        return NFT_ID;
    }}
    function setNFTskin(address player, uint256 skin, uint256 NFT_ID) external onlyGame returns (uint256) {
        uint256 contentID = Content_ID[NFT_ID];
        if (skinAvailable[contentID][skin] == false) {revert genericError();}
        _burn (player, 6, 1);           // setting skin will cost 1 Mystical Rune
        _burn (player, NFT_ID, 1);
        burnedIDs[contentID][selectedSkin[NFT_ID]].push(NFT_ID);
        if (PartyAssignment[player][NFT_ID] != 0) {removeFromParty_auto(player, NFT_ID, 1);}
        uint256 NFT_ID_NEW;
        unchecked{ if (burnedIDs[contentID][skin].length >= 1) {NFT_ID_NEW = burnedIDs[contentID][skin][burnedIDs[contentID][skin].length - 1]; burnedIDs[contentID][skin].pop();} else {lastMintedNFT++; NFT_ID_NEW = lastMintedNFT;}}
        _mint(player, NFT_ID_NEW, 1, "");
        selectedSkin[NFT_ID_NEW] = skin;
        nonFungibleLevels[NFT_ID_NEW] = nonFungibleLevels[NFT_ID];
        nonFungibleExp[NFT_ID_NEW] = nonFungibleExp[NFT_ID];
        Content_ID[NFT_ID_NEW] = contentID;
        NFT_Damage[NFT_ID_NEW] = NFT_Damage[NFT_ID];
        NFT_Agility[NFT_ID_NEW] = NFT_Agility[NFT_ID];
        NFT_Health[NFT_ID_NEW] = NFT_Health[NFT_ID];
        NFT_Armor[NFT_ID_NEW] = NFT_Armor[NFT_ID];
        potential[NFT_ID_NEW] = potential[NFT_ID];
        if (PlayerCharacters[player] == NFT_ID) {PlayerCharacters[player] = NFT_ID_NEW;}
        return NFT_ID_NEW;
    }
    function increasePotential(uint256 NFT_ID) external {
        address player = msg.sender;
        uint256 contentID = Content_ID[NFT_ID];
        uint256 rarity = Content_Rarity[contentID];
        if (Content_Type[contentID] != 7) {revert genericError();}
        if (rarity == 3) {_burn (player, 7, 1);} else {
            if (rarity == 4) {_burn (player, 8, 1);} else {
                if (rarity == 5) {_burn (player, 9, 1);} else {
                    if (rarity == 6) {_burn (player, 10, 1);} else {revert genericError();}
        }}}
        if (potential[NFT_ID] <= 4) {unchecked{potential[NFT_ID]++;}} else {revert genericError();}
    }
    function burnContent(address player, uint256 NFT_ID, uint256 amount) external onlyGame {
        uint256 contentID = Content_ID[NFT_ID];
        if ((contentID >= 200) && (contentID <= 500)) {revert genericError();}    // can't burn player character
        if (PartyAssignment[player][NFT_ID] != 0) {removeFromParty_auto(player, NFT_ID, amount);}
        _burn (player, NFT_ID, amount);
        if (NFT_ID >= 200) {burnedIDs[contentID][selectedSkin[NFT_ID]].push(NFT_ID);}
    }





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// party data
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public PartyContent;      // player => party 1-3 => party slot => NFT ID (0 if not used);    "slots": 1-7 = character, 11-17 = weapon, 21-27 = armor, 31-37 shield
    mapping(address => mapping(uint256 => uint256)) public PartyAssignment;                       // player address => NFT_ID => NFT values: 0 = NFT not in party, 11 = slot 1 party 1, 373 = slot 37 party 3    PartyAssignment / 10 = slot, PartyAssignment % 10 = party, fungible value: count of token usage in the party

    function addToParty(uint256 NFT_ID, uint256 Party, uint256 PartySlot) external { unchecked {
        if (((PartySlot % 10) == 0) || ((PartySlot % 10) >= 8) || (PartySlot >= 38) || (Party == 0) || (Party >= 4)) {revert genericError();}
        address player = msg.sender;
        uint256 ContentID = Content_ID[NFT_ID];
        uint256 AddedContentType = Content_Type[ContentID];
        uint256 _assignment = PartyAssignment[player][NFT_ID];
        if (NFT_ID >= 200) {
            if ((balanceOf(player, NFT_ID) == 0) || (_assignment != 0)) {revert genericError();}  // revert if this exact character is already added in a party
            if ((AddedContentType == 7) && (Content_Rarity[ContentID] >= 4)) { for (uint256 j = 1; j <= 3; j++) { for (uint256 i = 1; i <= 7; i++) {
                if (ContentID == Content_ID[PartyContent[player][j][i]]) {revert genericError();} // for characters with rarity 4 or above - revert if the same character is already in any party
            }}}
        } else {
            if (_assignment >= balanceOf(player, NFT_ID)) {revert genericError();}                // revert if the balance is insufficient to add another instance of the character
        }
        uint256 CurrentNFT_ID = PartyContent[player][Party][PartySlot];
        if (CurrentNFT_ID >= 1) {_removeFromParty(player, CurrentNFT_ID, Party, PartySlot);}      // section checking and emptying the slot in the party where content is added
        if ((PartySlot >= 1) && (PartySlot <= 7) && (AddedContentType == 7)) {} else {            // check of content compatibility
            if ((PartySlot >= 11) && (PartySlot <= 17) && ((AddedContentType == 1) || ((AddedContentType <= 4) && (AddedContentType >= 2) && (PartyContent[player][Party][(PartySlot % 10) + 30] == 0)))) {} else {
                if ((PartySlot >= 21) && (PartySlot <= 27) && (AddedContentType == 6)) {} else {
                    if ((PartySlot >= 31) && (PartySlot <= 37) && (AddedContentType == 5) && (Content_Type[Content_ID[PartyContent[player][Party][(PartySlot % 10) + 10]]] <= 1)) {} else {revert genericError();}
        }}}
        uint256 party1_Points; uint256 party2_Points; uint256 party3_Points; uint256 temp_contentID;
        if (Party == 1) {party1_Points = Content_PartyPoints[ContentID];} else {if (Party == 2) {party2_Points = Content_PartyPoints[ContentID];} else {party3_Points = Content_PartyPoints[ContentID];}}
        for (uint256 i = 1; i <= 7; i++) {
            party1_Points = party1_Points + Content_PartyPoints[Content_ID[PartyContent[player][1][i]]];
            party2_Points = party2_Points + Content_PartyPoints[Content_ID[PartyContent[player][2][i]]];
            party3_Points = party3_Points + Content_PartyPoints[Content_ID[PartyContent[player][3][i]]];
            temp_contentID = Content_ID[PartyContent[player][Party][i]];
            if (temp_contentID != 0) {    // excludes empty slots
            if (Content_GoodOrEvil[temp_contentID] >= Content_GoodOrEvil[ContentID]) {  // characters with too big difference in the "GoodOrEvil" (like angel and demon) can't be together in the same party
                if ((Content_GoodOrEvil[temp_contentID] - Content_GoodOrEvil[ContentID]) >= 50) {revert genericError();}
            } else {
                if ((Content_GoodOrEvil[ContentID] - Content_GoodOrEvil[temp_contentID]) >= 50) {revert genericError();}
            }}
        }
        if ((party1_Points >= 101) || (party2_Points >= 101) || (party3_Points >= 101) || ((party1_Points + party2_Points + party3_Points) >= 201)) {revert genericError();}
        PartyContent[player][Party][PartySlot] = NFT_ID;
        if (NFT_ID >= 200) {PartyAssignment[player][NFT_ID] = (10 * PartySlot) + Party;} else {PartyAssignment[player][NFT_ID]++;}
    }}
    function _removeFromParty(address player, uint256 NFT_ID, uint256 Party, uint256 PartySlot) internal {
        PartyContent[player][Party][PartySlot] = 0;
        if (PartyAssignment[player][NFT_ID] >= 1){
        if (NFT_ID >= 200) {PartyAssignment[player][NFT_ID] = 0;} else {unchecked {PartyAssignment[player][NFT_ID]--;}}
        }
    }
    function removeFromParty (uint256 Party, uint256 PartySlot) external {
        address player = msg.sender;
        uint256 NFT_ID = PartyContent[player][Party][PartySlot];
        _removeFromParty(player, NFT_ID, Party, PartySlot);
    }
    function removeFromParty_auto(address player, uint256 NFT_ID, uint256 amount) internal { unchecked {
        if (amount == 0) {revert genericError();}
        if (NFT_ID >= 200) {    // NFT part
            uint256 assignment = PartyAssignment[player][NFT_ID];
            _removeFromParty(player, NFT_ID, assignment % 10, assignment / 10);
        } else {                // fungible part
            uint256 count;
            uint256 Party;
            uint256 PartySlot;
            for (uint256 l = 1; l <= amount; l++) {
            count = 0;
            for (uint256 k = 1; k <= 3; k++) { for (uint256 j = 0; j <= 3; j++) { for (uint256 i = 1; i <= 7; i++) {
                if (PartyContent[player][k][(10*j)+i] == NFT_ID) {count++; Party = k; PartySlot = (10*j)+i;}
            }}}
            if ((count + amount) > balanceOf(player, NFT_ID)) {
                PartyContent[player][Party][PartySlot] = 0;
                if (count >= 1)  {count--;}
            }}
            PartyAssignment[player][NFT_ID] = count;
    }}}





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// view functions - retrieving of the data about content / NFT
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function getContentRange(uint256 contentGroup) external view returns (uint256 Min, uint256 Max) { unchecked {
        if ((contentGroup % 10) != 0) {revert genericError();}
        return (content_Ranges[contentGroup], content_Ranges[contentGroup + 1]);
    }}
    function getLevel(address player, uint256 NFT_ID) external view returns (uint256 Level) {
        if (NFT_ID >= 200) {return nonFungibleLevels[NFT_ID];} else {return fungibleLevels[player][NFT_ID];}
    }
    function getAdditionalData(uint256 NFT_ID) external view returns (string memory Name, uint256 Type, uint256 Rarity, uint256 PartyPoints, bool UseEquipment, uint256 GoodOrEvil, int256 Potential, uint256 PotentialEffect, uint256 ContentID) {
        uint256 _NFT_ID = NFT_ID;
        uint256 contentID = Content_ID[NFT_ID];
        return (Content_Name[contentID], Content_Type[contentID], Content_Rarity[contentID], Content_PartyPoints[contentID], Content_UseEquipment[contentID], Content_GoodOrEvil[contentID], potential[_NFT_ID], Content_PotentialEffect[contentID], contentID);
    }
    function getBasicAttributes(uint256 NFT_ID) external view returns (int256 Damage, int256 DamageBlock, int256 Health, int256 Agility, int256 Armor, int256 Range) {
        uint256 _NFT_ID = NFT_ID; uint256 contentID = Content_ID[_NFT_ID];
        if (_NFT_ID >= 200) {
            return (NFT_Damage[_NFT_ID], Content_Block[contentID], NFT_Health[_NFT_ID], NFT_Agility[_NFT_ID], NFT_Armor[_NFT_ID], Content_Range[contentID]);
        } else {
            return (Content_MinDmg[contentID], Content_Block[contentID], Content_MinHealth[contentID], Content_MinAgility[contentID], Content_MinArmor[contentID], Content_Range[contentID]);
    }}
    function getPartyAttributes1(address Player, uint256 Party, uint256 PartySlot) external view returns (int256 Damage, int256 DamageBlock, int256 Health) { unchecked {
        if ((Party == 0) || (Party >= 4) || (PartySlot == 0) || (PartySlot >= 8)) {revert genericError();}
        uint256 NFT_ID = PartyContent[Player][Party][PartySlot];
        int256 FinalDamage; int256 FinalBlock; int256 FinalHealth;
        if (NFT_ID == 0) return (FinalDamage, FinalBlock, FinalHealth);
        uint256 contentID = Content_ID[NFT_ID];
        uint256 PotentialEffect = Content_PotentialEffect[contentID];
        FinalBlock = Content_Block[contentID];                                                          // basic attributes
        if (NFT_ID >= 200) {
            FinalDamage = NFT_Damage[NFT_ID]; FinalHealth = NFT_Health[NFT_ID];                         // basic attributes for NFT
            if (PotentialEffect >= 1) {                                                                 // added effect of potential (only non-fungible)
                if (PotentialEffect == 1) {FinalDamage = FinalDamage + (potential[NFT_ID] * 2);} else {
                    if (PotentialEffect == 5) {FinalBlock = FinalBlock + potential[NFT_ID];} else {
                        if (PotentialEffect == 3) {FinalHealth = FinalHealth + (potential[NFT_ID] * 20);}
            }}}
        } else {FinalDamage = Content_MinDmg[contentID]; FinalHealth = Content_MinHealth[contentID];}   // basic attributes for fungible content
        address _player = Player; uint256 _party = Party; uint256 _partySlot = PartySlot;
        if (Content_UseEquipment[contentID]) {                                                          // applies only if the character can use equipment
            uint256 WeaponID = PartyContent[_player][_party][_partySlot + 10];
            uint256 ArmorID = PartyContent[_player][_party][_partySlot + 20];
            uint256 ShieldID = PartyContent[_player][_party][_partySlot + 30];
            if (WeaponID >= 200) {
                FinalDamage = FinalDamage + NFT_Damage[WeaponID];
                FinalHealth = FinalHealth + NFT_Health[WeaponID];
            } else {
                FinalDamage = FinalDamage + Content_MinDmg[WeaponID];
                FinalHealth = FinalHealth + Content_MinHealth[WeaponID];
            }
            if (ArmorID >= 200) {FinalHealth = FinalHealth + NFT_Health[ArmorID];} else {FinalHealth = FinalHealth + Content_MinHealth[ArmorID];}
            if (ShieldID >= 200) {FinalHealth = FinalHealth + NFT_Health[ShieldID];} else {FinalHealth = FinalHealth + Content_MinHealth[ShieldID];}
            FinalBlock = FinalBlock + Content_Block[Content_ID[ArmorID]] + Content_Block[Content_ID[ShieldID]];
        }
        int256 LvlMultiplier;
        if (NFT_ID >= 200) {LvlMultiplier = levelMultiplier[nonFungibleLevels[NFT_ID]];} else {LvlMultiplier = levelMultiplier[fungibleLevels[_player][NFT_ID]];}
        FinalDamage = (FinalDamage * LvlMultiplier) / 100000;
        FinalHealth = (FinalHealth * LvlMultiplier) / 100000;
        FinalBlock = (FinalBlock * LvlMultiplier) / 100000;
        return (FinalDamage, FinalBlock, FinalHealth);
    }}
    function getPartyAttributes2(address Player, uint256 Party, uint256 PartySlot) external view returns (int256 Agility, int256 Armor, int256 Range) { unchecked {
        if ((Party == 0) || (Party >= 4) || (PartySlot == 0) || (PartySlot >= 8)) {revert genericError();}
        uint256 NFT_ID = PartyContent[Player][Party][PartySlot];
        int256 FinalAgility; int256 FinalArmor; int256 FinalRange;
        if (NFT_ID == 0) return (FinalAgility, FinalArmor, FinalRange);
        uint256 contentID = Content_ID[NFT_ID];
        uint256 PotentialEffect = Content_PotentialEffect[contentID];
        FinalRange = Content_Range[contentID];                                                              // basic attributes
        if (NFT_ID >= 200) {
            FinalAgility = NFT_Agility[NFT_ID]; FinalArmor = NFT_Armor[NFT_ID];                             // basic attributes for NFT
            if (PotentialEffect >= 2) {                                                                     // added effect of potential (only non-fungible)
                if (PotentialEffect == 2) {FinalAgility = FinalAgility + (potential[NFT_ID] * 2);} else {
                    if (PotentialEffect == 4) {FinalArmor = FinalArmor + (potential[NFT_ID] * 2);}
            }}
        } else {FinalAgility = Content_MinAgility[contentID]; FinalArmor = Content_MinArmor[contentID];}    // basic attributes for fungible content
        address _player = Player; uint256 _party = Party; uint256 _partySlot = PartySlot;
        if (Content_UseEquipment[contentID]) {                                                              // applies only if the character can use equipment
            uint256 WeaponID = PartyContent[_player][_party][_partySlot + 10];
            uint256 ArmorID = PartyContent[_player][_party][_partySlot + 20];
            uint256 ShieldID = PartyContent[_player][_party][_partySlot + 30];
            if (WeaponID >= 200) {
                FinalAgility = FinalAgility + NFT_Agility[WeaponID];
                FinalArmor = FinalArmor + NFT_Armor[WeaponID];
            } else {
                FinalAgility = FinalAgility + Content_MinAgility[WeaponID];
                FinalArmor = FinalArmor + Content_MinArmor[WeaponID];
            }
            if (ArmorID >= 200) {
                FinalAgility = FinalAgility + NFT_Agility[ArmorID];
                FinalArmor = FinalArmor + NFT_Armor[ArmorID];
            } else {
                FinalAgility = FinalAgility + Content_MinAgility[ArmorID];
                FinalArmor = FinalArmor + Content_MinArmor[ArmorID];
            }
            if (ShieldID >= 200) {
                FinalAgility = FinalAgility + NFT_Agility[ShieldID];
                FinalArmor = FinalArmor + NFT_Armor[ShieldID];
            } else {
                FinalAgility = FinalAgility + Content_MinAgility[ShieldID];
                FinalArmor = FinalArmor + Content_MinArmor[ShieldID];
            }
            FinalRange = FinalRange + Content_Range[Content_ID[WeaponID]];
        }
        return (FinalAgility, FinalArmor, FinalRange);
    }}
    function getSkillData_1(address player, uint256 NFT_ID) external view returns (int256 Area, int256 SkillRange, int256 DamagePercentage, int256 Cooldown, int256 Cost, uint256 SpecialEffect, uint256 WeaponType) { unchecked {
        address _player = player;
        if (PlayerCharacters[_player] != NFT_ID) {
            uint256 contentID = Content_ID[NFT_ID];
            return (Content_Skill_1_Area[contentID], Content_Skill_1_Range[contentID], Content_Skill_1_DamagePercentage[contentID], Content_Skill_1_Cooldown[contentID], Content_Skill_1_Cost[contentID], Content_Skill_1_SpecialEffect[contentID], Content_Skill_WeaponType[contentID]);
        } else {
            return (Player_Skill_1_Area[_player], Player_Skill_1_Range[_player], Player_Skill_1_DamagePercentage[_player], Player_Skill_1_Cooldown[_player], Player_Skill_1_Cost[_player], Player_Skill_1_SpecialEffect[_player], Player_Skill_WeaponType[_player]);
        }
    }}
    function getSkillData_2(address player, uint256 NFT_ID) external view returns (int256 Area, int256 SkillRange, int256 DamagePercentage, int256 Cooldown, int256 Cost, uint256 SpecialEffect) { unchecked {
        address _player = player;
        if (PlayerCharacters[_player] != NFT_ID) {
            uint256 contentID = Content_ID[NFT_ID];
            return (Content_Skill_2_Area[contentID], Content_Skill_2_Range[contentID], Content_Skill_2_DamagePercentage[contentID], Content_Skill_2_Cooldown[contentID], Content_Skill_2_Cost[contentID], Content_Skill_2_SpecialEffect[contentID]);
        } else {
            return (Player_Skill_2_Area[_player], Player_Skill_2_Range[_player], Player_Skill_2_DamagePercentage[_player], Player_Skill_2_Cooldown[_player], Player_Skill_2_Cost[_player], Player_Skill_2_SpecialEffect[_player]);
        }
    }}
    function getSkillEquipmentBonus(address player, uint256 contentID, uint256 Party, uint256 PartySlot) internal view returns (int256, int256, int256){
        int256 damage; int256 cooldown; int256 cost;
        if ((Content_Rarity[contentID] >= 3) && (Content_UseEquipment[contentID])) { unchecked {
            uint256 WeaponID = Content_ID[PartyContent[player][Party][PartySlot + 10]];
            uint256 ArmorID = Content_ID[PartyContent[player][Party][PartySlot + 20]];
            damage = Content_Skill_1_DamagePercentage[WeaponID] + Content_Skill_1_DamagePercentage[ArmorID];
            cooldown = Content_Skill_1_Cooldown[WeaponID] + Content_Skill_1_Cooldown[ArmorID];
            cost = Content_Skill_1_Cost[WeaponID] + Content_Skill_1_Cost[ArmorID];
        }}
        return (damage, cooldown, cost);
    }
    function getPartySkillData_1(address Player, uint256 Party, uint256 PartySlot) external view returns (int256 Area, int256 SkillRange, int256 DamagePercentage, int256 Cooldown, int256 Cost, uint256 SpecialEffect, uint256 WeaponType) { unchecked {
        if ((Party == 0) || (Party >= 4) || (PartySlot == 0) || (PartySlot >= 8)) {revert genericError();}
        address _player = Player; uint256 _party = Party; uint256 _partySlot = PartySlot;
        uint256 NFT_ID = PartyContent[_player][_party][_partySlot];
        uint256 contentID = Content_ID[NFT_ID];
        (int256 SkillDamage, int256 SkillCooldown, int256 SkillCost) = getSkillEquipmentBonus(_player, contentID, _party, _partySlot);
        if (PlayerCharacters[_player] != NFT_ID) {
            return (Content_Skill_1_Area[contentID], Content_Skill_1_Range[contentID], SkillDamage + Content_Skill_1_DamagePercentage[contentID], SkillCooldown + Content_Skill_1_Cooldown[contentID], SkillCost + Content_Skill_1_Cost[contentID], Content_Skill_1_SpecialEffect[contentID], Content_Skill_WeaponType[contentID]);
        } else {
            return (Player_Skill_1_Area[_player], Player_Skill_1_Range[_player], SkillDamage + Player_Skill_1_DamagePercentage[_player], SkillCooldown + Player_Skill_1_Cooldown[_player], SkillCost + Player_Skill_1_Cost[_player], Player_Skill_1_SpecialEffect[_player], Player_Skill_WeaponType[_player]);
        }
    }}
    function getPartySkillData_2(address Player, uint256 Party, uint256 PartySlot) external view returns (int256 Area, int256 SkillRange, int256 DamagePercentage, int256 Cooldown, int256 Cost, uint256 SpecialEffect) { unchecked {
        if ((Party == 0) || (Party >= 4) || (PartySlot == 0) || (PartySlot >= 8)) {revert genericError();}
        address _player = Player; uint256 _party = Party; uint256 _partySlot = PartySlot;
        uint256 NFT_ID = PartyContent[_player][_party][_partySlot];
        uint256 contentID = Content_ID[NFT_ID];
        (int256 SkillDamage, int256 SkillCooldown, int256 SkillCost) = getSkillEquipmentBonus(_player, contentID, _party, _partySlot);
        if (PlayerCharacters[_player] != NFT_ID) {
            return (Content_Skill_2_Area[contentID], Content_Skill_2_Range[contentID], SkillDamage + Content_Skill_2_DamagePercentage[contentID], SkillCooldown + Content_Skill_2_Cooldown[contentID], SkillCost + Content_Skill_2_Cost[contentID], Content_Skill_2_SpecialEffect[contentID]);
        } else {
            return (Player_Skill_2_Area[_player], Player_Skill_2_Range[_player], SkillDamage + Player_Skill_2_DamagePercentage[_player], SkillCooldown + Player_Skill_2_Cooldown[_player], SkillCost + Player_Skill_2_Cost[_player], Player_Skill_2_SpecialEffect[_player]);
        }
    }}





///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// overrides
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function uri(uint256 _tokenid) override public view returns (string memory) {
        uint256 skin = selectedSkin[_tokenid];
        return string(abi.encodePacked(baseURIs[skin], Content_uriID[Content_ID[_tokenid]][skin]));
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return ERC1155.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) public override {
        if ((PlayerCharacters[from] == tokenId) || (tokenId == 6)) {revert genericError();}     // custom player character or mystical rune can't be transfered
        if (PartyAssignment[from][tokenId] != 0) {removeFromParty_auto(from, tokenId, amount);}
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }
    function safeBatchTransferFrom(address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public virtual override {
        uint256 currentID;
        unchecked { for (uint256 i = 0; i < ids.length; i++) {
            currentID = ids[i];
            if ((PlayerCharacters[from] == currentID) || (currentID == 6)) {revert genericError();}   // custom player character or mystical rune can't be transfered
            if (PartyAssignment[from][currentID] != 0) {removeFromParty_auto(from, currentID, amounts[i]);}
        }}
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}