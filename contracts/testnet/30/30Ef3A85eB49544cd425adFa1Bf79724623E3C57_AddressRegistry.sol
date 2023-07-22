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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressRegistry.sol";

contract AddressRegistry is IAddressRegistry, Ownable {
    mapping(uint256 => address) libraryAndContractAddresses;

    constructor(address _weth9) {
        setAddress(AddressId.ADDRESS_ID_WETH9, _weth9);
    }

    function setAddress(uint256 id, address _addr) public onlyOwner {
        libraryAndContractAddresses[id] = _addr;
        emit SetAddress(_msgSender(), id, _addr);
    }

    function getAddress(uint256 id) external view override returns (address) {
        return libraryAndContractAddresses[id];
    }
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;

import "../libraries/helpers/AddressId.sol";

interface IAddressRegistry {
    event SetAddress(
        address indexed setter,
        uint256 indexed id,
        address newAddress
    );

    function getAddress(uint256 id) external view returns (address);
}

// SPDX-License-Identifier: gpl-3.0
pragma solidity ^0.8.0;
pragma abicoder v2;

library AddressId {
    uint256 constant ADDRESS_ID_WETH9 = 1;
    uint256 constant ADDRESS_ID_UNI_V3_FACTORY = 2;
    uint256 constant ADDRESS_ID_UNI_V3_NONFUNGIBLE_POSITION_MANAGER = 3;
    uint256 constant ADDRESS_ID_UNI_V3_SWAP_ROUTER = 4;
    uint256 constant ADDRESS_ID_VELO_ROUTER = 5;
    uint256 constant ADDRESS_ID_VELO_FACTORY = 6;
    uint256 constant ADDRESS_ID_VAULT_POSITION_MANAGER = 7;
    uint256 constant ADDRESS_ID_SWAP_EXECUTOR_MANAGER = 8;
    uint256 constant ADDRESS_ID_LENDING_POOL = 9;
    uint256 constant ADDRESS_ID_VAULT_FACTORY = 10;
    uint256 constant ADDRESS_ID_TREASURY = 11;
    uint256 constant ADDRESS_ID_VE_TOKEN = 12;

    uint256 constant ADDRESS_ID_VELO_VAULT_DEPLOYER = 101;
    uint256 constant ADDRESS_ID_VELO_VAULT_INITIALIZER = 102;
    uint256 constant ADDRESS_ID_VELO_VAULT_POSITION_LOGIC = 103;
    uint256 constant ADDRESS_ID_VELO_VAULT_REWARDS_LOGIC = 104;
    uint256 constant ADDRESS_ID_VELO_VAULT_OWNER_ACTIONS = 105;
    uint256 constant ADDRESS_ID_VELO_SWAP_PATH_MANAGER = 106;
}