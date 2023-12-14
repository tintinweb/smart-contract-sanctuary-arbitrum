// SPDX-License-Identifier: BUSL-1.1

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

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

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
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC20Metadata} from "./extensions/IERC20Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {IERC20Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 */
abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `value`.
     */
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `value`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `value`.
     */
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    /**
     * @dev Transfers a `value` amount of tokens from `from` to `to`, or alternatively mints (or burns) if `from`
     * (or `to`) is the zero address. All customizations to transfers, mints, and burns should be done by overriding
     * this function.
     *
     * Emits a {Transfer} event.
     */
    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    /**
     * @dev Creates a `value` amount of tokens and assigns them to `account`, by transferring it from address(0).
     * Relies on the `_update` mechanism
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead.
     */
    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }

    /**
     * @dev Destroys a `value` amount of tokens from `account`, lowering the total supply.
     * Relies on the `_update` mechanism.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * NOTE: This function is not virtual, {_update} should be overridden instead
     */
    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    /**
     * @dev Sets `value` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    /**
     * @dev Variant of {_approve} with an optional flag to enable or disable the {Approval} event.
     *
     * By default (when calling {_approve}) the flag is set to true. On the other hand, approval changes made by
     * `_spendAllowance` during the `transferFrom` operation set the flag to false. This saves gas by not emitting any
     * `Approval` event during `transferFrom` operations.
     *
     * Anyone who wishes to continue emitting `Approval` events on the`transferFrom` operation can force the flag to
     * true using the following override:
     * ```
     * function _approve(address owner, address spender, uint256 value, bool) internal virtual override {
     *     super._approve(owner, spender, value, true);
     * }
     * ```
     *
     * Requirements are the same as {_approve}.
     */
    function _approve(address owner, address spender, uint256 value, bool emitEvent) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `value`.
     *
     * Does not update the allowance value in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Does not emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, value);
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
     * - The `operator` cannot be the address zero.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.0;

interface IBridgeAdapter {
    /// @notice Struct with token info for bridge.
    /// @notice `address_` - token address.
    /// @notice `amount` - token amount.
    /// @notice `slippage` - slippage for bridge.
    /// @dev Slippage should be in bps (eg 100% = 1e4)
    struct Token {
        address address_;
        uint256 amount;
        uint256 slippage;
    }

    /// @notice Struct with message info for bridge.
    /// @notice `dstChainId` - evm chain id (check http://chainlist.org/ for reference)
    /// @notice `content` - any info about bridge (eg `abi.encode(chainId, msg.sender)`)
    /// @notice `bridgeParams` - bytes with bridge params, different for each bridge implementation
    struct Message {
        uint256 dstChainId;
        bytes content;
        bytes bridgeParams;
    }

    /// @notice Event emitted when bridge finished on destination chain
    /// @param traceId trace id from `sendTokenWithMessage`
    /// @param token bridged token address
    /// @param amount bridge token amount
    event BridgeFinished(
        bytes32 indexed traceId,
        address token,
        uint256 amount
    );

    /// @notice Reverts, if bridge finished with wrong caller
    error Unauthorized();

    /// @notice Reverts, if chain not supported with this bridge adapter
    /// @param chainId Provided chain id
    error UnsupportedChain(uint256 chainId);

    /// @notice Reverts, if token not supported with this bridge adapter
    /// @param token Provided token address
    error UnsupportedToken(address token);

    /// @notice Send custom token with message to antoher evm chain.
    /// @dev Caller contract should be deployed on same addres on destination chain.
    /// @dev Caller contract should send target token before call.
    /// @dev Caller contract should implement `ITokenWithMessageReceiver`.
    /// @param token Struct with token info.
    /// @param token Struct with token info1.
    /// @param message Struct with message info.
    /// @return traceId Random bytes32 for bridge tracing.
    function sendTokenWithMessage(
        Token calldata token,
        Message calldata message
    ) external payable returns (bytes32 traceId);

    /// @notice Estimate fee in native currency for `sendTokenWithMessage`.
    /// @dev You should provide equal params to `estimateFee` and `sendTokenWithMessage`
    /// @param token Struct with token info.
    /// @param message Struct with message info.
    /// @return fee Fee amount in native currency
    function estimateFee(
        Token calldata token,
        Message calldata message
    ) external view returns (uint256 fee);

