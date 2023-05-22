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
// OpenZeppelin Contracts (last updated v4.8.0) (security/PullPayment.sol)

pragma solidity ^0.8.0;

import "../utils/escrow/Escrow.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/external-calls/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPayment {
    Escrow private immutable _escrow;

    constructor() {
        _escrow = new Escrow();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     *
     * Causes the `escrow` to emit a {Withdrawn} event.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     *
     * Causes the `escrow` to emit a {Deposited} event.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)

pragma solidity ^0.8.0;

import "../../access/Ownable.sol";
import "../Address.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract Escrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
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
pragma solidity 0.8.17;

/// CONTRACTS ///
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {PullPayment} from "@openzeppelin/contracts/security/PullPayment.sol";
import {ERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import {ERC1155PullTransfer} from "./utils/ERC1155PullTransfer.sol";

/// LIBRARIES ///
import {RBTLibrary} from "./libraries/RBTLibrary.sol";
import {LinkedListLibrary} from "./libraries/LinkedListLibrary.sol";

/// INTERFACES ///
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

/// @title Talentir Marketplace Contract
/// @author Christoph Siebenbrunner, Johannes Kares
/// @custom:security-contact [email protected]
contract TalentirMarketplaceV1 is
    Pausable,
    Ownable,
    ReentrancyGuard,
    ERC1155Receiver,
    PullPayment,
    ERC1155PullTransfer
{
    /// LIBRARIES ///

    using RBTLibrary for RBTLibrary.Tree;
    using LinkedListLibrary for LinkedListLibrary.LinkedList;

    /// TYPES ///

    /// @notice Side of order (buy=0, sell=1)
    enum Side {
        BUY,
        SELL
    }

    /// @notice Order struct
    /// @param orderId Id of order
    /// @param tokenId Id of token (ERC1155)
    /// @param side Side of order (buy=0, sell=1)
    /// @param sender Address of sender
    /// @param price Price of order. This is the price for 100% of the quantity.
    /// @param quantity Remaining quantity of order
    struct Order {
        uint256 orderId;
        uint256 tokenId;
        Side side;
        address sender;
        uint256 price;
        uint256 quantity;
    }

    /// @dev Internal OrderBook struct representing on specific tokenId
    struct OrderBook {
        /// @dev The price tree. Contains all available sorted prices for the token
        RBTLibrary.Tree priceTree;
        /// @dev price -> Linkedlist of orderIds. Each list contains all orders at specific price.
        mapping(uint256 => LinkedListLibrary.LinkedList) orderList;
    }

    /// @dev Internal Struct. This is used for a "stack to deep" error optimization
    struct OrderExecutedLocals {
        address seller;
        address buyer;
        address tokenSender;
        uint256 payToSeller;
        uint256 royalties;
        address royaltiesReceiver;
        bool success;
        uint256 talentirFee;
        uint256 remainingQuantity;
        uint256 quantity;
        bool useAsyncTransfer;
        uint256 cost;
    }

    /// MEMBERS ///

    /// @notice orderId => Order
    mapping(uint256 => Order) public orders;

    /// @notice Address of the corresponding ERC1155 contract
    address public talentirToken;

    /// @notice Current Marketplace Fee. 100% => 100 000
    uint256 public talentirFeePercent;

    /// @notice Address of the wallet receiving the marketplace fee
    address public talentirFeeWallet;

    /// @notice The constant represnting 100%
    uint256 public constant ONE_HUNDRED_PERCENT = 100_000;

    /// @notice This is the price factor. Public prices in this contract always represent 100% of
    /// the available quantity. This can be used to calculate the price for a single token.
    uint256 public constant PRICE_FACTOR = 1_000_000;

    /// @dev the next available orderId
    uint256 private _nextOrderId = 1;

    /// @dev tokenId => Side => OrderBook
    mapping(uint256 => mapping(Side => OrderBook)) private _markets;

    /// @dev private flag to enable receiving tokens
    bool private _contractCanReceiveToken = false;

    /// EVENTS ///

    /// @notice Event emitted when a new order is added
    /// @param orderId Id of order
    /// @param from Address of sender
    /// @param tokenId Id of token (ERC1155)
    /// @param side Side of order (buy=0, sell=1)
    /// @param price Price of order. This is the price for 100% of the quantity.
    /// @param quantity Quantity of order
    event OrderAdded(
        uint256 indexed orderId,
        address indexed from,
        uint256 tokenId,
        Side side,
        uint256 price,
        uint256 quantity
    );

    /// @notice Event emitted when an order is executed
    /// @param orderId Id of order
    /// @param buyer Address of buyer
    /// @param seller Address of seller
    /// @param paidToSeller Amount of token paid to seller (in wei)
    /// @param price Price of order. This is the price for 100% of the quantity.
    /// @param royalties Amount of token paid to royalties receiver (in wei)
    /// @param royaltiesReceiver Address of royalties receiver
    /// @param quantity Executed quantity of order
    /// @param remainingQuantity Remaining quantity in order
    /// @param asyncTransfer If true, the transfer of the token / ETH was executed async
    event OrderExecuted(
        uint256 orderId,
        address indexed buyer,
        address indexed seller,
        uint256 paidToSeller,
        uint256 price,
        uint256 royalties,
        address indexed royaltiesReceiver,
        uint256 quantity,
        uint256 remainingQuantity,
        bool asyncTransfer
    );

    /// @notice Event emitted when an order is cancelled
    /// @param orderId Id of order
    /// @param from Address of sender
    /// @param tokenId Id of token (ERC1155)
    /// @param side Side of order (buy=0, sell=1)
    /// @param price Price of order. This is the price for 100% of the quantity.
    /// @param quantity Quantity of order that was cancelled
    /// @param asyncTransfer If true, the refund of the token / ETH was executed async
    event OrderCancelled(
        uint256 indexed orderId,
        address indexed from,
        uint256 indexed tokenId,
        Side side,
        uint256 price,
        uint256 quantity,
        bool asyncTransfer
    );

    /// @notice Event emitted when the fee is changed
    /// @param fee New fee (100% => 100 000)
    /// @param wallet New wallet that receives the fee
    event TalentirFeeSet(uint256 fee, address indexed wallet);

    /// CONSTRUCTOR ///
    /// @param initialTalentirToken Address of the corresponding ERC1155 contract
    constructor(address initialTalentirToken) ERC1155PullTransfer(initialTalentirToken) {
        require(initialTalentirToken != address(0), "Invalid address");
        require(IERC165(initialTalentirToken).supportsInterface(type(IERC2981).interfaceId), "Must implement IERC2981");
        require(IERC165(initialTalentirToken).supportsInterface(type(IERC1155).interfaceId), "Must implement IERC1155");
        talentirToken = initialTalentirToken;
    }

    /// PUBLIC FUNCTIONS ///

    /// @notice Return the best `side` (buy=0, sell=1) order for token `tokenId`
    /// @param tokenId token Id (ERC1155)
    /// @param side Side of order (buy=0, sell=1)
    /// @return orderId of best order
    /// @return price price of best order. This is the price for 100% of the quantity.
    function getBestOrder(uint256 tokenId, Side side) public view returns (uint256 orderId, uint256 price) {
        price = side == Side.BUY ? _markets[tokenId][side].priceTree.last() : _markets[tokenId][side].priceTree.first();

        (, uint256 bestOrderId, ) = _markets[tokenId][side].orderList[price].getNode(0);
        orderId = bestOrderId;
    }

    /// @notice Computes the fee amount to be paid to Talentir for a transaction of size `totalPaid`
    /// @param totalPaid price*volume
    /// @return uint256 fee
    function calcTalentirFee(uint256 totalPaid) public view returns (uint256) {
        return (talentirFeePercent * totalPaid) / ONE_HUNDRED_PERCENT;
    }

    /// @notice Sell `tokenQuantity` of token `tokenId` for min `ethQuantity` total price. (ERC1155)
    /// @dev Price limit (`ethQuantity`) must always be included to prevent frontrunning.
    /// @dev Can emit multiple OrderExecuted events.
    /// @param from address that will send the ERC1155 and receive the ETH on successful sale
    /// (msg.sender must be approved to send token on behalf of for)
    /// @param tokenId token Id (ERC1155)
    /// @param ethQuantity total ETH demanded (quantity*minimum price per unit)
    /// @param tokenQuantity how much to sell in total of token
    /// @param addUnfilledOrderToOrderbook add order to order list at a limit price of ethQuantity/tokenQuantity if it can't be filled
    /// @param useAsyncTransfer use async transfer for ETH and ERC1155 transfers. Typically should
    /// be false but can be useful in case the ETH or ERC1155 transfer is blocked by the recipient
    function makeSellOrder(
        address from,
        uint256 tokenId,
        uint256 ethQuantity,
        uint256 tokenQuantity,
        bool addUnfilledOrderToOrderbook,
        bool useAsyncTransfer
    ) external whenNotPaused nonReentrant {
        _makeOrder(from, tokenId, Side.SELL, ethQuantity, tokenQuantity, addUnfilledOrderToOrderbook, useAsyncTransfer);
    }

    /// @notice Buy `tokenQuantity` of token `tokenId` for max `msg.value` total price.
    /// @dev Price limit must always be included to prevent frontrunning.
    /// @dev Can emit multiple OrderExecuted events.
    /// @param from address that will receive the ERC1155 token on successfull purchase
    /// @param tokenId token Id (ERC1155)
    /// @param tokenQuantity how much to buy in total of token
    /// @param addUnfilledOrderToOrderbook add order to order list at a limit price of WETHquantity/tokenQuantity if it can't be filled
    /// @param useAsyncTransfer use async transfer for ETH and ERC1155 transfers. Typically should
    /// be false but can be useful in case the ETH or ERC1155 transfer is blocked by the recipient
    /// @dev `msg.value` total ETH offered (quantity*maximum price per unit)
    function makeBuyOrder(
        address from,
        uint256 tokenId,
        uint256 tokenQuantity,
        bool addUnfilledOrderToOrderbook,
        bool useAsyncTransfer
    ) external payable whenNotPaused nonReentrant {
        _makeOrder(from, tokenId, Side.BUY, msg.value, tokenQuantity, addUnfilledOrderToOrderbook, useAsyncTransfer);
    }

    /// @notice Cancel orders: `orders`.
    /// This function may be front-runnable. This may be abused when the order owner wants
    /// to cancel one or more unfavorable market orders. Consider using private mempools, i.e.
    /// flashots.
    /// @dev emits OrdersCancelled event.
    /// @param orderIds array of order Ids
    /// @param useAsyncTransfer use async transfer for ETH and ERC1155 refunds. Typically should
    /// be false but can be useful in case the ETH or ERC1155 refund is blocked by the recipient
    function cancelOrders(uint256[] calldata orderIds, bool useAsyncTransfer) external nonReentrant {
        for (uint256 i = 0; i < orderIds.length; i++) {
            uint256 orderId = orderIds[i];
            Order memory order = orders[orderId];
            require(msg.sender == order.sender || msg.sender == owner(), "Wrong user");

            Side side = order.side;
            uint256 price = order.price;
            uint256 quantity = order.quantity;
            uint256 tokenId = order.tokenId;

            _removeOrder(orderId);

            if (useAsyncTransfer) {
                if (side == Side.BUY) {
                    _asyncTransfer(order.sender, (price * quantity) / PRICE_FACTOR);
                } else {
                    _asyncTokenTransferFrom(tokenId, address(this), order.sender, quantity);
                }
            } else {
                if (side == Side.BUY) {
                    _ethTransfer(order.sender, (price * quantity) / PRICE_FACTOR);
                } else {
                    _tokenTransferFrom(tokenId, address(this), order.sender, quantity);
                }
            }

            emit OrderCancelled(orderId, order.sender, tokenId, side, price, quantity, useAsyncTransfer);
        }
    }

    /// RESTRICTED PUBLIC FUNCTIONS ///

    /// @notice Pause contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Set the fee that Talentir will receive on each transaction.
    /// @dev emits DefaultFeeSet event.
    /// @dev fee capped at 10%
    /// @param fee fee percent (100% = 100 000)
    /// @param wallet address where Talentir fee will be sent to
    function setTalentirFee(uint256 fee, address wallet) external onlyOwner {
        require(wallet != address(0), "Wallet is zero");
        require(fee <= ONE_HUNDRED_PERCENT / 10, "Must be <=10k"); // Talentir fee can never be higher than 10%
        talentirFeePercent = fee;
        talentirFeeWallet = wallet;

        emit TalentirFeeSet(fee, wallet);
    }

    /// PRIVATE / INTERNAL FUNCTIONS ///

    /// @dev Return BUY for SELL or vice versa.
    function _oppositeSide(Side side) internal pure returns (Side) {
        return (side == Side.BUY) ? Side.SELL : Side.BUY;
    }

    /// @dev Make a limit order. Internally, all orders are limit orders to prevent frontrunning.
    function _makeOrder(
        address sender,
        uint256 tokenId,
        Side side,
        uint256 ethQuantity,
        uint256 tokenQuantity,
        bool addOrderForRemaining,
        bool useAsyncTransfer
    ) private {
        if (side == Side.SELL) {
            require(
                (sender == msg.sender) || (IERC1155(talentirToken).isApprovedForAll(sender, msg.sender)),
                "Not allowed"
            );
        }

        require(ethQuantity > 0, "Price must be positive");
        require(tokenQuantity > 0, "Token quantity must be positive");
        require(tokenQuantity <= 1_000_000, "Token quantity too high");

        uint256 price = (ethQuantity * PRICE_FACTOR) / tokenQuantity;
        require(price > 0, "Rounding problem");

        uint256 ethQuantityExecuted;
        Side oppositeSide = _oppositeSide(side);
        (uint256 bestOrderId, uint256 bestPrice) = getBestOrder(tokenId, oppositeSide);

        // If possible, buy up to the specified price limit
        uint256 remainingQuantity = tokenQuantity;

        while (
            (remainingQuantity > 0) &&
            ((side == Side.BUY) ? price >= bestPrice : price <= bestPrice) &&
            (bestOrderId > 0)
        ) {
            uint256 quantityToBuy;
            if (orders[bestOrderId].quantity >= remainingQuantity) {
                quantityToBuy = remainingQuantity;
            } else {
                quantityToBuy = orders[bestOrderId].quantity;
            }

            ethQuantityExecuted = _executeOrder(sender, bestOrderId, quantityToBuy, useAsyncTransfer);
            remainingQuantity -= quantityToBuy;

            if ((side == Side.BUY) && !(addOrderForRemaining)) {
                ethQuantity -= ethQuantityExecuted;
            }

            if (remainingQuantity > 0) {
                (bestOrderId, bestPrice) = getBestOrder(tokenId, oppositeSide);
            }
        }

        // If the order couldn't be filled, add the remaining quantity to buy orders
        if (addOrderForRemaining && (remainingQuantity > 0)) {
            _addOrder(tokenId, side, sender, price, remainingQuantity);
        }

        // Refund any remaining ETH from a buy order not added to order book
        if ((side == Side.BUY) && !(addOrderForRemaining)) {
            require(msg.value >= ethQuantity, "Couldn't refund"); // just to be safe - don't refund more than what was sent

            // Safe to directly send ETH. In the worst case the transaction just doesn't go through.
            _ethTransfer(sender, ethQuantity);
        }
    }

    /// @dev Executes one atomic order (transfers tokens and removes order).
    function _executeOrder(
        address sender,
        uint256 orderId,
        uint256 quantity,
        bool useAsyncTransfer
    ) private returns (uint256 ethQuantity) {
        // This is an optimization to avoid the famous "stack to deep" error.
        OrderExecutedLocals memory locals;
        Order memory order = orders[orderId];

        locals.quantity = quantity;
        locals.useAsyncTransfer = useAsyncTransfer;
        locals.cost = (order.price * quantity) / PRICE_FACTOR;

        (locals.royaltiesReceiver, locals.royalties) = IERC2981(talentirToken).royaltyInfo(order.tokenId, locals.cost);

        locals.talentirFee = calcTalentirFee(locals.cost);

        require(locals.cost > (locals.royalties + locals.talentirFee), "Problem calculating fees");

        if (quantity == order.quantity) {
            _removeOrder(orderId);
        } else {
            orders[orderId].quantity -= quantity;
            locals.remainingQuantity = orders[orderId].quantity;
        }

        if (order.side == Side.BUY) {
            // Caller is the seller
            locals.seller = sender;
            locals.buyer = order.sender;
            locals.tokenSender = sender;
        } else {
            // Caller is the buyer
            locals.seller = order.sender;
            locals.buyer = sender;
            locals.tokenSender = address(this);
        }

        locals.payToSeller = locals.cost - locals.royalties - locals.talentirFee;

        if (useAsyncTransfer) {
            _asyncTokenTransferFrom(order.tokenId, locals.tokenSender, locals.buyer, quantity);
            _asyncTransfer(locals.seller, locals.payToSeller);
            _asyncTransfer(locals.royaltiesReceiver, locals.royalties);
            _asyncTransfer(talentirFeeWallet, locals.talentirFee);
        } else {
            _tokenTransferFrom(order.tokenId, locals.tokenSender, locals.buyer, quantity);
            _ethTransfer(locals.seller, locals.payToSeller);
            _ethTransfer(locals.royaltiesReceiver, locals.royalties);
            _ethTransfer(talentirFeeWallet, locals.talentirFee);
        }

        _emitOrderExecutedEvent(locals, order);

        return locals.cost;
    }

    /// @dev This function exists to use less local variables and avoid the "stack to deep" error.
    function _emitOrderExecutedEvent(OrderExecutedLocals memory locals, Order memory order) private {
        emit OrderExecuted(
            order.orderId,
            locals.buyer,
            locals.seller,
            locals.payToSeller,
            order.price,
            locals.royalties,
            locals.royaltiesReceiver,
            locals.quantity,
            locals.remainingQuantity,
            locals.useAsyncTransfer
        );
    }

    /// @dev Add order to all data structures.
    function _addOrder(uint256 tokenId, Side side, address sender, uint256 price, uint256 quantity) private {
        // Transfer tokens to this contract
        if (side == Side.SELL) {
            _tokenTransferFrom(tokenId, sender, address(this), quantity);
        }

        // Check if orders already exist at that price, otherwise add tree entry
        if (!_markets[tokenId][side].priceTree.exists(price)) {
            _markets[tokenId][side].priceTree.insert(price);
        }

        // Add order to FIFO linked list at price
        _markets[tokenId][side].orderList[price].push(_nextOrderId, true);

        // add order to order mapping
        orders[_nextOrderId] = Order({
            orderId: _nextOrderId,
            side: side,
            tokenId: tokenId,
            sender: sender,
            price: price,
            quantity: quantity
        });

        emit OrderAdded(_nextOrderId, sender, tokenId, side, price, quantity);

        unchecked {
            _nextOrderId++;
        }
    }

    /// @dev Remove order from all data structures.
    function _removeOrder(uint256 orderId) private {
        uint256 price = orders[orderId].price;
        uint256 tokenId = orders[orderId].tokenId;
        Side side = orders[orderId].side;

        // remove order from linked list
        _markets[tokenId][side].orderList[price].remove(orderId);

        // if this was the last remaining order, remove node from red-black tree
        if (!_markets[tokenId][side].orderList[price].listExists()) {
            _markets[tokenId][side].priceTree.remove(price);
        }

        // remove from order mapping
        delete (orders[orderId]);
    }

    /// @dev Calls safeTransferFrom (ERC1155)
    function _tokenTransferFrom(uint256 tokenId, address from, address to, uint256 quantity) private {
        _contractCanReceiveToken = true;
        bytes memory data;
        IERC1155(talentirToken).safeTransferFrom(from, to, tokenId, quantity, data);
        _contractCanReceiveToken = false;
    }

    /// @dev Initiates an asynchronous transfer of tokens.
    function _asyncTokenTransferFrom(
        uint256 tokenId,
        address from,
        address to,
        uint256 quantity
    ) internal virtual override {
        _contractCanReceiveToken = true;
        super._asyncTokenTransferFrom(tokenId, from, to, quantity);
        _contractCanReceiveToken = false;
    }

    /// @dev Initiates an direct transfer of ETH.
    function _ethTransfer(address to, uint256 weiCount) private {
        (bool success, ) = to.call{value: weiCount}("");
        require(success, "Transfer failed");
    }

    /// OVERRIDE FUNCTIONS ///

    /// @dev This contract can only receive tokens when executing an order.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual override returns (bytes4) {
        require(_contractCanReceiveToken, "Cannot receive");

        return this.onERC1155Received.selector;
    }

    /// @dev This contract can't receive batch transfers.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual override returns (bytes4) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title LinkedListLib
 * @author Darryl Morris (o0ragman0o) and Modular.network
 *
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 * into the Modular-Network ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * It has been updated to add additional functionality and be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * version 1.0.0
 * Copyright (c) 2017 Modular Inc.
 * The MIT License (MIT)
 * https://github.com/Modular-network/ethereum-libraries/blob/master/LICENSE
 *
 * The LinkedListLib provides functionality for implementing data indexing using
 * a circlular linked list
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

library LinkedListLibrary {
    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    struct LinkedList {
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /// @dev returns true if the list exists
    /// @param self stored linked list from contract
    function listExists(LinkedList storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev returns true if the node exists
    /// @param self stored linked list from contract
    /// @param _node a node to search for
    function nodeExists(LinkedList storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /// @dev Returns the number of elements in the list
    /// @param self stored linked list from contract
    function sizeOf(LinkedList storage self) internal view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists, i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists, i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return numElements;
    }

    /// @dev Returns the links of a node as a tuple
    /// @param self stored linked list from contract
    /// @param _node id of the node to get
    function getNode(LinkedList storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /// @dev Returns the link of a node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node id of the node to step from
    /// @param _direction direction to step in
    function getAdjacent(
        LinkedList storage self,
        uint256 _node,
        bool _direction
    ) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /// @dev Can be used before `insert` to build an ordered list
    /// @param self stored linked list from contract
    /// @param _node an existing node to search from, e.g. HEAD.
    /// @param _value value to seek
    /// @param _direction direction to seek in
    //  @return next first node beyond '_node' in direction `_direction`
    function getSortedSpot(
        LinkedList storage self,
        uint256 _node,
        uint256 _value,
        bool _direction
    ) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }
        require((_node == 0) || nodeExists(self, _node));
        bool exists;
        uint256 next;
        (exists, next) = getAdjacent(self, _node, _direction);
        while ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }

    /// @dev Creates a bidirectional link between two nodes on direction `_direction`
    /// @param self stored linked list from contract
    /// @param _node first node for linking
    /// @param _link  node to link to in the _direction
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) internal {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /// @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node existing node
    /// @param _new  new node to insert
    /// @param _direction direction to insert node in
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }

    /// @dev removes an entry from the linked list
    /// @param self stored linked list from contract
    /// @param _node node to remove from the list
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /// @dev pushes an enrty to the head of the linked list
    /// @param self stored linked list from contract
    /// @param _node new entry to push to the head
    /// @param _direction push to the head (NEXT) or tail (PREV)
    function push(LinkedList storage self, uint256 _node, bool _direction) internal {
        insert(self, HEAD, _node, _direction);
    }

    /// @dev pops the first entry from the linked list
    /// @param self stored linked list from contract
    /// @param _direction pop from the head (NEXT) or the tail (PREV)
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists, adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// ----------------------------------------------------------------------------
// BokkyPooBah's Red-Black Tree Library v1.0-pre-release-a
//
// A Solidity Red-Black Tree binary search library to store and access a sorted
// list of unsigned integer data. The Red-Black algorithm rebalances the binary
// search tree, resulting in O(log n) insert, remove and search time (and ~gas)
//
// https://github.com/bokkypoobah/BokkyPooBahsRedBlackTreeLibrary
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2020. The MIT Licence.
// ----------------------------------------------------------------------------
//
// Minor modifications to error handling by DFK Team.
//
library RBTLibrary {
    struct Node {
        uint256 parent;
        uint256 left;
        uint256 right;
        bool red;
    }

    struct Tree {
        uint256 root;
        mapping(uint256 => Node) nodes;
    }

    uint256 private constant EMPTY = 0;

    function first(Tree storage self) internal view returns (uint256 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].left != EMPTY) {
                _key = self.nodes[_key].left;
            }
        }
    }

    function last(Tree storage self) internal view returns (uint256 _key) {
        _key = self.root;
        if (_key != EMPTY) {
            while (self.nodes[_key].right != EMPTY) {
                _key = self.nodes[_key].right;
            }
        }
    }

    function next(Tree storage self, uint256 target) internal view returns (uint256 cursor) {
        require(target != EMPTY, "Not found");
        if (self.nodes[target].right != EMPTY) {
            cursor = treeMinimum(self, self.nodes[target].right);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].right) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function prev(Tree storage self, uint256 target) internal view returns (uint256 cursor) {
        require(target != EMPTY, "Not found");
        if (self.nodes[target].left != EMPTY) {
            cursor = treeMaximum(self, self.nodes[target].left);
        } else {
            cursor = self.nodes[target].parent;
            while (cursor != EMPTY && target == self.nodes[cursor].left) {
                target = cursor;
                cursor = self.nodes[cursor].parent;
            }
        }
    }

    function exists(Tree storage self, uint256 key) internal view returns (bool) {
        return (key != EMPTY) && ((key == self.root) || (self.nodes[key].parent != EMPTY));
    }

    function isEmpty(uint256 key) internal pure returns (bool) {
        return key == EMPTY;
    }

    function getEmpty() internal pure returns (uint256) {
        return EMPTY;
    }

    function getNode(
        Tree storage self,
        uint256 key
    ) internal view returns (uint256 _returnKey, uint256 _parent, uint256 _left, uint256 _right, bool _red) {
        require(exists(self, key), "Not found");
        return (key, self.nodes[key].parent, self.nodes[key].left, self.nodes[key].right, self.nodes[key].red);
    }

    function insert(Tree storage self, uint256 key) internal {
        require(key != EMPTY, "Price below minimum");
        require(!exists(self, key), "Already created");
        uint256 cursor = EMPTY;
        uint256 probe = self.root;
        while (probe != EMPTY) {
            cursor = probe;
            if (key < probe) {
                probe = self.nodes[probe].left;
            } else {
                probe = self.nodes[probe].right;
            }
        }
        self.nodes[key] = Node({parent: cursor, left: EMPTY, right: EMPTY, red: true});
        if (cursor == EMPTY) {
            self.root = key;
        } else if (key < cursor) {
            self.nodes[cursor].left = key;
        } else {
            self.nodes[cursor].right = key;
        }
        insertFixup(self, key);
    }

    function remove(Tree storage self, uint256 key) internal {
        require(exists(self, key), "Not found");
        uint256 probe;
        uint256 cursor;
        if (self.nodes[key].left == EMPTY || self.nodes[key].right == EMPTY) {
            cursor = key;
        } else {
            cursor = self.nodes[key].right;
            while (self.nodes[cursor].left != EMPTY) {
                cursor = self.nodes[cursor].left;
            }
        }
        if (self.nodes[cursor].left != EMPTY) {
            probe = self.nodes[cursor].left;
        } else {
            probe = self.nodes[cursor].right;
        }
        uint256 yParent = self.nodes[cursor].parent;
        self.nodes[probe].parent = yParent;
        if (yParent != EMPTY) {
            if (cursor == self.nodes[yParent].left) {
                self.nodes[yParent].left = probe;
            } else {
                self.nodes[yParent].right = probe;
            }
        } else {
            self.root = probe;
        }
        bool doFixup = !self.nodes[cursor].red;
        if (cursor != key) {
            replaceParent(self, cursor, key);
            self.nodes[cursor].left = self.nodes[key].left;
            self.nodes[self.nodes[cursor].left].parent = cursor;
            self.nodes[cursor].right = self.nodes[key].right;
            self.nodes[self.nodes[cursor].right].parent = cursor;
            self.nodes[cursor].red = self.nodes[key].red;
            (cursor, key) = (key, cursor);
        }
        if (doFixup) {
            removeFixup(self, probe);
        }
        delete self.nodes[cursor];
    }

    function treeMinimum(Tree storage self, uint256 key) private view returns (uint256) {
        while (self.nodes[key].left != EMPTY) {
            key = self.nodes[key].left;
        }
        return key;
    }

    function treeMaximum(Tree storage self, uint256 key) private view returns (uint256) {
        while (self.nodes[key].right != EMPTY) {
            key = self.nodes[key].right;
        }
        return key;
    }

    function rotateLeft(Tree storage self, uint256 key) private {
        uint256 cursor = self.nodes[key].right;
        uint256 keyParent = self.nodes[key].parent;
        uint256 cursorLeft = self.nodes[cursor].left;
        self.nodes[key].right = cursorLeft;
        if (cursorLeft != EMPTY) {
            self.nodes[cursorLeft].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].left) {
            self.nodes[keyParent].left = cursor;
        } else {
            self.nodes[keyParent].right = cursor;
        }
        self.nodes[cursor].left = key;
        self.nodes[key].parent = cursor;
    }

    function rotateRight(Tree storage self, uint256 key) private {
        uint256 cursor = self.nodes[key].left;
        uint256 keyParent = self.nodes[key].parent;
        uint256 cursorRight = self.nodes[cursor].right;
        self.nodes[key].left = cursorRight;
        if (cursorRight != EMPTY) {
            self.nodes[cursorRight].parent = key;
        }
        self.nodes[cursor].parent = keyParent;
        if (keyParent == EMPTY) {
            self.root = cursor;
        } else if (key == self.nodes[keyParent].right) {
            self.nodes[keyParent].right = cursor;
        } else {
            self.nodes[keyParent].left = cursor;
        }
        self.nodes[cursor].right = key;
        self.nodes[key].parent = cursor;
    }

    function insertFixup(Tree storage self, uint256 key) private {
        uint256 cursor;
        while (key != self.root && self.nodes[self.nodes[key].parent].red) {
            uint256 keyParent = self.nodes[key].parent;
            if (keyParent == self.nodes[self.nodes[keyParent].parent].left) {
                cursor = self.nodes[self.nodes[keyParent].parent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].right) {
                        key = keyParent;
                        rotateLeft(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateRight(self, self.nodes[keyParent].parent);
                }
            } else {
                cursor = self.nodes[self.nodes[keyParent].parent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[keyParent].red = false;
                    self.nodes[cursor].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    key = self.nodes[keyParent].parent;
                } else {
                    if (key == self.nodes[keyParent].left) {
                        key = keyParent;
                        rotateRight(self, key);
                    }
                    keyParent = self.nodes[key].parent;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[keyParent].parent].red = true;
                    rotateLeft(self, self.nodes[keyParent].parent);
                }
            }
        }
        self.nodes[self.root].red = false;
    }

    function replaceParent(Tree storage self, uint256 a, uint256 b) private {
        uint256 bParent = self.nodes[b].parent;
        self.nodes[a].parent = bParent;
        if (bParent == EMPTY) {
            self.root = a;
        } else {
            if (b == self.nodes[bParent].left) {
                self.nodes[bParent].left = a;
            } else {
                self.nodes[bParent].right = a;
            }
        }
    }

    function removeFixup(Tree storage self, uint256 key) private {
        uint256 cursor;
        while (key != self.root && !self.nodes[key].red) {
            uint256 keyParent = self.nodes[key].parent;
            if (key == self.nodes[keyParent].left) {
                cursor = self.nodes[keyParent].right;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateLeft(self, keyParent);
                    cursor = self.nodes[keyParent].right;
                }
                if (!self.nodes[self.nodes[cursor].left].red && !self.nodes[self.nodes[cursor].right].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].right].red) {
                        self.nodes[self.nodes[cursor].left].red = false;
                        self.nodes[cursor].red = true;
                        rotateRight(self, cursor);
                        cursor = self.nodes[keyParent].right;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].right].red = false;
                    rotateLeft(self, keyParent);
                    key = self.root;
                }
            } else {
                cursor = self.nodes[keyParent].left;
                if (self.nodes[cursor].red) {
                    self.nodes[cursor].red = false;
                    self.nodes[keyParent].red = true;
                    rotateRight(self, keyParent);
                    cursor = self.nodes[keyParent].left;
                }
                if (!self.nodes[self.nodes[cursor].right].red && !self.nodes[self.nodes[cursor].left].red) {
                    self.nodes[cursor].red = true;
                    key = keyParent;
                } else {
                    if (!self.nodes[self.nodes[cursor].left].red) {
                        self.nodes[self.nodes[cursor].right].red = false;
                        self.nodes[cursor].red = true;
                        rotateLeft(self, cursor);
                        cursor = self.nodes[keyParent].left;
                    }
                    self.nodes[cursor].red = self.nodes[keyParent].red;
                    self.nodes[keyParent].red = false;
                    self.nodes[self.nodes[cursor].left].red = false;
                    rotateRight(self, keyParent);
                    key = self.root;
                }
            }
        }
        self.nodes[key].red = false;
    }
}
// ----------------------------------------------------------------------------
// End - BokkyPooBah's Red-Black Tree Library
// ----------------------------------------------------------------------------

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @notice Simple implementation of a pull transfer strategy for ERC1155 tokens, where transferring
/// doesn't execute `onERC1155Received`, but the tokens are escrowed in this contract and can be
/// withdrawn by the recipient.
contract ERC1155PullTransfer {
    /// @notice User => tokenId => escrowed token balance
    mapping(address => mapping(uint256 => uint256)) public userTokenEscrow;

    /// @notice Token contract address
    IERC1155 private _tokenContract;

    /// @notice This event is emitted when tokens are deposited into the escrow
    /// @param wallet The address of the user
    /// @param tokenId The ID of the token
    /// @param quantity The quantity of the token
    event ERC1155Deposited(address indexed wallet, uint256 tokenId, uint256 quantity);

    /// @notice This event is emitted when tokens are withdrawn from the escrow
    /// @param wallet The address of the user
    /// @param tokenId The ID of the token
    /// @param quantity The quantity of the token
    event ERC1155Withdrawn(address indexed wallet, uint256 tokenId, uint256 quantity);

    /// @notice Constructor
    /// @param tokenContract The address of the ERC1155 token contract
    constructor(address tokenContract) {
        _tokenContract = IERC1155(tokenContract);
    }

    /// @notice Function to withdraw tokens from this contract. Notice that ANY user can call this function
    /// @param user The address of the user
    /// @param tokenId The ID of the token
    function withdrawTokens(address user, uint256 tokenId) external {
        uint256 balance = userTokenEscrow[user][tokenId];
        require(balance > 0, "No tokens to withdraw");

        // Remove balance from escrow
        userTokenEscrow[user][tokenId] = 0;

        // Transfer token to user
        bytes memory data;
        _tokenContract.safeTransferFrom(address(this), user, tokenId, balance, data);

        emit ERC1155Withdrawn(user, tokenId, balance);
    }

    /// @notice Internal function to transfer tokens from a user to this contract
    /// @param tokenId The ID of the token
    /// @param from The address of the user
    /// @param to The address of the recipient
    /// @param quantity The quantity of the token
    function _asyncTokenTransferFrom(uint256 tokenId, address from, address to, uint256 quantity) internal virtual {
        // First, transfer token into this contract
        bytes memory data;
        _tokenContract.safeTransferFrom(from, address(this), tokenId, quantity, data);

        // Make them available for withdrawal
        userTokenEscrow[to][tokenId] += quantity;

        emit ERC1155Deposited(to, tokenId, quantity);
    }
}