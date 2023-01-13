// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

TransferBlocker.sol
Written by: mousedev.eth

Blocks transfer of tokens based on set requirements
*/

import "./utilities/OwnableOrAdminable.sol";
import "./SmolsAddressRegistryConsumer.sol";
import "./interfaces/ISchool.sol";

contract TransferBlocker is OwnableOrAdminable, SmolsAddressRegistryConsumer {

    /// @dev Returns whether a token is currently transferrable.
    /// @param _collectionAddress The collection that this token belongs to.
    /// @return _tokenId The token to check.
    function isTransferrable(address _collectionAddress, uint256 _tokenId)
        external
        view
        returns (bool)
    {
        address schoolAddress = smolsAddressRegistry.getAddress(SmolAddressEnum.SCHOOLADDRESS);
        if (ISchool(schoolAddress).totalStatsJoinedWithinCollection(_collectionAddress, _tokenId) > 0) return false;
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

abstract contract OwnableOrAdminable {
    address private _owner;

    mapping(address => bool) private _isAdmin;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(msg.sender);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwnerOrAdmin() {
        require(
            owner() == msg.sender || _isAdmin[msg.sender],
            "Ownable: caller is not the owner or admin"
        );
        _;
    }

    /**
     * @dev Allows owner or admin to add admins
     */

    function setAdmins(address[] memory _addresses, bool[] memory _isAdmins) public {
        require(
            owner() == msg.sender,
            "Ownable: caller is not the owner"
        );

        for (uint256 i = 0; i < _addresses.length; i++) {
            _isAdmin[_addresses[i]] = _isAdmins[i];
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/*

SmolsAddressRegistryConsumer.sol

Written by: mousedev.eth

*/

import "./utilities/OwnableOrAdminable.sol";
import "./interfaces/ISmolsAddressRegistry.sol";


contract SmolsAddressRegistryConsumer is OwnableOrAdminable {

    ISmolsAddressRegistry smolsAddressRegistry;

    
    /// @dev Sets the smols address registry address.
    /// @param _smolsAddressRegistry The address of the registry.
    function setSmolsAddressRegistry(address _smolsAddressRegistry) external onlyOwner {
        smolsAddressRegistry = ISmolsAddressRegistry(_smolsAddressRegistry);
    }

}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

struct TokenDetails {
    uint128 statAccrued;
    uint64 timestampJoined;
    bool joined;
}

struct StatDetails {
    uint128 globalStatAccrued;
    uint128 emissionRate;
    bool exists;
    bool joinable;
}

interface ISchool {
    function tokenDetails(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (TokenDetails memory);

    function getPendingStatEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (uint128);

    function statDetails(address _collectionAddress, uint64 _statId)
        external
        view
        returns (StatDetails memory);

    function totalStatsJoinedWithinCollection(
        address _collectionAddress,
        uint256 _tokenId
    ) external view returns (uint256);

    function getTotalStatPlusPendingEmissions(
        address _collectionAddress,
        uint64 _statId,
        uint256 _tokenId
    ) external view returns (uint128);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

enum SmolAddressEnum {
    OLDSMOLSADDRESS,
    SMOLSADDRESS,

    SMOLSSTATEADDRESS,
    SCHOOLADDRESS,

    SMOLSTRAITSTORAGEADDRESS,

    SMOLSRENDERERADDRESS,
    TRANSFERBLOCKERADDRESS
}

interface ISmolsAddressRegistry{
    function getAddress(SmolAddressEnum) external view returns(address);
}