// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Client} from "../libraries/Client.sol";

interface IRouterClient {
  error UnsupportedDestinationChain(uint64 destChainSelector);
  error InsufficientFeeTokenAmount();
  error InvalidMsgValue();

  /// @notice Checks if the given chain ID is supported for sending/receiving.
  /// @param chainSelector The chain to check.
  /// @return supported is true if it is supported, false if not.
  function isChainSupported(uint64 chainSelector) external view returns (bool supported);

  /// @notice Gets a list of all supported tokens which can be sent or received
  /// to/from a given chain id.
  /// @param chainSelector The chainSelector.
  /// @return tokens The addresses of all tokens that are supported.
  function getSupportedTokens(uint64 chainSelector) external view returns (address[] memory tokens);

  /// @param destinationChainSelector The destination chainSelector
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return fee returns execution fee for the message
  /// delivery to destination chain, denominated in the feeToken specified in the message.
  /// @dev Reverts with appropriate reason upon invalid message.
  function getFee(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory message
  ) external view returns (uint256 fee);

  /// @notice Request a message to be sent to the destination chain
  /// @param destinationChainSelector The destination chain ID
  /// @param message The cross-chain CCIP message including data and/or tokens
  /// @return messageId The message ID
  /// @dev Note if msg.value is larger than the required fee (from getFee) we accept
  /// the overpayment with no refund.
  /// @dev Reverts with appropriate reason upon invalid message.
  function ccipSend(
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// End consumer library.
library Client {
  /// @dev RMN depends on this struct, if changing, please notify the RMN maintainers.
  struct EVMTokenAmount {
    address token; // token address on the local chain.
    uint256 amount; // Amount of tokens.
  }

  struct Any2EVMMessage {
    bytes32 messageId; // MessageId corresponding to ccipSend on source.
    uint64 sourceChainSelector; // Source chain selector.
    bytes sender; // abi.decode(sender) if coming from an EVM chain.
    bytes data; // payload sent in original message.
    EVMTokenAmount[] destTokenAmounts; // Tokens and their amounts in their destination chain representation.
  }

  // If extraArgs is empty bytes, the default is 200k gas limit.
  struct EVM2AnyMessage {
    bytes receiver; // abi.encode(receiver address) for dest EVM chains
    bytes data; // Data payload
    EVMTokenAmount[] tokenAmounts; // Token transfers
    address feeToken; // Address of feeToken. address(0) means you will send msg.value.
    bytes extraArgs; // Populate this with _argsToBytes(EVMExtraArgsV1)
  }

  // bytes4(keccak256("CCIP EVMExtraArgsV1"));
  bytes4 public constant EVM_EXTRA_ARGS_V1_TAG = 0x97a657c9;
  struct EVMExtraArgsV1 {
    uint256 gasLimit;
  }

  function _argsToBytes(EVMExtraArgsV1 memory extraArgs) internal pure returns (bytes memory bts) {
    return abi.encodeWithSelector(EVM_EXTRA_ARGS_V1_TAG, extraArgs);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Provides set of properties, functions, and modifiers to help with 
 * security and access control of extending contracts
 */
contract ArcBase is Ownable2Step, Pausable, ReentrancyGuard
{
    function pause() public onlyOwner
    {
        _pause();
    }
    
    function unpause() public onlyOwner
    {
        _unpause();
    }

    function withdrawNative(address beneficiary) public onlyOwner {
        uint256 amount = address(this).balance;
        (bool sent, ) = beneficiary.call{value: amount}("");
        require(sent, 'Unable to withdraw');
    }

    function withdrawToken(address beneficiary, address token) public onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(beneficiary, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {ArcBase} from "./ArcBase.sol";
import {IRainbowRoad} from "../interfaces/IRainbowRoad.sol";

/**
 * Extends the ArcBase contract to provide
 * for interactions with the Rainbow Road
 */
contract ArcBaseWithRainbowRoad is ArcBase
{
    IRainbowRoad public rainbowRoad;
    
    constructor(address _rainbowRoad)
    {
        require(_rainbowRoad != address(0), 'Rainbow Road cannot be zero address');
        rainbowRoad = IRainbowRoad(_rainbowRoad);
    }
    
    function setRainbowRoad(address _rainbowRoad) external onlyOwner
    {
        require(_rainbowRoad != address(0), 'Rainbow Road cannot be zero address');
        rainbowRoad = IRainbowRoad(_rainbowRoad);
    }
    
    /// @dev Only calls from the Rainbow Road are accepted.
    modifier onlyRainbowRoad() 
    {
        require(msg.sender == address(rainbowRoad), 'Must be called by Rainbow Road');
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IArc {
    function approve(address _spender, uint _value) external returns (bool);
    function burn(uint amount) external;
    function mint(address account, uint amount) external;
    function transfer(address, uint) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IArc} from "./IArc.sol";

interface IRainbowRoad {
    
    function acceptTeam() external;
    function actionHandlers(string calldata action) external view returns (address);
    function arc() external view returns (IArc);
    function blockToken(address tokenAddress) external;
    function disableFeeManager(address feeManager) external;
    function disableOpenTokenWhitelisting() external;
    function disableReceiver(address receiver) external;
    function disableSender(address sender) external;
    function disableSendFeeBurn() external;
    function disableSendFeeCharge() external;
    function disableWhitelistingFeeBurn() external;
    function disableWhitelistingFeeCharge() external;
    function enableFeeManager(address feeManager) external;
    function enableOpenTokenWhitelisting() external;
    function enableReceiver(address receiver) external;
    function enableSendFeeBurn() external;
    function enableSender(address sender) external;
    function enableSendFeeCharge() external;
    function enableWhitelistingFeeBurn() external;
    function enableWhitelistingFeeCharge() external;
    function sendFee() external view returns (uint256);
    function whitelistingFee() external view returns (uint256);
    function chargeSendFee() external view returns (bool);
    function chargeWhitelistingFee() external view returns (bool);
    function burnSendFee() external view returns (bool);
    function burnWhitelistingFee() external view returns (bool);
    function openTokenWhitelisting() external view returns (bool);
    function config(string calldata configName) external view returns (bytes memory);
    function blockedTokens(address tokenAddress) external view returns (bool);
    function feeManagers(address feeManager) external view returns (bool);
    function receiveAction(string calldata action, address to, bytes calldata payload) external;
    function sendAction(string calldata action, address from, bytes calldata payload) external;
    function setActionHandler(string memory action, address handler) external;
    function setArc(address _arc) external;
    function setSendFee(uint256 _fee) external;
    function setTeam(address _team) external;
    function setTeamRate(uint256 _teamRate) external;
    function setToken(string calldata tokenSymbol, address tokenAddress) external;
    function setWhitelistingFee(uint256 _fee) external;
    function team() external view returns (address);
    function teamRate() external view returns (uint256);
    function tokens(string calldata tokenSymbol) external view returns (address);
    function MAX_TEAM_RATE() external view returns (uint256);
    function receivers(address receiver) external view returns (bool);
    function senders(address sender) external view returns (bool);
    function unblockToken(address tokenAddress) external;
    function whitelist(address tokenAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {ArcBaseWithRainbowRoad} from "../bases/ArcBaseWithRainbowRoad.sol";
import {IRainbowRoad} from "../interfaces/IRainbowRoad.sol";

/**
 * Sends messages to the Chainlink CCIP router
 */
contract ChainlinkSender is ArcBaseWithRainbowRoad 
{
    enum PaymentTypes {
        NATIVE,
        LINK
    }

    IRouterClient public router;
    LinkTokenInterface public link;
    PaymentTypes public paymentType;
    mapping(address => bool) public admins;

    event MessageSent(bytes32 messageId, uint64 destinationChainSelector, address messageReceiver, string action, address actionRecipient);

    constructor(address _rainbowRoad, address _router, address _link) ArcBaseWithRainbowRoad(_rainbowRoad)
    {
        require(_router != address(0), 'Router cannot be zero address');
        require(_link != address(0), 'Link cannot be zero address');
        
        router = IRouterClient(_router);
        link = LinkTokenInterface(_link);
        paymentType = PaymentTypes.LINK;
    }
    
    function setRouter(address _router) external onlyOwner
    {
        require(_router != address(0), 'Router cannot be zero address');
        router = IRouterClient(_router);
    }

    function setLink(address _link) external onlyOwner
    {
        require(_link != address(0), 'Link cannot be zero address');
        link = LinkTokenInterface(_link);
    }
    
    function setPaymentTypeToLink() external onlyOwner
    {
        require(paymentType != PaymentTypes.LINK, 'Fees are already paid in LINK');
        paymentType = PaymentTypes.LINK;
    }
    
    function setPaymentTypeToNative() external onlyOwner
    {
        require(paymentType != PaymentTypes.NATIVE, 'Fees are already paid in NATIVE');
        paymentType = PaymentTypes.NATIVE;
    }
    
    function enableAdmin(address admin) external onlyOwner
    {
        require(!admins[admin], 'Admin is enabled');
        admins[admin] = true;
    }
    
    function disableAdmin(address admin) external onlyOwner
    {
        require(admins[admin], 'Admin is disabled');
        admins[admin] = false;
    }

    function send(uint64 destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) external nonReentrant whenNotPaused onlyAdmins returns (bytes32 messageId)
    {
        return _send(destinationChainSelector, messageReceiver, actionRecipient, action, payload);
    }
    
    function send(uint64 destinationChainSelector, address messageReceiver, string calldata action, bytes calldata payload) external nonReentrant whenNotPaused returns (bytes32 messageId)
    {
        return _send(destinationChainSelector, messageReceiver, msg.sender, action, payload);
    }

    function _send(uint64 destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) internal returns (bytes32 messageId)
    {
        require(messageReceiver != address(0), 'Message receiver cannot be zero address');

        rainbowRoad.sendAction(action, actionRecipient, payload);
        
        bytes memory extraArgs;
        {
            string memory extraArgsConfigName = 'chainlink_sender_v1_2_0.extra_args';
            string memory extraArgsConfigNameOverride = string.concat(extraArgsConfigName, '_', action);
            extraArgs = rainbowRoad.config(extraArgsConfigNameOverride);
            if(extraArgs.length == 0) {
                extraArgs = rainbowRoad.config(extraArgsConfigName);
            }
        }
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(messageReceiver),
            data: abi.encode(action, actionRecipient, payload),
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: extraArgs,
            feeToken: paymentType == PaymentTypes.LINK ? address(link) : address(0)
        });

        uint256 fee = router.getFee(destinationChainSelector, message);

        if (paymentType == PaymentTypes.LINK) {
            link.approve(address(router), fee);
            messageId = router.ccipSend(destinationChainSelector, message);
        } else {
            messageId = router.ccipSend{value: fee}(destinationChainSelector, message);
        }

        emit MessageSent(messageId, destinationChainSelector, messageReceiver, action, actionRecipient);
    }
    
    /// @dev Only calls from the enabled admins are accepted.
    modifier onlyAdmins() 
    {
        require(admins[msg.sender], 'Invalid admin');
        _;
    }

    receive() external payable {}
}