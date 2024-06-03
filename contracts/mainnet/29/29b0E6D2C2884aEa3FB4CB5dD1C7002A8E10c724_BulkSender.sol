// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` amount of tokens of type `id` are transferred from `from` to `to` by `operator`.
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
     * @dev Returns the value of tokens of token type `id` owned by `account`.
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
     * @dev Transfers a `value` amount of tokens of type `id` from `from` to `to`.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155Received} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `value` amount.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * WARNING: This function can potentially allow a reentrancy attack when transferring tokens
     * to an untrusted contract, when invoking {onERC1155BatchReceived} on the receiver.
     * Ensure to follow the checks-effects-interactions pattern and consider employing
     * reentrancy guards when interacting with untrusted contracts.
     *
     * Emits either a {TransferSingle} or a {TransferBatch} event, depending on the length of the array arguments.
     *
     * Requirements:
     *
     * - `ids` and `values` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BulkSender
 * @dev A contract for sending ERC20 / ERC1155 (id = 0) tokens to multiple addresses in a single transaction.
 * @notice With 30M block gas limit, the max number of recipient count was 4200 for ERC1155 / 5500 for ERC20
 */
contract BulkSender is Ownable {
    error BulkSender__InvalidParams(string param);
    error BulkSender__InsufficientTokenBalance();
    error BulkSender__InsufficientTokenAllowance();
    error BulkSender__InvalidFeeSent();
    error BulkSender__FeeTransactionFailed();

    address public protocolBeneficiary;
    uint256 public feePerRecipient;

    event Sent(address token, uint256 totalAmount, uint256 recipientsCount);
    event ProtocolBeneficiaryUpdated(address protocolBeneficiary);
    event FeeUpdated(uint256 feePerRecipient);

    constructor(
        address protocolBeneficiary_,
        uint256 feePerRecipient_
    ) Ownable(_msgSender()) {
        protocolBeneficiary = protocolBeneficiary_;
        feePerRecipient = feePerRecipient_;
    }

    // MARK: - Admin functions

    /**
     * @dev Updates the protocol beneficiary address.
     * @param protocolBeneficiary_ The new address of the protocol beneficiary.
     */
    function updateProtocolBeneficiary(
        address protocolBeneficiary_
    ) external onlyOwner {
        if (protocolBeneficiary_ == address(0))
            revert BulkSender__InvalidParams("NULL_ADDRESS");

        protocolBeneficiary = protocolBeneficiary_;

        emit ProtocolBeneficiaryUpdated(protocolBeneficiary_);
    }

    /**
     * @dev Updates the fee per recipient.
     * @param feePerRecipient_ The new fee per recipient.
     */
    function updateFeePerRecipient(
        uint256 feePerRecipient_
    ) external onlyOwner {
        feePerRecipient = feePerRecipient_;

        emit FeeUpdated(feePerRecipient_);
    }

    // MARK: - Send functions

    function _validateParams(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) private pure returns (uint256 totalAmount) {
        uint256 length = recipients.length;

        if (length == 0) revert BulkSender__InvalidParams("EMPTY_ARRAY");
        if (length != amounts.length)
            revert BulkSender__InvalidParams("ARRAYS_LENGTH_DO_NOT_MATCH");

        unchecked {
            for (uint256 i = 0; i < length; i++) {
                totalAmount += amounts[i];
            }
        }
        if (totalAmount == 0) revert BulkSender__InvalidParams("ZERO_AMOUNT");
    }

    function _validateFees(
        uint256 recipientsCount
    ) private view returns (uint256 totalFee) {
        totalFee = feePerRecipient * recipientsCount;
        if (msg.value != totalFee) revert BulkSender__InvalidFeeSent();
    }

    function _collectFee(uint256 totalFee) private {
        if (totalFee > 0) {
            (bool success, ) = payable(protocolBeneficiary).call{
                value: totalFee
            }("");
            if (!success) revert BulkSender__FeeTransactionFailed();
        }
    }

    /**
     * @dev Sends ERC20 tokens to multiple addresses.
     * @param token The address of the ERC20 token.
     * @param recipients The addresses of the recipients.
     * @param amounts The amounts of tokens to send to each recipient.
     */
    function sendERC20(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        uint256 totalAmount = _validateParams(recipients, amounts);
        uint256 recipientsCount = recipients.length;
        uint256 totalFee = _validateFees(recipientsCount);

        if (totalAmount > IERC20(token).balanceOf(_msgSender()))
            revert BulkSender__InsufficientTokenBalance();
        if (totalAmount > IERC20(token).allowance(_msgSender(), address(this)))
            revert BulkSender__InsufficientTokenAllowance();

        // Send tokens to recipients
        unchecked {
            address msgSender = _msgSender(); // cache

            for (uint256 i = 0; i < recipientsCount; ++i) {
                IERC20(token).transferFrom(
                    msgSender,
                    recipients[i],
                    amounts[i]
                );
            }
        } // gas optimization

        emit Sent(token, totalAmount, recipientsCount);

        _collectFee(totalFee);
    }

    /**
     * @dev Sends ERC1155 tokens (only id = 0) to multiple addresses.
     * @param token The address of the ERC1155 token.
     * @param recipients The addresses of the recipients.
     * @param amounts The amounts of tokens to send to each recipient.
     */
    function sendERC1155(
        address token,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external payable {
        uint256 totalAmount = _validateParams(recipients, amounts);
        uint256 recipientsCount = recipients.length;
        uint256 totalFee = _validateFees(recipientsCount);

        if (totalAmount > IERC1155(token).balanceOf(_msgSender(), 0))
            revert BulkSender__InsufficientTokenBalance();
        if (!IERC1155(token).isApprovedForAll(_msgSender(), address(this)))
            revert BulkSender__InsufficientTokenAllowance();

        // Send tokens to recipients
        unchecked {
            address msgSender = _msgSender(); // cache

            for (uint256 i = 0; i < recipientsCount; ++i) {
                IERC1155(token).safeTransferFrom(
                    msgSender,
                    recipients[i],
                    0,
                    amounts[i],
                    ""
                );
            }
        } // gas optimization

        emit Sent(token, totalAmount, recipientsCount);

        _collectFee(totalFee);
    }
}