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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
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
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroUserApplicationConfig.sol";
import "./LayerZeroStorage.sol";
import "../zksync/ReentrancyGuard.sol";

/// @title LayerZero bridge implementation of non-blocking model
/// @dev if message is blocking we should call `retryPayload` of endpoint to retry
/// the reasons for message blocking may be:
/// * `_dstAddress` is not deployed to dst chain, and we can deploy LayerZeroBridge to dst chain to fix it.
/// * lzReceive cost more gas than `_gasLimit` that endpoint send, and user should call `retryMessage` to fix it.
/// * lzReceive reverted unexpected, and we can fix bug and deploy a new contract to fix it.
/// @author zk.link
contract LayerZeroBridge is ReentrancyGuard, LayerZeroStorage, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {

    // to avoid stack too deep
    struct LzBridgeParams {
        uint16 dstChainId; // the destination chainId
        address payable refundAddress; // native fees refund address if msg.value is too large
        address zroPaymentAddress; // if not zero user will use ZRO token to pay layerzero protocol fees(not oracle or relayer fees)
        bytes adapterParams; // see https://layerzero.gitbook.io/docs/guides/advanced/relayer-adapter-parameters
    }

    modifier onlyEndpoint {
        require(msg.sender == address(endpoint), "Require endpoint");
        _;
    }

    modifier onlyGovernor {
        require(msg.sender == zklink.networkGovernor(), "Caller is not governor");
        _;
    }

    receive() external payable {
        // receive the refund eth from layerzero endpoint when send msg
    }

    /// @param _zklink The zklink contract address
    /// @param _endpoint The LayerZero endpoint
    constructor(IZkLink _zklink, ILayerZeroEndpoint _endpoint) {
        initializeReentrancyGuard();

        zklink = _zklink;
        endpoint = _endpoint;
    }

    //---------------------------UserApplication config----------------------------------------
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyGovernor {
        endpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyGovernor {
        endpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyGovernor {
        endpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyGovernor {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    /// @notice Set bridge destination
    /// @param dstChainId LayerZero chain id on other chains
    /// @param contractAddr LayerZeroBridge contract address on other chains
    function setDestination(uint16 dstChainId, bytes calldata contractAddr) external onlyGovernor {
        require(dstChainId != endpoint.getChainId(), "Invalid dstChainId");
        destinations[dstChainId] = contractAddr;
        emit UpdateDestination(dstChainId, contractAddr);
    }

    /// @notice Estimate bridge ZkLink Block fees
    /// @param lzChainId the destination chainId
    /// @param syncHash the sync hash of stored block
    /// @param progress the sync progress
    /// @param useZro if true user will use ZRO token to pay layerzero protocol fees(not oracle or relayer fees)
    /// @param adapterParams see https://layerzero.gitbook.io/docs/guides/advanced/relayer-adapter-parameters
    function estimateZkLinkBlockBridgeFees(
        uint16 lzChainId,
        bytes32 syncHash,
        uint256 progress,
        bool useZro,
        bytes calldata adapterParams
    ) external view returns (uint nativeFee, uint zroFee) {
        bytes memory payload = buildZkLinkBlockBridgePayload(syncHash, progress);
        return endpoint.estimateFees(lzChainId, address(this), payload, useZro, adapterParams);
    }

    /// @notice Bridge ZkLink block to other chain
    /// @param storedBlockInfo the block proved but not executed at the current chain
    /// @param dstChainIds dst chains to bridge, empty array will be reverted
    /// @param refundAddress native fees refund address if msg.value is too large
    /// @param zroPaymentAddress if not zero user will use ZRO token to pay layerzero protocol fees(not oracle or relayer fees)
    /// @param adapterParams see https://layerzero.gitbook.io/docs/guides/advanced/relayer-adapter-parameters
    function bridgeZkLinkBlock(
        IZkLink.StoredBlockInfo calldata storedBlockInfo,
        uint16[] memory dstChainIds,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams
    ) external nonReentrant payable {
        // ===Checks===
        require(dstChainIds.length > 0, "No dst chain");

        // ===Interactions===
        bytes32 syncHash = storedBlockInfo.syncHash;
        uint256 progress = zklink.getSynchronizedProgress(storedBlockInfo);

        uint256 originMsgValue = msg.value;
        uint256 originBalance = address(this).balance - originMsgValue; // underflow is impossible
        // before refund, we send all balance of this contract and set refund address to this contract
        for (uint i = 0; i < dstChainIds.length; ++i) { // overflow is impossible
            _bridgeZkLinkBlockProgress(syncHash, progress, dstChainIds[i], payable(address(this)), zroPaymentAddress, adapterParams, address(this).balance);
        }
        // left value should be greater equal than originBalance and refund left value to `refundAddress`
        require(address(this).balance >= originBalance, "Msg value is not enough for bridge");
        uint256 leftMsgValue = address(this).balance - originBalance;  // underflow is impossible
        if (leftMsgValue > 0) {
            // solhint-disable-next-line  avoid-low-level-calls
            (bool success, ) = refundAddress.call{value: leftMsgValue}("");
            require(success, "Refund failed");
        }
        // log the fee payed to layerzero
        emit SynchronizationFee(originMsgValue - leftMsgValue);
    }

    function _bridgeZkLinkBlockProgress(
        bytes32 syncHash,
        uint256 progress,
        uint16 dstChainId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes memory adapterParams,
        uint256 bridgeFee
    ) internal {
        // ===Checks===
        bytes memory trustedRemote = checkDstChainId(dstChainId);

        // endpoint will check `refundAddress`, `zroPaymentAddress` and `adapterParams`

        // ===Effects===
        uint64 nonce = endpoint.getOutboundNonce(dstChainId, address(this));
        emit SendSynchronizationProgress(dstChainId, nonce + 1, syncHash, progress);

        // ===Interactions===
        // send LayerZero message
        bytes memory path = abi.encodePacked(trustedRemote, address(this));
        bytes memory payload = buildZkLinkBlockBridgePayload(syncHash, progress);
        // solhint-disable-next-line check-send-result
        endpoint.send{value:bridgeFee}(dstChainId, path, payload, refundAddress, zroPaymentAddress, adapterParams);
    }

    /// @notice Receive the bytes payload from the source chain via LayerZero
    /// @dev lzReceive can only be called by endpoint
    /// @dev srcPath(in UltraLightNodeV2) = abi.encodePacked(srcAddress, dstAddress);
    function lzReceive(uint16 srcChainId, bytes calldata srcPath, uint64 nonce, bytes calldata payload) external override onlyEndpoint nonReentrant {
        // reject invalid src contract address
        bytes memory srcAddress = destinations[srcChainId];
        bytes memory path = abi.encodePacked(srcAddress, address(this));
        require(keccak256(path) == keccak256(srcPath), "Invalid src");

        // try-catch all errors/exceptions
        // solhint-disable-next-line no-empty-blocks
        try this.nonblockingLzReceive(srcChainId, srcAddress, nonce, payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[srcChainId][srcAddress][nonce] = keccak256(payload);
            emit MessageFailed(srcChainId, srcAddress, nonce, payload);
        }
    }

    function nonblockingLzReceive(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) public {
        // only internal transaction
        require(msg.sender == address(this), "Caller must be this bridge");
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    /// @notice Retry the failed message, payload hash must be exist
    function retryMessage(uint16 srcChainId, bytes calldata srcAddress, uint64 nonce, bytes calldata payload) external payable virtual nonReentrant {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[srcChainId][srcAddress][nonce];
        require(payloadHash != bytes32(0), "No stored message");
        require(keccak256(payload) == payloadHash, "Invalid payload");
        // clear the stored message
        failedMessages[srcChainId][srcAddress][nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(srcChainId, srcAddress, nonce, payload);
    }

    function _nonblockingLzReceive(uint16 srcChainId, bytes calldata /**srcAddress**/, uint64 nonce, bytes calldata payload) internal {
        // unpack payload
        (bytes32 syncHash, uint256 progress) = abi.decode(payload, (bytes32, uint256));
        emit ReceiveSynchronizationProgress(srcChainId, nonce, syncHash, progress);
        zklink.receiveSynchronizationProgress(syncHash, progress);
    }

    function checkDstChainId(uint16 dstChainId) internal view returns (bytes memory trustedRemote) {
        trustedRemote = destinations[dstChainId];
        require(trustedRemote.length > 0, "Trust remote not exist");
    }

    function buildZkLinkBlockBridgePayload(bytes32 syncHash, uint256 progress) internal pure returns (bytes memory payload) {
        payload = abi.encode(syncHash, progress);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "./ILayerZeroEndpoint.sol";
import "../interfaces/IZkLink.sol";

/// @title LayerZero bridge storage
/// @author zk.link
/// @dev Do not initialize any variables of this contract
/// Do not break the alignment of contract storage
contract LayerZeroStorage {
    /// @notice zklink contract address
    IZkLink public zklink;
    /// @notice LayerZero endpoint that used to send and receive message
    ILayerZeroEndpoint public endpoint;
    /// @notice bridge contract address on other chains
    mapping(uint16 => bytes) public destinations;
    /// @notice failed message of lz non-blocking model
    /// @dev the struct of failedMessages is (srcChainId => srcAddress => nonce => payloadHash)
    /// srcChainId is the id of message source chain
    /// srcAddress is the trust remote address on the source chain who send message
    /// nonce is inbound message nonce
    /// payLoadHash is the keccak256 of message payload
    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event UpdateDestination(uint16 indexed lzChainId, bytes destination);
    event MessageFailed(uint16 indexed srcChainId, bytes srcAddress, uint64 nonce, bytes payload);
    event SendSynchronizationProgress(uint16 indexed dstChainId, uint64 nonce, bytes32 syncHash, uint progress);
    event ReceiveSynchronizationProgress(uint16 indexed srcChainId, uint64 nonce, bytes32 syncHash, uint progress);
    event SynchronizationFee(uint256 fee);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./zksync/Proxy.sol";
import "./zksync/UpgradeGatekeeper.sol";
import "./ZkLink.sol";
import "./ZkLinkPeriphery.sol";
import "./interfaces/IVerifier.sol";

/// @title Deploy ZkLink
/// @author zk.link
contract DeployFactory {
    // Why do we deploy contracts in the constructor?
    //
    // If we want to deploy Proxy and UpgradeGatekeeper (using new) we have to deploy their contract code with this contract
    // in total deployment of this contract would cost us around 2.5kk of gas and calling final transaction
    // deployProxyContracts would cost around 3.5kk of gas(which is equivalent but slightly cheaper then doing deploy old way by sending
    // transactions one by one) but doing this in one method gives us simplicity and atomicity of our deployment.
    //
    // If we use selfdesctruction in the constructor then it removes overhead of deploying Proxy and UpgradeGatekeeper
    // with DeployFactory and in total this constructor would cost us around 3.5kk, so we got simplicity and atomicity of
    // deploy without overhead.
    //
    // `_feeAccountAddress` argument is not used by the constructor itself, but it's important to have this
    // information as a part of a transaction, since this transaction can be used for restoring the tree
    // state. By including this address to the list of arguments, we're making ourselves able to restore
    // genesis state, as the very first account in tree is a fee account, and we need its address before
    // we're able to start recovering the data from the Ethereum blockchain.
    constructor(IVerifier _verifierTarget, ZkLink _zkLinkTarget, ZkLinkPeriphery _peripheryTarget, uint32 _blockNumber, uint256 _timestamp, bytes32 _stateHash, bytes32 _commitment, bytes32 _syncHash, address _firstValidator, address _governor, address _feeAccountAddress) {
        require(_firstValidator != address(0), "D0");
        require(_governor != address(0), "D1");
        require(_feeAccountAddress != address(0), "D2");

        Proxy verifier = new Proxy(address(_verifierTarget), abi.encode());
        deployProxyContracts(verifier, _zkLinkTarget, _peripheryTarget,
            _blockNumber, _timestamp, _stateHash, _commitment, _syncHash,
            _firstValidator, _governor);
    }

    event Addresses(Proxy verifier, Proxy zkLink, UpgradeGatekeeper gatekeeper);

    function deployProxyContracts(Proxy verifier, ZkLink _zkLinkTarget, ZkLinkPeriphery _peripheryTarget, uint32 _blockNumber, uint256 _timestamp, bytes32 _stateHash, bytes32 _commitment, bytes32 _syncHash, address _validator, address _governor) internal {
        // set this contract as governor
        Proxy zkLink =
            new Proxy(address(_zkLinkTarget), abi.encode(address(verifier), address(_peripheryTarget), address(this),
                _blockNumber, _timestamp, _stateHash, _commitment, _syncHash));

        UpgradeGatekeeper upgradeGatekeeper = new UpgradeGatekeeper(address(zkLink));

        emit Addresses(verifier, zkLink, upgradeGatekeeper);

        verifier.transferMastership(address(upgradeGatekeeper));
        upgradeGatekeeper.addUpgradeable(address(verifier));

        zkLink.transferMastership(address(upgradeGatekeeper));
        upgradeGatekeeper.addUpgradeable(address(zkLink));

        upgradeGatekeeper.transferMastership(_governor);

        ZkLinkPeriphery peripheryProxy = ZkLinkPeriphery(address(zkLink));
        peripheryProxy.setValidator(_validator, true);
        peripheryProxy.changeGovernor(_governor);
    }
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicense


/// Test representation of "smart wallet" which implements EIP-1271 interface.
contract AccountMock {
    address public owner;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)")
    bytes4 internal constant EIP1271_SUCCESS_RETURN_VALUE = 0x1626ba7e;

    constructor(address _owner) {
        owner = _owner;
    }

    function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
        require(_signature.length == 65, "sign.len incorrect");
        uint8 v;
        bytes32 r;
        bytes32 s;
        // Signature loading code (together with the comment is taken from the Argent smart contract).
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := and(mload(add(_signature, 0x41)), 0xff)
        }
        require(v == 27 || v == 28, "sign.v != 27 || 28");

        address recoveredAddress = ecrecover(_hash, v, r, s);
        require(recoveredAddress != address(0), "ecrecover returned 0");
        require(recoveredAddress == owner, "rec. addr != owner");

        return EIP1271_SUCCESS_RETURN_VALUE;
    }
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: Unlicense


import "./AccountMock.sol";

contract AccountMockDeployer {

    AccountMock public am;

    function deployAccountMock(bytes32 salt, address owner) external {
        am = new AccountMock{salt: salt}(owner);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../zksync/Bytes.sol";

contract BytesTest {
    function read(
        bytes calldata _data,
        uint256 _offset,
        uint256 _len
    ) external pure returns (uint256 new_offset, bytes memory data) {
        return Bytes.read(_data, _offset, _len);
    }

    function testUInt24(bytes calldata buf) external pure returns (uint24 r, uint256 offset) {
        (offset, r) = Bytes.readUInt24(buf, 0);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED



import "../zksync/Upgradeable.sol";
import "../zksync/UpgradeableMaster.sol";

interface DummyTarget {
    function get_DUMMY_INDEX() external pure returns (uint256);

    function initialize(bytes calldata initializationParameters) external;

    function upgrade(bytes calldata upgradeParameters) external;

    function verifyPriorityOperation() external;
}

contract DummyFirst is UpgradeableMaster, DummyTarget {
    uint256 constant UPGRADE_NOTICE_PERIOD = 4;

    function get_UPGRADE_NOTICE_PERIOD() external pure returns (uint256) {
        return UPGRADE_NOTICE_PERIOD;
    }

    function getNoticePeriod() external pure override returns (uint256) {
        return UPGRADE_NOTICE_PERIOD;
    }

    function isReadyForUpgrade() external view override returns (bool) {
        return totalVerifiedPriorityOperations() >= totalRegisteredPriorityOperations();
    }

    uint256 private constant DUMMY_INDEX = 1;

    function get_DUMMY_INDEX() external pure override returns (uint256) {
        return DUMMY_INDEX;
    }

    uint64 _verifiedPriorityOperations;

    function initialize(bytes calldata initializationParameters) external override {
        bytes32 byte_0 = bytes32(uint256(uint8(initializationParameters[0])));
        bytes32 byte_1 = bytes32(uint256(uint8(initializationParameters[1])));
        assembly {
            sstore(1, byte_0)
            sstore(2, byte_1)
        }
    }

    function upgrade(bytes calldata upgradeParameters) external override {}

    function totalVerifiedPriorityOperations() internal view returns (uint64) {
        return _verifiedPriorityOperations;
    }

    function totalRegisteredPriorityOperations() internal pure returns (uint64) {
        return 1;
    }

    function verifyPriorityOperation() external override {
        _verifiedPriorityOperations++;
    }
}

contract DummySecond is UpgradeableMaster, DummyTarget {
    uint256 constant UPGRADE_NOTICE_PERIOD = 4;

    function get_UPGRADE_NOTICE_PERIOD() external pure returns (uint256) {
        return UPGRADE_NOTICE_PERIOD;
    }

    function getNoticePeriod() external pure override returns (uint256) {
        return UPGRADE_NOTICE_PERIOD;
    }

    function isReadyForUpgrade() external view override returns (bool) {
        return totalVerifiedPriorityOperations() >= totalRegisteredPriorityOperations();
    }

    uint256 private constant DUMMY_INDEX = 2;

    function get_DUMMY_INDEX() external pure override returns (uint256) {
        return DUMMY_INDEX;
    }

    uint64 _verifiedPriorityOperations;

    function initialize(bytes calldata) external pure override {
        revert("dsini");
    }

    function upgrade(bytes calldata upgradeParameters) external override {
        bytes32 byte_0 = bytes32(uint256(uint8(upgradeParameters[0])));
        bytes32 byte_1 = bytes32(uint256(uint8(upgradeParameters[1])));
        assembly {
            sstore(2, byte_0)
            sstore(3, byte_1)
        }
    }

    function totalVerifiedPriorityOperations() internal view returns (uint64) {
        return _verifiedPriorityOperations;
    }

    function totalRegisteredPriorityOperations() internal pure returns (uint64) {
        return 0;
    }

    function verifyPriorityOperation() external override {
        _verifiedPriorityOperations++;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FaucetToken is ERC20, Ownable {

    uint8 private _decimals;
    uint8 private _fromTransferFeeRatio;
    uint8 private _toTransferFeeRatio;

    constructor (string memory name,
        string memory symbol,
        uint8 decimals_,
        uint8 fromTransferFeeRatio_,
        uint8 toTransferFeeRatio_) ERC20(name, symbol) {
        _decimals = decimals_;
        _fromTransferFeeRatio = fromTransferFeeRatio_;
        _toTransferFeeRatio = toTransferFeeRatio_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mintTo(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._transfer(from, to, amount);

        if (from != address(0) && _fromTransferFeeRatio > 0) {
            // take fee of from
            _burn(from, amount / _fromTransferFeeRatio);
        }
        if (to != address(0) && _toTransferFeeRatio > 0) {
            // take fee of to
            _burn(to, amount / _toTransferFeeRatio);
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT



import "../bridge/LayerZeroBridge.sol";

/// @title A lz bridge mock
/// @author zk.link
contract LayerZeroBridgeMock is LayerZeroBridge {

    constructor(IZkLink _zklink, ILayerZeroEndpoint _endpoint) LayerZeroBridge(_zklink, _endpoint) {
    }

    function setEndpoint(ILayerZeroEndpoint newEndpoint) external onlyGovernor {
        endpoint = newEndpoint;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: BUSL-1.1



import "../bridge/ILayerZeroReceiver.sol";
import "../bridge/ILayerZeroEndpoint.sol";
import "./LzLib.sol";
import "hardhat/console.sol";

/*
like a real LayerZero endpoint but can be mocked, which handle message transmission, verification, and receipt.
- blocking: LayerZero provides ordered delivery of messages from a given sender to a destination chain.
- non-reentrancy: endpoint has a non-reentrancy guard for both the send() and receive(), respectively.
- adapter parameters: allows UAs to add arbitrary transaction params in the send() function, like airdrop on destination chain.
unlike a real LayerZero endpoint, it is
- no messaging library versioning
- send() will short circuit to lzReceive()
- no user application configuration
*/
contract LZEndpointMock is ILayerZeroEndpoint {
    uint8 internal constant _NOT_ENTERED = 1;
    uint8 internal constant _ENTERED = 2;

    mapping(address => address) public lzEndpointLookup;

    uint16 public mockChainId;
    bool public nextMsgBlocked;

    // fee config
    RelayerFeeConfig public relayerFeeConfig;
    ProtocolFeeConfig public protocolFeeConfig;
    uint public oracleFee;
    bytes public defaultAdapterParams;

    // path = remote addrss + local address
    // inboundNonce = [srcChainId][path].
    mapping(uint16 => mapping(bytes => uint64)) public inboundNonce;
    // outboundNonce = [dstChainId][srcAddress]
    mapping(uint16 => mapping(address => uint64)) public outboundNonce;
    //    // outboundNonce = [dstChainId][path].
    //    mapping(uint16 => mapping(bytes => uint64)) public outboundNonce;
    // storedPayload = [srcChainId][path]
    mapping(uint16 => mapping(bytes => StoredPayload)) public storedPayload;
    // msgToDeliver = [srcChainId][path]
    mapping(uint16 => mapping(bytes => QueuedPayload[])) public msgsToDeliver;

    // reentrancy guard
    uint8 internal _send_entered_state = 1;
    uint8 internal _receive_entered_state = 1;

    struct ProtocolFeeConfig {
        uint zroFee;
        uint nativeBP;
    }

    struct RelayerFeeConfig {
        uint128 dstPriceRatio; // 10^10
        uint128 dstGasPriceInWei;
        uint128 dstNativeAmtCap;
        uint64 baseGas;
        uint64 gasPerByte;
    }

    struct StoredPayload {
        uint64 payloadLength;
        address dstAddress;
        bytes32 payloadHash;
    }

    struct QueuedPayload {
        address dstAddress;
        uint64 nonce;
        bytes payload;
    }

    modifier sendNonReentrant() {
        require(_send_entered_state == _NOT_ENTERED, "LayerZeroMock: no send reentrancy");
        _send_entered_state = _ENTERED;
        _;
        _send_entered_state = _NOT_ENTERED;
    }

    modifier receiveNonReentrant() {
        require(_receive_entered_state == _NOT_ENTERED, "LayerZeroMock: no receive reentrancy");
        _receive_entered_state = _ENTERED;
        _;
        _receive_entered_state = _NOT_ENTERED;
    }

    event UaForceResumeReceive(uint16 chainId, bytes srcAddress);
    event PayloadCleared(uint16 srcChainId, bytes srcAddress, uint64 nonce, address dstAddress);
    event PayloadStored(uint16 srcChainId, bytes srcAddress, address dstAddress, uint64 nonce, bytes payload, bytes reason);
    event ValueTransferFailed(address indexed to, uint indexed quantity);

    constructor(uint16 _chainId) {
        mockChainId = _chainId;

        // init config
        relayerFeeConfig = RelayerFeeConfig({
        dstPriceRatio: 1e10, // 1:1, same chain, same native coin
        dstGasPriceInWei: 1e10,
        dstNativeAmtCap: 1e19,
        baseGas: 100,
        gasPerByte: 1
        });
        protocolFeeConfig = ProtocolFeeConfig({zroFee: 1e18, nativeBP: 1000}); // BP 0.1
        oracleFee = 1e16;
        defaultAdapterParams = LzLib.buildDefaultAdapterParams(200000);
    }

    // ------------------------------ ILayerZeroEndpoint Functions ------------------------------
    function send(uint16 _chainId, bytes memory _path, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParams) external payable override sendNonReentrant {
        require(_path.length == 40, "LayerZeroMock: incorrect remote address size"); // only support evm chains

        address dstAddr;
        assembly {
            dstAddr := mload(add(_path, 20))
        }

        address lzEndpoint = lzEndpointLookup[dstAddr];
        require(lzEndpoint != address(0), "LayerZeroMock: destination LayerZero Endpoint not found");

        // not handle zro token
        bytes memory adapterParams = _adapterParams.length > 0 ? _adapterParams : defaultAdapterParams;
        (uint nativeFee, ) = estimateFees(_chainId, msg.sender, _payload, _zroPaymentAddress != address(0x0), adapterParams);
        require(msg.value >= nativeFee, "LayerZeroMock: not enough native for fees");

        uint64 nonce = ++outboundNonce[_chainId][msg.sender];

        // refund if they send too much
        uint amount = msg.value - nativeFee;
        if (amount > 0) {
            (bool success, ) = _refundAddress.call{value: amount}("");
            require(success, "LayerZeroMock: failed to refund");
        }

        // Mock the process of receiving msg on dst chain
        // Mock the relayer paying the dstNativeAddr the amount of extra native token
        (, uint extraGas, uint dstNativeAmt, address payable dstNativeAddr) = LzLib.decodeAdapterParams(adapterParams);
        if (dstNativeAmt > 0) {
            (bool success, ) = dstNativeAddr.call{value: dstNativeAmt}("");
            if (!success) {
                emit ValueTransferFailed(dstNativeAddr, dstNativeAmt);
            }
        }

        bytes memory srcUaAddress = abi.encodePacked(msg.sender, dstAddr); // cast this address to bytes
        bytes memory payload = _payload;
        LZEndpointMock(lzEndpoint).receivePayload(mockChainId, srcUaAddress, dstAddr, nonce, extraGas, payload);
    }

    function receivePayload(uint16 _srcChainId, bytes calldata _path, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external override receiveNonReentrant {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];

        // assert and increment the nonce. no message shuffling
        require(_nonce == ++inboundNonce[_srcChainId][_path], "LayerZeroMock: wrong nonce");

        // queue the following msgs inside of a stack to simulate a successful send on src, but not fully delivered on dst
        if (sp.payloadHash != bytes32(0)) {
            QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];
            QueuedPayload memory newMsg = QueuedPayload(_dstAddress, _nonce, _payload);

            // warning, might run into gas issues trying to forward through a bunch of queued msgs
            // shift all the msgs over so we can treat this like a fifo via array.pop()
            if (msgs.length > 0) {
                // extend the array
                msgs.push(newMsg);

                // shift all the indexes up for pop()
                for (uint i = 0; i < msgs.length - 1; i++) {
                    msgs[i + 1] = msgs[i];
                }

                // put the newMsg at the bottom of the stack
                msgs[0] = newMsg;
            } else {
                msgs.push(newMsg);
            }
        } else if (nextMsgBlocked) {
            storedPayload[_srcChainId][_path] = StoredPayload(uint64(_payload.length), _dstAddress, keccak256(_payload));
            emit PayloadStored(_srcChainId, _path, _dstAddress, _nonce, _payload, bytes(""));
            // ensure the next msgs that go through are no longer blocked
            nextMsgBlocked = false;
        } else {
            uint gas0 = gasleft();
            try ILayerZeroReceiver(_dstAddress).lzReceive{gas: _gasLimit}(_srcChainId, _path, _nonce, _payload) {} catch (bytes memory reason) {
                storedPayload[_srcChainId][_path] = StoredPayload(uint64(_payload.length), _dstAddress, keccak256(_payload));
                emit PayloadStored(_srcChainId, _path, _dstAddress, _nonce, _payload, reason);
                // ensure the next msgs that go through are no longer blocked
                nextMsgBlocked = false;
            }
            uint gas1 = gasleft();
            console.log(
                "lzReceive gas cost: %s",
                gas0 - gas1
            );
        }
    }

    function getInboundNonce(uint16 _chainID, bytes calldata _path) external view override returns (uint64) {
        return inboundNonce[_chainID][_path];
    }

    function getOutboundNonce(uint16 _chainID, address _srcAddress) external view override returns (uint64) {
        return outboundNonce[_chainID][_srcAddress];
    }

    function estimateFees(uint16 _dstChainId, address _userApplication, bytes memory _payload, bool _payInZRO, bytes memory _adapterParams) public view override returns (uint nativeFee, uint zroFee) {
        bytes memory adapterParams = _adapterParams.length > 0 ? _adapterParams : defaultAdapterParams;

        // Relayer Fee
        uint relayerFee = _getRelayerFee(_dstChainId, 1, _userApplication, _payload.length, adapterParams);

        // LayerZero Fee
        uint protocolFee = _getProtocolFees(_payInZRO, relayerFee, oracleFee);
        _payInZRO ? zroFee = protocolFee : nativeFee = protocolFee;

        // return the sum of fees
        nativeFee = nativeFee + relayerFee + oracleFee;
    }

    function getChainId() external view override returns (uint16) {
        return mockChainId;
    }

    function retryPayload(uint16 _srcChainId, bytes calldata _path, bytes calldata _payload) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        require(sp.payloadHash != bytes32(0), "LayerZeroMock: no stored payload");
        require(_payload.length == sp.payloadLength && keccak256(_payload) == sp.payloadHash, "LayerZeroMock: invalid payload");

        address dstAddress = sp.dstAddress;
        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        uint64 nonce = inboundNonce[_srcChainId][_path];

        ILayerZeroReceiver(dstAddress).lzReceive(_srcChainId, _path, nonce, _payload);
        emit PayloadCleared(_srcChainId, _path, nonce, dstAddress);
    }

    function hasStoredPayload(uint16 _srcChainId, bytes calldata _path) external view override returns (bool) {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        return sp.payloadHash != bytes32(0);
    }

    function getSendLibraryAddress(address) external view override returns (address) {
        return address(this);
    }

    function getReceiveLibraryAddress(address) external view override returns (address) {
        return address(this);
    }

    function isSendingPayload() external view override returns (bool) {
        return _send_entered_state == _ENTERED;
    }

    function isReceivingPayload() external view override returns (bool) {
        return _receive_entered_state == _ENTERED;
    }

    function getConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        address, /*_ua*/
        uint /*_configType*/
    ) external pure override returns (bytes memory) {
        return "";
    }

    function getSendVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function getReceiveVersion(
        address /*_userApplication*/
    ) external pure override returns (uint16) {
        return 1;
    }

    function setConfig(
        uint16, /*_version*/
        uint16, /*_chainId*/
        uint, /*_configType*/
        bytes memory /*_config*/
    ) external override {}

    function setSendVersion(
        uint16 /*version*/
    ) external override {}

    function setReceiveVersion(
        uint16 /*version*/
    ) external override {}

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _path) external override {
        StoredPayload storage sp = storedPayload[_srcChainId][_path];
        // revert if no messages are cached. safeguard malicious UA behaviour
        require(sp.payloadHash != bytes32(0), "LayerZeroMock: no stored payload");
        require(sp.dstAddress == msg.sender, "LayerZeroMock: invalid caller");

        // empty the storedPayload
        sp.payloadLength = 0;
        sp.dstAddress = address(0);
        sp.payloadHash = bytes32(0);

        emit UaForceResumeReceive(_srcChainId, _path);

        // resume the receiving of msgs after we force clear the "stuck" msg
        _clearMsgQue(_srcChainId, _path);
    }

    // ------------------------------ Other Public/External Functions --------------------------------------------------

    function getLengthOfQueue(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint) {
        return msgsToDeliver[_srcChainId][_srcAddress].length;
    }

    // used to simulate messages received get stored as a payload
    function blockNextMsg() external {
        nextMsgBlocked = true;
    }

    function setDestLzEndpoint(address destAddr, address lzEndpointAddr) external {
        lzEndpointLookup[destAddr] = lzEndpointAddr;
    }

    function setRelayerPrice(uint128 _dstPriceRatio, uint128 _dstGasPriceInWei, uint128 _dstNativeAmtCap, uint64 _baseGas, uint64 _gasPerByte) external {
        relayerFeeConfig.dstPriceRatio = _dstPriceRatio;
        relayerFeeConfig.dstGasPriceInWei = _dstGasPriceInWei;
        relayerFeeConfig.dstNativeAmtCap = _dstNativeAmtCap;
        relayerFeeConfig.baseGas = _baseGas;
        relayerFeeConfig.gasPerByte = _gasPerByte;
    }

    function setProtocolFee(uint _zroFee, uint _nativeBP) external {
        protocolFeeConfig.zroFee = _zroFee;
        protocolFeeConfig.nativeBP = _nativeBP;
    }

    function setOracleFee(uint _oracleFee) external {
        oracleFee = _oracleFee;
    }

    function setDefaultAdapterParams(bytes memory _adapterParams) external {
        defaultAdapterParams = _adapterParams;
    }

    // --------------------- Internal Functions ---------------------
    // simulates the relayer pushing through the rest of the msgs that got delayed due to the stored payload
    function _clearMsgQue(uint16 _srcChainId, bytes calldata _path) internal {
        QueuedPayload[] storage msgs = msgsToDeliver[_srcChainId][_path];

        // warning, might run into gas issues trying to forward through a bunch of queued msgs
        while (msgs.length > 0) {
            QueuedPayload memory payload = msgs[msgs.length - 1];
            ILayerZeroReceiver(payload.dstAddress).lzReceive(_srcChainId, _path, payload.nonce, payload.payload);
            msgs.pop();
        }
    }

    function _getProtocolFees(bool _payInZro, uint _relayerFee, uint _oracleFee) internal view returns (uint) {
        if (_payInZro) {
            return protocolFeeConfig.zroFee;
        } else {
            return ((_relayerFee + _oracleFee) * protocolFeeConfig.nativeBP) / 10000;
        }
    }

    function _getRelayerFee(
        uint16, /* _dstChainId */
        uint16, /* _outboundProofType */
        address, /* _userApplication */
        uint _payloadSize,
        bytes memory _adapterParams
    ) internal view returns (uint) {
        (uint16 txType, uint extraGas, uint dstNativeAmt, ) = LzLib.decodeAdapterParams(_adapterParams);
        uint totalRemoteToken; // = baseGas + extraGas + requiredNativeAmount
        if (txType == 2) {
            require(relayerFeeConfig.dstNativeAmtCap >= dstNativeAmt, "LayerZeroMock: dstNativeAmt too large ");
            totalRemoteToken += dstNativeAmt;
        }
        // remoteGasTotal = dstGasPriceInWei * (baseGas + extraGas)
        uint remoteGasTotal = relayerFeeConfig.dstGasPriceInWei * (relayerFeeConfig.baseGas + extraGas);
        totalRemoteToken += remoteGasTotal;

        // tokenConversionRate = dstPrice / localPrice
        // basePrice = totalRemoteToken * tokenConversionRate
        uint basePrice = (totalRemoteToken * relayerFeeConfig.dstPriceRatio) / 10**10;

        // pricePerByte = (dstGasPriceInWei * gasPerBytes) * tokenConversionRate
        uint pricePerByte = (relayerFeeConfig.dstGasPriceInWei * relayerFeeConfig.gasPerByte * relayerFeeConfig.dstPriceRatio) / 10**10;

        return basePrice + _payloadSize * pricePerByte;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: BUSL-1.1



library LzLib {
    // LayerZero communication
    struct CallParams {
        address payable refundAddress;
        address zroPaymentAddress;
    }

    //---------------------------------------------------------------------------
    // Address type handling

    struct AirdropParams {
        uint airdropAmount;
        bytes32 airdropAddress;
    }

    function buildAdapterParams(LzLib.AirdropParams memory _airdropParams, uint _uaGasLimit) internal pure returns (bytes memory adapterParams) {
        if (_airdropParams.airdropAmount == 0 && _airdropParams.airdropAddress == bytes32(0x0)) {
            adapterParams = buildDefaultAdapterParams(_uaGasLimit);
        } else {
            adapterParams = buildAirdropAdapterParams(_uaGasLimit, _airdropParams);
        }
    }

    // Build Adapter Params
    function buildDefaultAdapterParams(uint _uaGas) internal pure returns (bytes memory) {
        // txType 1
        // bytes  [2       32      ]
        // fields [txType  extraGas]
        return abi.encodePacked(uint16(1), _uaGas);
    }

    function buildAirdropAdapterParams(uint _uaGas, AirdropParams memory _params) internal pure returns (bytes memory) {
        require(_params.airdropAmount > 0, "Airdrop amount must be greater than 0");
        require(_params.airdropAddress != bytes32(0x0), "Airdrop address must be set");

        // txType 2
        // bytes  [2       32        32            bytes[]         ]
        // fields [txType  extraGas  dstNativeAmt  dstNativeAddress]
        return abi.encodePacked(uint16(2), _uaGas, _params.airdropAmount, _params.airdropAddress);
    }

    function getGasLimit(bytes memory _adapterParams) internal pure returns (uint gasLimit) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            gasLimit := mload(add(_adapterParams, 34))
        }
    }

    // Decode Adapter Params
    function decodeAdapterParams(bytes memory _adapterParams) internal pure returns (uint16 txType, uint uaGas, uint airdropAmount, address payable airdropAddress) {
        require(_adapterParams.length == 34 || _adapterParams.length > 66, "Invalid adapterParams");
        assembly {
            txType := mload(add(_adapterParams, 2))
            uaGas := mload(add(_adapterParams, 34))
        }
        require(txType == 1 || txType == 2, "Unsupported txType");
        require(uaGas > 0, "Gas too low");

        if (txType == 2) {
            assembly {
                airdropAmount := mload(add(_adapterParams, 66))
                airdropAddress := mload(add(_adapterParams, 86))
            }
        }
    }

    //---------------------------------------------------------------------------
    // Address type handling
    function bytes32ToAddress(bytes32 _bytes32Address) internal pure returns (address _address) {
        return address(uint160(uint(_bytes32Address)));
    }

    function addressToBytes32(address _address) internal pure returns (bytes32 _bytes32Address) {
        return bytes32(uint(uint160(_address)));
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./StandardToken.sol";

contract NonStandardToken is StandardToken {

    constructor (string memory name, string memory symbol) StandardToken(name, symbol) {
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._transfer(from, to, amount);

        if (from != address(0)) {
            // take 10% fee
            _burn(from, amount / 10);
        }
        if (to != address(0)) {
            // take 20% fee
            _burn(to, amount / 5);
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../zksync/Operations.sol";

contract OperationsTest {
    function testDepositPubdata(Operations.Deposit calldata _example, bytes calldata _pubdata) external pure {
        Operations.Deposit memory parsed = Operations.readDepositPubdata(_pubdata);
        require(_example.chainId == parsed.chainId, "cok");
        require(_example.accountId == parsed.accountId, "aok");
        require(_example.subAccountId == parsed.subAccountId, "sok");
        require(_example.tokenId == parsed.tokenId, "tok");
        require(_example.targetTokenId == parsed.targetTokenId, "t1ok");
        require(_example.amount == parsed.amount, "amn");
        require(_example.owner == parsed.owner, "own");
    }

    function testWriteDepositPubdata(Operations.Deposit calldata _example) external pure {
        bytes memory pubdata = Operations.writeDepositPubdataForPriorityQueue(_example);
        Operations.Deposit memory parsed = Operations.readDepositPubdata(pubdata);
        require(0 == parsed.accountId, "acc");
        require(_example.chainId == parsed.chainId, "cok");
        require(_example.subAccountId == parsed.subAccountId, "sok");
        require(_example.tokenId == parsed.tokenId, "tok");
        require(_example.targetTokenId == parsed.targetTokenId, "t1ok");
        require(_example.amount == parsed.amount, "amn");
        require(_example.owner == parsed.owner, "own");
    }

    function testWithdrawPubdata(Operations.Withdraw calldata _example, bytes calldata _pubdata) external pure {
        Operations.Withdraw memory parsed = Operations.readWithdrawPubdata(_pubdata);
        require(_example.chainId == parsed.chainId, "cok");
        require(_example.accountId == parsed.accountId, "aok");
        require(_example.subAccountId == parsed.subAccountId, "saok");
        require(_example.tokenId == parsed.tokenId, "tok");
        require(_example.amount == parsed.amount, "amn");
        require(_example.owner == parsed.owner, "own");
        require(_example.nonce == parsed.nonce, "nonce");
        require(_example.fastWithdrawFeeRate == parsed.fastWithdrawFeeRate, "fr");
        require(_example.fastWithdraw == parsed.fastWithdraw, "fw");
    }

    function testFullExitPubdata(Operations.FullExit calldata _example, bytes calldata _pubdata) external pure {
        Operations.FullExit memory parsed = Operations.readFullExitPubdata(_pubdata);
        require(_example.chainId == parsed.chainId, "cid");
        require(_example.accountId == parsed.accountId, "acc");
        require(_example.subAccountId == parsed.subAccountId, "scc");
        require(_example.owner == parsed.owner, "own");
        require(_example.tokenId == parsed.tokenId, "tok");
        require(_example.amount == parsed.amount, "amn");
    }

    function testWriteFullExitPubdata(Operations.FullExit calldata _example) external pure {
        bytes memory pubdata = Operations.writeFullExitPubdataForPriorityQueue(_example);
        Operations.FullExit memory parsed = Operations.readFullExitPubdata(pubdata);
        require(_example.chainId == parsed.chainId, "cid");
        require(_example.accountId == parsed.accountId, "acc");
        require(_example.subAccountId == parsed.subAccountId, "scc");
        require(_example.tokenId == parsed.tokenId, "tok");
        require(0 == parsed.amount, "amn");
        require(_example.owner == parsed.owner, "own");
    }

    function testForcedExitPubdata(Operations.ForcedExit calldata _example, bytes calldata _pubdata) external pure {
        Operations.ForcedExit memory parsed = Operations.readForcedExitPubdata(_pubdata);
        require(_example.chainId == parsed.chainId, "cid");
        require(_example.initiatorAccountId == parsed.initiatorAccountId, "iaid");
        require(_example.initiatorSubAccountId == parsed.initiatorSubAccountId, "isaid");
        require(_example.initiatorNonce == parsed.initiatorNonce, "in");
        require(_example.targetAccountId == parsed.targetAccountId, "taid");
        require(_example.tokenId == parsed.tokenId, "tcc");
        require(_example.amount == parsed.amount, "amn");
        require(_example.target == parsed.target, "tar");
    }

    function testChangePubkeyPubdata(Operations.ChangePubKey calldata _example, bytes calldata _pubdata) external pure {
        Operations.ChangePubKey memory parsed = Operations.readChangePubKeyPubdata(_pubdata);
        require(_example.accountId == parsed.accountId, "acc");
        require(_example.pubKeyHash == parsed.pubKeyHash, "pkh");
        require(_example.owner == parsed.owner, "own");
        require(_example.nonce == parsed.nonce, "nnc");
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StandardToken is ERC20 {

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {
    }

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }

    function mintTo(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./StandardToken.sol";

contract StandardTokenWithDecimals is StandardToken {

    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals_) StandardToken(name, symbol) {
        _decimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../interfaces/IVerifier.sol";

contract VerifierMock is IVerifier {

    // solhint-disable-next-line no-empty-blocks
    function initialize(bytes calldata) external {}

    /// @notice Verifier contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    // solhint-disable-next-line no-empty-blocks
    function upgrade(bytes calldata upgradeParameters) external {}

    bool public verifyResult = true;

    function setVerifyResult(bool r) external {
        verifyResult = r;
    }

    function verifyAggregatedBlockProof(
        uint256[] memory,
        uint256[] memory,
        uint8[] memory,
        uint256[] memory,
        uint256[16] memory
    ) external override view returns (bool) {
        return verifyResult;
    }

    function verifyExitProof(
        bytes32,
        uint8,
        uint32,
        uint8,
        bytes32,
        uint16,
        uint16,
        uint128,
        uint256[] calldata
    ) external override view returns (bool) {
        return verifyResult;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../ZkLinkPeriphery.sol";

contract ZkLinkPeripheryTest is ZkLinkPeriphery {

    function setGovernor(address governor) external {
        networkGovernor = governor;
    }

    function setAcceptor(uint32 accountId, bytes32 hash, address acceptor) external {
        accepts[accountId][hash] = acceptor;
    }

    function getAcceptor(uint32 accountId, bytes32 hash) external view returns (address) {
        return accepts[accountId][hash];
    }

    function mockProveBlock(StoredBlockInfo memory storedBlockInfo) external {
        storedBlockHashes[storedBlockInfo.blockNumber] = hashStoredBlockInfo(storedBlockInfo);
        totalBlocksProven = storedBlockInfo.blockNumber;
    }

    function getAuthFact(address account, uint32 nonce) external view returns (bytes32) {
        return authFacts[account][nonce];
    }

    function setTotalOpenPriorityRequests(uint64 _totalOpenPriorityRequests) external {
        totalOpenPriorityRequests = _totalOpenPriorityRequests;
    }

    function setSyncProgress(bytes32 syncHash, uint256 progress) external {
        synchronizedChains[syncHash] = progress;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "../ZkLink.sol";

contract ZkLinkTest is ZkLink {

    function setExodus(bool _exodusMode) external {
        exodusMode = _exodusMode;
    }

    function getPriorityHash(uint64 index) external view returns (bytes20) {
        return priorityRequests[index].hashedPubData;
    }

    function mockExecBlock(StoredBlockInfo memory storedBlockInfo) external {
        storedBlockHashes[storedBlockInfo.blockNumber] = hashStoredBlockInfo(storedBlockInfo);
        totalBlocksExecuted = storedBlockInfo.blockNumber;
    }

    function testAddPriorityRequest(Operations.OpType _opType, bytes memory _pubData) external {
        addPriorityRequest(_opType, _pubData);
    }

    function testCommitOneBlock(StoredBlockInfo memory _previousBlock, CommitBlockInfo memory _newBlock, bool _compressed, CompressedBlockExtraInfo memory _newBlockExtra) external view returns (StoredBlockInfo memory storedNewBlock) {
        return commitOneBlock(_previousBlock, _newBlock, _compressed, _newBlockExtra);
    }

    function testCollectOnchainOps(CommitBlockInfo memory _newBlockData) external view
    returns (
        bytes32 processableOperationsHash,
        uint64 priorityOperationsProcessed,
        bytes memory offsetsCommitment,
        bytes32[] memory onchainOperationPubdataHashs
    ) {
        return collectOnchainOps(_newBlockData);
    }

    function testExecuteWithdraw(Operations.Withdraw memory op) external {
        _executeWithdraw(op.accountId, op.accountId, op.subAccountId, op.nonce, op.owner, op.tokenId, op.amount, op.fastWithdrawFeeRate, op.fastWithdraw);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZKLinkToken is ERC20 {

    constructor () ERC20("ZKLink", "ZKL") {
        _mint(msg.sender, 1000000000000000000000000000);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./interfaces/IVerifier.sol";

/// @title An empty verifier, used to deploy to zkevm chain that does not support ecpair temporarily
/// @author zk.link
contract EmptyVerifier is IVerifier {
    // solhint-disable-next-line no-empty-blocks
    function initialize(bytes calldata) external {
        // no initialize need to do when delegatecall by Proxy
    }

    /// @notice Verifier contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    // solhint-disable-next-line no-empty-blocks
    function upgrade(bytes calldata upgradeParameters) external {
        // no upgrade need to do when delegatecall by Proxy
    }

    function verifyAggregatedBlockProof(uint256[] memory, uint256[] memory, uint8[] memory, uint256[] memory, uint256[16] memory) external override pure returns (bool) {
        return false;
    }

    function verifyExitProof(bytes32, uint8, uint32, uint8, bytes32, uint16, uint16, uint128, uint256[] calldata) external override pure returns (bool) {
        return false;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Verifier interface contract
/// @author zk.link
interface IVerifier {
    function verifyAggregatedBlockProof(uint256[] memory _recursiveInput, uint256[] memory _proof, uint8[] memory _vkIndexes, uint256[] memory _individualVksInputs, uint256[16] memory _subProofsLimbs) external returns (bool);

    function verifyExitProof(bytes32 _rootHash, uint8 _chainId, uint32 _accountId, uint8 _subAccountId, bytes32 _owner, uint16 _tokenId, uint16 _srcTokenId, uint128 _amount, uint256[] calldata _proof) external returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title ZkLink interface contract
/// @author zk.link
interface IZkLink {
    // stored block info of ZkLink
    struct StoredBlockInfo {
        uint32 blockNumber;
        uint64 priorityOperations;
        bytes32 pendingOnchainOperationsHash;
        uint256 timestamp;
        bytes32 stateHash;
        bytes32 commitment;
        bytes32 syncHash;
    }

    /// @notice Return the network governor
    function networkGovernor() external view returns (address);

    /// @notice Get synchronized progress of zkLink contract known on deployed chain
    function getSynchronizedProgress(StoredBlockInfo memory block) external view returns (uint256 progress);

    /// @notice Combine the `progress` of the other chains of a `syncHash` with self
    function receiveSynchronizationProgress(bytes32 syncHash, uint256 progress) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./zksync/Operations.sol";
import "./zksync/Config.sol";
import "./interfaces/IVerifier.sol";
import "./zksync/IERC20.sol";
import "./zksync/SafeCast.sol";

/// @title ZkLink storage contract
/// @dev Be carefully to change the order of variables
/// @author zk.link
contract Storage is Config {
    // verifier(20 bytes) + totalBlocksExecuted(4 bytes) + firstPriorityRequestId(8 bytes) stored in the same slot

    /// @notice Verifier contract. Used to verify block proof and exit proof
    IVerifier public verifier;

    /// @notice Total number of executed blocks i.e. blocks[totalBlocksExecuted] points at the latest executed block (block 0 is genesis)
    uint32 public totalBlocksExecuted;

    /// @notice First open priority request id
    uint64 public firstPriorityRequestId;

    // networkGovernor(20 bytes) + totalBlocksCommitted(4 bytes) + totalOpenPriorityRequests(8 bytes) stored in the same slot

    /// @notice The the owner of whole system
    address public networkGovernor;

    /// @notice Total number of committed blocks i.e. blocks[totalBlocksCommitted] points at the latest committed block
    uint32 public totalBlocksCommitted;

    /// @notice Total number of requests
    uint64 public totalOpenPriorityRequests;

    // periphery(20 bytes) + totalBlocksProven(4 bytes) + totalCommittedPriorityRequests(8 bytes) stored in the same slot

    /// @notice Periphery contract. Contains some auxiliary features
    address public periphery;

    /// @notice Total blocks proven.
    uint32 public totalBlocksProven;

    /// @notice Total number of committed requests.
    /// @dev Used in checks: if the request matches the operation on Rollup contract and if provided number of requests is not too big
    uint64 public totalCommittedPriorityRequests;

    /// @dev Used to safely call `delegatecall`, immutable state variables don't occupy storage slot
    address internal immutable self = address(this);

    // totalBlocksSynchronized(4 bytes) + exodusMode(1 bytes) stored in the same slot

    /// @dev Latest synchronized block height
    uint32 public totalBlocksSynchronized;

    /// @notice Flag indicates that exodus (mass exit) mode is triggered
    /// @notice Once it was raised, it can not be cleared again, and all users must exit
    bool public exodusMode;

    /// @dev Root-chain balances (per owner and token id) to withdraw
    /// @dev the amount of pending balance need to recovery decimals when withdraw
    /// @dev The struct of this map is (owner => tokenId => balance)
    /// @dev The type of owner is bytes32, when storing evm address, 12 bytes of prefix zero will be appended
    /// @dev for example: 0x000000000000000000000000A1a547358A9Ca8E7b320d7742729e3334Ad96546
    mapping(bytes32 => mapping(uint16 => uint128)) internal pendingBalances;

    /// @notice Flag indicates that a user has exited a certain token balance in the exodus mode
    /// @dev The struct of this map is (accountId => subAccountId => withdrawTokenId => deductTokenId => performed)
    /// @dev withdrawTokenId is the token that withdraw to user in L1
    /// @dev deductTokenId is the token that deducted from user in L2
    mapping(uint32 => mapping(uint8 => mapping(uint16 => mapping(uint16 => bool)))) public performedExodus;

    /// @dev Priority Requests mapping (request id - operation)
    /// Contains op type, pubdata and expiration block of unsatisfied requests.
    /// Numbers are in order of requests receiving
    mapping(uint64 => Operations.PriorityOperation) internal priorityRequests;

    /// @notice User authenticated fact hashes for some nonce.
    mapping(address => mapping(uint32 => bytes32)) public authFacts;

    /// @dev Timer for authFacts entry reset (address, nonce -> timer).
    /// Used when user wants to reset `authFacts` for some nonce.
    mapping(address => mapping(uint32 => uint256)) internal authFactsResetTimer;

    /// @dev Stored hashed StoredBlockInfo for some block number
    mapping(uint32 => bytes32) internal storedBlockHashes;

    /// @dev if `synchronizedChains` | CHAIN_INDEX equals to `ALL_CHAINS` defined in `Config.sol` then blocks at `blockHeight` and before it can be executed
    // the key is the `syncHash` of `StoredBlockInfo`
    // the value is the `synchronizedChains` of `syncHash` collected from all other chains
    mapping(bytes32 => uint256) internal synchronizedChains;

    /// @dev Accept infos of fast withdraw of account
    /// uint32 is the account id
    /// byte32 is keccak256(abi.encodePacked(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, tokenId, amount, fastWithdrawFeeRate))
    /// address is the acceptor
    mapping(uint32 => mapping(bytes32 => address)) public accepts;

    /// @dev Broker allowance used in accept, acceptor can authorize broker to do accept
    /// @dev Similar to the allowance of transfer in ERC20
    /// @dev The struct of this map is (tokenId => acceptor => broker => allowance)
    mapping(uint16 => mapping(address => mapping(address => uint128))) internal brokerAllowances;

    /// @notice A set of permitted validators
    mapping(address => bool) public validators;

    struct RegisteredToken {
        bool registered; // whether token registered to ZkLink or not, default is false
        bool paused; // whether token can deposit to ZkLink or not, default is false
        address tokenAddress; // the token address
        uint8 decimals; // the token decimals of layer one
        bool standard; // we will not check the balance different of zkLink contract after transfer when a token comply with erc20 standard
    }

    /// @notice A map of registered token infos
    mapping(uint16 => RegisteredToken) public tokens;

    /// @notice A map of token address to id, 0 is invalid token id
    mapping(address => uint16) public tokenIds;

    /// @dev We can set `enableBridgeTo` and `enableBridgeTo` to false to disable bridge when `bridge` is compromised
    struct BridgeInfo {
        address bridge;
        bool enableBridgeTo;
        bool enableBridgeFrom;
    }

    /// @notice bridges
    BridgeInfo[] public bridges;
    // 0 is reversed for non-exist bridge, existing bridges are indexed from 1
    mapping(address => uint256) public bridgeIndex;

    /// @notice block stored data
    /// @dev `blockNumber`,`timestamp`,`stateHash`,`commitment` are the same on all chains
    /// `priorityOperations`,`pendingOnchainOperationsHash` is different for each chain
    struct StoredBlockInfo {
        uint32 blockNumber; // Rollup block number
        uint64 priorityOperations; // Number of priority operations processed
        bytes32 pendingOnchainOperationsHash; // Hash of all operations that must be processed after verify
        uint256 timestamp; // Rollup block timestamp, have the same format as Ethereum block constant
        bytes32 stateHash; // Root hash of the rollup state
        bytes32 commitment; // Verified input for the ZkLink circuit
        bytes32 syncHash; // Used for cross chain block verify
    }

    /// @notice Checks that current state not is exodus mode
    modifier active() {
        require(!exodusMode, "0");
        _;
    }

    /// @notice Checks that current state is exodus mode
    modifier notActive() {
        require(exodusMode, "1");
        _;
    }

    /// @notice Set logic contract must be called through proxy
    modifier onlyDelegateCall() {
        require(address(this) != self, "2");
        _;
    }

    modifier onlyGovernor {
        require(msg.sender == networkGovernor, "3");
        _;
    }

    /// @notice Check if msg sender is a validator
    modifier onlyValidator() {
        require(validators[msg.sender], "4");
        _;
    }

    /// @notice Returns the keccak hash of the ABI-encoded StoredBlockInfo
    function hashStoredBlockInfo(StoredBlockInfo memory _storedBlockInfo) internal pure returns (bytes32) {
        return keccak256(abi.encode(_storedBlockInfo));
    }

    /// @notice Increase pending balance to withdraw
    /// @param _address the pending balance owner
    /// @param _tokenId token id
    /// @param _amount pending amount that need to recovery decimals when withdraw
    function increaseBalanceToWithdraw(bytes32 _address, uint16 _tokenId, uint128 _amount) internal {
        uint128 balance = pendingBalances[_address][_tokenId];
        // overflow should not happen here
        // (2^128 / 10^18 = 3.4 * 10^20) is enough to meet the really token balance of L2 account
        pendingBalances[_address][_tokenId] = balance + _amount;
    }

    /// @notice Extend address to bytes32
    /// @dev for example: extend 0xA1a547358A9Ca8E7b320d7742729e3334Ad96546 and the result is 0x000000000000000000000000a1a547358a9ca8e7b320d7742729e3334ad96546
    function extendAddress(address _address) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }

    /// @notice Sends tokens
    /// @dev NOTE: will revert if transfer call fails or rollup balance difference (before and after transfer) is bigger than _maxAmount
    /// This function is used to allow tokens to spend zkLink contract balance up to amount that is requested
    /// @param _token Token address
    /// @param _to Address of recipient
    /// @param _amount Amount of tokens to transfer
    /// @param _maxAmount Maximum possible amount of tokens to transfer to this account
    /// @param _isStandard If token is a standard erc20
    /// @return withdrawnAmount The really amount than will be debited from user
    function transferERC20(IERC20 _token, address _to, uint128 _amount, uint128 _maxAmount, bool _isStandard) external returns (uint128 withdrawnAmount) {
        require(msg.sender == address(this), "n0"); // can be called only from this contract as one "external" call (to revert all this function state changes if it is needed)

        // most tokens are standard, fewer query token balance can save gas
        if (_isStandard) {
            _token.transfer(_to, _amount);
            return _amount;
        } else {
            uint256 balanceBefore = _token.balanceOf(address(this));
            _token.transfer(_to, _amount);
            uint256 balanceAfter = _token.balanceOf(address(this));
            uint256 balanceDiff = balanceBefore - balanceAfter;
            require(balanceDiff > 0, "n1"); // transfer is considered successful only if the balance of the contract decreased after transfer
            require(balanceDiff <= _maxAmount, "n2"); // rollup balance difference (before and after transfer) is bigger than `_maxAmount`

            // It is safe to convert `balanceDiff` to `uint128` without additional checks, because `balanceDiff <= _maxAmount`
            return uint128(balanceDiff);
        }
    }

    /// @dev improve decimals when deposit, for example, user deposit 2 USDC in ui, and the decimals of USDC is 6
    /// the `_amount` params when call contract will be 2 * 10^6
    /// because all token decimals defined in layer two is 18
    /// so the `_amount` in deposit pubdata should be 2 * 10^6 * 10^(18 - 6) = 2 * 10^18
    function improveDecimals(uint128 _amount, uint8 _decimals) internal pure returns (uint128) {
        // overflow is impossible,  `_decimals` has been checked when register token
        return _amount * SafeCast.toUint128(10**(TOKEN_DECIMALS_OF_LAYER2 - _decimals));
    }

    /// @dev recover decimals when withdraw, this is the opposite of improve decimals
    function recoveryDecimals(uint128 _amount, uint8 _decimals) internal pure returns (uint128) {
        // overflow is impossible,  `_decimals` has been checked when register token
        return _amount / SafeCast.toUint128(10**(TOKEN_DECIMALS_OF_LAYER2 - _decimals));
    }

    /// @dev Return accept record hash for fast withdraw
    function getFastWithdrawHash(uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, address owner, uint16 tokenId, uint128 amount, uint16 fastWithdrawFeeRate) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, tokenId, amount, fastWithdrawFeeRate));
    }

    /// @notice Performs a delegatecall to the contract implementation
    /// @dev Fallback function allowing to perform a delegatecall to the given implementation
    /// This function will return whatever the implementation call returns
    function _fallback(address _target) internal {
        require(_target != address(0), "5");
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _target, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./zksync/ReentrancyGuard.sol";
import "./Storage.sol";
import "./zksync/Events.sol";
import "./zksync/UpgradeableMaster.sol";
import "./zksync/Utils.sol";

/// @title ZkLink contract
/// @dev Be carefully to use delegate to split contract(when the code size is too big) code to different files
/// see https://docs.openzeppelin.com/upgrades-plugins/1.x/faq#delegatecall-selfdestruct
/// @dev add `nonReentrant` to all user external interfaces to avoid a closed loop reentrant attack
/// @author zk.link
contract ZkLink is ReentrancyGuard, Storage, Events, UpgradeableMaster {
    enum ChangePubkeyType {ECRECOVER, CREATE2}

    /// @notice Data needed to process onchain operation from block public data.
    /// @notice Onchain operations is operations that need some processing on L1: Deposits, Withdrawals, ChangePubKey.
    /// @param ethWitness Some external data that can be needed for operation processing
    /// @param publicDataOffset Byte offset in public data for onchain operation
    struct OnchainOperationData {
        bytes ethWitness;
        uint32 publicDataOffset;
    }

    /// @notice Data needed to commit new block
    /// @dev `publicData` contain pubdata of all chains when compressed is disabled or only current chain if compressed is enable
    /// `onchainOperations` contain onchain ops of all chains when compressed is disabled or only current chain if compressed is enable
    struct CommitBlockInfo {
        bytes32 newStateHash;
        bytes publicData;
        uint256 timestamp;
        OnchainOperationData[] onchainOperations;
        uint32 blockNumber;
        uint32 feeAccount;
    }

    struct CompressedBlockExtraInfo {
        bytes32 publicDataHash; // pubdata hash of all chains
        bytes32 offsetCommitmentHash; // all chains pubdata offset commitment hash
        bytes32[] onchainOperationPubdataHashs; // onchain operation pubdata hash of the all other chains
    }

    /// @notice Data needed to execute committed and verified block
    /// @param storedBlock the block info that will be executed
    /// @param pendingOnchainOpsPubdata onchain ops(e.g. Withdraw, ForcedExit, FullExit) that will be executed
    struct ExecuteBlockInfo {
        StoredBlockInfo storedBlock;
        bytes[] pendingOnchainOpsPubdata;
    }

    // =================Upgrade interface=================

    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external pure override returns (uint256) {
        return UPGRADE_NOTICE_PERIOD;
    }

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external view override returns (bool) {
        return !exodusMode;
    }

    /// @notice ZkLink contract initialization. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param initializationParameters Encoded representation of initialization parameters:
    /// @dev _verifierAddress The address of Verifier contract
    /// @dev _peripheryAddress The address of ZkLinkPeriphery contract
    /// @dev _networkGovernor The address of system controller
    function initialize(bytes calldata initializationParameters) external onlyDelegateCall {
        initializeReentrancyGuard();

        (address _verifierAddress, address _peripheryAddress, address _networkGovernor,
        uint32 _blockNumber, uint256 _timestamp, bytes32 _stateHash, bytes32 _commitment, bytes32 _syncHash) =
            abi.decode(initializationParameters, (address, address, address, uint32, uint256, bytes32, bytes32, bytes32));
        require(_verifierAddress != address(0), "i0");
        require(_peripheryAddress != address(0), "i1");
        require(_networkGovernor != address(0), "i2");

        verifier = IVerifier(_verifierAddress);
        periphery = _peripheryAddress;
        networkGovernor = _networkGovernor;

        // We need initial state hash because it is used in the commitment of the next block
        StoredBlockInfo memory storedBlockZero =
            StoredBlockInfo(_blockNumber, 0, EMPTY_STRING_KECCAK, _timestamp, _stateHash, _commitment, _syncHash);

        storedBlockHashes[_blockNumber] = hashStoredBlockInfo(storedBlockZero);
        totalBlocksCommitted = totalBlocksProven = totalBlocksSynchronized = totalBlocksExecuted = _blockNumber;
    }

    /// @notice ZkLink contract upgrade. Can be external because Proxy contract intercepts illegal calls of this function.
    /// @param upgradeParameters Encoded representation of upgrade parameters
    function upgrade(bytes calldata upgradeParameters) external onlyDelegateCall {
        (address _peripheryAddress) = abi.decode(upgradeParameters, (address));
        require(_peripheryAddress != address(0), "u0");
        periphery = _peripheryAddress;
    }

    // =================Delegate call=================

    /// @notice Will run when no functions matches call data
    fallback() external payable {
        _fallback(periphery);
    }

    // =================User interface=================

    /// @notice Deposit ETH to Layer 2 - transfer ether from user into contract, validate it, register deposit
    /// @param _zkLinkAddress The receiver Layer 2 address
    /// @param _subAccountId The receiver sub account
    function depositETH(bytes32 _zkLinkAddress, uint8 _subAccountId) external payable nonReentrant {
        // ETH is not a mapping token in zkLink
        deposit(ETH_ADDRESS, SafeCast.toUint128(msg.value), _zkLinkAddress, _subAccountId, false);
    }

    /// @notice Deposit ERC20 token to Layer 2 - transfer ERC20 tokens from user into contract, validate it, register deposit
    /// @dev it MUST be ok to call other external functions within from this function
    /// when the token(eg. erc777) is not a pure erc20 token
    /// @param _token Token address
    /// @param _amount Token amount
    /// @param _zkLinkAddress The receiver Layer 2 address
    /// @param _subAccountId The receiver sub account
    /// @param _mapping If true and token has a mapping token, user will receive mapping token at L2
    function depositERC20(IERC20 _token, uint104 _amount, bytes32 _zkLinkAddress, uint8 _subAccountId, bool _mapping) external nonReentrant {
        // erc20 token address MUST NOT be ETH_ADDRESS which represent deposit eth
        // it's nearly impossible to create an erc20 token which address is the ETH_ADDRESS
        // add check to avoid this extreme case
        require(address(_token) != ETH_ADDRESS, "e");
        deposit(address(_token), _amount, _zkLinkAddress, _subAccountId, _mapping);
    }

    /// @notice Register full exit request - pack pubdata, add priority request
    /// @param _accountId Numerical id of the account
    /// @param _subAccountId The exit sub account
    /// @param _tokenId Token id
    /// @param _mapping If true and token has a mapping token, user's mapping token balance will be decreased at L2
    function requestFullExit(uint32 _accountId, uint8 _subAccountId, uint16 _tokenId, bool _mapping) external active nonReentrant {
        // ===Checks===
        // accountId and subAccountId MUST be valid
        require(_accountId <= MAX_ACCOUNT_ID && _accountId != GLOBAL_ASSET_ACCOUNT_ID, "a0");
        require(_subAccountId <= MAX_SUB_ACCOUNT_ID, "a1");
        // token MUST be registered to ZkLink
        RegisteredToken storage rt = tokens[_tokenId];
        require(rt.registered, "a2");
        // when full exit stable tokens (e.g. USDC, BUSD) with mapping, USD will be deducted from account
        // and stable token will be transfer from zkLink contract to account address
        // all other tokens don't support mapping
        uint16 srcTokenId;
        if (_mapping) {
            require(_tokenId >= MIN_USD_STABLE_TOKEN_ID && _tokenId <= MAX_USD_STABLE_TOKEN_ID, "a3");
            srcTokenId = USD_TOKEN_ID;
        } else {
            srcTokenId = _tokenId;
        }

        // ===Effects===
        // Priority Queue request
        Operations.FullExit memory op =
            Operations.FullExit({
                chainId: CHAIN_ID,
                accountId: _accountId,
                subAccountId: _subAccountId,
                owner: msg.sender, // Only the owner of account can fullExit for them self
                tokenId: _tokenId,
                srcTokenId: srcTokenId,
                amount: 0 // unknown at this point
            });
        bytes memory pubData = Operations.writeFullExitPubdataForPriorityQueue(op);
        addPriorityRequest(Operations.OpType.FullExit, pubData);
    }

    // =================Validator interface=================

    /// @notice Commit block
    /// @dev 1. Checks onchain operations of all chains, timestamp.
    /// 2. Store block commitments, sync hash
    function commitBlocks(StoredBlockInfo memory _lastCommittedBlockData, CommitBlockInfo[] memory _newBlocksData) external
    {
        CompressedBlockExtraInfo[] memory _newBlocksExtraData = new CompressedBlockExtraInfo[](_newBlocksData.length);
        _commitBlocks(_lastCommittedBlockData, _newBlocksData, false, _newBlocksExtraData);
    }

    /// @notice Commit compressed block
    /// @dev 1. Checks onchain operations of current chain, timestamp.
    /// 2. Store block commitments, sync hash
    function commitCompressedBlocks(StoredBlockInfo memory _lastCommittedBlockData, CommitBlockInfo[] memory _newBlocksData, CompressedBlockExtraInfo[] memory _newBlocksExtraData) external {
        _commitBlocks(_lastCommittedBlockData, _newBlocksData, true, _newBlocksExtraData);
    }

    /// @notice Execute blocks, completing priority operations and processing withdrawals.
    /// @dev 1. Processes all pending operations (Send Exits, Complete priority requests)
    /// 2. Finalizes block on Ethereum
    function executeBlocks(ExecuteBlockInfo[] memory _blocksData) external active onlyValidator nonReentrant {
        uint32 nBlocks = uint32(_blocksData.length);
        require(nBlocks > 0, "d0");

        require(totalBlocksExecuted + nBlocks <= totalBlocksSynchronized, "d1");

        uint64 priorityRequestsExecuted = 0;
        for (uint32 i = 0; i < nBlocks; ++i) {
            executeOneBlock(_blocksData[i], i);
            priorityRequestsExecuted = priorityRequestsExecuted + _blocksData[i].storedBlock.priorityOperations;
        }

        firstPriorityRequestId = firstPriorityRequestId + priorityRequestsExecuted;
        totalCommittedPriorityRequests = totalCommittedPriorityRequests - priorityRequestsExecuted;
        totalOpenPriorityRequests = totalOpenPriorityRequests - priorityRequestsExecuted;

        totalBlocksExecuted = totalBlocksExecuted + nBlocks;

        emit BlockExecuted(_blocksData[nBlocks-1].storedBlock.blockNumber);
    }

    // =================Internal functions=================

    function deposit(address _tokenAddress, uint128 _amount, bytes32 _zkLinkAddress, uint8 _subAccountId, bool _mapping) internal active {
        // ===Checks===
        // disable deposit to zero address or global asset account
        require(_zkLinkAddress != bytes32(0) && _zkLinkAddress != GLOBAL_ASSET_ACCOUNT_ADDRESS, "e1");
        // subAccountId MUST be valid
        require(_subAccountId <= MAX_SUB_ACCOUNT_ID, "e2");
        // token MUST be registered to ZkLink and deposit MUST be enabled
        uint16 tokenId = tokenIds[_tokenAddress];
        // 0 is a invalid token and MUST NOT register to zkLink contract
        require(tokenId != 0, "e3");
        RegisteredToken storage rt = tokens[tokenId];
        require(rt.registered, "e3");
        require(!rt.paused, "e4");

        if (_tokenAddress != ETH_ADDRESS) {
            // transfer erc20 token from sender to zkLink contract
            if (rt.standard) {
                IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
            } else {
                // support non-standard tokens
                uint256 balanceBefore = IERC20(_tokenAddress).balanceOf(address(this));
                // NOTE, the balance of this contract will be increased
                // if the token is not a pure erc20 token, it could do anything within the transferFrom
                // we MUST NOT use `token.balanceOf(address(this))` in any control structures
                IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _amount);
                uint256 balanceAfter = IERC20(_tokenAddress).balanceOf(address(this));
                // use the balance diff as real amount deposited
                _amount = SafeCast.toUint128(balanceAfter - balanceBefore);
            }
        }

        // improve decimals before send to layer two
        _amount = improveDecimals(_amount, rt.decimals);
        // disable deposit with zero amount
        require(_amount > 0 && _amount <= MAX_DEPOSIT_AMOUNT, "e0");

        // only stable tokens(e.g. USDC, BUSD) support mapping to USD when deposit
        uint16 targetTokenId;
        if (_mapping) {
            require(tokenId >= MIN_USD_STABLE_TOKEN_ID && tokenId <= MAX_USD_STABLE_TOKEN_ID, "e5");
            targetTokenId = USD_TOKEN_ID;
        } else {
            targetTokenId = tokenId;
        }

        // ===Effects===
        // Priority Queue request
        Operations.Deposit memory op =
        Operations.Deposit({
            chainId: CHAIN_ID,
            accountId: 0, // unknown at this point
            subAccountId: _subAccountId,
            owner: _zkLinkAddress,
            tokenId: tokenId,
            targetTokenId: targetTokenId,
            amount: _amount
        });
        bytes memory pubData = Operations.writeDepositPubdataForPriorityQueue(op);
        addPriorityRequest(Operations.OpType.Deposit, pubData);
    }

    // Priority queue

    /// @notice Saves priority request in storage
    /// @dev Calculates expiration block for request, store this request and emit NewPriorityRequest event
    /// @param _opType Rollup operation type
    /// @param _pubData Operation pubdata
    function addPriorityRequest(Operations.OpType _opType, bytes memory _pubData) internal {
        // Expiration block is: current block number + priority expiration delta
        uint64 expirationBlock = SafeCast.toUint64(block.number + PRIORITY_EXPIRATION);

        uint64 nextPriorityRequestId = firstPriorityRequestId + totalOpenPriorityRequests;

        bytes20 hashedPubData = Utils.hashBytesToBytes20(_pubData);

        priorityRequests[nextPriorityRequestId] = Operations.PriorityOperation({
            hashedPubData: hashedPubData,
            expirationBlock: expirationBlock,
            opType: _opType
        });

        emit NewPriorityRequest(msg.sender, nextPriorityRequestId, _opType, _pubData, uint256(expirationBlock));

        totalOpenPriorityRequests = totalOpenPriorityRequests + 1;
    }

    function _commitBlocks(StoredBlockInfo memory _lastCommittedBlockData, CommitBlockInfo[] memory _newBlocksData, bool compressed, CompressedBlockExtraInfo[] memory _newBlocksExtraData) internal active onlyValidator nonReentrant {
        // ===Checks===
        require(_newBlocksData.length > 0, "f0");
        // Check that we commit blocks after last committed block
        require(storedBlockHashes[totalBlocksCommitted] == hashStoredBlockInfo(_lastCommittedBlockData), "f1");

        // ===Effects===
        for (uint32 i = 0; i < _newBlocksData.length; ++i) {
            _lastCommittedBlockData = commitOneBlock(_lastCommittedBlockData, _newBlocksData[i], compressed, _newBlocksExtraData[i]);

            // forward `totalCommittedPriorityRequests` because it's will be reused in the next `commitOneBlock`
            totalCommittedPriorityRequests = totalCommittedPriorityRequests + _lastCommittedBlockData.priorityOperations;
            storedBlockHashes[_lastCommittedBlockData.blockNumber] = hashStoredBlockInfo(_lastCommittedBlockData);
        }
        require(totalCommittedPriorityRequests <= totalOpenPriorityRequests, "f2");

        totalBlocksCommitted = totalBlocksCommitted + SafeCast.toUint32(_newBlocksData.length);
        // If enable compressed commit then we can ignore prove and ensure that block is correct by sync
        if (compressed && ENABLE_COMMIT_COMPRESSED_BLOCK) {
            totalBlocksProven = totalBlocksCommitted;
        }

        // log the last new committed block number
        emit BlockCommit(_lastCommittedBlockData.blockNumber);
    }

    /// @dev Process one block commit using previous block StoredBlockInfo,
    /// returns new block StoredBlockInfo
    /// NOTE: Does not change storage (except events, so we can't mark it view)
    function commitOneBlock(StoredBlockInfo memory _previousBlock, CommitBlockInfo memory _newBlock, bool _compressed, CompressedBlockExtraInfo memory _newBlockExtra) internal view returns (StoredBlockInfo memory storedNewBlock) {
        require(_newBlock.blockNumber == _previousBlock.blockNumber + 1, "g0");
        require(!_compressed || ENABLE_COMMIT_COMPRESSED_BLOCK, "g1");

        // Check timestamp of the new block
        {
            require(_newBlock.timestamp >= _previousBlock.timestamp, "g2");
        }

        // Check onchain operations
        (
            bytes32 pendingOnchainOpsHash,
            uint64 priorityReqCommitted,
            bytes memory onchainOpsOffsetCommitment,
            bytes32[] memory onchainOperationPubdataHashs
        ) =
        collectOnchainOps(_newBlock);

        // Create block commitment for verification proof
        bytes32 commitment = createBlockCommitment(_previousBlock, _newBlock, _compressed, _newBlockExtra, onchainOpsOffsetCommitment);

        // Create synchronization hash for cross chain block verify
        if (_compressed) {
            require(_newBlockExtra.onchainOperationPubdataHashs.length == MAX_CHAIN_ID + 1, "g3");
            for(uint i = MIN_CHAIN_ID; i <= MAX_CHAIN_ID; ++i) {
                if (i != CHAIN_ID) {
                    onchainOperationPubdataHashs[i] = _newBlockExtra.onchainOperationPubdataHashs[i];
                }
            }
        }
        bytes32 syncHash = createSyncHash(_previousBlock.syncHash, commitment, onchainOperationPubdataHashs);

        return StoredBlockInfo(
            _newBlock.blockNumber,
            priorityReqCommitted,
            pendingOnchainOpsHash,
            _newBlock.timestamp,
            _newBlock.newStateHash,
            commitment,
            syncHash
        );
    }

    /// @dev Gets operations packed in bytes array. Unpacks it and stores onchain operations.
    /// Priority operations must be committed in the same order as they are in the priority queue.
    /// NOTE: does not change storage! (only emits events)
    /// processableOperationsHash - hash of the all operations of the current chain that needs to be executed  (Withdraws, ForcedExits, FullExits)
    /// priorityOperationsProcessed - number of priority operations processed of the current chain in this block (Deposits, FullExits)
    /// offsetsCommitment - array where 1 is stored in chunk where onchainOperation begins and other are 0 (used in commitments)
    /// onchainOperationPubdatas - onchain operation (Deposits, ChangePubKeys, Withdraws, ForcedExits, FullExits) pubdatas group by chain id (used in cross chain block verify)
    function collectOnchainOps(CommitBlockInfo memory _newBlockData) internal view returns (bytes32 processableOperationsHash, uint64 priorityOperationsProcessed, bytes memory offsetsCommitment, bytes32[] memory onchainOperationPubdataHashs) {
        bytes memory pubData = _newBlockData.publicData;
        // pubdata length must be a multiple of CHUNK_BYTES
        require(pubData.length % CHUNK_BYTES == 0, "h0");
        offsetsCommitment = new bytes(pubData.length / CHUNK_BYTES);

        uint64 uncommittedPriorityRequestsOffset = firstPriorityRequestId + totalCommittedPriorityRequests;
        priorityOperationsProcessed = 0;
        onchainOperationPubdataHashs = initOnchainOperationPubdataHashs();

        processableOperationsHash = EMPTY_STRING_KECCAK;

        for (uint256 i = 0; i < _newBlockData.onchainOperations.length; ++i) {
            OnchainOperationData memory onchainOpData = _newBlockData.onchainOperations[i];

            uint256 pubdataOffset = onchainOpData.publicDataOffset;
            // uint256 chainIdOffset = pubdataOffset.add(1);
            // comment this value to resolve stack too deep error
            require(pubdataOffset + 1 < pubData.length, "h1");
            require(pubdataOffset % CHUNK_BYTES == 0, "h2");

            {
                uint256 chunkId = pubdataOffset / CHUNK_BYTES;
                require(offsetsCommitment[chunkId] == 0x00, "h3"); // offset commitment should be empty
                offsetsCommitment[chunkId] = bytes1(0x01);
            }

            // check chain id
            uint8 chainId = uint8(pubData[pubdataOffset + 1]);
            checkChainId(chainId);

            Operations.OpType opType = Operations.OpType(uint8(pubData[pubdataOffset]));

            uint64 nextPriorityOpIndex = uncommittedPriorityRequestsOffset + priorityOperationsProcessed;
            (uint64 newPriorityProceeded, bytes memory opPubData, bytes memory processablePubData) = checkOnchainOp(
                opType,
                chainId,
                pubData,
                pubdataOffset,
                nextPriorityOpIndex,
                onchainOpData.ethWitness);
            priorityOperationsProcessed = priorityOperationsProcessed + newPriorityProceeded;
            // group onchain operations pubdata hash by chain id
            onchainOperationPubdataHashs[chainId] = Utils.concatHash(onchainOperationPubdataHashs[chainId], opPubData);
            if (processablePubData.length > 0) {
                // concat processable onchain operations pubdata hash of current chain
                processableOperationsHash = Utils.concatHash(processableOperationsHash, processablePubData);
            }
        }
    }

    function initOnchainOperationPubdataHashs() internal pure returns (bytes32[] memory onchainOperationPubdataHashs) {
        // overflow is impossible, max(MAX_CHAIN_ID + 1) = 256
        // use index of onchainOperationPubdataHashs as chain id
        // index start from [0, MIN_CHAIN_ID - 1] left unused
        onchainOperationPubdataHashs = new bytes32[](MAX_CHAIN_ID + 1);
        for(uint i = MIN_CHAIN_ID; i <= MAX_CHAIN_ID; ++i) {
            uint256 chainIndex = 1 << i - 1; // overflow is impossible, min(i) = MIN_CHAIN_ID = 1
            if (chainIndex & ALL_CHAINS == chainIndex) {
                onchainOperationPubdataHashs[i] = EMPTY_STRING_KECCAK;
            }
        }
    }

    function checkChainId(uint8 chainId) internal pure {
        require(chainId >= MIN_CHAIN_ID && chainId <= MAX_CHAIN_ID, "i1");
        // revert if invalid chain id exist
        // for example, when `ALL_CHAINS` = 13(1 << 0 | 1 << 2 | 1 << 3), it means 2(1 << 2 - 1) is a invalid chainId
        uint256 chainIndex = 1 << chainId - 1; // overflow is impossible, min(i) = MIN_CHAIN_ID = 1
        require(chainIndex & ALL_CHAINS == chainIndex, "i2");
    }

    function checkOnchainOp(Operations.OpType opType, uint8 chainId, bytes memory pubData, uint256 pubdataOffset, uint64 nextPriorityOpIdx, bytes memory ethWitness) internal view returns (uint64 priorityOperationsProcessed, bytes memory opPubData, bytes memory processablePubData) {
        priorityOperationsProcessed = 0;
        processablePubData = new bytes(0);
        // ignore check if ops are not part of the current chain
        if (opType == Operations.OpType.Deposit) {
            opPubData = Bytes.slice(pubData, pubdataOffset, DEPOSIT_BYTES);
            if (chainId == CHAIN_ID) {
                Operations.Deposit memory op = Operations.readDepositPubdata(opPubData);
                Operations.checkPriorityOperation(op, priorityRequests[nextPriorityOpIdx]);
                priorityOperationsProcessed = 1;
            }
        } else if (opType == Operations.OpType.ChangePubKey) {
            opPubData = Bytes.slice(pubData, pubdataOffset, CHANGE_PUBKEY_BYTES);
            if (chainId == CHAIN_ID) {
                Operations.ChangePubKey memory op = Operations.readChangePubKeyPubdata(opPubData);
                if (ethWitness.length != 0) {
                    bool valid = verifyChangePubkey(ethWitness, op);
                    require(valid, "k0");
                } else {
                    bool valid = authFacts[op.owner][op.nonce] == keccak256(abi.encodePacked(op.pubKeyHash));
                    require(valid, "k1");
                }
            }
        } else {
            if (opType == Operations.OpType.Withdraw) {
                opPubData = Bytes.slice(pubData, pubdataOffset, WITHDRAW_BYTES);
            } else if (opType == Operations.OpType.ForcedExit) {
                opPubData = Bytes.slice(pubData, pubdataOffset, FORCED_EXIT_BYTES);
            } else if (opType == Operations.OpType.FullExit) {
                opPubData = Bytes.slice(pubData, pubdataOffset, FULL_EXIT_BYTES);
                if (chainId == CHAIN_ID) {
                    Operations.FullExit memory fullExitData = Operations.readFullExitPubdata(opPubData);
                    Operations.checkPriorityOperation(fullExitData, priorityRequests[nextPriorityOpIdx]);
                    priorityOperationsProcessed = 1;
                }
            } else {
                revert("k2");
            }
            if (chainId == CHAIN_ID) {
                // clone opPubData here instead of return its reference
                // because opPubData and processablePubData will be consumed in later concatHash
                processablePubData = Bytes.slice(opPubData, 0, opPubData.length);
            }
        }
    }

    /// @dev Create synchronization hash for cross chain block verify
    function createSyncHash(bytes32 preBlockSyncHash, bytes32 commitment, bytes32[] memory onchainOperationPubdataHashs) internal pure returns (bytes32 syncHash) {
        syncHash = Utils.concatTwoHash(preBlockSyncHash, commitment);
        for (uint8 i = MIN_CHAIN_ID; i <= MAX_CHAIN_ID; ++i) {
            uint256 chainIndex = 1 << i - 1; // overflow is impossible, min(i) = MIN_CHAIN_ID = 1
            if (chainIndex & ALL_CHAINS == chainIndex) {
                syncHash = Utils.concatTwoHash(syncHash, onchainOperationPubdataHashs[i]);
            }
        }
    }

    /// @dev Creates block commitment from its data
    /// @dev _offsetCommitment - hash of the array where 1 is stored in chunk where onchainOperation begins and 0 for other chunks
    function createBlockCommitment(StoredBlockInfo memory _previousBlock, CommitBlockInfo memory _newBlockData, bool _compressed, CompressedBlockExtraInfo memory _newBlockExtraData, bytes memory offsetsCommitment) internal pure returns (bytes32 commitment) {
        bytes32 offsetsCommitmentHash = !_compressed ? sha256(offsetsCommitment) : _newBlockExtraData.offsetCommitmentHash;
        bytes32 newBlockPubDataHash = !_compressed ? sha256(_newBlockData.publicData) : _newBlockExtraData.publicDataHash;
        commitment = sha256(abi.encodePacked(
                uint256(_newBlockData.blockNumber),
                uint256(_newBlockData.feeAccount),
                _previousBlock.stateHash,
                _newBlockData.newStateHash,
                uint256(_newBlockData.timestamp),
                newBlockPubDataHash,
                offsetsCommitmentHash
            ));
    }

    /// @notice Checks that change operation is correct
    function verifyChangePubkey(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk) internal view returns (bool) {
        ChangePubkeyType changePkType = ChangePubkeyType(uint8(_ethWitness[0]));
        if (changePkType == ChangePubkeyType.ECRECOVER) {
            return verifyChangePubkeyECRECOVER(_ethWitness, _changePk);
        } else if (changePkType == ChangePubkeyType.CREATE2) {
            return verifyChangePubkeyCREATE2(_ethWitness, _changePk);
        } else {
            return false;
        }
    }

    /// @notice Checks that signature is valid for pubkey change message
    function verifyChangePubkeyECRECOVER(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk) internal view returns (bool) {
        (, bytes memory signature) = Bytes.read(_ethWitness, 1, 65); // offset is 1 because we skip type of ChangePubkey
        uint cid;
        assembly {
            cid := chainid()
        }
        bytes32 domainSeparator = keccak256(abi.encode(CHANGE_PUBKEY_DOMAIN_SEPARATOR, CHANGE_PUBKEY_HASHED_NAME, CHANGE_PUBKEY_HASHED_VERSION, cid, address(this)));
        bytes32 structHash = keccak256(abi.encode(CHANGE_PUBKEY_TYPE_HASH, _changePk.pubKeyHash, _changePk.nonce, _changePk.accountId));
        bytes32 messageHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address recoveredAddress = Utils.recoverAddressFromEthSignature(signature, messageHash);
        return recoveredAddress == _changePk.owner;
    }

    /// @notice Checks that signature is valid for pubkey change message
    function verifyChangePubkeyCREATE2(bytes memory _ethWitness, Operations.ChangePubKey memory _changePk) internal pure returns (bool) {
        address creatorAddress;
        bytes32 saltArg; // salt arg is additional bytes that are encoded in the CREATE2 salt
        bytes32 codeHash;
        uint256 offset = 1; // offset is 1 because we skip type of ChangePubkey
        (offset, creatorAddress) = Bytes.readAddress(_ethWitness, offset);
        (offset, saltArg) = Bytes.readBytes32(_ethWitness, offset);
        (offset, codeHash) = Bytes.readBytes32(_ethWitness, offset);
        // salt from CREATE2 specification
        bytes32 salt = keccak256(abi.encodePacked(saltArg, _changePk.pubKeyHash));
        // Address computation according to CREATE2 definition: https://eips.ethereum.org/EIPS/eip-1014
        address recoveredAddress = address(
            uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), creatorAddress, salt, codeHash))))
        );
        // This type of change pubkey can be done only once(when the account is not active)
        return recoveredAddress == _changePk.owner && _changePk.nonce == 0;
    }

    /// @dev Executes one block
    /// 1. Processes all pending operations (Send Exits, Complete priority requests)
    /// 2. Finalizes block on Ethereum
    /// _executedBlockIdx is index in the array of the blocks that we want to execute together
    function executeOneBlock(ExecuteBlockInfo memory _blockExecuteData, uint32 _executedBlockIdx) internal {
        // Ensure block was committed
        require(
            hashStoredBlockInfo(_blockExecuteData.storedBlock) ==
            storedBlockHashes[_blockExecuteData.storedBlock.blockNumber],
            "m0"
        );
        require(_blockExecuteData.storedBlock.blockNumber == totalBlocksExecuted + _executedBlockIdx + 1, "m1");

        bytes32 pendingOnchainOpsHash = EMPTY_STRING_KECCAK;
        for (uint32 i = 0; i < _blockExecuteData.pendingOnchainOpsPubdata.length; ++i) {
            bytes memory pubData = _blockExecuteData.pendingOnchainOpsPubdata[i];

            Operations.OpType opType = Operations.OpType(uint8(pubData[0]));

            // `pendingOnchainOpsPubdata` only contains ops of the current chain
            // no need to check chain id

            if (opType == Operations.OpType.Withdraw) {
                Operations.Withdraw memory op = Operations.readWithdrawPubdata(pubData);
                // account request fast withdraw and sub account supply nonce
                _executeWithdraw(op.accountId, op.accountId, op.subAccountId, op.nonce, op.owner, op.tokenId, op.amount, op.fastWithdrawFeeRate, op.fastWithdraw);
            } else if (opType == Operations.OpType.ForcedExit) {
                Operations.ForcedExit memory op = Operations.readForcedExitPubdata(pubData);
                // request forced exit for target account but initiator sub account supply nonce
                // forced exit require fast withdraw default and take no fee for fast withdraw
                _executeWithdraw(op.targetAccountId, op.initiatorAccountId, op.initiatorSubAccountId, op.initiatorNonce, op.target, op.tokenId, op.amount, 0, 1);
            } else if (opType == Operations.OpType.FullExit) {
                Operations.FullExit memory op = Operations.readFullExitPubdata(pubData);
                increasePendingBalance(op.tokenId, op.owner, op.amount);
            } else {
                revert("m2");
            }
            pendingOnchainOpsHash = Utils.concatHash(pendingOnchainOpsHash, pubData);
        }
        require(pendingOnchainOpsHash == _blockExecuteData.storedBlock.pendingOnchainOperationsHash, "m3");
    }

    /// @dev Execute fast withdraw or normal withdraw according by fastWithdraw flag
    function _executeWithdraw(uint32 accountId, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, address owner, uint16 tokenId, uint128 amount, uint16 fastWithdrawFeeRate, uint8 fastWithdraw) internal {
        // token MUST be registered
        RegisteredToken storage rt = tokens[tokenId];
        require(rt.registered, "o0");

        if (fastWithdraw == 1) {
            // recover withdraw amount
            uint128 acceptAmount = recoveryDecimals(amount, rt.decimals);
            uint128 dustAmount = amount - improveDecimals(acceptAmount, rt.decimals);
            bytes32 fwHash = getFastWithdrawHash(accountIdOfNonce, subAccountIdOfNonce, nonce, owner, tokenId, acceptAmount, fastWithdrawFeeRate);
            address acceptor = accepts[accountId][fwHash];
            if (acceptor == address(0)) {
                // receiver act as a acceptor
                accepts[accountId][fwHash] = owner;
                increasePendingBalance(tokenId, owner, amount);
            } else {
                increasePendingBalance(tokenId, acceptor, amount - dustAmount);
                // add dust to owner
                if (dustAmount > 0) {
                    increasePendingBalance(tokenId, owner, dustAmount);
                }
            }
        } else {
            increasePendingBalance(tokenId, owner, amount);
        }
    }

    /// @dev Increase `_recipient` balance to withdraw
    /// @param _amount amount that need to recovery decimals when withdraw
    function increasePendingBalance(uint16 _tokenId, address _recipient, uint128 _amount) internal {
        bytes32 recipient = extendAddress(_recipient);
        increaseBalanceToWithdraw(recipient, _tokenId, _amount);
        emit WithdrawalPending(_tokenId, recipient, _amount);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./zksync/ReentrancyGuard.sol";
import "./zksync/Events.sol";
import "./Storage.sol";
import "./zksync/Bytes.sol";
import "./zksync/Utils.sol";

/// @title ZkLink periphery contract
/// @author zk.link
contract ZkLinkPeriphery is ReentrancyGuard, Storage, Events {
    // =================User interface=================

    /// @notice Checks if Exodus mode must be entered. If true - enters exodus mode and emits ExodusMode event.
    /// @dev Exodus mode must be entered in case of current ethereum block number is higher than the oldest
    /// of existed priority requests expiration block number.
    function activateExodusMode() external active nonReentrant {
        bool trigger = block.number >= priorityRequests[firstPriorityRequestId].expirationBlock &&
        priorityRequests[firstPriorityRequestId].expirationBlock != 0;

        if (trigger) {
            exodusMode = true;
            emit ExodusMode();
        }
    }

    /// @notice Withdraws token from ZkLink to root chain in case of exodus mode. User must provide proof that he owns funds
    /// @param _storedBlockInfo Last verified block
    /// @param _owner Owner of the account
    /// @param _accountId Id of the account in the tree
    /// @param _subAccountId Id of the subAccount in the tree
    /// @param _proof Proof
    /// @param _withdrawTokenId The token want to withdraw in L1
    /// @param _deductTokenId The token deducted in L2
    /// @param _amount Amount for owner (must be total amount, not part of it) in L2
    function performExodus(StoredBlockInfo calldata _storedBlockInfo, bytes32 _owner, uint32 _accountId, uint8 _subAccountId, uint16 _withdrawTokenId, uint16 _deductTokenId, uint128 _amount, uint256[] calldata _proof) external notActive nonReentrant {
        // ===Checks===
        // performed exodus MUST not be already exited
        require(!performedExodus[_accountId][_subAccountId][_withdrawTokenId][_deductTokenId], "y0");
        // incorrect stored block info
        require(storedBlockHashes[totalBlocksExecuted] == hashStoredBlockInfo(_storedBlockInfo), "y1");
        // exit proof MUST be correct
        bool proofCorrect = verifier.verifyExitProof(_storedBlockInfo.stateHash, CHAIN_ID, _accountId, _subAccountId, _owner, _withdrawTokenId, _deductTokenId, _amount, _proof);
        require(proofCorrect, "y2");

        // ===Effects===
        performedExodus[_accountId][_subAccountId][_withdrawTokenId][_deductTokenId] = true;
        increaseBalanceToWithdraw(_owner, _withdrawTokenId, _amount);
        emit WithdrawalPending(_withdrawTokenId, _owner, _amount);
    }

    /// @notice Accrues users balances from deposit priority requests in Exodus mode
    /// @dev WARNING: Only for Exodus mode
    /// Canceling may take several separate transactions to be completed
    /// @param _n number of requests to process
    /// @param _depositsPubdata deposit details
    function cancelOutstandingDepositsForExodusMode(uint64 _n, bytes[] calldata _depositsPubdata) external notActive nonReentrant {
        // ===Checks===
        uint64 toProcess = Utils.minU64(totalOpenPriorityRequests, _n);
        require(toProcess > 0, "A0");

        // ===Effects===
        uint64 currentDepositIdx = 0;
        // overflow is impossible, firstPriorityRequestId >= 0 and toProcess > 0
        uint64 lastPriorityRequestId = firstPriorityRequestId + toProcess - 1;
        for (uint64 id = firstPriorityRequestId; id <= lastPriorityRequestId; ++id) {
            Operations.PriorityOperation memory pr = priorityRequests[id];
            if (pr.opType == Operations.OpType.Deposit) {
                bytes memory depositPubdata = _depositsPubdata[currentDepositIdx];
                require(Utils.hashBytesToBytes20(depositPubdata) == pr.hashedPubData, "A1");
                ++currentDepositIdx;

                Operations.Deposit memory op = Operations.readDepositPubdata(depositPubdata);
                // amount of Deposit has already improve decimals
                increaseBalanceToWithdraw(op.owner, op.tokenId, op.amount);
            }
            // after return back deposited token to user, delete the priorityRequest to avoid redundant cancel
            // other priority requests(ie. FullExit) are also be deleted because they are no used anymore
            // and we can get gas reward for free these slots
            delete priorityRequests[id];
        }
        // overflow is impossible
        firstPriorityRequestId += toProcess;
        totalOpenPriorityRequests -= toProcess;
    }

    /// @notice Set data for changing pubkey hash using onchain authorization.
    ///         Transaction author (msg.sender) should be L2 account address
    /// New pubkey hash can be reset, to do that user should send two transactions:
    ///         1) First `setAuthPubkeyHash` transaction for already used `_nonce` will set timer.
    ///         2) After `AUTH_FACT_RESET_TIMELOCK` time is passed second `setAuthPubkeyHash` transaction will reset pubkey hash for `_nonce`.
    /// @param _pubkeyHash New pubkey hash
    /// @param _nonce Nonce of the change pubkey L2 transaction
    function setAuthPubkeyHash(bytes calldata _pubkeyHash, uint32 _nonce) external active nonReentrant {
        require(_pubkeyHash.length == PUBKEY_HASH_BYTES, "B0"); // PubKeyHash should be 20 bytes.
        if (authFacts[msg.sender][_nonce] == bytes32(0)) {
            authFacts[msg.sender][_nonce] = keccak256(_pubkeyHash);
            emit FactAuth(msg.sender, _nonce, _pubkeyHash);
        } else {
            uint256 currentResetTimer = authFactsResetTimer[msg.sender][_nonce];
            if (currentResetTimer == 0) {
                authFactsResetTimer[msg.sender][_nonce] = block.timestamp;
                emit FactAuthResetTime(msg.sender, _nonce, block.timestamp);
            } else {
                require(block.timestamp - currentResetTimer >= AUTH_FACT_RESET_TIMELOCK, "B1"); // too early to reset auth
                authFactsResetTimer[msg.sender][_nonce] = 0;
                authFacts[msg.sender][_nonce] = keccak256(_pubkeyHash);
                emit FactAuth(msg.sender, _nonce, _pubkeyHash);
            }
        }
    }

    /// @notice  Withdraws tokens from zkLink contract to the owner
    /// @param _owner Address of the tokens owner
    /// @param _tokenId Token id
    /// @param _amount Amount to withdraw to request.
    /// @return The actual withdrawn amount
    /// @dev NOTE: We will call ERC20.transfer(.., _amount), but if according to internal logic of ERC20 token zkLink contract
    /// balance will be decreased by value more then _amount we will try to subtract this value from user pending balance
    function withdrawPendingBalance(address payable _owner, uint16 _tokenId, uint128 _amount) external nonReentrant returns (uint128) {
        // ===Checks===
        // token MUST be registered to ZkLink
        RegisteredToken storage rt = tokens[_tokenId];
        require(rt.registered, "b0");

        // Set the available amount to withdraw
        // balance need to be recovery decimals
        bytes32 owner = extendAddress(_owner);
        uint128 balance = pendingBalances[owner][_tokenId];
        uint128 withdrawBalance = recoveryDecimals(balance, rt.decimals);
        uint128 amount = Utils.minU128(withdrawBalance, _amount);
        require(amount > 0, "b1");

        // ===Interactions===
        address tokenAddress = rt.tokenAddress;
        if (tokenAddress == ETH_ADDRESS) {
            // solhint-disable-next-line  avoid-low-level-calls
            (bool success, ) = _owner.call{value: amount}("");
            require(success, "b2");
        } else {
            // We will allow withdrawals of `value` such that:
            // `value` <= user pending balance
            // `value` can be bigger then `amount` requested if token takes fee from sender in addition to `amount` requested
            amount = this.transferERC20(IERC20(tokenAddress), _owner, amount, withdrawBalance, rt.standard);
        }

        // improve withdrawn amount decimals
        pendingBalances[owner][_tokenId] = balance - improveDecimals(amount, rt.decimals);
        emit Withdrawal(_tokenId, amount);

        return amount;
    }

    /// @notice Returns amount of tokens that can be withdrawn by `address` from zkLink contract
    /// @param _address Address of the tokens owner
    /// @param _tokenId Token id
    /// @return The pending balance(without recovery decimals) can be withdrawn
    function getPendingBalance(bytes32 _address, uint16 _tokenId) external view returns (uint128) {
        return pendingBalances[_address][_tokenId];
    }
    // =======================Governance interface======================

    /// @notice Change current governor
    /// @param _newGovernor Address of the new governor
    function changeGovernor(address _newGovernor) external onlyGovernor {
        require(_newGovernor != address(0), "H");
        if (networkGovernor != _newGovernor) {
            networkGovernor = _newGovernor;
            emit NewGovernor(_newGovernor);
        }
    }

    /// @notice Add token to the list of networks tokens
    /// @param _tokenId Token id
    /// @param _tokenAddress Token address
    /// @param _decimals Token decimals of layer one
    /// @param _standard If token is a standard erc20
    function addToken(uint16 _tokenId, address _tokenAddress, uint8 _decimals, bool _standard) public onlyGovernor {
        // token id MUST be in a valid range
        require(_tokenId > 0 && _tokenId <= MAX_AMOUNT_OF_REGISTERED_TOKENS, "I0");
        // token MUST be not zero address
        require(_tokenAddress != address(0), "I1");
        // revert duplicate register
        RegisteredToken memory rt = tokens[_tokenId];
        require(!rt.registered, "I2");
        require(tokenIds[_tokenAddress] == 0, "I2");
        // token decimals of layer one MUST not be larger than decimals defined in layer two
        require(_decimals <= TOKEN_DECIMALS_OF_LAYER2, "I3");

        rt.registered = true;
        rt.tokenAddress = _tokenAddress;
        rt.decimals = _decimals;
        rt.standard = _standard;
        tokens[_tokenId] = rt;
        tokenIds[_tokenAddress] = _tokenId;
        emit NewToken(_tokenId, _tokenAddress, _decimals);
    }

    struct Token {
        uint16 tokenId; // token id defined by zkLink
        address tokenAddress; // token address in L1
        uint8 decimals; // token decimals in L1
        bool standard; // if token a pure erc20 or not
    }

    /// @notice Add tokens to the list of networks tokens
    /// @param _tokenList Token list
    function addTokens(Token[] calldata _tokenList) external {
        for (uint i; i < _tokenList.length; i++) {
            Token memory _token = _tokenList[i];
            addToken(_token.tokenId, _token.tokenAddress, _token.decimals, _token.standard);
        }
    }

    /// @notice Pause token deposits for the given token
    /// @param _tokenId Token id
    /// @param _tokenPaused Token paused status
    function setTokenPaused(uint16 _tokenId, bool _tokenPaused) external onlyGovernor {
        RegisteredToken storage rt = tokens[_tokenId];
        require(rt.registered, "K");

        if (rt.paused != _tokenPaused) {
            rt.paused = _tokenPaused;
            emit TokenPausedUpdate(_tokenId, _tokenPaused);
        }
    }

    /// @notice Change validator status (active or not active)
    /// @param _validator Validator address
    /// @param _active Active flag
    function setValidator(address _validator, bool _active) external onlyGovernor {
        if (validators[_validator] != _active) {
            validators[_validator] = _active;
            emit ValidatorStatusUpdate(_validator, _active);
        }
    }

    /// @notice Add a new bridge
    /// @param bridge the bridge contract
    /// @return the index of new bridge
    function addBridge(address bridge) external onlyGovernor returns (uint256) {
        require(bridge != address(0), "L0");
        // the index of non-exist bridge is zero
        require(bridgeIndex[bridge] == 0, "L1");

        BridgeInfo memory info = BridgeInfo({
            bridge: bridge,
            enableBridgeTo: true,
            enableBridgeFrom: true
        });
        bridges.push(info);
        bridgeIndex[bridge] = bridges.length;
        emit AddBridge(bridge, bridges.length);

        return bridges.length;
    }

    /// @notice Update bridge info
    /// @dev If we want to remove a bridge(not compromised), we should firstly set `enableBridgeTo` to false
    /// and wait all messages received from this bridge and then set `enableBridgeFrom` to false.
    /// But when a bridge is compromised, we must set both `enableBridgeTo` and `enableBridgeFrom` to false immediately
    /// @param index the bridge info index
    /// @param enableBridgeTo if set to false, bridge to will be disabled
    /// @param enableBridgeFrom if set to false, bridge from will be disabled
    function updateBridge(uint256 index, bool enableBridgeTo, bool enableBridgeFrom) external onlyGovernor {
        require(index < bridges.length, "M");
        BridgeInfo memory info = bridges[index];
        info.enableBridgeTo = enableBridgeTo;
        info.enableBridgeFrom = enableBridgeFrom;
        bridges[index] = info;
        emit UpdateBridge(index, enableBridgeTo, enableBridgeFrom);
    }

    function isBridgeToEnabled(address bridge) external view returns (bool) {
        uint256 index = bridgeIndex[bridge] - 1;
        return bridges[index].enableBridgeTo;
    }

    function isBridgeFromEnabled(address bridge) public view returns (bool) {
        uint256 index = bridgeIndex[bridge] - 1;
        return bridges[index].enableBridgeFrom;
    }

    // =======================Block interface======================

    /// @notice Recursive proof input data (individual commitments are constructed onchain)
    struct ProofInput {
        uint256[] recursiveInput;
        uint256[] proof;
        uint256[] commitments;
        uint8[] vkIndexes;
        uint256[16] subproofsLimbs;
    }

    /// @notice Blocks commitment verification.
    /// @dev Only verifies block commitments without any other processing
    function proveBlocks(StoredBlockInfo[] memory _committedBlocks, ProofInput memory _proof) external nonReentrant {
        // ===Checks===
        uint32 currentTotalBlocksProven = totalBlocksProven;
        for (uint256 i = 0; i < _committedBlocks.length; ++i) {
            currentTotalBlocksProven = currentTotalBlocksProven + 1;
            require(hashStoredBlockInfo(_committedBlocks[i]) == storedBlockHashes[currentTotalBlocksProven], "x0");

            // commitment of proof produced by zk has only 253 significant bits
            // 'commitment & INPUT_MASK' is used to set the highest 3 bits to 0 and leave the rest unchanged
            require(_proof.commitments[i] <= MAX_PROOF_COMMITMENT
                && _proof.commitments[i] == uint256(_committedBlocks[i].commitment) & INPUT_MASK, "x1");
        }

        // ===Effects===
        require(currentTotalBlocksProven <= totalBlocksCommitted, "x2");
        totalBlocksProven = currentTotalBlocksProven;

        // ===Interactions===
        bool success = verifier.verifyAggregatedBlockProof(
            _proof.recursiveInput,
            _proof.proof,
            _proof.vkIndexes,
            _proof.commitments,
            _proof.subproofsLimbs
        );
        require(success, "x3");

        emit BlockProven(currentTotalBlocksProven);
    }

    /// @notice Reverts unExecuted blocks
    function revertBlocks(StoredBlockInfo[] memory _blocksToRevert) external onlyValidator nonReentrant {
        uint32 blocksCommitted = totalBlocksCommitted;
        uint32 blocksToRevert = Utils.minU32(SafeCast.toUint32(_blocksToRevert.length), blocksCommitted - totalBlocksExecuted);
        uint64 revertedPriorityRequests = 0;

        for (uint32 i = 0; i < blocksToRevert; ++i) {
            StoredBlockInfo memory storedBlockInfo = _blocksToRevert[i];
            require(storedBlockHashes[blocksCommitted] == hashStoredBlockInfo(storedBlockInfo), "c"); // incorrect stored block info

            delete storedBlockHashes[blocksCommitted];

            --blocksCommitted;
            revertedPriorityRequests = revertedPriorityRequests + storedBlockInfo.priorityOperations;
        }

        totalBlocksCommitted = blocksCommitted;
        totalCommittedPriorityRequests = totalCommittedPriorityRequests - revertedPriorityRequests;
        if (totalBlocksCommitted < totalBlocksProven) {
            totalBlocksProven = totalBlocksCommitted;
        }
        if (totalBlocksProven < totalBlocksSynchronized) {
            totalBlocksSynchronized = totalBlocksProven;
        }

        emit BlocksRevert(totalBlocksExecuted, blocksCommitted);
    }

    // =======================Cross chain block synchronization======================

    /// @notice Combine the `progress` of the other chains of a `syncHash` with self
    function receiveSynchronizationProgress(bytes32 syncHash, uint256 progress) external {
        require(isBridgeFromEnabled(msg.sender), "C");

        synchronizedChains[syncHash] = synchronizedChains[syncHash] | progress;
    }

    /// @notice Get synchronized progress of current chain known
    function getSynchronizedProgress(StoredBlockInfo memory _block) public view returns (uint256 progress) {
        // `ALL_CHAINS` will be upgraded when we add a new chain
        // and all blocks that confirm synchronized will return the latest progress flag
        if (_block.blockNumber <= totalBlocksSynchronized) {
            progress = ALL_CHAINS;
        } else {
            progress = synchronizedChains[_block.syncHash];
            // combine the current chain if it has proven this block
            if (_block.blockNumber <= totalBlocksProven &&
                hashStoredBlockInfo(_block) == storedBlockHashes[_block.blockNumber]) {
                progress |= CHAIN_INDEX;
            } else {
                // to prevent bridge from delivering a wrong progress
                progress &= ~CHAIN_INDEX;
            }
        }
    }

    /// @notice Check if received all syncHash from other chains at the block height
    function syncBlocks(StoredBlockInfo memory _block) external nonReentrant {
        uint256 progress = getSynchronizedProgress(_block);
        require(progress == ALL_CHAINS, "D0");

        uint32 blockNumber = _block.blockNumber;
        require(blockNumber > totalBlocksSynchronized, "D1");

        totalBlocksSynchronized = blockNumber;
    }

    // =======================Fast withdraw and Accept======================

    /// @notice Acceptor accept a eth fast withdraw, acceptor will get a fee for profit
    /// @param acceptor Acceptor who accept a fast withdraw
    /// @param accountId Account that request fast withdraw
    /// @param receiver User receive token from acceptor (the owner of withdraw operation)
    /// @param amount The amount of withdraw operation
    /// @param withdrawFeeRate Fast withdraw fee rate taken by acceptor
    /// @param accountIdOfNonce Account that supply nonce, may be different from accountId
    /// @param subAccountIdOfNonce SubAccount that supply nonce
    /// @param nonce SubAccount nonce, used to produce unique accept info
    function acceptETH(address acceptor, uint32 accountId, address payable receiver, uint128 amount, uint16 withdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) external payable nonReentrant {
        // ===Checks===
        uint16 tokenId = tokenIds[ETH_ADDRESS];
        (uint128 amountReceive, ) =
        _checkAccept(acceptor, accountId, receiver, tokenId, amount, withdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce);

        // ===Interactions===
        // make sure msg value >= amountReceive
        uint256 amountReturn = msg.value - amountReceive;
        // msg.sender should set a reasonable gas limit when call this function
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = receiver.call{value: amountReceive}("");
        require(success, "E0");
        // if send too more eth then return back to msg sender
        if (amountReturn > 0) {
            // it's safe to use call to msg.sender and can send all gas left to it
            // solhint-disable-next-line avoid-low-level-calls
            (success, ) = msg.sender.call{value: amountReturn}("");
            require(success, "E1");
        }
        emit Accept(acceptor, accountId, receiver, tokenId, amount, withdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce, amountReceive, amountReceive);
    }

    /// @notice Acceptor accept a erc20 token fast withdraw, acceptor will get a fee for profit
    /// @param acceptor Acceptor who accept a fast withdraw
    /// @param accountId Account that request fast withdraw
    /// @param receiver User receive token from acceptor (the owner of withdraw operation)
    /// @param tokenId Token id
    /// @param amount The amount of withdraw operation
    /// @param withdrawFeeRate Fast withdraw fee rate taken by acceptor
    /// @param accountIdOfNonce Account that supply nonce, may be different from accountId
    /// @param subAccountIdOfNonce SubAccount that supply nonce
    /// @param nonce SubAccount nonce, used to produce unique accept info
    /// @param amountTransfer Amount that transfer from acceptor to receiver
    /// may be a litter larger than the amount receiver received
    function acceptERC20(address acceptor, uint32 accountId, address receiver, uint16 tokenId, uint128 amount, uint16 withdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, uint128 amountTransfer) external nonReentrant {
        // ===Checks===
        (uint128 amountReceive, address tokenAddress) =
        _checkAccept(acceptor, accountId, receiver, tokenId, amount, withdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce);

        // ===Interactions===
        // stack too deep
        uint128 amountSent;
        {
            address _acceptor = acceptor;
            address _receiver = receiver;
            uint256 receiverBalanceBefore = IERC20(tokenAddress).balanceOf(_receiver);
            uint256 acceptorBalanceBefore = IERC20(tokenAddress).balanceOf(_acceptor);
            IERC20(tokenAddress).transferFrom(_acceptor, _receiver, amountTransfer);
            uint256 receiverBalanceAfter = IERC20(tokenAddress).balanceOf(_receiver);
            uint256 acceptorBalanceAfter = IERC20(tokenAddress).balanceOf(_acceptor);
            uint128 receiverBalanceDiff = SafeCast.toUint128(receiverBalanceAfter - receiverBalanceBefore);
            require(receiverBalanceDiff >= amountReceive, "F0");
            amountReceive = receiverBalanceDiff;
            // amountSent may be larger than amountReceive when the token is a non standard erc20 token
            amountSent = SafeCast.toUint128(acceptorBalanceBefore - acceptorBalanceAfter);
        }
        if (msg.sender != acceptor) {
            require(brokerAllowance(tokenId, acceptor, msg.sender) >= amountSent, "F1");
            brokerAllowances[tokenId][acceptor][msg.sender] -= amountSent;
        }
        emit Accept(acceptor, accountId, receiver, tokenId, amount, withdrawFeeRate, accountIdOfNonce, subAccountIdOfNonce, nonce, amountSent, amountReceive);
    }

    /// @return Return the accept allowance of broker
    function brokerAllowance(uint16 tokenId, address acceptor, address broker) public view returns (uint128) {
        return brokerAllowances[tokenId][acceptor][broker];
    }

    /// @notice Give allowance to broker to call accept
    /// @param tokenId token that transfer to the receiver of accept request from acceptor or broker
    /// @param broker who are allowed to do accept by acceptor(the msg.sender)
    /// @param amount the accept allowance of broker
    function brokerApprove(uint16 tokenId, address broker, uint128 amount) external returns (bool) {
        require(broker != address(0), "G");
        brokerAllowances[tokenId][msg.sender][broker] = amount;
        emit BrokerApprove(tokenId, msg.sender, broker, amount);
        return true;
    }

    function _checkAccept(address acceptor, uint32 accountId, address receiver, uint16 tokenId, uint128 amount, uint16 withdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce) internal active returns (uint128 amountReceive, address tokenAddress) {
        // acceptor and receiver MUST be set and MUST not be the same
        require(acceptor != address(0), "H0");
        require(receiver != address(0), "H1");
        require(receiver != acceptor, "H2");
        // token MUST be registered to ZkLink
        RegisteredToken memory rt = tokens[tokenId];
        require(rt.registered, "H3");
        tokenAddress = rt.tokenAddress;
        // feeRate MUST be valid and MUST not be 100%
        require(withdrawFeeRate < MAX_ACCEPT_FEE_RATE, "H4");
        amountReceive = amount * (MAX_ACCEPT_FEE_RATE - withdrawFeeRate) / MAX_ACCEPT_FEE_RATE;

        // accept tx may be later than block exec tx(with user withdraw op)
        bytes32 hash = getFastWithdrawHash(accountIdOfNonce, subAccountIdOfNonce, nonce, receiver, tokenId, amount, withdrawFeeRate);
        require(accepts[accountId][hash] == address(0), "H6");

        // ===Effects===
        accepts[accountId][hash] = acceptor;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
            add(bts, 32), // BYTES_HEADER_SIZE
            data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(uint160(self)), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return newOffset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 newOffset, bytes memory data) {
        data = slice(_data, _offset, _length);
        newOffset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bool r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint8 r) {
        newOffset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint16 r) {
        newOffset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint24 r) {
        newOffset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint32 r) {
        newOffset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint128 r) {
        newOffset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, uint160 r) {
        newOffset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, address r) {
        newOffset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes20 r) {
        newOffset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 newOffset, bytes32 r) {
        newOffset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _newLength) internal pure returns (uint256 r) {
        require(_newLength <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _newLength, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _newLength) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
            // here outStringByte from each half of input byte calculates by the next:
            //
            // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
            // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                out_curr,
                shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                add(out_curr, 0x01),
                shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title zkSync configuration constants
/// @author Matter Labs
contract Config {
    bytes32 internal constant EMPTY_STRING_KECCAK = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /// @dev Bytes in one chunk
    uint8 internal constant CHUNK_BYTES = 23;

    /// @dev Bytes of L2 PubKey hash
    uint8 internal constant PUBKEY_HASH_BYTES = 20;

    /// @dev Max amount of tokens registered in the network
    uint16 internal constant MAX_AMOUNT_OF_REGISTERED_TOKENS = 65535;

    /// @dev Max account id that could be registered in the network
    uint32 internal constant MAX_ACCOUNT_ID = 16777215;

    /// @dev Max sub account id that could be bound to account id
    uint8 internal constant MAX_SUB_ACCOUNT_ID = 31;

    /// @dev Expected average period of block creation
    uint256 internal constant BLOCK_PERIOD = 12 seconds;

    /// @dev Operation chunks
    uint256 internal constant DEPOSIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant FULL_EXIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant WITHDRAW_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant FORCED_EXIT_BYTES = 3 * CHUNK_BYTES;
    uint256 internal constant CHANGE_PUBKEY_BYTES = 3 * CHUNK_BYTES;

    /// @dev Expiration delta for priority request to be satisfied (in seconds)
    /// @dev NOTE: Priority expiration should be > (EXPECT_VERIFICATION_IN * BLOCK_PERIOD)
    /// @dev otherwise incorrect block with priority op could not be reverted.
    uint256 internal constant PRIORITY_EXPIRATION_PERIOD = 14 days;

    /// @dev Expiration delta for priority request to be satisfied (in ETH blocks)
    uint256 internal constant PRIORITY_EXPIRATION =
        216000;

    /// @dev Reserved time for users to send full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant MASS_FULL_EXIT_PERIOD = 5 days;

    /// @dev Reserved time for users to withdraw funds from full exit priority operation in case of an upgrade (in seconds)
    uint256 internal constant TIME_TO_WITHDRAW_FUNDS_FROM_FULL_EXIT = 2 days;

    /// @dev Notice period before activation preparation status of upgrade mode (in seconds)
    /// @dev NOTE: we must reserve for users enough time to send full exit operation, wait maximum time for processing this operation and withdraw funds from it.
    uint256 internal constant UPGRADE_NOTICE_PERIOD =
        3600;

    /// @dev Max commitment produced in zk proof where highest 3 bits is 0
    uint256 internal constant MAX_PROOF_COMMITMENT = 0x1fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @dev Bit mask to apply for verifier public input before verifying.
    uint256 internal constant INPUT_MASK = 14474011154664524427946373126085988481658748083205070504932198000989141204991;

    /// @dev Auth fact reset timelock
    uint256 internal constant AUTH_FACT_RESET_TIMELOCK = 1 days;

    /// @dev Max deposit of ERC20 token that is possible to deposit
    uint128 internal constant MAX_DEPOSIT_AMOUNT = 20282409603651670423947251286015;

    /// @dev Chain id defined by ZkLink
    uint8 internal constant CHAIN_ID = 9;

    /// @dev Min chain id defined by ZkLink
    uint8 internal constant MIN_CHAIN_ID = 1;

    /// @dev Max chain id defined by ZkLink
    uint8 internal constant MAX_CHAIN_ID = 15;

    /// @dev All chain index, for example [1, 2, 3, 4] => 1 << 0 | 1 << 1 | 1 << 2 | 1 << 3 = 15
    uint256 internal constant ALL_CHAINS = 18263;

    /// @dev Chain index, CHAIN_ID is non-zero value
    uint256 internal constant CHAIN_INDEX = 1<<CHAIN_ID-1;

    /// @dev Enable commit a compressed block
    bool internal constant ENABLE_COMMIT_COMPRESSED_BLOCK = true;

    /// @dev Address represent eth when deposit or withdraw
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev When set fee = 100, it means 1%
    uint16 internal constant MAX_ACCEPT_FEE_RATE = 10000;

    /// @dev see EIP-712
    bytes32 internal constant CHANGE_PUBKEY_DOMAIN_SEPARATOR = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 internal constant CHANGE_PUBKEY_HASHED_NAME =  keccak256("ZkLink");
    bytes32 internal constant CHANGE_PUBKEY_HASHED_VERSION = keccak256("1");
    bytes32 internal constant CHANGE_PUBKEY_TYPE_HASH = keccak256("ChangePubKey(bytes20 pubKeyHash,uint32 nonce,uint32 accountId)");

    /// @dev Token decimals is a fixed value at layer two in ZkLink
    uint8 internal constant TOKEN_DECIMALS_OF_LAYER2 = 18;

    /// @dev Global asset account in the network
    /// @dev Can not deposit to or full exit this account
    uint32 internal constant GLOBAL_ASSET_ACCOUNT_ID = 1;
    bytes32 internal constant GLOBAL_ASSET_ACCOUNT_ADDRESS = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @dev USD and USD stable tokens defined by zkLink
    /// @dev User can deposit USD stable token(eg. USDC, BUSD) to get USD in layer two
    /// @dev And user also can full exit USD in layer two and get back USD stable tokens
    uint16 internal constant USD_TOKEN_ID = 1;
    uint16 internal constant MIN_USD_STABLE_TOKEN_ID = 17;
    uint16 internal constant MAX_USD_STABLE_TOKEN_ID = 31;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Upgradeable.sol";
import "./Operations.sol";

/// @title zkSync events
/// @author Matter Labs
interface Events {
    /// @notice Event emitted when a block is committed
    event BlockCommit(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is proven
    event BlockProven(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is executed
    event BlockExecuted(uint32 indexed blockNumber);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state and contract
    event Withdrawal(uint16 indexed tokenId, uint128 amount);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state but not from contract
    event WithdrawalPending(uint16 indexed tokenId, bytes32 indexed recepient, uint128 amount);

    /// @notice Event emitted when user sends a authentication fact (e.g. pub-key hash)
    event FactAuth(address indexed sender, uint32 nonce, bytes fact);

    /// @notice Event emitted when authentication fact reset clock start
    event FactAuthResetTime(address indexed sender, uint32 nonce, uint256 time);

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(uint32 totalBlocksVerified, uint32 totalBlocksCommitted);

    /// @notice Exodus mode entered event
    event ExodusMode();

    /// @notice New priority request event. Emitted when a request is placed into mapping
    event NewPriorityRequest(
        address sender,
        uint64 serialId,
        Operations.OpType opType,
        bytes pubData,
        uint256 expirationBlock
    );

    /// @notice Event emitted when acceptor accept a fast withdraw
    event Accept(address indexed acceptor, uint32 indexed accountId, address indexed receiver, uint16 tokenId, uint128 amount, uint16 withdrawFeeRate, uint32 accountIdOfNonce, uint8 subAccountIdOfNonce, uint32 nonce, uint128 amountSent, uint128 amountReceive);

    /// @notice Event emitted when set broker allowance
    event BrokerApprove(uint16 indexed tokenId, address indexed owner, address indexed spender, uint128 amount);

    /// @notice Token added to ZkLink net
    /// @dev log token decimals on this chain to let L2 know(token decimals maybe different on different chains)
    event NewToken(uint16 indexed tokenId, address indexed token, uint8 decimals);

    /// @notice Governor changed
    event NewGovernor(address newGovernor);

    /// @notice Validator's status changed
    event ValidatorStatusUpdate(address indexed validatorAddress, bool isActive);

    /// @notice Token pause status update
    event TokenPausedUpdate(uint16 indexed token, bool paused);

    /// @notice New bridge added
    event AddBridge(address indexed bridge, uint256 bridgeIndex);

    /// @notice Bridge update
    event UpdateBridge(uint256 indexed bridgeIndex, bool enableBridgeTo, bool enableBridgeFrom);
}

/// @title Upgrade events
/// @author Matter Labs
interface UpgradeEvents {
    /// @notice Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    event NewUpgradable(uint256 indexed versionId, address indexed upgradeable);

    /// @notice Upgrade mode enter event
    event NoticePeriodStart(
        uint256 indexed versionId,
        address[] newTargets,
        uint256 noticePeriod // notice period (in seconds)
    );

    /// @notice Upgrade mode cancel event
    event UpgradeCancel(uint256 indexed versionId);

    /// @notice Upgrade mode preparation status event
    event PreparationStart(uint256 indexed versionId);

    /// @notice Upgrade mode complete event
    event UpgradeComplete(uint256 indexed versionId, address[] newTargets);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external;

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

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
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Bytes.sol";
import "./Utils.sol";

/// @title zkSync operations tools
/// @dev Circuit ops and their pubdata (chunks * bytes)
library Operations {
    /// @dev zkSync circuit operation type
    enum OpType {
        Noop, // 0
        Deposit, // 1 L1 Op
        TransferToNew, // 2 L2 Op
        Withdraw, // 3 L2 Op
        Transfer, // 4 L2 Op
        FullExit, // 5 L1 Op
        ChangePubKey, // 6 L2 Op
        ForcedExit, // 7 L2 Op
        OrderMatching // 8 L2 Op
    }

    // Byte lengths

    /// @dev op is uint8
    uint8 internal constant OP_TYPE_BYTES = 1;

    /// @dev chainId is uint8
    uint8 internal constant CHAIN_BYTES = 1;

    /// @dev token is uint16
    uint8 internal constant TOKEN_BYTES = 2;

    /// @dev nonce is uint32
    uint8 internal constant NONCE_BYTES = 4;

    /// @dev address is 20 bytes length
    uint8 internal constant ADDRESS_BYTES = 20;

    /// @dev address prefix zero bytes length
    uint8 internal constant ADDRESS_PREFIX_ZERO_BYTES = 12;

    /// @dev fee is uint16
    uint8 internal constant FEE_BYTES = 2;

    /// @dev accountId is uint32
    uint8 internal constant ACCOUNT_ID_BYTES = 4;

    /// @dev subAccountId is uint8
    uint8 internal constant SUB_ACCOUNT_ID_BYTES = 1;

    /// @dev amount is uint128
    uint8 internal constant AMOUNT_BYTES = 16;

    // Priority operations: Deposit, FullExit
    struct PriorityOperation {
        bytes20 hashedPubData; // hashed priority operation public data
        uint64 expirationBlock; // expiration block number (ETH block) for this request (must be satisfied before)
        OpType opType; // priority operation type
    }

    struct Deposit {
        // uint8 opType
        uint8 chainId; // deposit from which chain that identified by L2 chain id
        uint32 accountId; // the account id bound to the owner address, ignored at serialization and will be set when the block is submitted
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        uint16 tokenId; // the token that registered to L2
        uint16 targetTokenId; // the token that user increased in L2
        uint128 amount; // the token amount deposited to L2
        bytes32 owner; // the address that receive deposited token at L2
    } // 59

    /// @dev Deserialize deposit pubdata
    function readDepositPubdata(bytes memory _data) internal pure returns (Deposit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.targetTokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        (offset, parsed.owner) = Bytes.readBytes32(_data, offset);
    }

    /// @dev Serialize deposit pubdata
    function writeDepositPubdataForPriorityQueue(Deposit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.Deposit),
            op.chainId,
            uint32(0), // accountId (ignored during hash calculation)
            op.subAccountId,
            op.tokenId,
            op.targetTokenId,
            op.amount,
            op.owner
        );
    }

    /// @dev Checks that deposit is same as operation in priority queue
    function checkPriorityOperation(Deposit memory _deposit, PriorityOperation memory _priorityOperation) internal pure {
        require(_priorityOperation.opType == Operations.OpType.Deposit, "OP: not deposit");
        require(Utils.hashBytesToBytes20(writeDepositPubdataForPriorityQueue(_deposit)) == _priorityOperation.hashedPubData, "OP: invalid deposit hash");
    }

    struct FullExit {
        // uint8 opType
        uint8 chainId; // withdraw to which chain that identified by L2 chain id
        uint32 accountId; // the account id to withdraw from
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the address that own the account at L2
        uint16 tokenId; // the token that withdraw to L1
        uint16 srcTokenId; // the token that deducted in L2
        uint128 amount; // the token amount that fully withdrawn to owner, ignored at serialization and will be set when the block is submitted
    } // 59

    /// @dev Deserialize fullExit pubdata
    function readFullExitPubdata(bytes memory _data) internal pure returns (FullExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.srcTokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
    }

    /// @dev Serialize fullExit pubdata
    function writeFullExitPubdataForPriorityQueue(FullExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.FullExit),
            op.chainId,
            op.accountId,
            op.subAccountId,
            bytes12(0), // append 12 zero bytes
            op.owner,
            op.tokenId,
            op.srcTokenId,
            uint128(0) // amount(ignored during hash calculation)
        );
    }

    /// @dev Checks that FullExit is same as operation in priority queue
    function checkPriorityOperation(FullExit memory _fullExit, PriorityOperation memory _priorityOperation) internal pure {
        require(_priorityOperation.opType == Operations.OpType.FullExit, "OP: not fullExit");
        require(Utils.hashBytesToBytes20(writeFullExitPubdataForPriorityQueue(_fullExit)) == _priorityOperation.hashedPubData, "OP: invalid fullExit hash");
    }

    struct Withdraw {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the withdraw happened
        uint32 accountId; // the account id to withdraw from
        uint8 subAccountId; // the sub account id to withdraw from
        uint16 tokenId; // the token that to withdraw
        //uint16 srcTokenId; -- the token that decreased in L2, present in pubdata, ignored at serialization
        uint128 amount; // the token amount to withdraw
        //uint16 fee; -- present in pubdata, ignored at serialization
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the address to receive token
        uint32 nonce; // the sub account nonce
        uint16 fastWithdrawFeeRate; // fast withdraw fee rate taken by acceptor
        uint8 fastWithdraw; // when this flag is 1, it means fast withdrawal
    } // 68

    function readWithdrawPubdata(bytes memory _data) internal pure returns (Withdraw memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        offset += TOKEN_BYTES;
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        offset += FEE_BYTES;
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
        (offset, parsed.fastWithdrawFeeRate) = Bytes.readUInt16(_data, offset);
        (offset, parsed.fastWithdraw) = Bytes.readUint8(_data, offset);
    }

    struct ForcedExit {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the force exit happened
        uint32 initiatorAccountId; // the account id of initiator
        uint8 initiatorSubAccountId; // the sub account id of initiator
        uint32 initiatorNonce; // the sub account nonce of initiator
        uint32 targetAccountId; // the account id of target
        //uint8 targetSubAccountId; -- present in pubdata, ignored at serialization
        uint16 tokenId; // the token that to withdraw
        //uint16 srcTokenId; -- the token that decreased in L2, present in pubdata, ignored at serialization
        uint128 amount; // the token amount to withdraw
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address target; // the address to receive token
    } // 68 bytes

    function readForcedExitPubdata(bytes memory _data) internal pure returns (ForcedExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.initiatorAccountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.initiatorSubAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.initiatorNonce) = Bytes.readUInt32(_data, offset);
        (offset, parsed.targetAccountId) = Bytes.readUInt32(_data, offset);
        offset += SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        offset += TOKEN_BYTES;
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.target) = Bytes.readAddress(_data, offset);
    }

    // ChangePubKey
    struct ChangePubKey {
        // uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain to verify(only one chain need to verify for gas saving)
        uint32 accountId; // the account that to change pubkey
        //uint8 subAccountId; -- present in pubdata, ignored at serialization
        bytes20 pubKeyHash; // hash of the new rollup pubkey
        //bytes12 addressPrefixZero; -- address bytes length in L2 is 32
        address owner; // the owner that own this account
        uint32 nonce; // the account nonce
        //uint16 tokenId; -- present in pubdata, ignored at serialization
        //uint16 fee; -- present in pubdata, ignored at serialization
    } // 67 bytes

    function readChangePubKeyPubdata(bytes memory _data) internal pure returns (ChangePubKey memory parsed) {
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        offset += SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.pubKeyHash) = Bytes.readBytes20(_data, offset);
        offset += ADDRESS_PREFIX_ZERO_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Ownable Contract
/// @author Matter Labs
contract Ownable {
    /// @dev Storage position of the masters address (keccak256('eip1967.proxy.admin') - 1)
    bytes32 private constant MASTER_POSITION = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @notice Contract constructor
    /// @dev Sets msg sender address as masters address
    /// @param masterAddress Master address
    constructor(address masterAddress) {
        setMaster(masterAddress);
    }

    /// @notice Check if specified address is master
    /// @param _address Address to check
    function requireMaster(address _address) internal view {
        require(_address == getMaster(), "1c"); // oro11 - only by master
    }

    /// @notice Returns contract masters address
    /// @return master Master's address
    function getMaster() public view returns (address master) {
        bytes32 position = MASTER_POSITION;
        assembly {
            master := sload(position)
        }
    }

    /// @dev Sets new masters address
    /// @param _newMaster New master's address
    function setMaster(address _newMaster) internal {
        bytes32 position = MASTER_POSITION;
        assembly {
            sstore(position, _newMaster)
        }
    }

    /// @notice Transfer mastership of the contract to new master
    /// @param _newMaster New masters address
    function transferMastership(address _newMaster) external {
        requireMaster(msg.sender);
        require(_newMaster != address(0), "1d"); // otp11 - new masters address can't be zero address
        setMaster(_newMaster);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Ownable.sol";
import "./Upgradeable.sol";
import "./UpgradeableMaster.sol";

/// @title Proxy Contract
/// @dev NOTICE: Proxy must implement UpgradeableMaster interface to prevent calling some function of it not by master of proxy
/// @author Matter Labs
contract Proxy is Upgradeable, Ownable {
    /// @dev Storage position of "target" (actual implementation address: keccak256('eip1967.proxy.implementation') - 1)
    bytes32 private constant TARGET_POSITION = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Contract constructor
    /// @dev Calls Ownable contract constructor and initialize target
    /// @param target Initial implementation address
    /// @param targetInitializationParameters Target initialization parameters
    constructor(address target, bytes memory targetInitializationParameters) Ownable(msg.sender) {
        setTarget(target);
        // solhint-disable-next-line avoid-low-level-calls
        (bool initializationSuccess, ) = getTarget().delegatecall(abi.encodeWithSignature("initialize(bytes)", targetInitializationParameters));
        require(initializationSuccess, "uin11"); // uin11 - target initialization failed
    }

    /// @notice Intercepts initialization calls
    function initialize(bytes calldata) external pure {
        revert("ini11"); // ini11 - interception of initialization call
    }

    /// @notice Intercepts upgrade calls
    function upgrade(bytes calldata) external pure {
        revert("upg11"); // upg11 - interception of upgrade call
    }

    /// @notice Returns target of contract
    /// @return target Actual implementation address
    function getTarget() public view returns (address target) {
        bytes32 position = TARGET_POSITION;
        assembly {
            target := sload(position)
        }
    }

    /// @notice Sets new target of contract
    /// @param _newTarget New actual implementation address
    function setTarget(address _newTarget) internal {
        bytes32 position = TARGET_POSITION;
        assembly {
            sstore(position, _newTarget)
        }
    }

    /// @notice Upgrades target
    /// @param newTarget New target
    /// @param newTargetUpgradeParameters New target upgrade parameters
    function upgradeTarget(address newTarget, bytes calldata newTargetUpgradeParameters) external override {
        requireMaster(msg.sender);

        setTarget(newTarget);
        // solhint-disable-next-line avoid-low-level-calls
        (bool upgradeSuccess, ) = getTarget().delegatecall(abi.encodeWithSignature("upgrade(bytes)", newTargetUpgradeParameters));
        require(upgradeSuccess, "ufu11"); // ufu11 - target upgrade failed
    }

    /// @notice Performs a delegatecall to the contract implementation
    /// @dev Fallback function allowing to perform a delegatecall to the given implementation
    /// This function will return whatever the implementation call returns
    function _fallback() internal {
        address _target = getTarget();
        assembly {
            // The pointer to the free memory slot
            let ptr := mload(0x40)
            // Copy function signature and arguments from calldata at zero position into memory at pointer position
            calldatacopy(ptr, 0x0, calldatasize())
            // Delegatecall method of the implementation contract, returns 0 on error
            let result := delegatecall(gas(), _target, ptr, calldatasize(), 0x0, 0)
            // Get the size of the last return data
            let size := returndatasize()
            // Copy the size length of bytes from return data at zero position to pointer position
            returndatacopy(ptr, 0x0, size)
            // Depending on result value
            switch result
                case 0 {
                    // End execution and revert state changes
                    revert(ptr, size)
                }
                default {
                    // Return data with length of size at pointers position
                    return(ptr, size)
                }
        }
    }

    /// @notice Will run when no functions matches call data
    fallback() external payable {
        _fallback();
    }

    /// @notice Same as fallback but called when calldata is empty
    receive() external payable {
        _fallback();
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    /// @dev Address of lock flag variable.
    /// @dev Flag is placed at random memory location to not interfere with Storage contract.
    uint256 private constant LOCK_FLAG_ADDRESS = 0x8e94fed44239eb2314ab7a406345e6c5a8f0ccedf3b600de3d004e672c33abf4; // keccak256("ReentrancyGuard") - 1;

    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/566a774222707e424896c0c390a84dc3c13bdcb2/contracts/security/ReentrancyGuard.sol
    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    function initializeReentrancyGuard() internal {
        uint256 lockSlotOldValue;

        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange every call to nonReentrant
        // will be cheaper.
        assembly {
            lockSlotOldValue := sload(LOCK_FLAG_ADDRESS)
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }

        // Check that storage slot for reentrancy guard is empty to rule out possibility of double initialization
        require(lockSlotOldValue == 0, "1B");
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        uint256 _status;
        assembly {
            _status := sload(LOCK_FLAG_ADDRESS)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_status == _NOT_ENTERED);

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(LOCK_FLAG_ADDRESS, _NOT_ENTERED)
        }
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/**
 * @dev Wrappers over Solidity's uintXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and then downcasting.
 *
 * _Available since v2.5.0._
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "16");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "17");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "18");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "19");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "1a");
        return uint8(value);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable contract
/// @author Matter Labs
interface Upgradeable {
    /// @notice Upgrades target of upgradeable contract
    /// @param newTarget New target
    /// @param newTargetInitializationParameters New target initialization parameters
    function upgradeTarget(address newTarget, bytes calldata newTargetInitializationParameters) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable master contract (defines notice period duration and allows finish upgrade during preparation of it)
/// @author Matter Labs
interface UpgradeableMaster {
    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external returns (uint256);

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Events.sol";
import "./Ownable.sol";
import "./Upgradeable.sol";
import "./UpgradeableMaster.sol";

/// @title Upgrade Gatekeeper Contract
/// @author Matter Labs
contract UpgradeGatekeeper is UpgradeEvents, Ownable {
    /// @notice Array of addresses of upgradeable contracts managed by the gatekeeper
    Upgradeable[] public managedContracts;

    /// @notice Upgrade mode statuses
    enum UpgradeStatus {Idle, NoticePeriod, Preparation}

    UpgradeStatus public upgradeStatus;

    /// @notice Notice period finish timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint256 public noticePeriodFinishTimestamp;

    /// @notice Addresses of the next versions of the contracts to be upgraded (if element of this array is equal to zero address it means that appropriate upgradeable contract wouldn't be upgraded this time)
    /// @dev Will be empty in case of not active upgrade mode
    address[] public nextTargets;

    /// @notice Version id of contracts
    uint256 public versionId;

    /// @notice Contract which defines notice period duration and allows finish upgrade during preparation of it
    UpgradeableMaster public mainContract;

    /// @notice Contract constructor
    /// @param _mainContract Contract which defines notice period duration and allows finish upgrade during preparation of it
    /// @dev Calls Ownable contract constructor
    constructor(address _mainContract) Ownable(msg.sender) {
        mainContract = UpgradeableMaster(_mainContract);
        versionId = 0;
    }

    /// @notice Adds a new upgradeable contract to the list of contracts managed by the gatekeeper
    /// @param addr Address of upgradeable contract to add
    function addUpgradeable(address addr) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Idle, "apc11"); /// apc11 - upgradeable contract can't be added during upgrade

        managedContracts.push(Upgradeable(addr));
        emit NewUpgradable(versionId, addr);
    }

    /// @notice Starts upgrade (activates notice period)
    /// @param newTargets New managed contracts targets (if element of this array is equal to zero address it means that appropriate upgradeable contract wouldn't be upgraded this time)
    function startUpgrade(address[] calldata newTargets) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Idle, "spu11"); // spu11 - unable to activate active upgrade mode
        require(newTargets.length == managedContracts.length, "spu12"); // spu12 - number of new targets must be equal to the number of managed contracts

        uint256 noticePeriod = mainContract.getNoticePeriod();
        upgradeStatus = UpgradeStatus.NoticePeriod;
        noticePeriodFinishTimestamp = block.timestamp + noticePeriod;
        nextTargets = newTargets;
        emit NoticePeriodStart(versionId, newTargets, noticePeriod);
    }

    /// @notice Cancels upgrade
    function cancelUpgrade() external {
        requireMaster(msg.sender);
        require(upgradeStatus != UpgradeStatus.Idle, "cpu11"); // cpu11 - unable to cancel not active upgrade mode

        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
        delete nextTargets;
        emit UpgradeCancel(versionId);
    }

    /// @notice Activates preparation status
    /// @return Bool flag indicating that preparation status has been successfully activated
    function startPreparation() external returns (bool) {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.NoticePeriod, "ugp11"); // ugp11 - unable to activate preparation status in case of not active notice period status

        if (block.timestamp >= noticePeriodFinishTimestamp) {
            upgradeStatus = UpgradeStatus.Preparation;
            emit PreparationStart(versionId);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Finishes upgrade
    /// @param targetsUpgradeParameters New targets upgrade parameters per each upgradeable contract
    function finishUpgrade(bytes[] calldata targetsUpgradeParameters) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Preparation, "fpu11"); // fpu11 - unable to finish upgrade without preparation status active
        require(targetsUpgradeParameters.length == managedContracts.length, "fpu12"); // fpu12 - number of new targets upgrade parameters must be equal to the number of managed contracts
        require(mainContract.isReadyForUpgrade(), "fpu13"); // fpu13 - main contract is not ready for upgrade

        for (uint64 i = 0; i < managedContracts.length; ++i) {
            address newTarget = nextTargets[i];
            if (newTarget != address(0)) {
                managedContracts[i].upgradeTarget(newTarget, targetsUpgradeParameters[i]);
            }
        }
        versionId++;
        emit UpgradeComplete(versionId, nextTargets);

        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
        delete nextTargets;
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "ut0"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    /// @notice Returns new_hash = hash(a + b)
    function concatTwoHash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    function hashBytesToBytes20(bytes memory _bytes) internal pure returns (bytes20) {
        return bytes20(uint160(uint256(keccak256(_bytes))));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}