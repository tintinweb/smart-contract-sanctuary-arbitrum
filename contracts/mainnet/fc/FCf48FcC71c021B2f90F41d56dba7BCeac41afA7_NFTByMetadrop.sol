// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

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
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

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
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

pragma solidity 0.8.19;

import "../Global/IConfigStructures.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDropFactory is IConfigStructures {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event DefaultMetadropPrimaryShareBasisPointsSet(
    uint256 defaultPrimaryFeeBasisPoints
  );
  event DefaultMetadropRoyaltyBasisPointsSet(
    uint256 defaultMetadropRoyaltyBasisPoints
  );
  event PrimaryFeeOverrideByDropSet(string dropId, uint256 percentage);
  event RoyaltyBasisPointsOverrideByDropSet(
    string dropId,
    uint256 royaltyBasisPoints
  );
  event PlatformTreasurySet(address platformTreasury);
  event TemplateAdded(
    TemplateStatus status,
    uint256 templateNumber,
    uint256 loadedDate,
    address templateAddress,
    string templateDescription
  );
  event TemplateTerminated(uint16 templateNumber);
  event DropApproved(
    string indexed dropId,
    address indexed dropOwner,
    bytes32 dropHash
  );
  event DropDetailsDeleted(string indexed dropId);
  event DropExpiryInDaysSet(uint32 expiryInDays);
  event pauseCutOffInDaysSet(uint8 cutOffInDays);
  event SubmissionFeeETHUpdated(uint256 oldFee, uint256 newFee);
  event DropDeployed(
    string dropId,
    address nftInstance,
    address vestingInstance,
    PrimarySaleModuleInstance[],
    address royaltySplitterInstance
  );
  event vrfSubscriptionIdSet(uint64 vrfSubscriptionId_);
  event vrfKeyHashSet(bytes32 vrfKeyHash);
  event vrfCallbackGasLimitSet(uint32 vrfCallbackGasLimit);
  event vrfRequestConfirmationsSet(uint16 vrfRequestConfirmations);
  event vrfNumWordsSet(uint32 vrfNumWords);
  event metadropOracleAddressSet(address metadropOracleAddress);
  event messageValidityInSecondsSet(uint80 messageValidityInSeconds);

  /** ====================================================================================================================
   *                                                     ERRORS
   * =====================================================================================================================
   */
  error MetadropOnly();
  error ValueExceedsMaximum();
  error TemplateCannotBeAddressZero();
  error ProjectOwnerCannotBeAddressZero();
  error PlatformTreasuryCannotBeAddressZero();
  error SuperAdminCannotBeAddressZero();
  error MetadropOracleCannotBeAddressZero();
  error VRFCoordinatorCannotBeAddressZero();

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformTreasury  return the treasury address (provided as explicit method rather than public var)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformTreasury_  Treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformTreasury()
    external
    view
    returns (address platformTreasury_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getDropDetails   Getter for the drop details held on chain
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_  The drop ID being queries
   * ---------------------------------------------------------------------------------------------------------------------
   * @return dropDetails_  The drop details struct for the provided drop Id.
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDropDetails(
    string memory dropId_
  ) external view returns (DropApproval memory dropDetails_);

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFSubscriptionId    Set the chainlink subscription id..
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfSubscriptionId_    The VRF subscription that this contract will consume chainlink from.

   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFSubscriptionId(uint64 vrfSubscriptionId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFKeyHash   Set the chainlink keyhash (gas lane).
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfKeyHash_  The desired VRF keyhash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFKeyHash(bytes32 vrfKeyHash_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFCallbackGasLimit  Set the chainlink callback gas limit
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfCallbackGasLimit_  Callback gas limit
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFCallbackGasLimit(uint32 vrfCallbackGasLimit_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFRequestConfirmations  Set the chainlink number of confirmations required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfRequestConfirmations_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFRequestConfirmations(uint16 vrfRequestConfirmations_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) setVRFNumWords  Set the chainlink number of words required
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vrfNumWords_  Required number of confirmations
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setVRFNumWords(uint32 vrfNumWords_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMetadropOracleAddress  Set the metadrop trusted oracle address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param metadropOracleAddress_   Trusted metadrop oracle address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropOracleAddress(address metadropOracleAddress_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->ORACLE
   * @dev (function) setMessageValidityInSeconds  Set the validity period of signed messages
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param messageValidityInSeconds_   Validity period in seconds for messages signed by the trusted oracle
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMessageValidityInSeconds(
    uint80 messageValidityInSeconds_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawETH   A withdraw function to allow ETH to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawETH(uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) withdrawERC20   A withdraw function to allow ERC20s to be withdrawn to the treasury
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param token_   The contract address of the token being withdrawn
   * ---------------------------------------------------------------------------------------------------------------------
   * @param amount_  The amount to withdraw
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getDefaultMetadropPrimaryShareBasisPoints   Getter for the default platform primary fee basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return defaultMetadropPrimaryShareBasisPoints_   The metadrop primary share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getDefaultMetadropPrimaryShareBasisPoints()
    external
    view
    returns (uint256 defaultMetadropPrimaryShareBasisPoints_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyBasisPoints   Getter for the metadrop royalty share in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyBasisPoints_   The metadrop royalty share in basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyBasisPoints()
    external
    view
    returns (uint256 metadropRoyaltyBasisPoints_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getPrimaryFeeOverrideByDrop    Getter for any drop specific primary fee override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                      The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                      If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return primaryFeeOverrideByDrop_   The primary fee override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPrimaryFeeOverrideByDrop(
    string memory dropId_
  ) external view returns (bool isSet_, uint256 primaryFeeOverrideByDrop_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) getMetadropRoyaltyOverrideByDrop    Getter for any drop specific royalty basis points override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                               The drop Id being queried
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isSet_                               If this override is set
   * ---------------------------------------------------------------------------------------------------------------------
   * @return metadropRoyaltyOverrideByDrop_       Royalty basis points override for the drop (if any)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getMetadropRoyaltyOverrideByDrop(
    string memory dropId_
  ) external view returns (bool isSet_, uint256 metadropRoyaltyOverrideByDrop_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) getPauseCutOffInDays    Getter for the default pause cutoff period
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPauseCutOffInDays()
    external
    view
    returns (uint8 pauseCutOffInDays_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->PAUSABLE
   * @dev (function) setpauseCutOffInDays    Set the number of days from the start date that a contract can be paused for
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_    Default pause cutoff in days
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setpauseCutOffInDays(uint8 pauseCutOffInDays_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDropFeeETH    Set drop fee (if any)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fee_    New drop fee
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropFeeETH(uint256 fee_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPlatformTreasury    Set the platform treasury address
   *
   * Set the address that platform fees will be paid to / can be withdrawn to.
   * Note that this is restricted to the highest authority level, the default
   * admin. Platform admins can trigger a withdrawal to the treasury, but only
   * the default admin can set or alter the treasury address. It is recommended
   * that the default admin is highly secured and restrited e.g. a multi-sig.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformTreasury_    New treasury address
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPlatformTreasury(address platformTreasury_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setDefaultMetadropPrimaryShareBasisPoints    Setter for the metadrop primary basis points fee
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropPrimaryShareBasisPoints_    New default meradrop primary share
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultMetadropPrimaryShareBasisPoints(
    uint32 defaultMetadropPrimaryShareBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyBasisPoints   Setter for the metadrop royalty percentate in
   *                                                basis points i.e. 100 = 1%
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param defaultMetadropRoyaltyBasisPoints_      New default royalty basis points
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyBasisPoints(
    uint32 defaultMetadropRoyaltyBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setPrimaryFeeOverrideByDrop   Setter for the metadrop primary percentage fee, in basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_           The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param basisPoints_      The basis points override
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPrimaryFeeOverrideByDrop(
    string memory dropId_,
    uint256 basisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) setMetadropRoyaltyOverrideByDrop   Setter to override royalty basis points
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                  The drop for the override
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyBasisPoints_      Royalty basis points verride
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMetadropRoyaltyOverrideByDrop(
    string memory dropId_,
    uint256 royaltyBasisPoints_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) setDropExpiryInDays   Setter for the number of days that must pass since a drop was last changed
   *                                       before it can be removed from storage
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropExpiryInDays_              The number of days that must pass for a submitted drop to be considered expired
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDropExpiryInDays(uint32 dropExpiryInDays_) external;

  /** ====================================================================================================================
   *                                                    VRF SERVER
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                                -->VRF
   * @dev (function) requestVRFRandomness  Get the metadata start position for use on reveal of the calling collection
   * _____________________________________________________________________________________________________________________
   */
  function requestVRFRandomness() external;

  /** ====================================================================================================================
   *                                                    TEMPLATES
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) addTemplate  Add a contract to the template library
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param contractAddress_              The address of the deployed contract that will be a template
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateDescription_          The description of the template
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function addTemplate(
    address payable contractAddress_,
    string memory templateDescription_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->TEMPLATES
   * @dev (function) terminateTemplate  Mark a template as terminated
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param templateNumber_              The number of the template to be marked as terminated
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function terminateTemplate(uint16 templateNumber_) external;

  /** ====================================================================================================================
   *                                                    DROP CREATION
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) removeExpiredDropDetails  A review admin user can remove details for a drop that has expired.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id for which details are to be removed
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function removeExpiredDropDetails(string memory dropId_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) approveDrop  A review admin user can approve the drop.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_              The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_        Address of the project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropConfigHash_      The config hash for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approveDrop(
    string memory dropId_,
    address projectOwner_,
    bytes32 dropConfigHash_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createDrop     Create a drop using the stored and approved configuration if called by the address
   *                                that the user has designated as project admin
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_                An array of collection URIs (pre-reveal, ipfs and arweave)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createDrop(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_,
    string[3] memory collectionURIs_
  ) external payable;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) configHashMatches  Check the passed config against the stored config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return matches_                      Whether the hash matches (true) or not (false)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function configHashMatches(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external view returns (bool matches_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->DROPS
   * @dev (function) createConfigHash  Create the config hash
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param dropId_                        The drop Id being approved
   * ---------------------------------------------------------------------------------------------------------------------
   * @param vestingModule_                 Struct containing the relevant config for the vesting module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_                     Struct containing the relevant config for the NFT module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModulesConfig_      Array of structs containing the config details for all primary sale modules
   *                                       associated with this drop (can be 1 to n)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitterModule_  Struct containing the relevant config for the royalty splitter module
   * ---------------------------------------------------------------------------------------------------------------------
   * @param salesPageHash_                 A hash of sale page data
   * ---------------------------------------------------------------------------------------------------------------------
   * @param customNftAddress_              If this drop uses a custom NFT this will hold that contract's address
   * ---------------------------------------------------------------------------------------------------------------------
   * @return configHash_                   The bytes32 config hash
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function createConfigHash(
    string memory dropId_,
    VestingModuleConfig memory vestingModule_,
    NFTModuleConfig memory nftModule_,
    PrimarySaleModuleConfig[] memory primarySaleModulesConfig_,
    RoyaltySplitterModuleConfig memory royaltyPaymentSplitterModule_,
    bytes32 salesPageHash_,
    address customNftAddress_
  ) external pure returns (bytes32 configHash_);
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * =======================================================================
 * Metadrop Access control, OpenZeppelin AccessControl with string usage
 * replaced with custom errors
 * =======================================================================
 *
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  error AccountDoesNotHaveRole(address account, bytes32 role);
  error CanOnlyRenounceForSelf();

  /**
   * @dev Modifier that checks that an account has a specific role. Reverts
   * with a standardized message including the required role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 role) {
    _checkRole(role);
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override returns (bool) {
    return
      interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(
    bytes32 role,
    address account
  ) public view virtual override returns (bool) {
    return _roles[role].members[account];
  }

  /**
   * @dev Revert with a standard message if `_msgSender()` is missing `role`.
   * Overriding this function changes the behavior of the {onlyRole} modifier.
   *
   * Format of the revert message is described in {_checkRole}.
   *
   * _Available since v4.6._
   */
  function _checkRole(bytes32 role) internal view virtual {
    _checkRole(role, _msgSender());
  }

  /**
   * @dev Revert with a standard message if `account` is missing `role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   */
  function _checkRole(bytes32 role, address account) internal view virtual {
    if (!hasRole(role, account)) {
      // revert(
      //     string(
      //         abi.encodePacked(
      //             "AccessControl: account ",
      //             Strings.toHexString(account),
      //             " is missing role ",
      //             Strings.toHexString(uint256(role), 32)
      //         )
      //     )
      // );
      revert AccountDoesNotHaveRole(account, role);
    }
  }

  /**
   * @dev Returns the admin role that controls `role`. See {grantRole} and
   * {revokeRole}.
   *
   * To change a role's admin, use {_setRoleAdmin}.
   */
  function getRoleAdmin(
    bytes32 role
  ) public view virtual override returns (bytes32) {
    return _roles[role].adminRole;
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleGranted} event.
   */
  function grantRole(
    bytes32 role,
    address account
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _grantRole(role, account);
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * If `account` had been granted `role`, emits a {RoleRevoked} event.
   *
   * Requirements:
   *
   * - the caller must have ``role``'s admin role.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeRole(
    bytes32 role,
    address account
  ) public virtual override onlyRole(getRoleAdmin(role)) {
    _revokeRole(role, account);
  }

  /**
   * @dev Revokes `role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   *
   * May emit a {RoleRevoked} event.
   */
  function renounceRole(bytes32 role, address account) public virtual override {
    if (account != _msgSender()) {
      revert CanOnlyRenounceForSelf();
    }

    _revokeRole(role, account);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * If `account` had not been already granted `role`, emits a {RoleGranted}
   * event. Note that unlike {grantRole}, this function doesn't perform any
   * checks on the calling account.
   *
   * May emit a {RoleGranted} event.
   *
   * [WARNING]
   * ====
   * This function should only be called from the constructor when setting
   * up the initial roles for the system.
   *
   * Using this function in any other way is effectively circumventing the admin
   * system imposed by {AccessControl}.
   * ====
   *
   * NOTE: This function is deprecated in favor of {_grantRole}.
   */
  function _setupRole(bytes32 role, address account) internal virtual {
    _grantRole(role, account);
  }

  /**
   * @dev Sets `adminRole` as ``role``'s admin role.
   *
   * Emits a {RoleAdminChanged} event.
   */
  function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
    bytes32 previousAdminRole = getRoleAdmin(role);
    _roles[role].adminRole = adminRole;
    emit RoleAdminChanged(role, previousAdminRole, adminRole);
  }

  /**
   * @dev Grants `role` to `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleGranted} event.
   */
  function _grantRole(bytes32 role, address account) internal virtual {
    if (!hasRole(role, account)) {
      _roles[role].members[account] = true;
      emit RoleGranted(role, account, _msgSender());
    }
  }

  /**
   * @dev Revokes `role` from `account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleRevoked} event.
   */
  function _revokeRole(bytes32 role, address account) internal virtual {
    if (hasRole(role, account)) {
      _roles[role].members[account] = false;
      emit RoleRevoked(role, account, _msgSender());
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title AuthorityModel.sol. Library for global authority components
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

/**
 *
 * @dev Inheritance details:
 *      AccessControl           OZ access control implementation - used for authority control
 *
 */

import "./AccessControlM.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract AuthorityModel is AccessControl {
  using EnumerableSet for EnumerableSet.AddressSet;
  // Platform admin: The role for platform admins. Platform admins can be added. These addresses have privileged
  // access to maintain configuration like the platform fee.
  bytes32 internal constant PLATFORM_ADMIN = keccak256("PLATFORM_ADMIN");

  // Review admin: access to perform reviews of drops, in this case the authority to maintain the drop status parameter, and
  // set it from review to editable (when sending back to the project owner), or from review to approved (when)
  // the drop is ready to go).
  bytes32 internal constant REVIEW_ADMIN = keccak256("REVIEW_ADMIN");

  // Project owner: This is the role for the project itself, i.e. the team that own this drop.
  bytes32 internal constant PROJECT_OWNER = keccak256("PROJECT_OWNER");

  // Address for the factory:
  address internal factory;

  // The super admin can grant and revoke roles
  address public superAdmin;

  // The project owner. Only applicable if inheritor is a Drop or a project.
  address public projectOwner;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _platformAdmins;

  // Enumerable set to store platform admins:
  EnumerableSet.AddressSet private _reviewAdmins;

  /** ====================================================================================================================
   *                                                        ERRORS
   * =====================================================================================================================
   */
  error CallerIsNotDefaultAdmin(address caller);
  error CallerIsNotPlatformAdmin(address caller);
  error CallerIsNotReviewAdmin(address caller);
  error CallerIsNotPlatformAdminOrProjectOwner(address caller);
  error CallerIsNotPlatformAdminOrFactory(address caller);
  error CallerIsNotProjectOwner(address caller);
  error MustHaveAPlatformAdmin();
  error PlatformAdminCannotBeAddressZero();
  error ReviewAdminCannotBeAddressZero();
  error CannotGrantOrRevokeDirectly();

  /** ====================================================================================================================
   *                                                       MODIFIERS
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlySuperAdmin. The associated action can only be taken by the super admin (an address with the
   * default admin role).
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlySuperAdmin() {
    if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
      revert CallerIsNotDefaultAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyPlatformAdmin. The associated action can only be taken by an address with the
   * platform admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyPlatformAdmin() {
    if (!hasRole(PLATFORM_ADMIN, msg.sender))
      revert CallerIsNotPlatformAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyReviewAdmin. The associated action can only be taken by an address with the
   * review admin role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyReviewAdmin() {
    if (!hasRole(REVIEW_ADMIN, msg.sender))
      revert CallerIsNotReviewAdmin(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyPlatformAdminOrProjectOwner. The associated action can only be taken by an address with the
   * platform admin role or project owner role
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyPlatformAdminOrProjectOwner() {
    if (
      !hasRole(PLATFORM_ADMIN, msg.sender) &&
      !hasRole(PROJECT_OWNER, msg.sender)
    ) revert CallerIsNotPlatformAdminOrProjectOwner(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyProjectOwner. The associated action can only be taken by an address with the
   * project owner role.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyProjectOwner() {
    if (!hasRole(PROJECT_OWNER, msg.sender))
      revert CallerIsNotProjectOwner(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (modifier) onlyFactoryOrPlatformAdmin. The associated action can only be taken by an address with the
   * platform admin role or the factory.
   *
   * _____________________________________________________________________________________________________________________
   */
  modifier onlyFactoryOrPlatformAdmin() {
    if (msg.sender != factory && !hasRole(PLATFORM_ADMIN, msg.sender))
      revert CallerIsNotPlatformAdminOrFactory(msg.sender);
    _;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getPlatformAdmins   Getter for the enumerable list of platform admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return platformAdmins_  A list of platform admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getPlatformAdmins()
    public
    view
    returns (address[] memory platformAdmins_)
  {
    return (_platformAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) getReviewAdmins   Getter for the enumerable list of review admins
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return reviewAdmins_  A list of review admins
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function getReviewAdmins()
    public
    view
    returns (address[] memory reviewAdmins_)
  {
    return (_reviewAdmins.values());
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantPlatformAdmin  Allows the super user Default Admin to add an address to the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newPlatformAdmin_              The address of the new platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantPlatformAdmin(address newPlatformAdmin_) public onlySuperAdmin {
    if (newPlatformAdmin_ == address(0)) {
      revert PlatformAdminCannotBeAddressZero();
    }

    _grantRole(PLATFORM_ADMIN, newPlatformAdmin_);
    // Add this to the enumerated list:
    _platformAdmins.add(newPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantReviewAdmin  Allows the super user Default Admin to add an address to the review admin group.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newReviewAdmin_              The address of the new review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function grantReviewAdmin(address newReviewAdmin_) public onlySuperAdmin {
    if (newReviewAdmin_ == address(0)) {
      revert ReviewAdminCannotBeAddressZero();
    }
    _grantRole(REVIEW_ADMIN, newReviewAdmin_);
    // Add this to the enumerated list:
    _reviewAdmins.add(newReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokePlatformAdmin  Allows the super user Default Admin to revoke from the platform admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldPlatformAdmin_              The address of the old platform admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokePlatformAdmin(
    address oldPlatformAdmin_
  ) external onlySuperAdmin {
    _revokeRole(PLATFORM_ADMIN, oldPlatformAdmin_);
    // Remove this from the enumerated list:
    _platformAdmins.remove(oldPlatformAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeReviewAdmin  Allows the super user Default Admin to revoke an address to the review admin group
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param oldReviewAdmin_              The address of the old review admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function revokeReviewAdmin(address oldReviewAdmin_) external onlySuperAdmin {
    _revokeRole(REVIEW_ADMIN, oldReviewAdmin_);
    // Remove this from the enumerated list:
    _reviewAdmins.remove(oldReviewAdmin_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferSuperAdmin  Allows the super user Default Admin to transfer this right to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newSuperAdmin_              The address of the new default admin
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferSuperAdmin(address newSuperAdmin_) external onlySuperAdmin {
    _grantRole(DEFAULT_ADMIN_ROLE, newSuperAdmin_);
    _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // Update storage of this address:
    superAdmin = newSuperAdmin_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) transferProjectOwner  Allows the current project owner to transfer this role to another address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param newProjectOwner_   New project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferProjectOwner(
    address newProjectOwner_
  ) external onlyProjectOwner {
    _grantRole(PROJECT_OWNER, newProjectOwner_);
    _revokeRole(PROJECT_OWNER, msg.sender);
    projectOwner = newProjectOwner_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) grantRole  Override to revert, as all modifications occur through our own functions
   *
   * _____________________________________________________________________________________________________________________
   */
  function grantRole(bytes32, address) public pure override {
    revert CannotGrantOrRevokeDirectly();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) revokeRole  Override to revert, as all modifications occur through our own functions
   *
   * _____________________________________________________________________________________________________________________
   */

  function revokeRole(bytes32, address) public pure override {
    revert CannotGrantOrRevokeDirectly();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                     -->ACCESS CONTROL
   * @dev (function) _initialiseAuthorityModel  Set intial authorities and roles
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_        The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_    Array of Platform admins
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_      Project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialiseAuthorityModel(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_
  ) internal {
    if (platformAdmins_.length == 0) {
      revert MustHaveAPlatformAdmin();
    }

    // DEFAULT_ADMIN_ROLE can grant and revoke all other roles. This address MUST be secured:
    _grantRole(DEFAULT_ADMIN_ROLE, superAdmin_);
    superAdmin = superAdmin_;

    // Setup the project owner address
    _grantRole(PROJECT_OWNER, projectOwner_);
    projectOwner = projectOwner_;

    // Setup the platform admin addresses
    for (uint256 i = 0; i < platformAdmins_.length; ) {
      _grantRole(PLATFORM_ADMIN, platformAdmins_[i]);
      // Add this to the enumerated list:
      _platformAdmins.add(platformAdmins_[i]);

      unchecked {
        i++;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title IConfigStructures.sol. Interface for common config structures used accross the platform
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

interface IConfigStructures {
  enum DropStatus {
    approved,
    deployed,
    cancelled
  }

  enum TemplateStatus {
    live,
    terminated
  }

  // The current status of the mint:
  //   - notEnabled: This type of mint is not part of this drop
  //   - notYetOpen: This type of mint is part of the drop, but it hasn't started yet
  //   - open: it's ready for ya, get in there.
  //   - finished: been and gone.
  //   - unknown: theoretically impossible.
  enum MintStatus {
    notEnabled,
    notYetOpen,
    open,
    finished,
    unknown
  }

  struct SubListConfig {
    uint256 start;
    uint256 end;
    uint256 phaseMaxSupply;
  }

  struct PrimarySaleModuleInstance {
    address instanceAddress;
    string instanceDescription;
  }

  struct NFTModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct PrimarySaleModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct VestingModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct RoyaltySplitterModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModuleConfig {
    uint256 templateId;
    bytes configData;
  }

  struct InLifeModules {
    InLifeModuleConfig[] modules;
  }

  struct NFTConfig {
    uint256 supply;
    uint256 mintingMethod;
    string name;
    string symbol;
    bytes32 positionProof;
  }

  struct DropApproval {
    DropStatus status;
    uint32 lastChangedDate;
    address dropOwnerAddress;
    bytes32 configHash;
  }

  struct Template {
    TemplateStatus status;
    uint16 templateNumber;
    uint32 loadedDate;
    address payable templateAddress;
    string templateDescription;
  }

  struct NumericOverride {
    bool isSet;
    uint248 overrideValue;
  }

  error AlreadyInitialised();
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title ERC721M.sol. Metadrop implementation of ERC721
 *
 * @author metadrop https://metadrop.com/
 *
 * @notice Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 *
 * Included features:
 * - LayerZero ONFT
 * - gas efficient batch minting
 * - clonable
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "../ThirdParty/EPS/EPSDelegationRegister/IEPSDelegationRegister.sol";
import "../ThirdParty/LayerZero/onft/IONFT721.sol";
import "../ThirdParty/LayerZero/onft/ONFT721Core.sol";

contract ERC721M is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  ONFT721Core,
  IONFT721,
  ERC2981
{
  using Address for address;
  using Strings for uint256;

  address internal constant BURN_ADDRESS =
    0x000000000000000000000000000000000000dEaD;

  // Boolean to indicate if this contract is a layerZero base contract
  bool private immutable layerZeroBase;

  // EPS Register
  IEPSDelegationRegister internal immutable epsRegister;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  uint256 internal remainingSupply;
  uint256 public maxSupply;

  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  error CallerIsNotOwnerOrApproved();
  error SendFromIncorrectOwner();
  error InvalidTokenID();
  error QuantityExceedsRemainingSupply();
  error InvalidOwner();
  error CannotApproveOwner();
  error CallerIsNotApprovedOrOwner();
  error TransferToNonReceiver();
  error CannotMintToZeroAddress();
  error TokenAlreadyExists();
  error TransferFromNonOwner();
  error CannotTransferToZeroAddress();
  error OwnerCannotBeOperator();

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param lzEndpoint_         The LZ endpoint for this chain
   *                            (see https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param layerZeroBase_      If this contract is the base layerZero contract. For this ONFT implementation the base
   *                            contract is where intial minting can occue. NFTs can then be sent to any supporting chain
   *                            but cannot be 'freshly' minted on other chains and sent to the base contract.
   * _____________________________________________________________________________________________________________________
   */
  constructor(
    address epsRegister_,
    address lzEndpoint_,
    bool layerZeroBase_
  ) ONFT721Core(lzEndpoint_) {
    epsRegister = IEPSDelegationRegister(epsRegister_);
    layerZeroBase = layerZeroBase_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param name_               The name of the NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param symbol_             The symbol of the NFT
   * ---------------------------------------------------------------------------------------------------------------------
   * @param maxSupply_          The maximum supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param owner_              The owner for this contract. Will be used to set the owner in ERC721M and also the
   *                            platform admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _initialiseERC721M(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    address owner_
  ) internal {
    _name = name_;
    _symbol = symbol_;
    maxSupply = maxSupply_;
    remainingSupply = maxSupply_;
    _transferOwnership(owner_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->LAYERZERO
   * @dev (function) _debitFrom  debit an item from a holder on layerzero call. While off-chain the NFT is custodied in
   * this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from_               The current owner of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId being sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _debitFrom(
    address from_,
    uint16,
    bytes memory,
    uint256 tokenId_
  ) internal virtual override {
    if (!(_isApprovedOrOwner(_msgSender(), tokenId_))) {
      revert CallerIsNotOwnerOrApproved();
    }

    if (!(ownerOf(tokenId_) == from_)) {
      revert SendFromIncorrectOwner();
    }

    _transfer(from_, address(this), tokenId_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                          -->LAYERZERO
   * @dev (function) _creditTo  credit an item to a holder on layerzero call. While off-chain the NFT is custodied in
   * this contract, this transfers it back to the holder
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param toAddress_          The recipient of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId that has been sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _creditTo(
    uint16,
    address toAddress_,
    uint256 tokenId_
  ) internal virtual override {
    if (!(_exists(tokenId_) && ownerOf(tokenId_) == address(this))) {
      revert InvalidTokenID();
    }
    // Different behaviour depending on whether this has been deployed on
    // the base chain or a satellite chain:
    if (layerZeroBase) {
      // Base chain. For us to be crediting the owner this token MUST be
      // owned by the contract, as they can only be minted on the base chain
      if (!(_exists(tokenId_) && ownerOf(tokenId_) == address(this))) {
        revert InvalidTokenID();
      }

      _transfer(address(this), toAddress_, tokenId_);
    } else {
      // Satellite chain. We can be crediting the user as a result of this reaching
      // this chain for the first time (mint) OR from a token that has been minted
      // here previously and is currently custodied by the contract.
      if (_exists(tokenId_) && ownerOf(tokenId_) != address(this)) {
        revert InvalidTokenID();
      }

      if (!_exists(tokenId_)) {
        _safeMint(toAddress_, tokenId_);
      } else {
        _transfer(address(this), toAddress_, tokenId_);
      }
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _mintIdWithoutBalanceUpdate  Mint an item without updating a holder's balance, so that this can
   * be performed just once per batch.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to_          The recipient of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId_            The tokenId that has been sent via LayerZero
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _mintIdWithoutBalanceUpdate(address to_, uint256 tokenId_) private {
    _beforeTokenTransfer(address(0), to_, tokenId_, 1);

    _owners[tokenId_] = to_;

    emit Transfer(address(0), to_, tokenId_);

    _afterTokenTransfer(address(0), to_, tokenId_, 1);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) _mintSequential  Mint NFTs in order (0,1,2,3 etc)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to_          The recipient of the asset
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantity_    The number of tokens to mint
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _mintSequential(
    address to_,
    uint256 quantity_
  ) internal virtual returns (uint256[] memory mintedTokenIds_) {
    if (quantity_ > remainingSupply) {
      revert QuantityExceedsRemainingSupply();
    }

    mintedTokenIds_ = new uint256[](quantity_);

    uint256 tokenId = maxSupply - remainingSupply;

    for (uint256 i = 0; i < quantity_; ) {
      _mintIdWithoutBalanceUpdate(to_, tokenId + i);

      mintedTokenIds_[i] = tokenId + i;

      unchecked {
        i++;
      }
    }

    remainingSupply = remainingSupply - quantity_;
    _balances[to_] += quantity_;

    return (mintedTokenIds_);
  }

  /** ____________________________________________________________________________________________________________________
   *
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply() external view virtual returns (uint256 totalSupply_) {
    //
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted()
    external
    view
    virtual
    returns (uint256 totalUnminted_)
  {
    //
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() external view virtual returns (uint256 totalMinted_) {
    //
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() external view virtual returns (uint256 totalBurned_) {
    //
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(
    bytes4 interfaceId
  )
    public
    view
    virtual
    override(ERC165, IERC165, ERC2981, ONFT721Core)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(
    address owner
  ) public view virtual override returns (uint256) {
    if (owner == address(0)) {
      revert InvalidOwner();
    }
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(
    uint256 tokenId
  ) public view virtual override returns (address) {
    address owner = _ownerOf(tokenId);
    if (owner == address(0)) {
      revert InvalidTokenID();
    }
    return owner;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory) {
    _requireMinted(tokenId);

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
   * by default, can be overridden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721M.ownerOf(tokenId);
    if (to == owner) {
      revert CannotApproveOwner();
    }

    if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
      revert CallerIsNotApprovedOrOwner();
    }

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(
    uint256 tokenId
  ) public view virtual override returns (address) {
    _requireMinted(tokenId);

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public virtual override {
    _setApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(
    address owner,
    address operator
  ) public view virtual override returns (bool) {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
      revert CallerIsNotApprovedOrOwner();
    }

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual override {
    if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
      revert CallerIsNotApprovedOrOwner();
    }

    _safeTransfer(from, to, tokenId, data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `data` is additional data, it has no specified format and it is sent in call to `to`.
   *
   * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
   * implement alternative mechanisms to perform token transfer, such as signature-based.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);

    if (!_checkOnERC721Received(from, to, tokenId, data)) {
      revert TransferToNonReceiver();
    }
  }

  /**
   * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
   */
  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    return _owners[tokenId];
  }

  /**
   * @dev Returns whether `tokenId` exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (`_mint`),
   * and stop existing when they are burned (`_burn`).
   */
  function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _ownerOf(tokenId) != address(0);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) internal view virtual returns (bool) {
    address owner = ERC721M.ownerOf(tokenId);
    return (spender == owner ||
      isApprovedForAll(owner, spender) ||
      getApproved(tokenId) == spender);
  }

  /**
   * @dev Safely mints `tokenId` and transfers it to `to`.
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, "");
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);

    if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
      revert TransferToNonReceiver();
    }
  }

  /**
   * @dev Mints `tokenId` and transfers it to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
   *
   * Requirements:
   *
   * - `tokenId` must not exist.
   * - `to` cannot be the zero address.
   *
   * Emits a {Transfer} event.
   */
  function _mint(address to, uint256 tokenId) internal virtual {
    if (to == address(0)) {
      revert CannotMintToZeroAddress();
    }

    if (_exists(tokenId)) {
      revert TokenAlreadyExists();
    }

    _beforeTokenTransfer(address(0), to, tokenId, 1);

    if (_exists(tokenId)) {
      revert TokenAlreadyExists();
    }

    unchecked {
      // Will not overflow unless all 2**256 token ids are minted to the same owner.
      // Given that tokens are minted one by one, it is impossible in practice that
      // this ever happens. Might change if we allow batch minting.
      // The ERC fails to describe this case.
      _balances[to] += 1;
    }

    _owners[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId, 1);
  }

  /**
   * @dev Burns `tokenId`. See {ERC721-_burn}.
   *
   * Requirements:
   *
   * - The caller must own `tokenId` or be an approved operator.
   */
  function burn(uint256 tokenId) public virtual {
    if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
      revert CallerIsNotApprovedOrOwner();
    }

    _burn(tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   * This is an internal function that does not check if the sender is authorized to operate on the token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721M.ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId, 1);

    // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
    owner = ERC721M.ownerOf(tokenId);

    // Clear approvals
    delete _tokenApprovals[tokenId];

    unchecked {
      // Cannot overflow, as that would require more tokens to be burned/transferred
      // out than the owner initially received through minting and transferring in.
      _balances[owner] -= 1;
      _owners[tokenId] = BURN_ADDRESS;
      _balances[BURN_ADDRESS] += 1;
    }
    delete _owners[tokenId];

    emit Transfer(owner, BURN_ADDRESS, tokenId);

    _afterTokenTransfer(owner, BURN_ADDRESS, tokenId, 1);
  }

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
   *
   * Requirements:
   *
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    if (ERC721M.ownerOf(tokenId) != from) {
      revert TransferFromNonOwner();
    }

    if (to == address(0)) {
      revert CannotTransferToZeroAddress();
    }

    _beforeTokenTransfer(from, to, tokenId, 1);

    // Check that tokenId was not transferred by `_beforeTokenTransfer` hook

    if (ERC721M.ownerOf(tokenId) != from) {
      revert TransferFromNonOwner();
    }

    // Clear approvals from the previous owner
    delete _tokenApprovals[tokenId];

    unchecked {
      // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
      // `from`'s balance is the number of token held, which is at least one before the current
      // transfer.
      // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
      // all 2**256 token ids to be minted, which in practice is impossible.
      _balances[from] -= 1;
      _balances[to] += 1;
    }
    _owners[tokenId] = to;

    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId, 1);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721M.ownerOf(tokenId), to, tokenId);
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
    if (owner == operator) {
      revert OwnerCannotBeOperator();
    }

    _operatorApprovals[owner][operator] = approved;
    emit ApprovalForAll(owner, operator, approved);
  }

  /**
   * @dev Reverts if the `tokenId` has not been minted yet.
   */
  function _requireMinted(uint256 tokenId) internal view virtual {
    if (!_exists(tokenId)) {
      revert InvalidTokenID();
    }
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert TransferToNonReceiver();
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
   * - When `from` is zero, the tokens will be minted for `to`.
   * - When `to` is zero, ``from``'s tokens will be burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 /* firstTokenId */,
    uint256 batchSize
  ) internal virtual {
    if (batchSize > 1) {
      if (from != address(0)) {
        _balances[from] -= batchSize;
      }
      if (to != address(0)) {
        _balances[to] += batchSize;
      }
    }
  }

  /**
   * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
   * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
   * - When `from` is zero, the tokens were minted for `to`.
   * - When `to` is zero, ``from``'s tokens were burned.
   * - `from` and `to` are never both zero.
   * - `batchSize` is non-zero.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _afterTokenTransfer(
    address from,
    address to,
    uint256 firstTokenId,
    uint256 batchSize
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title INFTByMetadrop.sol. Interface for metadrop NFT standard
 *
 * @author metadrop https://metadrop.com/
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Global/IConfigStructures.sol";

interface INFTByMetadrop is IConfigStructures {
  /** ====================================================================================================================
   *                                                     EVENTS
   * =====================================================================================================================
   */
  event Revealed();
  event RandomNumberReceived(uint256 indexed requestId, uint256 randomNumber);
  event VRFPositionSet(uint256 VRFPosition);
  event PositionProofSet(bytes32 positionProof);
  event MetadropMint(
    address indexed allowanceAddress,
    address indexed recipientAddress,
    address callerAddress,
    address primarySaleModuleAddress,
    uint256 unitPrice,
    uint256[] tokenIds
  );

  /** ====================================================================================================================
   *                                                     ERRORS
   * =====================================================================================================================
   */
  error MetadataIsLocked();
  error InvalidAddress();
  error IncorrectConfirmationValue();
  error MintingIsClosedForever();
  error VRFAlreadySet();
  error PositionProofAlreadySet();
  error MetadropFactoryOnly();
  error InvalidRecipient();
  error PauseCutOffHasPassed();

  /** ====================================================================================================================
   *                                                    FUNCTIONS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_              The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_          An array of platform admin addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_       The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_ The primary sale modules for this drop. These are the contract addresses that are
   *                            authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_          The drop specific configuration for this NFT. This is decoded and used to set
   *                            configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitter_  The address of the deployed royalty payment splitted for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param totalRoyaltyPercentage_  The total royalty percentage (project + metadrop) for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    address royaltyPaymentSplitter_,
    uint96 totalRoyaltyPercentage_,
    string[3] calldata collectionURIs_,
    uint8 pauseCutOffInDays_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_);

  /** ____________________________________________________________________________________________________________________
   *
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply() external view returns (uint256 totalSupply_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted() external view returns (uint256 totalUnminted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted() external view returns (uint256 totalMinted_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned() external view returns (uint256 totalBurned_);

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param preRevealURI_   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param arweaveURI_     The URI for arweave
   * ---------------------------------------------------------------------------------------------------------------------
   * @param ipfsURI_     The URI for IPFS
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(
    string calldata preRevealURI_,
    string calldata arweaveURI_,
    string calldata ipfsURI_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_   The confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone(string calldata confirmation_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner OR platform admin to set minting
   *                                                          complete
   *
   * @notice Enter confirmation value of "MintingComplete" to confirm that you are closing minting.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_  Confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone(
    string calldata confirmation_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setUseArweave  Guards against either arweave or IPFS being no more
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param useArweave_   Boolean to indicate whether arweave should be used or not (true = use arweave, false = use IPFS)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setUseArweave(bool useArweave_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(address recipient_, uint96 fraction_) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_   The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_        The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  ) external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setStartPosition  Get the metadata start position for use on reveal of this collection
   * _____________________________________________________________________________________________________________________
   */
  function setStartPosition() external;

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external;
}

// SPDX-License-Identifier: BUSL 1.0
// Metadrop Contracts (v0.0.1)

/**
 *
 * @title NFTByMetadrop.sol. This contract is the clonable template contract for
 * all metadrop NFT deployments.
 *
 * @author metadrop https://metadrop.com/
 *
 * @notice This contract does not include logic associated with the primary
 * sale of the NFT, that functionality being provided by other contracts within
 * the metadrop platform (e.g. an auction, or a public and list based sale) that
 * form a suite of primary sale modules.
 *
 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./ERC721M.sol";
import "./INFTByMetadrop.sol";
import "../DropFactory/IDropFactory.sol";
import "../Global/AuthorityModel.sol";

/**
 *
 * @dev Inheritance details:
 *      ERC721M                 ERC721Metadrop token standard, based on openzeppelin ERC721
 *      INFTMetadrop            Interface definition for the metadrop NFT
 *      DefaultOperatorFilterer Implemented for royalty compliant filtering
 *      Pausable                Allow contract to be paused by an authorised user
 *
 */

contract NFTByMetadrop is
  ERC721M,
  INFTByMetadrop,
  DefaultOperatorFilterer,
  Pausable,
  AuthorityModel
{
  using Strings for uint256;

  // Which metadata source are we using:
  bool public useArweave;

  // Is metadata locked?:
  bool public metadataLocked;

  // Minting complete confirmation
  bool public mintingComplete;

  // Are we revealed:
  bool public collectionRevealed;

  // Bool that controls initialisation and only allows it to occur ONCE. This is
  // needed as this contract is clonable, threfore the constructor is not called
  // on cloned instances. We setup state of this contract through the initialise
  // function.
  bool public initialised;

  uint8 public pauseCutOffInDays;

  uint32 private deployTimeStamp;

  // URI details:
  string public preRevealURI;
  string public arweaveURI;
  string public ipfsURI;

  // Proof and VRF results for metadata reveal:
  bytes32 public positionProof;
  uint256 public recordedRandomWord;
  uint256 public vrfStartPosition;

  // Valid primary market addresses
  mapping(address => bool) public validPrimaryMarketAddress;

  /** ====================================================================================================================
   *                                              CONSTRUCTOR AND INTIIALISE
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                        -->CONSTRUCTOR
   * @dev constructor           The constructor is not called when the contract is cloned. In this
   *                            constructor we just setup default values and set the template contract to initialised.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param epsRegister_        The EPS register address (0x888888888888660F286A7C06cfa3407d09af44B2 on most chains)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param lzEndpoint_         The LZ endpoint for this chain
   *                            (see https://layerzero.gitbook.io/docs/technical-reference/mainnet/supported-chain-ids)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param layerZeroBase_      If this contract is the base layerZero contract. For this ONFT implementation the base
   *                            contract is where intial minting can occue. NFTs can then be sent to any supporting chain
   *                            but cannot be 'freshly' minted on other chains and sent to the base contract.
   * _____________________________________________________________________________________________________________________
   */
  constructor(
    address epsRegister_,
    address lzEndpoint_,
    bool layerZeroBase_
  ) ERC721M(epsRegister_, lzEndpoint_, layerZeroBase_) {
    // Initialise this template instance:
    _initialiseERC721M("NFT", "NFT", 0, msg.sender);

    initialised = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) initialiseNFT  Load configuration into storage for a new instance.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param superAdmin_              The super admin for this contract. A super admin can manage roles
   * ---------------------------------------------------------------------------------------------------------------------
   * @param platformAdmins_          An array of platform admin addresses
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_            The project owner for this drop. Sets the project admin AccessControl role
   * ---------------------------------------------------------------------------------------------------------------------
   * @param primarySaleModules_      The primary sale modules for this drop. These are the contract addresses that are
   *                                 authorised to call mint on this contract.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_               The drop specific configuration for this NFT. This is decoded and used to set
   *                                 configuration for this metadrop drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyPaymentSplitter_  The address of the deployed royalty payment splitted for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param royaltyFromSalesInBasisPoints_  The royalty basis points for this drop
   * ---------------------------------------------------------------------------------------------------------------------
   * @param collectionURIs_          The URIs for this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * @param pauseCutOffInDays_       The number of days from deployment that this contract can be paused
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function initialiseNFT(
    address superAdmin_,
    address[] memory platformAdmins_,
    address projectOwner_,
    PrimarySaleModuleInstance[] calldata primarySaleModules_,
    NFTModuleConfig calldata nftModule_,
    address royaltyPaymentSplitter_,
    uint96 royaltyFromSalesInBasisPoints_,
    string[3] calldata collectionURIs_,
    uint8 pauseCutOffInDays_
  ) public {
    // This clone instance can only be initialised ONCE
    if (initialised) revert AlreadyInitialised();

    // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
    // will not revert, but the contract will need to be registered with the registry once it is deployed in
    // order for the modifier to filter addresses.
    if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
      OPERATOR_FILTER_REGISTRY.registerAndSubscribe(
        address(this),
        CANONICAL_CORI_SUBSCRIPTION
      );
    }

    _decodeAndSetParams(projectOwner_, nftModule_);

    _initialiseAuthorityModel(superAdmin_, platformAdmins_, projectOwner_);

    // Load the primary sale modules to the mappings
    for (uint256 i = 0; i < primarySaleModules_.length; ) {
      validPrimaryMarketAddress[primarySaleModules_[i].instanceAddress] = true;
      unchecked {
        i++;
      }
    }

    // Royalty setup
    // If the royalty contract is address(0) then the royalty module
    // has been flagged as not required for this drop.
    // To avoid any possible loss of funds from incorrect configuation we don't
    // set the royalty receiver address to address(0), but rather to the first
    // platform admin
    if (royaltyPaymentSplitter_ == address(0)) {
      _setDefaultRoyalty(platformAdmins_[0], royaltyFromSalesInBasisPoints_);
    } else {
      _setDefaultRoyalty(
        royaltyPaymentSplitter_,
        royaltyFromSalesInBasisPoints_
      );
    }

    useArweave = false;
    metadataLocked = false;
    mintingComplete = false;
    collectionRevealed = false;

    preRevealURI = collectionURIs_[0];
    ipfsURI = collectionURIs_[1];
    arweaveURI = collectionURIs_[2];

    factory = msg.sender;

    pauseCutOffInDays = pauseCutOffInDays_;
    deployTimeStamp = uint32(block.timestamp);

    // Set this clone to initialised
    initialised = true;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                         -->INITIALISE
   * @dev (function) _decodeAndSetParams  Decode NFT Parameters
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param projectOwner_     The project owner
   * ---------------------------------------------------------------------------------------------------------------------
   * @param nftModule_        NFT module data
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function _decodeAndSetParams(
    address projectOwner_,
    NFTModuleConfig calldata nftModule_
  ) internal {
    // Decode the config
    (
      uint256 decodedSupply,
      ,
      string memory decodedName,
      string memory decodedSymbol,
      bytes32 decodedPositionProof
    ) = abi.decode(
        nftModule_.configData,
        (uint256, uint256, string, string, bytes32)
      );

    // Initialise values on ERC721M
    _initialiseERC721M(
      decodedName,
      decodedSymbol,
      decodedSupply,
      projectOwner_
    );

    positionProof = decodedPositionProof;
  }

  /** ====================================================================================================================
   *                                            OPERATOR FILTER REGISTRY
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) setApprovalForAll  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param operator            The operator for the approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param approved            If the operator is approved
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setApprovalForAll(
    address operator,
    bool approved
  ) public override onlyAllowedOperatorApproval(operator) whenNotPaused {
    super.setApprovalForAll(operator, approved);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) approve  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param operator            The operator for the approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function approve(
    address operator,
    uint256 tokenId
  ) public override onlyAllowedOperatorApproval(operator) whenNotPaused {
    super.approve(operator, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) transferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) whenNotPaused {
    super.transferFrom(from, to, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) safeTransferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override onlyAllowedOperator(from) whenNotPaused {
    super.safeTransferFrom(from, to, tokenId);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                    -->OPERATOR FILTER
   * @dev (function) safeTransferFrom  Operator filter registry override
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param from                The sender of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param to                  The recipient of the token
   * ---------------------------------------------------------------------------------------------------------------------
   * @param tokenId             The tokenId for this approval
   * ---------------------------------------------------------------------------------------------------------------------
   * @param data                bytes data accompanying this transfer operation
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public override onlyAllowedOperator(from) whenNotPaused {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  /** ====================================================================================================================
   *                                                 PRIVILEGED ACCESS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->PAUSE
   * @dev (function) pause    Allow platform admin to pause
   * _____________________________________________________________________________________________________________________
   */
  function pause() external onlyPlatformAdminOrProjectOwner {
    unchecked {
      if (block.timestamp > (deployTimeStamp + pauseCutOffInDays * 1 days)) {
        revert PauseCutOffHasPassed();
      }
    }
    _pause();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                              -->PAUSE
   * @dev (function) unpause    Allow platform admin to unpause
   *
   * _____________________________________________________________________________________________________________________
   */
  function unpause() external onlyPlatformAdminOrProjectOwner {
    _unpause();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                       -->LOCK MINTING
   * @dev (function) setMintingCompleteForeverCannotBeUndone  Allow project owner OR platform admin to set minting
   *                                                          complete
   *
   * @notice Enter confirmation value of "done" to confirm that you are closing minting.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_  Confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setMintingCompleteForeverCannotBeUndone(
    string calldata confirmation_
  ) external onlyPlatformAdminOrProjectOwner {
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked("done"))
    ) {
      mintingComplete = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) revealCollection  Set the collection to revealed
   *
   * _____________________________________________________________________________________________________________________
   */
  function revealCollection() external onlyPlatformAdminOrProjectOwner {
    collectionRevealed = true;

    emit Revealed();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setPositionProof  Set the metadata position proof
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param positionProof_  The metadata proof
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setPositionProof(bytes32 positionProof_) external onlyPlatformAdmin {
    positionProof = positionProof_;

    emit PositionProofSet(positionProof_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) setStartPosition  Get the metadata start position for use on reveal of this collection
   * _____________________________________________________________________________________________________________________
   */
  function setStartPosition() external onlyPlatformAdminOrProjectOwner {
    if (recordedRandomWord != 0) {
      revert VRFAlreadySet();
    }
    IDropFactory(factory).requestVRFRandomness();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->REVEAL
   * @dev (function) fulfillRandomWords  Callback from the chainlinkv2 oracle (on factory) with randomness
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param requestId_      The Id of this request (this contract will submit a single request)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param randomWords_   The random words returned from chainlink
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function fulfillRandomWords(
    uint256 requestId_,
    uint256[] memory randomWords_
  ) external {
    if (msg.sender == factory) {
      recordedRandomWord = randomWords_[0];
      unchecked {
        vrfStartPosition = (randomWords_[0] % maxSupply) + 1;
      }
      emit RandomNumberReceived(requestId_, randomWords_[0]);
      emit VRFPositionSet(vrfStartPosition);
    } else {
      revert MetadropFactoryOnly();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setURIs  Set the URI data for this contracts
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param preRevealURI_   The URI to use pre-reveal
   * ---------------------------------------------------------------------------------------------------------------------
   * @param arweaveURI_     The URI for arweave
   * ---------------------------------------------------------------------------------------------------------------------
   * @param ipfsURI_     The URI for IPFS
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setURIs(
    string calldata preRevealURI_,
    string calldata arweaveURI_,
    string calldata ipfsURI_
  ) external onlyPlatformAdmin {
    if (metadataLocked) {
      revert MetadataIsLocked();
    }

    preRevealURI = preRevealURI_;
    arweaveURI = arweaveURI_;
    ipfsURI = ipfsURI_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) lockURIsCannotBeUndone  Lock the URI data for this contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param confirmation_   The confirmation string
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function lockURIsCannotBeUndone(
    string calldata confirmation_
  ) external onlyPlatformAdmin {
    if (
      keccak256(abi.encodePacked(confirmation_)) ==
      keccak256(abi.encodePacked("lock"))
    ) {
      metadataLocked = true;
    } else {
      revert IncorrectConfirmationValue();
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                           -->METADATA
   * @dev (function) setUseArweave  Guards against either arweave or IPFS being no more
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param useArweave_   Boolean to indicate whether arweave should be used or not (true = use arweave, false = use IPFS)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setUseArweave(
    bool useArweave_
  ) external onlyPlatformAdminOrProjectOwner {
    useArweave = useArweave_;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) setDefaultRoyalty  Set the royalty percentage
   *
   * @notice - we have specifically NOT implemented the ability to have different royalties on a token by token basis.
   * This reduces the complexity of processing on multi-buys, and also avoids challenges to decentralisation (e.g. the
   * project targetting one users tokens with larger royalties)
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_   Royalty receiver
   * ---------------------------------------------------------------------------------------------------------------------
   * @param fraction_   Royalty fraction
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function setDefaultRoyalty(
    address recipient_,
    uint96 fraction_
  ) public onlyPlatformAdminOrProjectOwner {
    _setDefaultRoyalty(recipient_, fraction_);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->ROYALTY
   * @dev (function) deleteDefaultRoyalty  Delete the royalty percentage claimed
   *
   * _____________________________________________________________________________________________________________________
   */
  function deleteDefaultRoyalty() public onlyPlatformAdminOrProjectOwner {
    _deleteDefaultRoyalty();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) receive  This contract does not handle ETH. Explicitly revert on receive()
   *
   * _____________________________________________________________________________________________________________________
   */
  receive() external payable {
    revert();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                            -->FINANCE
   * @dev (function) fallback  Explicitly revert on fallback()
   *
   * _____________________________________________________________________________________________________________________
   */
  fallback() external payable {
    revert();
  }

  /** ====================================================================================================================
   *                                             COLLECTION INFORMATION GETTERS
   * =====================================================================================================================
   */

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) metadropCustom  Returns if this contract is a custom NFT (true) or is a standard metadrop
   *                                 ERC721M (false)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return isMetadropCustom_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropCustom() external pure returns (bool isMetadropCustom_) {
    return (false);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalSupply  Returns total supply (minted - burned)
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalSupply_   The total supply of this collection (minted - burned)
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalSupply()
    external
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalSupply_)
  {
    return totalMinted() - totalBurned();
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalUnminted  Returns the remaining unminted supply
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalUnminted_   The total unminted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalUnminted()
    public
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalUnminted_)
  {
    return remainingSupply;
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalMinted  Returns the total number of tokens ever minted
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalMinted_   The total minted supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalMinted()
    public
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalMinted_)
  {
    return (maxSupply - remainingSupply);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) totalBurned  Returns the count of tokens sent to the burn address
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return totalBurned_   The total burned supply of this collection
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function totalBurned()
    public
    view
    override(ERC721M, INFTByMetadrop)
    returns (uint256 totalBurned_)
  {
    return ERC721M.balanceOf(BURN_ADDRESS);
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) tokenURI  Returns the URI for the passed token
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return tokenURI_   The token URI
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function tokenURI(
    uint256 tokenId
  ) public view virtual override returns (string memory tokenURI_) {
    _requireMinted(tokenId);

    unchecked {
      if (!collectionRevealed) {
        return
          bytes(preRevealURI).length > 0
            ? string(abi.encodePacked(preRevealURI))
            : "";
      } else {
        if (useArweave) {
          return
            bytes(arweaveURI).length > 0
              ? string(
                abi.encodePacked(
                  arweaveURI,
                  ((tokenId + vrfStartPosition) % maxSupply).toString(),
                  ".json"
                )
              )
              : "";
        } else {
          return
            bytes(ipfsURI).length > 0
              ? string(
                abi.encodePacked(
                  ipfsURI,
                  ((tokenId + vrfStartPosition) % maxSupply).toString(),
                  ".json"
                )
              )
              : "";
        }
      }
    }
  }

  /** ____________________________________________________________________________________________________________________
   *                                                                                                             -->GETTER
   * @dev (function) supportsInterface   Override is required by Solidity.
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @return bool    If the interface is supported
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function supportsInterface(
    bytes4 interfaceId
  ) public view override(AccessControl, ERC721M) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /** ====================================================================================================================
   *                                                    MINTING
   * =====================================================================================================================
   */
  /** ____________________________________________________________________________________________________________________
   *                                                                                                               -->MINT
   * @dev (function) metadropMint  Mint tokens. Can only be called from a valid primary market contract
   *
   * ---------------------------------------------------------------------------------------------------------------------
   * @param caller_                The address that has called mint through the primary sale module.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param recipient_             The address that will receive new assets.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param allowanceAddress_      The address that has an allowance being used in this mint. This will be the same as the
   *                               calling address in almost all cases. An example of when they may differ is in a list
   *                               mint where the caller is a delegate of another address with an allowance in the list.
   *                               The caller is performing the mint, but it is the allowance for the allowance address
   *                               that is being checked and decremented in this mint.
   * ---------------------------------------------------------------------------------------------------------------------
   * @param quantityToMint_        The quantity of tokens to be minted
   * ---------------------------------------------------------------------------------------------------------------------
   * @param unitPrice_             The unit price for each token
   * ---------------------------------------------------------------------------------------------------------------------
   * _____________________________________________________________________________________________________________________
   */
  function metadropMint(
    address caller_,
    address recipient_,
    address allowanceAddress_,
    uint256 quantityToMint_,
    uint256 unitPrice_
  ) external {
    if (recipient_ == address(0) || recipient_ == BURN_ADDRESS) {
      revert InvalidRecipient();
    }

    if (mintingComplete) {
      revert MintingIsClosedForever();
    }

    if (!validPrimaryMarketAddress[msg.sender]) revert InvalidAddress();

    uint256[] memory tokenIds = _mintSequential(recipient_, quantityToMint_);

    emit MetadropMint(
      allowanceAddress_,
      recipient_,
      caller_,
      msg.sender,
      unitPrice_,
      tokenIds
    );
  }
  /** ====================================================================================================================
   */
}

// SPDX-License-Identifier: CC0-1.0
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev EPS Delegation Register - Interface

 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../EPSRewardToken/IOAT.sol";
import "../EPSRewardToken/IERCOmnReceiver.sol";

/**
 *
 * @dev Implementation of the EPS proxy register interface.
 *
 */
interface IEPSDelegationRegister {
  // ======================================================
  // ENUMS and STRUCTS
  // ======================================================

  // Scope of a delegation: global, collection or token
  enum DelegationScope {
    global,
    collection,
    token
  }

  // Time limit of a delegation: eternal or time limited
  enum DelegationTimeLimit {
    eternal,
    limited
  }

  // The Class of a delegation: primary, secondary or rental
  enum DelegationClass {
    primary,
    secondary,
    rental
  }

  // The status of a delegation:
  enum DelegationStatus {
    live,
    pending
  }

  // Data output format for a report (used to output both hot and cold
  // delegation details)
  struct DelegationReport {
    address hot;
    address cold;
    DelegationScope scope;
    DelegationClass class;
    DelegationTimeLimit timeLimit;
    address collection;
    uint256 tokenId;
    uint40 startDate;
    uint40 endDate;
    bool validByDate;
    bool validBilaterally;
    bool validTokenOwnership;
    bool[25] usageTypes;
    address key;
    uint96 controlInteger;
    bytes data;
    DelegationStatus status;
  }

  // Delegation record
  struct DelegationRecord {
    address hot;
    uint96 controlInteger;
    address cold;
    uint40 startDate;
    uint40 endDate;
    DelegationStatus status;
  }

  // If a delegation is for a collection, or has additional data, it will need to read the delegation metadata
  struct DelegationMetadata {
    address collection;
    uint256 tokenId;
    bytes data;
  }

  // Details of a hot wallet lock
  struct LockDetails {
    uint40 lockStart;
    uint40 lockEnd;
  }

  // Validity dates when checking a delegation
  struct ValidityDates {
    uint40 start;
    uint40 end;
  }

  // Delegation struct to hold details of a new delegation
  struct Delegation {
    address hot;
    address cold;
    address[] targetAddresses;
    uint256 tokenId;
    bool tokenDelegation;
    uint8[] usageTypes;
    uint40 startDate;
    uint40 endDate;
    uint16 providerCode;
    DelegationClass delegationClass;
    uint96 subDelegateKey;
    bytes data;
    DelegationStatus status;
  }

  // Addresses associated with a delegation check
  struct DelegationCheckAddresses {
    address hot;
    address cold;
    address targetCollection;
  }

  // Classes associated with a delegation check
  struct DelegationCheckClasses {
    bool secondary;
    bool rental;
    bool token;
  }

  // Migrated record data
  struct MigratedRecord {
    address hot;
    address cold;
  }

  // ======================================================
  // CUSTOM ERRORS
  // ======================================================

  error UsageTypeAlreadyDelegated(uint256 usageType);
  error CannotDeleteValidDelegation();
  error CannotDelegatedATokenYouDontOwn();
  error IncorrectAdminLevel(uint256 requiredLevel);
  error OnlyParticipantOrAuthorisedSubDelegate();
  error HotAddressIsLockedAndCannotBeDelegatedTo();
  error InvalidDelegation();
  error ToMuchETHForPendingPayments(uint256 sent, uint256 required);
  error UnknownAmount();
  error InvalidERC20Payment();
  error IncorrectProxyRegisterFee();
  error UnrecognisedEPSAPIAmount();
  error CannotRevokeAllForRegisterAdminHierarchy();

  // ======================================================
  // EVENTS
  // ======================================================

  event DelegationMade(
    address indexed hot,
    address indexed cold,
    address targetAddress,
    uint256 tokenId,
    bool tokenDelegation,
    uint8[] usageTypes,
    uint40 startDate,
    uint40 endDate,
    uint16 providerCode,
    DelegationClass delegationClass,
    uint96 subDelegateKey,
    bytes data,
    DelegationStatus status
  );
  event DelegationRevoked(address hot, address cold, address delegationKey);
  event DelegationPaid(address delegationKey);
  event AllDelegationsRevokedForHot(address hot);
  event AllDelegationsRevokedForCold(address cold);
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   *
   *
   * @dev getDelegationRecord
   *
   *
   */
  function getDelegationRecord(address delegationKey_)
    external
    view
    returns (DelegationRecord memory);

  /**
   *
   *
   * @dev isValidDelegation
   *
   *
   */
  function isValidDelegation(
    address hot_,
    address cold_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (bool isValid_);

  /**
   *
   *
   * @dev getAddresses - Get all currently valid addresses for a hot address.
   * - Pass in address(0) to return records that are for ALL collections
   * - Pass in a collection address to get records for just that collection
   * - Usage type must be supplied. Only records that match usage type will be returned
   *
   *
   */
  function getAddresses(
    address hot_,
    address collection_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (address[] memory addresses_);

  /**
   *
   *
   * @dev beneficiaryBalanceOf: Returns the beneficiary balance
   *
   *
   */
  function beneficiaryBalanceOf(
    address queryAddress_,
    address contractAddress_,
    uint256 usageType_,
    bool erc1155_,
    uint256 id_,
    bool includeSecondary_,
    bool includeRental_
  ) external view returns (uint256 balance_);

  /**
   *
   *
   * @dev beneficiaryOf
   *
   *
   */
  function beneficiaryOf(
    address collection_,
    uint256 tokenId_,
    uint256 usageType_,
    bool includeSecondary_,
    bool includeRental_
  )
    external
    view
    returns (
      address primaryBeneficiary_,
      address[] memory secondaryBeneficiaries_
    );

  /**
   *
   *
   * @dev delegationFromColdExists - check a cold delegation exists
   *
   *
   */
  function delegationFromColdExists(address cold_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev delegationFromHotExists - check a hot delegation exists
   *
   *
   */
  function delegationFromHotExists(address hot_, address delegationKey_)
    external
    view
    returns (bool);

  /**
   *
   *
   * @dev getAllForHot - Get all delegations at a hot address, formatted nicely
   *
   *
   */
  function getAllForHot(address hot_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev getAllForCold - Get all delegations at a cold address, formatted nicely
   *
   *
   */
  function getAllForCold(address cold_)
    external
    view
    returns (DelegationReport[] memory);

  /**
   *
   *
   * @dev makeDelegation - A direct call to setup a new proxy record
   *
   *
   */
  function makeDelegation(
    address hot_,
    address cold_,
    address[] memory targetAddresses_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint8[] memory usageTypes_,
    uint40 startDate_,
    uint40 endDate_,
    uint16 providerCode_,
    DelegationClass delegationClass_, //0 = primary, 1 = secondary, 2 = rental
    uint96 subDelegateKey_,
    bytes memory data_
  ) external payable;

  /**
   *
   *
   * @dev getDelegationKey - get the link hash to the delegation metadata
   *
   *
   */
  function getDelegationKey(
    address hot_,
    address cold_,
    address targetAddress_,
    uint256 tokenId_,
    bool tokenDelegation_,
    uint96 controlInteger_,
    uint40 startDate_,
    uint40 endDate_
  ) external pure returns (address);

  /**
   *
   *
   * @dev getHotAddressLockDetails
   *
   *
   */
  function getHotAddressLockDetails(address hot_)
    external
    view
    returns (LockDetails memory, address[] memory);

  /**
   *
   *
   * @dev lockAddressUntilDate
   *
   *
   */
  function lockAddressUntilDate(uint40 unlockDate_) external;

  /**
   *
   *
   * @dev lockAddress
   *
   *
   */
  function lockAddress() external;

  /**
   *
   *
   * @dev unlockAddress
   *
   *
   */
  function unlockAddress() external;

  /**
   *
   *
   * @dev addLockBypassAddress
   *
   *
   */
  function addLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev removeLockBypassAddress
   *
   *
   */
  function removeLockBypassAddress(address bypassAddress_) external;

  /**
   *
   *
   * @dev revokeRecord: Revoking a single record with Key
   *
   *
   */
  function revokeRecord(address delegationKey_, uint96 subDelegateKey_)
    external;

  /**
   *
   *
   * @dev revokeGlobalAll
   *
   *
   */
  function revokeRecordOfGlobalScopeForAllUsages(address participant2_)
    external;

  /**
   *
   *
   * @dev revokeAllForCold: Cold calls and revokes ALL
   *
   *
   */
  function revokeAllForCold(address cold_, uint96 subDelegateKey_) external;

  /**
   *
   *
   * @dev revokeAllForHot: Hot calls and revokes ALL
   *
   *
   */
  function revokeAllForHot() external;

  /**
   *
   *
   * @dev deleteExpired: ANYONE can delete expired records
   *
   *
   */
  function deleteExpired(address delegationKey_) external;

  /**
   *
   *
   * @dev setRegisterFee: set the fee for accepting a registration:
   *
   *
   */
  function setRegisterFees(
    uint256 registerFee_,
    address erc20_,
    uint256 erc20Fee_
  ) external;

  /**
   *
   *
   * @dev setRewardTokenAndRate
   *
   *
   */
  function setRewardTokenAndRate(address rewardToken_, uint88 rewardRate_)
    external;

  /**
   *
   *
   * @dev lockRewardRate
   *
   *
   */
  function lockRewardRate() external;

  /**
   *
   *
   * @dev setLegacyOff
   *
   *
   */
  function setLegacyOff() external;

  /**
   *
   *
   * @dev setENSName (used to set reverse record so interactions with this contract are easy to
   * identify)
   *
   *
   */
  function setENSName(string memory ensName_) external;

  /**
   *
   *
   * @dev setENSReverseRegistrar
   *
   *
   */
  function setENSReverseRegistrar(address ensReverseRegistrar_) external;

  /**
   *
   *
   * @dev setTreasuryAddress: set the treasury address:
   *
   *
   */
  function setTreasuryAddress(address treasuryAddress_) external;

  /**
   *
   *
   * @dev setDecimalsAndBalance
   *
   *
   */
  function setDecimalsAndBalance(uint8 decimals_, uint256 balance_) external;

  /**
   *
   *
   * @dev withdrawETH: withdraw eth to the treasury:
   *
   *
   */
  function withdrawETH(uint256 amount_) external returns (bool success_);

  /**
   *
   *
   * @dev withdrawERC20: Allow any ERC20s to be withdrawn Note, this is provided to enable the
   * withdrawal of payments using valid ERC20s. Assets sent here in error are retrieved with
   * rescueERC20
   *
   *
   */
  function withdrawERC20(IERC20 token_, uint256 amount_) external;

  /**
   *
   *
   * @dev isLevelAdmin
   *
   *
   */
  function isLevelAdmin(
    address receivedAddress_,
    uint256 level_,
    uint96 key_
  ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev IERCOmnReceiver - Interface

 */

pragma solidity 0.8.19;

interface IERCOmnReceiver {
  function onTokenTransfer(
    address sender,
    uint256 value,
    bytes memory data
  ) external payable;
}

// SPDX-License-Identifier: MIT
// EPS Contracts v2.0.0
// www.eternalproxy.com

/**
 
@dev IOAT - Interface

 */

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev OAT interface
 */
interface IOAT is IERC20 {
  /**
   *
   * @dev emitToken
   *
   */
  function emitToken(address receiver_, uint256 amount_) external;

  /**
   *
   * @dev addEmitter
   *
   */
  function addEmitter(address emitter_) external;

  /**
   *
   * @dev removeEmitter
   *
   */
  function removeEmitter(address emitter_) external;

  /**
   *
   * @dev setTreasury
   *
   */
  function setTreasury(address treasury_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";
import "../util/BytesLib.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is
  Ownable,
  ILayerZeroReceiver,
  ILayerZeroUserApplicationConfig
{
  using BytesLib for bytes;

  ILayerZeroEndpoint public immutable lzEndpoint;
  mapping(uint16 => bytes) public trustedRemoteLookup;
  mapping(uint16 => mapping(uint16 => uint256)) public minDstGasLookup;
  address public precrime;

  event SetPrecrime(address precrime);
  event SetTrustedRemote(uint16 _remoteChainId, bytes _path);
  event SetTrustedRemoteAddress(uint16 _remoteChainId, bytes _remoteAddress);
  event SetMinDstGas(uint16 _dstChainId, uint16 _type, uint256 _minDstGas);

  error InvalidEndpointCaller();
  error InvalidSourceSendingContract();
  error DestinationIsNotTrustedSource();
  error MinGasLimitNotSet();
  error GasLimitIsTooLow();
  error InvalidAdapterParams();
  error NoTrustedPathRecord();
  error InvalidMinGas();

  constructor(address _endpoint) {
    lzEndpoint = ILayerZeroEndpoint(_endpoint);
  }

  function lzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) public virtual override {
    // lzReceive must be called by the endpoint for security
    if (_msgSender() != address(lzEndpoint)) {
      revert InvalidEndpointCaller();
    }

    bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
    // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
    if (
      !(_srcAddress.length == trustedRemote.length &&
        trustedRemote.length > 0 &&
        keccak256(_srcAddress) == keccak256(trustedRemote))
    ) {
      revert InvalidSourceSendingContract();
    }

    _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function _lzSend(
    uint16 _dstChainId,
    bytes memory _payload,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams,
    uint256 _nativeFee
  ) internal virtual {
    bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];

    if (trustedRemote.length == 0) {
      revert DestinationIsNotTrustedSource();
    }

    lzEndpoint.send{value: _nativeFee}(
      _dstChainId,
      trustedRemote,
      _payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _checkGasLimit(
    uint16 _dstChainId,
    uint16 _type,
    bytes memory _adapterParams,
    uint256 _extraGas
  ) internal view virtual {
    uint256 providedGasLimit = _getGasLimit(_adapterParams);
    uint256 minGasLimit = minDstGasLookup[_dstChainId][_type] + _extraGas;

    if (minGasLimit == 0) {
      revert MinGasLimitNotSet();
    }

    if (providedGasLimit < minGasLimit) {
      revert GasLimitIsTooLow();
    }
  }

  function _getGasLimit(
    bytes memory _adapterParams
  ) internal pure virtual returns (uint256 gasLimit) {
    if (_adapterParams.length < 34) {
      revert InvalidAdapterParams();
    }

    assembly {
      gasLimit := mload(add(_adapterParams, 34))
    }
  }

  //---------------------------UserApplication config----------------------------------------
  function getConfig(
    uint16 _version,
    uint16 _chainId,
    address,
    uint256 _configType
  ) external view returns (bytes memory) {
    return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
  }

  // generic config for LayerZero user Application
  function setConfig(
    uint16 _version,
    uint16 _chainId,
    uint256 _configType,
    bytes calldata _config
  ) external override onlyOwner {
    lzEndpoint.setConfig(_version, _chainId, _configType, _config);
  }

  function setSendVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setSendVersion(_version);
  }

  function setReceiveVersion(uint16 _version) external override onlyOwner {
    lzEndpoint.setReceiveVersion(_version);
  }

  function forceResumeReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress
  ) external override onlyOwner {
    lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
  }

  // _path = abi.encodePacked(remoteAddress, localAddress)
  // this function set the trusted path for the cross-chain communication
  function setTrustedRemote(
    uint16 _srcChainId,
    bytes calldata _path
  ) external onlyOwner {
    trustedRemoteLookup[_srcChainId] = _path;
    emit SetTrustedRemote(_srcChainId, _path);
  }

  function setTrustedRemoteAddress(
    uint16 _remoteChainId,
    bytes calldata _remoteAddress
  ) external onlyOwner {
    trustedRemoteLookup[_remoteChainId] = abi.encodePacked(
      _remoteAddress,
      address(this)
    );
    emit SetTrustedRemoteAddress(_remoteChainId, _remoteAddress);
  }

  function getTrustedRemoteAddress(
    uint16 _remoteChainId
  ) external view returns (bytes memory) {
    bytes memory path = trustedRemoteLookup[_remoteChainId];
    if (path.length == 0) {
      revert NoTrustedPathRecord();
    }

    return path.slice(0, path.length - 20); // the last 20 bytes should be address(this)
  }

  function setPrecrime(address _precrime) external onlyOwner {
    precrime = _precrime;
    emit SetPrecrime(_precrime);
  }

  function setMinDstGas(
    uint16 _dstChainId,
    uint16 _packetType,
    uint256 _minGas
  ) external onlyOwner {
    if (_minGas == 0) {
      revert InvalidMinGas();
    }

    minDstGasLookup[_dstChainId][_packetType] = _minGas;
    emit SetMinDstGas(_dstChainId, _packetType, _minGas);
  }

  //--------------------------- VIEW FUNCTION ----------------------------------------
  function isTrustedRemote(
    uint16 _srcChainId,
    bytes calldata _srcAddress
  ) external view returns (bool) {
    bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
    return keccak256(trustedSource) == keccak256(_srcAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";
import "../util/ExcessivelySafeCall.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
  using ExcessivelySafeCall for address;

  constructor(address _endpoint) LzApp(_endpoint) {}

  mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32)))
    public failedMessages;

  event MessageFailed(
    uint16 _srcChainId,
    bytes _srcAddress,
    uint64 _nonce,
    bytes _payload,
    bytes _reason
  );
  event RetryMessageSuccess(
    uint16 _srcChainId,
    bytes _srcAddress,
    uint64 _nonce,
    bytes32 _payloadHash
  );

  // overriding the virtual function in LzReceiver
  function _blockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual override {
    (bool success, bytes memory reason) = address(this).excessivelySafeCall(
      gasleft(),
      150,
      abi.encodeWithSelector(
        this.nonblockingLzReceive.selector,
        _srcChainId,
        _srcAddress,
        _nonce,
        _payload
      )
    );
    // try-catch all errors/exceptions
    if (!success) {
      failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
      emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload, reason);
    }
  }

  function nonblockingLzReceive(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) public virtual {
    // only internal transaction
    require(_msgSender() == address(this), "1");
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
  }

  //@notice override this function
  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 _nonce,
    bytes memory _payload
  ) internal virtual;

  function retryMessage(
    uint16 _srcChainId,
    bytes calldata _srcAddress,
    uint64 _nonce,
    bytes calldata _payload
  ) public payable virtual {
    // assert there is message to retry
    bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
    require(payloadHash != bytes32(0), "2");
    require(keccak256(_payload) == payloadHash, "3");
    // clear the stored message
    failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
    // execute the message. revert if it fails again
    _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    emit RetryMessageSuccess(_srcChainId, _srcAddress, _nonce, payloadHash);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "./IONFT721Core.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT721 is IONFT721Core, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Interface of the ONFT Core standard
 */
interface IONFT721Core is IERC165 {
  /**
   * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
   * _dstChainId - L0 defined chain id to send tokens too
   * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
   * _tokenId - token Id to transfer
   * _useZro - indicates to use zro to pay L0 fees
   * _adapterParams - flexible bytes array to indicate messaging adapter services in L0
   */
  function estimateSendFee(
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _tokenId,
    bool _useZro,
    bytes calldata _adapterParams
  ) external view returns (uint256 nativeFee, uint256 zroFee);

  /**
   * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
   * `_toAddress` can be any size depending on the `dstChainId`.
   * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
   * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
   */
  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes calldata _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes calldata _adapterParams
  ) external payable;

  /**
   * @dev Emitted when `_tokenId` are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
   * `_nonce` is the outbound nonce from
   */
  event SendToChain(
    uint16 indexed _dstChainId,
    address indexed _from,
    bytes indexed _toAddress,
    uint256 _tokenId
  );

  /**
   * @dev Emitted when `_tokenId` are sent from `_srcChainId` to the `_toAddress` at this chain. `_nonce` is the inbound nonce.
   */
  event ReceiveFromChain(
    uint16 indexed _srcChainId,
    bytes indexed _srcAddress,
    address indexed _toAddress,
    uint256 _tokenId
  );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IONFT721Core.sol";
import "../../LayerZero/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ONFT721Core is NonblockingLzApp, ERC165, IONFT721Core {
  uint256 public constant NO_EXTRA_GAS = 0;
  uint16 public constant FUNCTION_TYPE_SEND = 1;
  bool public useCustomAdapterParams;

  event SetUseCustomAdapterParams(bool _useCustomAdapterParams);

  error AdapterParamsMustBeEmpty();

  constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {}

  function supportsInterface(
    bytes4 interfaceId
  ) public view virtual override(ERC165, IERC165) returns (bool) {
    return
      interfaceId == type(IONFT721Core).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function estimateSendFee(
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    bool _useZro,
    bytes memory _adapterParams
  ) public view virtual override returns (uint256 nativeFee, uint256 zroFee) {
    // mock the payload for send()
    bytes memory payload = abi.encode(_toAddress, _tokenId);
    return
      lzEndpoint.estimateFees(
        _dstChainId,
        address(this),
        payload,
        _useZro,
        _adapterParams
      );
  }

  function sendFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) public payable virtual override {
    _send(
      _from,
      _dstChainId,
      _toAddress,
      _tokenId,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams
    );
  }

  function _send(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId,
    address payable _refundAddress,
    address _zroPaymentAddress,
    bytes memory _adapterParams
  ) internal virtual {
    _debitFrom(_from, _dstChainId, _toAddress, _tokenId);

    bytes memory payload = abi.encode(_toAddress, _tokenId);

    if (useCustomAdapterParams) {
      _checkGasLimit(
        _dstChainId,
        FUNCTION_TYPE_SEND,
        _adapterParams,
        NO_EXTRA_GAS
      );
    } else {
      if (_adapterParams.length != 0) {
        revert AdapterParamsMustBeEmpty();
      }
    }
    _lzSend(
      _dstChainId,
      payload,
      _refundAddress,
      _zroPaymentAddress,
      _adapterParams,
      msg.value
    );

    emit SendToChain(_dstChainId, _from, _toAddress, _tokenId);
  }

  function _nonblockingLzReceive(
    uint16 _srcChainId,
    bytes memory _srcAddress,
    uint64 /*_nonce*/,
    bytes memory _payload
  ) internal virtual override {
    (bytes memory toAddressBytes, uint256 tokenId) = abi.decode(
      _payload,
      (bytes, uint256)
    );
    address toAddress;
    assembly {
      toAddress := mload(add(toAddressBytes, 20))
    }

    _creditTo(_srcChainId, toAddress, tokenId);

    emit ReceiveFromChain(_srcChainId, _srcAddress, toAddress, tokenId);
  }

  function setUseCustomAdapterParams(
    bool _useCustomAdapterParams
  ) external onlyOwner {
    useCustomAdapterParams = _useCustomAdapterParams;
    emit SetUseCustomAdapterParams(_useCustomAdapterParams);
  }

  function _debitFrom(
    address _from,
    uint16 _dstChainId,
    bytes memory _toAddress,
    uint256 _tokenId
  ) internal virtual;

  function _creditTo(
    uint16 _srcChainId,
    address _toAddress,
    uint256 _tokenId
  ) internal virtual;
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
    internal
    pure
    returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
            tempBytes := mload(0x40)

        // Store the length of the first bytes array at the beginning of
        // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

        // Maintain a memory counter for the current write location in the
        // temp bytes array by adding the 32 bytes for the array length to
        // the starting location.
            let mc := add(tempBytes, 0x20)
        // Stop copying when the memory counter reaches the length of the
        // first bytes array.
            let end := add(mc, length)

            for {
            // Initialize a copy counter to the start of the _preBytes data,
            // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
            // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
            // Write the _preBytes data into the tempBytes memory 32 bytes
            // at a time.
                mstore(mc, mload(cc))
            }

        // Add the length of _postBytes to the current length of tempBytes
        // and store it as the new length in the first 32 bytes of the
        // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

        // Move the memory counter back from a multiple of 0x20 to the
        // actual end of the _preBytes data.
            mc := end
        // Stop copying when the memory counter reaches the new combined
        // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

        // Update the free-memory pointer by padding our last write location
        // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
        // next 32 byte block, then round down to the nearest multiple of
        // 32. If the sum of the length of the two arrays is zero then add
        // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
            add(add(end, iszero(add(length, mload(_preBytes)))), 31),
            not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
        // Read the first 32 bytes of _preBytes storage, which is the length
        // of the array. (We don't need to use the offset into the slot
        // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
        // Arrays of 31 bytes or less have an even value in their slot,
        // while longer arrays have an odd value. The actual length is
        // the slot divided by two for odd values, and the lowest order
        // byte divided by two for even values.
        // If the slot is even, bitwise and the slot with 255 and divide by
        // two to get the length. If the slot is odd, bitwise and the slot
        // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
        // slength can contain both the length and contents of the array
        // if length < 32 bytes so let's prepare for that
        // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
            // Since the new array still fits in the slot, we just need to
            // update the contents of the slot.
            // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                _preBytes.slot,
                // all the modifications to the slot are inside this
                // next block
                add(
                // we can just add to the slot contents because the
                // bytes we want to change are the LSBs
                fslot,
                add(
                mul(
                div(
                // load the bytes from memory
                mload(add(_postBytes, 0x20)),
                // zero all bytes to the right
                exp(0x100, sub(32, mlength))
                ),
                // and now shift left the number of bytes to
                // leave space for the length in the slot
                exp(0x100, sub(32, newlength))
                ),
                // increase length by the double of the memory
                // bytes length
                mul(mlength, 2)
                )
                )
                )
            }
            case 1 {
            // The stored value fits in the slot, but the combined value
            // will exceed it.
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // The contents of the _postBytes array start 32 bytes into
            // the structure. Our first read should obtain the `submod`
            // bytes that can fit into the unused space in the last word
            // of the stored array. To get this, we read 32 bytes starting
            // from `submod`, so the data we read overlaps with the array
            // contents by `submod` bytes. Masking the lowest-order
            // `submod` bytes allows us to add that value directly to the
            // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                sc,
                add(
                and(
                fslot,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                ),
                and(mload(mc), mask)
                )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
            // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
            // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

            // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

            // Copy over the first `submod` bytes of the new data as in
            // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
    internal
    pure
    returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
                tempBytes := mload(0x40)

            // The first word of the slice result is potentially a partial
            // word read from the original array. To read it, we calculate
            // the length of that partial word and start copying that many
            // bytes into the array. The first word we copy will start with
            // data we don't care about, but the last `lengthmod` bytes will
            // land at the beginning of the contents of the new array. When
            // we're done copying, we overwrite the full first word with
            // the actual length of the slice.
                let lengthmod := and(_length, 31)

            // The multiplication in the next line is necessary
            // because when slicing multiples of 32 bytes (lengthmod == 0)
            // the following copy loop was copying the origin's length
            // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                // The multiplication in the next line has the same exact purpose
                // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

            //update free-memory pointer
            //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
            //zero out the 32 bytes slice we are about to return
            //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

        // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
            // cb is a circuit breaker in the for loop since there's
            //  no said feature for inline assembly loops
            // cb = 1 - don't breaker
            // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                    // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
    internal
    view
    returns (bool)
    {
        bool success = true;

        assembly {
        // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
        // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

        // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                    // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                        // unsuccess:
                            success := 0
                        }
                    }
                    default {
                    // cb is a circuit breaker in the for loop since there's
                    //  no said feature for inline assembly loops
                    // cb = 1 - don't breaker
                    // cb = 0 - break
                        let cb := 1

                    // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                            // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
            // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.7.6;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
    0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
            _gas, // gas
            _target, // recipient
            0, // ether value
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
            _gas, // gas
            _target, // recipient
            add(_calldata, 0x20), // inloc
            mload(_calldata), // inlen
            0, // outloc
            0 // outlen
            )
        // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
        // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
        // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(bytes4 _newSelector, bytes memory _buf)
    internal
    pure
    {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
        // load the first word of
            let _word := mload(add(_buf, 0x20))
        // mask out the top 4 bytes
        // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
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
pragma solidity ^0.8.17;

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