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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ArcBaseWithRainbowRoad} from "../bases/ArcBaseWithRainbowRoad.sol";
import {IAdminAxelarSender} from "../interfaces/IAdminAxelarSender.sol";
import {IAdminChainlinkSender} from "../interfaces/IAdminChainlinkSender.sol";
import {IAdminLayerZeroSender} from "../interfaces/IAdminLayerZeroSender.sol";
import {IRainbowRoad} from "../interfaces/IRainbowRoad.sol";

/**
 * Automation to call update period for Archly DEX on other chains
 */
contract DexWeeklyUpdater is ArcBaseWithRainbowRoad
{
    enum Providers {
        Axelar,
        Chainlink,
        LayerZero
    }
    
    uint256[] public chains;
    mapping(address => bool) public admins;
    mapping(address => bool) public authorized;
    mapping(uint256 => bool) public chainActive;
    mapping(uint256 => Providers) public chainProvider;
    mapping(uint256 => address) public chainReceiver;
    mapping(uint256 => address) public chainSender;
    mapping(uint256 => string) public axelarChainSelectorIds;
    mapping(uint256 => uint64) public chainlinkChainSelectorIds;
    mapping(uint256 => uint16) public layerzeroChainSelectorIds;
    
    error DuplicateChainId(uint256 chainId);
    error ChainIdDoesNotExist(uint256 chainId);
    
    event WeeklyUpdateNotProcessed(uint256 chainId, bool isActive);
    event WeeklyUpdateErrorProcessing(uint256 chainId, bool isActive);
    event WeeklyUpdateSuccess(uint256 chainId, bool isActive, Providers provider);
    
    constructor(address _rainbowRoad) ArcBaseWithRainbowRoad(_rainbowRoad)
    {
        admins[msg.sender] = true;
    }
    
    function chainIdExists(uint256 chainId) public view returns (bool)
    {
        for(uint i = 0; i < chains.length; i++) {
            if(chains[i] == chainId) {
                return true;
            }
        }
        
        return false;
    }
    
    function addChain(uint256 chainId, Providers provider, address sender, address receiver, string calldata axelarChainSelectorId, uint64 chainlinkChainSelectorId, uint16 layerzeroChainSelectorId) external onlyAdmins
    {
        require(sender != address(0), 'Sender cannot be zero address');
        require(receiver != address(0), 'Receiver cannot be zero address');
        
        
        if(this.chainIdExists(chainId)) {
            revert DuplicateChainId({chainId: chainId});
        }
        
        chains.push(chainId);
        chainActive[chainId] = true;
        chainProvider[chainId] = provider;
        chainReceiver[chainId] = receiver;
        chainSender[chainId] = sender;
        axelarChainSelectorIds[chainId] = axelarChainSelectorId;
        chainlinkChainSelectorIds[chainId] = chainlinkChainSelectorId;
        layerzeroChainSelectorIds[chainId] = layerzeroChainSelectorId;
    }
    
    function setChainProvider(uint256 chainId, Providers provider) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        chainProvider[chainId] = provider;
    }
    
    function setChainReceiver(uint256 chainId, address receiver) external onlyAdmins
    {
        require(receiver != address(0), 'Receiver cannot be zero address');
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        chainReceiver[chainId] = receiver;
    }
    
    function setChainSender(uint256 chainId, address sender) external onlyAdmins
    {
        require(sender != address(0), 'Sender cannot be zero address');
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        chainSender[chainId] = sender;
    }
    
    function setAxelarChainSelectorId(uint256 chainId, string calldata selectorId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        axelarChainSelectorIds[chainId] = selectorId;
    }
    
    function setChainlinkChainSelectorId(uint256 chainId, uint64 selectorId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        chainlinkChainSelectorIds[chainId] = selectorId;
    }
    
    function setLayerZeroChainSelectorId(uint256 chainId, uint16 selectorId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        layerzeroChainSelectorIds[chainId] = selectorId;
    }
    
    function enableAdmin(address admin) external onlyOwner
    {
        require(admin != address(0), 'Admin cannot be zero address');
        require(!admins[admin], 'Admin is enabled');
        admins[admin] = true;
    }
    
    function disableAdmin(address admin) external onlyOwner
    {
        require(admin != address(0), 'Admin cannot be zero address');
        require(admins[admin], 'Admin is disabled');
        admins[admin] = false;
    }
    
    function enableAuthorized(address _authorized) external onlyOwner
    {
        require(_authorized != address(0), 'Authorized cannot be zero address');
        require(!authorized[_authorized], 'Authorized is enabled');
        authorized[_authorized] = true;
    }
    
    function disableAuthorized(address _authorized) external onlyOwner
    {
        require(_authorized != address(0), 'Authorized cannot be zero address');
        require(authorized[_authorized], 'Admin is disabled');
        authorized[_authorized] = false;
    }
    
    function enableChain(uint256 chainId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        require(!chainActive[chainId], 'Chain already enabled');
        
        chainActive[chainId] = true;
    }
    
    function disableChain(uint256 chainId) external onlyAdmins
    {
        if(!this.chainIdExists(chainId)) {
            revert ChainIdDoesNotExist({chainId: chainId});
        }
        
        require(chainActive[chainId], 'Chain already disabled');
        
        chainActive[chainId] = false;
    }
    
    function runWeeklyUpdates() external onlyAdmins
    {
        for(uint256 i = 0; i < chains.length; i++) {
            try this.runWeeklyUpdate(chains[i]) {
                
            } catch {
                emit WeeklyUpdateNotProcessed(chains[i], chainActive[chains[i]]);
            }
        }
    }
    
    function runWeeklyUpdate(uint256 chainId) public onlyAdmins
    {
        processWeeklyUpdate(chainId);
    }
    
    function processWeeklyUpdate(uint256 chainId) internal
    {
        if(chainActive[chainId]) {
            
            Providers provider = chainProvider[chainId];
            address receiver = chainReceiver[chainId];
            address sender = chainSender[chainId];
            
            IERC20(address(rainbowRoad.arc())).approve(address(rainbowRoad), rainbowRoad.sendFee());
            
            if(provider == Providers.Axelar) {
                IAdminAxelarSender(sender).send(
                    axelarChainSelectorIds[chainId], 
                    receiver,
                    'dex_weekly_update', 
                    ''
                );
            } else if(provider == Providers.Chainlink) {
                IAdminChainlinkSender(sender).send(
                    chainlinkChainSelectorIds[chainId], 
                    receiver,
                    'dex_weekly_update', 
                    ''
                );
            } else {
                IAdminLayerZeroSender(sender).send(
                    layerzeroChainSelectorIds[chainId], 
                    receiver,
                    'dex_weekly_update', 
                    ''
                );
            }

            emit WeeklyUpdateSuccess(chainId, chainActive[chainId], provider);
        } else {
            emit WeeklyUpdateNotProcessed(chainId, chainActive[chainId]);
        }
    }
    
    /// @dev Only calls from the enabled admins are accepted.
    modifier onlyAdmins() 
    {
        require(admins[msg.sender], 'Invalid admin');
        _;
    }
    
    /// @dev Only calls from the authorized are accepted.
    modifier onlyAuthorized() 
    {
        require(authorized[msg.sender], "Not authorized");
        _;
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

interface IAdminAxelarSender {
    function send(string calldata destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) external;
    function send(string calldata destinationChainSelector, address messageReceiver, string calldata action, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAdminChainlinkSender {
    function send(uint64 destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) external;
    function send(uint64 destinationChainSelector, address messageReceiver, string calldata action, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAdminLayerZeroSender {
    function send(uint16 destinationChainSelector, address messageReceiver, address actionRecipient, string calldata action, bytes calldata payload) external;
    function send(uint16 destinationChainSelector, address messageReceiver, string calldata action, bytes calldata payload) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IArc {
    function burn(uint amount) external;
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