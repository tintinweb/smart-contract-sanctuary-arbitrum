// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressRegistryV2.sol";

contract AddressRegistryController is Ownable {

    event FunctionOwnershipTransferred(address indexed previousOwner, address indexed newOwner, bytes32 functionId);

    IAddressRegistryV2 public registry;

    bytes32 public constant SET_ADMIN = "SET_ADMIN";
    bytes32 public constant SET_LOCK_MANAGER = "SET_LOCK_MANAGER";
    bytes32 public constant SET_REVEST_TOKEN = "SET_REVEST_TOKEN";
    bytes32 public constant SET_TOKEN_VAULT = "SET_TOKEN_VAULT";
    bytes32 public constant SET_REVEST = "SET_REVEST";
    bytes32 public constant SET_FNFT = "SET_FNFT";
    bytes32 public constant SET_METADATA = "SET_METADATA";
    bytes32 public constant SET_REWARDS_HANDLER = 'SET_REWARDS_HANDLER';
    bytes32 public constant UNPAUSE_TOKEN = 'UNPAUSE_TOKEN';
    bytes32 public constant MODIFY_BREAKER = 'MODIFY_BREAKER';
    bytes32 public constant MODIFY_PAUSER = 'MODIFY_PAUSER';


    mapping(bytes32 => address) public functionOwner;

    constructor(address _provider) Ownable() {
        registry = IAddressRegistryV2(_provider);
        functionOwner[SET_ADMIN] = _msgSender();
        functionOwner[SET_LOCK_MANAGER] = _msgSender();
        functionOwner[SET_REVEST_TOKEN] = _msgSender();
        functionOwner[SET_TOKEN_VAULT] = _msgSender();
        functionOwner[SET_REVEST] = _msgSender();
        functionOwner[SET_FNFT] = _msgSender();
        functionOwner[SET_METADATA] = _msgSender();
        functionOwner[SET_REWARDS_HANDLER] = _msgSender();
        functionOwner[UNPAUSE_TOKEN] = _msgSender();
        functionOwner[MODIFY_BREAKER] = _msgSender();
        functionOwner[MODIFY_PAUSER] = _msgSender();
    }

    modifier onlyFunctionOwner(bytes32 functionId) {
        require(_msgSender() == functionOwner[functionId] && _msgSender() != address(0), 'E079');
        _;
    }

    ///
    /// Controller control functions
    ///

    function transferFunctionOwnership(
        bytes32 functionId, 
        address newFunctionOwner
    ) external onlyFunctionOwner(functionId) {
        address oldFunctionOwner = functionOwner[functionId];
        functionOwner[functionId] = newFunctionOwner;
        emit FunctionOwnershipTransferred(oldFunctionOwner, newFunctionOwner, functionId);
    }

    function renounceFunctionOwnership(
        bytes32 functionId
    ) external onlyFunctionOwner(functionId) {
        address oldFunctionOwner = functionOwner[functionId];
        functionOwner[functionId] = address(0);
        emit FunctionOwnershipTransferred(oldFunctionOwner, address(0), functionId);
    }
    
    ///
    /// Control functions
    ///

    /// Pass through unpause signal to Registry
    function unpauseToken() external onlyFunctionOwner(UNPAUSE_TOKEN) {
        registry.unpauseToken();
    }
    
    /// Admin function for adding or removing breakers
    function modifyBreaker(address breaker, bool grant) external onlyFunctionOwner(MODIFY_BREAKER) {
        registry.modifyBreaker(breaker, grant);
    }

    /// Admin function for adding or removing pausers
    function modifyPauser(address pauser, bool grant) external onlyFunctionOwner(MODIFY_PAUSER) {
        registry.modifyPauser(pauser, grant);
    }


    ///
    /// SETTERS
    ///

    function setAdmin(address admin) external onlyFunctionOwner(SET_ADMIN) {
        registry.setAdmin(admin);
    }

    function setLockManager(address manager) external onlyFunctionOwner(SET_LOCK_MANAGER) {
        registry.setLockManager(manager);
    }

    function setTokenVault(address vault) external onlyFunctionOwner(SET_TOKEN_VAULT) {
        registry.setTokenVault(vault);
    }
   
    function setRevest(address revest) external onlyFunctionOwner(SET_REVEST) {
        registry.setRevest(revest);
    }

    function setRevestFNFT(address fnft) external onlyFunctionOwner(SET_FNFT) {
        registry.setRevestFNFT(fnft);
    }

    function setMetadataHandler(address metadata) external onlyFunctionOwner(SET_METADATA) {
        registry.setMetadataHandler(metadata);
    }

    function setRevestToken(address token) external onlyFunctionOwner(SET_REVEST_TOKEN) {
        registry.setRevestToken(token);
    }

    function setRewardsHandler(address esc) external onlyFunctionOwner(SET_REWARDS_HANDLER) {
        registry.setRewardsHandler(esc);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IAddressRegistry.sol";

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistryV2 is IAddressRegistry {

        function initialize_with_legacy(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address legacy_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getLegacyTokenVault() external view returns (address legacy);

    function setLegacyTokenVault(address legacyVault) external;

    function breakGlass() external;

    function pauseToken() external;

    function unpauseToken() external;

    function modifyPauser(address pauser, bool grant) external;

    function modifyBreaker(address breaker, bool grant) external;
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

// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

/**
 * @title Provider interface for Revest FNFTs
 * @dev
 *
 */
interface IAddressRegistry {

    function initialize(
        address lock_manager_,
        address liquidity_,
        address revest_token_,
        address token_vault_,
        address revest_,
        address fnft_,
        address metadata_,
        address admin_,
        address rewards_
    ) external;

    function getAdmin() external view returns (address);

    function setAdmin(address admin) external;

    function getLockManager() external view returns (address);

    function setLockManager(address manager) external;

    function getTokenVault() external view returns (address);

    function setTokenVault(address vault) external;

    function getRevestFNFT() external view returns (address);

    function setRevestFNFT(address fnft) external;

    function getMetadataHandler() external view returns (address);

    function setMetadataHandler(address metadata) external;

    function getRevest() external view returns (address);

    function setRevest(address revest) external;

    function getDEX(uint index) external view returns (address);

    function setDex(address dex) external;

    function getRevestToken() external view returns (address);

    function setRevestToken(address token) external;

    function getRewardsHandler() external view returns(address);

    function setRewardsHandler(address esc) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLPs() external view returns (address);

    function setLPs(address liquidToken) external;

}