    /// @notice Returns block containing bridge finishing transaction.
    /// @param traceId trace id from `sendTokenWithMessage`
    /// @return blockNumber block number in destination chain
    function bridgeFinishedBlock(
        bytes32 traceId
    ) external view returns (uint256 blockNumber);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.0;

interface ITokenWithMessageReceiver {
    /// @notice Receive bridged token with message from `BridgeAdapter`
    /// @dev Implementation should take token from caller (eg `IERC20(token).transferFrom(msg.seder, ..., amount)`)
    /// @param token Bridged token address
    /// @param amount Bridged token amount
    /// @param message Bridged message
    function receiveTokenWithMessage(
        address token,
        uint256 amount,
        bytes calldata message
    ) external;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SharedLiquidity} from "./SharedLiquidity.sol";
import {Logic} from "./Logic.sol";
import {Constants} from "../../libraries/Constants.sol";

abstract contract Execution is SharedLiquidity, Ownable {
    using SafeERC20 for IERC20;

    struct ExecutionConstructorParams {
        address logic;
        address incentiveVault;
        address treasury;
        uint256 fixedFee;
        uint256 performanceFee;
    }

    address public immutable LOGIC;
    address public immutable INCENTIVE_VAULT;
    address public immutable TREASURY;
    uint256 public immutable PERFORMANCE_FEE;
    uint256 public immutable FIXED_FEE;
    bool public killed;

    event Entered(uint256 liquidityDelta);
    event EmergencyExited();

    error EnterFailed();
    error ExitFailed();
    error Killed();
    error NotKilled();

    modifier alive() {
        if (killed) revert Killed();
        _;
    }

    constructor(ExecutionConstructorParams memory params) Ownable(msg.sender) {
        LOGIC = params.logic;
        INCENTIVE_VAULT = params.incentiveVault;
        TREASURY = params.treasury;
        PERFORMANCE_FEE = params.performanceFee;
        FIXED_FEE = params.fixedFee;
    }

    function claimRewards() external {
        _logic(abi.encodeCall(Logic.claimRewards, (INCENTIVE_VAULT)));
    }

    function emergencyExit() external alive onlyOwner {
        _logic(abi.encodeCall(Logic.emergencyExit, ()));

        killed = true;
        emit EmergencyExited();
    }

    function totalLiquidity() public view override returns (uint256) {
        return Logic(LOGIC).accountLiquidity(address(this));
    }

    function _enter(
        uint256 minLiquidityDelta
    ) internal alive returns (uint256 newShares) {
        uint256 liquidityBefore = totalLiquidity();
        _logic(abi.encodeCall(Logic.enter, ()));
        uint256 liquidityAfter = totalLiquidity();
        if (
            liquidityBefore >= liquidityAfter ||
            (liquidityAfter - liquidityBefore) < minLiquidityDelta
        ) {
            revert EnterFailed();
        }
        emit Entered(liquidityAfter - liquidityBefore);

        return _sharesFromLiquidityDelta(liquidityBefore, liquidityAfter);
    }

    function _exit(
        uint256 shares,
        address[] memory tokens,
        uint256[] memory minDeltas
    ) internal alive {
        uint256 n = tokens.length;
        for (uint256 i = 0; i < n; i++) {
            minDeltas[i] += IERC20(tokens[i]).balanceOf(address(this));
        }

        uint256 liquidity = _toLiquidity(shares);
        _logic(abi.encodeCall(Logic.exit, (liquidity)));

        for (uint256 i = 0; i < n; i++) {
            if (IERC20(tokens[i]).balanceOf(address(this)) < minDeltas[i]) {
                revert ExitFailed();
            }
        }
    }

    function _withdrawLiquidity(address recipient, uint256 amount) internal {
        _logic(abi.encodeCall(Logic.withdrawLiquidity, (recipient, amount)));
    }

    function _withdrawAfterEmergencyExit(
        address recipient,
        uint256 shares,
        uint256 totalShares,
        address[] memory tokens
    ) internal {
        if (!killed) revert NotKilled();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(tokens[i]).safeTransfer(
                    recipient,
                    (tokenBalance * shares) / totalShares
                );
            }
        }
    }

    function _logic(bytes memory call) internal returns (bytes memory data) {
        bool success;
        (success, data) = LOGIC.delegatecall(call);

        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }

    function _calculateFixedFeeAmount(
        uint256 shares
    ) internal view returns (uint256 performanceFeeAmount) {
        return (shares * FIXED_FEE) / Constants.BPS;
    }

    function _calculatePerformanceFeeAmount(
        uint256 shares
    ) internal view returns (uint256 performanceFeeAmount) {
        return (shares * PERFORMANCE_FEE) / Constants.BPS;
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Execution} from "./Execution.sol";
import {Logic} from "./Logic.sol";

abstract contract ExecutionSimulation is Execution {
    function simulateExit(
        uint256 shares,
        address[] calldata tokens
    ) external returns (int256[] memory balanceChanges) {
        try this.simulateExitAndRevert(shares, tokens) {} catch (
            bytes memory result
        ) {
            balanceChanges = abi.decode(result, (int256[]));
        }
    }

    function simulateExitAndRevert(
        uint256 shares,
        address[] calldata tokens
    ) external {
        int256[] memory balanceChanges = new int256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balanceChanges[i] = int256(
                IERC20(tokens[i]).balanceOf(address(this))
            );
        }

        _logic(abi.encodeCall(Logic.exit, (_toLiquidity(shares))));

        for (uint256 i = 0; i < tokens.length; i++) {
            balanceChanges[i] =
                int256(IERC20(tokens[i]).balanceOf(address(this))) -
                balanceChanges[i];
        }

        bytes memory returnData = abi.encode(balanceChanges);
        uint256 returnDataLength = returnData.length;

        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }

    function simulateClaimRewards(
        address[] calldata rewardTokens
    ) external returns (int256[] memory balanceChanges) {
        try this.simulateClaimRewardsAndRevert(rewardTokens) {} catch (
            bytes memory result
        ) {
            balanceChanges = abi.decode(result, (int256[]));
        }
    }

    function simulateClaimRewardsAndRevert(
        address[] calldata rewardTokens
    ) external {
        int256[] memory balanceChanges = new int256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            balanceChanges[i] = int256(
                IERC20(rewardTokens[i]).balanceOf(INCENTIVE_VAULT)
            );
        }

        _logic(abi.encodeCall(Logic.claimRewards, (INCENTIVE_VAULT)));

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            balanceChanges[i] =
                int256(IERC20(rewardTokens[i]).balanceOf(INCENTIVE_VAULT)) -
                balanceChanges[i];
        }

        bytes memory returnData = abi.encode(balanceChanges);
        uint256 returnDataLength = returnData.length;
        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

