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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// External
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// Tapioca
import {ICluster} from "tapioca-periph/interfaces/periph/ICluster.sol";

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

contract Cluster is Ownable, ICluster {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice returns the current LayerZero chain id
    uint32 public lzChainId;

    /// @notice returns the whitelist status for an address
    /// @dev LZ chain id => contract => status
    mapping(uint32 lzChainId => mapping(address _contract => bool status)) private _whitelisted;

    /// @notice Centralized role assignment for Tapioca contract. Other contracts can use this mapping to check if an address has a role on them
    mapping(address _contract => mapping(bytes32 role => bool hasRole)) public hasRole;

    /// @notice event emitted when LZ chain id is updated
    event LzChainUpdate(uint256 indexed _oldChain, uint256 indexed _newChain);
    /// @notice event emitted when a contract status is updated
    event ContractUpdated(
        address indexed _contract, uint32 indexed _lzChainId, bool indexed _oldStatus, bool _newStatus
    );
    /// @notice event emitted when a role is set
    event RoleSet(address indexed _contract, bytes32 indexed _role, bool _hasRole);

    // ************** //
    // *** ERRORS *** //
    // ************** //
    error NotAuthorized();

    constructor(uint32 _lzChainId, address _owner) {
        emit LzChainUpdate(0, _lzChainId);
        lzChainId = _lzChainId;
        transferOwnership(_owner);
    }

    modifier isAuthorized() {
        if (msg.sender != owner()) {
            revert NotAuthorized();
        }
        _;
    }

    // ******************** //
    // *** VIEW METHODS *** //
    // ******************** //
    /// @notice returns the whitelist status of a contract
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    function isWhitelisted(uint32 _lzChainId, address _addr) external view override returns (bool) {
        if (_lzChainId == 0) {
            _lzChainId = lzChainId;
        }
        return _whitelisted[_lzChainId][_addr];
    }

    // ********************** //
    // *** PUBLIC METHODS *** //
    // ********************** //

    /// @notice updates the whitelist status of contracts
    /// @dev can only be called by Editors or the Owner
    /// @param _lzChainId LayerZero chain id
    /// @param _addresses the contracts addresses
    /// @param _status the new whitelist status
    function batchUpdateContracts(uint32 _lzChainId, address[] memory _addresses, bool _status)
        external
        override
        isAuthorized
    {
        if (_lzChainId == 0) {
            //set lz chain as the current one
            _lzChainId = lzChainId;
        }

        for (uint256 i; i < _addresses.length; i++) {
            emit ContractUpdated(_addresses[i], _lzChainId, _whitelisted[_lzChainId][_addresses[i]], _status);
            _whitelisted[_lzChainId][_addresses[i]] = _status;
        }
    }

    /// @notice updates the whitelist status of a contract
    /// @dev can only be called by Editors or the Owner
    /// @param _lzChainId LayerZero chain id
    /// @param _addr the contract's address
    /// @param _status the new whitelist status
    function updateContract(uint32 _lzChainId, address _addr, bool _status) external override isAuthorized {
        if (_lzChainId == 0) {
            //set lz chain as the current one
            _lzChainId = lzChainId;
        }

        emit ContractUpdated(_addr, _lzChainId, _whitelisted[_lzChainId][_addr], _status);
        _whitelisted[_lzChainId][_addr] = _status;
    }

    /**
     * @notice sets a role for a contract.
     * @param _contract the contract's address.
     * @param _role the role's name for the contract, in bytes32 format.
     * @param _hasRole the new role status.
     */
    function setRoleForContract(address _contract, bytes32 _role, bool _hasRole) external isAuthorized {
        hasRole[_contract][_role] = _hasRole;
        emit RoleSet(_contract, _role, _hasRole);
    }

    // ********************* //
    // *** OWNER METHODS *** //
    // ********************* //

    /// @notice updates LayerZero chain id
    /// @param _lzChainId the new LayerZero chain id
    function updateLzChain(uint32 _lzChainId) external onlyOwner {
        emit LzChainUpdate(lzChainId, _lzChainId);
        lzChainId = _lzChainId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/*

████████╗ █████╗ ██████╗ ██╗ ██████╗  ██████╗ █████╗ 
╚══██╔══╝██╔══██╗██╔══██╗██║██╔═══██╗██╔════╝██╔══██╗
   ██║   ███████║██████╔╝██║██║   ██║██║     ███████║
   ██║   ██╔══██║██╔═══╝ ██║██║   ██║██║     ██╔══██║
   ██║   ██║  ██║██║     ██║╚██████╔╝╚██████╗██║  ██║
   ╚═╝   ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝
   
*/

interface ICluster {
    function isWhitelisted(uint32 lzChainId, address _addr) external view returns (bool);

    function updateContract(uint32 lzChainId, address _addr, bool _status) external;

    function batchUpdateContracts(uint32 _lzChainId, address[] memory _addresses, bool _status) external;

    function lzChainId() external view returns (uint32);

    function hasRole(address _contract, bytes32 _role) external view returns (bool);

    function setRoleForContract(address _contract, bytes32 _role, bool _hasRole) external;
}