abstract contract Logic {
    error NotImplemented();

    function claimRewards(address recipient) external virtual {
        revert NotImplemented();
    }

    function emergencyExit() external virtual {
        revert NotImplemented();
    }

    function enter() external virtual;

    function exit(uint256 liquidity) external virtual;

    function withdrawLiquidity(
        address recipient,
        uint256 amount
    ) external virtual;

    function accountLiquidity(
        address account
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

/* solhint-disable named-return-values */
abstract contract SharedLiquidity {
    function totalShares() public view virtual returns (uint256);

    function totalLiquidity() public view virtual returns (uint256);

    function _sharesFromLiquidityDelta(
        uint256 liquidityBefore,
        uint256 liquidityAfter
    ) internal view returns (uint256) {
        uint256 totalShares_ = totalShares();
        uint256 liquidityDelta = liquidityAfter - liquidityBefore;
        if (totalShares_ == 0) {
            return liquidityDelta;
        } else {
            return (liquidityDelta * totalShares_) / liquidityBefore;
        }
    }

    function _toLiquidity(uint256 shares) internal view returns (uint256) {
        return (shares * totalLiquidity()) / totalShares();
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FundsHolder is Ownable {
    using SafeERC20 for IERC20;

    constructor() Ownable(msg.sender) {}

    function transferTokenTo(
        address token,
        uint256 amount,
        address to
    ) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "../../interfaces/IVault.sol";
import {IDefii} from "../../interfaces/IDefii.sol";

contract LocalInstructions {
    using SafeERC20 for IERC20;

    address immutable SWAP_ROUTER;

    event Swap(
        address tokenIn,
        address tokenOut,
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut
    );

    error WrongInstructionType(
        IDefii.InstructionType provided,
        IDefii.InstructionType required
    );
    error InstructionFailed();

    constructor(address swapRouter) {
        SWAP_ROUTER = swapRouter;
    }

    function _doSwap(
        IDefii.SwapInstruction memory swapInstruction
    ) internal returns (uint256 amountOut) {
        if (swapInstruction.tokenIn == swapInstruction.tokenOut) {
            return swapInstruction.amountIn;
        }
        amountOut = IERC20(swapInstruction.tokenOut).balanceOf(address(this));
        IERC20(swapInstruction.tokenIn).safeIncreaseAllowance(
            SWAP_ROUTER,
            swapInstruction.amountIn
        );
        (bool success, ) = SWAP_ROUTER.call(swapInstruction.routerCalldata);

        amountOut =
            IERC20(swapInstruction.tokenOut).balanceOf(address(this)) -
            amountOut;

        if (!success || amountOut < swapInstruction.minAmountOut)
            revert InstructionFailed();

        emit Swap(
            swapInstruction.tokenIn,
            swapInstruction.tokenOut,
            SWAP_ROUTER,
            swapInstruction.amountIn,
            amountOut
        );
    }

    function _returnAllFunds(
        address vault,
        uint256 positionId,
        address token
    ) internal {
        _returnFunds(
            vault,
            positionId,
            token,
            IERC20(token).balanceOf(address(this))
        );
    }

    function _returnFunds(
        address vault,
        uint256 positionId,
        address token,
        uint256 amount
    ) internal {
        if (amount > 0) {
            IERC20(token).safeIncreaseAllowance(vault, amount);
            IVault(vault).depositToPosition(positionId, token, amount, 0);
        }
    }

    function _checkInstructionType(
        IDefii.Instruction memory instruction,
        IDefii.InstructionType requiredType
    ) internal pure {
        if (instruction.type_ != requiredType) {
            revert WrongInstructionType(instruction.type_, requiredType);
        }
    }

    /* solhint-disable named-return-values */
    function _decodeSwap(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.SwapInstruction memory) {
        _checkInstructionType(instruction, IDefii.InstructionType.SWAP);
        return abi.decode(instruction.data, (IDefii.SwapInstruction));
    }

    function _decodeMinLiquidityDelta(
        IDefii.Instruction memory instruction
    ) internal pure returns (uint256) {
        _checkInstructionType(
            instruction,
            IDefii.InstructionType.MIN_LIQUIDITY_DELTA
        );
        return abi.decode(instruction.data, (uint256));
    }

    function _decodeMinTokensDelta(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.MinTokensDeltaInstruction memory) {
        _checkInstructionType(
            instruction,
            IDefii.InstructionType.MIN_TOKENS_DELTA
        );
        return abi.decode(instruction.data, (IDefii.MinTokensDeltaInstruction));
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBridgeAdapter} from "@shift-defi/adapters/contracts/bridge/IBridgeAdapter.sol";
import {ITokenWithMessageReceiver} from "@shift-defi/adapters/contracts/bridge/ITokenWithMessageReceiver.sol";

import {IDefii} from "../../interfaces/IDefii.sol";
import {LocalInstructions} from "./LocalInstructions.sol";
import {FundsHolder} from "./FundsHolder.sol";

contract RemoteInstructions is LocalInstructions, ITokenWithMessageReceiver {
    using SafeERC20 for IERC20;

    uint256 public immutable REMOTE_CHAIN_ID;
    FundsHolder public immutable FUNDS_HOLDER;

    mapping(address vault => mapping(uint256 positionId => mapping(address owner => mapping(address token => uint256 balance))))
        public positionBalance;

    event Bridge(
        address token,
        address bridgeAdapter,
        uint256 amount,
        uint256 chainId,
        bytes32 traceId
    );

    constructor(
        address swapRouter_,
        uint256 remoteChainId
    ) LocalInstructions(swapRouter_) {
        REMOTE_CHAIN_ID = remoteChainId;
        FUNDS_HOLDER = new FundsHolder();
    }

    function receiveTokenWithMessage(
        address token,
        uint256 amount,
        bytes calldata message
    ) external {
        (address vault, uint256 positionId, address owner) = abi.decode(
            message,
            (address, uint256, address)
        );

        IERC20(token).safeTransferFrom(
            msg.sender,
            address(FUNDS_HOLDER),
            amount
        );
        positionBalance[vault][positionId][owner][token] += amount;
    }

    function withdrawFunds(
        address vault,
        uint256 positionId,
        address token,
        uint256 amount
    ) external {
        positionBalance[vault][positionId][msg.sender][token] -= amount;
        FUNDS_HOLDER.transferTokenTo(token, amount, msg.sender);
    }

    function _releaseToken(
        address vault,
        uint256 positionId,
        address owner,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            amount = positionBalance[vault][positionId][owner][token];
        }

        if (amount > 0) {
            positionBalance[vault][positionId][owner][token] -= amount;
            FUNDS_HOLDER.transferTokenTo(token, amount, address(this));
        }
    }

    function _holdToken(
        address vault,
        uint256 positionId,
        address owner,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            amount = IERC20(token).balanceOf(address(this));
        }
        if (amount > 0) {
            IERC20(token).safeTransfer(address(FUNDS_HOLDER), amount);
            positionBalance[vault][positionId][owner][token] += amount;
        }
    }

    function _doBridge(
        address vault,
        uint256 positionId,
        address owner,
        IDefii.BridgeInstruction memory bridgeInstruction
    ) internal {
        IERC20(bridgeInstruction.token).safeTransfer(
            bridgeInstruction.bridgeAdapter,
            bridgeInstruction.amount
        );

        bytes32 traceId = IBridgeAdapter(bridgeInstruction.bridgeAdapter)
            .sendTokenWithMessage{value: bridgeInstruction.value}(
            IBridgeAdapter.Token({
                address_: bridgeInstruction.token,
                amount: bridgeInstruction.amount,
                slippage: bridgeInstruction.slippage
            }),
            IBridgeAdapter.Message({
                dstChainId: REMOTE_CHAIN_ID,
                content: abi.encode(vault, positionId, owner),
                bridgeParams: bridgeInstruction.bridgeParams
            })
        );

        emit Bridge(
            bridgeInstruction.token,
            bridgeInstruction.bridgeAdapter,
            bridgeInstruction.amount,
            REMOTE_CHAIN_ID,
            traceId
        );
    }

    function _doSwapBridge(
        address vault,
        uint256 positionId,
        address owner,
        IDefii.SwapBridgeInstruction memory swapBridgeInstruction
    ) internal {
        _doSwap(
            IDefii.SwapInstruction({
                tokenIn: swapBridgeInstruction.tokenIn,
                tokenOut: swapBridgeInstruction.tokenOut,
                amountIn: swapBridgeInstruction.amountIn,
                minAmountOut: swapBridgeInstruction.minAmountOut,
                routerCalldata: swapBridgeInstruction.routerCalldata
            })
        );
        _doBridge(
            vault,
            positionId,
            owner,
            IDefii.BridgeInstruction({
                token: swapBridgeInstruction.tokenOut,
                amount: IERC20(swapBridgeInstruction.tokenOut).balanceOf(
                    address(this)
                ),
                slippage: swapBridgeInstruction.slippage,
                bridgeAdapter: swapBridgeInstruction.bridgeAdapter,
                value: swapBridgeInstruction.value,
                bridgeParams: swapBridgeInstruction.bridgeParams
            })
        );
    }

    /* solhint-disable named-return-values */
    function _decodeBridge(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.BridgeInstruction memory) {
        _checkInstructionType(instruction, IDefii.InstructionType.BRIDGE);
        return abi.decode(instruction.data, (IDefii.BridgeInstruction));
    }

    function _decodeSwapBridge(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.SwapBridgeInstruction memory) {
        _checkInstructionType(instruction, IDefii.InstructionType.SWAP_BRIDGE);
        return abi.decode(instruction.data, (IDefii.SwapBridgeInstruction));
    }

    function _decodeRemoteCall(
        IDefii.Instruction calldata instruction
    ) internal pure returns (bytes calldata) {
        _checkInstructionType(instruction, IDefii.InstructionType.REMOTE_CALL);
        return instruction.data;
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

abstract contract RemoteCalls {
    enum RemoteCallsType {
        LZ
    }

    event RemoteCall(bytes calldata_);

    error RemoteCallFailed();

    modifier remoteFn() {
        if (msg.sender != address(this)) revert RemoteCallFailed();
        _;
    }

    function remoteCallType() external pure virtual returns (RemoteCallsType);

    function _startRemoteCall(
        bytes memory calldata_,
        bytes calldata bridgeParams
    ) internal {
        _remoteCall(calldata_, bridgeParams);
    }

    function _finishRemoteCall(bytes memory calldata_) internal {
        (bool success, ) = address(this).call(calldata_);
        if (!success) revert RemoteCallFailed();
    }

    function _remoteCall(
        bytes memory calldata_,
        bytes calldata bridgeParams
    ) internal virtual;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {RemoteCalls} from "./RemoteCalls.sol";
import {ILayerZeroEndpoint} from "@layerzerolabs/contracts/contracts/interfaces/ILayerZeroEndpoint.sol";
import {ILayerZeroReceiver} from "@layerzerolabs/contracts/contracts/interfaces/ILayerZeroReceiver.sol";

contract RemoteCallsLZ is ILayerZeroReceiver, RemoteCalls {
    // version + value - https://layerzero.gitbook.io/docs/evm-guides/advanced/relayer-adapter-parameters
    uint256 constant MIN_ADAPTER_PARAMS_LENGTH = 34;

    ILayerZeroEndpoint immutable LZ_ENDPOINT;
    uint16 immutable LZ_REMOTE_CHAIN_ID;
    uint256 immutable MIN_DST_GAS;

    error InvalidAdapterParams();

    constructor(address lzEndpoint, uint16 lzRemoteChainId, uint256 minDstGas) {
        LZ_ENDPOINT = ILayerZeroEndpoint(lzEndpoint);
        LZ_REMOTE_CHAIN_ID = lzRemoteChainId;
        MIN_DST_GAS = minDstGas;
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64,
        bytes calldata _payload
    ) external {
        if (
            _srcChainId != LZ_REMOTE_CHAIN_ID ||
            msg.sender != address(LZ_ENDPOINT) ||
            keccak256(_srcAddress) !=
            keccak256(abi.encodePacked(address(this), address(this)))
        ) revert RemoteCallFailed();

        _finishRemoteCall(_payload);
    }

    function quoteLayerZeroFee(
        bytes calldata calldata_,
        bool payInZRO,
        bytes calldata lzAdapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee) {
        (nativeFee, zroFee) = LZ_ENDPOINT.estimateFees({
            _dstChainId: LZ_REMOTE_CHAIN_ID,
            _userApplication: address(this),
            _payload: calldata_,
            _payInZRO: payInZRO,
            _adapterParam: lzAdapterParams
        });
    }

    function remoteCallType() external pure override returns (RemoteCallsType) {
        return RemoteCallsType.LZ;
    }

    function _remoteCall(
        bytes memory calldata_,
        bytes calldata bridgeParams
    ) internal override {
        (address lzPaymentAddress, bytes memory lzAdapterParams) = abi.decode(
            bridgeParams,
            (address, bytes)
        );

        if (lzAdapterParams.length < MIN_ADAPTER_PARAMS_LENGTH) {
            revert InvalidAdapterParams();
        } else {
            uint256 gasLimit;
            assembly {
                gasLimit := mload(
                    add(lzAdapterParams, MIN_ADAPTER_PARAMS_LENGTH)
                )
            }
            if (gasLimit < MIN_DST_GAS) revert InvalidAdapterParams();
        }

        // solhint-disable-next-line check-send-result
        ILayerZeroEndpoint(LZ_ENDPOINT).send{value: msg.value}({
            _dstChainId: LZ_REMOTE_CHAIN_ID,
            _destination: abi.encodePacked(address(this), address(this)),
            _payload: calldata_,
            _refundAddress: payable(tx.origin), // solhint-disable-line avoid-tx-origin
            _zroPaymentAddress: lzPaymentAddress,
            _adapterParams: lzAdapterParams
        });
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IDefii} from "../interfaces/IDefii.sol";
import {IRemoteDefiiAgent} from "../interfaces/IRemoteDefiiAgent.sol";
import {IRemoteDefiiPrincipal} from "../interfaces/IRemoteDefiiPrincipal.sol";
import {OperatorMixin} from "../OperatorMixin.sol";
import {ExecutionSimulation} from "./execution/ExecutionSimulation.sol";
import {Execution} from "./execution/Execution.sol";
import {RemoteInstructions} from "./instructions/RemoteInstructions.sol";
import {RemoteCalls} from "./remote-calls/RemoteCalls.sol";
import {SupportedTokens} from "./supported-tokens/SupportedTokens.sol";

abstract contract RemoteDefiiAgent is
    IRemoteDefiiAgent,
    RemoteInstructions,
    RemoteCalls,
    ExecutionSimulation,
    SupportedTokens,
    OperatorMixin
{
    using SafeERC20 for IERC20;

    uint256 internal _totalShares;

    event RemoteEnter(address indexed vault, uint256 indexed postionId);
    event RemoteExit(address indexed vault, uint256 indexed postionId);

    constructor(
        address swapRouter_,
        address operatorRegistry,
        uint256 remoteChainId_,
        ExecutionConstructorParams memory executionParams
    )
        RemoteInstructions(swapRouter_, remoteChainId_)
        Execution(executionParams)
        OperatorMixin(operatorRegistry)
    {}

    function remoteEnter(
        address vault,
        uint256 positionId,
        address owner,
        IDefii.Instruction[] calldata instructions
    ) external payable operatorCheckApproval(owner) {
        // instructions
        // [SWAP, SWAP, ..., SWAP, MIN_LIQUIDITY_DELTA, REMOTE_CALL]

        address[] memory tokens = supportedTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            _releaseToken(vault, positionId, owner, tokens[i], 0);
        }

        uint256 nInstructions = instructions.length;
        for (uint256 i = 0; i < nInstructions - 2; i++) {
            IDefii.SwapInstruction memory instruction = _decodeSwap(
                instructions[i]
            );
            _checkToken(instruction.tokenOut);
            _doSwap(instruction);
        }

        uint256 shares = _enter(
            _decodeMinLiquidityDelta(instructions[nInstructions - 2])
        );

        uint256 fee = _calculateFixedFeeAmount(shares);
        uint256 userShares = shares - fee;

        _totalShares += shares;
        positionBalance[address(0)][0][owner][address(this)] += fee;
        _startRemoteCall(
            abi.encodeWithSelector(
                IRemoteDefiiPrincipal.mintShares.selector,
                vault,
                positionId,
                userShares
            ),
            _decodeRemoteCall(instructions[nInstructions - 1])
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            _holdToken(vault, positionId, owner, tokens[i], 0);
        }
        emit RemoteEnter(vault, positionId);
    }

    function startRemoteExit(
        address vault,
        uint256 positionId,
        address owner,
        IDefii.Instruction[] calldata instructions
    ) external payable operatorCheckApproval(owner) {
        // instructions
        // [MIN_TOKENS_DELTA, BRIDGE/SWAP_BRIDGE, BRIDGE/SWAP_BRIDGE, ...]

        IDefii.MinTokensDeltaInstruction
            memory minTokensDelta = _decodeMinTokensDelta(instructions[0]);

        uint256 shares = positionBalance[vault][positionId][owner][
            address(this)
        ];

        _exit(shares, minTokensDelta.tokens, minTokensDelta.deltas);
        positionBalance[vault][positionId][owner][address(this)] = 0;
        _totalShares -= shares;

        for (uint256 i = 1; i < instructions.length; i++) {
            if (instructions[i].type_ == IDefii.InstructionType.BRIDGE) {
                IDefii.BridgeInstruction
                    memory bridgeInstruction = _decodeBridge(instructions[i]);
                _checkToken(bridgeInstruction.token);
                _doBridge(vault, positionId, owner, bridgeInstruction);
            } else if (
                instructions[i].type_ == IDefii.InstructionType.SWAP_BRIDGE
            ) {
                IDefii.SwapBridgeInstruction
                    memory swapBridgeInstruction = _decodeSwapBridge(
                        instructions[i]
                    );
                _checkToken(swapBridgeInstruction.tokenOut);
                _doSwapBridge(vault, positionId, owner, swapBridgeInstruction);
            }
        }

        address[] memory tokens = supportedTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            _holdToken(vault, positionId, owner, tokens[i], 0);
        }
        emit RemoteExit(vault, positionId);
    }

    function reinvest(IDefii.Instruction[] calldata instructions) external {
        // instructions
        // [SWAP, SWAP, ..., SWAP, MIN_LIQUIDITY_DELTA]

        uint256 nInstructions = instructions.length;
        for (uint256 i = 0; i < nInstructions - 1; i++) {
            IDefii.SwapInstruction memory instruction = _decodeSwap(
                instructions[i]
            );
            IERC20(instruction.tokenIn).safeTransferFrom(
                msg.sender,
                address(this),
                instruction.amountIn
            );
            _checkToken(instruction.tokenIn);
            _checkToken(instruction.tokenOut);
            _doSwap(instruction);
        }

        uint256 shares = _enter(
            _decodeMinLiquidityDelta(instructions[nInstructions - 1])
        );
        uint256 fee = _calculatePerformanceFeeAmount(shares);

        positionBalance[address(0)][0][TREASURY][address(this)] += shares;
        _totalShares += fee;

        address[] memory tokens = supportedTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(tokens[i]).transfer(msg.sender, tokenBalance);
            }
        }
    }

    function increaseShareBalance(
        address vault,
        uint256 positionId,
        address owner,
        uint256 shares
    ) external remoteFn {
        positionBalance[vault][positionId][owner][address(this)] += shares;
    }

    function withdrawLiquidity(address to, uint256 shares) external remoteFn {
        uint256 liquidity = _toLiquidity(shares);
        _totalShares -= shares;

        _withdrawLiquidity(to, liquidity);
    }

    function withdrawFundsAfterEmergencyExit(
        address vault,
        uint256 positionId,
        address owner
    ) external {
        uint256 shares = positionBalance[vault][positionId][owner][
            address(this)
        ];
        uint256 totalShares_ = totalShares();
        positionBalance[vault][positionId][owner][address(this)] = 0;

        _withdrawAfterEmergencyExit(
            owner,
            shares,
            totalShares_,
            supportedTokens()
        );
    }

    // solhint-disable-next-line named-return-values
    function totalShares() public view override returns (uint256) {
        return _totalShares;
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IDefii} from "../interfaces/IDefii.sol";
import {IVault} from "../interfaces/IVault.sol";
import {IRemoteDefiiAgent} from "../interfaces/IRemoteDefiiAgent.sol";
import {IRemoteDefiiPrincipal} from "../interfaces/IRemoteDefiiPrincipal.sol";
import {OperatorMixin} from "../OperatorMixin.sol";
import {RemoteInstructions} from "./instructions/RemoteInstructions.sol";
import {RemoteCalls} from "./remote-calls/RemoteCalls.sol";
import {SupportedTokens} from "./supported-tokens/SupportedTokens.sol";
import {Notion} from "./supported-tokens/Notion.sol";

abstract contract RemoteDefiiPrincipal is
    IDefii,
    IRemoteDefiiPrincipal,
    RemoteInstructions,
    RemoteCalls,
    SupportedTokens,
    ERC20,
    Notion,
    OperatorMixin
{
    using SafeERC20 for IERC20;

    constructor(
        address swapRouter_,
        address operatorRegistry,
        uint256 remoteChainId_,
        address notion_,
        string memory name
    )
        Notion(notion_)
        OperatorMixin(operatorRegistry)
        RemoteInstructions(swapRouter_, remoteChainId_)
        ERC20(name, "DLP")
    {}

    function enter(
        uint256 amount,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable {
        IERC20(NOTION).safeTransferFrom(msg.sender, address(this), amount);

        address owner = IVault(msg.sender).ownerOf(positionId);
        for (uint256 i = 0; i < instructions.length; i++) {
            if (instructions[i].type_ == InstructionType.BRIDGE) {
                BridgeInstruction memory instruction = _decodeBridge(
                    instructions[i]
                );
                _checkNotion(instruction.token);
                _doBridge(msg.sender, positionId, owner, instruction);
            } else if (instructions[i].type_ == InstructionType.SWAP_BRIDGE) {
                SwapBridgeInstruction memory instruction = _decodeSwapBridge(
                    instructions[i]
                );
                _checkToken(instruction.tokenOut);
                _doSwapBridge(msg.sender, positionId, owner, instruction);
            }
        }

        _returnAllFunds(msg.sender, positionId, NOTION);
    }

    function exit(
        uint256 shares,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable {
        _burn(msg.sender, shares);

        _startRemoteCall(
            abi.encodeWithSelector(
                IRemoteDefiiAgent.increaseShareBalance.selector,
                msg.sender,
                positionId,
                IVault(msg.sender).ownerOf(positionId),
                shares
            ),
            _decodeRemoteCall(instructions[0])
        );
    }

    function mintShares(
        address vault,
        uint256 positionId,
        uint256 shares
    ) external remoteFn {
        _mint(vault, shares);
        IVault(vault).enterCallback(positionId, shares);
    }

    function finishRemoteExit(
        address vault,
        uint256 positionId,
        address owner,
        IDefii.Instruction[] calldata instructions
    ) external payable operatorCheckApproval(owner) {
        // instructions
        // [SWAP, SWAP, ..., SWAP]
        uint256 nInstructions = instructions.length;
        for (uint256 i = 0; i < nInstructions; i++) {
            IDefii.SwapInstruction memory instruction = _decodeSwap(
                instructions[i]
            );
            _checkToken(instruction.tokenIn);
            _checkNotion(instruction.tokenOut);
            _releaseToken(
                vault,
                positionId,
                owner,
                instruction.tokenIn,
                instruction.amountIn
            );
            _doSwap(instruction);
        }
        _returnAllFunds(vault, positionId, NOTION);
        IVault(vault).exitCallback(positionId);
    }

    function withdrawLiquidity(
        address recipient,
        uint256 shares,
        Instruction[] calldata instructions
    ) external payable {
        _burn(msg.sender, shares);

        _startRemoteCall(
            abi.encodeWithSelector(
                IRemoteDefiiAgent.withdrawLiquidity.selector,
                recipient,
                shares
            ),
            _decodeRemoteCall(instructions[0])
        );
    }

    // solhint-disable-next-line named-return-values
    function notion() external view returns (address) {
        return NOTION;
    }

    /// @inheritdoc IDefii
    // solhint-disable-next-line named-return-values
    function defiiType() external pure returns (Type) {
        return Type.REMOTE;
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

contract Notion {
    address immutable NOTION;

    error NotANotion(address token);

    constructor(address notion) {
        NOTION = notion;
    }

    function _checkNotion(address token) internal view {
        if (token != NOTION) {
            revert NotANotion(token);
        }
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {SupportedTokens} from "./SupportedTokens.sol";

contract Supported2Tokens is SupportedTokens {
    address private immutable T0;
    address private immutable T1;

    constructor(address t0, address t1) {
        T0 = t0;
        T1 = t1;
    }

    function supportedTokens()
        public
        view
        override
        returns (address[] memory t)
    {
        t = new address[](2);
        t[0] = T0;
        t[1] = T1;
    }

    function _isTokenSupported(
        address token
    ) internal view override returns (bool isSupported) {
        return token == T0 || token == T1;
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {SupportedTokens} from "./SupportedTokens.sol";

contract Supported3Tokens is SupportedTokens {
    address private immutable T0;
    address private immutable T1;
    address private immutable T2;

    constructor(address t0, address t1, address t2) {
        T0 = t0;
        T1 = t1;
        T2 = t2;
    }

    function supportedTokens()
        public
        view
        override
        returns (address[] memory t)
    {
        t = new address[](3);
        t[0] = T0;
        t[1] = T1;
        t[2] = T2;
    }

    function _isTokenSupported(
        address token
    ) internal view override returns (bool isSupported) {
        return token == T0 || token == T1 || token == T2;
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

abstract contract SupportedTokens {
    error TokenNotSupported(address token);

    function supportedTokens() public view virtual returns (address[] memory t);

    function _checkToken(address token) internal view {
        if (!_isTokenSupported(token)) {
            revert TokenNotSupported(token);
        }
    }

    function _isTokenSupported(
        address
    ) internal view virtual returns (bool isSupported);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDefii is IERC20 {
    /// @notice Instruction type
    /// @dev SWAP_BRIDGE is combination of SWAP + BRIDGE instructions.
    /// @dev Data for MIN_LIQUIDITY_DELTA type is just `uint256`
    enum InstructionType {
        SWAP,
        BRIDGE,
        SWAP_BRIDGE,
        REMOTE_CALL,
        MIN_LIQUIDITY_DELTA,
        MIN_TOKENS_DELTA
    }

    /// @notice DEFII type
    enum Type {
        LOCAL,
        REMOTE
    }

    /// @notice DEFII instruction
    struct Instruction {
        InstructionType type_;
        bytes data;
    }

    /// @notice Swap instruction
    /// @dev `routerCalldata` - 1inch router calldata from API
    struct SwapInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
    }

    /// @notice Bridge instruction
    /// @dev `slippage` should be in bps
    struct BridgeInstruction {
        address token;
        uint256 amount;
        uint256 slippage;
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
    }

    /// @notice Swap and bridge instruction. Do swap and bridge all token from swap
    /// @dev `routerCalldata` - 1inch router calldata from API
    /// @dev `slippage` should be in bps
    struct SwapBridgeInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
        uint256 slippage;
    }

    struct MinTokensDeltaInstruction {
        address[] tokens;
        uint256[] deltas;
    }

    /// @notice Enters DEFII with predefined logic
    /// @param amount Notion amount for enter
    /// @param positionId Position id (used in callback)
    /// @param instructions List with instructions for enter
    /// @dev Caller should implement `IVault` interface
    function enter(
        uint256 amount,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice Exits from DEFII with predefined logic
    /// @param shares Defii lp amount to burn
    /// @param positionId Position id (used in callback)
    /// @param instructions List with instructions for enter
    /// @dev Caller should implement `IVault` interface
    function exit(
        uint256 shares,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice Withdraw liquidity (eg lp tokens) from
    /// @param shares Defii lp amount to burn
    /// @param recipient Address for withdrawal
    /// @param instructions List with instructions
    /// @dev Caller should implement `IVault` interface
    function withdrawLiquidity(
        address recipient,
        uint256 shares,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice DEFII notion (start token)
    /// @return notion address
    // solhint-disable-next-line named-return-values
    function notion() external view returns (address);

    /// @notice DEFII type
    /// @return type Type
    // solhint-disable-next-line named-return-values
    function defiiType() external pure returns (Type);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

interface IOperatorRegistry {
    function isOperatorApprovedForAddress(
        address user,
        address operator,
        address forAddress
    ) external view returns (bool isApproved);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

interface IRemoteDefiiAgent {
    function increaseShareBalance(
        address vault,
        uint256 positionId,
        address owner,
        uint256 shares
    ) external;

    function withdrawLiquidity(address to, uint256 shares) external;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

interface IRemoteDefiiPrincipal {
    function mintShares(
        address vault,
        uint256 positionId,
        uint256 shares
    ) external;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IDefii} from "./IDefii.sol";
import {Status} from "../libraries/StatusLogic.sol";

interface IVault is IERC721Enumerable {
    /// @notice Event emitted when vault balance has changed
    /// @param positionId Position id
    /// @param token token address
    /// @param amount token amount
    /// @param increased True if balance increased, False if balance decreased
    /// @dev You can get current balance via `funds(token, positionId)`
    event BalanceChanged(
        uint256 indexed positionId,
        address indexed token,
        uint256 amount,
        bool increased
    );

    /// @notice Event emitted when defii status changed
    /// @param positionId Position id
    /// @param defii Defii address
    /// @param newStatus New status
    event DefiiStatusChanged(
        uint256 indexed positionId,
        address indexed defii,
        Status indexed newStatus
    );

    /// @notice Reverts, for example, if you try twice run enterDefii before processing ended
    /// @param currentStatus - Current defii status
    /// @param wantStatus - Want defii status
    /// @param positionStatus - Position status
    error CantChangeDefiiStatus(
        Status currentStatus,
        Status wantStatus,
        Status positionStatus
    );

    /// @notice Reverts if trying to decrease more balance than there is
    error InsufficientBalance(
        uint256 positionId,
        address token,
        uint256 balance,
        uint256 needed
    );

    /// @notice Reverts if trying to exit with 0% or > 100%
    error WrongExitPercentage(uint256 percentage);

    /// @notice Reverts if position processing in case we can't
    error PositionProcessing();

    /// @notice Reverts if trying use unknown defii
    error UnsupportedDefii(address defii);

    /// @notice Deposits token to vault. If caller don't have position, opens it
    /// @param token Token address.
    /// @param amount Token amount.
    /// @param operatorFeeAmount Fee for operator (offchain service help)
    /// @dev You need to get `operatorFeeAmount` from API or set it to 0, if you don't need operator
    function deposit(
        address token,
        uint256 amount,
        uint256 operatorFeeAmount
    ) external returns (uint256 positionId);

    /// @notice Deposits token to vault. If caller don't have position, opens it
    /// @param token Token address
    /// @param amount Token amount
    /// @param operatorFeeAmount Fee for operator (offchain service help)
    /// @param deadline Permit deadline
    /// @param permitV The V parameter of ERC712 permit sig
    /// @param permitR The R parameter of ERC712 permit sig
    /// @param permitS The S parameter of ERC712 permit sig
    /// @dev You need to get `operatorFeeAmount` from API or set it to 0, if you don't need operator
    function depositWithPermit(
        address token,
        uint256 amount,
        uint256 operatorFeeAmount,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256 positionId);

    /// @notice Deposits token to vault. If caller don't have position, opens it
    /// @param positionId Position id
    /// @param token Token address
    /// @param amount Token amount
    /// @param operatorFeeAmount Fee for operator (offchain service help)
    /// @dev You need to get `operatorFeeAmount` from API or set it to 0, if you don't need operator
    function depositToPosition(
        uint256 positionId,
        address token,
        uint256 amount,
        uint256 operatorFeeAmount
    ) external;

    /// @notice Withdraws token from vault
    /// @param token Token address
    /// @param amount Token amount
    /// @param positionId Position id
    /// @dev Validates, that position not processing, if `token` is `NOTION`
    function withdraw(
        address token,
        uint256 amount,
        uint256 positionId
    ) external;

    /// @notice Enters the defii
    /// @param defii Defii address
    /// @param positionId Position id
    /// @param instructions List with encoded instructions for DEFII
    function enterDefii(
        address defii,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable;

    /// @notice Callback for DEFII
    /// @param positionId Position id
    /// @param shares Minted shares amount
    /// @dev DEFII should call it after enter
    function enterCallback(uint256 positionId, uint256 shares) external;

    /// @notice Exits from defii
    /// @param defii Defii address
    /// @param positionId Position id
    /// @param instructions List with encoded instructions for DEFII
    function exitDefii(
        address defii,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable;

    /// @notice Callback for DEFII
    /// @param positionId Position id
    /// @dev DEFII should call it after exit
    function exitCallback(uint256 positionId) external;

    function NOTION() external returns (address);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

library Constants {
    uint256 constant BPS = 1e4;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IVault} from "../interfaces/IVault.sol";

uint256 constant MASK_SIZE = 2;
uint256 constant ONES_MASK = (1 << MASK_SIZE) - 1;
uint256 constant MAX_DEFII_AMOUNT = 256 / MASK_SIZE - 1;

enum Status {
    NOT_PROCESSING,
    ENTERING,
    EXITING,
    PROCESSED
}

type Statuses is uint256;
using StatusLogic for Statuses global;

library StatusLogic {
    /*
    Library for gas efficient status updates.

    We have more than 2 statuses, so, we can't use simple bitmask. To solve
    this problem, we use MASK_SIZE bits for every status.
    */

    function getPositionStatus(
        Statuses statuses
    ) internal pure returns (Status positionStatus) {
        return
            Status(Statuses.unwrap(statuses) >> (MASK_SIZE * MAX_DEFII_AMOUNT));
    }

    function getDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex
    ) internal pure returns (Status defiiStatus) {
        return
            Status(
                (Statuses.unwrap(statuses) >> (MASK_SIZE * defiiIndex)) &
                    ONES_MASK
            );
    }

    // solhint-disable-next-line named-return-values
    function isAllDefiisProcessed(
        Statuses statuses,
        uint256 numDefiis
    ) internal pure returns (bool) {
        // Status.PROCESSED = 3 = 0b11
        // So, if all defiis processed, we have
        // statuses = 0b0100......111111111

        // First we need remove 2 left bits (position status)
        uint256 withoutPosition = Statuses.unwrap(
            statuses.setPositionStatus(Status.NOT_PROCESSING)
        );

        return (withoutPosition + 1) == (2 ** (MASK_SIZE * numDefiis));
    }

    function updateDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex,
        Status newStatus,
        uint256 numDefiis
    ) internal pure returns (Statuses newStatuses) {
        Status positionStatus = statuses.getPositionStatus();

        if (positionStatus == Status.NOT_PROCESSING) {
            // If position not processing:
            // - we can start enter/exit
            // - we need to update position status too
            if (newStatus == Status.ENTERING || newStatus == Status.EXITING) {
                return
                    statuses
                        .setDefiiStatus(defiiIndex, newStatus)
                        .setPositionStatus(newStatus);
            }
        } else {
            Status currentStatus = statuses.getDefiiStatus(defiiIndex);
            // If position entering:
            // - we can start/finish enter
            // - we need to reset position status, if all defiis has processed

            // If position exiting:
            // - we can start/finish exit
            // - we need to reset position status, if all defiis has processed

            // prettier-ignore
            if ((
        positionStatus == Status.ENTERING && currentStatus == Status.NOT_PROCESSING && newStatus == Status.ENTERING)
        || (positionStatus == Status.ENTERING && currentStatus == Status.ENTERING && newStatus == Status.PROCESSED)
        || (positionStatus == Status.EXITING && currentStatus == Status.NOT_PROCESSING && newStatus == Status.EXITING)
        || (positionStatus == Status.EXITING && currentStatus == Status.EXITING && newStatus == Status.PROCESSED)) {
                statuses = statuses.setDefiiStatus(defiiIndex, newStatus);
                if (statuses.isAllDefiisProcessed(numDefiis)) {
                    return Statuses.wrap(0);
                } else {
                    return statuses;
                }
            }
        }

        revert IVault.CantChangeDefiiStatus(
            statuses.getDefiiStatus(defiiIndex),
            newStatus,
            positionStatus
        );
    }

    function setPositionStatus(
        Statuses statuses,
        Status newStatus
    ) internal pure returns (Statuses newStatuses) {
        uint256 offset = MASK_SIZE * MAX_DEFII_AMOUNT;
        uint256 cleanupMask = ~(ONES_MASK << offset);
        uint256 newStatusMask = uint256(newStatus) << offset;
        return
            Statuses.wrap(
                (Statuses.unwrap(statuses) & cleanupMask) | newStatusMask
            );
    }

    function setDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex,
        Status newStatus
    ) internal pure returns (Statuses newStatuses) {
        uint256 offset = MASK_SIZE * defiiIndex;
        uint256 cleanupMask = ~(ONES_MASK << offset);
        uint256 newStatusMask = uint256(newStatus) << offset;
        return
            Statuses.wrap(
                (Statuses.unwrap(statuses) & cleanupMask) | newStatusMask
            );
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IOperatorRegistry} from "./interfaces/IOperatorRegistry.sol";

contract OperatorMixin {
    IOperatorRegistry public immutable OPERATOR_REGISTRY;

    error OperatorNotUnauthorized(address user, address operator);

    modifier operatorCheckApproval(address user) {
        _operatorCheckApproval(user);
        _;
    }

    constructor(address operatorRegistry) {
        OPERATOR_REGISTRY = IOperatorRegistry(operatorRegistry);
    }

    function _operatorCheckApproval(address user) internal view {
        if (
            user != msg.sender &&
            !OPERATOR_REGISTRY.isOperatorApprovedForAddress(
                user,
                msg.sender,
                address(this)
            )
        ) {
            revert OperatorNotUnauthorized(user, msg.sender);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {RemoteDefiiPrincipal} from "@shift-defi/core/contracts/defii/RemoteDefiiPrincipal.sol";
import {RemoteDefiiAgent} from "@shift-defi/core/contracts/defii/RemoteDefiiAgent.sol";
import {Supported2Tokens} from "@shift-defi/core/contracts/defii/supported-tokens/Supported2Tokens.sol";
import {Supported3Tokens} from "@shift-defi/core/contracts/defii/supported-tokens/Supported3Tokens.sol";

import {RemoteCallsLZ} from "@shift-defi/core/contracts/defii/remote-calls/RemoteCallsLZ.sol";

import "../constants/base.sol" as Base;
import "../constants/arbitrumOne.sol" as ArbitrumOne;
import "../constants/common.sol" as common;

contract Principal is RemoteDefiiPrincipal, Supported2Tokens, RemoteCallsLZ {
    constructor()
        RemoteDefiiPrincipal(
            common.ONEINCH_ROUTER,
            common.OPERATOR_REGISTRY,
            Base.CHAIN_ID,
            ArbitrumOne.USDC,
            "[USD] Moonwell Base Leveraged DAI"
        )
        Supported2Tokens(ArbitrumOne.USDCe, ArbitrumOne.DAI)
        RemoteCallsLZ(ArbitrumOne.LZ_ENDPOINT, Base.LZ_ID, common.LZ_GAS)
    {}
}

contract Agent is RemoteDefiiAgent, RemoteCallsLZ, Supported3Tokens {
    constructor()
        RemoteDefiiAgent(
            common.ONEINCH_ROUTER,
            common.OPERATOR_REGISTRY,
            ArbitrumOne.CHAIN_ID,
            ExecutionConstructorParams({
                logic: 0x9864D8C3D8c1782393f83D8c0C83aB51d45aDe12,
                incentiveVault: msg.sender,
                treasury: msg.sender,
                fixedFee: 5, // 0.05%
                performanceFee: 1000 // 10%
            })
        )
        Supported3Tokens(Base.DAI, Base.USDbC, Base.USDC)
        RemoteCallsLZ(ArbitrumOne.LZ_ENDPOINT, Base.LZ_ID, common.LZ_GAS)
    {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

uint256 constant CHAIN_ID = 42161;

address constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant USDCe = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
address constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

address constant LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
uint16 constant LZ_ID = 110;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

uint256 constant CHAIN_ID = 8453;

address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
address constant USDbC = 0xd9aAEc86B65D86f6A7B5B1b0c42FFA531710b6CA;
address constant DAI = 0x50c5725949A6F0c72E6C4a641F24049A917DB0Cb;

address constant LZ_ENDPOINT = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;
uint16 constant LZ_ID = 184;

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

address constant ONEINCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
address constant OPERATOR_REGISTRY = 0x0F1a301192734dBcB660608d82954505521056D8;

uint256 constant LZ_GAS = 123;